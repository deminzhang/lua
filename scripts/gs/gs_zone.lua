--Zone场景类
--青海长云暗雪山，孤城遥望玉门关。黄沙百战穿金甲，不破楼兰终不还。
dofile'gs/gs_zonetilemgr.lua'
----------------------------------------------------------------
local Zone = Zone
local _meta = Object.newMeta(Zone)
----------------------------------------------------------------
--cfg
----------------------------------------------------------------
--tolocal
local new = table.new
local insert = table.insert
local ceil = math.ceil
local from32l = string.from32l
local Unit = Unit
local CONFIG = CONFIG
local Object = Object
local TileMgr = TileMgr
----------------------------------------------------------------
--local
local _zones = table.new(0,512)
local _zonenum = 0
local _privateZones = {} 	--k:pid v:guid
local _normalZones = {} 	--k:id v:guid

----------------------------------------------------------------
--public 公共类
function Zone.new(id, info)
	local cfg = cfg_zone[id]
	local guid = Object.newGuid()
	local tm = TileMgr.new(cfg.tilex,cfg.tiley,cfg.tilew)
	local o = {
		--base
		type = 'zone',
		guid = guid,		--objectID
		id = id,			--configID
		cfg = cfg,			--config
		tickSave = cfg.tickSave or false,--跳图后保存
		noReborn = cfg.noReborn or false,--跳图后保存

		--数据
		info = info or {},	--k={}同步到前端的动态值如门开关,动态生成单位
		data = {},			--k=v 不需同步到前端的动态值
		--统计
		counts = {}, 		--单位计数{[type]=num,...}
		unitNum = 0,		--单位总计数
		--集合
		tileMgr = tm,
		tilex = tm.tilex,	--地图最大宽
		tilez = tm.tilez,	--地图最大宽
		inst = false,		-- or {}下层实例事件
		timers = {},		--计时器{tid=true,...}
		units = {},			--{id=true,...}
		unit_update = {},	--帧更新单位{id=true,...}
		unit_updateOnce ={},--只更新一次{id=true,...}
		unit_allVisible ={},--全图同步
		ownerpid = 0,		--所属角色
		roles = {},			--角色{id=true,...}
		-- monster = {},		--{id=true,...}
		-- npc = {},		--{id=true,...}
		-- door = {},		--{id=true,...}
		-- dynamics = {},	--{id=true,...}
		-- buffs = {},		--{id=true,...}
		-- traps = {},		--{id=true,...}
		-- mines = {},		--{id=true,...}
		
		--频用方法直接挂对象上,减少走__index
		--update = Zone.update,
	}
	setmetatable(o,_meta)
	
	_zones[guid] = o
	_zonenum = _zonenum + 1
	Object.ref(o)
	--
	if cfg.createOnNew~=0 then
		o:creates()
	end
	return o
end
_meta.__call = Zone.new
function Zone.all() return _zones end
function Zone.count() return _zonenum end
function Zone.get(guid) return _zones[guid] end
function Zone.del(guid)
	local z = _zones[guid]
	if not z then
		error('zone.del repeat'..guid)
	end
	-- 清理所有的单位
	local uget = Unit.get
	local zdelUnit = Zone.delUnit
	for eguid,_ in pairs(z.units) do
		local e = uget(eguid)
		assert(e.type~='role', 'some role in zone before Zone.del')
		zdelUnit(z, e, 'Zone.del')
	end
	
	z:clearTimer()
	_zones[guid] = nil
	_zonenum = _zonenum - 1
	Object.unref(guid)
end
function Zone.byID(id, pid)	--非副本
	local cfg = cfg_zone[id]
	assert(cfg, id)
	local type = cfg.type
	if type=='normal' then	--公共野外 不释放
		local guid = _normalZones[id]
		if guid then return _zones[guid] end
		local z = Zone.new(id)
		_normalZones[id] = z.guid
		return z
	elseif type=='private' then	--单人野外 人走图释放
		assert(pid,'no pid')
		local guid = _privateZones[pid]
		if guid then
			local z = _zones[guid]
			assert(z, '_zones idx Fail')
			if z.id == id then
				return z
			end
		end
		local z = Zone.new(id)
		_privateZones[pid] = z.guid
		z.ownerpid = pid
		assert(z, 'Zone.new Fail2')
		return z
	else
		error('Zone.byID only support normal/private')
	end
end

----------------------------------------------------------------
--updates更新管理
function Zone:update(e, now)
	if self.closeAfterRoleExit then --最后一个玩家离开后关闭
		Zone.del(self.guid)
		return
	end
	--常更新
	local o
	local uget = Unit.get
	if CONFIG.TEST_AI_ALWAYS_AWAKE then
		for guid, _ in pairs(self.units) do
			o = uget(guid)
			if o then o:update(e, now) end
		end
	else
		for guid, _ in pairs(self.unit_update) do
			o = uget(guid)
			if o then o:update(e, now) end
		end
	end
	--更新一次 TODO应当改在sleepAI()里
	local unit_updateOnce = self.unit_updateOnce
	for guid, _ in pairs(unit_updateOnce) do
		o = uget(guid)
		if o then
			o:updateOnce(e, now)
			unit_updateOnce[guid] = nil
		end
	end
	--地图专用玩法
	if self.gbase then self.gbase:onUpdate(e, now) end
	--通用事件
	--onZoneUpdate{ zone = self, zoneid = self.id, e = e}
end
Zone.addTimer = Object.addTimer
Zone.delTimer = Object.delTimer
Zone.clearTimer = Object.clearTimer
Zone.delTimerGroup = Object.delTimerGroup

----------------------------------------------------------------
--units单位管理
function Zone:addUnit(o)
	local guid = o.guid
	local otype = o.type
	local counts = self.counts
	counts[otype] = (counts[otype] or 0) + 1
	self.unitNum = self.unitNum + 1
	self.units[guid] = otype
	o:setZone(self)
	-- addToTile
	local pos = o:getv'pos'
	local tile = self.tileMgr:getTile(pos.x, pos.z)
	if not tile then --出界
		error('tileOut:'..pos.x..','..pos.z..debug.traceback())
	end
	tile:addUnit(o)
	CallRound(o,true).AddUnit{T=o:getData()}
	
	if otype=='role' then
		self.unit_update[guid] = true
	else
		-- if o.tile.roleNum>0 then
		-- end
	end
end
function Zone:delUnit(o, reason)
	local guid = o.guid
	local otype = o.type
	local counts = self.counts
	counts[otype] = counts[otype] - 1
	self.unitNum = self.unitNum - 1
	self.units[guid] = nil
	-- delFromTile
	local tile = o.tile
	if tile then
		CallRound(o).DelUnit{Guid=o.guid}
		if otype=='role' and o:getNet() then
			-- local t = o:getRoundUnits(true)
			-- if next(t) then
				-- CallRole(o).DelUnits{List=table.keys(t)}
			-- end
			CallRole(o).DelZoneUnits{Zid=self.id}
		end
		tile:delUnit(o)
	end
	
	o:setZone(nil)
	self.unit_update[guid] = nil
	--私人场景,人走图清
	if otype=='role' and self.ownerpid==o.pid then
		_privateZones[self.ownerpid] = nil
		Zone.del(self.guid)
	end
end
function Zone:getUnit(guid)
	if self.units[guid] then --在本场景
		return Object.get(guid)
	end
end
--area of sight
function Zone:procAOI(unit,pos)
	local tileMgr = self.tileMgr
	local newtile = tileMgr:getTile(pos.x, pos.z)
	if not newtile then --出界. 强制界内
		Log.warn('position is out range')
		if pos.x < 0 then pos.x = 0
		elseif pos.x > tileMgr.tilex then
			pos.x = tileMgr.tilex
		end
		if pos.z < 0 then pos.z = 0
		elseif pos.z > tileMgr.tilez then
			pos.z = tileMgr.tilez
		end
		newtile = tileMgr:getTile(pos.x, pos.z)
		if not newtile then
			assert(newtile,'tileOut:'..pos.x..','..pos.z..debug.traceback()) 
		end
	end
	local oldtile = unit.tile
	if oldtile then
		if oldtile == newtile then return end
		oldtile:delUnit(unit)
	end
	newtile:addUnit(unit)
	--AOI
	local uget = Unit.get
	local mguid, mtype = unit.guid, unit.type
	local o
	local news = newtile:allSight()
	if oldtile then
		local olds = oldtile:allSight()
		for tile,_ in pairs(olds) do
			if not news[tile] then
				for guid,type in pairs(tile.units) do
					if mguid~=guid then
						if mtype=='role' then --我删
							CallRole(unit).DelUnit{Guid=guid}
						end
						if type=='role' then --删我
							o = uget(guid)
							CallRole(o).DelUnit{Guid=mguid}
						end
					end
				end
			end
		end
		for tile,_ in pairs(news) do
			if not olds[tile] then
				for guid,type in pairs(tile.units) do
					if mguid~=guid then
						o = uget(guid)
						if mtype=='role' then --我建
							CallRole(unit).AddUnit{T=o:getData()}
						end
						if type=='role' then --建我
							CallRole(o).AddUnit{T=unit:getData()}
						end
					end
				end
			end
		end
	else
		for tile,_ in pairs(news) do
			for guid,type in pairs(tile.units) do
				if mguid~=guid then
					o = uget(guid)
					if mtype=='role' then --我建
						CallRole(unit).AddUnit{T=o:getData()}
					end
					if type=='role' then --建我
						CallRole(o).AddUnit{T=unit:getData()}
					end
				end
			end
		end
	end
end
--同步动态数据
function Zone:getData(role)
	local data = {
		dyna = self.dyna,
		effect = self.effect,
		door = self.door,
		npc = self.npc,
	}
	--getZoneData{zone=self, info=data, role=role}
	local gbase = self.gbase
	if gbase then gbase:onGetData(data) end
	return data
end

function Zone:creates(groupidx)	--创建编辑器布置的单位
	local cfg = self.cfg
	if not cfg.create then return end
	--[[结构create = {
		{type='mon',id=,pos={x=,y=,z=,r=},ai=替换初始AI,step=阶段,boss=boss}
		{type='npc',id=,pos={x=,y=,z=,r=}}
		{type='mine',id=,pos={x=,y=,z=,r=}}
		{type='trap',id=,pos={x=,y=,z=,r=}}
	}]]
	for i, v in pairs(cfg.create) do
		if v.type=='mon' and not nomonster then
			self:createMonster(v.id, v.pos,{editKey=i})
		elseif v.type=='mine' then
			self:createMine(v.id, v.pos,{editKey=i})
		end
	end
	--TOTEST
	for i=1,500,3 do
		for j=1,500,3 do
			self:createMonster(1, {x=i,y=1,z=j,r=0})
		end
	end
end

function Zone:createMonster(id, pos, preSet) --pos={x=,y=,z=,r=}
	local x = pos.x or 0
	local y = pos.y or 0
	local z = pos.z or 0 --修正高
	local r = pos.r or 0 --朝向[0,math.pi]
	local m = Monster.new(id)
	if preSet then
		--local attr, aa = {{}}, false
		for k, v in pairs(preSet) do
			-- if cfg_attr[k] or cfg_attr[string.sub(k, 1,-2)] then
				-- attr[1][k] = v
				-- aa = true
			-- else
				if m:isdef(k) then
					m:sp(k, v)
				else
					m[k] = v
				end
			--end
		end
		-- if aa then
			-- AttrSys.add(m, attr, false, 'mon')
		-- end
		if preSet.maxHp or preSet.maxHpX then
			m:setv('hp', m:getv'maxHp')
		end
	end
	--m:setBornPos(x, y, z, r)
	m.bornPos = {x=x,y=y,z=z}
	--m:setSavePos(x, y)
	m:setPos(x, y, z, r)
	-- if m.baseai then
		-- for _,v in ipairs(m.baseai) do
			-- assert(cfg_ai[v],'怪'..id..'配用不存在的AI'..v)
			-- m:addAI(v)
		-- end
	-- end
	self:addUnit(m)
	-- local bornbuffs = cfg_mon[id].bornbuffs
	-- for _, buff in ipairs(bornbuffs or { }) do
		-- BuffSys.addBuffGroup(m, m, { groupID = buff, type = 'bornbuff' })
	-- end
	--onMonBorn{mon=m} --AI
	m:setv('born', false)
	return m
end

----------------------------------------------------------------
--event
function event.loadConfig()
	dofile"config/cfg_zone.lua"
end
function event.afterConfig()

end
function event.checkConfig()

end

function event.onStart()
	if os.info.gstype=='world' then --世界线预创野外
		Zone.byID(1)
		-- for i=1,10 do
			-- Zone.byID(3,i)
		-- end
	else --副本线现用现创
	
	end
end

local lastuptime = _now()
function event.onUpdate(e)
	local now = _now()
	e = now - lastuptime
	lastuptime = now
	--print('Zone:update',e)
	for _, z in pairs(_zones) do
		z:update(e, now)
	end
end

----------------------------------------------------------------
--RPC
define.TestTrans{Zid=0}
define.AskTransTo{Zid=0, Point=0}	--Zid:zoneID, Point:transPoint
define.IntoMark{Zid=0,Mark='',Sign='',T=0}
define.LeaveMark{Zid=0,Mark='',Sign='',T=0}

when{}function TestTrans(Zid)
	local role = Role.byNet(_from)
	role:transTo(Zid, 1,1,1,0)
end

when{}function AskTransTo(Zid,Point)
	local role = Role.byNet(_from)
	
end

when{}function IntoMark(Zid,Mark,Sign,T)

end

when{}function LeaveMark(Zid,Mark,Sign,T)

end


do return end ----------------------------------------------------
do return end ----------------------------------------------------
do return end ----------------------------------------------------
do return end ----------------------------------------------------
do return end ----------------------------------------------------
do return end ----------------------------------------------------
do return end ----------------------------------------------------
do return end ----------------------------------------------------
do return end ----------------------------------------------------
do return end ----------------------------------------------------
do return end ----------------------------------------------------
do return end ----------------------------------------------------
do return end ----------------------------------------------------
do return end ----------------------------------------------------
do return end ----------------------------------------------------
do return end ----------------------------------------------------
do return end ----------------------------------------------------
do return end ----------------------------------------------------

----------------------------------------------------------------
local pathcaches = { }
--static方法
function Zone.createPathFinder(cogfile, door)
	local keys = door and table.keys(door) or { }
	table.sort(keys)
	local c = pathcaches[cogfile]
	if not c then
		c = { }
		pathcaches[cogfile] = c
	end
	for ii = 1, #keys do
		local key = keys[ii]
		local cc = c[key]
		if not cc then
			cc = { }
			c[key] = cc
		end
		c = cc
	end
	local pf = c[1]
	if not pf then
		pf = _PathFinder.new()
		pf:loadPath(cogfile)
		local rect = _Rect.new()
		pf:getWalkArea(rect, true)
		pf.rect = rect
		pathcaches[cogfile] = pf
		for ii = 1, #keys do
			local key = keys[ii]
			pf:enableGroup(key, true)
		end
	end
	return pf
end
function Zone.getMarkerPos(zoneid,marker)
	local cfg = cfg_zone[zoneid]
	assert(cfg,zoneid)
	assert(cfg.markers, 'zone ' ..zoneid.. ' not have markers')
	local mkrs = cfg.markers
	local m = mkrs[marker]
	assert(m,zoneid..'no marker:'..marker)
	return m.pos[1],m.pos[2],m.pos[3],m.rot[4],m, m.sizeR or 0--x,y,z,r,m, sizeR
end
function Zone.isSavePos(fromzone, tozone)
	if not fromzone then return end
	if not tozone then return end
	for k, v in pairs(Cfg.cfg_savepos{ }) do
		if v.zone == fromzone and v.tozone == tozone then
			return true
		end
	end
end
function Zone.getNpcPos(zoneid, npcid)
	local cfgz = cfg_zone[zoneid]
	assert(cfgz, zoneid..' invalid zoneid in Zone.getNpcPos')
	for i, v in pairs(cfgz.npcs) do
		if v.id == npcid then
			return v.pos
		end
	end
end

--object方法--------------------------------------------------------------
function Zone:getWUnits()
	return self.wenities
end
function Zone:getBornPos(role)
	if self.gbase then
		return self.gbase:getBornPos(self.id, role.guid)
	else
		local cfg = cfg_zone[self.id]
		assert(cfg,self.id)
		local mkrs = cfg.markers
		local m = mkrs['revive_01']
		if m then
			local x, y, z, r = Zone.getMarkerPos(self.id, 'revive_01')
			return { x = x, y = y, z = z, r = r }
		else
			Log.sys('no marker revive_01',debug.traceback())
			local x = cfg.pos and cfg.pos[1] or 0
			local y = cfg.pos and cfg.pos[2] or 0
			return { x = x, y = y, z = 0, r = 0 }
		end
	end
end
function Zone:createMine(id, pos, default) --pos={x=,y=,z=,r=}
	local x = pos.x or 0
	local y = pos.y or 0
	local z = pos.z or 0 --修正高
	local r = pos.r or 0 --朝向[0,math.pi]
	local m = Mine.new(id)

	assert(m.preGatherBy,'')
	if default then
		for k,v in pairs(default) do
			if m:isSp(k) then
				m:sp(k, v)
			else
				m[k] = v
			end
		end
	end
	m:setPos(x, y, z, r)
	self:addUnit(m)
	onMineBorn{mine=m}
	m:sp('born', false)
	return m
end
function Zone:createTrap(id, pos, default)	--动态触发点 --pos={x=,y=,z=,r=}
	local x = pos.x or 0
	local y = pos.y or 0
	local z = pos.z or 0 --修正高
	local r = pos.r or 0 --朝向[0,math.pi]
	local o = Trap.new(id, pos)
	if default then
		for k,v in pairs(default) do
			if o:isSp(k) then
				o:sp(k, v)
			else
				o[k] = v
			end
		end
	end
	o:setPos(x, y, z, r)
	self:addUnit(o)
	return o
end
function Zone:createNpc(id, pos, default)	--动态NPC+ 只许在动态地图用
	local cfg = cfg_zone[self.id]
	--assert(cfg.type ~= 0,'Zone:createNpc not support zonetype=0' .. self.id)
	local idx = #self.npc+1
	local createkey = 'npc'..idx
	local npc = {
		id = id,
		type = 'npc',
		currPos = {x=pos.x,y=pos.y,z=pos.z,r=pos.r},
		createkey = createkey,
		guid = id..'|'..createkey,
		idx = idx,
	}
	if default then
		for k,v in pairs(default) do
			npc[k] = v
		end
	end
	self.npc[idx] = npc
	CallZone(self).CreateEntity{ Info = npc }
	return npc
end
function Zone:getNpc(guid)
	for idx, n in pairs(self.npc) do
		if n.guid == guid then
			return n
		end
	end
end
function Zone:getNpcById(id)
	for idx, n in pairs(self.npc) do
		if n.id == id then
			return n
		end
	end
end
function Zone:delNpc(guid, lab)	--动态NPC-
	--Log.sys('delNpc', lab,  guid)
	for idx, npc in pairs(self.npc) do
		if npc.guid == guid then
			self.npc[idx] = nil
			--Log.sys('DelEntity delNpc', lab,  guid)
			CallZone(self).DelEntity{ GUIDS = { guid } }
			return npc
		end
	end
end
function Zone:delNpcs(guids, lab)	--动态NPC-
	for _, guid in pairs(guids) do
		for idx, npc in pairs(self.npc) do
			if npc.guid == guid then
				self.npc[idx] = nil
				--Log.sys('DelEntity delNpc', lab,  guid)
			end
		end
	end
	CallZone(self).DelEntity{ GUIDS = guids }
end

function Zone:setDyna(k, v)
	if self.dyna[k] == v then return end
	self.dyna[k] = v
	CallZone(self).SetDynascene{ Dyna = { [k] = v } }
end
function Zone:setDynas(dynas)
	local send = {}
	for k, v in pairs(dynas) do
		if self.dyna[k] ~= v then
			self.dyna[k] = v
			send[k] = v
		end
	end
	CallZone(self).SetDynascene{ Dyna = send }
end
function Zone:setAreaEffect(k, v, t)
	if self.effect[k] == v then return end
	self.effect[k] = v
	CallZone(self).SetDynaEffect{ Dyna = { [k] = v }, T=t }
end
function Zone:setDoor(k, open, other)
	assert(type(open)=='boolean', 'open or not must boolean')
	if not self.door[k] == not open then return end
	self.door[k] = open and true or nil

	if other then
		self[ other .. 'pathfinder' ].enableGroup(k, not open)
	else
		--self.pathfinder.enableGroup(k, not open)
		self.pathfinder = Zone.createPathFinder("zone/"..cfg_zone[self.id].cog, self.door)
	end

	CallZone(self).SetDoor{ Door = { [k] = open } }
end

_G._GetZoneData = function(param, net, player)
	local role = GsRole.byNet(net)
	if not role then return { } end
	local zone = role:getZone()
	local cfg = cfg_zone[zone.id]
	if not cfg.create then return { } end
	return cfg.create
end
--evevnt---------------------------------
when{} function loadConfigGS()
	dofile'config/cfg_zone.lua'
	--cfg_zone[0] = nil
	for id,v in pairs(cfg_zone) do
		v.markers = {}
		--地编mark,尽量不用
		-- if v.markFile then
			-- local f1 = loadfile('zone/'..v.markFile)
			-- if f1 then
				-- for k,vv in pairs(f1()) do
					-- v.markers[k]=vv
				-- end
			-- end
		-- end
		--内编mark 覆盖同命编mark
		local f2 = loadfile('zone/'..id..'marker.lua')
		if f2 then
			for k,vv in pairs(f2()) do
				v.markers[k]=vv
			end
		else
			if id > 0 then
				Log.sys('Marker:', 'zone/' .. id .. 'marker.lua', ' not exist')
			end
		end
		--单位创建数据
		local f3,b = loadfile('zone/'..id..'create.lua')
		if f3 then
			v.create = f3()
		end
		--单位创建数据
		local f4,b = loadfile('zone/'..id..'npc.lua')
		if f4 then
			v.npcs = f4()
		end
	end

	dofile'config/cfg_transpoint.lua'
	for _,v in pairs(cfg_transpoint) do
		local scfg = cfg_zone[v.zone]
		if v.tozone and scfg.type ~= 6 then
			when{zoneid=v.zone,mark=v.mark}
			function onIntoMark(role,zoneid,mark)
				local x,y,z,r = Zone.getMarkerPos(v.tozone,v.tomark)
				role:transTo(v.tozone, x,y,z,r)
			end
		end
	end
end
when{} function checkConfigGS()
	for id,v in pairs(cfg_zone) do
		assert(math.abs(id)<=UINT,'zone id is too big:'..id..'>'.. UINT)
		if id ~= 0 then
			assert(Zone.TYPE[v.type],id..' invalid zone type '..v.type)
		end
	end
	for _,v in pairs(cfg_transpoint) do
		assert(cfg_zone[v.zone], v.zone..' invalid zoneid in cfg_transpoint')
		assert(cfg_zone[v.zone].markers[v.mark], v.mark..' invalid mark in cfg_transpoint')
		if v.tozone then
			assert(cfg_zone[v.tozone], v.tozone..' invalid tozone in cfg_transpoint')
			assert(cfg_zone[v.tozone].markers[v.tomark], v.tomark..' invalid tomark in cfg_transpoint')
		end
	end
end


--PRC------------------------------------
cdefine.c.IntoMark{Zid=0,Mark='',Sign='',T=0}
cdefine.c.LeaveMark{Zid=0,Mark='',Sign='',T=0}
cdefine.cs.TaskNewMonster{Token='',ID=0,Num=0,Mark='',Interval=0,Info={}}
cdefine.cs.EffectChange{ Token = '', State = '', Dyna = '' }
cdefine.cs.AreaChange{ Token = '', From = '', To = '', Time = 0 }
cdefine.cs.TaskChangeBody{ Token = '' }
cdefine.cs.TaskClearChange{ Token = '' }

when{ }
function TaskChangeBody(Token)
	local role = GsRole.byToken(Token)
	_ChangeSys.beginChange(role)
end
when{ }
function TaskClearChange(Token)
	local role = GsRole.byToken(Token)
	_ChangeSys.cleanCD(role)
end

when{ }
function EffectChange(Token, State, Dyna)
	local r = GsRole.byToken(Token)
	if not r then return end
	local zone = r:getZone()
	zone:setDyna(Dyna, State)
end
when{ }
function AreaChange(Token, From, To, Time)
	local r = GsRole.byToken(Token)
	if not r then return end
	local zone = r:getZone()
	zone:setAreaEffect(From, To, Time)
end

when{_order=0}
function IntoMark(Zid,Mark,Sign,T,_args)
	local r = GsRole.byNet(_from)
	if not r then return end
	if not r:getZone() then return end --不在场景中
	if Cd(r,'IntoMark'..Mark,200) then _zdm('>>IntoMark Cd') return end
	if not DEBUGNOCHECK then
		local t = _now(1)
		if T-t > Zone.INMARKDELAY then _zdm('>>IntoMark Delay'..(T-t)) return end
		local s = string.format('%d|%s|',Zid,Mark)..T
		local sign = s:md5()
		if sign~=Sign then
			_zdm('>>IntoMark sign invalid')
			_zdm(s, sign, Sign)
			return
		end
	end
	_zdm('-GS IntoMark',Zid,Mark)
	assert(r:getZone(), 'IntoMark: role:getZone()==nil')
	onIntoMark{role=r,zoneid=Zid,mark=Mark}
	CallCSByRole(r).IntoMark{ Token = r.getToken(), Zid = Zid, Mar = Mark }
end

when{_order=0}
function LeaveMark(Zid,Mark,Sign,T,_args)
	local r = GsRole.byNet(_from)
	if not r then return end
	if not r:getZone() then return end --不在场景中
	if Cd(r,'LeaveMark'..Mark,100) then _zdm('>>LeaveMark Cd') return end
	if not DEBUGNOCHECK then
		local t = _now(1)
		if T-t > Zone.INMARKDELAY then _zdm('>>LeaveMark Delay'..(T-t)) return end
		local s = string.format('%d|%s|',Zid,Mark)..T
		local sign = s:md5()
		if sign~=Sign then
			_zdm('>>LeaveMark sign invalid')
			_zdm(s, sign, Sign)
			return
		end
	end
	_zdm('-PRC LeaveMark',Zid,Mark)
	assert(r:getZone(), 'LeaveMark: role:getZone()==nil')
	onLeaveMark{role=r,zoneid=Zid,mark=Mark}
end

when{ } function TaskTransTo(Token, Zid, Marker)
	_yyf('__________________________________TaskTransTo')
	local role = GsRole.byToken(Token)
	if not role then return end
	local x,y,z,r = Zone.getMarkerPos(Zid, Marker)
	role:transTo(Zid, x,y,z,r)
end

cdefine.cs.QuickTransTo{ Token='',Zid=0,Marker='' }
cdefine.cs.QuickTransToNpc{ Token='',Zid=0,Npc=0 }
when{} function QuickTransTo(Token, Zid, Marker)
	local role = GsRole.byToken(Token)
	if not role then return end
	if(Marker == '') then
		Marker = 'revive_01'
	end
	assert(role:getZone(), 'QuickTransTo: role:getZone()==nil')
	local x,y,z,r = Zone.getMarkerPos(Zid, Marker)
	role:transTo(Zid, x,y,z,r)
end
when{} function QuickTransToNpc(Token, Zid, Npc)
	local role = GsRole.byToken(Token)
	if not role then return end
	assert(role:getZone(), 'QuickTransToNpc: role:getZone()==nil')
	local pos = Zone.getNpcPos(Zid, Npc)
	if not pos then return end
	role:transTo(Zid, pos.x,pos.y,pos.z)
end

when{} function TaskNewMonster(Token, ID, Num, Mark, Interval, Info)
	local r = GsRole.byToken(Token)
	if not r then return end
	local zone = r:getZone()
	if not zone then return end
	for i = 1, Num do
		local cb = function()
			local x,y,z,r = Zone.getMarkerPos(zone.id, Mark..i)
			local pos = {x=x,y=y,z=z,r=r}
			if Info.activetime then
				local m = zone:createMonster(ID, pos, { active = Info.active, noReborn=true })
				m.alwaysupdate = true
				local mcb = function()
					m:setProp('active', true)
				end
				zone:addTimer(Info.activetime, mcb)
			else
				zone:createMonster(ID, pos, { noReborn=true })
			end
		end
		if Interval and i > 1 then
			zone:addTimer(Interval*(i - 1), cb, 'createmonster')
		else
			cb()
		end
	end
end

when{_order=0} function SetServerInfo(K, T)
	GS.serverinfo[K] = T.v
end