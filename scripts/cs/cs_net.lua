--cs_net.lua
--百战沙场碎铁衣，城南已合数重围。突营射杀呼延将，独领残兵千骑归。
print('>>cs_net')
print('>>localIP:',_net.hostips())
_G.NetMgr = NetMgr or {}
define.onConnectCGS{Line=0,Use='',Cid=0,Zid=0}
----------------------------------------------------------------
local random = math.random
local listen_cs = os.listenAddr(os.info.server_id,os.info.line)
local s_token = 0
----------------------------------------------------------------
function NetMgr.launchGS(line, gstype)
	s_token = s_token + 1
	local token = line..'|'..s_token
	local args = ('type=gs gstype=%s line=%s token=%s')
		:format(gstype,line,token)
	local pid = os.launch('.', args)
	print('>>launch gs pid=',pid)
end

function NetMgr.listen_cs()
	local onListen = function(net, listener, ip, port, myip, myport, share)
		print('>>onListen',net, ip, port, share)
	end
	local onClose = function(net, err, code)
		print('>>onClose',net,err, code)
		if net.server_id then
			NetMgr.unRegServer(net)
		end
		local c = Client.byNet(net)
		if c then c.setNet(nil) end
	end
	Net.listen(listen_cs,onListen,onClose)
end

--TODO 暂用random分线, 应当按活的GS,人数,先充足一线,再充下一线等
function NetMgr.selectGS(type,n)
	local gss = NetMgr.getAllGS()
	if n then return gss[n] end
	if type=='world' then 		--野外 1-50
		local line = random(os.info.gs_num)
		local gs = gss[line] or gss[1]
		return gs
	elseif type=='dungeon' then	--副本 51-99
		local line = random(51, 50+os.info.dun_num)
		local gs = gss[line]
		return gs
	--elseif type=='battle' then	--小跨101+
		--异步
	--elseif type=='war' then		--大跨901+
		--异步
	else error('invalid gs type:'..type)
	end
end

--常连跨服中心服,断则重连
function NetMgr.connectCCS()
	local onConnect = function(net, ip, port, myip, myport)
		RegServer{Sid=0,Line=0,Addr=listen_cs,net=net}
		net.RegServer{Sid=os.info.server_id,Line=0,Addr=os.info.listen_ccs}
	end
	local onClose = function(net, err, code)
		NetMgr.unRegServer(net)
		Timer.add(3000,NetMgr.connectCCS)
	end
	print('>>connectCCS',os.info.listen_ccs)
	Net.connect(os.info.listen_ccs,onConnect,onClose,5)
end

function NetMgr.connectCGS(line,addr,callback,onFail)
	local onConnect = function(net, ip, port, myip, myport)
		RegServer{Sid=0,Line=line,Addr=addr,net=net}
		net.RegServer{Sid=os.info.server_id,Line=0,Addr=os.info.listen_ccs}
		callback(cgs)
	end
	local onClose = function(net, err, code)
		NetMgr.unRegServer(net)
		onFail(line,addr)
	end
	print('>>connectCGS',addr)
	Net.connect(addr,onConnect,onClose,2)
end

----------------------------------------------------------------
--event
function event.loadConfig()
	dofile"config/cfg_zone.lua"
end
function event.onStart()
	NetMgr.listen_cs()
	-- for line = 1, os.info.gs_num do
		-- NetMgr.launchGS(line, 'world')
	-- end
	-- for line = 51, 50+os.info.dun_num do
		-- NetMgr.launchGS(line, 'dungeon')
	-- end
	NetMgr.connectCCS()
end
when{} --regGSs
function onUnRegServer(server,Sid,Line)
	print('>>onUnRegServer',Sid,Line)
	if Line==0 then return end --CSS
	for cid,_ in pairs(server.players)do --掉线在此gs上的角色
		local c = Client.byPID(cid)
		if c then
			Client.del(c, 'GS crashed')
		end
		server.players[cid] = nil
		server.playerNum = 0
	end
	if server.processID and server.processID~=0 then --reLaunchGS
		print('>>RelaunchGS',Line)
		print( pcall(os.kill,server.processID) )
		NetMgr.launchGS(Line, server.type)
	end
end
----------------------------------------------------------------
--PRC
