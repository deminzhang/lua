
local unpack = table.unpack or unpack
_G.AI_model = {}
_G.AI_medit = {} --编辑器用
local tryAndDoAction = function(self)
	if not self.action then return end
	local entity = Entity.byGUID(self.enityguid)
	if not entity then return end
	if self.mutex then	--mutex互斥huchi
		assert(self.rates,self.id..'mutex AI must have rates')
		local r = math.random(100)
		for i,act in ipairs(self.action) do
			assert(self.rates[i], self.id..'mutex AI must have rates')
			if r<=self.rates[i] then
				AI_action[act.k]( entity, unpack(act) )
				return
			end
		end
	else
		for i,act in ipairs(self.action) do
			if not self.rates or not self.rates[i] or math.random(100)<=self.rates[i] then
				AI_action[act.k]( entity, unpack(act) )
			end
		end
	end
end

AI_medit.onBorn = { name = '出生'}
AI_model.onBorn = {--name = '出生AI',
	onBorn = function(self)
		if self.action[1][1] == 'talk' then
			if math.random(3)==1 then tryAndDoAction(self) end
		else
			tryAndDoAction(self)
		end
	end,
}
AI_medit.onDie = { name = '死亡'}
AI_model.onDie = {--name = '死亡AI',
	onDie = function(self)
		tryAndDoAction(self)
	end,
}
AI_medit.onCombat = { name = '入战'}
AI_model.onCombat = {--name = '入战',
	onCombat = function(self)
		tryAndDoAction(self)
	end,
}
AI_medit.onImcombat = { name = '脱战'}
AI_model.onImcombat = {--name = '脱战',
	onImcombat  = function(self)
		tryAndDoAction(self)
	end,
}
AI_medit.onTick = { name = '计时', p={{'间隔ms', 10000},{'最大间隔ms', 10000},{'延迟ms', 0},{'次数', 1}}}
AI_model.onTick = { --name = '计时',
	--p1:心跳间隔
	--p2:最大间隔
	--p3:延迟心跳
	--p4:触发次数(满次自动删除此AI)
	update = function(self,e,currtime)
		currtime = currtime or os.now()
		local interval = self.event[2]
		if interval > 0 then
			if currtime - self.lastTick >= interval then
				self:onTick()
				if self.event[3] and self.event[3] > self.event[2] then
					self.lastTick = self.lastTick + math.random(interval, self.event[3])
				else
					self.lastTick = self.lastTick + interval
				end
			end
		end
		if self.duration>0 and currtime-self.startTime > self.duration then
			self:release()
		end
	end,
	onActive = function(self)
		if self.event[4] and self.event[4] > 0 then
			self.lastTick = self.startTime + self.event[4]
		else
			self.lastTick = self.startTime
		end
	end,
	onTick  = function(self)
		tryAndDoAction(self)
		if self.event[5] then
			self.data.times = self.data.times or 0
			self.data.times = self.data.times + 1
			if self.data.times >= self.event[5] then
				self:release()
			end
		end
	end,
	onImcombat  = function(self)
		self:release()
	end,
}

AI_medit.onActive = { name = 'AI被加上时'}
AI_model.onActive = { --name = 'AI被加上时',
	onActive = function(self)
		tryAndDoAction(self)
	end,
}

AI_medit.onDeacitve = { name = '此AI删除时'}
AI_model.onDeacitve = { --name = '此AI删除时',
	onDeacitve = function(self)
		tryAndDoAction(self)
	end,
}

AI_medit.onSeeEnemy = { name = '敌方进入视野时'}
AI_model.onSeeEnemy = { --name = '敌方进入视野时',
	onSeeEnemy = function(self,entity,target)
		tryAndDoAction(self)
	end,
}
AI_medit.onIdle = { name = '返营点'}
AI_model.onIdle = { --name = '返回savePos',
	onIdle = function(self)
		tryAndDoAction(self)
	end,
}
AI_medit.onHpXLow = { name = '生命百分比', p={{'低于', 0},{'回血重置次数', 0}}}
AI_model.onHpXLow = { --name = '生命百分比低于', --p1:百分比值 --p2:回血重置次数
	onHpModify = function(self,val,hp,maxHp)
		self.data.times = self.data.times or 0
		if self.event[3] and self.event[3]>0 and self.data.times >= self.event[3] then return end
		if not self.data.flag then
			if hp/maxHp < self.event[2]/100 then
				self.data.flag = true
				self.data.times = self.data.times + 1
				tryAndDoAction(self)
			end
		else
			if not self.event[3] or self.event[3]<=0 then
				if hp/maxHp >= self.event[2]/100 then
					self.data.flag = false
				end
			end
		end
	end,
	onImcombat  = function(self)
		self.data = {}
	end,
}
AI_medit.onHpLow = { name = '生命值', p={{'低于', 0},{'回血重置次数', 0}}}
AI_model.onHpLow = { --name = '生命值低于', --p1:值 --p2:回血重置次数
	onHpModify = function(self,val,hp)
		self.data.times = self.data.times or 0
		if self.event[3] and self.data.times >= self.event[3] then return end
		if not self.data.flag then
			if hp < self.event[2] then
				tryAndDoAction(self)
				self.data.flag = true
				self.data.times = self.data.times + 1
			end
		else
			if not self.event[3] or self.event[3]<=0 then
				if hp >= self.event[2] then
					self.data.flag = false
				end
			end
		end
	end,
	onImcombat  = function(self)
		self.data = {}
	end,
}

do return end------------------------------以下重调

AI_model.onGetHit = {
	--name = '受到攻击几率触发',
	--p1:几率
	onGetHit = function(self,entity,target,skillid)
		if math.random(100) <= self.event[2] then
			tryAndDoAction(self)
		end
	end,
}
AI_model.onHitBySkill = {
	--name = '受到指定技能攻击',
	--p1:技能ID
	--p2:几率
	onGetHit = function(self,entity,target,skillid)
		if skillid == self.event[2] then
			if self.event[3] and not math.random(100) <= self.event[3] then return end
			tryAndDoAction(self)
		end
	end,
}
AI_model.onSeePlayer = {
	--name = '单位进入视野',
	onEnterObject = function(self,entity,target)
		if target.type=='player' then
			tryAndDoAction(self)
		end
	end,
}
AI_model.onSeeFriend = {
	--name = '友方进入视野',
	onEnterObject = function(self,entity,target)
		if CampManage.campRelation( entity, target ) == 'friend' then
			tryAndDoAction(self)
		end
	end,
}
AI_model.onReach = {
	--name = '到达寻路尾点时',
	--p1:pathID
	onReach = function(self,pathID)
		if self.event[2] then
			if self.event[2]~=pathID then return end
			tryAndDoAction(self)
		else
			tryAndDoAction(self)
		end
	end,
}
AI_model.onBeTalk = {
	--name = '被对话',
	onBeTalk = function(self)
		tryAndDoAction(self)
	end,
}
AI_model.onListen = {
	--name = '',
	--p1:wordid
	onListen = function(self,wordid)
		if self.event[2] ~= wordid then return end
		tryAndDoAction(self)
	end,
}
AI_model.onReborn = {
	--重生AI
	onReborn = function(self)
		tryAndDoAction(self)
	end,
}
AI_model.onNearDie = {
	--濒死AI
	onNearDie = function(self)
		tryAndDoAction(self)
	end,
}
AI_model.onMateDie = {
	onMateDie = function(self,entity,mate)
		tryAndDoAction(self)
	end,
}
AI_model.onHpCampare = {
	--p1:自己低于
	--p2:队友高于
	onHpModify = function(self,entity)
		if self.data.flag then return end
		local mateguid
		for guid,_ in pairs(entity.mates) do
			mateguid = guid
			break
		end
		if not mateguid then return end
		local mate = Entity.byGUID(mateguid)
		if not mate then return end
		if entity.hp >= self.event[2] then return end
		if mate.hp <= self.event[3] then return end
		tryAndDoAction(self)
		self.data.flag = true
	end,
	onImcombat  = function(self)
		self.data = {}
	end,
}
AI_model.onHpXCampare = {
	--p1:自己低于%
	--p2:队友高于%
	onHpModify = function(self,entity)
		if self.data.flag then return end
		local mateguid
		for guid,_ in pairs(entity.mates) do
			mateguid = guid
			break
		end
		if not mateguid then return end
		local mate = Entity.byGUID(mateguid)
		if not mate then return end
		if entity.hp/entity.maxHp >= self.event[2]/100 then return end
		if mate.hp/mate.maxHp <= self.event[3]/100 then return end
		tryAndDoAction(self)
		self.data.flag = true
	end,
	onImcombat  = function(self)
		self.data = {}
	end,
}
AI_model.onHpDiffer = {
	--p1:差值大于
	onHpModify = function(self,entity)
		if self.data.flag then return end
		local mateguid
		for guid,_ in pairs(entity.mates) do
			mateguid = guid
			break
		end
		if not mateguid then return end
		local mate = Entity.byGUID(mateguid)
		if not mate then return end
		if mate.hp - entity.hp <= self.event[2] then return end
		tryAndDoAction(self)
		self.data.flag = true
	end,
	onImcombat  = function(self)
		self.data = {}
	end,
}

--可直接 addAI( key,time )
AI_model.onMemHit = {
	--name = '掉血时',

	onHpModify = function(self,entity,source)
		if not source then return end
		if source.type=='pet' then source = Entity.byGUID(source:gp'hostguid') or source end
		if source.type ~= 'player' then return end
		local gl = source.guildname
		if not gl then return end
		if gl == '' then return end
		self.data[gl] = ( self.data[gl] or 0 ) + 1
	end,

	onDie = function(self,entity)
		entity.noReborn = true --不走正常重刷流程
		local bestguild = ''
		local bestvalue = 0
		for k, v in pairs( self.data ) do
			if v >= bestvalue then bestguild = k bestvalue = v end end
		GuildZone.createFlag( entity:getZone(), bestguild )
		GuildZone.guildFlagDie( entity:getZone().id, bestguild )
	end,
}

