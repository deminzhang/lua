--do return end
--[[in C===================================================================
local queues, subqueues = {},{};
local subqueueon;
local beforecall, aftercall, errcall;
function _queue(beforeCall, afterCall, errCall)
	assert(type(beforeCall) == 'function', 'bad argument #1 (function expected, got '..tostring(beforeCall)..' value)')
	assert(type(afterCall) == 'function', 'bad argument #1 (function expected, got '..tostring(afterCall)..' value)')
	assert(type(errCall) == 'function', 'bad argument #1 (function expected, got '..tostring(errCall)..' value)')
	beforecall, aftercall, errcall = beforeCall, afterCall, errCall
end
function _enqueue(delay, from, nameorfunc, args...)
	delay = delay or 0
	if subqueueon then
		subqueues[#subqueues + 1] = {os_msec() + delay,from,fn,argn,args...}
	else
		queues[#queues + 1] = {os_msec() + delay,from,fn,argn,args...}
	end
end
function _subqueue(start)
	subqueueon = start and true or false
	if #subqueues == 0 then return end
	if start then
		for _, v in ipairs(subqueues) do
			queues[#queues + 1] = v
		end
	end
	subqueues = {}
end
function _callin(from, data)
	local fn, args = _decode(data)
	local func = event[fn]
	assert(func, fn..'invaild RPC')
	_enqueue(0, from, fn, args)
end
_queue(beforeCall, afterCall, errCall)
_enqueue(delay, from, nameorfunc, args)
_subqueue(start)
_callin(from, data)
--]]
--lua===================================================================
_queue(function( fn, args ) --beforecall begins
	--_SQL:begin()
	_MDB:begin()
	--GMLog:begin()
	--print('begin', fn)
	_subqueue( true ) --启动子队列
end, function( fn ) --aftercall commits
	--_SQL:commit()
	_MDB:commit()
	--GMLog:commit()
	--print('commit', fn)
	_subqueue( true ) --提交己启动队列,重新启动新子队列
	_subqueue( false )--回滚子队列
end, function( fn, err ) --errorcall rollbacks
	--_SQL:rollback( )
	_MDB:rollback()
	--GMLog:rollback( )
	--print('rollback', fn, err)
	print(err)
	_subqueue( false ) --回滚子队列
end)