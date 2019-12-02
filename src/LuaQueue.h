#ifndef _LUAQUEUE_H_
#define _LUAQUEUE_H_
//#include "lua.h"
//#include <math.h>
#ifdef _WIN32
#include <windows.h>
//#include <time.h>
#else
#include <unistd.h>
#include <sys/time.h>
#endif
#include "LuaScript.h"
#include "LuaTime.h"
#include "LuaCode.h"

LUA_API void luaqueue_loop(lua_State *L);
LUA_API int luaopen_queue(lua_State *L);

#endif
