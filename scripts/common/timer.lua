--timer.lua
_G.Timer = {}
local _count = 0
local _id = 0
local _timers = {}
local os_msec = os.msec-- ms毫秒方法

function Timer.count()
	return _count
end

function Timer.add(ms, callback, asm)--asm:对象托管的timer处理
	_id = _id + 1
	local info = debug.getinfo( 2 )
	local source = info.source .. '|' .. info.currentline
	_timers[_id] = {
		time = os_msec() + ms;
		func = callback;
		source = source;
		asm = asm;
	}
	_count = _count + 1
	return _id
end

function Timer.del(id)
	local t = _timers[id]
	local a = t.asm
	if a then a[id] = nil end
	_timers[id] = nil
	_count = _count - 1
end

function Timer.update()
	local now = os_msec()
	for id,t in pairs(_timers) do
		if t.time <= now then
			local a = t.asm
			if a then a[id] = nil end
			_timers[id] = nil
			_count = _count - 1
			t.func() --TODO pcall
		end
	end
end

--重设回调,会产生临时func,一般不用,用asm
function Timer.callback(id, func)
	_timers[id].func = func
end

---------------------------------
define.onTimer{}--计时器循环
when{_order=0}
function event.onTimer()
	onTimer{_delay=2}
	Timer.update()
end
onTimer{_delay=0}