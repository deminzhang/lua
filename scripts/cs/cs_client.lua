--cs_client
_G.Client = {}
----------------------------------------------------------------
--to local
local os = os
local assert = assert
local debug = debug
local dump = dump
local pairs = pairs
local print = print
local tostring = tostring
----------------------------------------------------------------
--local var
local clientnum = 0
local clients = { } -- { [client]=true,... }
local net2client = table.weakv() -- { net=client }
local uid2client = table.weakv() -- { uid=client }
local pid2client = table.weakv() -- { pid=client }
local token2client = table.weakv() -- { token=client }
local name2client = table.weakv() -- { name=client }

----------------------------------------------------------------
--local function
--TODO
local function setNet(c, net)
end
local function getNet(c, net)
end
local function newClient()
	-- m_net,
	-- m_uid,
	-- m_pid,
	-- m_ssid,	--原服
	-- m_name,
	-- m_token,
	-- m_serverid = 0, --当前服
	-- m_gs = nil,
	-- m_line = nil,
	-- m_instanceZone = nil,
	-- m_cleartime,
	-- m_cleartrace,
	local c = {
		
		setNet = setNet,
		getNet = getNet,
		setUID = setUID,
		getUID = getUID,
		setSID = setSID,
		getSID = getSID,
		setPID = setPID,
		getPID = getPID,
		setToken = setToken,
		getToken = getToken,
	}
	return c
end

local function newClient()
	local m_net, m_uid, m_pid
	local m_ssid	--原服
	local m_name, m_token
	local m_serverid = 0 --当前服
	local m_gs = nil
	local m_line = nil
	local m_instanceZone = nil
	local m_cleartime, m_cleartrace
	local c
	c = {
		logintime = 0,
		setNet = function( val )
			print('setNet',c,val)
			if net2client[m_net] then
				net2client[m_net] = nil
			end
			m_net = val
			if m_net then
				net2client[m_net] = c
				c.setClearTime(nil) --noClear
			else --clearDelay
				c.setClearTime(os.time()+CONFIG.DISCONNECT_KICK_DELAY)
			end
		end,
		getNet = function() return m_net end,

		setUID = function( val )
			m_uid = val
			if val then uid2client[val] = c end
		end,
		getUID = function() return m_uid end,

		setSID = function( val ) m_ssid = val end, --所属服
		getSID = function() return m_ssid end,

		setPID = function( val )
			m_pid = val
			if val then pid2client[val] = c end
		end,
		getPID = function() return m_pid end,

		setName = function( val )
			m_name = val
			if m_net then m_net.__netinfo = val end
			if val then name2client[val] = c end
		end,
		getName = function()  return m_name end,
		
		setToken = function( val )
			m_token = val
			if val then token2client[val] = c end
		end,
		getToken = function() return m_token end,

		setGS = function( val, gstoken )
			if m_gs then m_gs.players[m_pid]=nil end
			if val then val.players[m_pid]=true end
			m_gs = val
			c.setgstraceback = tostring(val) .. '|' .. debug.traceback()
		end,
		getGS = function() return m_gs end,

		setServerID = function( val ) m_serverid = val end,
		getServerID = function() return m_serverid end,

		setLine = function( val )
			-- if m_line then GServer.linesub( m_line ) end
			-- if val then GServer.lineadd( val ) end
			m_line = val
		end,
		getLine = function() return m_line end,

		setGameIns = function( val )
			m_instanceZone = val
			--if not val then
				--Log.sys( 'SETGAMEINS_NIL', debug.traceback() )
			--end
		end,
		getGameIns = function() return m_instanceZone end,

		setClearTime = function( val )
			m_cleartime = val
			m_cleartrace = debug.traceback()
		end,
		getClearTime = function() return m_cleartime, m_cleartrace end,

		
	}
	return c
end
----------------------------------------------------------------
function Client.all() return clients end

function Client.allPID() return pid2client end
--用clinet的net找
function Client.byNet( net ) return net2client[net] end
--用帐号找 account.uid
function Client.byUID( uid ) return uid2client[uid] end
--用角色id找 player.pid
function Client.byPID( pid ) return pid2client[pid] end
--用token找 来自GS的PRC用
function Client.byToken(token) return token2client[token] end
--用角色名找 player.name
function Client.byName( name ) return name2client[name] end

function Client.add(uid, sid)
	assert(not Client.byUID(uid), 'duplicate Client.add')
	print('Client.add', uid, sid)
	local c = newClient()
	c.setUID( uid )
	c.setSID( sid )
	c.logintime = os.time()
	
	clients[c] = true
	clientnum = clientnum + 1
	return c
end

function Client.del(c, Reason)
	print('Client.del', c, Reason)
	onClearClient{client=c}
	local net = c.getNet()
	if net then
		net2client[net] = nil
		net:close(Reason)
	end
	local uid = c.getUID()
	if uid then uid2client[uid] = nil end
	local pid = c.getPID()
	if pid then pid2client[pid] = nil end
	local token = c.getToken()
	local gs = c.getGS()
	if token then
		token2client[token]=nil
		if gs and gs.net then
			gs.net.DelToken{ Token = token, Reason=Reason or 'no' }
		end
	end
	local name = c.getName()
	if name then name2client[name] = nil end
		
	c.setLine(nil)
	c.setGS(nil)
	
	clients[c] = nil
	clientnum = clientnum - 1
end

function Client.count()
	return clientnum
end

function Client.PidByNet(net)
	local c = Client.byNet(net)
	return c and c.getPID()
end

----------------------------------------------------------------
--event
define.onClearClient{ client = { } }
function event.onClearClient( client )
	-- local c = client
	-- CallGs( c.getGS() ).DelToken{ Token = c.getToken(), Reason='clearClient' }
	-- Log.sys( 'clear-client', client.getUID(), client.getPID() or 'nil', client.getToken() or 'nil' )

	-- local level
	-- if c.getPID() then
		-- level = Role.getLevel( c.getPID() )
	-- else level = 0 end

	-- local olsec = c.getPID() and Role.getOnlineSec( c.getPID() ) or 0
	-- CYLog.log( 'logout', { level = level or 0, ip = '0.0.0.0', group = '', onlinetime = olsec or 0 }, c )
end

function event.onSecond()
	--己断开的CONFIG.DISCONNECT_KICK_DELAY后下线
	local now = os.time()
	for c,_ in pairs(clients) do
		local t, err = c.getClearTime()
		if t and t < now then
			Client.del(c, 'disconnect')
		end
	end
end

----------------------------------------------------------------
--RPC.fromGS
define.TickReport{Token='',Data={}}
when{} function TickReport(Token,Data)
	print('>>TickReport',Token)
	dump(Data)
end

