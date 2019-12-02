--对象伪基类
--伪:因__index的频繁调用占用效率,不做继承,子类需直接复制基类方法
_G.Object = {}
----------------------------------------------------------------
--tolocal
local debug = debug
local error = error
local pairs = pairs
local print = print
local Object = Object
----------------------------------------------------------------
--local
local _objects = {}
local _num = 0
local _objectsWV = table.weakv()
local _newindex = function(o,k,v)
	error('all prop must be pre-defined:..'..k)
end
local _id1, _id2 = 0, 0 --guid序例
----------------------------------------------------------------
--public
function Object.newMeta(class)
	return {
		--__call = class.new,
		__index=class,
		__newindex=_newindex,
	}
end
function Object.newGuid(negative)
	if negative then --负索引
		_id2 = _id2 - 1
		return _id2
	else
		_id1 = _id1 + 1
		return _id1
	end
end
function Object.new(tb)
	return tb or {}
end
function Object.all() return _objects end
function Object.count() return _num end
function Object.ref(o)
	_objects[o.guid] = o
	_objectsWV[o.guid] = o
	_num = _num + 1
	return o
end
function Object.unref(guid)
	local o = _objects[guid]
	_objects[guid] = nil
	_num = _num - 1
	return o
end
function Object.get(guid)
	return _objects[guid]
end
function Object.getLeaks()
	local t
	local n = 0
	for i,o in pairs(_objectsWV) do
		if not _objects[i] then
			n = n + 1
			if not t then t = {} end
			t[n] = o
		end
	end
	return n,t
end
function Object.listLeaks(gcCnt)
	-- for i=1, (gcCnt or 2) do --检查前gc次数
		-- debug.gc()
	-- end
	local n, t = Object.getLeaks()
	if n > 0 then
		print('ObjectLeakNum='..n)
		for i,o in ipairs(t) do
			print(o,o.type)
			--local t = debug.findobj(debug.getregistry(), function(t)return t==o end,'_REG')
			local t = debug.findobj(_G, function(t)return t==o end,'_G')
			dump(t,2)
		end
	end
	-- local t = debug.getregistry()
	-- for k,v in pairs(t) do
		-- if type(v)=='table' then
			-- print('_R.',k,table.count(v))
		-- end
	-- end
end
----------------------------------------------------------------
--object
function Object:addTimer(delay, callback, group)
	local timers = self.timers
	local tid = Timer.add( delay, callback, timers)
	timers[tid] = group or true
	return tid
end
function Object:delTimer(tid)
	assert(self.timers[tid], 'tid')
	Timer.del( tid )
end
function Object:delTimerGroup(group)
	local del = Timer.del
	for tid, g in pairs(self.timers) do
		if group == g then
			del( tid )
		end
	end
end
function Object:clearTimer()
	local delTimer = self.delTimer
	for tid,_ in pairs(self.timers) do delTimer(self,tid) end
end
----------------------------------------------------------------
--
if _DEVELOPMENT and CONFIG.LEAK_CHECK then--泄漏检查 TODO 发布版关闭,手动运行
	function event.onSecond(e)
		Object.listLeaks(8)
	end
end
