--cs
define.NewToken{Token = '', Data = {}, Reason = ''}
--cs
define.DelToken{Token = '', Reason='noreason'}
--c
define.Enter{Token = ''}
define.EnterDone{}
--cs
define.TransTo{Token='', Gkey = '', Data = {}}
--cs
define.TransBack{Token = '', Zoneid = 0, Data = {}}


function event.NewToken(Token, Data, Reason)
	print('NewToken', Token, Reason )
	local role = Role.new(Data, Token, false)
	role:setCS(_from)
	dump(Data)
	local zone, pos
	if Data.ckey then --副本
		--TODO
	elseif Data.backPos then --从副本回,普通图落点为副本的坐标
		--TODO
	else	--普通野外地图	返回到数据库存的点
		zone = Zone.byID(Data.zoneid, role.pid)
		pos = Data.pos or {x=1,y=1,z=1,r=0}
	end
	
	if pos then
		role:setPos( pos.x, pos.y, pos.z, pos.r )
	end
	zone:addUnit(role)
end

function event.DelToken(Token, Reason)
	local role = Role.byToken(Token)
	print('DelToken',Token, Reason, role)
	if not role then return end

	local zone = role:getZone()
	if zone then
		--TODO 关闭互动如双人坐骑
		
		zone:delUnit(role, Reason)
	else
		print('DelTokenNoZone',Token, Reason)
	end
end

function event.Enter(Token)
	local role = Role.byToken(Token)
	print('Enter',Token, role)
	if not role then --retry
		_from.EnterWait{}
		return
	end
	local zone = role:getZone()
	if not zone then
		print('EnterNoZone', role and role.pid, Token )
		CallRoleCS(role).GSClearClient{ Token = Token }
		return
	end
	--onEnter
	-- net.login = true
	role:setNet(_from)
	local roleInfo = {guid=role.guid}
	-- for k,v in pairs(私人属性) do
	-- 	roleInfo[k] = 
	-- end
	local units = {[role.guid]=role:getData()} --除自己外因场景载完再加
	local zdata = zone:getData(role)
	local data = {
		Id = zone.id,
		Time = os.time(),
		Role = roleInfo,
		Units = units,
		Zone = zdata,
	}
	role:setProtect(true)
	CallRole(role).EnterZone(data)
end

--前端场景载入完毕,取消隐藏,保护/通知交际圈等
local CREATE_NUM = 9
function event.EnterDone()
	print('>>EnterDone')
	local role = Role.byNet(_from)
	if CREATE_NUM == 1 then
		for guid, u in pairs(role:getRoundUnits(true)) do
			CallRole(role).AddUnit{T=u:getData()}
		end
	else
		local units = {}	--除自己外因场景载完再加
		local n = 0
		for guid, u in pairs(role:getRoundUnits(true)) do
			units[guid] = u:getData()
			n=n+1
			if n>CREATE_NUM then
				n=0
				CallRole(role).AddUnits{List=units}
				units = {}
			end
		end
		if next(units) then
			CallRole(role).AddUnits{List=units}
		end
	end
	--CallTeam(role).TeamMateEnter
	--CallFriends(role).FriendEnter
	--CallGuild(role).GuildMemberEnter
	role:setProtect(false)
end