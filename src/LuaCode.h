#ifndef _Code_H_
#define _Code_H_
//#include <stdio.h>
//#include <string.h>
//#include <memory.h> 
#include "LuaScript.h"

LUA_API int lua_encode(lua_State *L);
LUA_API int lua_decode(lua_State *L);

#endif