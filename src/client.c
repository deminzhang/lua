#define LUA_LIB

#include <stdio.h>
#include <stdlib.h>  
#include <math.h>
#ifdef __cplusplus
#include "lua.hpp"
extern "C" {
#endif
#include "LuaNet.h" //win front because #include <winsock2.h> must front
#include "LuaScript.h"
#include "LuaTime.h"
#include "LuaCode.h"
#include "LuaQueue.h"
//#include "LuaSqlite3.h"
//#include "LuaZip.h"
#ifdef __cplusplus
}
#endif //__cplusplus


#ifdef _WIN32
	#include <winternl.h>
	//#pragma comment(lib, "lua51.lib")		//lua
	
	//#pragma comment(lib, "zlib.lib")		//static
	//#pragma comment(lib, "zdll.lib")		//dll


	#define OS "windows"
	#ifdef _WIN64
		#define ARCH "x64"
	#else
		#define ARCH "x86"
	#endif
	#ifdef _DEBUG
	#else
	#endif
	#ifdef _MSC_VER //>=
	#else
	#endif
#else
	#include <unistd.h>
	#include <sys/prctl.h>
	#include <sys/stat.h>
	#include <sys/types.h>
	#include <sys/wait.h>
	#include <pwd.h>
	#define MAX_PATH        260
	#define OS "linux"
	#ifdef __x86_64
		#define ARCH "x64"
	#else
		#define ARCH "x86"
	#endif
#endif //_WIN32

static int lua_sleep(lua_State *L)
{
	int ms = luaL_optinteger(L, 1, 0);
	usleep((ms>0 ? ms : 0)*1000);
	return 0;
}
//--main------------------------------------------------------

LUA_API int luaopenEx(lua_State *L)
{
	lua_register(L, "_now", lua__now);
	lua_register(L, "_encode", lua_encode);
	lua_register(L, "_decode", lua_decode);
	lua_register(L, "_timestr", lua_timestr);
	lua_register(L, "_time", lua__time);
	luaopen_extend(L);
	luaopen_queue(L);
	//luaopen_zip(L);
	luaopen_net(L, 0);
#ifdef USESQLITE3
	luaopen_sqlite3(L);
#endif

	//os----------------------------------
	lua_getglobal(L, "os");
	lua_pushcfunction(L, lua_sleep);
	lua_setfield(L, -2, "sleep");
	lua_pushcfunction(L, lua_utc);
	lua_setfield(L, -2, "utc");
	lua_pushcfunction(L, lua_now);
	lua_setfield(L, -2, "now");
	
	//os.info----------------------------------
	lua_createtable(L, 0, 1);
	lua_pushliteral(L, OS);
	lua_setfield(L, -2, "system");
	lua_pushliteral(L, ARCH);
	lua_setfield(L, -2, "arch");
	lua_setfield(L, -2, "info");
	lua_pop(L, 1); //pop os
	//check stack top==0
	int topidx = lua_gettop(L);
	if (topidx){
		fprintf(stderr, "[C]Warning:lua_gettop()=%d. Maybe some init defective\n", topidx);
		lua_close(L);
		for(;;) usleep(9999);
	}
	return 0;
}
