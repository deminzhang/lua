--cs_login.lua --TODO转loginServer
----------------------------------------------------------------
--tolocal
local CONFIG = CONFIG
local format = string.format
local Client = Client
local print = print
----------------------------------------------------------------
--cfg

----------------------------------------------------------------
--local
local s_token = 0
local newtoken = function( )
	s_token = s_token + 1
	return ('gstoken_s%d_p%s_%d_%d'):format(os.info.server_id,
		os.info.platform, s_token, os.time())
end
local GetRoleInfo = function( uid, pid )
	--local uid = c.getUID()
	--local pid = c.getPID()
	print(uid,pid)
	--local player = _ORM:table'player':where{ pid = pid }:select( )[1]
	local player = _SQL:run('select * from player where pid=$1', pid)[1]
	local info = {
		serverid = os.info.server_id,
		player = player,
	}
	-- if prejobpids[player.job] and prejobpids[player.job][pid] then --预创建角色
		-- info = prejobpids[player.job][pid][2]
		-- prejobpids[player.job][pid] = nil
		-- info.player = player
		-- getUserInfoX{ uid = uid, pid = pid, info = info }
		-- print("precreateGsInfo", pid)
	-- else
		getUserInfo{uid=uid,pid=pid,info=info,step='gs'}
	-- end
	--info.account = _ORM:table'account':where{ uid = uid }:select( )[1]

	-- local net = c.getNet()
	-- if net and net._logininfo then
		-- info.qqinfo = net._logininfo.qqinfo
	-- end
	return info, newtoken()
end

----------------------------------------------------------------
--RPC.from client
define.Login{Uid='',Pass='',Token='', Sid=1, Mac='',Kick=false}
define.CreateRole{Name='',Gender=0,Job=0,Face=0,Hair=0,Body=0}
define.DeleteRole{Pid=0}
define.RecoverRole{Pid=0} 
define.TryEnter{Pid=0} 

--登陆
function event.Login(Uid, Pass, Token, Sid, Mac, Kick)
	print('Login', Uid,Pass,Token, Sid, Mac, Kick)
	--check session
	local sUID = format('%s|%s', Sid, Uid)
	
	local c = Client.byUID(sUID)
	print(c,c and c.getNet(), 'XX')
	local relogin
	if c then
		local net = c.getNet()
		if net then
			if Kick then
				net.LoginKick{} --帐号已从别处登陆
				c.setNet(nil)
				net.kicked = true
				net:close('loginkick')
			else
				_from.LoginDuplicate{}--帐号在游戏中,是否强制踢出?
				return
			end
		end
		relogin = true
	end
	--check db
	local r = _SQL:run('select * from account where uid=$1',sUID)
	if r then
	
	else
		-- 	createacc(Uid)
		_SQL:run([[insert into account(uid, server_id, plat_uid, gold, accgold, costgold, ip, frozen, frozenreason, createtime, rechargetimes) values($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11);]],
			sUID, Sid, Uid, CONFIG.ROLE_CREATE_GOLD, 0, 0, '', _SQL.time(0), '', _SQL.time(), 0)
	end
	if not relogin then
		c = Client.add(sUID, Sid)
	end
	c.macAddr = Mac
	c.setNet(_from)
	
	local list = _SQL:run('select * from player where uid=$1',sUID)
	_from.RoleList{Data=list}
end
--创角
function event.CreateRole(Name, Gender, Job, Face, Hair, Body)
	local c = Client.byNet(_from)
	print('CreateRole',Name, Gender, Job, Face, Hair, Body)

	local r = _SQL:run('select * from player where name=$1',Name) 
	if r then
		_from.Error{Err=_T'重名'}
		return
	end
	local pid = GetSeqIdS('player', os.info.server_id)
	print('playerids.nextval', pid)
	_SQL:run([[insert into player(pid, name, uid, gender, job, level, createtime, delflag, deltime, prefab) values($1,$2,$3,$4,$5,$6,$7,$8,$9,$10);]],
		pid, Name, c.getUID(), Gender, Job, 1, _SQL.time(), false, _SQL.time(0), false)

	_from.RoleNew{Data={pid=pid, name=Name, gender=Gender,
		job=Job, face=Face, hair=Hair, body=Body}}
end
--删角
function event.DeleteRole(Pid)
	local c = Client.byNet(_from)
	local uid = c.getUID()
	print('DeleteRole',Pid)
	local r = _SQL:run('select * from player where pid=$1',Pid)
	if r and r[1].uid == uid then
		_SQL:run([[update player set delflag=true,deltime=$1]], _SQL.time())
	end
	_from.RoleDel{Pid=Pid}
end
--恢角
function event.RecoverRole(Pid)
	local c = Client.byNet(_from)
	local uid = c.getUID()
	print('RecoverRole',Pid)
	local r = _SQL:run('select * from player where pid=$1',Pid)
	if r then
		r = r[1]
		if r.uid == uid and (os.now()-r.deltime)<ROLE_RECOVER_TIME then
			_SQL:run([[update player set delflag=false,deltime=0]])
		else
			_from.Error{Err=_T'无法恢复'}
			return
		end
	else
			_from.Error{Err=_T'无法恢复'}
		return
	end
	_from.RoleRecover{Pid=Pid}
end
--进入
function event.TryEnter(Pid)
	local c = Client.byNet(_from)
print('TryEnter', Pid, c)
	assert(c,'未登陆')
	local reconnect, reconnect2 = false,false--重连, 换机重连
	local oldr = c.getPID()
	if oldr then
		if Pid ~= oldr then--账号其它角色在线
			--其它角色下线() or 战斗中禁止下线遁()
		else
			reconnect = true
		end
	end
	print('reconnect',reconnect)
	local gs, user, token
	if reconnect then
		gs = c.getGS()
		token = c.getToken()
	else
		gs = NetMgr.selectGS('world')
		user, token = GetRoleInfo( c.getUID(), Pid )
		user.zoneid=1
		--TOTEST
		-- for i=1,30,3 do
			-- for j=1,30,3 do
				-- user.pos = {x=i,y=1,z=j,r=0}
				-- user.player.pid = user.player.pid + 1
				-- gs.net.NewToken{Token = newtoken(), Data = user, Reason = 'login'}
				-- user.pos = nil
			-- end
		-- end
		-- user.player.pid = Pid
		
		gs.net.NewToken{Token = token, Data = user, Reason = 'login'}
	end
	--dump(user)

	c.setToken( token )
	c.setPID(Pid)
	c.setGS( gs )
	c.setLine( gs.line )
	
	local sinfo = { 
		Cfg_Plat = Cfg_Plat,
		server_id = os.info.server_id
	}
	--getServerInfo{ info = sinfo, step = 'login' }
	
	print('gs.addr',gs.addr)
	_from.OnLogin{Res={user=user, serverinfo=sinfo, token=token, addr=gs.addr}}
end

----------------------------------------------------------------
define.TryChangeZoneTest{Zid=0} --c
function event.TryChangeZoneTest(Zid)
	--assert(cfg_zone[Zid],Zid)
	local c = Client.byNet(_from)
	local oldgs = c.getGS()
	oldgs.net.DelToken{Token=c.getToken(), Reason='changezone'}
	
	local gs = NetMgr.selectGS('world')
	if oldgs == gs then
		--转同线跳图
	end
	local user, token = GetRoleInfo( c.getUID(), c.getPID() )
	user.zoneid=Zid
	gs.net.NewToken{Token=token, Data=user, Reason='changezone'}
	
	c.setToken( token )
	c.setGS( gs )
	c.setLine( gs.line )
	print('gs.addr',gs.addr)
	local sinfo = { 
		Cfg_Plat = Cfg_Plat,
		server_id = os.info.server_id
	}
	--getServerInfo{ info = sinfo, step = 'login' }
	_from.OnLogin{Res={user=user, serverinfo=sinfo, token=token, addr=gs.addr}}
end

define.TryCrossZoneTest{Zid=0}	--c
function event.TryCrossZoneTest(Zid)
	--assert(cfg_zone[Zid],Zid)
	local ccs = NetMgr.getCCS()
	if not ccs then
		_from.Error{Err=_T'CCS fail'}
		return
	end
	local c = Client.byNet(_from)
	ccs.net.SelectCGS{Pid=c.getPID(),Zid=Zid,Use='test'}
end
when{Use='test'}
function onConnectCGS(Line,Use,Cid,Zid)
	print('onConnectCGS',Line,Use,Cid,Zid)
	local c = Client.byPID(Cid)
	if not c then return end
	local oldgs = c.getGS()
	oldgs.net.DelToken{Token=c.getToken(), Reason='crosszone'}
	
	local gs = NetMgr.getCGS(Line)
	if oldgs==gs then
		--应当不会有从跨服直切到跨服的情况吧
	end
	local user, token = GetRoleInfo(c.getUID(), c.getPID())
	user.zoneid=Zid
	gs.net.NewToken{Token=token, Data=user, Reason='crosszone'}
	
	c.setToken( token )
	c.setGS( gs )
	c.setLine( gs.line )
	print('gs.addr',gs.addr)
	local sinfo = { 
		Cfg_Plat = Cfg_Plat,
		server_id = os.info.server_id
	}
	--getServerInfo{ info = sinfo, step = 'login' }
	c.getNet().OnLogin{Res={user=user, serverinfo=sinfo, token=token, addr=gs.addr}}
end

define.AllotCGS{Line=0,Addr='',Cid=0,Zid=0,Use=''} --ccs
function event.AllotCGS(Line,Addr,Cid,Zid,Use)
	print('AllotCGS',Line,Addr,Cid,Zid,Use)
	local c = Client.byPID(Cid)
	if not c then return end
	if Line==0 then
		_from.Error{Err=_T'CGS fail'}
		return
	end
	local cgs = NetMgr.getCGS(Line)
	if cgs then
		onConnectCGS{Line=Line,Use=Use,Cid=Cid,Zid=Zid}
	else
		NetMgr.connectCGS(Line,Addr,function(cgs)
			print('onConnectCGS',Cid,c)
			onConnectCGS{Line=Line,Use=Use,Cid=Cid,Zid=Zid}
		end, function()
			local c = Client.byPID(Cid)
			print('onConnectCGSFail',Cid,c)
			if not c then return end
			c.getNet().Error{Err=_T'CGS fail'}
		end)
	end
end
----------------------------------------------------------------
--RPC.fromGS
