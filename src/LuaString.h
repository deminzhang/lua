#ifndef LUASTR_H  
#define LUASTR_H  
//#include <stdio.h>
//#include <string.h>
//#include <memory.h> 
#include "LuaScript.h"

#ifndef LUAEXTEND_API
#define LUAEXTEND_API extern
#endif

LUAEXTEND_API int luaopen_stringEx(lua_State *L);

#endif