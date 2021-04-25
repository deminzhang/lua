--Unit单位伪基类
----------------------------------------------------------------
local Unit = Unit
local _meta = Object.newMeta(Unit)
----------------------------------------------------------------
--const
local ARRIVE_DIS = 0.05	--位移差小于此值则到达
----------------------------------------------------------------
--to local
local Object = Object
local Zone = Zone
local _Vector2 = _Vector2
local _Vector3 = _Vector3
local new = table.new
local acos = math.acos
local sqrt = math.sqrt
local insert = table.insert
local CallRole = CallRole
local CallRound = CallRound
local CallCSByRole = CallCSByRole
----------------------------------------------------------------
--local
local units = table.new(0,4096)	--{[guid]=unit,...}
local unitNum = 0
local counts = table.new(0,8)	--[utype] = count
----------------------------------------------------------------
----------------------------------------------------------------
--Unit.
function Unit.new(isFight,temp)	--isFight:初始化战斗属性,temp:临时计算用不分配guid
	local guid = temp and 0 or Object.newGuid()
	local o = {
		--property
		type = 'unit',		--
		guid = guid,		--
		isFight = isFight and true or false, --是否战斗单位
		visibleTo = 0,		--指定玩家可见 0:所有人;非0为pid
		--allZoneVisible = false,	--全图同步
		zoneGuid = 0,		--所属地图
		--同步属性
		sync_groups  = {}, 	--{group={k=v,...},...}
		sync_defines = {},	--{key=group}
		sync_encodes = {}, 	--{group=encodedData}
		--集合
		timers = {},		--计时器
		attrpool = false,	--属性池
		attribute = {},		--属性
		sights = {},		--视野
		debug = {},			--热查BUG用
		tile = false,		--所属地图格table or false
		
		---常用funciton直接挂对象上,提高效率但不方便热更 衍生类处理
		-- update			= Unit.update,
		-- setPos 			= Unit.setPos,
		-- getRoundRoles	= Unit.getRoundRoles,
		reftrace = '',		--debug上次引用traceback
	}
	setmetatable(o, _meta)
	o:def('guid','never',guid)
	o:def('name','never','')
	o:def('type','never','unit')
	o:def('camp','rare',0)					--阵营
	o:def('pos','often',{x=0,y=0,z=0,r=0})	--当前位置
	o:def('sizeR','never',5)				--贴身半径
	o:def('visible','rare',true)			--可见
	o:def('active','rare',true)				--激活
	o:def('born','rare',true)				--新生

	--有位移/战斗功能的单位
	if isFight then
		o:def('toPos', 'often')				--目标位置
		Attr.init(o)
		o:def('hp', 'often', o:getv('maxHp'))
		o:def('mp', 'often', o:getv('maxMp'))
		o:def('speed', 'rare', 0)
		o:def('buffs', 'often', {})			--buff表
		o:def('masterguid', 'rare', 0) 		--主人guid
		--o:def('slaves', 'rare', {})			--宠物guid
		
		-- o.siege = {}	--布围
		-- o.stateMachine = StateMachine.new( o )
		-- o.stateMachine:changeState( State_idle.new( o ) )--初始为idle状态
		-- o.combatState = COMBATSTATE.IMCOMBAT

	end
	return o
end
_meta.__call = Unit.new
function Unit.all() return units end
function Unit.count(utype)
	if utype then
		return counts[utype] or 0
	end
	return unitNum
end
function Unit.get(guid) return units[guid] end
function Unit.ref(unit)
	local guid = unit.guid
	if units[guid] then
		error('repeat refer,last refer='..unit.reftrace)
	end
	unit.reftrace = debug.traceback()
	unitNum = unitNum + 1
	units[guid] = unit
	local utype = unit.type
	counts[utype] = (counts[utype] or 0) + 1
	Object.ref(unit)
end
function Unit.unref(guid)
	local o = units[guid]
	if not o then
		error('unrefered:'..guid)
	end
	unitNum = unitNum - 1
	if o then o:clearTimer( ) end
	units[guid] = nil
	local utype = o.type
	counts[utype] = (counts[utype] or 0) - 1
	Object.unref(guid)
end

----------------------------------------------------------------
--syncor 同步属性管理
function Unit:def(key,group,initVal)
	local defines = self.sync_defines
	if defines[key] then
		error('duplicate def:'..key)
	end
	defines[key] = group
	local groups = self.sync_groups[group]
	if not groups then
		groups = {}
		self.sync_groups[group] = groups
	end
	if initVal~=nil then
		local encodes = self.sync_encodes
		groups[key] = initVal
		encodes[group] = nil
	end
end
function Unit:undef(key)
	local defines = self.sync_defines
	local group = defines[key]
	assert(group, key)
	defines[key] = nil
	self.sync_encodes[group] = nil
end
function Unit:isdef(key)
	return self.sync_defines[key] and true or false
end
function Unit:setv(key, val)
	local group = self.sync_defines[key]
	if not group then
		error('undef:'..key)
	end
	local encodes = self.sync_encodes
	local groups = self.sync_groups[group]
	if groups[key] == val then
		if type(val)=='table' then --dirty
			encodes[group] = nil
		end
		return
	end
	groups[key] = val
	encodes[group] = nil
end
function Unit:getv(key)
	local group = self.sync_defines[key]
	if not group then
		--error('undef:'..key)
		return
	end
	return self.sync_groups[group][key]
end
function Unit:dirty(key)
	local group = self.sync_defines[key]
	if not group then
		error('undef:'..key)
	end
	self.sync_encodes[group] = nil
end
function Unit:getData()	--打包编码给前端
	local encodes = self.sync_encodes
	for k, v in pairs(self.sync_groups) do
		if not encodes[k] then
			encodes[k] = _encode(v)
		end
	end
	return encodes
end

----------------------------------------------------------------
--update 更新类
local tmpVec2_1 = _Vector2.new()
local tmpVec2_2 = _Vector2.new()
local tmpVec3_1 = _Vector3.new()
local function updatePos(self, e) 
	--TODO 频繁调用的,最后优化一波尽量都调upvalue,并保证可热更
	--TODO 3D化
	local ugetv = Unit.getv
	local tpos = ugetv(self,'toPos')
	if not tpos then return end
	if self.noMove then self:stop() return end
	local old,dir,new = tmpVec2_1,tmpVec2_2,tmpVec3_1
	local pos = ugetv(self,'pos')
	old.x = pos.x
	old.y = pos.z
	dir.x = tpos.x - old.x
	dir.y = tpos.z - old.y
	if dir.x==0 and dir.y==0 then --ignore NAN
		self:stop()
		return
	end
	local dis = dir:magnitude()
	local speed = self:getSpeed()
	local move = speed*e/1000
	local r = acos(dir.x/sqrt(dir.x^2+dir.y^2))
	if r ~= r then return end -- rotation is NAN
	if self.type=='role' then
		--onRoleMove{role=self}
		--print(dis)
	end
	if dis<move or dis<ARRIVE_DIS then
		new.x = tpos.x
		new.z = tpos.z
		self:setPos(new.x, new.y, new.z, r)
		self:stop()
	else
		dir:normalized()
		_Vector2.mul(dir, move, dir)
		_Vector2.add(old, dir, dir)
		new.x = dir.x
		new.z = dir.y
		self:setPos(new.x, new.y, new.z, r)
	end
	--self.siege = { } --清包围
end
Unit.updatePos = updatePos
function Unit:update(e, now)
	updatePos(self, e)
	--self.stateMachine.currentState:update( e )
	-- local diftime = now - self.secondtime
	-- if( diftime >= 1000 ) then
		-- self:onSecond( diftime, now )
		-- self.secondtime = now
	-- end
	-- diftime = now - self.mintime
	-- if( diftime >= 60000 ) then
		-- self:onMinute( diftime, now )
		-- self.mintime = now
	-- end

	-- if _G._DEBUGPOS then
		-- CallRound( self ).ServerPos{ GUID = self.guid, X=self:getv'pos'.x, Y=self:getv'pos'.y }
	-- end
end
function Unit:onSecond( e, now )

end
function Unit:onMinute( e, now )

end
Unit.addTimer = Object.addTimer
Unit.delTimer = Object.delTimer
Unit.clearTimer = Object.clearTimer
Unit.delTimerGroup = Object.delTimerGroup

----------------------------------------------------------------
--get/set 属性类
function Unit:setZone(zone)
	local oldz = Zone.get(self.zoneGuid)
	if zone then
		Unit.ref(self)
		self.zoneGuid = zone.guid
		self.debug.zoneClearTrace = nil
		self:onEnterZone(zone)
	else
		Unit.unref(self.guid)
		self.zoneGuid = 0
		self.debug.zoneClearTrace = debug.traceback()
		self:onExitZone(oldz)
	end
end
function Unit:getZone()
	return Zone.get(self.zoneGuid)
end
function Unit:onEnterZone(zone)	end
function Unit:onExitZone(zone) end
function Unit:getSpeed()
	local truespeed = 2
	-- if self.type == 'pet' then
		-- local master = Entity.byGUID( self:getv'masterguid' )
		-- local isleader, guid = GSuperRide.isLeader( master )
		-- if not isleader then
			-- if not guid then
				-- truespeed = master and AttrSys.get( master, 'speed' ) or 0
			-- else
				-- local e = Entity.byGUID( guid )
				-- truespeed = AttrSys.get( e, 'speed' )
			-- end
		-- else
			-- truespeed = master and AttrSys.get( master, 'speed' ) or 0
		-- end
	-- else
		-- if self.type == 'role' then
			-- local isleader, guid = GSuperRide.isLeader( self )
			-- if not isleader then
				-- if not guid then
					-- truespeed = AttrSys.get( self, 'speed' )
				-- else
					-- local e = Entity.byGUID( guid )
					-- truespeed = AttrSys.get( e, 'speed' )
				-- end
			-- else
				-- truespeed = AttrSys.get( self, 'speed' )
			-- end
		-- else
			-- truespeed = AttrSys.get( self, 'speed' )
		-- end
	-- end
	return truespeed
end
function Unit:syncAttribute()
	local t = {}
	for k, v in pairs( cfg_attr ) do
		t[k] = AttrSys.get( self, k )
	end
	self:sendProps(t)
	if self.type == 'role' then
		--local newforcce = AttrSys.getForce( self )
		CallCSByRole( self ).UpdateForce{Token = self.getToken(), T = {attr = t, force = self:getTotalForce(), label = 'level'}}
	end
end
function Unit:sendProps(props)	--同步变化属性
	CallRound(self).Prop{Guid = self.guid, T = props}
end
function Unit:setProp(k,v)	--更改并同步变化属性
	self:setv(k, v)
	CallRound(self).Prop{Guid = self.guid, T = {[k] = v==nil and '_nil' or v} }
end
function Unit:setProps(props)	--更改并同步变化属性
	for k,v in pairs(props) do
		self:sp( k, v )
	end
	CallRound( self ).Prop{Guid = self.guid, T = props }
end
function Unit:setVisible(v)
	self:sp( 'visible', v )
	self:sendProps( {visible=v} )
end
function Unit:setDisabled(v)
	self:setv('disabled', v)
	self:sendProps{disabled=v}
end

----------------------------------------------------------------
--zone/tile/sight 场景视野
function Unit:getRoundUnits(nome)	--附近单位,不含私显,含全图显
	local uget = Unit.get
	local pid = self.pid
	local o
	local t = {}
	for tile,_ in pairs(self.tile:allSight()) do
		for guid,type in pairs(tile.units) do
			o = uget(guid)
			if o.visibleTo==0 or o.visibleTo==pid then
				t[guid] = o
			end
		end
	end
	if nome then t[self.guid] = nil end
	return t
end

----------------------------------------------------------------
--position 位移类

function Unit:setPos(x, y, z, r )
	local pos = self:getv'pos'
	if x then pos.x = x end
	if y then pos.y = y end
	if z then pos.z = z end
	if r then pos.r = r end
	self:dirty'pos'
	local zone = self:getZone()
	if zone then
		zone:procAOI(self,pos)
	end
end

function Unit:runTo(toPos, _haveme)
	-- if self.noMove then return end
	-- if self.movetype == 'NO' then return end
	-- if self.skillStage and self.skillStage.flag == 'lead' and not self.skillStage.skill.ismoveuse then
		-- return
	-- end
	local to = self:getv'toPos'
	if to then
		to.x = toPos.x
		to.z = toPos.z
	else
		to = {x=toPos.x, z=toPos.z}
	end
	self:setv('toPos', to)
	local cp = self:getv'pos'
	CallRound(self, not _haveme).Run{Guid=self.guid, 
		X=to.x, Z=to.z, FX=cp.x, FZ=cp.z, Speed=self:getSpeed()}
end

function Unit:stop(pos, lab)
	self:setv('toPos', nil)
	if pos then
		self:setPos(pos.x, pos.y, pos.z, pos.r)
	end
	--self.siege = {} --清包围
	--self._laststoptrace = tostring(lab) .. debug.traceback()
	-- if self.pathParam then
		-- local cfg = cfg_path[self.aipath]
		-- if cfg.once and self.pathParam.n >= #cfg then
			-- local zone = self:getZone()
			-- if zone.gbase then
				-- zone.gbase:onMonArrive( self, self.aipath )
			-- end
			-- onMonPathArrive{ mon = self, pathid = self.aipath }
			-- self.aipath = nil
			-- self.pathParam = nil
		-- end
	-- end
	local cp = self:getv'pos'
	CallRound(self, true).Stop{Guid=self.guid, X=cp.x, Z=cp.z}
end
--同线传送
function Unit:transTo(zid, x, y, z, r)
	local oldzone = self:getZone()
	assert(oldzone,'EntityBase:transTo no oldzone')
	local isRole = self.type=='role'
	if isRole then
		--双骑/飞行/打坐等处理
	end
	if oldzone.id == zid then	--同图闪跳 TOTEST
		self:setPos(x, y, z, r)
		self:stop()
		local slaves = self:getv'slaves'
		if slaves then --随从/宠物等跟闪
			for guid, _ in pairs(slaves) do
				local slave = Unit.get(guid)
				if slave then
					slave:setPos(x-8, y, z, r)
					self:stop()
					CallRound(self).JumpTo{Guid=slave.guid, X=x-8, Y=y, Z=z, R=r}
				end
			end
		end
		CallRound(self).JumpTo{Guid=self.guid, X=x, Y=y, Z=z, R=r}
	else
		local slaves = self:getv'slaves'
		if slaves then --随从/宠物删除,新图决定创建
			for guid, _ in pairs(slaves) do
				local slave = Unit.get(guid)
				if slave then
					--self:stop()
					oldzone:delUnit(slave,'masterTrans')
					slave:setZone(nil)
				end
			end
		end
		--复活.先复活后传
		-- if isRole and self:isDead() then
			-- if self.revivetimer then
				-- self:delTimer( self.revivetimer )
				-- self.revivetimer = nil
			-- end
			-- self:setv('hp', AttrSys.get(self, 'maxHp'))
			-- CallRound(self).Revive{GUID = self.guid, Hp = self:gp'hp'}
		-- end

		self:stop()
		oldzone:delUnit(self,'transTo')

		self:setPos(x, y, z, r)
		local zone = Zone.byID(zid, self.pid)
		zone:addUnit(self)
		
		if isRole then
			local roleInfo = {guid=self.guid}
			-- for k,v in pairs(私人属性) do
			-- 	roleInfo[k] = 
			-- end
			local units = {[self.guid]=self:getData()} --除自己外因场景载完再加
			local zdata = zone:getData(self)
			local data = {
				Id = zone.id,
				Time = os.time(),
				Role = roleInfo,
				Units = units,
				Zone = zdata,
			}
			self:setProtect(true)
			CallRole(self).EnterZone(data)
		end
	end
end
--同图闪跳
function Unit:jumpTo(pos)
	local z = self:getZone()
	self:transTo(z.id, pos.x, pos.y, pos.z, pos.r)
end

function Unit:transToIns(ckey)	--TODO
	local zone = GsGameMgr.getZone( ckey )
	assert(zone,'cant find zone:'..ckey)
	local pos = zone:getBornPos( self )
	local x, y, z, r = pos.x, pos.y, pos.z, pos.r
	local datas = zone:getData( self )
	local oldzone = self:getZone()
	local oldid = oldzone.id
	if oldid == zone.id then
		self:setPos( x, y, z, r )
		self:stop()
		CallEntity( self ).JumpTo{Guid=self.guid, X = x, Y = y, R = r }
	else
		oldzone:delUnit( self, 'transToIns' )
		self:setZone( zone )
		self:setPos( x, y, z, r )
		self:stop()
		zone:addUnit(self)
		local units = { }
		for k, v in next, self:getRoundEntities( true ) do units[v.guid] = v:getData( ) end
		for guid, e in pairs( oldzone:getWEntities( ) ) do
			if not units[guid] then units[guid]  = e:getData( ) end
		end
		CallEntity(self).TransTo{ TarZone = zone.id , X = x, Y = y, Info = { }, Entities = units, Data = datas  }
	end
end

----------------------------------------------------------------TODO
--fight 战斗类
function Unit:isDead()
	return self:getv'hp' == 0
end
function Unit:enterCombat()
	if self.type == 'role' then
		self.combatTime = os.now()
	end
end
function Unit:quitCombat()
	if self.type == 'role' then
		self.combatTime = nil
	end
end
function Unit:onGetHit(srcEntity, skill)
	local type = self.type
	if( type == 'monster' and skill ) then
		--[[
		if( srcEntity.type == 'role' and skill.monpausetime ) then
			self:pause( skill.monpausetime )
		else
			if( not cfg_mon[ self:getv'id' ].isNotMove ) then
				self:stop()
			end
		end
		--]]
		if( not cfg_mon[ self:getv'id' ].isNotGetHitStop ) then
			self:stop()
		end
	elseif( type == 'role' ) then
		if( self:getv'muse'.state == 1 ) then
			self:endMuse()
		end
	end
	onGetHit{entity=self, srctarget=srcEntity, skillcat=skill and skill.category, _delay = (skill and skill.effectDelay) and skill.effectDelay*0.001 or 0}
end
function Unit:onAttack(tarEntity, skill)
	onAttack{ entity=self, target=tarEntity, skillcat = skill and skill.category, _delay = (skill and skill.effectDelay) and skill.effectDelay*0.001 or 0 }
end
function Unit:changeCombatState(state)
	if self.combatState == state then return end
	self.combatState = state
	if( state == COMBATSTATE.COMBAT ) then
		self:enterCombat()
		CallRound( self ).EnterCombat{ GUID = self.guid }
	elseif( state == COMBATSTATE.IMCOMBAT ) then
		self:quitCombat()
		CallRound( self ).QuitCombat{ GUID = self.guid }
	end
end
function Unit:breakLead()
	if( self.skillStage and self.skillStage.flag == 'lead' ) then
		for _, timeid in ipairs( self.skillStage.leadTimer ) do
			self:delTimer( timeid )
		end

		CallRound( self ).CancelLead{ GUID = self.guid, Flag = 'nofinish' }
		self.stateMachine:changeState( State_idle.new( self ) )
		self.skillStage = nil
	end
end
function Unit:castTo(target, skillID, point)
	CallRound( self, true ).CastTo{ FGUID = self.guid, TGUID = target, SkillID = skillID, Point = point }
	self.stateMachine:changeState( State_cast.new( self.entity, skillID ) )
end
--修改hp( val表示修改的值，flag表示标志hash表有：{cir = true爆击, damageret = true反弹}， src:'skill', 'normal', 'famousweapon','damageret' )
--noRpc 如果为true表示此次修改的hp消息不需要通过这里的RPC广播( 由战斗相关的RPC发送 )
--返回参数1 bool值， true表示止次行为导致死亡行为
--返回参数2 number, 表示此次修改的真实hp值
--返回参数3 bool值，true表示止次扣血行为失败
function Unit:modifyHp( srcGUID, value, flag, src, noRpc )
	local type = self.type
	local guid = self.guid
	local trueValue = 0
	if self.noHit then--无敌
		return false, trueValue, true
	elseif( self:isDead() ) then
		return false, trueValue, true
	elseif self.combat == 'back' and not self.nohurtinback then --怪脱战营
		return false, trueValue, true
	end
	local value = math.floor( value )
	local oldHp = self:getv'hp'
	local maxHp = AttrSys.get( self, 'maxHp' )
	--_xmz( '----------modifyHp---', oldHp, maxHp, value, debug.traceback() )
	if self.type == 'monster' then
		if value < 0 then
			if self.gethurtabs then
				value = - self.gethurtabs
			end
		end
	end
	if( oldHp + value > maxHp ) then
		trueValue = maxHp - oldHp
	elseif( oldHp + value < 0 ) then
		trueValue = (-oldHp)
	else
		trueValue = value
	end

	if( self.giftAutoRevive and (oldHp+trueValue) == 0 and not Cd(self, 'cdgiftautorevive', self.giftAutoRevive[1]) ) then
		local revivehp = math.floor( AttrSys.get(self, 'maxHp')*self.giftAutoRevive[2]*0.01 )
		trueValue = revivehp - oldHp
	end

	self:sp( 'hp', oldHp+trueValue )

	--同步客户端
	if( not noRpc ) then
		CallRound( self ).ModifyHp{ GUID = guid, SrcGUID = srcGUID, Flag = flag, Value = value, Src = src, TrueValue = trueValue, IsSyn = true }
	end
	if self:getZone( ) then
		onModifyHp{ entity = self, etype = type, val = trueValue, hp = self:getv'hp', srcGUID=srcGUID }
	end
	--死亡
	if self:getv'hp' == 0 then
		self:deathPro( srcGUID, noRpc, flag )
		return true, trueValue
	else
		if( type == 'role' ) then
			self:useSuperHp()
			self:useSpeHp()
		end
	end

	SkillManage.hpGiftPro( self )

	return false, trueValue
end
function Unit:deathPro( srcGUID, noRpc, flag )
	if( self.skillStage and self.skillStage.flag == 'cast' ) then
		self:delTimer( self.skillStage.timerID )
	end

	self:stop()
	self:breakLead()

	if( not noRpc ) then
		local guid = self.guid
		CallRound( self ).Death{ GUID = guid, SRCGUID = srcGUID }
	end
	local type = self.type
	if( type == 'monster' ) then
		self:die( srcGUID )
	elseif( type == 'role' ) then
		local killer = Entity.byGUID( srcGUID )
		local killname = killer and killer:getv'name' or _T'未知'
		local cb = function()
			local killer = Entity.byGUID( srcGUID )
			local info = { killname = killname, killtime = os.now() }
			CallEntity( self ).Msg{ K='roledeath',T = info }

			local autorevive = function()
				self:revive('normal')
			end
			local tempt = 30000
			if( cfg_zone[ self:getZone().id ].norevive ) then
				tempt = cfg_zone[ self:getZone().id ].norevive*1000
			end
			if( not cfg_zone[ self:getZone().id ].noreviveui ) then
				self.revivetimer = self:addTimer( tempt, autorevive )
			end
		end
		self.revivedelaytimer = self:addTimer( 400, cb )

		if( killer ) then
			if( not cfg_zone[ self:getZone().id ].canpk and (not flag or not flag.damageret) ) then
				if( killer.type == 'role' ) then
					if( not self:isRedName() and not self:isGrayName() ) then
						killer:modifyPVPPoint( 1, 1 )
					end
					--黑名单
					CallCSByRole( self ).AddToEnemy{ Token = self.getToken(), Pid = killer.pid }
				elseif( killer.type == 'pet' ) then
					local master = Entity.byGUID( killer:getv'masterguid' )
					if( master ) then
						if( not self:isRedName() and not self:isGrayName() ) then
							master:modifyPVPPoint( 1, 1 )
						end
						--黑名单
						CallCSByRole( self ).AddToEnemy{ Token = self.getToken(), Pid = master.pid }
					end
				end
			end

			if( killer.type == 'role' and cfg_zone[ self:getZone().id ].canpvpkillinfo ) then
			--if( killer.type == 'role' ) then
				CallCSByRole( self ).PvpKillInfo{ Token = self.getToken(), Info={ type = 1,zoneid = self:getZone().id,name = killer:getv'name',tarpid = killer.pid } }

				CallCSByRole( killer ).PvpKillInfo{ Token = killer.getToken(), Info={ type = 2,zoneid = self:getZone().id,name = self:getv'name',tarpid = self.pid } }
			end
		end
		onDie{entity=self,killer=killer}
	end

	BuffSys.closeDeathBuffGroup( self )
end

----------------------------------------------------------------TODO
--event
function event.loadConfig()
	
end
function event.afterConfig()

end

-- when{_order=0}
-- function onDie(entity, killer, _args) --玩家隶属单位击杀转为主人击杀
	-- local guid = killer:isdef('masterguid') and killer:getv'masterguid'
	-- if guid then
		-- local master = Unit.get(guid)
		-- if master.type=='role' then
			-- _args.killer = master
		-- end
	-- end
-- end
