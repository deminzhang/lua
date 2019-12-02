#ifndef _LUAMYSQL_H
#define _LUAMYSQL_H

#ifdef _WIN32
#define USEMYSQL
#include <winsock2.h>
#pragma comment(lib,"libmysql.lib")
//#pragma comment(lib,"mysqlclient.lib")	//_MSC_VER must match

#else //http://blog.chinaunix.net/uid-26758020-id-3289515.html
#endif
//#include <string.h>
//#include <stdio.h>
#include <malloc.h>
#include "mysql.h"
#include "LuaScript.h"

LUA_API void luaopen_mysql(lua_State *L);

#endif