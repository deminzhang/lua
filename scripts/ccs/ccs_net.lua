--ccs_net.lua
--烽火照西京，心中自不平。牙璋辞凤阙，铁骑绕龙城。雪暗凋旗画，风多杂鼓声。宁为百夫长，胜作一书生。
print('>>ccs_net')
print('>>localIP:',_net.hostips())
_G.NetMgr = NetMgr or {}
----------------------------------------------------------------
function NetMgr.listen_ccs()
	local onListen = function(net, listener, ip, port, myip, myport, share)
		print('>>onListen',net, ip, port)
	end
	local onClose = function(net, err, code)
		print('>>onClose',net,err, code)
		NetMgr.unRegServer(net)
	end
	Net.listen(os.info.listen_ccs,onListen,onClose)
end
----------------------------------------------------------------
--event
function event.onStart()
	NetMgr.listen_ccs()
end
----------------------------------------------------------------
define.SelectCGS{Cid=0,Zid=0,Use=''}
when{} function SelectCGS(Cid,Zid,Use)
	local line, cgs = next(NetMgr.getAllCGS()) --TODO 临时选一个
	if cgs then
		_from.AllotCGS{Line=line,Addr=cgs.addr,Cid=Cid,Zid=Zid,Use=Use}
	else
		_from.AllotCGS{Line=0,Cid=Cid,Zid=Zid,Use=Use}
	end
end

