--Monster
----------------------------------------------------------------
--tolocal
local max = math.max
local min = math.min
local random = math.random
local Unit = Unit
local Monster = Monster
local Zone = Zone
local _meta = Object.newMeta(Monster)
----------------------------------------------------------------
--config
local AI_FREQ_MIN = 500
local AI_FREQ_MAX = 2000

----------------------------------------------------------------
local _new
function event.loadConfig()
	local o = Unit.new(true,true)
	setmetatable(o, nil)
	o.type 			= 'monster'
	o.id 			= 0 --配置id
	o.editKey 		= 0	--编辑器值
	o.t_lastai		= 0	--上次AI更新时间
	o.update		= false
	o.updateAI 		= false
	o.setPos 		= false
	o.getRoundRoles	= false
	o.bornPos		= {x=0,y=0,z=0}
	o.bornTime		= 0
	_new = table.template(o)
end
function Monster.new(id)
	local cfg = cfg_mon[id]
	local o = _new(true)
	local guid = Object.newGuid()
	o.guid 			= guid
	o.id 			= id
	o.bornTime 		= _now()
	--set often use functions directly
	o.update 		= Monster.update
	o.updateAI 		= Monster.updateAI
	o.setPos 		= Unit.setPos
	o.getRoundRoles	= Unit.getRoundRoles
	--setv
	setmetatable(o, _meta)
	o:def('id', 'never', id)
	o:setv('type', 'monster')
	o:setv('guid', guid)
	o:setv('speed', 2)
	o:setv('name', cfg.name)
	
	Attr.add(o, cfg, true, 'new') --TEST
	Attr.reset(o, 'rolenew', true) --属性池计算
	o:setv('hp', o:getv'maxHp' )

	return o
end
_meta.__call = Monster.new
Monster.addToTile	= Unit.addToTile
Monster.delFromTile	= Unit.delFromTile

function Monster:updateAI()
	--print('updateAI-', self.guid)
	--TOTEST
	if not self:getv'toPos' then
		local x,z = self.bornPos.x + random(-7,7),self.bornPos.z + random(-7,7)
		
		local tileMgr = self:getZone().tileMgr
		if x < 0 then x = 0
		elseif x > tileMgr.tilex then
			x = tileMgr.tilex
		end
		if z < 0 then z = 0
		elseif z > tileMgr.tilez then
			z = tileMgr.tilez
		end
		
		self:runTo({x=math.max(0.1,x),z=math.max(0.1,z)})
	end
	-- if _now()-self.bornTime>5000 then
		-- self:die()
	-- end
end

local Unit_update = Unit.update
function Monster:update(e, now)
	local zone = self:getZone()
	if not zone then return end
	Unit_update(self, e, now)
	-- if self.movetype == 'NO' and self:getv'toPos' then
		-- self:stop(nil, 'movetype=NO')
	-- end
	-- if not zone.getPathFinder( self ) then
		-- Log.sys('PathFinder no ready', zone.id)
	-- end
	local unitnum = Unit.count()
	local ai_freq = unitnum/1000*500 --每加一千单位加半秒
	ai_freq = min(max(ai_freq, AI_FREQ_MIN), AI_FREQ_MAX)
	if now - self.t_lastai > ai_freq then
		self.t_lastai = now
		self:updateAI( e )
		-- if self.combat ~= 'death' then
			-- onMonUpdate{mon=self,e=e}
		-- end
	end
end

function Monster:die()
	local zone = self:getZone()
	self:setZone(nil)
	self:delFromTile()
	if self.noReborn then return end
	if zone.noReborn then return end
	local id = self.id
	local pos = self.bornPos
	zone:addTimer(2000, function()
		zone:createMonster(id, pos, preSet)
	end)
end


----------------------------------------------------------------
--event
function event.loadConfig()
	dofile"config/cfg_mon.lua"
end
function event.afterConfig()

end
