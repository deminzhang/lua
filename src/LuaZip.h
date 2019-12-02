#ifndef _LUAZIP_H_
#define _LUAZIP_H_
//#include <stdio.h>
//#include <string.h>
//#include <memory.h> 

#include "LuaTime.h"
#include "LuaScript.h"

#ifdef _WIN32
	#pragma comment(lib, "zlib.lib")		//static
	//#pragma comment(lib, "zdll.lib")		//dll
#endif

void luaopen_zip(lua_State *L);

#endif