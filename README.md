# dev

已删除x86属配

require list of libs for windows
	可安装PostgreSQL,MySQL复制相应
	
	.\lib\
	libmysql.lib	C:\Program Files\MySQL\MySQL Connector.C 6.1\lib\
	libpq.lib		C:\Program Files\PostgreSQL\9.6\lib\
	lua51.lib		luajit2.04		Makefile_win luajit
	zdll.lib
	zlib.lib		zlib-1.2.11		Makefile_win zlib-1.2.11

	.\bin\
	libeay32.dll	C:\Program Files\PostgreSQL\9.6\bin
	libiconv-2.dll	C:\Program Files\PostgreSQL\9.6\bin
	libintl-8.dll	C:\Program Files\PostgreSQL\9.6\bin
	libpq.dll		C:\Program Files\PostgreSQL\9.6\bin
	ssleay32.dll	C:\Program Files\PostgreSQL\9.6\bin
	libmysql.dll	C:\Program Files\MySQL\MySQL Connector.C 6.1\lib


luajit source add
	lua.h
	LUA_API void  (lua_sizetable) (lua_State *L, int idx); //Extra
	LUA_API void  (lua_duplicatetable) (lua_State *L, int idx); //Extra

	lj_api.c
	LUA_API void lua_sizetable(lua_State *L, int idx)
	{
	  GCtab *t;
	  t = tabV(index2adr(L, idx));
	  lua_pushnumber(L,t->asize);
	  lua_pushnumber(L,t->hmask);
	}

	LUA_API void lua_duplicatetable(lua_State *L, int idx)
	{
	  GCtab *t;
	  lj_gc_check(L);
	  t = lj_tab_dup(L, tabV(index2adr(L, idx)));
	  settabV(L, L->top, t);
	  incr_top(L);
	}

