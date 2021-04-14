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
//#include "luajit.h"
#include "LuaString.h" 

#ifndef LUAEXTEND_API
#define LUAEXTEND_API extern
#endif

//luaplus---------------------------------------------------------

//new a bytes-usedata with most method of string //stack+1
LUAEXTEND_API char *lua_newBytes(lua_State *L, int size);
//set really used lenth of reused bytes-usedata
LUAEXTEND_API void lua_setBytesLen(lua_State *L, int idx, size_t len);
//get string or userdata string
LUAEXTEND_API const char *(lua_toBytes)(lua_State *L, int idx, size_t *len);

//lua_error apply outline
LUAEXTEND_API int lua_errorEx(lua_State *L, const char *format, ...);

//reg a common metatable of userdata with if hang a hide table which save properties
LUAEXTEND_API void lua_regMetatable(lua_State *L, char * type, luaL_Reg *methods, int hangtab);

//set a weakv ref userdata by ptr. if use C find lua
LUAEXTEND_API void lua_setUserdata(lua_State *L);
//get a userdata from weakv by ptr. if use C find lua
LUAEXTEND_API void lua_getUserdata(lua_State *L, void*p);

//get element from hangtable of userdata //stack+1
LUAEXTEND_API void lua_getfieldUD(lua_State *L, int idx, char *name);
//set element from hangtable of userdata  //stack-1
LUAEXTEND_API void lua_setfieldUD(lua_State *L, int idx, char *name);

LUAEXTEND_API int lua_stackDump(lua_State* L);

//open
LUAEXTEND_API int luaopen_extend(lua_State *L);

#endif