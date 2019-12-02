--gs_callout
--
----------------------------------------------------------------
local next = next
local pairs = pairs
local _encode = _encode
local from32l = string.from32l
----------------------------------------------------------------
do	--CallRound(unit, true).RPC{}
	local _unit, _nome, _rpc, _trace
	local _callRound = function(args)
		local unit = _unit
		_unit = nil
		local mguid = unit.guid
		local data, len, head
		local uget = Unit.get
		local role, net
		for tile,_ in pairs(unit.tile:allSight()) do
			for guid,type in pairs(tile.units) do
				if type=='role' then
					if not(_nome and guid==mguid) then
						role = uget(guid)
						net = role:getNet()
						if net then
							if not data then
								data, len = _encode(_rpc, args)
								head = from32l(len)
							end
							net:send(head)
							net:send(data, len)
						end
					end
				end
			end
		end
	end
	local callout = setmetatable({},{__index=function(t,rpc)
		_rpc = rpc
		return _callRound
	end})
	function _G.CallRound(remote, nome)
		_unit, _nome = remote, nome
		--_trace = debug.traceback()
		return callout
	end
end
----------------------------------------------------------------
do	--CallRole(role).RPC{}
	local _role, _nome, _rpc, _trace
	local _callRole = function(args)
		local net = _role:getNet()
		_role = nil
		if not net then return end
		local data, len = _encode(_rpc, args)
		local head = from32l(len)
		net:send(head)
		net:send(data, len)
	end
	local callout = setmetatable({},{__index=function(t,rpc)
		_rpc = rpc
		return _callRole
	end})
	function _G.CallRole(role, nome)
		if role.type~='role' then
			error('CallRole call a non-role unit '..role.type) 
		end
		_role, _nome = role, nome
		--_trace = debug.traceback()
		return callout
	end
end
----------------------------------------------------------------
do	--CallRoles(roles).RPC{}
	local _roles, _rpc, _trace
	local _callRoles = function(args)
		if not next(_roles) then return end
		local data, len = _encode(_rpc, args)
		local head = from32l(len)
		for guid,role in pairs(_roles) do
			if role.type=='role' then
				local net = role:getNet()
				if net then
					net:send(head)
					net:send(data, len)
				end
			end
		end
		_roles = nil
	end
	local callout = setmetatable({},{__index=function(t,rpc)
		_rpc = rpc
		return _callRoles
	end})
	function _G.CallRoles(roles)
		_roles = roles
		--_trace = debug.traceback()
		return callout
	end
end
----------------------------------------------------------------
do	--CallRoleCS(role).RPC{}
	local _role, _rpc, _trace
	local _callRoleCS = function(args)
		local net = _role:getCS()
		_role = nil
		if not net then return end
		local data, len = _encode(_rpc, args)
		local head = from32l(len)
		net:send(head)
		net:send(data, len)
	end
	local callout = setmetatable({},{__index=function(t,rpc)
		_rpc = rpc
		return _callRoleCS
	end})
	function _G.CallRoleCS(role)
		if role.type~='role' then
			error('CallRole call a non-role unit '..role.type) 
		end
		_role = role
		--_trace = debug.traceback()
		return callout
	end
end
----------------------------------------------------------------
do	--CallTeam(role).RPC{}

end
----------------------------------------------------------------
do	--CallFriends(role).RPC{}

end
----------------------------------------------------------------
do	--CallGuild(role).RPC{}

end
----------------------------------------------------------------
