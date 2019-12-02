
#include "LuaSqlite3.h"

#ifdef USESQLITE3

#define META_NAME "[SQLITE3]"
#define PARAM_MAXN 128

static int _WeakK_ColCache;

typedef struct conn_data {
	sqlite3    *sql_conn;
	unsigned char auto_commit;
	unsigned char line;
} conn_data;

//lua meta---------------------------------------
static int conn_gc(lua_State *L) {
	conn_data *conn = (conn_data *)lua_touserdata(L, -1);
	lua_getref(L, _WeakK_ColCache); //top,wk
	lua_pushvalue(L, 1);
	lua_rawget(L, -2);	//top,,wk, utb
	lua_remove(L, -2); //top, utb

	sqlite3_stmt *stmt;
	size_t *coltypes;
	for (lua_pushnil(L); lua_next(L, -2); lua_pop(L, 1))
	{
		lua_rawgeti(L, -1, 1);
		coltypes = (size_t*)lua_touserdata(L, -1);
		stmt = (sqlite3_stmt*)coltypes[0];
		sqlite3_finalize(stmt);
		lua_pop(L, 1);
	}
	if (conn->sql_conn)
		sqlite3_close(conn->sql_conn);
	conn->sql_conn = NULL;
	return 0;
}
static int conn_close(lua_State *L) {
	conn_data *conn = (conn_data *)luaL_checkudata(L, 1, META_NAME);
	if (!conn->sql_conn) {
		lua_pushboolean(L, 0);
		return 1;
	}
	sqlite3_close(conn->sql_conn);
	conn->sql_conn = NULL;
	lua_pushboolean(L, 1);
	return 1;
}
static int conn_closed(lua_State *L) {
	conn_data *conn = (conn_data *)luaL_checkudata(L, 1, META_NAME);
	if (!conn->sql_conn)
		lua_pushboolean(L, 1);
	else
		lua_pushboolean(L, 0);
	return 1;
}
static int conn_begin(lua_State *L) {
	conn_data *conn = (conn_data *)luaL_checkudata(L, 1, META_NAME);
	char *errmsg;
	int res = sqlite3_exec(conn->sql_conn, "BEGIN;", NULL, NULL, &errmsg);
	if (res != SQLITE_OK) {
		fprintf(stderr, "[C]error in run sqlite3: %s\n", errmsg);
		sqlite3_free(errmsg);//must
	}
	return 0;
}
static int conn_rollback(lua_State *L) {
	conn_data *conn = (conn_data *)luaL_checkudata(L, 1, META_NAME);
	char *errmsg;
	const char *sql = conn->auto_commit == 0 ? "ROLLBACK;BEGIN;" : "ROLLBACK";
	int res = sqlite3_exec(conn->sql_conn, sql, NULL, NULL, &errmsg);
	if (res != SQLITE_OK) {
		fprintf(stderr, "[C]error in run sqlite3: %s\n", errmsg);
		sqlite3_free(errmsg);//must
	}
	return 0;
}
static int conn_commit(lua_State *L) {
	conn_data *conn = (conn_data *)luaL_checkudata(L, 1, META_NAME);
	char *errmsg;
	const char *sql = conn->auto_commit==0 ? "COMMIT;BEGIN;" : "COMMIT;";
	int res = sqlite3_exec(conn->sql_conn, sql, NULL, NULL, &errmsg);
	if (res != SQLITE_OK) {
		fprintf(stderr, "[C]error in run sqlite3: %s\n", errmsg);
		sqlite3_free(errmsg);//must
	}
	return 0;
}
static int conn_autocommit(lua_State *L) {
	conn_data *conn = (conn_data *)luaL_checkudata(L, 1, META_NAME);
	char *errmsg;
	int res;
	int b = lua_toboolean(L, 2);
	conn->auto_commit = b;
	if (b)
		res = sqlite3_exec(conn->sql_conn, "ROLLBACK;", NULL, NULL, &errmsg);
	else
		res = sqlite3_exec(conn->sql_conn, "BEGIN;", NULL, NULL, &errmsg);
	if (res != SQLITE_OK) {
		fprintf(stderr, "[C]error in run sqlite3: %s\n", errmsg);
		sqlite3_free(errmsg);//must
	}
	return 0;
}

static int conn_line(lua_State *L) {
	conn_data *conn = (conn_data *)luaL_checkudata(L, 1, META_NAME);
	conn->line = 1;
	return 1;
}

static int conn_run(lua_State *L)
{
	conn_data *conn = (conn_data *)luaL_checkudata(L, 1, META_NAME);
	const char *query = luaL_checkstring(L, 2);
	int top = lua_gettop(L);

	sqlite3_stmt *stmt;
	int colnum = 0;
	size_t *coltypes;
	const char *tail;
	int res;
	char *err;
	//_WeakK_ColCache[conn][query] = {
	//	coltypes{ [0] = stmt, [i++] =  }
	//	colnames{...}
	//}
	lua_getref(L, _WeakK_ColCache); //top,wk
	lua_pushvalue(L, 1), lua_rawget(L, -2), lua_remove(L, -2); //top, utb --local utb = wk[mysql]
	lua_pushvalue(L, 2), lua_rawget(L, -2);//top, utb, query			--local cache = utb[query]
	if (!lua_isnil(L, -1)) { //getCache
		lua_remove(L, -2);//top, cache
		lua_rawgeti(L, -1, 1);//top, cache, coltypes
		coltypes = (size_t*)lua_touserdata(L, -1);
		stmt = (sqlite3_stmt*)coltypes[0];
		lua_pop(L, 1);//top, cache
		lua_rawgeti(L, -1, 2);//top, cache, colnames
		if (!lua_isnil(L, -1))
			colnum = lua_objlen(L, -1); //colnum=#colnames
	}
	else {
#if SQLITE_VERSION_NUMBER > 3006013
		res = sqlite3_prepare_v2(conn->sql_conn, query, -1, &stmt, &tail);
#else
		res = sqlite3_prepare(conn->sql_conn, query, -1, &stmt, &tail);
#endif
		if (res != SQLITE_OK)
		{
			err = (char *)sqlite3_errmsg(conn->sql_conn);
			fprintf(stderr, "[C]error in prepare sqlite3: %s\n", err);
			sqlite3_free(err); //must
			return 0;
		}
		lua_pop(L, 1);
		lua_createtable(L, 2, 0);//top, utb, cache
		lua_pushvalue(L, 2), lua_pushvalue(L, -2), lua_rawset(L, -4);//top, utb, cache  utb[query]=cache
		lua_remove(L, -2); //top, cache
		/* process first result to retrive query information and type */
		colnum = sqlite3_column_count(stmt);
		if (colnum > 0) {
			//coltypes = (size_t*)lua_newuserdata(L, sizeof(int*) + sizeof(int*) * colnum);
			coltypes = (size_t*)lua_newuserdata(L, sizeof(int*));
			lua_rawseti(L, -2, 1);//top, cache
			lua_createtable(L, colnum, 0); //top, cache, colnames
			lua_pushvalue(L, -1), lua_rawseti(L, -3, 2);
			for (int i = 0; i < colnum; )
			{
				lua_pushstring(L, sqlite3_column_name(stmt, i));
				lua_rawseti(L, top + 2, ++i);
				//coltypes[i] = 
			}
		}
		else {
			coltypes = (size_t*)lua_newuserdata(L, sizeof(int*));
			lua_rawseti(L, -2, 1);
		}
		coltypes[0] = (size_t)stmt;
		///* create table with column types */
		//lua_newtable(L);
		//for (int i = 0; i < colnum;)
		//{
		//	lua_pushstring(L, sqlite3_column_decltype(stmt, i));
		//	lua_rawseti(L, -2, ++i);
		//}
	}
	//bind params
	int paramn = sqlite3_bind_parameter_count(stmt);
	if (paramn >= PARAM_MAXN)
		lua_errorEx(L, "[C]sql error: too many parameters %d", paramn);
	if (paramn != top - 2)
		lua_errorEx(L, "[C]bad argument (%d parameters expected, got %d)", paramn, top - 2);
	if (paramn > 0) {
		int idx;
		long long i;
		for (int p = 1; p <= paramn; p++) {
			idx = p + 2;// , bind = binds + p, i = binds[p].buffer;
			switch (lua_type(L, idx))
			{
			case LUA_TNIL:
				sqlite3_bind_null(stmt, p);
				break;
			case LUA_TBOOLEAN:
				break;
			case LUA_TNUMBER: {
				double V = lua_tonumber(L, idx);
				i = (long long)V;
				if (i == V)
					sqlite3_bind_int64(stmt, p, double2long(V));
				else
					sqlite3_bind_double(stmt, p, V);
				break;
			}
			case LUA_TSTRING: {
				size_t len;
				const char*s = lua_tolstring(L, idx, &len);
				sqlite3_bind_text(stmt, p, s, len, NULL);
				break;
			}
			case LUA_TUSERDATA:	case LUA_TLIGHTUSERDATA: {
				size_t len;
				const char *s = lua_toBytes(L, idx, &len);
				if (s) {
					sqlite3_bind_text(stmt, p, s, len, NULL);
				}
				break;
			}
			default:
				lua_errorEx(L, "[C]unsurpported sql param type:%s", lua_typename(L, lua_type(L, idx)));
				break;
			}
		}
	}
	//execute
	if (colnum == 0) {//无返回值 return affected_rows, insert_id/* and numcols==0, INSERT,UPDATE,DELETE statement */
		res = sqlite3_step(stmt);
		conn->line = 0;
		if (res != SQLITE_DONE) {
			err = (char *)sqlite3_errmsg(conn->sql_conn);
			fprintf(stderr, "[C]error in run sqlite3: %s\n", err);
			sqlite3_free(err);//must
			sqlite3_reset(stmt);
			return 0;
		}
		lua_pushnumber(L, sqlite3_last_insert_rowid(conn->sql_conn));
		lua_pushnumber(L, sqlite3_changes(conn->sql_conn));
		sqlite3_reset(stmt);
		return 2;
	}
	int col;
	for (int row = 1; ; row++) //row
	{
		res = sqlite3_step(stmt);
		if (res == SQLITE_DONE)
			break;
		if (res != SQLITE_ROW) {
			err = (char *)sqlite3_errmsg(conn->sql_conn);
			fprintf(stderr, "[C]error in run sqlite3: %s\n", err);
			sqlite3_free(err);//must
			sqlite3_reset(stmt);
			return 0;
		}
		if (!conn->line) {
			if (row == 1)
				lua_createtable(L, 100, 0);
			lua_createtable(L, 0, colnum);
		}
		for (col = 0; col < colnum; col++)
		{
			if (!conn->line)
				lua_rawgeti(L, top + 2, col + 1); //pushname //lua_pushstring(L, sqlite3_column_name(stmt, col));
			switch (sqlite3_column_type(stmt, col)) {
			case SQLITE_INTEGER:
				lua_pushinteger(L, sqlite3_column_int64(stmt, col));
				break;
			case SQLITE_FLOAT:
				lua_pushnumber(L, sqlite3_column_double(stmt, col));
				break;
			case SQLITE_TEXT:
				lua_pushlstring(L, (const char *)sqlite3_column_text(stmt, col),
					(size_t)sqlite3_column_bytes(stmt, col));
				break;
			case SQLITE_BLOB:
				lua_pushlstring(L, sqlite3_column_blob(stmt, col),
					(size_t)sqlite3_column_bytes(stmt, col));
				break;
			case SQLITE_NULL:
				lua_pushnil(L);
				break;
			default:
				luaL_error(L, "Unrecognized column type");
				break;
			}
			if (!conn->line)
				lua_rawset(L, -3);
		}
		if (!conn->line)
			lua_rawseti(L, -2, row);
		else
			break;
	}
	sqlite3_reset(stmt);
	if (conn->line) {
		conn->line = 0;
		return colnum;
	}
	return 1;
}

static int conn_runs(lua_State *L) {
	conn_data *conn = (conn_data *)luaL_checkudata(L, 1, META_NAME);
	char *errmsg;
	size_t len;
	char *s = (char *)lua_tolstring(L, 2, &len);
	int res = sqlite3_exec(conn->sql_conn, s, NULL, NULL, &errmsg);
	if (res != SQLITE_OK) {
		fprintf(stderr, "[C]error in run sqlite3: %s\n", errmsg);
		sqlite3_free(errmsg);//must
	}
	return 0;
}

static int sqlConnect(lua_State *L)
{
	const char *source = luaL_checkstring(L, 1);
	sqlite3 *sqlite_conn;
	char *err;
	int res;

#if SQLITE_VERSION_NUMBER > 3006013
	res = sqlite3_open_v2(source, &sqlite_conn, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL);
#else
	res = sqlite3_open(source, &sqlite_conn);
#endif
	if (res != SQLITE_OK)
	{
		err = (char *)sqlite3_errmsg(sqlite_conn);
		fprintf(stderr, "[C]error in open sqlite3: %s\n", err);
		//sqlite3_free(err);//must? 报错exec和query时的报错必用,open的好象不用
		sqlite3_close(sqlite_conn);
		return 0;
	}
	if (lua_isnumber(L, 3)) 
		sqlite3_busy_timeout(sqlite_conn, lua_tonumber(L, 3)); /* TODO: remove this */

	conn_data *conn = (conn_data *)lua_newuserdata(L, sizeof(conn_data));
	conn->sql_conn = sqlite_conn;
	conn->auto_commit = 1; //must
	conn->line = 1;
	lua_pushvalue(L, lua_upvalueindex(1)); //luaL_getmetatable(L, META_NAME);
	lua_setmetatable(L, -2);

	//stmt cache table
	lua_getref(L, _WeakK_ColCache);
	lua_pushvalue(L, -2);
	lua_createtable(L, 0, 0);
	lua_rawset(L, -3);
	lua_pop(L, 1);

	return 1;
}

LUA_API void luaopen_sqlite3(lua_State *L)
{
	//ref weak table
	lua_createtable(L, 0, 0);
	lua_createtable(L, 0, 1);
	lua_pushliteral(L, "__mode");
	lua_pushliteral(L, "k");
	lua_rawset(L, -3);
	lua_setmetatable(L, -2);
	_WeakK_ColCache = lua_ref(L, -1);

	struct luaL_Reg methods[] = {
		{ "__gc",   conn_gc }, //userdata use
		{ "run",	conn_run },
		{ "close",  conn_close },
		{ "closed", conn_closed },
		{ "begin",	conn_begin },
		{ "rollback", conn_rollback },
		{ "commit", conn_commit },
		{ "autocommit",	conn_autocommit },
		{ "runs", 	conn_runs },
		{ "line", 	conn_line },

		{ NULL, NULL },
	};
	lua_regMetatable(L, META_NAME, methods, 0);
	//version info
	luaL_getmetatable(L, META_NAME);
	lua_pushliteral(L, "SQLITE_VERSION");
	lua_pushliteral(L, SQLITE_VERSION);
	lua_settable(L, -3);
	lua_pushliteral(L, "SQLITE_VERSION_NUMBER");
	lua_pushnumber(L, SQLITE_VERSION_NUMBER);
	lua_settable(L, -3);
	//lua_pop(L, 1);
	//lua_register(L, "_sqlite3", sqlConnect);
	lua_pushcclosure(L, sqlConnect, 1);
	lua_setglobal(L, "_sqlite3");
}

#endif