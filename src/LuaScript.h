#ifndef _LUASCRIPT_H  
#define _LUASCRIPT_H  
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <memory.h> 
#include <math.h>
#include <time.h> 
#include "base.h"
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include "luajit.h"
#include "LuaString.h" 

//luaplus---------------------------------------------------------

#if !defined LUA_VERSION_NUM || LUA_VERSION_NUM==501 //Adapted from Lua 5.2
LUALIB_API void luaL_setfuncs(lua_State *L, const luaL_Reg *l, int nup);
#endif

//new a bytes-usedata with most method of string //stack+1
LUA_API char *lua_newBytes(lua_State *L, int size);
//set really used lenth of reused bytes-usedata
LUA_API void lua_setBytesLen(lua_State *L, int idx, size_t len);
//get string or userdata string
LUA_API const char *(lua_toBytes)(lua_State *L, int idx, size_t *len);

//rawset field //stack-1
//static inline void lua_rawsetk(lua_State *L, int idx, const char *k)
//{
//	lua_pushstring(L, k), lua_insert(L, -1), lua_rawset(L, idx>0 ? idx : idx - 1);
//}
////rawset field //stack+1
//static inline void lua_rawgetk(lua_State *L, int idx, const char *k)
//{
//	lua_pushstring(L, k), lua_rawget(L, idx>0 ? idx : idx - 1);
//}

//lua_error apply outline
LUA_API int lua_errorEx(lua_State *L, const char *format, ...);

//reg a common metatable of userdata with if hang a hide table which save properties
LUA_API void lua_regMetatable(lua_State *L, char * type, luaL_Reg *methods, int hangtab);

//set a weakv ref userdata by ptr. if use C find lua
LUA_API void lua_setUserdata(lua_State *L);
//get a userdata from weakv by ptr. if use C find lua
LUA_API void lua_getUserdata(lua_State *L, void*p);

//get element from hangtable of userdata //stack+1
LUA_API void lua_getfieldUD(lua_State *L, int idx, char *name);
//set element from hangtable of userdata  //stack-1
LUA_API void lua_setfieldUD(lua_State *L, int idx, char *name);


//open
LUA_API void luaopen_extend(lua_State *L);

#ifdef _DEBUG //ต๗สิ
void luaValueDump(lua_State *L, int idx);
void luaStackDump(lua_State *L);
#endif
#endif