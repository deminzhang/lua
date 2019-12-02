--=============AI 动作======================
_G.AI_action = {}
_G.AI_a_edit = {} --编辑器用

AI_a_edit.addai = {k='增加AI', {'id'} , {'duration'} }
function AI_action.addai(mon, id, duration)--增加AI
	mon:addAI(id, duration)
end
AI_a_edit.delai = {k='删除AI', {'id'} }
function AI_action.delai(mon, id)	--删除AI
	mon:delAI(id)
end

function AI_action.cskill(mon)	--清空技能队列
	mon:clearSkillQueue()
end
AI_a_edit.skill = {k='准备技能', {'id', 0}, {'最前',false}, {'可重复',false} }
function AI_action.skill(mon, skillid, front, duplicate, param)--增加技能到队列
	assert(cfg_skill[skillid],'mon:'..(mon.id or 'nil')..'invalid skill:'..skillid)
	if not duplicate then
		for i, sk in ipairs(mon.skillQueue) do
			if sk.id==skillid then return end
		end
	end
	if front then
		table.insert( mon.skillQueue,1, {id=skillid, param=param} )
	else
		mon.skillQueue[#mon.skillQueue+1] = {id=skillid, param=param}
	end
end

function AI_action.skillr(mon,skills,front, duplicate)--增加随机技能到队列
	AI_action.skill(mon, skills[math.random(#skills)], front, duplicate)
end

function AI_action.skills(mon,skills)--增加多个技能到队列
	for _,skillid in ipairs(skills) do
		AI_action.skill(mon, skillid)
	end
end

function AI_action.trap(mon,id,pos,data)--创建 Trap
	mon:getZone():createTrap( id, pos, data )
end

function AI_action.delTrap(mon,guid)--删除 Trap
	local e = Trap.get(guid)
	if e then
		e:delete()
	end
end

function AI_action.moveType(mon,mvtype)--设置攻击移动
	mon:setMoveType(mvtype)
end

function AI_action.atcType(mon,atktype)--设置攻击模式
	mon:setAttackType(atktype)
end
AI_a_edit.setActive = {k='设激活', {'active', true}, {'过程时间', nil}}
function AI_action.setActive(mon,active,pause)--设置激活
	mon:setProp( 'active', active )
	mon:pause(pause or 1000)
end
--召唤
AI_a_edit.sum = {k='召唤', {'id',}, {'数量',}}
AI_action.sum = function(mon, id, num, default )--, dieOnHostDie, lr, fb)
	mon:summon(id, num, default )--, dieOnHostDie, lr, fb )
end

AI_action.npc = function(mon, npcid, talkid, default )
	local pos = mon:gp'currPos'
	local npc = mon:getZone():createNpc( npcid, {x=pos.x, y=pos.y, z=pos.z, r=pos.r}, default )
	npc.talkid = talkid
end
--设置巡路
AI_action.setpath = function(mon, pathid )
	mon:stop()
	mon.aipath = pathid
end


do return end------------------------------以下重调-----------------------------


--呼叫
AI_action.call = function(mon,...)
	mon:call(...)
end
--清除所有AI
AI_action.cAi = function(mon,p1,p2,p3,p4,p5,p6,p7)
	mon:clearAi()
end
--暂停
AI_action.stand = function(mon,p1,p2,p3,p4,p5,p6,p7)
	mon:stand(p1)
end
--设置距敌距离
AI_action.keepDis = function(mon,p1,p2,p3,p4,p5,p6,p7)
	if not p1 or p1<4 then p1=4 end
	mon:setKeepDis(p1)
end
--逃跑一定时间
AI_action.escape = function(mon,p1,p2,p3,p4,p5,p6,p7)
	mon:escape( p1 )
end
--跑向
AI_action.run = function(mon,p1,p2,p3,p4,p5,p6,p7)
	mon:runTo{x=p1, y=p2}
end
--创建怪物
AI_action.monster = function(mon,p1,p2,p3,p4,p5,p6,p7)
	--p1,p2,p3,p4,p5:怪id,坐标x,坐标y,怪物数量,继承hp百分比
	if p4 and p4>1 then
		local Nodes = {
		{-7,-7},{-8,-3},{-8,3},{-7,7},
		{-3,-8},{-8,-3},{-8,3},{-3,8},
		{ 3,-8},{-8,-3},{-8,3},{ 3,8},
		{ 7,-7},{ 8,-3},{ 8,3},{ 7,7}}
		while p4>0 do
			p4 = p4-1
			if #Nodes==0 then
				mon:getZone():newMonster( p1,{x=p2,y=p3} )
			else
				local node = math.random(#Nodes)
				mon:getZone():newMonster( p1,{x=p2+Nodes[node][1],y=p3+Nodes[node][2]} )
				table.remove(Nodes,node)
			end
		end
	else
		mon:getZone():newMonster( p1,{x=p2,y=p3} )
	end
end
--消失
AI_action.disappear = function(mon,p1,p2,p3,p4,p5,p6,p7)
	mon:release()
end
--公告
AI_action.announce = function(mon,p1,p2,p3,p4,p5,p6,p7)
	local p2 = p2 or 0
	if p2 == 0 then
		for guid,_ in pairs(mon:getZone().players) do--
			Entity.byGUID(guid).Msg{K='announce2',T={msg=p1 or ''}}
		end
	elseif p2 == 1 then
		for i,p in pairs(World.entitys) do--
			if p.type=='player' then
				p.Msg{K='announce2',T={msg=p1 or ''}}
			end
		end
	elseif p2 == 2 then
		--_G.GS.getCS( ).WorldAnnounce{ T={msg=p1}, Type='announce2' }
	end
end
--下跳消息
AI_action.noticeArt = function(mon,p1,p2,p3,p4,p5,p6,p7)
	mon:getZone():noticeArt(p1,p2)
end
--消息
AI_action.notice = function(mon,p1,p2,p3,p4,p5,p6,p7)
	mon:getZone():notice(p1,p2)
end
--开门
AI_action.openDoor = function(mon,p1,p2,p3,p4,p5,p6,p7)
	--if p1<101 or p1>999 then error('AI魔法门编号超限'..p1) end
	mon:getZone():openDoor(p1)
end
--关门
AI_action.closeDoor = function(mon,p1,p2,p3,p4,p5,p6,p7)
	if p1<101 or p1>999 then error('AI魔法门编号超限'..p1) end
	mon:getZone():closeDoor(p1)
end
--说话
AI_action.talk = function(mon,p1,p2,p3,p4,p5,p6,p7)
	-- p1:word  p2:bubble p3:channel p4:loop p5:random
	if not p1 then error ("no word!") end
	local wordid = p1
	local bubble = p2
	local channel = p3 or CHAT_CHANNEL.ZONE
	local loop = p4
	local delay = p5 or 0
	local random = p6
	mon:speak ( wordid, bubble, channel, loop, random )
	local entities,counts = entityInSights(mon.sights)
	if delay<=0 then
		for guid,e in pairs(entities) do
			if e.type=='npc' or e.type=='monster' then
				e:onListen(wordid)
			end
		end
		return
	end
	local func = function()
		for guid,e in pairs(entities) do
			if e.type=='npc' or e.type=='monster' then
				e:onListen(wordid)
			end
		end
	end
	mon:getZone():addTimer ( delay, func )
end
--聊天频道
AI_action.chat = function(mon,p1,p2,p3,p4,p5,p6,p7)
	-- p1:word  p2:channel
	local p2 = p2 or 1
	for guid,_ in pairs(mon:getZone().players) do
		Entity.byGUID(guid).GetNotice{ Channel = 1, Info = p1 }
	end
end
--单位特效
AI_action.effect = function(mon,p1,p2,p3,p4,p5,p6,p7)
	mon:showEffect(p1)
end
--变身
AI_action.transform = function(mon,p1,p2,p3,p4,p5,p6,p7)
	mon:transform(p1)
end
--创建 矿/宝箱
AI_action.mine = function(mon,mineId,x,y)
	local pl = {{1,-1},{0,1},{1,1},
				{0,-1},		  {1,0},
				{-1,-1},{0,-1},{1,-1}}
	local p = pl[math.random(8)]
	local pos
	if x and y then
		pos = {x=x,y=y}
	else
		local currPos = mon:gp'currPos'
		pos = {x=currPos.x+6*p[1], y=currPos.y+6*p[2]}
	end
	mon.mineguid = mon:getZone():newMine( mineId,pos ):gp'guid'
end
--直接暴落
AI_action.dropitem = function(mon,itemid,min,max)
	local item = Item.CreateXXX(itemid, math.random(min,max or min))
	local pos = mon:gp'currPos'
	Item.CreateSceneItem(item,mon:getZone(), pos, pos,{},0)
end
--设置重生
AI_action.setReborn = function(mon,delay,hpPercent,times)
	mon:setReborn(delay,hpPercent,times)
end
--回恢百分血
AI_action.setHpPer = function(mon,hpPercent)
	mon:modifyHp( mon:gp'guid', AttrSys.get( mon, 'maxHp' )*hpPercent)
end
--复制怪物属性
AI_action.setAttr = function(mon,monid)
	local sm = cfg_mon[monid]
	assert(sm,'AI_action setAttr use invalid monsterid'..monid)
	local mm = cfg_mon[mon.id]
	local currhp = mon.hp
	local atrb={}
	for k,v in pairs(cfg_attr) do--..'X'
		if sm[k] then
			atrb[k] = sm[k]
			atrb[k..'X'] = sm[k..'X']
		end
		if mm[k] then
			atrb[k] = atrb[k]-mm[k]
			if atrb[k..'X'] then
				atrb[k..'X'] = atrb[k..'X']-mm[k..'X']
			end
		end
	end
	AttrSys.add( mon, {atrb} )
	if AttrSys.get( mon, 'maxHp' )<currhp then
		mon:modifyHp( mon:gp'guid', currhp-mon.maxHp )
	end
	local attr = { }
	attr.maxHp = AttrSys.get( mon, 'maxHp' )
	attr.level = mon.level
	mon:synBroadAttris( attr )
end
--增加一个BUFF
AI_action.addBuff = function(mon,buffid)
	SkillManage.switchBuffPro( mon, buffid, true )
end
--删除一个BUFF
AI_action.delBuff = function(mon,buffid)
	SkillManage.switchBuffPro( mon, buffid, false )
end
--复活同生怪
AI_action.rebornmate = function(mon)
	for guid,_ in pairs(mon.mates) do
		local p = Entity.byGUID(guid)
		if p and p.hp<1 then
			p:reborn()
			break
		end
	end
end
--更换阵营
AI_action.changeCamp = function(mon,camp)
	mon:changeTmpCamp(camp)
end
--设置副本进度
AI_action.setDunPro = function(mon,pro)
	mon:getZone():setProcess(pro)
end
--显示进度为pro/max
AI_action.showProcess = function(mon,pro)
	mon:getZone():showProcess(pro)
end
--设置副本完成
AI_action.setDunDone = function(mon)
	mon:getZone():setDone()
end



