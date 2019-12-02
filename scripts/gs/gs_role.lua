--Role
-- 太上台星　应变无停
-- 驱邪缚魅　保命护身
-- 智慧明净　心神安宁
-- 三魂永久　魄无丧倾
local Role = Role
----------------------------------------------------------------
--to local
local Unit = Unit
local Zone = Zone
local Net = Net
local _meta = Object.newMeta(Role)

local _csnets = table.weakkv(0,3000)
local _cnets = table.weakkv(0,3000)
local _new
----------------------------------------------------------------
--event
function event.loadConfig()
	local o = Unit.new(true,true)
	o:def('pid', 'never', 0)
	setmetatable(o, nil)
	o.type 			= 'role'
	o.pid 			= 0		--角色库id
	o.token 		= ''	--CS令牌
	
	--avatar部件
	-- o.ava_hair		= 0	--发
	-- o.ava_face		= 0	--脸
	-- o.ava_body		= 0	--体
	-- o.ava_hand		= 0	--手
	-- o.ava_belt		= 0	--腰
	-- o.ava_feet		= 0	--足
	-- o.ava_wp_l		= 0	--左武
	-- o.ava_wp_r		= 0	--右武
	-- o.ava_wp_p		= 0	--武器状态
	--预留方法空间
	o.update		= false
	o.setPos 		= false
	o.getRoundRoles	= false
	defineRole{role=o}
	_new = table.template(o)
end

----------------------------------------------------------------
--local
local net2Role = table.weakkv(0,3000)
local token2Role = table.weakkv(0,3000)
local guid2Role = table.weakkv(0,3000)
local pid2Role = table.weakkv(0,3000)
----------------------------------------------------------------
--global
function Role.byToken(token) return token2Role[token] end
function Role.byNet(net) return net2Role[net] end
function Role.byGUID(guid) return guid2Role[guid] end
function Role.byPID(pid) return pid2Role[pid] end
function Role.all() return token2Role end
function Role.new(data, token, temp) --temp:用于计算的临时对象
	local o = _new(true)
	local guid = Object.newGuid()
	o.guid 			= guid
	o.pid 			= data.player.pid
	o.token 		= token
	--set often use functions directly
	o.update		= Role.update
	o.setPos 		= Unit.setPos
	o.getRoundRoles	= Unit.getRoundRoles
	--setv
	setmetatable(o, _meta)
	o:setv('guid', guid)
	o:setv('type', 'role')
	o:setv('pid', o.pid)
	o:setv('speed', 2)
	if not temp then
		token2Role[token] = o
		guid2Role[o.guid] = o
		pid2Role[o.pid] = o
	end
	o:setv('name', data.player.name)
	
	Attr.lockReset(o, true) --锁定属性池计算
	loadUserInfo{info=data,role=o} --各系统属性注入
	Attr.add(o, {maxHp=100}, true, 'new') --TEST
	Attr.lockReset(o, nil) --解锁属性池计算
	Attr.reset(o, 'rolenew', true) --属性池计算
	
	o:setv('hp', o:getv'maxHp' )
	
	return o
end
_meta.__call = Role.new
Role.addToTile		= Unit.addToTile
Role.delFromTile	= Unit.delFromTile
----------------------------------------------------------------
--Role:
function Role:update(e, now)
	local zone = self:getZone()
	if not zone then return end
	Unit.update(self, e, now)
end

function Role:getPid()
	return self.pid
end

function Role:getToken()
	return self.token
end

function Role:setCS(net)
	_csnets[self] = net
end
function Role:getCS()
	return _csnets[self]
end

function Role:setNet(net)
	local oldnet = _cnets[self]
	if oldnet then
		net2Role[oldnet] = nil
	end
	if net then
		net2Role[net] = self
	end
	_cnets[self] = net
end
function Role:getNet()
	return _cnets[self]
end
function Role:disconnect()
	self:setNet(nil)
end

----------------------------------------------------------------

function Role:setProtect(bool)
	--角色切图载入过程的保护状态
end

function Role:getBornPos(zone)
	do return { x = 3, y = 0, z = 3, r = 0 } end
	if self.inst then
		return self.inst:getBornPos(self.id, self.guid)
	else
		-- local cfg = cfg_zone[self.id]
		-- local mkrs = cfg.markers
		-- local m = mkrs['revive_01']
		-- if m then
			-- local x, y, z, r = zone.getMarkerPos(self.id, 'revive_01')
			-- return { x = x, y = y, z = z, r = r }
		-- else
			-- Log.sys('no marker revive_01',debug.traceback())
			-- local x = cfg.pos and cfg.pos[1] or 0
			-- local y = cfg.pos and cfg.pos[2] or 0
			-- return { x = x, y = y, z = 0, r = 0 }
		-- end
	end
end

function Role:onEnterZone(zone)
	local guid = self.guid
	
	if zone.tickSave then --玩家可驻停地图,加到新图后立即上报
		local pos = o:getv'pos'
		CallRoleCS(o).TickReport{Token=o:getToken(), 
			Data={zoneid=zone.id, x=pos.x, y=pos.y, z=pos.z} }
	end
	zone.roles[guid] = true
	--zone.updateOnceAfterZoneNoRole = nil
	-- if zone.inst then
		-- zone.inst:onRoleIn(o, o.guid, o.pid, reason)
	-- end
	--onEnterZone{role=o, zone=zone, zoneid=zone.id}
end

function Role:onExitZone(zone)
	local guid = self.guid
	zone.roles[guid] = nil
	-- if zone.inst then
		-- zone.inst:onRoleOut(o, o.guid, o.pid, reason)
	-- end
	-- onExitZone{role=o, zoneid=zone.id}
	
	if zone.counts.role == 0 then
		--self.updateOnceAfterZoneNoRole = true
	end
end

----------------------------------------------------------------
--RPC
define.Run{Guid=0,X=0,Y=0,Z=0} --主角移动
when{}
function event.Run(Guid,X,Y,Z)
	--print('Run',Guid,X,Y,Z)
	local r = Role.byNet(_from)
	if not r then return end
	local u = r
	if Guid ~= 0 then --可控非主角
		u = Unit.get(Guid)
		if not u then return end
		if u:getv'hostguid'~=r.guid then return end --无权
	end
	u:runTo({x=X,z=Z})
end

define.Skip{Guid=0} --主角跳跃
when{}
function event.Skip(Guid)
	print('Skip',Guid)
end
