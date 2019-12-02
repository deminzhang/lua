--gs_skill.lua
_G.Skill = {}
----------------------------------------------------------------
local EMPTY = EMPTY
----------------------------------------------------------------
function Skill.cast(unit,target,id,postion)
	local cfg = cfg_skill[id]
	if Skill.cd(unit,id) then return end
	if cfg.targetType == 0 then --敌对目标
		if not target then
			return
		end
		--check
		CallRound(unit).Cast{Guid=unit.guid,TGuid=target.guid,Id=id}
		--target:
		
	elseif cfg.targetType == 1 then --友好目标
		if not target then
			return
		end
	
	elseif cfg.targetType == 2 then --地面
		if postion==EMPTY then
			return
		end
		
	end

	
end

function Skill.cd(unit,id)
	
	return
end

function Skill.relation(unit,target)
	
	return
end


----------------------------------------------------------------
--event
function event.loadConfig()
	dofile"config/cfg_skill.lua"
end
function event.afterConfig()

end
function event.defineRole(role)
	role.skill = {}
	role.skillCD = {}
	role.skillPublicCD = 0
end
function event.loadUserInfo(info,role)
	print('loadUserInfo.skill')
	role.skill = info.skill or role.skill
	role.skillCD = info.skillCD or role.skillCD
	role.skillPublicCD = 0

end

----------------------------------------------------------------
--RPC
define.Cast{Guid=0,TGuid=0,SkillId=0,Pos=EMPTY} --使用技能
when{}
function event.Cast(Guid,TGuid,SkillId,Pos)
	local r = Role.byNet(_from)
	if not r then return end
	if 技能公共CD中 then return end	--TODO 
	local u = r
	if Guid ~= 0 then --可控非主角
		u = Unit.get(Guid)
		if not u then return end
		if u:getv'hostguid' ~= r.guid then return end --无权
	end
	local tar = Unit.get(TGuid)
	Skill.cast(u, tar, SkillId, Pos)
end
