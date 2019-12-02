-- gs_npc.lua--TODO:动态创建的NPC.限动态地图
_G.Npc = {}

function Npc.new(id, k)
	-- local createkey = k
	-- local pos = v.pos
	-- local data = {
		-- id = id,
		-- type = 'npc',
		-- currPos = {x=pos.x,y=pos.y,z=pos.z,r=pos.r},
		-- createkey = createkey,
		-- guid = id..'|'..createkey,
	-- }
end

--evevnt
when{} function loadConfigGS()
	dofile'config/cfg_npc.lua'
end
when{} function checkConfigGS()
	for id,v in pairs(cfg_npc) do
		assert(math.abs(id)<=UINT,'cfg_npc id is too big:'..id..'>'.. UINT)

	end
end
when{} function onTalkNpc(role,id,guid,key,menu)
	_zdm('onTalkNpc',role,id,guid,key,menu)
end

for i, v in pairs(Cfg.cfg_npcwelfare{}) do
	when{id=v.npcid}
-- for i, v in pairs({Cfg.cfg_npcwelfare[1]}) do
	-- when{}
	function onTalkNpc(role,id,guid,key,menu)
		local label = v.label
		local todaykey = getDayKeyNum()
		if v.datefrom and v.datefrom > 0 then
			if todaykey<v.datefrom then return end
		end
		if v.dateto and v.dateto > 0 then
			if todaykey>=v.dateto then return end
		end
		local lockkey
		if v.circle == 'daily' then
			lockkey = 'npcwelfare'..id..'_'..todaykey
		elseif v.circle == 'once' then
			lockkey = 'npcwelfare'..id..'_once'
		else
			error(v.circle)
		end
		if role:getDaily( lockkey ) then return end
		if key == 'hello' then
			menu.say = v.label --_T'(今日己领)'
			menu.ask = _T'接受'
			menu.key = _T'get'
		elseif key == 'get' then
			menu.say = _T'祝你好运'
			menu.ask = _T'多谢'
			menu.key =  _T'bye'
			-- GiveItems( role:gp'cpid', v.item, 'npcwelfare' )
			if v.item then
				CallCSByRole( role ).NpcWelfare{ Token = role.getToken(), Key=lockkey, List = v.item, Circle=v.circle, Lab = 'npcwelfare' }
			else
				error('not ready')
			end
		end
	end
end

--PRC
cdefine.c.DoTalk{Id=0, Guid='', Key='hello'}
when{} function DoTalk(Id, Guid, Key)
	local r = GsRole.byNet( _from )
	if not r then return end
	local zone = r:getZone()
	if not zone then return end
	local npc = zone:getNpc(Guid)
	local dynamenu = {}
	if npc then
		dynamenu.talkid = npc.talkid
		dynamenu.movietalk = npc.movietalk
	end
	onTalkNpc{menu=dynamenu, id=Id, guid=Guid, key=Key, role=r}
	if npc then
		if npc.notalk then return end
	end
	if Key == 'bye' then return end
	_from.ShowTalk{ Id=Id, Guid = Guid, Info=dynamenu }
end
