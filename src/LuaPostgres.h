#ifndef _LUAPOSTGRES_H
#define _LUAPOSTGRES_H

#ifdef _WIN32
#define USEPOSTGRES
#include <winsock2.h>
#pragma comment(lib, "libpq.lib")	//postgresql
#else
#include <arpa/inet.h>
#endif
//#include <stdlib.h>
//#include <stdio.h>
#include "libpq-fe.h"
#include "LuaScript.h"
#include "LuaTime.h"

LUA_API void luaopen_postgres(lua_State *L);

#endif