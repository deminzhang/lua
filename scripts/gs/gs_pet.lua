do return end
_G.Pet = {}
Pet.JUMPTOHOSTDISTANCE = 250  --跳主距离
Pet._META = {__index=Pet}
function Pet.new( id )
	local cfg = cfg_pet_ava[ id ]

	local t = EntityBase.new( istemp, 'fight' )
	-- properties
	t:addProp( 'id', 'never', 'basedata' )
	t:addProp( 'hostguid', 'never', 'basedata' )
	t:addProp( 'level', 'rare', 'basedata' )
	t:addProp( 'hostpid', 'rare', 'basedata' )

	-- prop values
	t:sp( 'type', 'pet' )
	t:sp( 'id', id )

	t.playergift	= {}
	t.alwaysupdate 	= true
	t.update		= Pet.update	--cover
	t.useSkill		= Pet.useSkill
	t.noHit			= true

	return setmetatable( t, Pet._META )
end

function Pet.create( id, host )
	assert(host, 'no pethost')
	local zone = host:getZone()
	if not zone then return end
	if cfg_zone[zone.id].nopet then return end
	local pet = Pet.new( id )
	local cfg = cfg_pet_ava[ id ]
	pet:sp( 'name', host:gp'name' or '?' )
	pet:setPos( host:gp'currPos'.x-8, host:gp'currPos'.y )
	pet:sp('hostguid', host:gp'guid')
	pet:sp('hostpid', host:gp'pid')
	pet:sp('level', host:gp'level' )

	AttrSys.add( pet, {[1]={ speed=host:gp'speed'+2} }, true, 'petnew' )
	local attrs = GrowSYS.getTotalAttr( host, 'pet' )
	AttrSys.add( pet, attrs, false, 'petnew', true )

	zone:addUnit(pet)
	host.petguid = pet:gp'guid'
end

function Pet.getSkill( pid )
	local r = GsRole.byPID( pid )
	if not r then return end
	local info = r.growsys.pet
	local lv = info.lv
	if lv < 1 then return { } end

	local cfg = Cfg.cfg_pet[lv]
	local stb = { cfg.skill[1] }

	for i = 1, cfg.skillnum do
		if info.exskillselect[i] and info.exskill[info.exskillselect[i]] and info.exskill[info.exskillselect[i]] ~= -1 then
			stb[#stb + 1] = info.exskill[info.exskillselect[i]]
		end
	end
	return stb
end

function Pet:update( e, now )
	local host = Entity.byGUID( self:gp'hostguid' )
	if not host then
		self:delete( )
		return
	end
	if self:getZone() ~= host:getZone( ) then
		if host.petguid == self:gp'guid' then
			host.petguid = nil
		end
		self:delete( )
		return
	end
	if not isInRect( self:gp'currPos', host:gp'currPos', Pet.JUMPTOHOSTDISTANCE, true ) then
		self:jumpTo( host:gp'currPos' )
	end
	EntityBase.update( self, e, now )
end

function Pet:getHost( )
	local host = Entity.byGUID( self:gp'hostguid' )
	return host
end

function Pet:delete( host )
	if host then
		host.petguid = nil
	end
	self:getZone():delEntity( self )
	Entity.delGUID( self:gp'guid' )
end

function Pet:runTo( tarpos )
	self:sp( 'targetPos', { x = target.x, y = target.y } )
	CallRound( self ).RunX{ Guid=self.guid, X=target.x, Y=target.y }
end

function Pet:useSkill(targetguid, skillID, SrcSkillID, point, extData)
	local skill = cfg_skill[ skillID ]
	if Cd(self, 'cd'..skillID, skill.cdTime or 2000) then return end
	if not skill then return end
	if self:isDead() then return end
	local host = self:getHost( )
	if not host then return end
	if host:isDead() then return end
	local skill = Cfg.cfg_skill[ skillID ]
	self:stop()
	local srcskill = cfg_skill[ SrcSkillID ]
	SkillManage.skillAttack( self, skill, srcskill, targetguid, point, newSkillGuid(), extData )
end
--event-------------------------------------
when{} function loadConfigGS()
	dofile'config/cfg_pet_ava.lua'
end
-- when{} function checkConfigGS()
	-- for id, v in pairs(cfg_pet) do
	-- end
-- end
when{ key = 'pet' }
function onChangeGrowSYSShow( pid, key, show )
	local r = GsRole.byPID( pid )
	if not r then return end
	if not r:getZone() then return end
	if not cfg_pet_ava[ show ] then return end
	local pet = Entity.byGUID( r.petguid )
	if pet then
		if pet:gp'id' ~= show then
			pet:delete( r )
			if not r.growsys.pet.hide then
				Pet.create( show, r )
			end
		end
	else
		if not r.growsys.pet.hide then
			Pet.create( show, r )
		end
	end
end

when{ key = 'pet' }
function onChangeGrowSYSHide( pid, key, hide )
	local r = GsRole.byPID( pid )
	if not r then return end
	if not r:getZone() then return end
	if not cfg_pet_ava[ r.growsys.pet.show ] then return end
	if hide then
		local pet = Entity.byGUID( r.petguid )
		if pet then
			pet:delete( r )
		end
	else
		Pet.create( r.growsys.pet.show, r )
	end
end
when{} function onEnterZone( role, zone, zoneid, oldzoneid )
	if not role.growsys.pet then return end
	if not cfg_pet_ava[ role.growsys.pet.show ] then return end

	if role.growsys.pet.hide then
		local pet = Entity.byGUID( role.petguid )
		if pet then
			pet:delete( role )
		end
	else
		Pet.create( role.growsys.pet.show, role )
	end
end

--RPC from cs-------------------------------------


--RPC from client---------------------------------
cdefine.c.AIUseSkill{ Guid=0, TGUID = 0, SkillID = 0, SrcSkillID = 0, Point = EMPTY, SkillGUID = 0, ExtData = EMPTY }
when{} function AIUseSkill(Guid, TGUID, SkillID, SrcSkillID, Point, SkillGUID, ExtData )
--_zdm('AIUseSkill:_______', GSMonitor.getElapse ( ), Guid, TGUID, SkillID, SrcSkillID, Point, SkillGUID, ExtData)
	if GSMonitor.getElapse ( ) > 1000000 then return end
	local role = GsRole.byNet(_from)
	if not role then return end
	local e = Entity.byGUID( Guid )
	if not e then return end
	local tar = Entity.byGUID( TGUID )
	if not tar then return end
	if CampManage.campRelation( role, tar ) ~= "enemy" then return end
	if e:isSp('hostguid') and e:gp'hostguid' == role:gp'guid' then --受我控制的AI单位
		-- me.growsys.pet.exskill
		-- me.growsys.pet.exskillselect
		-- r.growsys.pet.exskill
		-- r.growsys.pet.exskillselect
		e:useSkill( TGUID, SkillID, SrcSkillID, Point, ExtData )
	end
end
