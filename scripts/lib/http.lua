_G.Http = {}
define.onHttp{action='',api='',params={},content='',protocol='HTTP/1.1',header={}}
----------------------------------------------------------------
local HTTP_LOG_ON = true		--日志开关
local HTTP_CONN_TIME = 10	--连接超时s
local HTTP_RECV_TIME = 180	--接收超时s
local HTTP_RECV_LEN = 8192		--按分隔符接受最大长度
local NET_HEAD_LEN = Net.NET_HEAD_LEN
----------------------------------------------------------------
local tostring = tostring
local unpack = table.unpack or unpack
local insert = table.insert
local concat = table.concat
local remove = table.remove
local toJson = table.toJson
local enurl = table.enurl
local deurl = table.deurl
local push = table.push
local find = string.find
local trim = string.trim
local split = string.split
local _listen = _net.listen
local _connect = _net.connect
local _hostips = _net.hostips
----------------------------------------------------------------
--format
function Http.makePost(host, api, args, noencode)
	local qs = { }
	for k, v in next, args do
		if noencode and noencode[k] then
			push(qs, tostring(k):enurl(), '=', tostring(v), '&');
		else
			push(qs, tostring(k):enurl(), '=', tostring(v):enurl(), '&');
		end
	end
	if #qs>1 then
		remove(qs, #qs); --remove last'&'
	end
	local content = concat(qs);
	return concat({'POST ', api, ' HTTP/1.1\r\nHost: ', host, '\r\nContent-Type: application/x-www-form-urlencoded\r\nContent-Length: ', #content, '\r\n\r\n', content});
end
function Http.makeGet(host, api, args, noencode)
	local conttb = {'GET ', api, '?'}
	for k, v in next, args do
		if noencode and noencode[k] then
			push(conttb, tostring(k):enurl(), '=', tostring(v), '&');
		else
			push(conttb, tostring(k):enurl(), '=', tostring(v):enurl(), '&');
		end
	end
	if #conttb>4 then
		remove(conttb, #conttb);
	end
	push(conttb, ' HTTP/1.1\r\nHost: ', host, '\r\n\r\n');
	return concat(conttb)
end
function Http.makeGetByQuery(host, api, qs)
	local conttb = {'GET ', api, '?'}
	insert(conttb, qs);
	push(conttb, ' HTTP/1.1\r\nHost: ', host, '\r\n\r\n');
	return concat(conttb)
end
function Http.makeQuery( net, args, noencode)
	local tb = {}
	local b
	for k, v in next, args do
		b = true
		if noencode and noencode[k] then
			push(tb, tostring(k):enurl(),'=',tostring(v), '&');
		else
			push(tb, tostring(k):enurl(),'=',tostring(v):enurl(),'&')
		end
	end
	if b then
		remove(tb, #tb)
	end
	return concat(tb)
end

----------------------------------------------------------------
----------------------------------------------------------------
--connect.callback
local function onRecvErr(net, msg)
	local callback = net.httperrback
	local callargs = net.httpcallargs
	net:close( 'httperr' )
	-- 先close后callback，避免因为callback 出错导致网络连接未关闭
	if HTTP_LOG_ON then
		print( "httperr", msg, unpack(callargs) ) 
	end
	if callback then
		callback(msg, unpack(callargs))
	end
end
local function onRecvOver(net, content)
	local callback = net.httpcallback
	local callargs = net.httpcallargs
	net:close( 'httpover' )
	-- 先close后callback，避免因为callback 出错导致网络连接未关闭
	-- if HTTP_LOG_ON then
		-- print( "httpback", content, unpack(callargs) )
	-- end
	if callback then
		callback(content, unpack(callargs))
	end
end
----------------------------------------------------------------
--connect.lengthMode
local len_onContent,len_recvContent,len_onBegin,len_onLine,len_onLen
len_onContent = function(net, data)
	onRecvOver(net, data)
end
len_recvContent = function(net)
	if net.httplen<=0 then
		onRecvOver(net, '')
		return
	end
	net:receive(net.httplen, len_onContent, HTTP_RECV_TIME, true)
end
len_onBegin = function(net, data, seperator)
	if seperator == '\r\n\r\n' then
		len_recvContent(net)
	end
end
len_onLine = function(net, data, seperator)
	if seperator == '\r\n' then --body开始了
		len_recvContent(net)
	else
		net:receive('\r\n\r\n', 1024, len_onBegin, HTTP_RECV_TIME, true)
	end
end
len_onLen =  function(net, data, seperator)
	if seperator ~= '\r\n' then
		return
	end
	net.httplen = toint(data)
	net:receive('\r\n', 2, len_onLine, HTTP_RECV_TIME, true)
end
----------------------------------------------------------------
--connect.chunkMode
--[[
HTTP/1.1 200 OK
Server: nginx/1.6.0
Date: Fri, 09 Jun 2017 07:04:50 GMT
Content-Type: application/json; charset=utf-8
Transfer-Encoding: chunked
Connection: keep-alive
Status: 200 OK
X-Frame-Options: SAMEORIGIN
X-XSS-Protection: 1; mode=block
X-Content-Type-Options: nosniff
ETag: "df6e81e37fd74985ae4323f0fc836e0e"
Cache-Control: max-age=0, private, must-revalidate
X-Request-Id: b2ae1ab1-40f3-4c60-8928-f329c1b7261d
X-Runtime: 0.021251

15
{"code":0,"msg":"ok"}
--]]
--1.find Transfer-Encoding: chunked
--2.find \r\n\r\n
--3.find {len} \r\n
--4.find {chunk}
----------------------------------------------------------------
local chunk_onNext,chunk_onContent,chunk_onLen,chunk_onBegin
chunk_onNext =  function(net, data, seperator)
	if seperator ~= '\r\n' then
		onRecvErr(net, 'chunk_onNext seperator error '..seperator)
		return
	end
	net:receive('\r\n', 1024, chunk_onLen, HTTP_RECV_TIME, true)
end
chunk_onContent = function(net, data)
	insert(net.httpcont, data)
	net:receive('\r\n', 2, chunk_onNext, HTTP_RECV_TIME, true)
end
chunk_onLen = function(net, data)
	local len = tonumber('0x'..data)
	if not len then
		onRecvErr(net, 'ChunkMode,receiveLen error. len=0x'..data)
		return
	end
	if len > 0 then--endOfChunk
		net:receive(len, chunk_onContent, HTTP_RECV_TIME, true)
	else
		onRecvOver(net, concat(net.httpcont))
	end
end
chunk_onBegin = function(net, data)
	net.httpcont = {}
	net:receive('\r\n', 1024, chunk_onLen, HTTP_RECV_TIME, true)
end
----------------------------------------------------------------
--connect
local httpnets = {}
local function onHeadHttp(net, data, seperator)
	if seperator == 'Content-Length: ' then
		net:receive('\r\n', 1024, len_onLen, HTTP_RECV_TIME, true)
	elseif seperator == 'Transfer-Encoding: chunked' then
		net:receive('\r\n\r\n', 1024, chunk_onBegin, HTTP_RECV_TIME, true)
	elseif seperator == '\r\n\r\n' then
		net:receive('\r\n', 1024, chunk_onLen, HTTP_RECV_TIME, true)
	else
		onRecvErr(net, "http receive error "..data)
	end
end
local function onConnectHttp(net, ip, port, myip, myport)
	--print('onConnectHttp',net, ip, port, myip, myport)
	httpnets[net] = {ip=ip,port=port,myip=myip,myport=myport}
	local ret = net:send(net.httpsendstr)
	if ret then
		net:close(ret)
		return
	end
	--don't reorder seperators!
	net:receive('Content-Length: ', 'Transfer-Encoding: chunked', '\r\n\r\n',
		1024, onHeadHttp, HTTP_RECV_TIME, true)
end
local function onCloseHttp(net, ...)
	httpnets[net] = nil
	print('onCloseHttp',net.httpaddr,...)
end

function Http.Connect(addr, sendstr, callback, errback, ...)
	local _, _, a, port = find(addr, '([^:]+):(.*)')
	addr = a or addr
	port = port and toint(port) or 80
	local ip = _hostips(addr)
	if not ip then
		error( 'no host:'..addr )
		return
	end
	local net = _connect(addr, port, onConnectHttp, onCloseHttp, HTTP_CONN_TIME)
	net.httpaddr = ip
	net.httpsendstr = sendstr
	net.httpcallback = callback
	net.httperrback = errback
	net.httpcallargs = {...}
	httpnets[net] = true
end

function Http.PostConnect(host, api, args, noencode, callback, errback, ...)
	local s = Http.makePost(host, api, args, noencode)
	Http.Connect(host, s, callback, errback, ...)
end

function Http.GetConnect(host, api, args, noencode, callback, errback, ...)
	local s = Http.makeGet(host, api, args, noencode)
	Http.Connect(host, s, callback, errback, ...)
end

function Http.GetByUrl(url, callback, errback, callargs)
	local _, _, addr, api, qs = find(url, "http://(.-)/(.*)?(.*)")
	print('addr:' .. addr .. '    api:' .. api .. '     qs:' .. qs)
	if not addr then
		if errback then
			errback("url format error:"..url, unpack(callargs or {}))
		else
			print("url format error:"..url, unpack(callargs or {}))
		end
		return
	end
	local _, _, host, port = find(addr, '([^:]+):(.*)')
	addr = host or addr
	port = port or 80
	Http.Connect(addr, Http.makeGetByQuery(addr..':'..port, "/"..api, qs), callback, errback, callargs)
end

----------------------------------------------------------------
local function checkDomain(domain)
	return string.match(domain, "^[%w%-%_%.]+[%w%-%_]+$" )
end
local function onHttpDomain(net, data, seperator)
	if seperator == '\r\n' then
		local datas = net.gatehttp
		push(datas, data)
		local _, _,  domain = find(data, "(.*):")
		domain = domain or data
		if checkDomain(domain) then
			print('sharetodomain', data)
			net:share(domain:lower(), concat(datas))
			net:close('http share to'.. domain)
		else
			net:close('http domain error:'..domain)
		end
	else
		net:close('http lack of the domain')
	end
end
local function onHttpHost(net, data, seperator)
	if seperator == 'Host: ' then
		push(net.gatehttp, data, seperator)
		net:receive('\r\n', HTTP_RECV_LEN, onHttpDomain, HTTP_RECV_TIME, true)
	else
		net:close('error http lack of the host')
	end
end
local function onHttpHeadGate(net,data)
	net.gatehttp = {data:tostr()}
	net:receive('Host: ',HTTP_RECV_LEN, onHttpHost, HTTP_RECV_TIME, true)
end
----------------------------------------------------------------
--listen.GET
--[[
GET /abc?a=1&b=2 HTTP/1.1
Host: localhost:9000
User-Agent: Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:61.0) Gecko/20100101 Firefox/61.0
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2
Accept-Encoding: gzip, deflate
Connection: keep-alive
Upgrade-Insecure-Requests: 1

--]]
local onGetLine
function onGetLine(net,data,seperator)
	local http = net.http
	local s = data --:tostr()
	if s=='\r\n' then
		Http.onData(net,http)
		if http.header["Connection"] ~= "close" then
			net:receive(NET_HEAD_LEN, Net.onHead, NET_RECV0_TIMEOUT )
		else
			net:close('httpGetOver')
		end
	else
		local _,_,k,v = find(s, '([%a%_%/%-]-%.*[%a%_%/%-]*)%:% (.*)')
		http.header[trim(k)] = trim(v)
		net:receive('\r\n', HTTP_RECV_LEN, onGetLine, HTTP_RECV_TIME,true)
	end
end
local function onGetDomain(net,data)
	local s = data --:tostr() --"/abc?a=1&b=2 HTTP/1.1"
	local _,_,api,args,protocol = find(s,'%/([%a%_%/]-%.*[%a%_%/]*)%?(.+)%s(.+)')
	if not api then
		net:close('empty api:'..s)
		return
	end
	local http = net.http
	http.api = api
	http.content = args
	http.protocol = protocol
	http.params = Net.parseParam(args)
	net:receive( '\r\n', HTTP_RECV_LEN, onGetLine, HTTP_RECV_TIME,true)
end
function Http.onHttpGet(net,data)
	if os.info.type=='gate' then
		onHttpHeadGate(net,data)
		return
	end
	net.http = { action = 'GET', header = {}}
	net:receive( '\r\n', HTTP_RECV_LEN, onGetDomain, HTTP_RECV_TIME,true)
end
----------------------------------------------------------------
--listen.POST
--[[
POST /api/ss HTTP/1.1
Host: localhost
Content-Type: application/x-www-form-urlencoded
Content-Length: 11

cc=cc&xx=xx
--]]
local onPostLine
local function onContent(net,content)
	local http = net.http
	http.content = content
	http.params = Net.parseParam(content)
	Http.onData(net,http)
	if http.header["Connection"] ~= "close" then
		net:receive(NET_HEAD_LEN, Net.onHead, NET_RECV0_TIMEOUT )
	else
		net:close('httpPostOver')
	end
end
function onPostLine(net,data,seperator)
	local http = net.http
	local s = data--:tostr()
	if s=='\r\n' then
		local len = tonumber(http.header['Content-Length'])
		if len>0 then
			net:receive(len, onContent, HTTP_RECV_TIME, true)
		else
			if http.header["Connection"] ~= "close" then
				net:receive(NET_HEAD_LEN, Net.onHead, NET_RECV0_TIMEOUT)
			else
				net:close('httpOver')
			end
		end
	else
		local _,_,k,v = find(s, '([%a%_%/%-]-%.*[%a%_%/%-]*)%:% (.*)')
		http.header[trim(k)] = trim(v)
		net:receive('\r\n', HTTP_RECV_LEN, onPostLine, HTTP_RECV_TIME,true)
	end
end
local function onPostDomain(net,data)
	local s = data--:tostr() --" /api/ss HTTP/1.1"
	local _,_,api,protocol = find(s,'%/([%a%_%/]-%.*[%a%_%/]*)%s(.*)')
	if not api then
		net:close('empty api '..s)
		return
	end
	local http = net.http
	http.api = api
	http.protocol = protocol
	net:receive( '\r\n', HTTP_RECV_LEN, onPostLine, HTTP_RECV_TIME,true)
end
function Http.onHttpPost(net,data)
	if os.info.type=='gate' then
		onHttpHeadGate(net,data)
		return
	end
	net.http = { action = 'POST', header = {}}
	net:receive( '\r\n', HTTP_RECV_LEN, onPostDomain, HTTP_RECV_TIME,true)
end
--listen.callback
function Http.onData(net,data)
	-- print('Http.onData',net)
	-- dump(data)
	if onHttp then
		-- onHttp{ _delay=0, 
			-- action = data.action, 
			-- api = data.api, 
			-- params = data.params, 
			-- content = data.content, 
			-- protocol = data.protocol, 
			-- header = header,
		-- }
		data._delay=0
		onHttp(data)
	else
		Net.sendJson(net, {ret = 0, msg = 'no onHttp.testOK' })
	end
end
when{}
function onHttp(action,api,params,content,protocol,header)
	print('onHttp',action,api,params,content)
end
----------------------------------------------------------------
--http from share
local function onPostParam( net, data )
	local http = net.http
	local content = data--:tostr( )
	http.params = Net.qstring2table( content )
	http.content = content
	net.http = nil
	Http.onData( net, http )
end
local onSharedHead
function onSharedHead( net, data, seperator )
	if seperator == '\r\n\r\n' then
		local http = net.http
		local heads = split(data, "\r\n")
		local header = http.header
		for i = 1, #heads do
			local _,_,k,v = find(heads[i], '([%a%_%/%-]-%.*[%a%_%/%-]*)%:% (.*)')
			if not k or not v then
				net:close('wrong http header format when receive \\r\\n\\r\\n') 
				return 
			end
			header[trim(k)] = trim(v)
		end
		if http.action == 'GET' then
			Http.onData(net, http)
		else
			assert(http.action == 'POST')
			local len = header["Content-Length"]
			if not len then
				net:close( 'wrong post http format, content-lenght expected' )
				return
			end
			len = toint( len )
			if not len then
				net:close( 'wrong post http format, content-lenght must be uint' )
				return
			end
			net:receive(len, onPostParam, HTTP_RECV_TIME,true)
		end
	elseif seperator == '\r\n' then
		local _,_,k,v = find(data, '([%a%_%/%-]-%.*[%a%_%/%-]*)%:% (.*)')
		if not k or not v then
			net:close('wrong http header format')
			return
		end
		local header = http.header
		header[trim(k)] = trim(v)
		net:receive('\r\n\r\n','\r\n',HTTP_RECV_LEN,onSharedHead,HTTP_RECV_TIME)
	else
		net:close('wrong http format, can not get http header')
	end
end
function Http.onDataShared(net,data)
	local lines = data:split('\r\n')
	local line1 = lines[1]:split" "
	if #line1 ~= 3 then
		print(data)
		net:close('wrong http url format') 
		return
	end
	local action = trim(line1[1])
	if action ~= 'GET' and action ~= 'POST' then
		print(data)
		net:close('wrong http unsupped action:'..action)
		return
	end
	local params, interface, content = Net.parseUrl(line1[2])
	local header = {}
	for i = 2, #lines do
		local s = lines[i]
		if s ~= '' then
			local _,_,k,v = find(s, '([%a%_%/%-]-%.*[%a%_%/%-]*)%:% (.*)')
			if not k or not v then
				net:close('wrong http header format:'..s)
				return 
			end
			header[trim(k)] = header[trim(v)]
		end
	end
	net.http = {
		action = action,
		api = interface, 
		protocol = trim(line1[3]), 
		params = params or {}, 
		header = header,
		content = content,
	}
	net:receive('\r\n\r\n','\r\n',HTTP_RECV_LEN,onSharedHead,HTTP_RECV_TIME,true)
end
----------------------------------------------------------------
--sample/test
--[[
--'localhost:9000/api/ss?x1=x1&c2=c2'
Http.PostConnect('localhost:9000', '/api/ss', {x1='x1',c2='c2'}, {}, function(content,...)
	print('OK_______',...)
	dump(content)
end, function(...)
	print('Fail_______')
	dump({...})
end)
--]]