#pragma once

#include "LuaScript.h"

/*二选一用*/
/*库直接注册到_G[name]=库*/
LUAEXTEND_API int luaopen_protobuf_G(lua_State* L, const char*name);
/*库=require("注册的库名")*/
LUAEXTEND_API int luaopen_protobuf(lua_State* L);
