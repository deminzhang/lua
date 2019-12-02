
#include "LuaMySql.h"
#ifdef USEMYSQL
#define META_NAME "[MYSQL]"
#define PARAM_MAXN 128

static int _WeakK_ColCache;
//lua meta---------------------------------------
static int conn_gc(lua_State *L) {
	MYSQL *mysql = (MYSQL *)lua_touserdata(L, 1);
	mysql_close(mysql);
	return 0;
}
static int conn_close(lua_State *L) {
	MYSQL *mysql = (MYSQL *)luaL_checkudata(L, 1, META_NAME);
	mysql_close(mysql);
	return 0;
}
static int conn_closed(lua_State *L) {
	MYSQL *mysql = (MYSQL *)luaL_checkudata(L, 1, META_NAME);
	if (mysql->db==NULL) //maybe
		lua_pushboolean(L, 1);
	else
		lua_pushboolean(L, 0);
	return 1;
}
static int conn_begin(lua_State *L) {
	MYSQL *mysql = (MYSQL *)luaL_checkudata(L, 1, META_NAME);
	if (mysql_query(mysql, "START TRANSACTION"))
		fprintf(stderr, "[C]sql error %d-%s\n", mysql_errno(mysql), mysql_error(mysql));
	return 0;
}
static int conn_rollback(lua_State *L) {
	MYSQL *mysql = (MYSQL *)luaL_checkudata(L, 1, META_NAME);
	if (mysql_rollback(mysql))	//if (mysql_query(mysql, "ROLLBACK"))
		fprintf(stderr, "[C]sql error %d-%s\n", mysql_errno(mysql), mysql_error(mysql));
	return 0;
}
static int conn_commit(lua_State *L) {
	MYSQL *mysql = (MYSQL *)luaL_checkudata(L, 1, META_NAME);
	if (mysql_commit(mysql))	//if (mysql_query(mysql, "COMMIT"))
		fprintf(stderr, "[C]sql error %d-%s\n", mysql_errno(mysql), mysql_error(mysql));
	return 0;
}
static int conn_autocommit(lua_State *L) {
	MYSQL *mysql = (MYSQL *)luaL_checkudata(L, 1, META_NAME);
	int b = (my_bool)lua_toboolean(L, 2);
	my_bool r = mysql_autocommit(mysql, b);
	if (mysql_autocommit(mysql, b))
		fprintf(stderr, "[C]sql error %d-%s\n", mysql_errno(mysql), mysql_error(mysql));
	return 0;
}

static int conn_skip(lua_State *L) {
	MYSQL *mysql = (MYSQL *)luaL_checkudata(L, 1, META_NAME);
	//conn->skip = 1;
	return 1;
}

//* :run("select * from table where id=?",1);
//_WeakK_ColCache[mysql][query] = {
//	coltypes{ [0] = stmt, [i++] = MYSQL_FIELD.type }
//	colnames{...}
//}缓存stmt的列名和类型 http://blog.csdn.net/luketty/article/details/6071913 
//TODO重连后缓存的stmt句柄可能失效!
static int conn_run(lua_State *L) 
{
	MYSQL *mysql = (MYSQL *)luaL_checkudata(L, 1, META_NAME);
	const char *query = lua_tostring(L, 2);
	int top = lua_gettop(L);

	MYSQL_STMT *stmt;
	int colnum = 0;
	size_t *coltypes;
	lua_getref(L, _WeakK_ColCache); //top,wk 
	lua_pushvalue(L, 1), lua_rawget(L,-2), lua_remove(L, -2); //top, utb --local utb = wk[mysql]
	lua_pushvalue(L, 2), lua_rawget(L, -2);//top, utb, query			--local cache = utb[query]
	if (!lua_isnil(L, -1)){ //top, utb, cache //have colnum cache
		lua_remove(L, -2);//top, cache
		lua_rawgeti(L, -1, 1);//top, cache, coltypes
		coltypes = (size_t*)lua_touserdata(L, -1);
		stmt = (MYSQL_STMT*)coltypes[0];
		lua_pop(L, 1);//top, cache
		lua_rawgeti(L, -1, 2);//top, cache, colnames
		if(!lua_isnil(L, -1))
			colnum = lua_objlen(L, -1); //colnum=#colnames
	}
	else {//top, utb, nil  //new cache
		stmt = mysql_stmt_init(mysql);
		if (!stmt) {
			lua_errorEx(L, "[C]sql error %d-%s\n", mysql_errno(mysql), mysql_error(mysql));
			return 0;
		}
		const char *err;
		if (mysql_stmt_prepare(stmt, query, strlen(query))) {
			err = mysql_stmt_error(stmt);
			mysql_stmt_close(stmt);
			lua_errorEx(L, "[C]sql error: %s", err);
			return 0;
		}
		MYSQL_RES *res = mysql_stmt_result_metadata(stmt);
		if (mysql_stmt_errno(stmt)) {
			err = mysql_stmt_error(stmt);
			mysql_stmt_close(stmt);
			lua_errorEx(L, "[C]sql error: %s", err);
			return 0;
		}
		lua_pop(L, 1);
		lua_createtable(L, 2, 0);//top, utb, cache
		lua_pushvalue(L, 2);//top, utb, cache ,str
		lua_pushvalue(L, -2);//top, utb, cache ,str, cache
		lua_rawset(L, -4);//top, utb, cache  utb[str]=cache
		lua_remove(L, -2); //top, cache
		if (res) {
			colnum = mysql_num_fields(res);
			if (colnum >= PARAM_MAXN) {
				mysql_stmt_free_result(stmt);
				mysql_stmt_close(stmt);
				lua_errorEx(L, "[C]sql error: too many columns %d", colnum);
			}
			coltypes = (size_t*)lua_newuserdata(L, sizeof(int*) + sizeof(int*) * colnum); //top, cache, coltypes
			lua_rawseti(L, -2, 1);//top, cache
			lua_createtable(L, colnum, 0); //top, cache, colnames
			lua_pushvalue(L, -1), lua_rawseti(L, -3, 2); 
			MYSQL_FIELD *field;
			for (int i = 1; i <= colnum; i++)
			{
				field = mysql_fetch_field_direct(res, i - 1);
				lua_pushstring(L, field->name);
				lua_rawseti(L, top + 2, i);
				switch (field->type)
				{
				case MYSQL_TYPE_TINY: case MYSQL_TYPE_SHORT: case MYSQL_TYPE_LONG:
				case MYSQL_TYPE_LONGLONG: case MYSQL_TYPE_FLOAT: case MYSQL_TYPE_DOUBLE:
					coltypes[i] = field->type; break;
				case MYSQL_TYPE_STRING: case MYSQL_TYPE_VAR_STRING:
					coltypes[i] = field->charsetnr == 63 ? MYSQL_TYPE_BLOB // binary
						: field->type; break;
				case MYSQL_TYPE_BLOB:
					coltypes[i] = field->charsetnr != 63 ? MYSQL_TYPE_VAR_STRING // text
						: field->type; break;
				default:
					mysql_stmt_free_result(stmt);
					mysql_stmt_close(stmt);
					lua_errorEx(L, "[C]sql error: unknown type of column %d", i);
				}
			}
			mysql_stmt_free_result(stmt);
		}
		else { // no result set
			coltypes = (size_t*)lua_newuserdata(L, sizeof(int*));//top, cache, coltypes
			lua_rawseti(L, -2, 1);
		}
		coltypes[0] = (size_t)stmt;
	}

	int paramn = mysql_stmt_param_count(stmt);
	if (paramn >= PARAM_MAXN)
		lua_errorEx(L, "[C]sql error: too many parameters %d", paramn);
	if (paramn != top - 2)
		lua_errorEx(L, "[C]bad argument (%d parameters expected, got %d)", paramn, top - 2);
	MYSQL_BIND binds[PARAM_MAXN];
	long long is[PARAM_MAXN]; //?
	my_bool zs[PARAM_MAXN], es[PARAM_MAXN];
	memset(binds + 1, 0, paramn * sizeof(binds[0]));

	MYSQL_BIND *bind;
	if (paramn > 0) {
		int idx;
		long long *i;
		for (int p = 1; p <= paramn; p++) {
			binds[p].buffer = is + p;
			binds[p].length = &binds[p].buffer_length;
			binds[p].is_null = zs + p, zs[p] = 0;
			binds[p].error = es + p;
			//lua2mysql
			idx = p + 2,  bind = binds + p,  i = binds[p].buffer;
			switch (lua_type(L, idx))
			{
			case LUA_TNIL:
				bind->buffer_type = MYSQL_TYPE_NULL; break;
			case LUA_TBOOLEAN:
				bind->buffer_type = MYSQL_TYPE_TINY;
				*i = lua_toboolean(L, idx);
				bind->buffer_length = 1;
				break;
			case LUA_TNUMBER: {
				double V = lua_tonumber(L, idx);
				*i = (long long)V;
				if (*i == V)
					bind->buffer_type = MYSQL_TYPE_LONGLONG;
				else
					bind->buffer_type = MYSQL_TYPE_DOUBLE, *i = *(long long*)&V;//?
				bind->buffer_length = 8;
				break;
			}
			case LUA_TSTRING:
				bind->buffer_type = MYSQL_TYPE_STRING;
				bind->buffer = (void*)lua_tostring(L, idx);
				bind->buffer_length = lua_objlen(L, idx);
				break;
			case LUA_TUSERDATA:	case LUA_TLIGHTUSERDATA:{
				const char *s = lua_toBytes(L, idx, (size_t*)bind->length);
				if (s) {
					bind->buffer_type = MYSQL_TYPE_BLOB;
					bind->buffer = (void*)s;
					break;
				}
			}
			default:
				lua_errorEx(L, "[C]unsurpported mysql param type:%s", lua_typename(L, lua_type(L, idx)));
				break;
			}
		}
	}

	if (mysql_stmt_bind_param(stmt, binds + 1))
		lua_errorEx(L, "[C]sql error: %s", mysql_stmt_error(stmt));
	if (mysql_stmt_execute(stmt))
		lua_errorEx(L, "[C]sql error: %s", mysql_stmt_error(stmt));
	if (colnum == 0) { //无返回值 return affected_rows, insert_id
		lua_pushnumber(L, mysql_stmt_insert_id(stmt));
		lua_pushnumber(L, mysql_stmt_affected_rows(stmt));
		return 2;
	}
	if (colnum != (int)mysql_stmt_field_count(stmt)) { 
		mysql_stmt_free_result(stmt);
		lua_errorEx(L, "[C]sql error: result columns inconsistent");
	}
	//mysql_stmt_store_result(stmt);  // @precise rownum 1/2 是否浪费效率? mysql_stmt_num_rows依赖mysql_stmt_store_result
	//lua_createtable(L, (int)mysql_stmt_num_rows(stmt), 0);
	//lua_createtable(L, 100, 0); // rettab data, no store_result no precise
	int col;
	const char *err;
	for (int row = 1; ; row++) //row
	{
		for (col = 1; col <= colnum; col++)
		{
			is[col] = 0;
#if _WIN32
			binds[col].buffer_type = (enum_field_types)coltypes[col];
#else
			binds[col].buffer_type = coltypes[col];
#endif
			binds[col].buffer = is + col;
			binds[col].is_null = zs + col;
			binds[col].error = es + col;
			if (coltypes[col] == MYSQL_TYPE_STRING || coltypes[col] == MYSQL_TYPE_BLOB)
				binds[col].buffer_length = 0, binds[col].length = (unsigned long*)(is + col);
			else
				binds[col].buffer_length = 8, binds[col].length = &binds[col].buffer_length;
		}
		mysql_stmt_bind_result(stmt, binds + 1);
		int fail = mysql_stmt_fetch(stmt);
		if (fail == MYSQL_NO_DATA) break;
		if (fail && fail != MYSQL_DATA_TRUNCATED){
			err = mysql_stmt_error(stmt);
			mysql_stmt_free_result(stmt);
			lua_errorEx(L, "sql error: %s", err);
			return 0;
		}

		if (row == 1)
			lua_createtable(L, 100, 0);
		lua_createtable(L, 0, colnum); // row
		for (col = 1; col <= colnum; col++)
		{
			if ((int)binds[col].buffer_type != coltypes[col]) {
				//const char *err = mysql_stmt_error(stmt);
				mysql_stmt_free_result(stmt);
				lua_errorEx(L, "sql error: different column type %d %d", coltypes[col], binds[col].buffer_type);
				return 0;
			}
			lua_rawgeti(L, top + 2, col); //getname
			//mysql2lua
			bind = binds + col;
			if (*bind->is_null)
				lua_pushnil(L);
			else switch (bind->buffer_type) {
			case MYSQL_TYPE_TINY: case MYSQL_TYPE_SHORT: case MYSQL_TYPE_LONG:
				lua_pushinteger(L, *(int*)bind->buffer); break;
			case MYSQL_TYPE_LONGLONG:
				lua_pushnumber(L, *(long long*)bind->buffer); break;
			case MYSQL_TYPE_FLOAT:
				lua_pushnumber(L, *(float*)bind->buffer); break;
			case MYSQL_TYPE_DOUBLE:
				lua_pushnumber(L, *(double*)bind->buffer); break;
			case MYSQL_TYPE_STRING: case MYSQL_TYPE_VAR_STRING: {
				if (*bind->length > 262144)
					err = mysql_stmt_error(stmt), mysql_stmt_free_result(stmt),
					lua_errorEx(L, "[C]sql error: column too long %u", *bind->length);
				char data[262144];
				bind->buffer_length = *bind->length, bind->buffer = data;
				if (mysql_stmt_fetch_column(stmt, bind, col - 1, 0))
					err = mysql_stmt_error(stmt), mysql_stmt_free_result(stmt),
					lua_errorEx(L, "[C]sql error: %s", err);
				lua_pushlstring(L, data, *bind->length); break;
			}
			case MYSQL_TYPE_BLOB: {
				if (*bind->length > 6 * 1024 * 1024)
					err = mysql_stmt_error(stmt), mysql_stmt_free_result(stmt),
					lua_errorEx(L, "[C]sql error: column too long %u", *bind->length);
				char *data = lua_newBytes(L, *bind->length);
				bind->buffer_length = *bind->length, bind->buffer = data;
				if (mysql_stmt_fetch_column(stmt, bind, col - 1, 0))
					err = mysql_stmt_error(stmt), mysql_stmt_free_result(stmt),
					lua_errorEx(L, "[C]sql error: %s", err);
				break;
			}
			default:
				lua_pushnil(L);
			}
			lua_rawset(L, -3);
		}
		lua_rawseti(L, -2, row);
	}
	mysql_stmt_free_result(stmt);// @precise rownum (2/2)
	return 1;
}
//批量句无返回值 //require CLIENT_MULTI_STATEMENTS when connect //navicat导出的需去掉 "/*注释块*/"
static int conn_runs(lua_State *L) {
	MYSQL *mysql = (MYSQL *)luaL_checkudata(L, 1, META_NAME);
	size_t len;
	char *s = (char *)lua_tolstring(L, 2, &len); 
	if (mysql_real_query(mysql, s, len)) 
		fprintf(stderr, "[C]sql error %d-%s\n", mysql_errno(mysql), mysql_error(mysql));
	return 0;
}

static int sqlConnect(lua_State *L)
{
	const char *host = lua_tostring(L,1);
	unsigned port = (unsigned)luaL_optinteger(L,2,3306);
	const char *user = lua_tostring(L,3);
	const char *pass = lua_tostring(L,4);
	const char *base = lua_tostring(L,5);
	MYSQL *mysql = (MYSQL *)lua_newuserdata(L, sizeof(MYSQL));
	mysql_init(mysql);

	if (mysql_options(mysql, MYSQL_SET_CHARSET_NAME, "utf8"))
		fprintf(stderr, "[C]error MYSQL_SET_CHARSET_NAME fail\n");
	//CLIENT_MULTI_STATEMENTS 可多语句用于runs运行复合句sql脚本
#ifndef _WIN32
	if(host[0]=='/')//unix_socket "/var/run/mysqld/mysqld.sock"
		if (!mysql_real_connect(mysql, NULL, user, pass, base, 0, host, CLIENT_MULTI_STATEMENTS))
		{
			fprintf(stderr, "[C]sql error %d-%s\n", mysql_errno(mysql), mysql_error(mysql));
			return 0;
		}
	else
#endif // !_WIN32
	if (!mysql_real_connect(mysql,host,user,pass,base,port,0, CLIENT_MULTI_STATEMENTS))
	{
		fprintf(stderr, "[C]sql error %d-%s\n", mysql_errno(mysql), mysql_error(mysql));
		return 0;
	}
	my_bool my_true = 1; //mysql 5.0.19后MYSQL_OPT_RECONNECT必须在mysql_real_connect之后,否则会被重置为默认不
	if (mysql_options(mysql, MYSQL_OPT_RECONNECT, &my_true))  //TODO重连后缓存的stmt句柄可能失效!
		fprintf(stderr, "[C]error MYSQL_OPT_RECONNECT fail\n");

	lua_pushvalue(L, lua_upvalueindex(1));// luaL_getmetatable(L, META_NAME);
	lua_setmetatable(L, -2);

	//stmt cache table
	lua_getref(L, _WeakK_ColCache);
	lua_pushvalue(L, -2);
	lua_createtable(L, 0, 0);
	lua_rawset(L, -3);
	lua_pop(L,1);

	return 1;
}

LUA_API void luaopen_mysql(lua_State *L)
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
		{ "begin",  conn_begin },
		{ "rollback", conn_rollback },
		{ "commit", conn_commit },
		{ "autocommit",	conn_autocommit },
		{ "runs", 	conn_runs },
		//{ "setoptions", 	conn_setoptions },
		//{ "skip", 	conn_skip },
		//{ "columns", 	conn_columns },//列集return{id={1,2,3,...},key={...}}
		{ NULL, NULL },
	};
	lua_regMetatable(L, META_NAME, methods, 0);
	//version info
	luaL_getmetatable(L, META_NAME); 
	lua_pushliteral(L, "LIBMYSQL_VERSION");
	lua_pushliteral(L, LIBMYSQL_VERSION);
	lua_settable(L, -3);
	lua_pushliteral(L, "LIBMYSQL_VERSION_ID");
	lua_pushnumber(L, LIBMYSQL_VERSION_ID);
	lua_settable(L, -3);
	//lua_pop(L, 1);
	//lua_register(L, "_mysql", sqlConnect);
	lua_pushcclosure(L, sqlConnect, 1);
	lua_setglobal(L, "_mysql");
}
#endif //USEMYSQL