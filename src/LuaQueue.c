#include "LuaQueue.h"

#define QUEUE_MAX 5000
#define upx lua_upvalueindex

#define DELAYTO -1
#define FUNC -2
#define ARGVN -3
#define FROM -4
#define CALLED -5

static int queues, subqueues;
static int subqueueon = 0;
static int beforecall, aftercall, errcall = 0;

//function _queue(beforeCall, afterCall, errCall)
//	assert(type(beforeCall) == 'function', 'bad argument #1 (function expected, got '..tostring(beforeCall)..' value)')
//	assert(type(afterCall) == 'function', 'bad argument #1 (function expected, got '..tostring(afterCall)..' value)')
//	assert(type(errCall) == 'function', 'bad argument #1 (function expected, got '..tostring(errCall)..' value)')
//	beforecall, aftercall, errcall = beforeCall, afterCall, errCall
//end
static int lua_queue(lua_State *L)
{
	if (!lua_isfunction(L, 1))
		lua_errorEx(L, "#1 must be a function beforecall(fn, args)");
	if (!lua_isfunction(L, 2)) 
		lua_errorEx(L, "#2 must be a function aftercall(fn)");
	if (!lua_isfunction(L, 3)) 
		lua_errorEx(L, "#3 must be a function errcall(fn,err)");
	lua_settop(L,3);
	errcall = lua_ref(L, -1);
	aftercall = lua_ref(L, -1);
	beforecall = lua_ref(L, -1);
	return 0;
}

//function _enqueue(delay, from, nameorfunc, args...)
//	delay = delay or 0
//	if subqueueon then
//		subqueues[#subqueues + 1] = {os_msec() + delay,from,fn,argn,args...}
//	else
//		queues[#queues + 1] = {os_msec() + delay,from,fn,argn,args...}
//	end
//end
static int lua_enqueue(lua_State *L)
{
	double delayms = luaL_optinteger(L, 1, 0);
	if (delayms<0)
		delayms = 1; //防止循环中插入delay0的直接执行造成混乱
	//2 from
	if (!(lua_isstring(L, 3) || lua_isfunction(L, 3)))
		lua_errorEx(L, "#3 function or functionname expected, got %s", lua_typename(L,lua_type(L,3)));

	int top = lua_gettop(L);
	int argn = top - 3;
	if(argn==1 && !lua_istable(L,4)) //单参数必须为表
		lua_errorEx(L, "#4 table expected, got %s", lua_typename(L, lua_type(L, 3)));

	lua_createtable(L, argn, 4);//{delayto,from,func,argn,args...}
	lua_pushnumber(L, timeNow(.001f,0) + delayms), lua_rawseti(L, -2, DELAYTO);//delayto
	lua_pushvalue(L, 2), lua_rawseti(L, -2, FROM); //from
	lua_pushvalue(L, 3), lua_rawseti(L, -2, FUNC); //funcorname
	lua_pushinteger(L, (lua_Number)argn), lua_rawseti(L, -2, ARGVN);//argn
	for (int i = 1; i <= argn;)
		lua_pushvalue(L, i+3), lua_rawseti(L, -2, i++); //args

	lua_getref(L, subqueueon ? subqueues : queues);
	lua_insert(L, -2);
	int n = luaL_getn(L, -2) + 1;
	if (n > QUEUE_MAX) //to many
		lua_errorEx(L, "queue too long %d, MAX:%d", n, QUEUE_MAX);

	lua_rawseti(L, -2, n );
	return 0;
}

//function _subqueue(start)
//	subqueueon = start and true or false
//	if #subqueues == 0 then return end
//	if start then
//		for _, v in ipairs(subqueues) do
//			queues[#queues + 1] = v
//		end
//	end
//	subqueues = {}
//end
static int lua_subqueue(lua_State *L)
{
	subqueueon = lua_toboolean(L, 1);
	lua_getref(L, subqueues);
	int sn = luaL_getn(L, -1);
	if (sn == 0) return 0;
	if (subqueueon) {
		lua_getref(L, queues);
		int n = luaL_getn(L, -1);
		for (int i = sn; i > 0; i--) {//queues[++n] = subqueues[i++]
			lua_rawgeti(L, -2, i);
			lua_rawseti(L, -2, ++n);
		}
	}
	lua_unref(L, subqueues);
	lua_createtable(L, 0, 0);
	subqueues = lua_ref(L, -1);
	lua_pushboolean(L, subqueueon);
	return 1;
}

//function _callin(from, data)
//	local fn, args = _decode(data)
//	local func = event[fn]
//	assert(func, fn..'invaild RPC')
//	_enqueue(0, from, fn, args)
//end
//upv _enqueue, _G, "_decode", "delay"
//_callin( net, data )
static int lua_callin(lua_State *L)
{
	//int t0 = lua_gettop(L); //from, data
	//lua_pushcfunction(L, lua_decode); //用lua_getglobal为了可用自定义_decode
	lua_getglobal(L, "_decode");//from,data,_decode
	lua_insert(L, 2);//from,_decode,data
	lua_call(L, 1, 2);//from,fn,args

	lua_pushvalue(L, 1);
	lua_setglobal(L, "_from");
	if (beforecall) {
		//fprintf(stdout, "[C]beforecall\n");
		lua_getref(L, beforecall);//from,func,args,bc
		lua_pushvalue(L, 2);
		lua_pushvalue(L, 3);
		if (lua_pcall(L, 2, 0, 0) != 0) {
			fprintf(stderr, "[C]error in beforecall; %s\n", lua_tostring(L, -1));
			lua_pushnil(L);
			lua_setglobal(L, "_from");
		}
	}
	if (lua_isstring(L, 2)) {
		size_t l;
		const char *s = lua_tolstring(L, 2, &l);
		lua_getglobal(L, s);//from,fn,args,func
		if (!lua_isfunction(L, -1)) {
			lua_pushnil(L);
			lua_setglobal(L, "_from");
			lua_settop(L, 0);
			fprintf(stderr, "Remote: %s must be a function\n", s);
			lua_errorEx(L, "%s must be a function", s);
			return 0;
		}
		lua_replace(L, 2);//from,func,args
	}
	if (aftercall)
	{
		lua_pushvalue(L, 2);
		lua_pushvalue(L, 3);
	}//from,func,args,func,args
	if (lua_pcall(L, 1, 0, 0) != 0) {
		if (errcall) {
			//fprintf(stderr, "[C]error %s\n", lua_tostring(L, -1));
			lua_pushnil(L);
			lua_setglobal(L, "_from");
			lua_getref(L, errcall);//from,func,args,err,ec
			lua_pushvalue(L, 2);//from,func,args,err,ec,func
			lua_pushvalue(L, -3);//from,func,args,err,ec,func,err
			if (lua_pcall(L, 2, 0, 0) != 0) {
				fprintf(stderr, "[C]error in errcall; %s\n", lua_tostring(L, -1));
			}
		}
		else
			//fprintf(stderr, "[C]error %s\n", lua_tostring(L, -1));
			lua_errorEx(L, "[C]error %s\n", lua_tostring(L, -1));
	}
	else if (aftercall)
	{
		lua_settop(L, 3);//queues,k,v  //pop the returning of call
		lua_getref(L, aftercall);//from,func,args,ac
		lua_insert(L, 2);//from,ac,func,args
		if (lua_pcall(L, 2, 0, 0) != 0) {
			fprintf(stderr, "[C]error in aftercall; %s\n", lua_tostring(L, -1));
		}
		lua_pushnil(L);
		lua_setglobal(L, "_from");
	}
	return 0;
}

//upv: remote, onCallout, name||func, _enqueue, "_delay", _callout, defaultdelay
//remote.Name{_delay=}
static int callout_call(lua_State *L)
{
	if (!lua_istable(L, 1))			//args
		lua_errorEx(L, "#1 must be a table value");
	int top = lua_gettop(L);
	if (top != 1)					//only1arg TODO 想扩成多参数
		lua_errorEx(L, "too many arguments");

	//lua_pushstring(L, "_delay"), lua_rawget(L, 1);
	lua_pushvalue(L, upx(5)),lua_rawget(L, 1); //args._delay
	if (!lua_isnil(L, -1))
		lua_pushvalue(L, upx(7));	//defaultdelay

	if (lua_isnil(L, -1)) { //nodelay onCallout(remote,name,args,_encode(name,args))
		lua_pushvalue(L, upx(3)), lua_insert(L, 1); // 1 name 2 args
		lua_encode(L); // encode(name,args)
		top = lua_gettop(L);	//top
		lua_pushvalue(L, upx(2));	//onCallout
		lua_pushvalue(L, upx(1));	//remote
		lua_pushvalue(L, 1);		//Name
		lua_pushvalue(L, 2);		//args
		lua_pushvalue(L, top - 1);	//encoded ud
		lua_pushvalue(L, top);		//ud len
		lua_call(L, 5, 0);			//onCallout(...)
		lua_pushvalue(L, 2);		//return remote
	}
	else {		//delay enqueue(0|delay, _callout, doSend, ...)
		double delay = lua_tonumber(L, -1);
		lua_pushnil(L), lua_pushvalue(L, upx(5)), lua_rawset(L, 1);//args._delay=nil

		lua_pushvalue(L, upx(4));	//_enqueue
		lua_pushnumber(L, delay);	//delay
		lua_pushvalue(L, upx(6));	//_callout
		lua_pushvalue(L, upx(2));	//onCallout
		lua_pushvalue(L, upx(1));	//remote
		lua_pushvalue(L, 1);		//Name
		lua_pushvalue(L, 2);		//args
		lua_call(L, 7, 1);			// enqueue( ...)
	}
	return 1;
}

//upv: old__index,  onCallout, _enqueue, "_delay", _callout, defaultdelay
static int callout_name(lua_State *L)
{
	unsigned char *name = (unsigned char*)lua_tostring(L, 2);
	if (name && name[0] - (unsigned)'A' <= 'Z' - 'A') // remote.Name callout
	{
		lua_pushvalue(L, 1),		//upv1=remote
		lua_pushvalue(L, upx(2)),	//onCallout
		lua_pushvalue(L, 2),		//name || func
		lua_pushvalue(L, upx(3)),	//_enqueue
		lua_pushvalue(L, upx(4)),	//"_delay"
		lua_pushvalue(L, upx(5)),	//_callout
		lua_pushvalue(L, upx(6)),	//upv7=defaultdelay
		lua_pushcclosure(L, callout_call, 7);
		return 1; 
	}
	//remote.name callin
	lua_pushvalue(L, upx(1));		//old__index 
	if (lua_istable(L, -1))
		lua_pushvalue(L, 2), lua_gettable(L, -2);
	else if (lua_isfunction(L, -1))
		lua_pushvalue(L, 1), lua_pushvalue(L, 2), lua_call(L, 2, 1);
	else
		lua_pushnil(L); //return 0;
	return 1; // net.name
}

//function Net.callout( net )
//	if not _callout( net ) then
//		_callout( net, function( net, rpc, args, data, len )
//			--local data,len = _encode(rpc,args)
//			net:send(string.from32l(len))
//			net:send(data,len)
//		end, 0 )
//	end
//end
//upv: _G._enqueue,  "_delay", _callout, "__index"
static int lua_callout(lua_State *L)
{
	int type = lua_type(L, 1);
	if (type != LUA_TTABLE && type != LUA_TUSERDATA)
		lua_errorEx(L, "bad argument #1 (table or userdata expected, got %s)", luaL_typename(L, 1));
	int set = lua_type(L, 2) == LUA_TFUNCTION;
	if (lua_toboolean(L, 3))
		luaL_checknumber(L, 3);
	else
		lua_settop(L, 2), lua_pushboolean(L, 0);
	if (!set){
		//if(lua_getmetatable(L, 1) && (lua_pushstring(L,"__index"),lua_rawget(L,-2),lua_tocfunction == callout_name))
		if(lua_getmetatable(L, 1) && (lua_pushvalue(L, upx(4)), lua_rawget(L, -2), lua_tocfunction(L, -1) == callout_name))
			return lua_getupvalue(L, -1, 2), 1;
		lua_pushnil(L); //return 0;
		return 1;
	}
	if (!lua_getmetatable(L, 1))	{
		lua_createtable(L, 0, 4);
		lua_pushstring(L, "__metatable"), lua_pushboolean(L, 0), lua_rawset(L, -3);
		lua_pushvalue(L, -1), lua_setmetatable(L, 1);
	}
	//lua_pushstring(L, "__metatable"), lua_rawget(L, -2);
	lua_pushvalue(L, upx(4)), lua_rawget(L, -2);
	if (lua_tocfunction(L, -1) != callout_name)	//upv1 old__index
	{
		lua_pushvalue(L, 2),		//upv2 onCallout
		lua_pushvalue(L, upx(1)),	//_enqueue
		lua_pushvalue(L, upx(2)),	//"_delay"
		lua_pushvalue(L, upx(3)),	//_callout
		lua_pushvalue(L, 3),					//upv6=defaultdelay
		lua_pushcclosure(L, callout_name, 6),	//__index
		lua_pushvalue(L, upx(4)), lua_insert(L, -2), lua_rawset(L, -3);
	}
	else if (lua_getupvalue(L, -1, 2), !lua_rawequal(L, -1, 2))
		lua_errorEx(L, "already _callout with a different function %p", lua_topointer(L,-1));

	lua_settop(L, 1);
	return 1;
}

static int *calledidx = NULL;
static size_t arrn = 32;
LUA_API void luaqueue_loop(lua_State *L)
{
	int top = lua_gettop(L);
	if (top != 0) {
		lua_settop(L, 0);
		fprintf(stderr, "[C]top!=0 %d when luaqueue_loop begin\n", top);
	}
	lua_getref(L, queues); //queues
	long long t = time_Now(.001f, 0);
	if(calledidx==NULL) //first once
		calledidx = (int *)malloc(arrn*sizeof(int));

	int called = 0;
	int n = 0;
	for (lua_pushnil(L); lua_next(L, -2); lua_pop(L, 1))
	{
		int v = lua_gettop(L);
		lua_rawgeti(L, v, DELAYTO);//queues,k,v,time
		called = t >= lua_tointeger(L, -1);
		if (called)	{	//queues, k,..
			lua_rawgeti(L, v, ARGVN);//3v,time,argn
			int argn = (int)lua_tointeger(L, -1);

			lua_rawgeti(L, v, CALLED);//3v,time,argn,called
			int cd = lua_toboolean(L, -1);
			lua_pop(L, 3);//v
			if (cd)  continue;
			lua_pushboolean(L, 1), lua_rawseti(L, v, CALLED);

			if (beforecall)	{
				//fprintf(stdout, "[C]beforecall\n");
				lua_getref(L, beforecall);//v,bc
				lua_rawgeti(L, v, FUNC);//v,bc,fn
				for (int i = 1; i <= argn; )
					lua_rawgeti(L, v, i++);//v,bc,fn,args++
				if (lua_pcall(L, argn+1, 0, 0) != 0) 
					fprintf(stderr, "[C]error in beforecall; %s\n", lua_tostring(L, -1));
			}
			lua_rawgeti(L, v, FUNC);//v,fn
			if (lua_isstring(L, -1)) { //if func is name func=_G[func]
				size_t l;
				const char *s = lua_tolstring(L, -1, &l);
				lua_getglobal(L, s);//v,time,fname,fn
				lua_replace(L, -2);//v,time,fn
			}
			for (int i = 1; i <= argn; )
				lua_rawgeti(L, v, i++);//v,fn,args++
			if (lua_pcall(L, argn, 0, 0) != 0) {
				if (errcall)				{
					//fprintf(stderr, "[C]error %s\n", lua_tostring(L, -1));
					lua_getref(L, errcall);//v,err,ec
					lua_rawgeti(L, v, FUNC);//v,err,ec,fn
					lua_pushvalue(L, -3);//v,err,ec,fn,err
					if (lua_pcall(L, 2, 0, 0) != 0) 
						fprintf(stderr, "[C]error in errcall; %s\n", lua_tostring(L, -1));
				}
				else
					fprintf(stderr, "[C]error %s\n", lua_tostring(L, -1));
			}
			else if (aftercall)
			{
				//lua_settop(L, 3);//queues,k,v  //pop the returning of call
				lua_getref(L, aftercall);//queues,k,v,ac
				lua_rawgeti(L, v, FUNC);//v,ac,fn
				for (int i = 1; i <= argn; )
					lua_rawgeti(L, v, i++);//v,bc,fn,args++
				if (lua_pcall(L, argn+1, 0, 0) != 0) 
					fprintf(stderr, "[C]error in aftercall; %s\n", lua_tostring(L, -1));
			}
			lua_settop(L, v);//queues,k,v
			//mark done
			if (arrn < n){
				fprintf(stdout, "[C]queue call num out of; %d\n", n);
				arrn += 16;
				int *tmp = (int *)realloc((void*)calledidx, arrn*sizeof(int));
				if (!tmp) {
					fprintf(stderr, "[C]error in realloc calledidx; maybe not enough memory \n");
					break;
				}
				calledidx = tmp;
			}
			calledidx[n++] = (int)lua_tointeger(L, -2);
			break;
		}
		lua_settop(L, 3);//queues,k,v
		//-1v -2k
	}
	//remove marked
	for (int i = 0; i < n; i++)
		lua_pushnil(L), lua_rawseti(L, 1, calledidx[i]);

	lua_settop(L, 0);
}
LUA_API int luaopen_queue(lua_State *L)
{
	lua_createtable(L, 4, 0);
	queues = lua_ref(L, -1);
	lua_createtable(L, 4, 0);
	subqueues = lua_ref(L, -1);

	lua_pushcclosure(L, lua_queue, 0);
	lua_setglobal(L, "_queue");

	lua_pushcclosure(L, lua_enqueue, 0);
	lua_setglobal(L, "_enqueue");

	lua_pushcclosure(L, lua_subqueue, 0);
	lua_setglobal(L, "_subqueue");

	lua_getglobal(L, "_enqueue");	//upv1
	lua_getglobal(L, "_G");			//upv2
	lua_pushliteral(L, "_decode");	//upv3
	lua_pushliteral(L, "_delay");	//upv4
	lua_pushcclosure(L, lua_callin, 4);
	lua_setglobal(L, "_callin");

	lua_getglobal(L, "_enqueue");	//upv1
	lua_pushliteral(L, "_delay");	//upv2
	lua_pushnil(L);					//upv3
	lua_pushliteral(L, "__index");	//upv4
	lua_pushcclosure(L, lua_callout, 4);
	lua_pushvalue(L, -1);
	lua_setupvalue(L, -2, 3);		//upv3
	lua_setglobal(L, "_callout");

	return 0;
}