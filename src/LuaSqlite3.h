#ifndef _LUASQLITE_H
#define _LUASQLITE_H

#ifdef _WIN32
#define USESQLITE3
#endif

#include "LuaScript.h"
#include "sqlite3.h"


LUA_API void luaopen_sqlite3(lua_State *L);


#endif