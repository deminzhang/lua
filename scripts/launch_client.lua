--launch_client.lua
----------------------------------------------------------------
--define.onSecond{}--秒循环
--local nets = {}
function GetCS()
	return _G.CS
end
function GetGS()
	return _G.GS
end
while false do --connect_cs
	local onConnect = function(net, ip, port, myip, myport)
		_G.CS = net
		
	end
	local onClose = function(net, err, code)
		_G.CS = nil
		os.sleep(1000)
		os.exit(0)
	end
	local listen_cs = os.listenAddr(os.info.server_id,0)
	print('>>connectCS',listen_cs)
	Net.connect(listen_cs,onConnect,onClose,10)
	
end

function event.onSecond()
	onSecond{_delay=1000}
	--print('onSecond', CS)
	if _G.CS then
		_G.CS.Hello{T="Hi!CS fromclient"}
	end
end
onSecond{}

-- Http.PostConnect('10.6.10.230:8081', '/', {op=1}, {}, function(content,...)
	-- print('OK1_______',...)
	-- dump(content)
-- end, function(...)
	-- print('Fail1_______')
	-- dump({...})
-- end)
--test armar
local onFail = function(...)
	print('onFail')
	dump({...})
end
local logfile = 'client.log'
local afterlogin
local host
local userId
local _data = {}
local function onData(data)
	if not data then return end
	for k,v in pairs(data)do
		if type(_data[k])=='table' then
			for k1,v1 in pairs(v) do
				_data[k][k1] = v1
			end
		else
			_data[k] = v
		end
	end
end
local function onChange(changes)
	if not changes then return end
	if changes.updates then
		for k,v in pairs(changes.updates)do
			if type(k)=='number' then
			_data.userData[k] = v
			end
		end
	end
	if changes.removes then
		for k,v in pairs(changes.removes)do
			if type(v)=='table' then
			else
				_data.userData[k] = nil
			end
		end
	end
end
---------------------------------------------------------------
local function tax(t)
	local params = {
		_t = _data.token,
		_a='city.tax',
		double=1,
	}
	Http.PostConnect(host, '/', params, {}, function(ret,...)
		local t = table.fromJson(ret)
		print('return',t.action)
		dump(t,nil,logfile)
		onData(t.data)
		onChange(t.changes)
	end, onFail)
end
local function tax2(t)
	local params = {
		_t = _data.token,
		_a='city.taxcd',
	}
	Http.PostConnect(host, '/', params, {}, function(ret,...)
		local t = table.fromJson(ret)
		print('return',t.action)
		dump(t,nil,logfile)
		onData(t.data)
		onChange(t.changes)
	end, onFail)
end
local function building(t)
	local params = {
		_t = _data.token,
		_a='city.upgrade',
		buildkey=100,
	}
	Http.PostConnect(host, '/', params, {}, function(ret,...)
		local t = table.fromJson(ret)
		print('return',t.action)
		dump(t,nil,logfile)
		onData(t.data)
		onChange(t.changes)
	end, onFail)
end

local function recruit(t)
	local params = {
		_t = _data.token,
		_a='hero.recruit',
		id=12096,
	}
	Http.PostConnect(host, '/', params, {}, function(ret,...)
		local t = table.fromJson(ret)
		print('return',t.action)
		dump(t,nil,logfile)
		onData(t.data)
		onChange(t.changes)
	end, onFail)
end
local function dismiss(t)
	local params = {
		_t = _data.token,
		_a='hero.dismiss',
		id=32064,
	}
	Http.PostConnect(host, '/', params, {}, function(ret,...)
		local t = table.fromJson(ret)
		print('return',t.action)
		dump(t,nil,logfile)
		onData(t.data)
		onChange(t.changes)
	end, onFail)
end
local function herounlock(t)
	local params = {
		_t = _data.token,
		_a='test.cmd',
		op='unlockhero',
		heroId=11,
	}
	Http.PostConnect(host, '/', params, {}, function(ret,...)
		local t = table.fromJson(ret)
		print('return',t.action)
		dump(t,nil,logfile)
		onData(t.data)
		onChange(t.changes)
		--recruit(t)
	end, onFail)
end

local function heropool(t)
	local params = {
		_t = _data.token,
		_a='hero.pool',
	}
	Http.PostConnect(host, '/', params, {}, function(ret,...)
		local t = table.fromJson(ret)
		print('return',t.action)
		dump(t,nil,logfile)
		_data.userData.heropool = t.data
	end, onFail)
end

local function equipbuy(t)
	local params = {
		_t = _data.token,
		_a='equip.buy',
		equipId = 1002,
	}
	Http.PostConnect(host, '/', params, {}, function(ret,...)
		local t = table.fromJson(ret)
		print('return',t.action)
		dump(t,nil,logfile)
		onData(t.data)
		onChange(t.changes)
	end, onFail)
end
local function equipsell(t)
	local params = {
		_t = _data.token,
		_a='equip.sell',
		ids = table.toJson{16064}--'[16064]',
	}
	Http.PostConnect(host, '/', params, {}, function(ret,...)
		local t = table.fromJson(ret)
		print('return',t.action)
		dump(t,nil,logfile)
		onData(t.data)
		onChange(t.changes)
	end, onFail)
end
local function equip(t)
	local params = {
		_t = _data.token,
		_a='equip.wear',
		id = 13064,
		heroId = 0,
	}
	Http.PostConnect(host, '/', params, {}, function(ret,...)
		local t = table.fromJson(ret)
		print('return',t.action)
		dump(t,nil,logfile)
		onData(t.data)
		onChange(t.changes)
	end, onFail)
end
local function equiprefine(t)
	local params = {
		_t = _data.token,
		_a='equip.refine', 
		id = 11064
	}
	Http.PostConnect(host, '/', params, {}, function(ret,...)
		local t = table.fromJson(ret)
		print('return',t.action)
		dump(t,nil,logfile)
		onData(t.data)
		onChange(t.changes)
	end, onFail)
end

local function test(t)
	local params = {
		_t = _data.token,
		-- _a='test.prestige',
		--_a='test.silver',
		-- _a='test.level',
		_a='test.exploit',
		num=1000,
		-- level = 100,
		-- id = 100,
	}
	Http.PostConnect(host, '/', params, {}, function(ret,...)
		local t = table.fromJson(ret)
		print('return',t.action)
		dump(t,nil,logfile)
		onData(t.data)
		onChange(t.changes)
	end, onFail)
end
local function getSalary(t)
	local params = {
		_t = _data.token,
		_a='city.getSalary', 
		--_a='city.getNobility', 
	}
	Http.PostConnect(host, '/', params, {}, function(ret,...)
		local t = table.fromJson(ret)
		print('return',t.action)
		dump(t,nil,logfile)
		_data.userData.nobility = t.data
		onChange(t.changes)
	end, onFail)
end
local function cityrecruit(t)
	local params = {
		_t = _data.token,
		_a='city.recruit', 
		num=1, 
	}
	Http.PostConnect(host, '/', params, {}, function(ret,...)
		local t = table.fromJson(ret)
		print('return',t.action)
		dump(t,nil,logfile)
		onChange(t.changes)
	end, onFail)
end
local function draft(t)
	local params = {
		_t = _data.token,
		_a='city.draft', 
	}
	Http.PostConnect(host, '/', params, {}, function(ret,...)
		local t = table.fromJson(ret)
		print('return',t.action)
		dump(t,nil,logfile)
		onChange(t.changes)
	end, onFail)
end
-- 3.4.解锁训练槽
local function trainopen(t)
	local params = {
		_t = _data.token,
		_a='hero.trainopen', 
	}
	Http.PostConnect(host, '/', params, {}, function(ret,...)
		local t = table.fromJson(ret)
		print('return',t.action)
		dump(t,nil,logfile)
		onChange(t.changes)
	end, onFail)
end
-- 3.5.训练槽升级
local function trainposup(t)
	local params = {
		_t = _data.token,
		_a='hero.trainposup', 
		pos=1,
	}
	Http.PostConnect(host, '/', params, {}, function(ret,...)
		local t = table.fromJson(ret)
		print('return',t.action)
		dump(t,nil,logfile)
		onChange(t.changes)
	end, onFail)
end
-- 3.6.训练槽换武将
local function trainchange(t)
	local params = {
		_t = _data.token,
		_a='hero.trainchange', 
		pos=1,
		id=11096,
		-- id=6096,
	}
	Http.PostConnect(host, '/', params, {}, function(ret,...)
		local t = table.fromJson(ret)
		print('return',t.action)
		dump(t,nil,logfile)
		onChange(t.changes)
	end, onFail)
end
-- 3.7.训练槽自动转生开关
local function transauto(t)
	local params = {
		_t = _data.token,
		_a='hero.transauto', 
		pos=1,
	}
	Http.PostConnect(host, '/', params, {}, function(ret,...)
		local t = table.fromJson(ret)
		print('return',t.action)
		dump(t,nil,logfile)
		onChange(t.changes)
	end, onFail)
end
-- 3.8.训练师开启
local function traineropen(t)
	local params = {
		_t = _data.token,
		_a='hero.trainer', 
		ids='[1,2,3,4,5]',
	}
	Http.PostConnect(host, '/', params, {}, function(ret,...)
		local t = table.fromJson(ret)
		print('return',t.action)
		dump(t,nil,logfile)
		onChange(t.changes)
	end, onFail)
end
-- 3.9.训练师购买次数
local function trainerbuy(t)
	local params = {
		_t = _data.token,
		_a='hero.trainerbuy', 
		id=1, 
	}
	Http.PostConnect(host, '/', params, {}, function(ret,...)
		local t = table.fromJson(ret)
		print('return',t.action)
		dump(t,nil,logfile)
		onChange(t.changes)
	end, onFail)
end
-- 3.a.武将突飞训练
local function fasttrain(t)
	local params = {
		_t = _data.token,
		_a='hero.fasttrain', 
		pos=1,
		-- id=12096,
		-- id=11096,
		-- id=6096,
	}
	Http.PostConnect(host, '/', params, {}, function(ret,...)
		local t = table.fromJson(ret)
		print('return',t.action)
		dump(t,nil,logfile)
		onChange(t.changes)
	end, onFail)
end
-- 3.b.武将转生
local function herotrans(t)
	local params = {
		_t = _data.token,
		_a='hero.trans', 
		pos=1,
	}
	Http.PostConnect(host, '/', params, {}, function(ret,...)
		local t = table.fromJson(ret)
		print('return',t.action)
		dump(t,nil,logfile)
		onChange(t.changes)
	end, onFail)
end

local function userInit(t)
	local params = {
		_t = _data.token,
		_a='user.init',
		heroId=1,
		icon=1,
	}
	Http.PostConnect(host, '/', params, {}, function(ret,...)
		local t = table.fromJson(ret)
		print('return',t.action)
		dump(t,7,logfile)
		onData(t.data)
		onChange(t.changes)
		afterlogin(t)
	end, onFail)
end
local function login()
	local params = {
		_a='user.login',
		id=userId,
	}
	Http.PostConnect(host, '/', params, {}, function(ret,...)
		local t = table.fromJson(ret)
		print('return',t.action)
		print('userData=')
		dump(t.data.userData,7,logfile)
		onData(t.data)
		onChange(t.changes)
		if t.data.userData then
			afterlogin(t)
		else
			userInit(t)
		end
	end, onFail)
end
local function makeDocs()
	local params = {
		_a='develop.makeDocs',
		id=userId,
	}
	Http.PostConnect(host, '/', params, {}, function(ret,...)
		local t = table.fromJson(ret)
		print('return',t.action)
		dump(t,nil,logfile)
	end, onFail)
end
function afterlogin(t)
	-- building(t)
	--tax(t)
	--tax2(t)
	-- heropool(t)
	-- equipbuy(t)
	--equipsell(t)
	--equip(t)
	-- equiprefine(t)
	-- test(t)
	--getSalary(t)
	-- recruit(t)
	-- cityrecruit(t)
	-- draft(t)
	-- trainopen(t)
	-- trainposup(t)
	-- trainchange(t)
	-- fasttrain(t)
	-- transauto(t)
	-- traineropen(t)
	-- trainerbuy(t)
	-- herotrans(t)
	
end

--host = '10.45.20.23:8081' --new-server
host = '10.45.20.23:8082' --dev-server
userId = 20170159000 + 77  -- 80
login()
-- makeDocs()

