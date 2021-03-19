#include "LuaScript.h"

static int _WeakV_PTR2UD; //PTR find userdata C对象指定找对应userdata
static int _WeakK_UD_PROPERTY; //property table of userdata [ud] = {} userdata挂载附加属性表
static int _BytesMeta; //metatable of bytes
static int _WeakK_BytesLenth; //used lenth of bytes

//lua extend-----------------------------------------------------------
static int table_new(lua_State *L) {
	int narr = luaL_optinteger(L, 1, 0);
	int nrec = luaL_optinteger(L, 2, 0);
	lua_createtable(L, narr<0 ? 0 : narr, nrec<0 ? 0 : nrec);
	return 1;
}

static int table_size(lua_State* L)
{
	if (!lua_istable(L, 1))
		lua_errorEx(L, "#1 must table for getsize");
	lua_sizetable(L, 1); //TODO改的lua
	return 2;
}

#ifdef LUAJIT_VERSION
static int table_duplicate(lua_State *L)
{
	if (!lua_istable(L, 1))
		lua_errorEx(L, "#1 must table for duplicate");
	lua_duplicatetable(L, 1);
	return 1;
}
//#else
#endif // LUAJIT_VERSION

//return wk[ud] and wk[ud][k] or meta[k]
//upv{_WeakK_UD_PROPERTY}
static int lua_userdata_index(lua_State *L)
{
	//userdata,k
	if (!lua_isuserdata(L, 1)) //ud,k
		lua_errorEx(L, "#1 must be userdata");
	lua_pushvalue(L, lua_upvalueindex(1));//lua_getref(L, _WeakK_UD_PROPERTY);//ud,k,wk
	lua_pushvalue(L, 1);
	lua_rawget(L, -2);
	if (!lua_isnil(L, -1)) {
		lua_pushvalue(L, 2);
		lua_rawget(L, -2);
	}
	if (lua_isnil(L, -1)) {
		lua_getmetatable(L, 1);
		lua_pushvalue(L, 2);
		lua_rawget(L, -2);
	}
	return 1;
}
//if not wk[t] then wk[t] = {} end //wk[t][k] = v
//upv{_WeakK_UD_PROPERTY}
static int lua_userdata_newindex(lua_State *L)
{
	//userdata,k,v
	if (!lua_isuserdata(L, 1))
		lua_errorEx(L, "#1 must be userdata");
	lua_pushvalue(L, lua_upvalueindex(1));//lua_getref(L, _WeakK_UD_PROPERTY); //ud,k,v,wk
	lua_pushvalue(L, 1); //ud,k,v,wk,ud
	lua_rawget(L, -2);  //ud,k,v,wk,tb?
	int newtb = lua_isnil(L, -1);
	if (newtb)
		lua_createtable(L, 0, 1);//userdata,k,v,wk,nil,tb  //else userdata,k,v,wk,tb
	lua_pushvalue(L, 2);
	lua_pushvalue(L, 3);
	lua_rawset(L, -3); //tb[k] = v
	if (newtb)//userdata,k,v,wk,nil,tb //else userdata,k,v,wk,tb
	{
		lua_pushvalue(L, 1); //userdata, k, v, wk, nil, tb, userdata
		lua_replace(L, -3); //userdata, k, v, wk, userdata, tb 
		lua_rawset(L, -3); //userdata, k, v, wk[userdata]=tb
	}
	return 0;
}
//return wk[t]
//upv{_WeakK_UD_PROPERTY}
static int lua_userdata_property(lua_State *L)
{
	//userdata,k,v
	if (!lua_isuserdata(L, 1))
		lua_errorEx(L, "#1 must be userdata");
	lua_pushvalue(L, lua_upvalueindex(1));//lua_getref(L, _WeakK_UD_PROPERTY);
	lua_pushvalue(L, 1);
	lua_rawget(L, -2);
	return 1;
}

static int lua_userdata_tostring(lua_State *L)
{
	if (!lua_isuserdata(L, 1))
		lua_errorEx(L, "#1 must be userdata");
	lua_getfieldUD(L, 1, "._name");
	if (!lua_isnil(L, -1)) return 1; //first set after read
	//size_t pk = (size_t)lua_topointer(L, 1);
	lua_getmetatable(L, 1);
	lua_getfield(L, -1, "_TYPE");
	const char*t = lua_tostring(L, -1);
	char s[32];
	sprintf(s, "%s: 0x%p\0", t, lua_topointer(L, 1));
	lua_pushstring(L, s);
	lua_pushvalue(L, -1);
	lua_setfieldUD(L, 1, "._name");
	return 1;
}

//upv{_WeakK_BytesLenth}
static int lua_bytesLen(lua_State*L)
{
	lua_pushvalue(L, lua_upvalueindex(1));//lua_getref(L, _WeakK_BytesLenth);
	lua_pushvalue(L, 1);
	lua_rawget(L, -2);
	size_t len = lua_isnil(L, -1) ? lua_objlen(L, -2) : lua_tointeger(L, -1);
	lua_pushinteger(L, len);
	return 1;
}

static int lua_bytes2str(lua_State*L)
{
	if (lua_isstring(L, 1)) return 1;
	size_t len; const char *s = lua_toBytes(L, 1, &len);
	size_t i = indexn0(luaL_optint(L, 2, 1), len);
	size_t j = indexn(luaL_optint(L, 3, -1), len);
	lua_pushlstring(L, s + i, j - i);
	return 1;
}

static int lua_str_tostring(lua_State*L)
{
	if (lua_isstring(L, 1)) return 1;
	size_t len; const char *s = lua_toBytes(L, 1, &len);

	for (int x = 0; x < len; x++)
		lua_pushfstring(L, "%d ", (unsigned char)s[x]);
	lua_concat(L, len);
	return 1;
}


//C api extend-----------------------------------------------------------
#if !defined LUA_VERSION_NUM || LUA_VERSION_NUM==501
LUALIB_API void luaL_setfuncs(lua_State *L, const luaL_Reg *l, int nup) {
	luaL_checkstack(L, nup, "too many upvalues");
	for (; l->name != NULL; l++) {  /* fill the table with given functions */
		int i;
		for (i = 0; i < nup; i++)  /* copy upvalues to the top */
			lua_pushvalue(L, -nup);
		lua_pushcclosure(L, l->func, nup);  /* closure with those upvalues */
		lua_setfield(L, -(nup + 2), l->name);
	}
	lua_pop(L, nup);  /* remove upvalues */
}
#endif

LUA_API char *lua_newBytes(lua_State *L, int size)
{
	char *u = (char*)lua_newuserdata(L, size);
	lua_getref(L, _BytesMeta);
	lua_setmetatable(L, -2);
	lua_setBytesLen(L, -1, size);
	return u;
}

LUA_API void lua_setBytesLen(lua_State *L, int idx, size_t len)
{
	lua_getref(L, _WeakK_BytesLenth);
	lua_pushvalue(L, idx>0 ? idx : idx - 1);
	lua_pushinteger(L, len);
	lua_rawset(L, -3);
	lua_pop(L, 1);
}

LUA_API const char *lua_toBytes(lua_State *L, int idx, size_t *len)
{
	if (lua_isstring(L, idx))
		return lua_tolstring(L, idx, len);
	else if (lua_isuserdata(L, idx)) {
		*len = lua_objlen(L, idx);
		lua_getmetatable(L, idx);
		lua_getref(L, _BytesMeta);
		if (lua_equal(L, -1, -2)) {
			lua_pop(L, 2);
			lua_getref(L, _WeakK_BytesLenth);
			lua_pushvalue(L, idx>0 ? idx : idx - 1);
			lua_rawget(L, -2);
			if (!lua_isnil(L, -1))
				*len = lua_tointeger(L, -1);
			lua_pop(L, 2);
			return (const char *)lua_touserdata(L, idx);
		}
	}
	lua_errorEx(L, "# must be string or bytes");
	return NULL;
}

LUA_API int lua_errorEx(lua_State *L, const char *format, ...) {
	for (int x = 1; luaL_where(L, x), !lua_tostring(L, -1)[0] && x < 10; x++);
	va_list va; va_start(va, format), lua_pushvfstring(L, format, va), va_end(va);
	lua_concat(L, 2);
	return lua_error(L);
}

LUA_API void lua_regMetatable(lua_State *L, char * type, luaL_Reg *methods, int hangtab)
{
	luaL_newmetatable(L, type);
	lua_pushstring(L, type);
	lua_setfield(L, -2, "_TYPE");
	lua_pushcclosure(L, lua_userdata_tostring, 0);
	lua_setfield(L, -2, "__tostring");
	if (methods != NULL) {
		lua_pushvalue(L, -1);	//metatable
		luaL_setfuncs(L, methods, 1);
	}
	if (hangtab) {
		lua_getref(L, _WeakK_UD_PROPERTY);
		lua_pushcclosure(L, lua_userdata_property, 1);// lua_pushcfunction(L, lua_userdata_property);
		lua_setfield(L, -2, "_getProps");
		lua_getref(L, _WeakK_UD_PROPERTY);
		lua_pushcclosure(L, lua_userdata_index, 1);//lua_pushcfunction(L, lua_userdata_index);
		lua_setfield(L, -2, "__index");
		lua_getref(L, _WeakK_UD_PROPERTY);
		lua_pushcclosure(L, lua_userdata_newindex, 1);//lua_pushcfunction(L, lua_userdata_newindex);
		lua_setfield(L, -2, "__newindex");
	}
	else{
		lua_pushvalue(L, -1);
		lua_setfield(L, -2, "__index");
	}
	lua_pop(L, 1);
}

LUA_API void lua_setUserdata(lua_State *L)
{
	if (!lua_type(L, -1) == LUA_TUSERDATA) {
		lua_errorEx(L, "need userdata");
		return;
	}
	size_t pk = (size_t)lua_topointer(L, -1);
	lua_getref(L, _WeakV_PTR2UD);
	lua_pushnumber(L, (lua_Number)pk);	//k=p
	lua_pushvalue(L, -3); //v=o
	lua_rawset(L, -3);	//weakv[k]=o
	lua_pop(L, 1); //pop weakv top=o
}

LUA_API void lua_getUserdata(lua_State *L, void*p)
{
	lua_getref(L, _WeakV_PTR2UD);//wv
	size_t pk = (size_t)p;
	lua_pushnumber(L, (lua_Number)pk);//wv,k
	lua_rawget(L, -2);//wv,u
	lua_remove(L, -2);//u
}

LUA_API void lua_getfieldUD(lua_State *L, int idx, char *name)
{
	if (!lua_isuserdata(L, idx))
		lua_errorEx(L, "lua_getfieldUD #-1 must be userdata");
	lua_getref(L, _WeakK_UD_PROPERTY);
	lua_pushvalue(L, idx>0 ? idx : idx - 1);
	lua_rawget(L, -2);
	if (lua_isnil(L, -1)) { //ud,wk,nil
		lua_remove(L, -2); //ud,nil
		return;
	}
	lua_replace(L, -2); //ud,tb
	lua_pushstring(L, name);
	lua_rawget(L, -2); //ud,tb,v
	lua_remove(L, -2);//ud,v
}

LUA_API void lua_setfieldUD(lua_State *L, int idx, char *name)
{
	if (!lua_isuserdata(L, idx))
		lua_errorEx(L, "lua_setfieldUD #-1 must be userdata");
	int top = lua_gettop(L);
	lua_getref(L, _WeakK_UD_PROPERTY); //top-1,v,wk
	lua_pushvalue(L, idx>0 ? idx : idx - 1);//top-1,v,wk,ud
	lua_rawget(L, -2);  //top,v,wk,tb?
	int newtb = lua_isnil(L, -1);
	if (newtb)
		lua_createtable(L, 0, 1);//top-1,v,wk,nil,tb  //else top-1,v,wk,tb
	lua_pushstring(L, name); //top-1,v,wk,?,tb,k
	lua_pushvalue(L, top);//top-1,v,wk,?,tb,k,v
	lua_rawset(L, -3); //tb[k] = v
	if (newtb)//top-1,v,wk,nil,tb //else top-1,v,wk,tb
	{
		lua_pushvalue(L, idx>0 ? idx : idx - 3); //top-1, v, wk, nil, tb, ud
		lua_replace(L, -3); //top-1, v, wk, ud, tb 
		lua_rawset(L, -3); //top-1, v, wk[ud]=tb
	}
	lua_settop(L, top-1);
}

//os---------------------------------------------------------------

//debug------------------------------------------------------------
//debug.getargs(function)
static int debug_getargs(lua_State* L)
{
	int top = lua_gettop(L);
	if (!lua_isfunction(L, 1) || top != 1) {
		lua_errorEx(L, "#1 debug.getargs only need a function");
		return 0;
	}
	const char* name;
	int i = 1;
	while ((name = lua_getlocal(L, NULL, i++)) != NULL) {
		lua_pushstring(L, name);
		lua_insert(L, -2);
	}
	lua_pop(L, 1);
	return lua_gettop(L);
}
//debug.stack_dump()
LUA_API int lua_stackDump(lua_State* L)
{
	int top = lua_gettop(L);
	printf("[C]dump stack:\n");
	for (int i = 0; i < top; i++)
	{
		int iindex = -1 - i;
		int itype = lua_type(L, iindex);
		printf("stack :%d  ", iindex);
		switch (itype) {
		case LUA_TSTRING:
			printf("'%s'", lua_tostring(L, iindex));
			break;
		case LUA_TBOOLEAN:
			printf(lua_toboolean(L, iindex) ? "true" : "false");
			break;
		case LUA_TNUMBER:
			printf("%g", lua_tonumber(L, iindex));
			break;
		default:
			printf("%s %08zx", lua_typename(L, itype), (size_t)lua_topointer(L, iindex));
			break;
		}
		printf("\n");
	}
	return top;
}


//-------------------------------------------------------------
LUA_API void luaopen_extend(lua_State *L) {
	lua_openstringEx(L);
	int weakk, weakv, weakkv;
	//weakmeta
	lua_createtable(L, 0, 1); //luaL_newmetatable(L, "WEAKK");
	lua_pushliteral(L, "__mode");
	lua_pushliteral(L, "k");
	lua_rawset(L, -3);
	weakk = lua_gettop(L);

	lua_createtable(L, 0, 1); //luaL_newmetatable(L, "WEAKV");
	lua_pushliteral(L, "__mode");
	lua_pushliteral(L, "v");
	lua_rawset(L, -3);
	weakv = lua_gettop(L);

	lua_createtable(L, 0, 1); //luaL_newmetatable(L, "WEAKKV");
	lua_pushliteral(L, "__mode");
	lua_pushliteral(L, "kv");
	lua_rawset(L, -3);
	weakkv = lua_gettop(L);

	//lua_pop(L, 3); 
	//ref weak table------------------------------
	lua_createtable(L, 0, 0);
	lua_pushvalue(L, weakv);//luaL_getmetatable(L, "WEAKV");
	lua_setmetatable(L, -2);
	_WeakV_PTR2UD = lua_ref(L, -1);
	//ref weak table
	lua_createtable(L, 0, 0);
	lua_pushvalue(L, weakk);//luaL_getmetatable(L, "WEAKK");
	lua_setmetatable(L, -2);
	_WeakK_UD_PROPERTY = lua_ref(L, -1);
	//ref weak table
	lua_createtable(L, 0, 0);
	lua_pushvalue(L, weakk);//luaL_getmetatable(L, "WEAKK");
	lua_setmetatable(L, -2);
	_WeakK_BytesLenth = lua_ref(L, -1);
	lua_pop(L, 3); //pop weak3

	//bytes metatable
	lua_createtable(L, 0, 3); //tb
		lua_pushliteral(L, "__index");//tb,"__index"
		lua_pushliteral(L, "");//tb,"__index",""
		lua_getmetatable(L, -1);//tb,"__index","",stringmt
		lua_remove(L, -2); //tb,"__index",stringmt

		lua_pushliteral(L, "__index");//tb,"__index",stringmt,"__index"
		lua_rawget(L, -2);//tb,"__index",stringmt,__index
		lua_remove(L, -2); //tb,"__index",__index
		lua_rawset(L, -3); //tb

		lua_pushliteral(L, "__len");//tb,"__len"
		lua_getref(L, _WeakK_BytesLenth);//lua_pushcfunction(L, lua_bytesLen);
		lua_pushcclosure(L, lua_bytesLen, 1);
		lua_rawset(L, -3);

		lua_pushliteral(L, "__tostring");//
		lua_pushcfunction(L, lua_str_tostring);
		lua_rawset(L, -3);

		lua_pushliteral(L, "tostr");//tb,"__len"
		lua_pushcfunction(L, lua_bytes2str); //lua_bytes_tostr重复
		lua_rawset(L, -3);

	_BytesMeta = lua_ref(L, -1);

	//table-----------------------------------------------
	lua_getglobal(L, "table");
		lua_pushcfunction(L, table_new);
		lua_setfield(L, -2, "new");
		lua_pushcfunction(L, table_size);
		lua_setfield(L, -2, "size");
#ifdef LUAJIT_VERSION
		lua_pushcfunction(L, table_duplicate);
		lua_setfield(L, -2, "duplicate");
#endif
	lua_pop(L, 1); //pop table

	lua_getglobal(L, "debug");
		lua_pushcfunction(L, debug_getargs);
		lua_setfield(L, -2, "getargs");
		lua_pushcfunction(L, lua_stackDump);
		lua_setfield(L, -2, "stack_dump");

	lua_pop(L, 1);//pop debug

}