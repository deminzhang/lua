--战斗属性计算
_G.Attr = {}
----------------------------------------------------------------
--to local
local Attr = Attr
local pairs = pairs
local ipairs = ipairs
local min = math.min
local max = math.max

----------------------------------------------------------------
--local
local k2x = {}
local attrLock = Attr._attrLock or table.weakk()
Attr._attrLock = attrLock

local function template()
	if Attr._template then
		return Attr._template()
	else
		local t = {}
		for k, v in pairs(cfg_attr) do
			t[k] = 0
			t[k..'X'] = 100
			k2x[k] = k..'X'
		end
		Attr._template = table.template( t )
		return t
	end
end

local function reset(o, k) --主公式
	--属性=(base*(1+baseX)+app)*(1+appX)
	local val = (o.base[k]*(1+o.baseX[k])+o.app[k])*(1+o.appX[k])
	return val
end
----------------------------------------------------------------
--Attr.
function Attr.init(o)
	local t = {
		base = {},	--基础属性
		baseX = {},	--基础属性百分加成
		app = {},	--附加属性
		appX = {},	--属性总百分加成
	}
	o.attrpool = t
	for k, v in pairs(cfg_attr) do
		t.base[k] = 0
		t.baseX[k] = 0
		t.app[k] = 0
		t.appX[k] = 0
		if v.broad then
			o:def(k, 'often', 0)
		else
			o.attribute[k] = 0
		end
	end
end
function Attr.release(o)
	attrLock[o] = nil
end
function Attr.lockReset(o, bool)
	attrLock[o] = bool
end
function Attr.add(o, attrs, noReset, label, noSend )	--加
	local b
	local pool = o.attrpool
	for k,v in pairs(attrs) do
		if cfg_attr[k] then
			pool.base[k] = (pool.base[k] or 0) + v
		end
	end
	if not noReset then
		Attr.reset(o, label, noSend)
	end
end
function Attr.sub(o, attrs, noReset, label, noSend)	--减
	local b
	local pool = o.attrpool
	for k,v in pairs(attrs) do
		if cfg_attr[k] then
			pool.base[k] = (pool.base[k] or 0) - v
		end
	end
	if b and not noReset then
		Attr.reset(o, label, noSend)
	end
end
function Attr.reset(o, label, noSend)
	assert(not attrLock[o], 'Attr.reset was locked')
	local pool = o.attrpool
	assert(pool,'no init')
	for k, v in pairs(cfg_attr) do
		local vv = reset(pool, k)
		vv = min(max(vv,v.min),v.max)
		if not v.float then
			vv = toint(vv)
		end
		if v.broad then
			o:setv(k, vv)
		else
			o.attribute[k] = vv
		end
	end
end
function Attr.get(o, k)
	return cfg_attr[k].broad and o:getv(k) or o.attribute[k]
end
--得到所有的属性
function Attr.getAll(o)
	local t = {}
	for k, v in pairs(cfg_attr) do
		t[k] = Attr.get(o, k)
	end
	return t
end


----------------------------------------------------------------
--event
when{} function loadConfig()
	dofile'config/cfg_attr.lua'
end
when{} function checkConfig()
	for k,v in pairs(cfg_attr) do
		assert(v.min>-0x7fffffffffff, k..' invalid min:'..v.min)
		assert(v.max<0x7fffffffffff, k..' invalid max:'..v.max)
	end
end

----------------------------------------------------------------
