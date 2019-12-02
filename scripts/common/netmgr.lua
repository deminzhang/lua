--netmgr.lua
--服务器间的接连管理
_G.NetMgr = {}
define.RegServer{Sid=0,Line=0,Addr='',Token='',Pid=0}
define.onRegServer{Sid=0,Line=0,Addr=''}
define.unRegServer{Sid=0,Line=0,Addr='',Token=''}
define.onUnRegServer{server={},Sid=0,Line=0,Addr=''}
----------------------------------------------------------------
--local var
local alls = {
	-- [0] = {[0]=ccs,cgs1,cgs2,},
	-- [1] = {[0]=cs1,gs1,gs2,},
	-- [2] = {[0]=cs2,gs1,gs2,},
	-- ...
}
local ccs
local csGroup = {}--{cs1,cs2,...}
local gsGroup = {}--{gs1,gs2,...}
local cgsGroup = {}--{cgs1,cgs2,...}
local net2server = table.weakkv()
-- server结构 = {
	-- sid = Sid, line = Line, 
	-- addr = Addr, token = Token, 
	-- processID = ProcID, --进程id(仅同机CS管理GS用)
	-- net = net, state = 'connect', 
	-- playerNum = 0,	players = {[playerId]=true},
-- }
----------------------------------------------------------------
--glocal
function NetMgr.getCCS()	--跨服中心 cs cgs
	return ccs
end
function NetMgr.getCS(sid)	--各服中心 gs
	return csGroup[sid]
end
function NetMgr.getGS(line)	--各服各线 cs
	return gsGroup[line]
end
function NetMgr.getCGS(line)--跨服各线 ccs cs
	return cgsGroup[line]
end

function NetMgr.getAllCS()
	return csGroup
end
function NetMgr.getAllGS()
	return gsGroup
end
function NetMgr.getAllCGS()
	return cgsGroup
end

function NetMgr.getServerByNet(net)
	return net2server[net]
end

function NetMgr.getServer(sid,line)
	local g = alls[sid]
	return g and g[line]
end

function NetMgr.regServer(net,Sid,Line,Addr,Token,ProcID)
	print('>>RegServer',Sid,Line,Addr,Token)
	local old,svr
	if Sid==0 then
		if Line==0 then --ccs
			old = ccs
		else	--cgs
			old = cgsGroup[Line]
		end
	else
		if Line==0 then --cs
			old = csGroup[Sid]
		else	--gs
			old = gsGroup[Line]
		end
	end
	if old then
		svr = old
		net2server[old.net] = nil
		net2server[net] = svr
		if svr.net ~= net then
			if svr.net:closed() then --重连
				if svr.addr ~= Addr then
					Log.warn('reRegServer not equal old:'..svr.addr..' new:'..Addr)
				end
				svr.addr = Addr
			else --未断开的旧连
				error('RegServer conflict. old:'..svr.addr..' new:'..Addr)
			end
		end
		svr.state = 'connect'
		svr.net = net
		svr.token = Token
		svr.processID = ProcID
	else
		svr = {
			sid = Sid, line = Line, 
			addr = Addr, token = Token, 
			processID = ProcID, --进程id(仅同机CS管理GS用)
			net = net, state = 'connect', 
			playerNum = 0,	players = {}, --[playerId]=true
		}
		net2server[net] = svr
		if Sid==0 then
			if Line==0 then --ccs
				ccs = svr
			else	--cgs
				cgsGroup[Line] = svr
			end
		else
			if Line==0 then --cs
				csGroup[Sid] = svr
			else	--gs
				gsGroup[Line] = svr
			end
		end
	end
	net.server_id = Sid
	net.line = Line
	if alls[Sid] then
		alls[Sid][Line] = svr
	else
		alls[Sid] = {[Line] = svr}
	end
	onRegServer{Sid=Sid,Line=Line,Addr=Addr}
end

function NetMgr.unRegServer(net)
	local svr = net2server[net]
	if not svr then return end
	print('unRegServer2',svr.sid,svr.line,net)
	net2server[net] = nil
	alls[svr.sid][svr.line] = nil
	onUnRegServer{server=svr,Sid=svr.sid,Line=svr.line,Addr=svr.addr}
end

----------------------------------------------------------------
when{} function RegServer(Sid,Line,Addr,Token,ProcID,net)
	NetMgr.regServer(net or _from,Sid,Line,Addr,Token,ProcID)
end
