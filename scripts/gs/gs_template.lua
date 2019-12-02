do return end
_G.Mine = {}
--程控常量
Mine.CASTTIMEOUT = 5000	--采集超时
Mine.DISTANCE = 200			--最大采集距离
Mine._meta = {__index=Mine}
--static公共方法
function Mine.new(id)
	local cfg = cfg_mine[id]
	assert(cfg, id..' invalid mine id')
	local e = EntityBase.new()
	-- properties
	e:addProp( 'id', 'rare', 'basedata' )
	e:addProp( 'minestate', 'rare', 'basedata' )
	e:addProp( 'belong', 'rare', 'basedata' )
	e:addProp( 'campid', 'rare', 'basedata' )

	e:sp( 'type', 'mine' )
	e:sp( 'id', id )
	e:sp( 'name', cfg.name )
	e:sp( 'minestate', 'idle' )
	e:sp( 'campid', 0 )

	--private
	e.borntime 		= _now()
	e.gathers		= {}			--采集者[guid]=pretime
	e.lifetime		= cfg.lifetime
	e.times			= cfg.times > 0 and cfg.times or 1
	e.lastrevive	= _now()

	e.update		= Mine.update
	return setmetatable( e, Mine._meta )
end
function Mine.get(guid)
	local e = Entity.byGUID( guid )
	if not e then return end
	if e:gp'type'~='mine' then return end
	return e
end
--object对象方法
function Mine:update(e)
	if self.dietime then return end
	local now = _now()
	local cfg = cfg_mine[self:gp'id']
	if self.lifetime and self.lifetime>0 and now - self.borntime > self.lifetime then	--时限自消
		self:die()
		return
	end
	if cfg.revive>0 and now - self.lastrevive > cfg.revive then	--回满可采集次数
		self.times = cfg.times > 0 and cfg.times or 1
		self.lastrevive = now
	end
	for pid, pretime in pairs(self.gathers) do
		local role = GsRole.byPID(pid)
		if role then
			if role:isDead() then
				self.gathers[pid] = nil
				CallEntity( role ).Msg{K='gatherfaildeath'}
			elseif (now - pretime > cfg.casttime + Mine.CASTTIMEOUT) then	--超时采集者
				self.gathers[pid] = nil
				CallEntity( role ).Msg{K='gatherfailtimeout'}
			end
		else
			self.gathers[pid] = nil
		end
	end
end
function Mine:canGather( role )
	local can = not self:gp'disabled'
	if not can then
		self.gathers[role.pid] = nil
		return false
	end
	local b = self:gp'belong'
	can = not b or b == role.pid
	if not can then
		self.gathers[role.pid] = nil
	end
	if self.xgname then
		can = self.xgname ~= role:gp'guildname'
	end
	local id = self:gp'id'
	local cfg = cfg_mine[id]
	if cfg.zonecd then
		local cd = self:getZone().zonecd[role.pid]
		if cd and cd[id] then
			if _now() - cd[id] < cfg.zonecd then
				can = false
			end
		end
	end
	local zone = role:getZone( )
	if zone.id == 7000103 or zone.id == 7000102 or zone.id == 7000101 then
		if self:gp'id' == 30601 then
			zone.gbase.roleboxtimes[role:gp'pid'] = zone.gbase.roleboxtimes[role:gp'pid'] or 0
			if zone.gbase.roleboxtimes[role:gp'pid'] >= zone.gbase.maxboxtimes then
				CallEntity( role ).Warn{ Msg = _T"次数已用完" }
				can = false
			end
			if role.weddinglimit['wedbox'..zone.gbase.gamedata.level] >= WeddingCFG.DAYLIMITES.wed.box[zone.gbase.gamedata.level] then
				CallEntity( role ).Warn{ Msg = _T"达到每日上限" }
				can = false
			end
		end
		if self:gp'id' == 30605 or self:gp'id' == 30607 then
			zone.gbase.roleminetimes[role:gp'pid'] = zone.gbase.roleminetimes[role:gp'pid'] or 0
			if zone.gbase.roleminetimes[role:gp'pid'] >= zone.gbase.maxmineimes then
				CallEntity( role ).Warn{ Msg = _T"次数已用完" }
				can = false
			end
			if role.weddinglimit['wedmine'..zone.gbase.gamedata.level] >= WeddingCFG.DAYLIMITES.wed.red[zone.gbase.gamedata.level] then
				CallEntity( role ).Warn{ Msg = _T"达到每日上限" }
				can = false
			end
		end
	end
	if zone.id == 6000002 then
		if table.count( WeddingCache ) ~= 0 then
			if self:gp'id' == WeddingCFG.MINEID1 then
				WeddingRedCache[role:gp'pid'] = WeddingRedCache[role:gp'pid'] or 0
				if WeddingRedCache[role:gp'pid'] >= WeddingCFG.LIMITTIMES[WeddingCache.level] then
					CallEntity( role ).Warn{ Msg = _T"次数已用完" }
					can = false
				end
				if role.weddinglimit['mapred'..WeddingCache.level] >= WeddingCFG.DAYLIMITES.map.red[WeddingCache.level] then
					CallEntity( role ).Warn{ Msg = _T"达到每日上限" }
					can = false
				end
			end
			if self:gp'id' == WeddingCFG.MINEID2 then
				WeddingBoxCache[role:gp'pid'] = WeddingBoxCache[role:gp'pid'] or 0
				if WeddingBoxCache[role:gp'pid'] >= WeddingCFG.LIMITTIMES[WeddingCache.level] then
					CallEntity( role ).Warn{ Msg = _T"次数已用完" }
					can = false
				end
				if role.weddinglimit['mapbox'..WeddingCache.level] >= WeddingCFG.DAYLIMITES.map.box[WeddingCache.level] then
					CallEntity( role ).Warn{ Msg = _T"达到每日上限" }
					can = false
				end
			end
		end
	end

	if zone.id == 6920011 then
		if role:gp'lol' == 'redteam' and self:gp'id' == 30810 then 
			CallEntity( role ).Warn{ Msg = _T"不能采集本阵营初始旗子" }
			can = false
		end

		if role:gp'lol' == 'blueteam' and self:gp'id' == 30800 then 
			CallEntity( role ).Warn{ Msg = _T"不能采集本阵营初始旗子" }
			can = false
		end
	end

	if zone.id == ThanksgivingCFG.ZONEID then
		if table.count( zone.gbase.ThanksgivingCache ) ~= 0 then
			if self:gp'id' == ThanksgivingCFG.MINEID then
				zone.gbase.ThanksgivingCache[role:gp'pid'].getcount = zone.gbase.ThanksgivingCache[role:gp'pid'].getcount or 0
				if zone.gbase.ThanksgivingCache[role:gp'pid'].getcount >= ThanksgivingCFG.LIMITTIME then
				    CallEntity( role ).Warn{ Msg = _T"您已经吃了太多大餐了，等待下一场大餐吧" }
					can = false
				end
			end
		end
	end

	if zone.id == 7013001 then   --舞狮绣球的
		if role.have_newyear_ball then
			CallEntity( role ).NoticeArt{ Msg = mstr{_T"请先将绣球运送到自己阵营区域"} }
			can =  false
		end
	end
	if zone.id == 6000002 and self:gp'id' == 30750 then can = false end --主城的不能采集

	return can
end
function Mine:preGatherBy( role )--开采
	if self:gp'minestate' ~= 'idle' then return end
	if not self:canGather( role ) then return end
	local pid = role.pid
	if not isInCircle( self:gp'currPos', role:gp'currPos', Mine.DISTANCE, true ) then
		_zdm('minpos:',self:gp'currPos'.x, self:gp'currPos'.y)
		_zdm('rolepos:',self:gp'currPos'.x, role:gp'currPos'.y)
		CallEntity( role ).Msg{K='minetoofar'}
		return
	end
	local cfg = cfg_mine[self:gp'id']
	if not cfg.mulgahter then	--不可多人同采
		self.gathers[pid] = nil
		if table.count(self.gathers)>0 then --目标正在被他人采集
			CallEntity( role ).Msg{K='targetminenomulgahter'}
			return
		end
	end
	if cfg.casttime <=0 then self:gatherBy( role ) return end
	if CanonMgr.check( self:gp'id' ) then
		if CanonMgr.isCanon( role ) then return end
	end
	self.gathers[pid] = _now()
	CallRound( role ).GatherCast{Guid=role:gp'guid', TGuid=self:gp'guid'}
end
function Mine:gatherBy( role )--结采
	if self:gp'minestate' ~= 'idle' then return end
	if not self:canGather( role ) then return end
	local pid = role.pid
	local mineid = self:gp'id'
	local cfg = cfg_mine[mineid]
	if cfg.casttime > 0 then
		local last = self.gathers[pid]
		if not last then return end
		local now = _now()
		if now - last < cfg.casttime then return end
		self.gathers[pid] = nil
	end

	local id = self:gp'id'
	local cfg = cfg_mine[id]
	if cfg.zonecd then
		local cd = self:getZone().zonecd
		if not cd[pid] then
			cd[pid] = {}
		end
		cd[pid][id] = _now()
	end

	CallRound( role ).GatherOK{Guid=role:gp'guid', TGuid=self:gp'guid'}
	if cfg.dropid then
		DropItem.dropGroup(self:getZone(), cfg.dropid, self:gp'currPos', sharer, pid, {'mine', self:gp'id'}, 2000 )
	end
	if cfg.monster then
		self:getZone():createMonster( cfg.monster, self:gp'currPos' )
	end
	if CanonMgr.check( mineid ) then
		CanonMgr.gather( role, mineid )
	end
	self.times = self.times - 1
	if self.times == 0 then
		self:die()
	end
	if self._trek_pid and self._trek_borntime then
		if ( _now( ) - self._trek_borntime ) <= 30000 then
			local xrole = GsRole.byPID( self._trek_pid )
			if xrole then
				CallEntity( xrole ).TrekSuccess{ }
			end
		end
	end
	return true
end
function Mine:die( ) --待重生
	if self.dietime then return end
	self.dietime = _now()
	local mineid = self:gp'id'
	local cfg = cfg_mine[mineid]
	self:sp( 'minestate', 'opened' )
	self:sendProps( {minestate='opened'} )
	local z = self:getZone()
	if cfg.diekeep > 0 then
		z:addTimer(cfg.diekeep, function()
			self:delete()
		end, 'deletemine')
	else
		--self:delete()	--机关类不删
		return
	end
	--重刷
	local bornPos = self.bornPos or self:gp'currPos'
	if self.noReborn then return end --本尊不想重生
	if z.noReborn then return end --本图不让重生
	z:addTimer(cfg.revive, function()
		z:createMine( mineid, bornPos )
	end, 'createmine')
end
function Mine:delete() --删除不重生
	local z = self:getZone()
	if not z then return end
	z:delEntity( self )
	Entity.delGUID( self:gp'guid' )
end

-----------------------------------------------------
--evevnt事件------------------------------------------
when{} function loadConfigGS()
	dofile'config/cfg_mine.lua'

end
when{} function checkConfigGS() --检查采集产物
	for id,v in pairs(cfg_mine) do
		assert(math.abs(id)<=UINT, 'cfg_mine id is too big:'..id..'>'.. UINT)
		if v.dropid then
			assert(cfg_drop[v.dropid], v.dropid..' invalid dropid in cfg_mine')
		end
		if v.taskmine then
			assert(not v.zonecd, id..' taskmine can not use zonecd ')
		end
	end
end
when{} function getZoneData( zone, info, role ) --场景私用专属数据
	info.zonecd = zone.zonecd[role.pid]
end
when{} function onGatherMine(role, pid, mine, mineid)
	CallCSByRole( role ).RoleGatherMine{Token=role.getToken(), MineId=mineid}
end
--RPC--远程调用=============================
cdefine.c.PreGather{Guid=0,Id=0}
cdefine.c.Gather{Guid=0,Id=0,TaskMine=false}
cdefine.c.GatherBreak{TGuid=0}
when{} function PreGather(Guid, Id)
	local r = GsRole.byNet( _from )
	if not r then return end
	local m = Mine.get(Guid)
	if not m then return end
	m:preGatherBy(r)
end
when{} function Gather(Guid, Id, TaskMine)
	local r = GsRole.byNet( _from )
	if not r then return end
	_zdm('Gather', Guid, Id, TaskMine)
	if TaskMine then --任务采集物直接给CS发成功
		CallCSByRole( r ).RoleGatherMine{Token=r.getToken(), MineId=Id}
		local m = Mine.get(Guid)
		if not m then return end
		m:gatherBy(r, TaskMine)
	else
		local m = Mine.get(Guid)
		if not m then return end
		local pid = r.pid
		local success = m:gatherBy(r)
		if success then
			onGatherMine{role=r, pid=pid, mine=m, mineid=m:gp'id'}
		else
			CallRound( r ).GatherFail{Guid=r:gp'guid', TGuid=Guid}
		end
	end
end
when{} function GatherBreak(TGuid)
	local r = GsRole.byNet( _from )
	if not r then return end
	local m = Mine.get(TGuid)
	if not m then return end
	local pid = r.pid
	m.gathers[pid] = nil
	CallRound( r, true ).GatherBreak{Guid=r:gp'guid', TGuid=TGuid}
end