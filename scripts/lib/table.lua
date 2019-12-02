
--[[in C===================================================================
table.new(narr,nrec) --创建指定size的表
narr,nrec = table.size(tb) --返回表大小数组/哈希(指分配空间,非实际元素个数)2^i+1,2^i-1
table.duplicate(src) --浅复制一个表 不含metatable

local mt = {
	__add = function(t, v) --加法t+v
		print('__add',t, v)
		return t
	end,
	__sub = function(t, v) --减法t-v
		print('__sub',t, v)
		return t
	end,
	__mul = function(t, v) --乘法t*v
		print('__mul',t, v)
		return t
	end,
	__div = function(t, v) --除法t/v
		print('__div',t, v)
		return t
	end,
	__mod = function(t, v) --取模t%v
		print('__mod',t, v)
		return t
	end,
	__pow = function(t, v) --乘幂t^v
		print('__pow',t, v)
		return t
	end,
	__unm = function(t) 	--相反数-t
		print('__unm',t, v)
		return t
	end,
	__concat = function(t, v) --连接t..v
		print('__concat',t, v)
		return t
	end,
	__len = function(t) --长度#t 仅userdata可用
		print('__len',t)
		return 0
	end,
	__eq = function(t, v) --相等t==v
		print('__eq',t, v)
		return false
	end,
	__lt = function(t, v) --小于t<v
		print('__lt',t, v)
		return false
	end,
	__le = function(t, v) --小于等于t<=v
		print('__le',t, v)
		return false
	end,
	__index = function(t, k) --索引查询t.v
		print('__index',t, k)
	end,
	__newindex = function(t, k, v) --索引更新t.k=v
		print('__newindex',t, k, v)
		return '__newindex'
	end,
	__call = function(t, ...) --执行调用t(...)
		print('__call',t, ...)
	end,
	__tostring = function(t) --字符串输出tostring(t)
		return '__tostring'
	end,
	-- __pairs = function(t) --字符串输出pairs(t)
		-- print('__pairs',t)
		-- return k,v
	-- end,
	__metatable = '__metatable'--保护元表
}
--]]
--todo
--lua5.1 table.insert不会触发__newindex 5.3会
--lua===================================================================
local unpack = table.unpack or unpack
local load = load or loadstring
local insert = table.insert
local new = table.new or function() return {} end
--function table.ASC(a,b) return a<b end --用不到缺省为升序
function table.asc(k) return function(a,b) return a[k]<b[k] end end
function table.DESC(a,b) return a>b end
function table.desc(k) return function(a,b) return a[k]>b[k] end end
function table.orderby(...) --table.orderby('score','desc','time','asc')
	local tb = {...}
	return function(a,b)
		for i = 1, #tb, 2 do
			local k = tb[i]
			local by = tb[i+1]
			if a[k]==b[k] then
			else
				if by == 'desc' then
					return a[k] > b[k]
				else
					return a[k] < b[k]
				end
			end
		end
		return false
	end
end

table.arithmetic = { --加合并元表
	__index = function(t,k)
		return 0
	end,
	__add = function(t, v) -- +
		for k, v in pairs(v) do
			t[k] = t[k] + v
		end
		return t
	end,
	__sub = function(t, v) -- - 是否max(0,val)?
		for k, v in pairs(v) do
			t[k] = t[k] - v
		end
		return t
	end,
	__mul = function(t, m) -- *
		for k, v in pairs(t) do
			t[k] = t[k] * m
		end
		return t
	end,
	__div = function(t, d) -- /
		for k, v in pairs(t) do
			t[k] = t[k] / d
		end
		return t
	end,
}

function table.clone(src, withmeta) --深copy,带metatable
	local t = table.duplicate and table.duplicate(src) or {}
	for k, v in pairs(src) do
		if type(k)=='table' then
			k = table.clone(k, withmeta)
		end
		if type(v)=='table' then
			t[k] = table.clone(v, withmeta)
		else
			t[k] = v
		end
	end
	if withmeta then
		setmetatable( t, getmetatable(src) )
	end
	return t
end
function table.copy(t,src)
	if not t then
		t = table.duplicate and table.duplicate(src) or {}
	end
	for k,v in pairs(src) do
		t[k] = v
	end
	return t
end
function table.find(t,func)
	for k,v in pairs(t) do
		if func(k,v) then
			return k,v
		end
	end
end
function table.tostr(t) --低效
	local tt = type(t)
	assert(tt=='table','bad argument #1(table expected, got '..tt..')')
	local ts = {}
	for k,v in pairs(t) do
		local tk = type(k)
		local tv = type(v)
		if tk=='number' then
			k = '['..k..']'
		elseif tk=='boolean' then
			k = '['..k..']'
		elseif tk=='string' then
		else
			error(k..'='..tk..'cannot tostr')
		end
		if tv=='table' then
			insert(ts, k..'='..table.tostr(v))
		elseif tv=='string' then
			insert(ts, k.."='"..v.."'")
		elseif tv=='number' then
			insert(ts, k..'='..tostring(v))
		elseif tv=='boolean' then
			insert(ts, k..'='..tostring(v))
		else
			error(k..'='..tv..'cannot tostr')
		end
	end
	return '{'..table.concat(ts,',')..'}'
end
function table.template(t) --适用初始化
	return load('return ' .. table.tostr(t))
end
function table.count(t)
	local sum = 0
	for i,v in pairs(t) do
		sum = sum + 1
	end
	return sum
end

if not table.weakk then
	local weakk={__mode='k'}
	table.weakk = function(narr,nrec,newmeta)
		return setmetatable(new(narr,nrec), newmeta and {__mode='k'} or weakk)
	end
end
if not table.weakv then
	local weakv={__mode='v'}
	table.weakv = function(narr,nrec,newmeta)
		return setmetatable(new(narr,nrec), newmeta and {__mode='v'} or weakv)
	end
end
if not table.weakkv then
	local weakkv={__mode='kv'}
	table.weakkv = function(narr,nrec,newmeta)
		return setmetatable(new(narr,nrec), newmeta and {__mode='kv'} or weakkv)
	end
end
 
function table.toJson(tb)  --Json..太多,待优化
	return Json():encode(tb)
end
function table.fromJson(json)
	return Json():decode( json )
end

function table.push(t,...)
	assert(t,'#1 table required')
	for i=1, select("#", ...) do
		local v = select(i, ...)
		insert(t, v)
	end
	return t
end

--return array of keys
function table.keys(t, out)
	out = out or { }
	for k, _ in next, t do
		insert(out, k)
	end
	return out
end
--return array of values
function table.values(t, out)
	out = out or { }
	for k, _ in next, t do
		insert(out, k)
	end
	return out
end
