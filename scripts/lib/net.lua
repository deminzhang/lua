
--[[in C===================================================================
local server = _net.listen(addr,onListen,onClose)
	onListen(net, listener, cip, cport, sip, sport, share)
	net:close()
	net:closed()
	net:receive( len, func_onReceive(net, data), timeout, bool_tostr)
	net:send(string/byte)
	net:nagle(bool) --setnodelay
	net:share(...)
--server在未关时C层会强引用,不会被回收
local client = _net.connect(addr,port,onConnect,onClose,timeOut,laddress,lport)
	onConnect(net, listener, cip,cport, sip,sport, share)
	onClose(net, res, errcode) --res=reason or where
--未回调前 C层对client进行强引用,不会被回收
_net.hostips(addr) --DNS return IPs

function _callin(from, data)
	local fn, args = _decode(data)
	local func = event[fn]
	assert(func, fn..'invaild RPC')
	_enqueue(0, from, fn, args)
end
--]]
--lua===================================================================
_G.Net = {}
---------------------------------------------------------------
--config/const
local NET_LOG_ON = true			--日志开关
local NET_RECV0_TIMEOUT = 10	--首次连接超时s
local NET_RECV_TIMEOUT = 300	--接收超时s
local NET_CONN_TIMEOUT = 10		--连接超时s
local NET_HEAD_LEN = 4			--包头长度
local NET_RECV_MAX_LEN = 0x100000--最大接收大小
Net.NET_HEAD_LEN = NET_HEAD_LEN
Net.HEART 			= 0
----------------------------------------------------------------
--to local
local print = print
local format = string.format
local char = string.char
local from32l = string.from32l
local to32l = string.to32l
local find = string.find
local toJson = table.toJson
local push = table.push
local _listen = _net.listen
local _connect = _net.connect
local _hostips = _net.hostips
----------------------------------------------------------------
--local
local netnum = 0
local nets = {}				--main refer
local weaks = table.weakk()	--weakk refer
local newconn = table.weakk()
local sendcache = nil
----------------------------------------------------------------
--normal count of nets
function Net.count()
	return netnum,nets
end
--weak count of nets
function Net.weakCount()
	return table.count(weaks),weaks
end
--new count of nets
function Net.newCount()
	return table.count(newconn),newconn
end
--cleanup newconn without valid data timeout
function Net.cleanUp()
	local now = os.time()
	for net, t in pairs(newconn) do
		if now - t > 60 then
			newconn[net] = nil
			net:close('newnettimeout')
		end
	end
end

function Net.begin()
	sendcache = {}
end

function Net.commit()
	local n = #sendcache
	for i = 1, n, 2 do
		local net, data = sendcache[i], sendcache[i+1]
		net:send( data )
	end
	sendcache = nil
	--Net.deflates = nil
	return n/2
end

function Net.rollback()
	sendcache = nil
	--Net.deflates = nil
end

function Net.sendEx(net, data)
	if sendcache then
		push(sendcache, net, data)
	else
		return net:send(data)
	end
end
----------------------------------------------------------------
define.netCleanUpdate{}
when{} function netCleanUpdate()
	netCleanUpdate{_delay=10000}
	Net.cleanUp()
	if _DEVELOPMENT and CONFIG.LEAK_CHECK then--泄漏检查 TODO 发布版关闭,手动运行
		-- debug.gc()
		-- debug.gc()
		for net,_ in pairs(weaks) do
			if not nets[net] then
				local t = debug.findobj(_G, function(t)return t==net end,'_G')
				print('weaknet:')
				dump(t,2)
			end
		end
	end
end
netCleanUpdate{_delay=2000}
----------------------------------------------------------------
--common 
local onListen0, _onClose0, onHead, onBody, onHeart
local onPipeLen, onPipe
function onPipeLen(net,data)
	local len = data:byte()
	if len<0 then
		net:close('dataerror')
		return
	end
	net:receive(len, onPipe, NET_RECV_TIMEOUT,true)
end
function onPipe(net,data)
	--print('>>net.share to:',data)
	net:share(data,'\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0')
	net:close('share to'..data)
end
function onHead(net, data)
	local len = data:to32l()
	if len==542393671 then --if data:lead'GET ' then
		newconn[net] = nil
		Http.onHttpGet(net,data)
	elseif len==1414745936 then --if data:lead'POST' then
		newconn[net] = nil
		Http.onHttpPost(net,data)
	elseif len==1162889552 then --if data:lead'PIPE' then
		net:receive(1, onPipeLen, NET_RECV_TIMEOUT,true)
	elseif len==0 then		--hearbeat
		net:receive(NET_HEAD_LEN, onHeart, NET_RECV_TIMEOUT)
	elseif len < 0 or len > NET_RECV_MAX_LEN then --1~int4
		net:close('dataerror')
	else --bodylength
		net:receive(len, onBody, NET_RECV_TIMEOUT)
	end
end
function onBody(net, data)
	--print( net, 'onBody>>', data )
	newconn[net] = nil
	_callin(net, data)
	net:receive(NET_HEAD_LEN, onHead, NET_RECV_TIMEOUT)
end 
function onHeart(net, data)
	local code = data:to32l()
	print('>>onHeartCode:', code)
	net:receive(NET_HEAD_LEN, onHead, NET_RECV_TIMEOUT)
end 
function onListen0(net, listener, ip, port, myip, myport, share)
	--print('>>onListen0',net, listener, ip, port, share)
	weaks[net] = true --只管加不管减
	nets[net] = true
	netnum = netnum + 1
	newconn[net] = os.time()
	net.ip = ip
	net.port = port
	net.onClose = listener.onClose
	if share then
		share = share:tostr()
		if share == '\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0' then
			share = nil
		elseif share ==  '' then
			share = nil
		end
	end
	if share then	--http call
		Http.onDataShared(net,share)
	else				--normal binary call
		net:receive(NET_HEAD_LEN, onHead, NET_RECV0_TIMEOUT )
		Net.callout( net )
		local onListen = listener.onListen
		if onListen then
			onListen(net, listener, ip, port, myip, myport, share)
		end
	end
end
function onClose0(net, err, code)
	netnum = netnum - 1
	nets[net] = nil
	newconn[net] = nil
	
	local onClose = net.onClose
	if onClose then onClose(net, err, code) end
	print( '>>net.onClose', os.info.type, err, code, net.ip )
end
Net.onHead = onHead
----------------------------------------------------------------
--listen address as format like addr = 'XXX.com:PORT@PIPE'
--if PIPE listen pipe else listen ip:port
function Net.listen(addr, onListen, onClose)
	print('>>listen:'..addr)
	local _,_,host,port,pipe = addr:find("[%[]*([^%]]*)[%]]*:(%d+)[%@]*([^%@]*)")
	if not host then
		error('Net.listen invalid addr:',addr)
	end
	if pipe and pipe~='' then	--*:port@pipe
		print('>>>listen @'..pipe)
		local s = _listen('@'..pipe, onListen0, onClose0)
		s.onListen = onListen
		s.onClose = onClose
	else	--*:port
		print('>>>listen [::]:'..port)
		local s = _listen('[::]:'..port, onListen0, onClose0)
		s.onListen = onListen
		s.onClose = onClose
		if os.info.system=='windows' then
			print('>>>listen 0.0.0.0:'..port)
			s = _listen('0.0.0.0:'..port, onListen0, onClose0)
			s.onListen = onListen
			s.onClose = onClose
		end
	end
end
----------------------------------------------------------------
local function onConnect0(net, ip, port, myip, myport)
	print('>>onConnect',net, ip, port)
	weaks[net] = true
	nets[net] = true
	netnum = netnum + 1
	Net.callout( net )
	local pipe = net.onPipe
	if pipe and pipe~='' then
		net:send('PIPE')
		net:send(char(#pipe))
		net:send(pipe)
	end
	net:receive(NET_HEAD_LEN, onHead, NET_RECV_TIMEOUT)
	local onConnect = net.onConnect
	if onConnect then
		onConnect(net, ip, port, myip, myport)
	end
end
local function onClose0(net, err, code)
	print('>>connect.onClose',net, err, code)
	if nets[net] then --已连接过的
		netnum = netnum - 1
		nets[net] = nil
	end
	local onClose = net.onClose
	if onClose then
		onClose(net, err, code)
	end
end
function Net.connect(addr,onConnect,onClose,timeout)
	local _,_,host,port,pipe = addr:find("[%[]*([^%]]*)[%]]*:(%d+)[%@]*([^%@]*)")
	if not host then
		error('Net.listen invalid addr:',addr)
	end
	--TODO _hostips多返回值,依次尝试
	local ip = _hostips(host)
	print('>>connect:',host,port,pipe,ip)
	if not ip then
		error( 'no host:'..host )
		return
	end
	if not port then port = 80 end
	local net = _connect(ip, toint(port), onConnect0, onClose0, timeout or NET_CONN_TIMEOUT)
	net.onConnect = onConnect
	net.onClose = onClose
	net.onPipe = pipe
	return net
end
---------------------------------------------------------------- Http
-- 解析xxx1=xxxa&xxx2=xxxb的字符串为表
--Net.parseParam('xxx1=xxxa&xxx2=xxxb')return{xxx1='xxxa',xxx2='xxxb'}
local tmp
local deurl = function(k,v)
	tmp[k:deurl()] = v:deurl()
end
function Net.parseParam(s,out)
	tmp = out or {}
	s:gsub('(%w+)=(%w+)',deurl)
	out = tmp; tmp = nil
	return out
end
--解析xxx.com/api?xx=xx&cc=cc
--为{xx=xx,cc=cc}, 'api', xx=xx&cc=cc
function Net.parseUrl(url)
	local _, _, cf, params  = find(url, '%/([%a%_%/]-%.*[%a%_%/]*)%?(.*)')
	if cf==nil then
		_,_,cf = find(url, '%/(.*)')
		if cf==nil then
			return;
		end
		return nil, cf;
	end
	-- 解析参数
	local ps --paramtable
	if params then
		local _, _, args, _  = find(params, '(.*)%s(.*)')
		if args then
			ps = Net.parseParam(args)
		else
			ps = Net.parseParam(params)
		end
	end
	return ps, cf, params
end

----------------------------------------------------------------
function Net.callout(net)
	if not _callout(net) then
		_callout(net, function(net, rpc, args, data, len)
			--local data,len = _encode(rpc,args)
			net:send(from32l(len))
			net:send(data,len)
		end )
	end
end

function Net.send(net, data, len)
	if not len then len = #data end
	net:send(from32l(len))
	net:send(data, len)
end

function Net.sendText(net, text)
	local s = format("HTTP/1.1 200 OK\r\nContent-Type: text/html;charset=utf-8\r\nConnection: close\r\nContent-Length: %d\r\n\r\n%s",
		#text,text)
	-- sendcount = sendcount + #s
	Net.sendEx(net, s)
end

function Net.sendJson(net, tb)
	local content = toJson(tb)
	local s = format("HTTP/1.1 200 OK\r\nContent-Type: application/json;charset=utf-8\r\nConnection: close\r\nContent-Length: %d\r\n\r\n%s",
		#content, content )
	--sendcount = sendcount + #s
	Net.sendEx(net, s)
end
