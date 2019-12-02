--gs_net.lua
print('>>gs_net')
_G.NetMgr = NetMgr or {}
----------------------------------------------------------------
local listen_gs = os.listenAddr(os.info.server_id,os.info.line)
----------------------------------------------------------------
function NetMgr.listen_gs()
	local onListen = function(net, listener, ip, port, myip, myport, share)
		print('>>onListen',net, ip, port, share)
	end
	local onClose = function(net, err, code)
		local role = Role.byNet(net)
		print('>>onClose',net,err, code, role)
		if role then
			role:disconnect()
		end
	end
	Net.listen(listen_gs,onListen,onClose)
end
if os.info.type=='gs' then
	function NetMgr.connectCS()
		local listen_cs = os.listenAddr(os.info.server_id,0)
		local onConnect = function(net, ip, port, myip, myport)
			RegServer{Sid=os.info.server_id,Line=0,Addr=listen_cs,net=net}
			net.RegServer{Sid=os.info.server_id,Line=os.info.line,Addr=listen_gs,ProcID=os.id()}
		end
		local onClose = function(net, err, code)
			NetMgr.unRegServer(net)
			os.sleep(1000)
			os.exit(0)
		end
		print('>>connectCS',listen_cs)
		Net.connect(listen_cs,onConnect,onClose,10)
	end
end
if os.info.type=='cgs' then
	function NetMgr.connectCCS()
		local listen_ccs = os.info.listen_ccs
		local onConnect = function(net, ip, port, myip, myport)
			RegServer{Sid=0,Line=0,Addr=listen_ccs,net=net}
			net.RegServer{Sid=0,Line=os.info.line,Addr=listen_gs}
		end
		local onClose
		onClose = function(net, err, code)
			print('>>reconnectCCS',listen_ccs)
			NetMgr.unRegServer(net)
			Timer.add(2000,NetMgr.connectCCS)
		end
		Net.connect(listen_ccs,onConnect,onClose,2)
	end
end
----------------------------------------------------------------
--event
function event.onStart()
	NetMgr.listen_gs()
	if os.info.type=='gs' then
		NetMgr.connectCS()
	end
	if os.info.type=='cgs' then
		NetMgr.connectCCS()
	end
end
----------------------------------------------------------------
--PRC

