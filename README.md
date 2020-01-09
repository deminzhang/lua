# dev

1.已删除x86属配,只保留x64版本

2.require list of libs for windows
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

3.headFiles 
	lauxlib.h   lua.h    luaconf.h  lualib.h   lua.hpp  luajit.h ->luajit2
	sqlite3.h   sqlite3.c
	zconf.h zlib.h
	mysql/**			-> C:\Program Files\MySQL\MySQL Connector.C 6.1\include
	libpq-fe.h  pg_config_ext.h  postgres_ext.h	-> C:\Program Files\PostgreSQL\9.6\include

4.luajit source add

	lua.h:

	LUA_API void  (lua_sizetable) (lua_State *L, int idx); //Extra
	LUA_API void  (lua_duplicatetable) (lua_State *L, int idx); //Extra

	lj_api.c:
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

