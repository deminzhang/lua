--launch.lua main
print(_VERSION, jit.version, jit.os, jit.arch)
--load main configure 运维配置
dofile(os.info.system=='linux' and 'conf.lua' or 'conf_win.lua')
----------------------------------------------------------------
print0,load0 = print,load or loadstring
loadfile0,dofile0 = loadfile,dofile
if os.info.pack then
	--rewrite if use zipfile
	local fn = os.info.pack
	print('loading local file',fn)
	local file = io.open(fn, 'rb')
	assert(file,'open file fail:'..fn)
	local data = file:read('*a')
	file:close()
	local files = _unzip(data)
	loadfile = function(filename)
		local cont = files[filename]
		assert(cont,'loadfile fail:'..filename)
		cont = cont:tostr()
		--if cont:lead'\239\187\191' then cont = cont:sub( 4, -1 ) end
		local ret, errmsg = loadstring(cont)
		return ret, errmsg
	end
	dofile = function(filename)
		local cont = files[filename]
		assert(cont,'dofile fail:'..filename)
		cont = cont:tostr()
		--if cont:lead'\239\187\191' then cont = cont:sub( 4, -1 ) end
		local ret, errmsg = loadstring(cont)
		assert(ret,errmsg)
		return ret()
	end
	io.readall = function(filename)
		local cont = files[filename]
		return cont
	end
end
----------------------------------------------------------------
--load common
dofile'lib/base.lua'
dofile'lib/math.lua'
dofile'lib/time.lua'
dofile'lib/json.lua'
dofile'lib/table.lua'
dofile'lib/debug.lua'
dofile'lib/string.lua'
dofile'lib/utils.lua'
dofile'lib/event.lua'
dofile'lib/codec.lua'
dofile'lib/protobuf.lua'
dofile'lib/net.lua'
dofile'lib/http.lua'
dofile'common/config.lua'
dofile'common/define.lua'
dofile'common/timer.lua'
dofile'common/logger.lua'
dofile'common/memorydb.lua'
dofile'common/netmgr.lua'
----------------------------------------------------------------
--分载
if not os.info.type then os.info.type = 'cs' end
if not os.info.server_id then os.info.server_id = 0 end
if not os.info.line then os.info.line = 0 end
os.info.server_id = toint(os.info.server_id)
os.info.line = toint(os.info.line)
if os.info.type=='ccs' then
	os.info.server_id = 0
	os.info.line = 0
elseif os.info.type=='cs' then
	assert(os.info.server_id>0 and os.info.server_id<=9999,'cs.server_id must[1,9999]')
	assert(os.info.line==0,'cs.line must 0')
elseif os.info.type=='gs' then
	assert(os.info.server_id>0 and os.info.server_id<=9999,'gs.server_id must[1,9999]')
	assert(os.info.line>0 and os.info.line<=100,'gs.line must[1,100]')
elseif os.info.type=='cgs' then
	os.info.server_id = 0
	assert(os.info.line>100,'cgs.server_id must >100')
else
end
function os.listenAddr(server_id,line)
	local info = os.info
	line = line or 0
	local _,_,host,port = info.listen:find("[%[]*([^%]]*)[%]]*:(%d+)[%@]*([^%@]*)")
	if info.system == 'linux' then
		return info.listen_rule:format(host,info.sname,server_id,line)
	else
		return ('%s:%d'):format(host,port+server_id+line*10)
	end
	return info.listen
end
if os.info.system=='windows' then
	local color = {cs='2e',gs='1e',ccs='3b',cgs='4b'}
	--os.execute('@chcp 65001')
	os.execute('@color '..(color[os.info.type] or '07'))
	os.execute(('@title %sS%dL%d'):format(os.info.type,os.info.server_id,os.info.line))
end
----------------------------------------------------------------
local launchers = {
	gate = 'launch_gate.lua',	--linux.gate
	proxy = 'launch_proxy.lua',	--代理
	login = 'launch_login.lua',	--登陆服
	cs = 'launch_cs.lua',		--中心数据服
	ccs = 'launch_ccs.lua',		--跨服调度中心
	gs = 'launch_gs.lua',		--战斗服
	cgs = 'launch_gs.lua',		--跨服战斗服
	chat = 'launch_chat.lua',	--聊天服
	client = 'launch_client.lua',--仿客户端*或压测用)
	packer = 'launch_packer.lua',--打包器
}
local launcher = launchers[os.info.type]
assert(launcher,'undefined os.info.type='..tostring(os.info.type))
print('>>launch_'..os.info.type, os.id(0))
dofile(launcher)
----------------------------------------------------------------
--common test
if not os.info.pack and os.info.system=='windows' then
	dofile'test.lua'
end