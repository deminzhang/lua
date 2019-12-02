
#include "LuaPostgres.h"
#ifdef USEPOSTGRES

#define META_NAME "[PGSQL]"
#define PARAM_MAXN 128
#define PARAM_BUFFSIZE 512

//#define STRRES_TEST //DEBUG字符结果

typedef struct conn_data {
	PGconn    *pg_conn;
	unsigned int skip;
} conn_data;
typedef struct {
	Oid oid;
	char typname[11];
	short typlen;	//-1 ? var len : -2 ? : NULLend : const len
	char typcategory; //B ? bool : S ? string : N ? number : A ? array : T ? datime : U ? byte
	Oid typelem; //~0 array base
	Oid typarray; //~array ? oid : 0
} pgtype;
//select oid, typname, typlen, typcategory, typelem, typarray from pg_type where typtype = 'b' order by oid; //基本类型
//http://www.chinaitlab.com/linux/manual/database/pgsqldoc-8.1c/libpq-exec.html
//http://blog.chinaunix.net/uid-20726500-id-4926919.html

static int pgtype_cache_num=0;
static pgtype *pgtype_cache = NULL;
static char *paramValuesCache[PARAM_MAXN];
//----------------------------------------------------
static void notice_processor(void *arg, const char *message) {
	(void)arg; (void)message;
	/* arg == NULL */
}
static pgtype *getpgtype(Oid oid)
{
	for (int i = 0; i < pgtype_cache_num; ++i)
	{
		if (pgtype_cache[i].oid == oid)
			return &pgtype_cache[i];
	}
	//缓存无,现查
	//基本类型Connect时己读出,别现查了
	return NULL;
}
//lua meta----------------------------------------------------
static int conn_gc(lua_State *L) {
	conn_data *conn = (conn_data *)lua_touserdata(L, -1);
	PQfinish(conn->pg_conn);
	conn->pg_conn = NULL;
	return 0;
}
static int conn_close(lua_State *L) {
	conn_data *conn = (conn_data *)luaL_checkudata(L, 1, META_NAME);
	if (!conn->pg_conn) {
		lua_pushboolean(L, 0);
		return 1;
	}
	PQfinish(conn->pg_conn);
	conn->pg_conn = NULL;
	lua_pushboolean(L, 1);
	return 1;
}
static int conn_closed(lua_State *L) {
	conn_data *conn = (conn_data *)luaL_checkudata(L, 1, META_NAME);
	if (!conn->pg_conn)
		lua_pushboolean(L, 1);
	else
		lua_pushboolean(L, 0);
	return 1;
}
static const char *SQLbegin = "begin";
static const char *SQLrollback = "rollback";
static const char *SQLcommit = "commit";
static int conn_begin(lua_State *L) {
	conn_data *conn = (conn_data *)luaL_checkudata(L, 1, META_NAME);
	PGconn *pg_conn = conn->pg_conn;
	PGresult *res = PQexec(pg_conn, SQLbegin);
	if (res)
		PQclear(res);
	else {// error 
		//PQclear(res); //?
		lua_errorEx(L, "[C]sql error %s\n", PQerrorMessage(pg_conn));
	}
	return 0;
}
static int conn_rollback(lua_State *L) {
	conn_data *conn = (conn_data *)luaL_checkudata(L, 1, META_NAME);
	PGconn *pg_conn = conn->pg_conn;
	PGresult *res = PQexec(pg_conn, SQLrollback);
	if (res)
		PQclear(res);
	else {// error 
		//PQclear(res); //?
		lua_errorEx(L, "[C]sql error %s\n", PQerrorMessage(pg_conn));
	}
	return 0;
}
static int conn_commit(lua_State *L) {
	conn_data *conn = (conn_data *)luaL_checkudata(L, 1, META_NAME);
	PGconn *pg_conn = conn->pg_conn;
	PGresult *res = PQexec(pg_conn, SQLcommit);
	if (res)
		PQclear(res);
	else {// error 
		//PQclear(res);
		lua_errorEx(L, "[C]sql error %s\n", PQerrorMessage(pg_conn));
	}
	return 0;
}

static int conn_skip(lua_State *L) {
	conn_data *conn = (conn_data *)luaL_checkudata(L, 1, META_NAME);
	PGconn *pg_conn = conn->pg_conn;
	conn->skip = 1;
	return 1;
}

//sigle operate with returns; support outline
static int conn_run(lua_State *L) {
	conn_data *conn = (conn_data *)luaL_checkudata(L, 1, META_NAME);
	PGconn *pg_conn = conn->pg_conn;
	if (!pg_conn)
		lua_errorEx(L, "[C]sql error: not connected\n");

	const char *query = luaL_checkstring(L, 2);
	int nParams = lua_gettop(L)-2;
	if (nParams > PARAM_MAXN)
		lua_errorEx(L, "[C]sql error too many params: at most 128\n");

	char *paramValues[PARAM_MAXN];
	memset(paramValues, 0, PARAM_MAXN * sizeof(char*));
	int idx;
	for (int i = 0; i < nParams; i++)
	{
		paramValues[i] = paramValuesCache[i];
		idx = i + 3;
		switch (lua_type(L, idx))
		{
		//case LUA_TNIL:
			//lua_errorEx(L, "[C]invalid param nil");
			//strcpy(paramValues[i], "null"); //TODO 这不行好象
		case LUA_TBOOLEAN:
			strcpy(paramValues[i], lua_toboolean(L, idx) ? "t" : "f");
			break;
		case LUA_TTABLE:
			strcpy(paramValues[i], "{");
			lua_pushvalue(L, idx);
			for (int n = 1; n <= luaL_getn(L, -1); n++)
			{
				lua_rawgeti(L, -1, n);
				int stop = 0;
				switch (lua_type(L, -1))
				{
				case LUA_TNIL:case LUA_TNONE:
				case LUA_TTABLE:	//暂不支持2维
					stop = 1;
					break;
				case LUA_TBOOLEAN:
					if (n > 1)
						strcat(paramValues[i], ",");
					strcat(paramValues[i], lua_toboolean(L, -1) ? "t" : "f");
					break;
				case LUA_TSTRING:
					if (n > 1)
						strcat(paramValues[i], ",");
					strcat(paramValues[i], "\"");
					strcat(paramValues[i], lua_tostring(L, -1));
					strcat(paramValues[i], "\"");
					break;
				case LUA_TNUMBER:
					if (n > 1)
						strcat(paramValues[i], ",");
					strcat(paramValues[i], lua_tostring(L, -1));
					break;
				case LUA_TUSERDATA:	case LUA_TLIGHTUSERDATA:
				default:
					lua_errorEx(L, "unsurpported sql param type:%s", lua_typename(L, lua_type(L, idx)));
					break;
				}
				lua_pop(L, 1);
				if (stop) break;
			}
			lua_pop(L, 1);
			strcat(paramValues[i], "}");
			break;
		case LUA_TSTRING: case LUA_TNUMBER:
			strcpy(paramValues[i], lua_tostring(L, idx));
			break;
		case LUA_TUSERDATA:	case LUA_TLIGHTUSERDATA:
		default:
			lua_errorEx(L, "[C]unsurpported sql param type:%s", lua_typename(L, lua_type(L, idx)));
			break;
		}
	}
	PGresult *res;
	res = PQexecParams(pg_conn, query, nParams,           //* 一个参数
		NULL,        //* 让后端推导参数类型
		(const char *const *)paramValues,
		NULL,        //* 因为是文本，所以不需要参数长度
		NULL,        //* 缺省是参数都是文本
#ifdef STRRES_TEST
		0);          //* 0要求获取字符结果 //仅用测试,给lua用效率不好
#else
		1);          //* 1要求获取二进制结果
#endif

	if (res && PQresultStatus(res) == PGRES_COMMAND_OK) {  // no tuples returned 
		lua_pushstring(L, PQcmdTuples(res));
		int d = lua_tointeger(L, -1);
		lua_pushinteger(L, d);
		PQclear(res);
		return 1;
	}
	else if (res && PQresultStatus(res) == PGRES_TUPLES_OK) // tuples returned 
	{
		int tuple_num = PQntuples(res);//行数
		if (tuple_num == 0) return 0;

		lua_createtable(L, tuple_num, 0);
		int field_num = PQnfields(res);//列数
		Oid oid;
		char *fieldname, *val;
		pgtype *type, *btype;
		int j;
		for (int i = 0; i<tuple_num; ++i)
		{
			lua_createtable(L, 0, field_num);
			for (j = 0; j < field_num; ++j)
			{
				if (!PQgetisnull(res, i, j)) //if (PQgetisnull(res, i, j)) continue;
				{
					oid = PQftype(res, j);
					fieldname = PQfname(res, j);
					type = getpgtype(oid); //连联时生成的缓存
					if (!type) {
						PQclear(res);
						lua_errorEx(L, "error invalid oid: %d no type\n", oid);
						return 1;
					}
					val = PQgetvalue(res, i, j);
					int len = PQgetlength(res, i, j);
					lua_pushstring(L, fieldname); //push k
#ifdef STRRES_TEST
					if (type->typelem) { //isArray
						btype = getpgtype(type->typelem);
						int n;
						char* p; //ptr
						char* s; //sub string
						int len = strlen(val);
						if(len<3) //{}
							lua_createtable(L, 0, 0);
						else
							switch (btype->typcategory) {
							case 'B': //bool
								n = len/2;
								lua_createtable(L, n, 0);
								n = 1;
								int pn;
								for (pn = 1; pn < len; pn += 2)//{t}3,{t,f}5
								{
									char b = val[pn];
									lua_pushboolean(L, b=='t' ? 1 : 0);
									lua_rawseti(L, -2, n);
									n++;
								}
								break;
							case 'N': //number
								n = 1;
								lua_createtable(L, 0, 0);
								p = strtok(val, "{"); //cut'{'
								p[strlen(p) - 1] = '\0'; //cut'}'
								while (p) {
									p = strtok(n==1 ? p : NULL, ",");
									if (p)
									{
										//lua_pushnumber(L, atof(p));
										lua_pushstring(L, p);
										double d = lua_tonumber(L, -1);
										lua_pop(L, 1);
										lua_pushnumber(L, d);
										lua_rawseti(L, -2, n);
										n++;
									}
								}
								break;
							case 'S': //string
								n = 1;
								lua_createtable(L, 0, 0);
								p = strtok(val, "{"); //cut'{'
								p[strlen(p) - 1] = '\0'; //cut'}'
								while (p) {
									char c = p[0];
									if (c == '\0')
										break;
									else if (c == '"') //"1 lead" end"
									{
										p++;//cut1"
										if (p[0] == '"') //"2  ""
										{
											lua_pushliteral(L, "");
											lua_rawseti(L, -2, n);
											n++;
											p++;//cut2"
											c = p[0];
											if (c == '\0')
												p=NULL;
											else if (c == ',')
												p++; //cut ,
										}
										else
										{
											s = p;
											for (;;)
											{
												p++;
												if (p[0] == '"') //"2
												{
													p[0] = '\0';
													lua_pushstring(L, s);
													lua_rawseti(L, -2, n);
													n++;
													p++; //cut "2

													c = p[0];
													if (c == '\0')
														p=NULL;
													else if (c == ',')
														p++; //cut','

													break;
												}

											}
										}
									}
									else //lead no " end,
									{
										s = p;
										for(;;)
										{
											if(strlen(p)>0)
											{
												p++;
												if (p[0] == ',') //"2
												{
													p[0] = '\0'; //cut ,
													lua_pushstring(L, s);
													lua_rawseti(L, -2, n);
													n++;
													p++; //next
													c = p[0];
													if (c == '\0')
														p = NULL;
													else if (c == ',')
														p++; //cut','
													break;
												}
											}
											else
												{
													lua_pushstring(L, s);
													lua_rawseti(L, -2, n);
													n++;
													break;
												}
										}
									}
								}
								break;
							default:
								lua_pushstring(L, val);
								break;
							}
					}
					else
					{
						switch (type->typcategory)
						{
						case 'B': //bool
							lua_pushboolean(L, strcmp(val, "f") ? 1 : 0);
							break;
						case 'N': //number
							//sscanf(val, "%lf", &d);
							//lua_pushnumber(L, atof(val)); // fuck atof("1")==0 不精确
							lua_pushstring(L, val);
							double d = lua_tonumber(L, -1);
							lua_pop(L, 1);
							lua_pushnumber(L, d);
							break;
						case 'S': //string
							lua_pushstring(L, val);
							break;
						default: //other
							lua_pushstring(L, val);
							break;
						}
						//select to_timestamp(0) as datetime;
						//select extract(epoch from timestamp '1970-01-01 08:00:00+08')
					}
#else
					//printf("%s=%d\n", fieldname, R32l(val));
					switch (oid) {
					case 16: // bool
						lua_pushboolean(L, (int)val[0]); break;
					case 21: // int2
						lua_pushnumber(L, R16l(val)); break;
					case 23: case 26: // int4 oid
						lua_pushnumber(L, R32l(val)); break;
					case 20: //int8
						lua_pushnumber(L, R64l(val)); break;
					case 1114: {// timestamp  //TODO temp int8 timestamp write with string but read as int8 now.
						char s0[27];
						//int8todatestr(s0, R64l(val));
						//lua_pushstring(L, s0);
						lua_pushnumber(L, R64l(val));
						break;
					}
					case 700: // float4 
						lua_pushnumber(L, RFll(val)); break;
					case 701: // float8		790 money
						lua_pushnumber(L, RDbl(val)); break;
					//case 650: case 869: // cidr inet
					case 18: case 19: case 25: case 1042: case 1043:  // char name text bpchar varchar
						lua_pushlstring(L, val, len); break;
					default:
						if (type->typelem) //elem oid of array
							//code of array example:{true,false,true}
							//00000001 int4 0?empty:have
							//00000000 
							//00000010 typelem
							//00000003 num of array
							//00000001 start
							//00000001 len of t[1]
							//01	     t[1]
							//00000001 len of t[1]
							//00	     t[2]
							//00000001 len of t[1]
							//01	     t[3]
							if(R32l(val)==0) //empty table
								lua_createtable(L, 0, 0);
							else {
								//Oid elem = (Oid)val32b(val + 8); //==type->typelem
								int n = R32l(val + 12); //num of array
								int l = R32l(val + 16);
								int h = l + n;
								lua_createtable(L, n, 0);
								char *p;
								int len1;
								for (p = val + 20; l < h; l++)
								{
									len1 = R32l(p); //元素长度
									p += 4; //指定元素
									switch (type->typelem)
									{
									case 16: // bool
										lua_pushboolean(L, (int)p[0]); break;
									case 21: // int2
										lua_pushnumber(L, R16l(p)); break;
									case 23: case 26: // int4 oid
										lua_pushnumber(L, R32l(p)); break;
									case 20: //int8
										lua_pushnumber(L, R64l(p)); break;
									case 1114: //timestamp
										{
										//char s0[27];
											//int8todatestr(s0, R64l(val));
											//lua_pushstring(L, s0);
										}
										lua_pushnumber(L, R64l(val));
										break;
									case 700: // float4
										lua_pushnumber(L, RFll(p)); break;
									case 701: // float8		790 money
										lua_pushnumber(L, RDbl(p)); break;
									//case 650: case 869: // cidr inet
									case 18: case 19: case 25: case 1042: case 1043:  // char name text bpchar varchar
										lua_pushlstring(L, p, len1); break;
									default:
										lua_errorEx(L, "unsupport type oid=%d\n", oid);
									}
									lua_rawseti(L, -2, l);
									p += len1;
								}
							}
						else
							lua_errorEx(L, "unsupport type oid=%d\n", oid);
						break; 
					}
#endif
					lua_rawset(L, -3); //[k]=v
				}
			}
			lua_rawseti(L, -2, i + 1);
		}
		PQclear(res);
		return 1;
	}
	else {// error 
		PQclear(res);
		lua_errorEx(L, "[C]sql error %s\n", PQerrorMessage(pg_conn));
	}
	return 0;
}
//multiply operate; no returns; unsupport outline
static int conn_runs(lua_State *L) {
	conn_data *conn = (conn_data *)luaL_checkudata(L, 1, META_NAME);
	PGconn *pg_conn = conn->pg_conn;
	if (!pg_conn) {
		luaL_where(L, 1);
		lua_pushliteral(L, "error run database: not connected\n");
		lua_concat(L, 2);
		lua_error(L);
	}
	const char *query = luaL_checkstring(L, 2);

	PGresult *res = PQexec(pg_conn, query);
	if (res && PQresultStatus(res) == PGRES_COMMAND_OK) {  // no tuples returned 
														   //lua_pushnumber(L, atof(PQcmdTuples(res)));
		PQclear(res);
		return 0;
	}
	else if (res && PQresultStatus(res) == PGRES_TUPLES_OK) // tuples returned 
	{
		PQclear(res);
		return 0;
	}
	else {// error 
		PQclear(res);
		lua_errorEx(L, "[C]sql error %s\n", PQerrorMessage(pg_conn));
	}
	return 0;
}
//lua global----------------------------------------------------
static int sqlConnect(lua_State *L) {
	const char *host = luaL_optstring(L, 1, NULL);
	const char *port = luaL_optstring(L, 2, NULL);
	const char *user = luaL_optstring(L, 3, NULL);
	const char *pass = luaL_optstring(L, 4, NULL);
	const char *base = luaL_optstring(L, 5, NULL);

	//PGconn *pg_conn = PQsetdbLogin(host, port, NULL, NULL, base, user, pass);
	char conninfo[256];	//host=localhost hostaddr=127.0.0.1
	sprintf(conninfo, "host=%s port=%s dbname=%s user=%s password=%s connect_timeout=%d",
		host, port, base, user, pass, 200);
	PGconn *pg_conn = PQconnectdb(conninfo);

	if (PQstatus(pg_conn) == CONNECTION_BAD) {
		//fprintf(stderr, "error connecting to database: %s\n", PQerrorMessage(pg_conn));
		luaL_where(L, 1);
		lua_pushstring(L, PQerrorMessage(pg_conn));
		PQfinish(pg_conn);
		lua_concat(L, 2);
		lua_error(L);
		return 0;
	}
	PQsetNoticeProcessor(pg_conn, notice_processor, NULL);
	//make cache of base type
	if (pgtype_cache == NULL)
	{
		char stmt[] = "select oid, typname, typlen, typcategory, typelem, typarray from pg_type where typtype = 'b' order by oid";
		PGresult *res;
		res = PQexecParams(pg_conn, stmt, 0, NULL, NULL, NULL, NULL, 1); //* 1要求获取二进制结果

		if (PQresultStatus(res) == PGRES_TUPLES_OK) {
			int tuple_num = PQntuples(res);//行数
			pgtype_cache_num = tuple_num;
			pgtype_cache = (pgtype *)malloc(tuple_num * sizeof(pgtype));
			for (int i = 0; i < tuple_num; ++i)
			{
				char *ptr = PQgetvalue(res, i, 0);
				Oid oid = (Oid)ntohl(*((u_long *)ptr));
				char * name = PQgetvalue(res, i, 1);
				ptr = PQgetvalue(res, i, 2);
				short typlen = (short)ntohs(*((u_short *)ptr)); ;
				char typcategory = PQgetvalue(res, i, 3)[0];
				ptr = PQgetvalue(res, i, 4);
				Oid typelem = (Oid)ntohl(*((u_long *)ptr));
				ptr = PQgetvalue(res, i, 5);
				Oid typarray = (Oid)ntohl(*((u_long *)ptr));

				pgtype_cache[i].oid = oid;
				strncpy(pgtype_cache[i].typname, name, 11);
				pgtype_cache[i].typlen = typlen;
				pgtype_cache[i].typcategory = typcategory;
				pgtype_cache[i].typelem = typelem;
				pgtype_cache[i].typarray = typarray;
			}
			PQclear(res);
		}
		else
		{
			//fprintf(stderr, "select pg_type error: %s\n", PQerrorMessage(pg_conn));
			luaL_where(L, 1);
			lua_pushstring(L, PQerrorMessage(pg_conn));
			PQclear(res);
			PQfinish(pg_conn);
			lua_concat(L, 2);
			lua_error(L);
			return 0;
		}
	}

	conn_data *conn = (conn_data *)lua_newuserdata(L, sizeof(conn_data));
	conn->pg_conn = pg_conn;
	lua_pushvalue(L, lua_upvalueindex(1)); //luaL_getmetatable(L, META_NAME);
	lua_setmetatable(L, -2);
	return 1;
}
//global
LUA_API void luaopen_postgres(lua_State *L)
{
	//init cache
	memset(paramValuesCache, 0, PARAM_MAXN * sizeof(char*));
	for (int i = 0; i < PARAM_MAXN; i++)
		paramValuesCache[i] = (char*)malloc(PARAM_BUFFSIZE * sizeof(char));

	//reg2lua-----------------------------------------------------------
	struct luaL_Reg methods[] = {
		{ "__gc",   conn_gc }, //userdata use
		{ "close",  conn_close },
		{ "closed", conn_closed },
		{ "begin",  conn_begin },
		{ "rollback",conn_rollback },
		{ "commit", conn_commit },
		{ "run", 	conn_run },
		{ "runs", 	conn_runs },
		//{ "autocommit",	conn_autocommit },
		//{ "skip", 	conn_skip },
		//{ "columns", 	conn_columns },//列集return{id={1,2,3,...},key={...}}
		{ "time", 	lua_timestr },
		{ NULL, NULL },
	};
	lua_regMetatable(L, META_NAME, methods, 0);
	//version info
	luaL_getmetatable(L, META_NAME);
	lua_pushliteral(L, "PQlibVersion");
	lua_pushnumber(L, PQlibVersion());
	lua_settable(L, -3);
	//lua_pop(L, 1);
	//lua_register(L, "_pgsql", sqlConnect);
	lua_pushcclosure(L, sqlConnect, 1);
	lua_setglobal(L, "_pgsql");
}

#endif // USEPOSTGRES