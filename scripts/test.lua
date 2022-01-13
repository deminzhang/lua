print('\n--------------------------------------------load test.lua\n')
local test = {}
local dump = debug.dump
local insert = table.insert
local remove = table.remove
local format = string.format

define.HotTest{T=''}
function event.HotTest(T)
	print('HotTest',T,_from)
	dostring(T)
end

test.cs = function()
	print('汉字')
	function event.onSecond()
		do return end
		debug.gc()
		for id, v in pairs(NetMgr.getAllGS()) do
			if v.net then
				--v.net.Hello{T="CS:Hi!GS"..id}
				--v.net.Hello{T=string.rep('a',0x4000)}
				v.net.Hello{T="CS:Hi!GS"..id}
			end
		end
		if NetMgr.getCS() then
			NetMgr.getCS().Hello{T="CS:Hi!CS"}
		end

	end
print('sql test---------------------------------------')

print('metatable test---------------------------------------')

print('encode/decode test---------------------------------------')
	local t = {abcdef=10,n=8,c=7,d={abcdef=23,dd='abcdef'}}
	local pack,len = _encode(t)
	--print(len,#pack,'XXXXXXXXXXXXXXXXX')

print('net test---------------------------------------')
	print('local: ip',_net.hostips())
	print('localhost: ip',_net.hostips('localhost'))
	print('baidu: ip',_net.hostips('baidu.com'))
print('other test---------------------------------------')
	--dofile'lib/calendar.lua'
	print(_md5sum('bin64/luaserver.exe'))
	--dump(os.env)
	print[[养志者，心气之思不达也。有所欲，志存而思之。志者，欲之使也。 欲多则心散，心散则志衰，志衰则思不达。故心气一则欲不徨，欲不徨则志意不衰，志意不衰则思理达矣。理达则和通，和通则乱气不烦于胸中，故内以养志，外以知人。养志则心通矣，知人则识分明矣。将欲用之于人，必先知其养气志。知人气盛衰，而养其志气，察其所安，以知其所能。
志不养，则心气不固；心气不固，则思虑不达；思虑不达，则志意不实。志意不实，则应对不猛；应对不猛，则志失而心气虚；志失而心气虚，则丧其神矣；神丧，则仿佛；仿佛，则参会不一。养志之始，务在安己；己安，则志意实坚；志意实坚，则威势不分，神明常固守，乃能分之。]]
	local c = [[
	]]
	--#GS.TestTrans{Zid=2}
	--print(string.find('/api/ss HTTP/1.1', '%/([%a%_%/]-%.*[%a%_%/]*)% '))
	-- print(Http.makePost('localhost', '/api/ss', {xx='xx',cc='cc'}, {}))
	-- Http.PostConnect('localhost:9000', '/api/ss', {x1='x1',c2='c2'}, {}, function(content,...)
		-- print('OK1_______',...)
		-- dump(content)
	-- end, function(...)
		-- print('Fail1_______')
		-- dump({...})
	-- end)
	-- Http.GetByUrl('http://localhost:9000/api/ss?a=a&b=b', function(content,...)
		-- print('OK2_______',...)
		-- dump(content)
	-- end, function(...)
		-- print('Fail2_______')
		-- dump({...})
	-- end)
	local d = tonumber(os.date('%Y%m%d', os.time()))
	dump(d)
		d = math.floor(d/100)
		dump(d)
	
	print(('SELECT id, name, level, combat, vipLevel FROM game_user where name like "%%%s%%"' ):format('adfsf'))
	
	print(string)
	print("a"+123)

local WK_TIME = {
	__eq = function(t, v) --相等t==v
		return t[1]==v[1] and t[2]==v[2] and t[3]==v[3]
	end,
	__lt = function(t, v) --小于t<v
		local tw,th,tm,vw,vh,vm = t[1],t[2],t[3],v[1],v[2],v[3]
		if tw==vw then
			if th==vh then
				return tm<vm
			else
				return th<vh
			end
		else
			return tw<vw
		end
	end,
	__le = function(t, v) --小于等于t<=v
		local tw,th,tm,vw,vh,vm = t[1],t[2],t[3],v[1],v[2],v[3]
		if tw==vw then
			if th==vh then
				return tm<=vm
			else
				return th<vh
			end
		else
			return tw<vw
		end
	end,
}
	
	local s = {5,8,0}
	local t = {7,9,0}
	local e = {6,20,0} 
	-- local s = {7,8,0}
	-- local t = {2,9,0}
	-- local e = {1,20,0} 
	setmetatable(t,WK_TIME)
	setmetatable(s,WK_TIME)
	setmetatable(e,WK_TIME)
	
	if s <= e then --不跨周
		print('Y',s<=t and t<=e)
	else --跨周
		print('Y',s<=t or t<=e)
	end
	
	
	local s = '/data/app/log/item_2148992_2019-06-03.log'
	local s = '/data/app/log/2148992/item2019-06-03.log'
	

	
	
	
end
test.gs = function()
	local enqueue = _enqueue
	
	-- function _enqueue( _delay, f, name, args, ...)
		-- print(name,_delay, os.now() + _delay)
		-- enqueue(_delay, f, name, args, ...)
	-- end
	
	
	
	function event.onSecond()
	
		-- local reg = debug.getregistry()
		-- local queues = reg[5]
		-- dump(queues,2)
		do return end
		--print('onSecond', CS)
		if _G.CS then
			_G.CS.Hello{T="Hi!CS from"..os.info.line}
		end
		print('zonenum,unitnum',Zone.count(), Unit.count())
	end
	
	local _guid=0
	local Entity = {
		zones = {},
		units = {},
		players = {},
		monsters = {},
	}
	local Component = {
		transform = function() return{}end,
		tiles = function() return{}end,
		equip = function() return{}end,
		bag = function() return{}end,
		attr = function() return{}end,
		buff = function() return{}end,
	}
	local System = {
		Events = {},
		Timer = {},
		Update = {},
		Attr = {},
		Syncor = {},
		RPC = {},
		Item = {
			have = function(pid,id)
			end,
			add = function(pid,id,num)
			end,
			del = function(pid,id,num)
			end,
		},
		Net = {},
		Brain = {},
	}
	local Helper = {
	}
	local Utility = {
	}
	
	
	
	
	
end

if test[os.info.type] then
	test[os.info.type]()
end

function _mainloop()
do return end
	local reg = debug.getregistry()
	local queues = reg[5]
	local called = {}
	
	-- lua_pushnumber(L, timeNow(.001,0) + delayms),lua_rawseti(L, -2, 1);//delayto
	-- lua_pushvalue(L, 2),lua_rawseti(L, -2, 2); //from
	-- lua_pushvalue(L, 3),lua_rawseti(L, -2, 3); //funcorname
	-- lua_pushinteger(L, (lua_Number)argn), lua_rawseti(L, -2, 4);//argn
	local now = os.now()
	--print('now',now)
	for i,v in pairs(queues) do
		v.old = 'wait'
	end
	for i,v in pairs(queues) do
		--print(v[3],now,v[1],now-v[1])
		if v.old=='wait' and v[1]<=now then
			v.old = 'called'
			local f = type(v[3])=='string' and _G[v[3]] or v[3]
			local an = v[4]
			table.insert(called,i)
			--queues[i] = nil
			local a = {}
			for i=5,an+4 do
				table.insert(a,v[i])
			end
			f(unpack(a))
		end
	end
	for _,i in ipairs(called) do
		queues[i] = nil
	end
end


-- do return end
--lua题
--debug.getupvalue 热更代码debug
--元表__eq 表内相等
--只读表
--元表类
--弱表
--表引用
--userdata加元方法
--字串哈希占内存
--__index动态加载配置
--select("#", ...)
--function table.template(t) --适用初始化
	-- return load('return ' .. table.tostr(t))
-- end
--用索引代码elseif
--and or 二元操作
--表创建优化,尽量整体

debug.gc()
collectgarbage('collect')
collectgarbage('collect')
collectgarbage('collect')
collectgarbage('collect')
local TIMES = 1000000
-- local t = os.clock()
-- for i=1,TIMES do
	-- local t1 = {}
	-- for j=1,128 do
		-- t1[j] = 1
	-- end
-- end
-- print(os.clock()-t) --1.29599999999999982
-- collectgarbage('collect')
-- local t = os.clock()
-- for i=1,TIMES do
	-- local t1 = {1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,}
	-- for j=1,128 do
		-- t1[j] = 1
	-- end
-- end
-- print(os.clock()-t) --0.663000000000000256
-- collectgarbage('collect')
-- local t = os.clock()
-- for i=1,TIMES do
	-- local t1 = {false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,}
	-- for j=1,128 do
		-- t1[j] = 1
	-- end
-- end
-- print(os.clock()-t) --0.663000000000000256
-- collectgarbage('collect')
-- local newtab = table.new
-- local t = os.clock()
-- for i=1,TIMES do
	-- local t1 = newtab(128,0)
	-- for j=1,128 do
		-- t1[j] = 1
	-- end
-- end
-- print(os.clock()-t) --0.729999999999999538
-- collectgarbage('collect')

-- local t1 = {1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,1,2,2,3,}
-- local t = os.clock()
-- for i=1,TIMES do
	-- local t2 = {}
	-- for i,v in pairs(t1) do --普通复制
		-- t2[i] = v
	-- end
-- end
-- print(os.clock()-t) --2.31700000000000017
-- collectgarbage('collect')
-- local t = os.clock()
-- for i=1,TIMES do
	-- local t2 = table.new(128,0) --已知容量
	-- for i,v in pairs(t1) do
		-- t2[i] = v
	-- end
-- end
-- print(os.clock()-t) --1.46000000000000085
-- collectgarbage('collect')
-- local t = os.clock()
-- for i=1,TIMES do
	-- local t2 = table.new(table.size(t1)) --取得容量
	-- for i,v in pairs(t1) do
		-- t2[i] = v
	-- end
-- end
-- print(os.clock()-t) --1.49799999999999933

-- local t = os.clock()
-- for i=1,TIMES do
	-- local t2 = table.duplicate(t1) --C层浅复制jit
-- end
-- print(os.clock()-t) --0.704000000000000625
-- collectgarbage('collect')

-- local t = os.clock()
-- for i=1,TIMES do
	-- local t2 = {}
	-- for i,v in pairs(t1) do --普通复制
		-- t2[i] = v
	-- end
-- end
-- print(os.clock()-t) --2.31700000000000017  非jit 7.774
-- collectgarbage('collect')
-- local func = table.template(t1)
-- local t = os.clock()
-- for i=1,TIMES do
	-- local t2 = func() --逆向模板
-- end
-- print(os.clock()-t) --0.000900000000000011 非jit 2.906
-- collectgarbage('collect')
-- local t = os.clock()
-- for i=1,TIMES do
	-- for i,v in pairs(t1) do
	-- end
-- end
-- print(os.clock()-t) --0.459000000000001407
-- collectgarbage('collect')

local obj = {}
function TestLeak()
	print(obj)
end
local refs = debug.findobj( _G, function(o)return o==obj end, '_G' )
dump(refs)
local refs = debug.findobj( debug.getregistry(), function(o)return o==obj end, '_REG') 
dump(refs)


error('teststop')



