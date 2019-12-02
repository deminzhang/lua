--Item道具
_G.Item = {}
----------------------------------------------------------------
--to local
local Item = Item
local next = next
local pairs = pairs
local ipairs = ipairs
local assert = assert
local unpack = table.unpack or unpack
----------------------------------------------------------------
--const.适配
Item.BASEBAGBLANK = 10		--初始背格数
Item.BASEDEPOT = 1			--初始仓页数
Item.DEPOTBLANK = 63		--仓格数/页
Item.BAGSORTCD = 30000		--整理包CD ms
Item.DEPOTSORTCD = 30000	--整理仓CD
Item.COINS	= 5000000		--金币+绑金 仅消耗用 增加视为绑金
Item.COIN	= 5000001		--金币
Item.COINB	= 5000002		--绑金
Item.GOLD	= 5000003		--元宝
Item.GOLDP	= 5000004		--礼金
Item.EXP	= 5000005 		--经验
Item.QUALITYCOLOR = {		--品质色 白绿蓝紫橙金铂
	[0]='e1e1e1',
	[1]='1e90ff',
	[2]='ae32ec',
	[3]='xae32ec',
	[4]='ff6600',
	[5]='ffff00',
	[6]='ffffff',
}

----------------------------------------------------------------
--const.程序
Item.CLEANTIME = 1000000*60*60*24*14--己删道具清库时间
Item.DELETEMETHOD = 'MOVE'  --'MARK'/'MOVE' 道具删除方式 标志/转表
Item.BIND = {unbind=0, bind=1, usebind=2, dealbind=3} --非绑/绑定/装备绑定/交易绑定
Item.MARK = { --位置标记 负值上线初始化不取
	invalid = -5,--版本己删
	guild = -4, --公会仓库
	sell = -3, 	--在售 拍卖或摆摊
	sold = -2, 	--己售给NPC(在线可回购)
	del = -1, 	--销毁
	-----------小于0上线不取
	bag = 0, 	--背包
	depot = 1, 	--仓库
	equip = 2, 	--装备
	task = 3, 	--任务计数(不占格, 无限叠, 不可移动, 任务系统控制删除)
	--...10000以上cfg_equip自动
}
Item.MARKnew = {
	--计数 gs,c
	
	--包类 gs,c
	
	--装类 gs,c,参与属性计算的包类库类都作装类
	
	--库类 c(多的话首次现查)
	
	--备存 销毁/己售/在售/公仓(现查)
	
	--
}
----------------------------------------------------------------
--local

----------------------------------------------------------------
--Item.get/add/del
function Item.gets(pid, mark, noidx) --读一包

end
function Item.getBySid(sid, pid, mark) --读一个

end
function Item.get(pid, mark, pos) --读一个

end
function Item.have(pid, id, sumall)--拥有量 sumall含锁定,仓库,过期等不可用 

end

function Item.add(pid, id, num, bind, lab)--加单种道具

end
--加多种道具list={{id,num,bind}or{id=id,num=num,binbind}}
function Item.adds(pid, list, lab)

end
function Item.delById(pid, id, num, lab)--删一种道具

end
function Item.delByPos(pid, pos, num, lab)--按包格位置删

end
function Item.delByDepotPos(pid, pos, num, lab)--按仓格位置删

end
function Item.delByIdList(pid, list, lab) --批量删

end

function Item.addInstance(pid, it, lab, new) --给实例

end
function Item.addCopy(pid, it0, lab, num) --给实例copy 

end

function Item.delete(it) --真删

end
function Item.markDelete(it, lab) --标删

end
function Item.markSold(it) --标记售出,用于回购
end
--实例属性get/set
function Item.getv( it, key )	--取实例值

end
function Item.setv( it, key, val )	--更新实例值
end
--使用限制/条件
function Item.lockId(pid, id, label) --冻结id道具

end
function Item.unlockId(pid, id) 	--解冻id道具

end
function Item.isLock(pid, id) 		--是否冻结

	return bool
end

function Item.lockBagPos(pid, pos)		--在线 临时冻结包位 交易等操作时用

end
function Item.unlockBagPos(pid, pos)	--在线 解冻包位

end
function Item.isLockBagPos(pid, pos)	--在线 是否冻包

	return bool
end

function Item.cd(pid, id) --CD中

	return bool
end
function Item.canUse(pid, it)

	return bool, err
end



----------------------------------------------------------------
--event
when{} function loadConfig()
-- dofile'cs_itemaction.lua'
-- dofile'cfg_createequip.lua'
end
when{} function afterConfig()
end
when{} function checkConfig()
end
when{} function cleanupUser(pid) --删号后
end
when{} function onStart() --删除己删除超期道具
end
when{} function afterMerge() --合服后清理过期与冲突
end
when{} function onRoleLogin(pid)
end
when{} function getUserInfo(uid, pid, info, step)

end

----------------------------------------------------------------
--global
--给单个
define.giveItem{pid=0,id=0,num=0,bind=Item.BIND.bind,lab='',mail=true,try=false,mailtime=0}
--给多个
define.giveItems{pid=0,list={},lab='',mail=true,try=false,mailtime=0}
--不经包直接给到装备位
define.giveEquip{pid=0,id=0,bind=Item.BIND.bind,mark='',pos=0,lab='',mail=true,try=false}
when{} function giveItem(pid, id, num, bind, lab, mail, try, mailtime)
	assert(pid ~= 0, 'pid error')
	assert(lab ~= '', 'lab error')
	assert(num > 0, 'num error' .. num)
	return Item._add(pid, id, num, bind, lab, mail, try, mailtime)
end
when{} function giveItems(pid, list, lab, mail, try, mailtime)
	assert(pid ~= 0, 'pid error')
	assert(lab ~= '', 'lab error')
	if #list==0 then return true end
	if #list==1 then
		local v = list[1]
		local id = toint(v[1] or v.id)
		local num = toint(v[2] or v.num or 1)
		local bind = toint(v[3] or v.bind or 1)
		return Item._add(pid, id, num, bind, lab, mail, try, mailtime)
	else
		return Item._adds(pid, list, lab, mail, try, mailtime)
	end
end
when{} function giveEquip(pid, id, bind, mark, pos, lab, mail, try)
	assert(pos == toint(pos), 'pos must int '..pos)
	assert(pid ~= 0, 'pid error')
	if bind==Item.BIND.usebind then bind=Item.BIND.bind end
	assert(lab ~= '', 'lab error')
	local im = cfg_item[id]
	assert(im, 'giveEquip invalid item id '..id)
	
end

----------------------------------------------------------------
--RPC.from gs
define.GSGiveItems{Token = '', List = { }, Lab = ''}
define.GSDelItems{Token = '', List = { }, Lab = ''}
define.GiveItemByPicks{Token='', T=EMPTY, ZoneID=0}
define.DelItemById{Token='', Id=0, Num=0, Lab=''}
define.ConsumeItem{Token='', Pos=0, Id=0, Num=0, Sid=0, Sel=0, Lab=''}

----------------------------------------------------------------
--RPC.from client
define.UseItem{Pos=0, Num=0, Sid=0, Sel=0} --使用
define.DelItem{Mark='', Pos=0, Sid=0} --销毁
define.MoveItem{Type='', From=0, To=0, Sid=0, Num=0, Lab='' } --移动
define.SplitItem{Mark='', Pos=0, Num=0, Sid=0} --拆分
define.SortBag{Mark=''} --整理
-- define.AddDepot{}	--开仓库
-- define.AskGetBlank{To=0}--开包格



----------------------------------------------------------------
do return end---------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------

----------------------------------------------------------------
--常量定义 程序定义
Item.FASHION = {
	fcloth = true,
	fhead = true,
	fweapon = true,
}
Item.EQUIPNUM = 11			--常规装备量
Item.MARKNAME = {}
for k,v in pairs(Item.MARK) do
	Item.MARKNAME[v] = k
end
Item.NoSendNumToGS = { 	--不用同步数量给GS, wear的也不用
	[Item.COIN] = true,
	[Item.COINB] = true,
	[Item.GOLD] = true,
	[Item.GOLDP] = true,
	[Item.EXP] = true,
}

----------------------------------------------------------------
function Item.new(id, num, bind, mailtime) 		--新建
	local it = DefaultDB.get'item'
	it.id = id
	it.num = num or it.num
	it.bind = bind or it.bind
	local im = cfg_item[id]
	assert(im, 'invalid itemid'..id)
	local startmin
	if im.limitmin then	--相对时限(分)
		startmin = mailtime and mailtime > 0 and mailtime/60000000 or _now(60)
		it.timeto = (startmin + im.limitmin) * 60000000
	elseif im.limitto then	--绝对时限
		local t = string.split(im.limitto, '-' )
		local d = {year=toint(t[1]), month=toint(t[2]), day=toint(t[3]), hour=t[4] and toint(t[4]), min=t[5] and toint(t[5]) }
		it.timeto = _time(0, d)
	end
	local imi = im --转义前im
	local tid = im.titem
	if tid then--转义实例
		it.id = tid
		im = cfg_item[tid]
	end
	if it.timeto == 0 then --转义前没有则用转义后的
		if im.limitmin then	--相对时限(分)
			startmin = startmin or (mailtime and mailtime > 0 and mailtime/60000000 or _now(60))
			it.timeto = (startmin + im.limitmin) * 60000000
		elseif im.limitto then	--绝对时限
			local t = string.split(im.limitto, '-' )
			local d = {year=toint(t[1]), month=toint(t[2]), day=toint(t[3]), hour=t[4] and toint(t[4]), min=t[5] and toint(t[5]) }
			it.timeto = _time(0, d)
		end
	end
	if im.getincd then --获得即进入cd道具
		Item.setv( it, 'getincd', _now(1) + im.getincd )
	end
	--初生实例
	for i = 1, math.huge do --base attribute 基础
		local ak = im['ba'..i]
		if ak then
			local av = math.random( im['bav'..i][1], im['bav'..i][2] or im['bav'..i][1] )
			it.key[#it.key+1] = 'basea'..i
			it.val[#it.key] = av
		else break
		end
	end
	for i = 1, math.huge do --high attribute 卓越
		local ha = im['ha'..i]
		if ha then
			local wt = im['hawt'..i]
			local idx = math.weight(wt)
			it.key[#it.key+1] = 'higha'..i
			it.val[#it.key] = ha[idx]
		else break
		end
	end
	-- 橙装初始id
	local orangeid = im.orangeid
	if orangeid then
		it.key[#it.key+1] = 'orangeid'
		it.val[#it.key] = orangeid
	end
	--转义实例
	local diamond
	if imi.instance then
		for k, v in pairs(imi.instance) do
			if k == 'diamond' then diamond = true end
			local cover
			for i, key in ipairs(it.key) do
				if k == key then
					cover = i
				end
			end
			if cover then
				it.val[cover] = v
			else
				it.key[#it.key+1] = k
				it.val[#it.key] = v
			end
		end
	else
		if im.instance then
			for k, v in pairs(im.instance) do
				if k == 'diamond' then diamond = true end
				local cover
				for i, key in ipairs(it.key) do
					if k == key then
						cover = i
					end
				end
				if cover then
					it.val[cover] = v
				else
					it.key[#it.key+1] = k
					it.val[#it.key] = v
				end
			end
		end
	end
	if diamond then
		for i = 1, math.huge do --base attribute 基础
			local ba = Item.getv(it, 'basea'..i)
			if ba then
				Item.setv( it, 'basea'..i, math.ceil(ba*Item.DIAMOND_MUL) )
			else break
			end
		end
	end

	it.time = _now( 0 )

	return it
end
function Item._newX(id, mailtime) 		--转模对比
	local im = cfg_item[id]
	assert(im, 'invalid itemid'..id)
	local timeto = 0
	if im.limitmin then	--相对时限(分)
		local startmin = mailtime and mailtime > 0 and mailtime/60000000 or _now(60)
		timeto = (startmin + im.limitmin) * 60000000
	elseif im.limitto then	--绝对时限
		local t = string.split(im.limitto, '-' )
		local d = {year=toint(t[1]), month=toint(t[2]), day=toint(t[3]), hour=t[4] and toint(t[4]), min=t[5] and toint(t[5]) }
		timeto = _time(0, d)
	end
	local tid = im.titem
	if tid then--转义实例
		id = tid
		im = cfg_item[tid]
	end
	return id, timeto
end
function Item.flow(it, str)
	if it.flow == str then
		return
	elseif it.flow == '' then
		it.flow = str
	else
		it.flow = it.flow..'|'..str
	end
end
function Item._init(c)		--道具模块内存初始化(非入库数据)
	c.lockbagblank = c.lockbagblank or {}	--临时冻结包格 k:pos v:true
	c.lockcoin = c.lockcoin or {}	--临时冻结货币 k:id v:num
end
function Item.gets(pid, mark, noidx) --读一包
	assert(pid, 'no pid')
	assert(mark, 'no mark')
	assert(Item.MARK[mark], mark..' unreg mark')
	mark = Item.MARK[mark]
	local r = _ORM'item':where{pid=pid, mark=mark}:select()
	if r and not noidx then --返回按it.pos索引的表
		local equip={}
		for _, it in next, r do
			equip[it.pos] = it;
		end
		r=equip
	end
	return r or {}
end
function Item.getBySid( sid, pid, mark ) --读一个
	assert(pid, 'no pid')
	if type(mark)=='string' then
		mark = Item.MARK[mark]
	end
	if mark then
		local r = _ORM'item':where{sid=sid, pid=pid, mark=mark}:select()
		return r and r[1]
	else
		local r = _ORM'item':where{sid=sid, pid=pid, mark=mark}:select()
		return r and r[1]
	end
end
function Item.get(pid, mark, pos) --读一个
	assert(mark, 'unreg mark')
	assert(Item.MARK[mark], mark..' unreg mark')
	assert(pos, 'no pos')
	mark = Item.MARK[mark]
	local r = _ORM'item':where{pid=pid, mark=mark, pos=pos}:select()
	return r and r[1]
end
function Item.getMaxBlank(pid, mark) --通用最大包格数
	if mark == 'bag' then
		local p = _ORM'player':where{ pid = pid }:select( )[1]
		return Item.BASEBAGBLANK + p.bagblankex
	elseif mark == 'depot' then
		local p = _ORM'player':where{ pid = pid }:select( )[1]
		return Item.DEPOTBLANK * (Item.BASEDEPOT + p.depotpageex)
	elseif mark == 'wingspirit' then
		return WingSpirit.getEquipBlank(pid)
	elseif mark == 'wingspiritbag' then
		return WingSpirit.BAGBLANK
	elseif mark == 'wingspiritdepot' then
		return WingSpirit.DEPOTBLANK
	elseif mark == 'horcruxbag' then
		return 350
	elseif mark == 'crossbowbag' then
		return 350
	elseif mark == 'qlbbag' then
		return 350
	elseif mark == 'mengpetbag' then
		return 245
	elseif mark == 'tequiprunebag' then
		return 560
	elseif mark == 'artifactbag' then
		return 200
	elseif mark == 'cloakbag' then
		return 350
	elseif mark == 'holybag' then
		return 350
	else
		error('undefinedblankmark', mark)
	end
end
function Item.getFreeBlank( pid, mark ) --通用空格数
	local maxn = Item.getMaxBlank(pid, mark)
	local bag = Item.gets(pid, mark)
	local free, first = 0
	for pos = 1, maxn do
		if not bag[pos] then
			if not first then first = pos end
			free = free +1
		end
	end
	return free, first
end
function Item.getFreeBag(pid) --空包格数 return 空格数, 首空格序数
	return Item.getFreeBlank( pid, 'bag' )
end
function Item.getItemNum(pid) --计数道具
	local its = _ORM'itemnum':where{pid=pid}:select()
	local nums = {}
	if not its then return nums end
	for i, it in pairs(its) do
		nums[it.id] = it.num
	end
	return nums
end
function Item.getBag(pid) --背包道具
	return Item.gets(pid, 'bag')
end
function Item.getDepot(pid) --仓库道具
	return Item.gets(pid, 'depot')
end
function Item.realDelete(it) --真删
	_ORM'item':where{sid=it.sid}:delete()
end
function Item.markDelete(it, lab) --标删
	if Item.DELETEMETHOD == 'MARK' then --标记式
		if it.mark == Item.MARK.bag then
			assert(not Item.isLockBag(it.pid, it.pos), it.pos..' bagblanklocked' )
		end
		_ORM'item':where{sid=it.sid}:update{mark=Item.MARK.del, time=_now(0)}
	elseif Item.DELETEMETHOD == 'MOVE' then --转表式
		local it = table.newclone(it)
		it.time=_now(0)
		_ORM'item_del':insert(it)
		_ORM'item':where{sid=it.sid}:delete()
	else error(Item.DELETEMETHOD)
		-- _SQL:run([[insert into item_del(sid, pid, id, mark, pos, num, bind, timeto, time, key, val, flow) values($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12);]],
			--it.id, it.pid, it.id, it.mark, it.pos, it.num, it.bind, it.timeto, it.time, it.key, it.val, it.flow) --不用ORM不用clone但不方法统计
	end
end
function Item._markSold(it) --标售
	_ORM'item':where{sid=it.sid}:update{mark=Item.MARK.sold, time=_now(0)}
end
function Item.have(pid, id, sumall) --id道具拥有数量 sumall含己锁定,仓库,过期 用于记日志的统计量
	assert(pid, 'no pid')
	local im = cfg_item[id]
	assert(im, 'invalid itemid'..id)
	if im.nobag then
		local im = cfg_item[id]
		if im.trans then
			return cfg_itemTrans[im.trans].have(pid)
		else
			local r = _ORM'itemnum':where{pid=pid, id=id}:select()
			return r and r[1].num or 0
		end
	elseif im.bagin then --must no pile
		local sum = 0
		local r = _ORM'item':where{pid=pid, mark=Item.MARK[im.bagin]}:select()
		if r then
			for i, it in pairs(r) do
				if it.id==id and (sumall or not Item.timeout( it )) then
					sum = sum + it.num
				end
			end
		end
		if sumall and Item.MARK[im.bagin..'depot'] then
			local r = _ORM'item':where{pid=pid, mark=Item.MARK[im.bagin..'depot']}:select()
			if r then
				for i, it in pairs(r) do
					if it.id==id then
						sum = sum +it.num
					end
				end
			end
		end
		return sum
	else
		local sum = 0
		local r = _ORM'item':where{pid=pid, mark=Item.MARK.bag}:select()
		local maxn = Item.getMaxBlank(pid, 'bag')
		if r then
			for i, it in pairs(r) do
				if it.id==id and it.pos <= maxn then
					if sumall then
						sum = sum + it.num
					else
						if not Item.timeout( it ) and not Item.isLockBag(pid, it.pos) then
							sum = sum + it.num
						end
					end
				end
			end
		end
		if sumall then
			local r = _ORM'item':where{pid=pid, mark=Item.MARK.depot}:select()
			if r then
				for i, it in pairs(r) do
					if it.id==id then
						sum = sum + it.num
					end
				end
			end
		end
		return sum
	end
end
function Item.money(pid) --金币+绑金
	return Item.have(pid, Item.COIN) + Item.have(pid, Item.COINB)
end
function Item.costMoney(pid, num, lab) --删金币, 先绑后非
	if num>Item.money(pid) then return false end
	local haveb = Item.have(pid, Item.COINB)
	if num<=haveb then
		Item.delById(pid, Item.COINB, num, lab)
	else
		if haveb>0 then
			Item.delById(pid, Item.COINB, haveb, lab)
		end
		Item.delById(pid, Item.COIN, num-haveb, lab)
	end
	return true
end
function Item.getName(it) --取名
	local im = cfg_item[it.id]
	return string.format("<font color='#%s'>%s</font>", Item.QUALITYCOLOR[im.quality], im.name), im.name
end
function Item.getNameById(id)
	local im =Cfg.cfg_item[id]
	return string.format("<font color='#%s'>%s</font>", Item.QUALITYCOLOR[im.quality], im.name), im.name
end
function Item.giveCopy(pid, it0, lab, num) --给实例copy it0源实例, num可选指定数量默认源数量
	assert(it0.sid~=0, 'Item.give item.sid==0')
	local free, first = Item.getFreeBag(pid)
	if free==0 then return false end
	local it = table.newclone(it0)
	it.sid = dbsid( 'item', pid )
	it.pid = pid
	it.mark = Item.MARK.bag
	it.pos = first
	it.time = _now(0)
	if num then
		it.num = num
	end
	Item.flow(it, 'givecopy_'..lab)
	local old = Item.have(pid, it.id, true) --别动顺序
	_ORM'item':insert(it)
	local new = old + it.num
	CallPlayer(pid).BagUp{T={pos=first, it=it}}
	onGetItem{pid=pid, it=it, id=it.id, num=num, bind=bind, lab=lab, old=old, new=new}
	return it
end
function Item.giveInstance(pid, it, lab, new) --给实例
	local free, first = Item.getFreeBag(pid)
	if free==0 then return false end
	local old = Item.have(pid, it.id, true)
	if new then
		it.pid = pid
		it.sid = dbsid( 'item', pid )
		it.mark = Item.MARK.bag
		it.pos = first
		it.time = _now(0)
		Item.flow(it, lab)
		_ORM'item':insert( it )
	else
		assert(it.sid~=0, 'Item.give item.sid==0')
		local flow = it.flow..'|'..lab
		it = _ORM'item':where{sid=it.sid}:returning( ):updateinsert{pid=pid, mark=Item.MARK.bag, pos=first, time=_now(0), flow=flow }[1]
	end
	local new = old + it.num
	CallPlayer(pid).BagUp{T={pos=first, it=it}}
	onGetItem{pid=pid, it=it, id=it.id, num=it.num, bind=bind, lab=lab, old=old, new=new}
	return true, it
end
function Item._relist(list, pid, lab, mailtime) --辅助Item._adds
	local role = _ORM'player':where{ pid = pid }:select( )[1]
	local lnum, lpile, l1 = {}, {}, {}
	local lxpile = {}
	for i, v in ipairs(list) do --整理
		local id = v[1] or v.id
		assert(id, 'gives no id lab:'..lab)
		local num = toint(v[2] or v.num or 1)
		assert(num>0, num..'<=0 id'..id..'lab:'..lab) --TODO为了接口的安全简洁不做适应, 请保证num大于0!
		local bind = v[3] or v.bind or 1
		if type(bind)~='number' then
			dump(list)
			error('bind type error'..lab)
		end
		assert(bind==Item.BIND.unbind or bind==Item.BIND.bind or bind==Item.BIND.usebind, bind..'bind must 0/1/2 lab:'..lab)
		local im = cfg_item[id]
		assert(im, 'invalid itemid'..id..' lab:'..lab)
		if im.job1 then --职业转义
			id = im['job'..role.job]
			im = cfg_item[id]
		end
		if im.nobag then--不进包的合并数量
			if id == Item.CROSSHONOR then
				num = CrossDaily.checkHonor( pid, num )
			end
			if num > 0 then
				lnum[id] = (lnum[id] or 0) +num
			end
------------FUCK{
		elseif im.piletime and im.limitmin then
			lxpile[id] = (lxpile[id] or 0) +num
------------FUCK}
		else
			local pile = im.pile or 0
			if pile>0 then
				local idx = id..'_'..bind
				if lpile[idx] then
					lpile[idx][2] = lpile[idx][2] + num
				else
					lpile[idx] = {id, num, bind}
				end
			else
				for ii=1, num do
					l1[#l1+1] = {id, 1, bind}
				end
			end
		end
	end
	for id, num in pairs(lnum) do
		l1[#l1+1] = {id, num, 1}
	end
------------FUCK{
	local pilemin = {}
	for id, num in pairs(lxpile) do
		local im = cfg_item[id]
		l1[#l1+1] = {id, num, 1, pilemin=0} --发邮件用
		if im.titem then
			pilemin[im.titem] = (pilemin[im.titem] or 0) + num * im.limitmin
		else
			pilemin[id] = (pilemin[id] or 0) + num * im.limitmin
		end
	end
	for id, min in pairs(pilemin) do
		l1[#l1+1] = {id, 0, 1, pilemin=min} --即时给用
	end
------------FUCK}
	for idx, v in pairs(lpile) do
		l1[#l1+1] = v
	end
	return l1, lxpile
end
function Item._add(pid, id, num, bind, lab, mail, try, mailtime) --新给单种
	assert(id, 'gives no id lab:'..lab)
	assert(num>0, num..'<=0 id'..id..'lab:'..lab) --TODO为了接口的安全简洁不做适应, 请保证num大于0!
	assert(bind==Item.BIND.unbind or bind==Item.BIND.bind or bind==Item.BIND.usebind, bind..'bind must 0/1/2 lab:'..lab)
	local im = cfg_item[id]
	assert(im, 'invalid itemid'..id..' lab:'..lab)
	if im.job1 then --职业转义
		local job = Role.getJob( pid )
		id = im['job'..job]
		im = cfg_item[id]
	end
	if im.nobag then
		return Item._add_nobag(pid, id, num, bind, lab, mail, try, mailtime)
	else
		do return Item._adds(pid, {{id, num, bind}}, lab, mail, try, mailtime) end --TODO 注掉这句就可以用分流方式
		if im.piletime and im.limitmin then
			return Item._add_piletime(pid, id, num, bind, lab, mail, try, mailtime)
		else
			local pile = im.pile or 0
			if pile>0 then
				return Item._add_pile(pid, id, num, bind, lab, mail, try, mailtime)
			else
				return Item._add_nopile(pid, id, num, bind, lab, mail, try, mailtime)
			end
		end
	end
end
function Item._adds(pid, list0, lab, mail, try, mailtime) --批量新给list={{id, num, bind}, ...} or {{id=, num=, bind=}, ...}
	assert(pid, 'no pid')
	assert(lab, 'require lab')--必须加
	local list, lxpile = Item._relist(list0, pid, lab, mailtime) --不会破坏原list

	local bagg = {}
	local bag
	local maxbag
	--分发
	local nums = {}--不计格的{[id]=num}
	local ready = {}--准备单{[pos]={id, num, bind}}
	local remain = {}--剩余单{[i]={id, num, bind}}
	local baginready = {} --特殊背包
------------FUCK{
	local piletime = {} --叠时道具
------------FUCK}
	for i, v in ipairs(list) do
		local id, num, bind = v[1], v[2], v[3]
		local im = cfg_item[id]
		if im.nobag then
			nums[id] = num
------------FUCK{
		elseif im.piletime then	--TODO FUCK:有格ready合并后的ID和天数.没格remain原始ID和数量
			bag = bagg['bag'] or Item.gets(pid, 'bag')
			bagg['bag'] = bag
			maxbag = maxbag or Item.getMaxBlank(pid, 'bag')
			local r = _ORM'item':where{pid=pid, id=id}:select()
			--TODO_Item._adds001:除己删,寄售,己售@Item.MARK
			if v.pilemin > 0 then --即时给用
				if r and r[1].mark >= 0 then --有:备时间/ 无:备一格
					piletime[id] = v
				else
					local num = 1
					for pos = 1, maxbag do
						if not bag[pos] and not ready[pos] then
							ready[pos] = v
							num = 0
							piletime[id] = v
							v.pos = pos
							break
						end
					end
					if num>0 then
						for idx, num in pairs(lxpile) do
							local im = cfg_item[idx]
							if idx == id or im.titem == id then
								remain[#remain+1] = {idx, num, bind}
							end
						end
					end
				end
			else --待发邮件用
			end
------------FUCK}
		elseif im.bagin then --must no pile
			if not baginready[im.bagin] then baginready[im.bagin] = {} end
			-- local t = baginready[im.bagin]
			-- t[#t+1] = {id, num, bind}
			bag = bagg[im.bagin] or Item.gets(pid, im.bagin)
			bagg[im.bagin] = bag
			maxbag = maxbag or Item.getMaxBlank(pid, im.bagin)
			local ready = baginready[im.bagin]
			local pile = im.pile or 0
			if pile>0 then--Item._relist己按id, bind组合
				local idX, timetoX = Item._newX(id, mailtime)
				for pos=1, maxbag do --先合并
					local had = bag[pos]
					if had and had.id==idX and had.bind==bind and had.timeto==timetoX then --可合并
						local freepile = 0
						if ready[pos] then
							freepile = pile-(had.num +ready[pos][2])
						else
							freepile = pile-had.num
						end
						if freepile>0 then
							if freepile>=num then--无余, 有多少加多少
								if ready[pos] then
									ready[pos][2] = ready[pos][2] + num
								else
									ready[pos] = {id, num, bind}
								end
								num = 0
								break
							else --分不完, 本格加满
								if ready[pos] then
									local set = pile-had.num
									ready[pos][2] = set
									num = num - freepile
								else
									ready[pos] = {id, freepile, bind}
									num = num - freepile
								end
							end
						end
					end
					if num==0 then break end
				end
				if num>0 then--再分空格
					for pos = 1, maxbag do --for1
						if not bag[pos] and not ready[pos] then
							if pile>=num then --无余
								ready[pos] = {id, num, bind}
								num = 0
								break
							else  --分不完, 本格加满
								ready[pos] = {id, pile, bind}
								num = num - pile
							end
						end
					end
				end
				if num>0 then--未分完
					remain[#remain+1] = {id, num, bind}
				end
			else --非叠加Item._relist己分单
				local num = 1
				for pos = 1, maxbag do
					if not bag[pos] and not ready[pos] then
						ready[pos] = v
						num = 0
						break
					end
				end
				if num>0 then
					remain[#remain+1] = v
				end
			end
		else --一般背包道具
			bag = bagg['bag'] or Item.gets(pid, 'bag')
			bagg['bag'] = bag
			maxbag = maxbag or Item.getMaxBlank(pid, 'bag')
			local pile = im.pile or 0
			if pile>0 then--Item._relist己按id, bind组合
				local idX, timetoX = Item._newX(id, mailtime)
				for pos=1, maxbag do --先合并
					local had = bag[pos]
					if had and had.id==idX and had.bind==bind and had.timeto==timetoX and not Item.isLockBag(pid, pos) then --可合并
						local freepile = 0
						if ready[pos] then
							freepile = pile-(had.num +ready[pos][2])
						else
							freepile = pile-had.num
						end
						if freepile>0 then
							if freepile>=num then--无余, 有多少加多少
								if ready[pos] then
									ready[pos][2] = ready[pos][2] + num
								else
									ready[pos] = {id, num, bind}
								end
								num = 0
								break
							else --分不完, 本格加满
								if ready[pos] then
									local set = pile-had.num
									ready[pos][2] = set
									num = num - freepile
								else
									ready[pos] = {id, freepile, bind}
									num = num - freepile
								end
							end
						end
					end
					if num==0 then break end
				end
				if num>0 then--再分空格
					for pos = 1, maxbag do --for1
						if not bag[pos] and not ready[pos] then
							if pile>=num then --无余
								ready[pos] = {id, num, bind}
								num = 0
								break
							else  --分不完, 本格加满
								ready[pos] = {id, pile, bind}
								num = num - pile
							end
						end
					end
				end
				if num>0 then--未分完
					remain[#remain+1] = {id, num, bind}
				end
			else --非叠加Item._relist己分单
				local num = 1
				for pos = 1, maxbag do
					if not bag[pos] and not ready[pos] then
						ready[pos] = v
						num = 0
						break
					end
				end
				if num>0 then
					remain[#remain+1] = v
				end
			end
		end
	end
	local enough = true
	-- for bagname, bb in pairs(baginready) do
		-- local free, first = Item.getFreeBlank( pid, bagname )
		-- if free < #bb then
			-- enough = false
			-- break
		-- end
	-- end
	if #remain > 0 then enough = false end
	if try then
		return enough
	end
	--给
	local ins = {}
	if mail then--可以邮件
		if not enough then --格不足 全封邮 TODO 有叠时道具可能进邮件 无法实现余者封邮
			local mailblank, maillist = 0, {}
			local function checkFullMail()
				if mailblank==Mail.ITEMBLANK then--满一封
					Item.mail(pid, maillist, lab)
					mailblank, maillist = 0, {}
				end
			end
			for i, v in ipairs(list) do
				local id, num, bind = v[1], v[2], v[3]
				if num > 0 then
					local im = cfg_item[id]
					if im.nobag then
						maillist[#maillist+1] = v
						mailblank = mailblank +1
						checkFullMail()
					else
						local pile = im.pile or 0
						if pile>0 then
							local mailnum = math.ceil(num/pile)
							for ii=1, mailnum do
								if num>pile then
									maillist[#maillist+1] = {id, pile, bind}
									mailblank = mailblank +1
									num = num -pile
								else
									maillist[#maillist+1] = {id, num, bind}
									mailblank = mailblank +1
								end
								checkFullMail()
							end
						else
							maillist[#maillist+1] = v
							mailblank = mailblank +1
							checkFullMail()
						end
					end
				else --叠时转义后的不用于发邮
				end
			end
			if mailblank>0 then --剩余不足格
				Item.mail(pid, maillist, lab)
				mailblank, maillist = 0, {}
			end
			return true
		end
	else --禁邮，须足格
		-- for bagname, bb in pairs(bagin) do
			-- local free, first = Item.getFreeBlank( pid, bagname )
			-- if free < #bb then
				-- CallPlayer(pid).Msg{K='baglimit'}
				-- return false
			-- end
		-- end
		if #remain>0 then--有余
			CallPlayer(pid).Msg{K='baglimit'}
			return false
		end
	end
	--计数道具
	for id, num in pairs(nums) do
		local im = cfg_item[id]
		local maxown = im.maxown and math.min(im.maxown, BIT54) or BIT54
		if im.trans then
			local old = Item.have(pid, id, true)
			if old<maxown then
				if maxown-old < num then --暴表
					num = maxown-old
				end
				if num > 0 then
					cfg_itemTrans[im.trans].add(pid, num, lab)
				end
			end
		else
			local r = _ORM'itemnum':where{pid=pid, id=id}:select()
			local old, new = 0, num
			if id == Item.CROSSHONOR then
				CrossDaily.addHonor( pid, num, 'item' )
			end
			if r then
				old = r[1].num
				if old<maxown then
					if maxown-old < num then --暴表
						num = maxown-old
					end
					if num > 0 then
						new = old + num
						_ORM'itemnum':where{pid=pid, id=id}:update{num=new}
						CallPlayer(pid).ItemUp{T={id=id, num=new-old, new=new}}
					end
					onGetItem{pid=pid, id=id, num=num, bind=1, lab=lab, old=old, new=new}
				end
			else
				new = math.min(num, maxown)
				local it = DefaultDB.get'itemnum'
				it.pid = pid
				it.id = id
				it.num = new
				_ORM'itemnum':insert(it)
				CallPlayer(pid).ItemUp{T={id=id, num=new-old, new=new}}
				onGetItem{pid=pid, id=id, num=num, bind=1, lab=lab, old=old, new=new}
			end
		end
		local showit = Item.new(id) --itemnum
		showit.num = num
		ins[#ins+1] = showit
	end
	--特殊背包
	for bagname, ready in pairs(baginready) do
		local bag = Item.gets(pid, bagname)
		for pos, v in pairs(ready) do
			local id, num, bind = v[1], v[2], v[3]
			local old = Item.have(pid, id, true)
			local new = old + num
			local it = bag[pos]
			if it then
				it = _ORM'item':where{sid=it.sid}:returning( ):update{num=it.num+num}[1]
			else
				it = Item.new(id, num, bind, mailtime)
				it.sid = dbsid( 'item', pid )
				it.pid = pid
				it.mark = Item.MARK[bagname]
				it.pos = pos
				Item.flow(it, lab)
				_ORM'item':insert(it)
			end
			CallPlayer(pid).ItemInUp{BagIn=bagname, T={pos=pos, it=it}}
			onGetItem{pid=pid, it=it, id=id, num=num, bind=bind, lab=lab, old=old, new=new}
			local showit = table.newclone(it)
			showit.num = num
			ins[#ins+1] = showit
		end
	end
	--格道具
	for pos, v in pairs(ready) do
		bag = bagg['bag'] or Item.gets(pid, 'bag')
		local id, num, bind = v[1], v[2], v[3]
		local im = cfg_item[id]
		if im.piletime then
			--@叠时道具X_1
		else
			local old = Item.have(pid, id, true)
			local new = old + num
			local it = bag[pos]
			if it then
				it = _ORM'item':where{sid=it.sid}:returning( ):update{num=it.num+num}[1]
			else
				it = Item.new(id, num, bind, mailtime)
				it.sid = dbsid( 'item', pid )
				it.pid = pid
				it.mark = Item.MARK.bag
				it.pos = pos
				Item.flow(it, lab)
				_ORM'item':insert(it)
			end
			CallPlayer(pid).BagUp{T={pos=pos, it=it}}
			onGetItem{pid=pid, it=it, id=id, num=num, bind=bind, lab=lab, old=old, new=new}
			local showit = table.newclone(it)
			showit.num = num
			ins[#ins+1] = showit
		end
	end
------------FUCK{
	--叠时道具X_1
	local c = Client.byPID(pid)
	for id, v in pairs(piletime) do
		local id, num, bind, min = v[1], v[2], Item.BIND.bind, v.pilemin --TODO:绑定必须统一
		local r = _ORM'item':where{pid=pid, id=id}:select()
		--TODO_Item._adds001:除己删,寄售,己售@Item.MARK
		local now = _now(0)
		local addus = 60000000 * min
		local it
		if r and r[1].mark >= 0 then --有:备时间/ 无:备一格
			it = r[1]
			local pos = it.pos
			if it.timeto >= now then
				it = _ORM'item':where{sid=it.sid}:returning( ):update{timeto = it.timeto + addus}[1]
			else
				it = _ORM'item':where{sid=it.sid}:returning( ):update{timeto = now + addus}[1]
			end
			if it.mark == Item.MARK.mengpet then
				CallPlayer(pid).ComEquipUp{T={key='mengpet',pos=pos, it=it}}
				CallGsByPid( pid ).ComEquip{Token=c.getToken(), Pos=pos, It=it, Key='mengpet'}
			else
				CallPlayer(pid).ItemInUp{BagIn=Item.MARKNAME[it.mark], T={pos=pos, it=it}}
			end
		else
			local pos = v.pos
			it = Item.new(id) --piletime
			it.sid = dbsid( 'item', pid )
			it.pid = pid
			it.mark = Item.MARK.bag
			it.pos = pos
			it.bind = bind
			it.num = 1
			it.timeto = now + addus
			Item.flow(it, lab)
			_ORM'item':insert(it)
			CallPlayer(pid).ItemInUp{BagIn='bag', T={pos=pos, it=it}}
		end
	end
	for id, num in pairs(lxpile) do --TODO:按源ID记日志
		onGetItem{pid=pid, it=it, id=id, num=num, bind=bind, lab=lab, old=0, new=0}
		ins[#ins+1] = it
	end
------------FUCK}

	return true, ins
end
function Item._add_nobag(pid, id, num, bind, lab, mail, try, mailtime) --不占包
	local im = cfg_item[id]
	if try then return true end
	local maxown = im.maxown and math.min(im.maxown, BIT54) or BIT54
	if im.trans then
		local old = Item.have(pid, id, true)
		if old<maxown then
			if maxown-old < num then --暴表
				num = maxown-old
			end
			if num > 0 then
				cfg_itemTrans[im.trans].add(pid, num, lab)
			end
		end
	else
		local r = _ORM'itemnum':where{pid=pid, id=id}:select()
		local old, new = 0, num
		if id == Item.CROSSHONOR then
			CrossDaily.addHonor( pid, num, 'item' )
		end
		if r then
			old = r[1].num
			if old<maxown then
				if maxown-old < num then --暴表
					num = maxown-old
				end
				if num > 0 then
					new = old + num
					_ORM'itemnum':where{pid=pid, id=id}:update{num=new}
					CallPlayer(pid).ItemUp{T={id=id, num=new-old, new=new}}
				end
				onGetItem{pid=pid, id=id, num=num, bind=1, lab=lab, old=old, new=new}
			end
		else
			new = math.min(num, maxown)
			local it = DefaultDB.get'itemnum'
			it.pid = pid
			it.id = id
			it.num = new
			_ORM'itemnum':insert(it)
			CallPlayer(pid).ItemUp{T={id=id, num=new-old, new=new}}
			onGetItem{pid=pid, id=id, num=num, bind=1, lab=lab, old=old, new=new}
		end
	end
	local showit = Item.new(id) --nobag
	showit.num = num
	return true, {showit}
end
function Item._add_piletime(pid, id, num, bind, lab, mail, try, mailtime) --新给单种叠时(未分立)
	do return Item._adds(pid, {{id, num, bind}}, lab, mail, try, mailtime) end
	--local im = cfg_item[id]

end
function Item._add_pile(pid, id, num, bind, lab, mail, try, mailtime) --背包可叠加
	local im = cfg_item[id]
	local bagname = im.bagin or 'bag'
	local bag = Item.gets(pid, bagname)
	local maxbag = Item.getMaxBlank(pid, bagname)
	local ready = {}--准备单{[pos]=num
	local rnum = num	--余量
	local pile = im.pile

	local idX, timetoX = Item._newX(id, mailtime)
	for pos=1, maxbag do --先合并
		local had = bag[pos]
		if had and had.id==idX and had.bind==bind and had.timeto==timetoX and not ( bagname=='bag' and Item.isLockBag(pid, pos) ) then --可合并
			local hadnum = had.num --格原有量
			local pileneed = pile - (hadnum + (ready[pos] or 0)) --补满堆需量
			if pileneed>0 then
				if pileneed>=rnum then--无余, 有多少加多少
					ready[pos] = (ready[pos] or 0) + rnum
					rnum = 0
					break
				else --分不完, 本格加满
					ready[pos] = (ready[pos] or 0) + pileneed
					rnum = rnum - pileneed
				end
			end
		end
		if rnum==0 then break end
	end
	if rnum>0 then--再分空格
		for pos = 1, maxbag do --for1
			if not bag[pos] and not ready[pos] then
				if pile>=rnum then --无余
					ready[pos] = rnum
					rnum = 0
					break
				else  --分不完, 本格加满
					ready[pos] = pile
					rnum = rnum - pile
				end
			end
		end
	end
	local enough = true
	if rnum > 0 then enough = false end
	if try then
		return enough
	end
	if mail then
		local mailblank, maillist = 0, {}
		local function checkFullMail()
			if mailblank==Mail.ITEMBLANK then--满一封
				Item.mail(pid, maillist, lab)
				mailblank, maillist = 0, {}
			end
		end
		if not enough then
			local rnum2 = Item.MAIL_REMAIN and rnum or num
			local mailnum = math.ceil(rnum2/pile)
			for ii=1, mailnum do
				if rnum2>pile then
					maillist[#maillist+1] = {id, pile, bind}
					mailblank = mailblank +1
					rnum2 = rnum2 -pile
				else
					maillist[#maillist+1] = {id, rnum2, bind}
					mailblank = mailblank +1
				end
				checkFullMail() --满一封就发
			end
			if mailblank>0 then --剩余不满封发
				Item.mail(pid, maillist, lab)
			end
			if not Item.MAIL_REMAIN then --格不足 全封邮
				return true
			end
		end
	else
		if rnum>0 then--有余
			CallPlayer(pid).Msg{K='baglimit'}
			return false
		end
	end
	if rnum == num then return end --无进格,全进邮了
	local innum = num - rnum --进包量
	local ins = {}
	local old = Item.have(pid, id, true)
	for pos, add in pairs(ready) do
		local it = bag[pos]
		if it then
			it = _ORM'item':where{sid=it.sid}:returning( ):update{num=it.num+add}[1]
		else
			it = Item.new(id, add, bind, mailtime)
			it.sid = dbsid( 'item', pid )
			it.pid = pid
			it.mark = Item.MARK[bagname]
			it.pos = pos
			Item.flow(it, lab)
			_ORM'item':insert(it)
		end
		CallPlayer(pid).BagUp{T={pos=pos, it=it}}
	end
	onGetItem{pid=pid, id=id, num=innum, bind=bind, lab=lab, old=old, new=old+innum}
	local shownum = math.ceil(innum/pile)
	for i=1, shownum do
		if innum>pile then
			ins[#ins+1] = Item.new(id, pile, bind, mailtime)
			innum = innum - pile
		else
			ins[#ins+1] = Item.new(id, innum, bind, mailtime)
			innum = 0
		end
	end
	return true, ins
end
function Item._add_nopile(pid, id, num, bind, lab, mail, try, mailtime) --背包不可叠加
	local im = cfg_item[id]
	local bagname = im.bagin or 'bag'
	local bag = Item.gets(pid, bagname)
	local maxbag = Item.getMaxBlank(pid, bagname)

	local ready = {}--准备单{[pos]=1
	local rnum = num	--余量
	for pos = 1, maxbag do
		if not bag[pos] and not ready[pos] then
			ready[pos] = 1
			rnum = rnum - 1
			if rnum == 0 then
				break
			end
		end
	end
	local enough = true
	if rnum > 0 then enough = false end
	if try then
		return enough
	end
	if mail then--可以邮件
		local mailblank, maillist = 0, {}
		local function checkFullMail()
			if mailblank==Mail.ITEMBLANK then--满一封
				Item.mail(pid, maillist, lab)
				mailblank, maillist = 0, {}
			end
		end
		if not enough then
			if Item.MAIL_REMAIN then --空足/余者封邮
				for i = 1, rnum do
					maillist[#maillist+1] = {id, 1, bind}
					mailblank = mailblank +1
					checkFullMail()
				end
				if mailblank>0 then --剩余不足格
					Item.mail(pid, maillist, lab)
				end
			else --格不足 全封邮
				for i = 1, num do
					maillist[#maillist+1] = {id, 1, bind}
					mailblank = mailblank +1
					checkFullMail()
				end
				if mailblank>0 then --剩余不足格
					Item.mail(pid, maillist, lab)
				end
				return true
			end
		end
	else --禁邮，须足格
		if rnum>0 then--有余
			CallPlayer(pid).Msg{K='baglimit'}
			return false
		end
	end
	if rnum == num then return end --无进格,全进邮了
	local ins = {}
	local old = Item.have(pid, id, true)
	for pos, _ in pairs(ready) do
		local new = old + 1
		local it = Item.new(id, nil, nil, mailtime)
		it.sid = dbsid( 'item', pid )
		it.pid = pid
		it.mark = Item.MARK[bagname]
		it.pos = pos
		it.bind = bind
		it.num = 1
		Item.flow(it, lab)
		_ORM'item':insert(it)
		CallPlayer(pid).BagUp{T={pos=pos, it=it}}
		onGetItem{pid=pid, it=it, id=id, num=1, bind=bind, lab=lab, old=old, new=new}
		ins[#ins+1] = it
		old = new
	end
	return true, ins
end
function Item.mail(pid, list, lab) --转邮件 TODO:lab记日志用,标题用的道具来自lab要转成玩家可识别
	Mail.send(pid, _T'[系统]', _T'道具奖励',
		mstr{_T'道具奖励来自[<<<lab>>>]', lab=LabStr( lab )}, list, lab)
end
function Item.delById(pid, id, num, lab) --按id删，实例道具禁用
	assert(pid, 'no pid')
	assert(id, 'id id')
	assert(lab, 'must lab')
	assert(num>0, 'must num>0')
	local oldbag = Item.have(pid, id)
	if oldbag<num then return false end
	local old = Item.have(pid, id, true)
	local new = old -num
	local im = cfg_item[id]
	assert(im, 'invalid itemid'..id)
	if im.nobag then
		if im.trans then
			return cfg_itemTrans[im.trans].sub(pid, num, lab)
		else
			_ORM'itemnum':where{pid=pid, id=id}:update{num=new}
			CallPlayer(pid).ItemUp{T={id=id, num=num, new=new}}
			onLossItem{pid=pid, id=id, num=num, bind=1, lab=lab, old=old, new=new}
		end
	else
		local bagname = im.bagin or 'bag'
		local pile = im.pile or 0
		if pile>0 then
			local need = num
			local maxn = Item.getMaxBlank(pid, bagname)
			local bag = Item.gets(pid, bagname)
			do--1 TODO先删限时 作为绑定
				for pos=maxn, 1, -1 do
					local it = bag[pos]
					if it and it.id==id and it.timeto~=0 and not Item.timeout( it ) and not Item.isLockBag(pid, pos) then
						if it.num>need then
							local n = it.num-need
							it = _ORM'item':where{sid=it.sid}:returning( ):update{num=n}[1]
							need = 0
							CallPlayer(pid).BagInUp{K=bagname,T={pos=pos, it=it}}
						else
							Item.realDelete(it)
							need = need - it.num
							CallPlayer(pid).BagInUp{K=bagname,T={pos=pos}}
						end
						if need==0 then break end
					end
				end
			end
			if need>0 then--2先删绑定
				for pos=maxn, 1, -1 do
					local it = bag[pos]
					if it and it.id==id and it.bind==Item.BIND.bind and not Item.timeout( it ) and not Item.isLockBag(pid, pos) then
						if it.num>need then
							local n = it.num-need
							it = _ORM'item':where{sid=it.sid}:returning( ):update{num=n}[1]
							need = 0
							CallPlayer(pid).BagInUp{K=bagname,T={pos=pos, it=it}}
						else
							Item.realDelete(it)
							need = need - it.num
							CallPlayer(pid).BagInUp{K=bagname,T={pos=pos}}
						end
						if need==0 then break end
					end
				end
			end
			local bindnum = num - need
			if bindnum > 0 then
				onLossItem{pid=pid, id=id, num=bindnum, bind=1, lab=lab, old=old, new=old-bindnum}
			end
			if need>0 then--3再删非绑
				local n = need
				for pos=maxn, 1, -1 do
					local it = bag[pos]
					if it and it.id==id and it.bind~=Item.BIND.bind and not Item.timeout( it ) and not Item.isLockBag(pid, pos) then
						if it.num>need then
							local n = it.num-need
							it = _ORM'item':where{sid=it.sid}:returning( ):update{num=n}[1]
							need = 0
							CallPlayer(pid).BagInUp{K=bagname,T={pos=pos, it=it}}
						else
							Item.realDelete(it)
							need = need - it.num
							CallPlayer(pid).BagInUp{K=bagname,T={pos=pos}}
						end
						if need==0 then break end
					end
				end
				assert(need==0, 'itemdelbyiderror1')
				onLossItem{pid=pid, id=id, num=n, bind=0, lab=lab, old=old-bindnum, new=new}
			end
		else
			if im.fixed then
				local need = num
				local maxn = Item.getMaxBlank(pid, bagname)
				local bag = Item.gets(pid, bagname)
				for pos=maxn, 1, -1 do
					local it = bag[pos]
					if it and it.id==id and not Item.timeout( it ) and not Item.isLockBag(pid, pos) then
						Item.markDelete(it, lab)
						need = need -1
						CallPlayer(pid).BagInUp{K=bagname,T={pos=pos}}
						if need==0 then break end
					end
				end
				assert(need==0, 'itemdelbyiderror2')
				onLossItem{pid=pid, id=id, num=num, bind=1, lab=lab, old=old, new=new}
			else
				error(id..'instance item must use Item.delByPos') --TODO 非叠加道具视为实例道具,只能按格位删,不能按ID批量删
			end
		end
	end
	return true
end
function Item.delByPos(pid, pos, num, lab, try) --按包位删, 计数道具不入
	assert(lab, 'must lab')
	if num<1 then return false end
	local r = _ORM'item':where{pid=pid, mark=Item.MARK.bag, pos=pos}:select()
	local it = r and r[1]
	if not it then return false end
	if Item.isLockBag(pid, pos) then return false end
	if it.num<num then return false end
	if try then return true end
	local im = cfg_item[it.id]
	local pile = im.pile or 0
	local old = Item.have(pid, it.id, true)
	local new = old-num
	if pile>0 then
		if it.num==num then--叠加的直接删了
			if lab=='sold' then	--可回购的除外
				Item._markSold(it)
			else
				Item.realDelete(it)
			end
			CallPlayer(pid).BagUp{T={pos=pos}}
		else
			it = _ORM'item':where{sid=it.sid}:returning( ):update{num=it.num-num}[1]
			CallPlayer(pid).BagUp{T={pos=pos, it=it}}
		end
		onLossItem{pid=pid, id=it.id, num=num, bind=it.bind, lab=lab, old=old, new=new}
	else --不叠加的加删标记实例保存以备查询
		if lab=='sold' then	--可回购
			Item._markSold(it)
		else
			if im.lognum > 0 then
				Item.markDelete(it, lab)
			else
				Item.realDelete(it)	--日志都不用记的清
			end
		end
		CallPlayer(pid).BagUp{T={pos=pos}}
		onLossItem{pid=pid, it=it, id=it.id, num=num, bind=it.bind, lab=lab, old=old, new=new}
	end
	return true
end
function Item.delByIdList(pid, list, lab) --批量删
	for i, v in ipairs(list) do
		if not Item.delById(pid, v[1], v[2], lab) then
			ErrHint( _T'道具不足')
		end
	end
end
function Item.delByDepotPos(pid, pos) --按仓位删X
	local r = _ORM'item':where{pid=pid, mark=Item.MARK.depot, pos=pos}:select()
	local it = r and r[1]
	local num = it.num
	local im = cfg_item[it.id]
	local pile = im.pile or 0
	local old = Item.have(pid, it.id, true)
	local new = old -num
	if pile>0 then
		Item.realDelete(it)
		CallPlayer(pid).DepotUp{T={pos=pos}}
		onLossItem{pid=pid, id=it.id, num=num, bind=it.bind, lab='deldepot', old=old, new=new}
	else --不叠加的加删标记实例保存以备查询
		if im.lognum > 0 then
			Item.markDelete(it, 'deldepot')
		else
			Item.realDelete(it)		--日志都不用记的清
		end
		CallPlayer(pid).DepotUp{T={pos=pos}}
		onLossItem{pid=pid, it=it, id=it.id, num=num, bind=it.bind, lab='deldepot', old=old, new=new}
	end
	return true
end
function Item._sortBag(pid, mark) --整理包 TODO 不是所有mark都能sort各种when{Mark='BAG'}   function AskSortItem(Mark)处理各自己CD和入口
	mark = mark or 'bag'
	assert(Item.MARK[mark], mark.. ' unreg mark')
	local its = Item.gets(pid, mark, true)
	local temp = {}
	for i, v in pairs( its ) do
		temp[#temp+1] = v
	end
	table.sort(temp, table.asc('id') )
	local i = 0
	while true do --合并
		i = i+1
		if i<#temp then
			local it = temp[i]
			if it then
				local im = cfg_item[it.id]
				local pile = im.pile or 0
				if pile>0 then
					local need = pile-it.num
					if need>0 then
						for j=#temp, i+1, -1 do --从尾
							local itr = temp[j]
							if itr and it.id==itr.id and it.bind==itr.bind and it.timeto==itr.timeto then
								if itr.num<need then--不足
									temp[i] = _ORM'item':where{sid=it.sid}:returning():update{num=it.num+itr.num}[1]
									it = temp[i]
									Item.realDelete(itr)
									temp[j] = false
									need = pile - it.num
								elseif itr.num==need then--正好
									temp[i] = _ORM'item':where{sid=it.sid}:returning():update{num=pile}[1]
									it = temp[i]
									Item.realDelete(itr)
									temp[j] = false
									break
								else --足余
									temp[i] = _ORM'item':where{sid=it.sid}:returning():update{num=pile}[1]
									it = temp[i]
									temp[j] = _ORM'item':where{sid=itr.sid}:returning():update{num=itr.num-need}[1]
									break
								end
							end
						end
					end
				end
			end
		else--没有未合并的了
			break
		end
	end
	local new = {}
	for i, it in pairs( temp ) do
		if it then
			new[#new+1] = it
		end
	end
	table.sort(new, table.asc('id'))
	for pos, it in ipairs(new) do
		_ORM'item':where{sid=it.sid}:update{pos=pos}
	end
	CallPlayer(pid).BagAllUp{K=mark, T=Item.gets(pid, mark)}
end
function Item.lockId(pid, id, label) --冻结id道具
	local lock = _ORM'itemlock':where{pid=pid, id=id}:select()
	if lock then assert(false, id..'already locked by'..lock[1].label) return end
	local lock = DefaultDB.get'itemlock'
	lock.pid = pid
	lock.id = id
	lock.label = label
	_ORM'itemlock':insert(lock)
end
function Item.unlockId(pid, id) --解冻id道具
	_ORM'itemlock':where{pid=pid, id=id}:delete()
end
function Item.isLock(pid, id) --是否冻结
	local lock = _ORM'itemlock':where{pid=pid, id=id}:select()
	return lock and true or false
end
function Item._numToGS(pid, token, id)	--同步包中总量给GS GS用于战斗等消耗判定
	if Item.NoSendNumToGS[id] then return end
	CallGsByPid( pid ).ItemNum{Token=token, Id=id, Num=Item.have(pid, id)}
end
function Item.lockBag(pid, pos)		--在线 临时冻结包位 交易等操作时用
	local c = Client.byPID(pid)
	if not c then return end
	local pid = c.getPID()
	if not pid then return end
	local it = Item.get(pid, 'bag', pos)
	if not it then return end
	assert(not c.lockbagblank[pos], 'repeat lockBag')
	c.lockbagblank[pos] = true
	CallPlayer(pid).LockBagPos{Pos=pos}
	Item._numToGS(pid, c.getToken(), it.id)--CallGsByPid( pid ).ItemNum{Token=c.getToken(), Id=it.id, Num=Item.have(pid, it.id)}
end
function Item.unlockBag(pid, pos)	--在线 解冻包位
	local c = Client.byPID(pid)
	if not c then return end
	if not pos then return end
	assert(c.lockbagblank[pos], 'repeat unlockBag')
	local it = Item.get(pid, 'bag', pos)
	if not it then return end
	c.lockbagblank[pos] = nil
	CallPlayer(pid).UnlockBagPos{Pos=pos}
	Item._numToGS(pid, c.getToken(), it.id)--CallGsByPid( pid ).ItemNum{Token=c.getToken(), Id=it.id, Num=Item.have(pid, it.id)}
end
function Item.isLockBag(pid, pos)	--在线 是否冻包
	local c = Client.byPID(pid)
	if not c then return end
	if c and c.lockbagblank[pos] then return true end
	return false
end
function Item.timeout( it )
	return it.timeto > 0 and it.timeto <=_now(0)
end
function Item.isLimit( pid, it )	--return lvlimit, sexlimit, joblimit, timeout
	local role = _ORM'player':where{ pid = pid }:select( )[1]
	assert(role, pid)
	local im = cfg_item[it.id]
	local lvlimit = im.lv and im.lv > role.level or false
	local sexlimit = im.sex and im.sex ~= role.sex or false
	local joblimit = im.job and im.job[role.job] == 0 or false
	local timeout = it.timeto > 0 and it.timeto <=_now(0)
	local uselimit

	local needwake = false
	if im.needwake then
		needwake = Wake.getWakeStep(pid) < im.needwake
	end
	return lvlimit, sexlimit, joblimit, timeout, uselimit, needwake
end
function Item.getv( it, key )	--取实例值
	for i, k in ipairs(it.key) do
		if k == key then
			return it.val[i]
		end
	end
end
function Item.setv( it, key, val )	--更新实例值
	assert(type(key)=='string', 'invalid key:'..tostring(key))
	assert(type(val)=='number', 'invalid val:'..tostring(val))
	assert(cfg_enum_item_inskey[key], key..' must define in cfg_enum_item_inskey')
	local im = cfg_item[it.id]
	assert(not im.fixed, it.id..' fixed item can not use Item.setv固定属性道具不能改实例属性')
	if it.mark == Item.MARK.bag then
		assert(not Item.isLockBag(pid, it.pos), 'lockbag')
	end
	for i, k in ipairs(it.key) do
		if k == key then
			local newval = table.newclone(it.val)
			newval[i] = val
			if it.sid == 0 then--未入库的
				it.val = newval
			else
				it = _ORM'item':where{sid=it.sid}:returning( ):update{val=newval}[1]
			end
			return it
		end
	end
	local newkey = table.newclone(it.key)
	local newval = table.newclone(it.val)
	newkey[#newkey+1] = key
	newval[#newval+1] = val
	if it.sid == 0 then--未入库的
		it.key = newkey
		it.val = newval
	else
		it = _ORM'item':where{sid=it.sid}:returning( ):update{key=newkey, val=newval}[1]
	end
	return it
end
function Item.getBagFashion( pid )
	local myequip = Item.gets(pid, 'equip')
	local bag = Item.gets(pid, 'bag')
	local myfashion = Item.gets(pid, 'wardrobe')
	local fashions = { }
	for k, v in pairs( bag ) do
		local im = cfg_item[v.id]
		if Item.FASHION[im.wear] then
			local partid = Cfg.cfg_part{ part = im.wear }[1].id
			local it = myequip[partid]
			if not fashions[im.id] and not myfashion[im.id] and ( not it or ( it and it.id ~= v.id ) ) then
				local lvlimit, sexlimit, joblimit, timeout, uselimit, needwake = Item.isLimit( pid, v )
				if not lvlimit and not sexlimit and not joblimit and not timeout and not needwake then
					fashions[im.id] = v
				end
			end
		end
	end
	return fashions
end
function Item.cd(pid, id) --CD中
	local im = cfg_item[id]
	if im.cd and im.cd > 0 then
		return Role.getCdAndSet( pid, 'item'..id, im.cd)
	end
	return false
end
function Item.addBagAndDepot(pid, bagblank, depotpage)
	local p = _ORM'player':where{ pid = pid }:select( )[1]
	if bagblank > 0 then
		local currblank = Item.BASEBAGBLANK + p.bagblankex
		for i = bagblank, 1, -1 do
			local toblank = currblank + i
			if cfg_bag[toblank] then
				local cfg = cfg_bag[currblank+1]
				local list = {{cfg.item1, cfg.num1, cfg.bind1} }
				if cfg.item2 then
					list[2] = {cfg.item2, cfg.num2, cfg.bind2}
				end
				for i = currblank + 2, toblank do
					local cfg = cfg_bag[i]
					if cfg then
						list[1][2] = list[1][2] + cfg.num1
						if list[2] then
							list[2][2] = list[2][2] + cfg.num2
						end
					else
						toblank = i
						break
					end
				end
				local cdTime = Role.getOnlineSec( pid )
				_ORM'player':where{ pid = pid }:update{ bagblankex = toblank-Item.BASEBAGBLANK }
				giveItems{ pid = pid, list= list, lab='itemslot'}
				local r = _ORM:table'playercd':where{pid=pid, k='itemslot'}:select()
				if r then --如果itemslot没解锁就addBagAndDepot会没有r
					_ORM:table'playercd':where{pid=pid, k='itemslot'}:update{ time = cdTime}
				end
				local bagblankex = _ORM:table'player':where{pid=pid}:select()[1].bagblankex
				CallPlayer( pid ).UpdateBlank{Bagblankex=bagblankex, Reward=list, Num=0, CdTime=cdTime}
				break
			end
		end
	end
	if depotpage > 0 then
		for i = depotpage, 1, -1 do
			local nextpage = p.depotpageex + i
			if cfg_depot[Item.BASEDEPOT+nextpage] then
				_ORM'player':where{ pid = pid }:update{depotpageex=nextpage}
				CallPlayer(pid).AddDepotPage{Page=nextpage}
				break
			end
		end
	end
end
function Item.getListByPack(pid, packid)
	local cfg = cfg_pack[packid]
	assert(cfg, packid..' invalid packid')
	local p = _ORM'player':where{ pid = pid }:select( )[1]
	local idx
	if cfg.sexsub then
		idx = p.sex
	elseif cfg.jobsub then
		idx = p.job
	else
		idx = math.weight(cfg.weight)
	end
	assert(idx, tostring(idx))
	local sublist = cfg['sub'..idx]
	assert(sublist, idx)
	local list = {}
	for i,v in pairs(sublist) do
		local iid, bind, rate, minn, maxn = unpack(v)
		if math.random(100) <= rate then
			local num = maxn and math.random(minn, maxn) or minn
			list[#list+1] = {iid, num, bind}
		end
	end
	return list
end
function Item.getListByDrop(pid, dropid)
	local p = _ORM'player':where{ pid = pid }:select( )[1]
	local cfg = cfg_drop[dropid]
	local list = {}
	local ready = {}
	for i,id in pairs(cfg.subs) do
		if math.random(1000)<=cfg.subr[i] then
			ready[#ready+1] = {'sub',id}
		end
	end
	if cfg.sexr and math.random(1000)<=cfg.sexr then
		ready[#ready+1] = {'sub',cfg['sexsub'..p.sex]}
	end
	if cfg.jobr and math.random(1000)<=cfg.jobr then
		ready[#ready+1] = {'sub',cfg['jobsub'..p.job]}
	end
	for i,id in pairs(cfg.items) do
		if math.random(1000)<=cfg.itemr[i] then
			local minn, maxn = cfg.itemc[i][1], cfg.itemc[i][2]
			local num = maxn and math.random(minn, maxn) or minn
			ready[#ready+1] = {'item',{id, num, cfg.itemb[i]}}
		end
	end
	if cfg.maxn and cfg.maxn>0 then
		while #ready>cfg.maxn do
			table.remove(ready, math.random(#ready))
		end
	end
	for i,v in pairs(ready) do
		if v[1] == 'sub' then
			local subs = Item.getListByDrop(pid, v[2])
			for _, vv in pairs(subs) do
				list[#list + 1] = vv
			end
		else
			list[#list + 1] = v[2]
		end
	end
	return list
end
function Item.getListByMon(pid, monid)
	local mm = cfg_mon[monid]
	local list = {}
	if mm.dpfirst then --首刀独享
		local r = math.weight(mm.weight)
		local dropid = mm.dpfirst[r]
		local l = Item.getListByDrop(pid, dropid)
		for _, vv in pairs(l) do
			list[#list + 1] = vv
		end
	end
	if mm.dplast then --末刀独享
		local r = math.weight(mm.weight)
		local dropid = mm.dplast[r]
		local l = Item.getListByDrop(pid, dropid)
		for _, vv in pairs(l) do
			list[#list + 1] = vv
		end
	end
	if mm.dpmvp then --MVP独享
		local r = math.weight(mm.weight)
		local dropid = mm.dpmvp[r]
		local l = Item.getListByDrop(pid, dropid)
		for _, vv in pairs(l) do
			list[#list + 1] = vv
		end
	end
	if mm.dphurt then --参与共享
		if mm.dphurt[1] then
			local dropid = mm.dphurt[1]
			local l = Item.getListByDrop(pid, dropid)
			for _, vv in pairs(l) do
				list[#list + 1] = vv
			end
		end
	end
	if mm.dphurts then --前三分享
		for i = 1, 3 do
			local dropid = mm.dphurts[i]
			local l = Item.getListByDrop(pid, dropid)
			for _, vv in pairs(l) do
				list[#list + 1] = vv
			end
		end
	end
	return list
end
function Item.getListByMons(pid, mons) --mons={{monid1, num1}, {monid2, num2} }
	local list = {}
	for monid, num in pairs(mons) do
		for i = 1, num do
			local l = Item.getListByMon(pid, monid)
			for _, vv in pairs(l) do
				list[#list + 1] = vv
			end
		end
	end
	return list
end
----------------------------------------------------------------
--event
when{} function loadConfig()
	DefaultDB.add( 'item', {
		sid = 0, 	--实例sid
		pid = 0, 	--玩家sid
		id = 0, 		--模板id
		mark = 0, 	--位置Item.MARK
		pos = 0, 	--位置index
		num = 1, 	--堆叠
		bind = 0, 	--绑态Item.BIND
		timeto = 0, 	--有效期至(0不限)
		time = 0, 	--更新时间(己删过久的清理)
		key = {}, 	--非通用实例key
		val = {}, 	--非通用实例val
		flow = '',	--流向记录
	} )
	DefaultDB.add( 'guilditem', {
		sid = 0, 	--实例sid
		pid = 0, 	--公会sid
		id = 0, 		--模板id
		mark = 0, 	--位置Item.MARK
		pos = 0, 	--位置index
		num = 1, 	--堆叠
		bind = 0, 	--绑态Item.BIND
		timeto = 0, 	--有效期至(0不限)
		time = 0, 	--更新时间(己删过久的清理)
		key = {}, 	--非通用实例key
		val = {}, 	--非通用实例val
		flow = '',	--流向记录
	} )
	DefaultDB.add( 'itemnum', {
		pid = 0, 	--玩家id
		id = 0, 		--模板id
		num = 0, 	--堆叠量
	} )
	DefaultDB.add( 'itemlock', {
		pid = 0, 	--玩家id
		id = 0, 		--模板id
		label = '', 	--原因
	} )
	DefaultDB.add( 'itemuse', {
		pid = 0, 	--玩家id
		id = 0, 		--道具id
		times = 0, 	--本周期己用次数
		time = 0, 	--使用时间
	} )
	DefaultDB.add( 'yb_expend', {
		sid		= 0,		--serial
		uid		= '',		--帐号account.uid
		pid		= 0,		--角色id
		gold	= 0,		--充值量
		fgold	= 0,		--充值后
		reason 	= '',		--原因
		time	= 0,		--时间
	} )
	DefaultDB.add( 'realreward', {
		sid			= 0,		--sid
		pid 		= 0,               	--玩家id
		item		= '',					--奖品名
		name		= '',					--收件人
		phone     	= '',					--电话
		address    	= '',					--地址
		time		= 0,           	--时间
	} )
	DefaultDB.add( 'itemcode', {
		sid			= 0,		--道具sid
		pid			= 0,					--玩家pid
		time		= 0,					--入库时间
		qrcode     	= '',					--二维码地址
		timeto    	= 0,					--到期时间
	} )

	dofile'config/cfg_item.lua'
	dofile'config/cfg_link.lua'
	dofile'cfg_item_trans.lua'
	--dofile'config/cfg_part.lua'
	dofile'config/cfg_enum_item_inskey.lua'
	dofile'config/cfg_enum_item_action.lua'
	dofile'config/cfg_equip_ha.lua'
	dofile'config/cfg_pack.lua'
	dofile'config/cfg_mulpack.lua'
	dofile'config/cfg_itemcost.lua'
	dofile'config/cfg_bag.lua'
	dofile'config/cfg_depot.lua'
	dofile'config/cfg_guilddepot.lua'
	dofile'config/cfg_qualityup.lua'
	dofile'config/cfg_luckpack.lua'

	dofile'config/cfg_drop.lua'
	for id,v in pairs(cfg_drop) do--转为易读格式
		v.subs = {v.sub1,v.sub2,v.sub3,v.sub4,v.sub5}
		v.subn = #v.subs
		v.subr = {v.subr1,v.subr2,v.subr3,v.subr4,v.subr5}
		assert(v.subn==#v.subr,'cfg_drop['..id..']subsCount~=subrCount')
		v.sub1,v.sub2,v.sub3,v.sub4,v.sub5 = nil,nil,nil,nil,nil
		v.subr1,v.subr2,v.subr3,v.subr4,v.subr5 = nil,nil,nil,nil,nil

		v.items = {}
		v.itemr = {}
		v.itemc = {}
		v.itemb = {}
		for ii=1,math.huge do
			local it = v['item'..ii]
			if it then
				v.items[ii] = it
				assert(v['itemr'..ii],'cfg_drop['..id..'].itemr'..ii..'does not exist')
				v.itemr[ii] = v['itemr'..ii]
				v.itemc[ii] = v['count'..ii]--{min,max}--有区随min,max，无区则min，无则1
				v.itemb[ii] = v['bind'..ii]
				v['item'..ii] = nil
				v['itemr'..ii] = nil
				v['count'..ii] = nil
				v['bind'..ii] = nil
			else
				break
			end
		end
		v.itemn = #v.items
	end
	_ORM'item':pkey( 'sid' ):index('pid'):mapping( )
end
when{} function afterConfig()
	for i=1, math.huge do
		if not cfg_bag[i] then
			Item.BASEBAGBLANK = i
		else
			break
		end
	end
end
when{} function checkConfig()
	for id, v in pairs(cfg_item) do
		assert(math.abs(id)<=UINT, 'item id is too big:'..id..'>'.. UINT) --20亿都不够你用的，int8一样能被浪暴
		if v.maxown then
			assert(v.maxown<=0xffffffff, 'item maxown is too big:'..v.maxown..'>'.. 0xffffffff)
		end
		if v.trans then
			assert(cfg_itemTrans[v.trans], 'item undefined trans:'..v.trans)
		end
		if v.titem then
			assert(cfg_item[v.titem], 'item undefined trans:'..v.titem)
		end
		if v.maxid then
			assert(cfg_item[v.maxid], 'item maxid is not itemid'..v.maxid)
		end
		if v.instance then
			for k, v in pairs(v.instance) do
				assert(cfg_enum_item_inskey[k], 'undefined item instance key:'..k)
			end
		end
		if v.action then
			assert(table.count(v.action)==1, 'action must 1') --防检查复杂度无限,限1个
			for k, v in pairs(v.action) do --防配错 白名单检查
				assert(cfg_enum_item_action[k], 'undefined item action:'..k)
			end
			if v.action.item then			--固定产出,可批量使用
				assert(cfg_item[v.action.item[1]], v.action.item[1]..'invalid item in item:'..id)
			end
			if v.action.pack then			--产物随机,避免批量使用
				assert(cfg_pack[v.action.pack], v.action.pack..'invalid pack in item:'..id)
			end
			if v.action.rechargepack then	--产物随机,避免批量使用
				assert(cfg_pack[v.action.rechargepack.pack], v.action.rechargepack.pack..'invalid pack in item:'..id)
			end
			if v.action.mulpack then		--消耗可选,不可批量使用
				assert(cfg_mulpack[v.action.mulpack], v.action.mulpack..'invalid mulpack in item:'..id)
				assert(not v.pileuse or v.pileuse<=1,'pileuse limit on action.costitem item:'..id)
			end
			if v.action.costitem then		--消耗变化,不可批量使用
				local costcfg = cfg_itemcost[v.action.costitem.costid]
				assert(costcfg, v.action.costitem.costid..'invalid costid in item:'..id)
				assert(cfg_item[v.action.costitem.item[1]], v.action.costitem.item[1]..'invalid item in item:'..id)
				if costcfg.base and costcfg.base > 0 then --可变消耗
					assert(not v.pileuse or v.pileuse<=1,'pileuse limit on action.costitem item:'..id)
				end
			end
			if v.action.costpack then		--消耗变化,不可批量使用
				local costcfg = cfg_itemcost[v.action.costpack.costid]
				assert(costcfg, v.action.costpack.costid..'invalid costid in item:'..id)
				assert(cfg_pack[v.action.costpack.pack], v.action.costpack.pack..'invalid item in pack:'..id)
				if costcfg.base and costcfg.base > 0 then --可变消耗
					assert(not v.pileuse or v.pileuse<=1,'pileuse limit on action.costpack item:'..id)
				end
			end
			if v.action.lvexp then			--产出效果变化,不可批量使用
				assert(v.pileuse<=1,'pileuse limit on action.lvexp item:'..id)
			end
			if v.action.dayitem then 		--实例计数,不可叠加; 消耗变化,不可批量使用
				assert(not v.pile or v.pile<=1,'pile limit 1 on action.dayitem item:'..id)
				assert(not v.pileuse or v.pileuse<=1,'pileuse limit on action.dayitem item:'..id)
				for day, vv in ipairs(v.action.dayitem) do
					assert(cfg_item[vv[1]], vv[1]..'invalid item in item:'..id)
					if vv[4] then
						assert(cfg_item[vv[4]], vv[4]..'invalid item in item:'..id)
					end
				end
			end
			if v.action.lucky then
				v.action.lucky.money = toint(v.action.lucky.money)
				local m = v.action.lucky.money
				assert(m>=100 and m<=20000, m..' action.lucky.money must in range[100,20000] item:'..id)
				assert(type(v.action.lucky.wishing)=='string', 'action.lucky.wishing require in item:'..id)
				assert(type(v.action.lucky.name)=='string', 'action.lucky.name require in item:'..id)
				assert(type(v.action.lucky.activity)=='string', 'action.lucky.activity require in item:'..id)
			end
			if v.action.luckyid then
				assert(not v.pile or v.pile<=1,'pile limit 1 on action.luckyid item:'..id)
			end
		end
		for i=1, math.huge do
			if v['ba'..i] then
				assert(v['bav'..i], 'have ba but no bav'..i)
				if v.fixed then --绝对固定属性
					if #v['bav'..i]>1 then
						assert(v['bav'..i][1]==v['bav'..i][2], id..'fixed equip must no random attribute ba')
					end
				else
					assert(not(v.pile and v.pile>0), id..'no fixed equip must no pile')
				end
			else break
			end
		end
		for i=1, math.huge do
			if v['ha'..i] then
				for i, hid in pairs(v['ha'..i]) do
					assert(cfg_equip_ha[hid], hid..'invalid cfg_equip_ha id in item'..id)
				end
				assert(v['hawt'..i] and #v['ha'..i] == #v['hawt'..i], 'hawt error in item'..id)
				if v.fixed then --绝对固定属性
					assert(table.count(v['ha'..i])<=1, id..' fixed equip must no random attribute ha')
				else
					assert(not(v.pile and v.pile>0), id..'no fixed equip must no pile')
				end
			else break
			end
		end
		if v.bagin then
			assert(Item.MARK[v.bagin], v.bagin..' undefined bag')
			if v.bagin == 'wingspiritbag' then --翅魂有吞吃不可叠加
				assert(not(v.pile and v.pile>0), id..'bag in item must no pile')
			end
		end

		if v.job1 then --职业转义
			for i = 1, math.huge do
				local tid = v['job'..i]
				if tid then
					assert(cfg_item[tid], tid..' invalid job item id in item '..id)
				else break
				end
			end
		end
		if v.linkid then
			assert(v.linklv, 'item have linkid but no linklv '..id)
			assert(cfg_link[v.linkid..'_'..v.linklv], 'invalid link '..v.linkid..'_'..v.linklv)
		end
		if v.wear == 'wingspirit' then
			assert(v.exp, id.. ' wingspirit item no exp')
		end
		if v.wear then
			local kk = string.split(v.wear, '_')
			if kk then
				if kk[1] == 'horcrux' then
					assert(v.hllv, id.. ' item no hllv')
				elseif kk[1] == 'crossbow' then
					assert(v.dnlv, id.. ' item no dnlv')
				end
			end
		end
	end
	for sid, v in pairs(cfg_link) do
		for k, vv in pairs(v.attr) do

		end
	end
	_G.cfg_link = nil
	for i, v in pairs(cfg_equip_ha) do
		--id:ip>	ak:s<>	av:i<>	weight:i<>	name:s-<>
	end
	for id, v in pairs(cfg_pack) do
		assert(math.abs(id)<=UINT, 'cfg_pack id is too big:'..id..'>'.. UINT) --20亿都不够你用的，int8一样能被浪暴
		local subn = 0
		for i2 = 1, math.huge do
			local sub = v['sub'..i2]
			if sub then
				subn = i2
				for i3, v3 in pairs(sub) do
					assert(cfg_item[v3[1]], tostring(v3[1])..' invalid item in cfg_pack'..id)
				end
			else break
			end
		end
		if v.sexsub then
			assert(v.sub1, 'cfg_pack sexsub no sub1')
			assert(v.sub2, 'cfg_pack sexsub no sub2')
		elseif v.jobsub then
			for job, _ in pairs(Role.JOB) do
				assert(v['sub'..job], 'jobpack need sub'..job)
			end
		else
			if v.weight then
				assert(subn == #v.weight, '#v.weight ~= subnum in cfg_pack'..id)
			end
		end
		if v.wish then
			assert(v.wish[1]==0 or v.wish[1]==1, 'cfg_pack wish[1] must 0/1')
			assert(v.wish[2]>0 , 'cfg_pack wish[2] must>0')
			local sub = v['sub'..v.wish[3]]
			assert(sub, 'cfg_pack wish[3] must have sub..'..v.wish[3])
			assert(#sub==1, 'wish sub must #sub=1')
			assert(sub[1][3]==100, 'wish sub must rate=100')
		end
	end
	for id, v in pairs(cfg_mulpack) do
		assert(math.abs(id)<=UINT, 'cfg_pack id is too big:'..id..'>'.. UINT) --20亿都不够你用的，int8一样能被浪暴
		assert(v.pack1, 'mulpack must have pack1 at least')
		for i=1,math.huge do
			local packid = v['pack'..i]
			if packid then
				assert(cfg_pack[packid], packid ..' invalid packid in cfg_mulpack'..id)
				if v['need'..i] then
					assert(cfg_item[v['need'..i]], v['need'..i] ..' invalid packid in cfg_mulpack'..id)
				end
			else break
			end
		end
	end
	for id, v in pairs(cfg_itemcost) do
		if v.need and v.need > 0 then
			assert(cfg_item[v.need], v.need..' invalid needitem in cfg_itemcost')
		end
		assert(v.circle == 'daily' or v.circle == 'weekly', v.circle..' circle only support daily and weekly')
	end

	for job, je in pairs(cfg_createequip) do
		local have = {}
		for i, id in pairs(je) do
			local im = cfg_item[id]
			assert(im.wear, 'cfg_createequip no im.wear:'..id)
			local wearpos = Cfg.cfg_part{ part = im.wear }[1].id
			assert(not have[wearpos], 'cfg_createequip have >2 wearpos:'..wearpos)
		end
	end

	local openbagitem1, openbagitem2, openbaggold
	for i, v in pairs(cfg_bag) do
		openbagitem1 = openbagitem1 or v.item1
		openbaggold = openbaggold or v.gold
		assert(cfg_item[v.item1], v.item1..' item undefined cfg_bag')
		assert(v.item1==openbagitem1, 'cfg_bag reward item must equal')
		if v.item2 then
			openbagitem2 = openbagitem2 or v.item2
			assert(cfg_item[v.item2], v.item2..' item undefined cfg_bag')
			assert(v.item2==openbagitem2, 'cfg_bag reward item must equal')
		end
		assert(v.gold==openbaggold, 'cfg_bag reward gold must equal')
	end
	for i, v in pairs(cfg_depot) do
		assert(cfg_item[v.item], v.item..' item undefined cfg_depot')
	end
	for id, v in pairs(cfg_qualityup) do
		assert(cfg_item[id], id..' item undefined cfg_qualityup')
		assert(cfg_item[v.item], v.item..' item undefined cfg_qualityup')
		assert(cfg_item[v.tid], v.tid..' item undefined cfg_qualityup')
	end
	_G.cfg_qualityup = nil
	for k, v in pairs( Cfg.cfg_equip{ } ) do
		local cfg = Cfg['cfg_qualityup_'..k]{}
		if cfg then
			for id, vv in pairs(cfg) do
				assert(cfg_item[vv.tid], vv.tid..' invalid item in cfg_qualityup_'..k)
				assert(cfg_item[vv.item], vv.item..' invalid item in cfg_qualityup_'..k)
				if vv.item1 then
					assert(cfg_item[vv.item1], vv.item1..' invalid item in cfg_qualityup_'..k)
					assert(vv.count1, id..' no vv.count1 in cfg_qualityup_'..k)
				end
			end
		end
	end
	for i, v in pairs(cfg_luckpack) do
		assert(#v.weight==#v.luckn, '#weight==#luckn in cfg_luckpack['..i)
		for ii=1,math.huge do
			if v['item'..ii] then
				assert(cfg_item[v['item'..ii]], v['item'..ii]..' invalid itemid in cfg_luckpack')
			else break
			end
		end
	end
end
when{} function cleanupUser(pid)
	_SQL:run('delete from item where pid=$1', pid)
	_SQL:run('delete from itemnum where pid=$1', pid)
	_SQL:run('delete from itemlock where pid=$1', pid)
	_SQL:run('delete from itemuse where pid=$1', pid)
end
when{} function onCreateRole(sid, uid, pid, info)
	if info._robot then return end
	local je = cfg_createequip[info.player.job]
	for i, id in pairs(je) do
		local im = cfg_item[id]
		local it = Item.new(id)
		it.sid = dbsid( 'item', pid )
		it.pid = pid
		it.mark = Item.MARK.equip
		it.pos = Cfg.cfg_part{ part = im.wear }[1].id
		it.bind = Item.BIND.bind
		it.num = 1
		Item.flow(it, 'createequip')
		_ORM'item':insert(it)
		onGetItem{pid=pid, id=id, num=1, bind=1, lab='rolecreate'}
	end
end
when{} function onRoleLogin(pid)
	local c = Client.byPID( pid )
	if c then
		Item._init(c)
		Deal.cancel( pid )
	end
end
when{} function getUserInfo(uid, pid, info, step)
	info.equip = Item.gets(pid, 'equip')
	info.tequip = Item.gets(pid, 'tequip')
	info.tequiprune = Item.gets(pid, 'tequiprune')
	info.bag = Item.gets(pid, 'bag')
	info.wardrobe = Item.gets(pid, 'wardrobe')

	for k, v in pairs( Cfg.cfg_equip{ } ) do
		info['equip_'..k] = Item.gets(pid, k)
	end
	info.itemnum = Item.getItemNum(pid)
	for key, v in pairs(cfg_itemTrans) do
		if v.id then
			info.itemnum[v.id] = v.have(pid)
		end
	end

	if step=='login' then --上线,GS不用的都放这里 (如果太多就做成异步)
		info.depot = Item.gets(pid, 'depot')
		info.horcruxbag = Item.gets(pid, 'horcruxbag')
		info.crossbowbag = Item.gets(pid, 'crossbowbag')
		info.mengpetbag = Item.gets(pid, 'mengpetbag')
		info.tequiprunebag = Item.gets(pid, 'tequiprunebag')
		info.qlbbag = Item.gets(pid, 'qlbbag')
		info.artifactbag = Item.gets(pid, 'artifactbag')
		info.cloakbag = Item.gets(pid, 'cloakbag')
		info.holybag = Item.gets(pid, 'holybag')

		local iu =  _ORM'itemuse':where{ pid = pid }:select( )
		info.itemuse = {}
		if iu then
			for _, v in pairs(iu) do
				info.itemuse[v.id] =v
			end
		end
		local c = Client.byPID( pid )
		if c then
			info.lockbagblank = c.lockbagblank
		end
	end
end

when{} function onGetItem(pid, it, id, num, bind, lab, old, new)
	--Log.sys('onGetItem',pid, it, id, num, bind, lab, old, new)
	assert(num>0, 'onGetItemNum0_lab='..lab)
	local c = Client.byPID(pid)
	local im = cfg_item[id]
	if im.lognum > 0 and num >= im.lognum then
		CYLog.log( 'item_log', { itemid = id, opid = LabStr( lab ), lab = lab, amount = num, bind=bind, new=new }, c )
	end
	sumItem{pid=pid,id=id, num=num, lab=lab}
	if not c then return end
	if not im.wear then --TODO:装备类不能按ID删, 给GS数量无意义
		Item._numToGS(pid, c.getToken(), id)--CallGsByPid( pid ).ItemNum{Token=c.getToken(), Id=id, Num=new}
	end
	if id ~= Item.EXP then
		CallPlayer(pid).NewItem{Id=id, New=num, Lab=lab}
	end

end
when{} function onLossItem(pid, it, id, num, bind, lab, old, new)
	assert(num>0, 'onLossItemNum0_lab='..lab)
	local c = Client.byPID(pid)
	local im = cfg_item[id]
	if im.lognum > 0 and num >= im.lognum then
		CYLog.log( 'item_log', { itemid = id, opid = LabStr( lab ), lab = lab, amount = -num, bind=bind, old=old, new=new }, c )
	end

	if not c then return end
	if not im.wear then --TODO:装备类不能按ID删, 给GS数量无意义
		Item._numToGS(pid, c.getToken(), id)--CallGsByPid( pid ).ItemNum{Token=c.getToken(), Id=id, Num=new}
	end
	_zdm('onLossItem_________', old, new)
	if new > old then
		_zdm('onLossItem__2', old, new )
		_zdm(debug.traceback() )
	end
	if id ~= Item.EXP then
		CallPlayer(pid).NewItem{Id=id, New=-num, Lab=lab}
	end
end
when{} function onGetCoin(pid, num, lab, old, new)
	local c = Client.byPID(pid)
	if num > 10000 then
		CYLog.log( 'gold', { num = num, status = LabStr( lab ), lab = lab, new=new }, c )
	end
	sumItem{pid=pid,id=Item.COIN, num=num, lab=lab}
end
when{} function onLossCoin(pid, num, lab, old, new)
	local c = Client.byPID(pid)
	if num > 10000 then
		CYLog.log( 'gold', { num = -num, status = LabStr( lab ), lab = lab, new=new }, c )
	end
end
when{} function onGetCoinB(pid, num, lab, old, new)
	local c = Client.byPID(pid)
	if num > 10000 then
		CYLog.log( 'gold', { num = num, status = LabStr( lab ), lab = lab, new=new, b=1 }, c )
	end
	sumItem{pid=pid,id=Item.COINB, num=num, lab=lab}
end
when{} function onLossCoinB(pid, num, lab, old, new)
	local c = Client.byPID(pid)
	if num > 10000 then
		CYLog.log( 'gold', { num = -num, status = LabStr( lab ), lab = lab, new=new, b=1 }, c )
	end
end
when{} function onGetGold(pid, num, lab, old, new, acc, cost)
	local c = Client.byPID(pid)
	if lab ~= 'recharge' then
		local level = Role.getLevel( pid )
		CYLog.log( 'yb_income', { amount = num, balance = new, level = level, reason = LabStr( lab ), lab = lab, accgold=acc, acccost=cost }, c )
	end
	sumItem{pid=pid,id=Item.GOLD, num=num, lab=lab}
	if c then
		CallGsByPid( pid ).GSRoleGoldChange{Token=c.getToken(), T={gold=new, accgold=acc, costgold=cost} }
		--CallGsByPid( pid ).ItemNum{Token=c.getToken(), Id=Item.GOLD, Num=new}
	end
end
when{} function onLossGold(pid, num, lab, old, new, acc, cost)
	local c = Client.byPID(pid)
	local level = Role.getLevel( pid )
	CYLog.log( 'yb_expend', { amount = num, balance = new, level = level, reason = LabStr( lab ), lab = lab, accgold=acc, acccost=cost }, c )

	-- local uid = c.getUID()
	-- local y = DefaultDB.get'yb_expend'
	-- y.sid = dbsid( 'yb_expend', pid )
	-- y.uid = uid
	-- y.pid = pid
	-- y.gold = num
	-- y.fgold = new
	-- y.reason = lab
	-- y.time = _now(0)
	-- _ORM'yb_expend':insert(y)
	if c then
		CallGsByPid( pid ).GSRoleGoldChange{Token=c.getToken(), T={gold=new, accgold=acc, costgold=cost} }
		--CallGsByPid( pid ).ItemNum{Token=c.getToken(), Id=Item.GOLD, Num=new}
	end
end
when{} function onGetGoldP(pid, num, lab, old, new)
	local c = Client.byPID(pid)
	local im = cfg_item[Item.GOLDP]
	if im.lognum > 0 and num >= im.lognum then
		CYLog.log( 'item_log', { itemid = Item.GOLDP, opid = LabStr( lab ), lab = lab, amount = num, new=new }, c )
		CYLog.log( 'giftmoney', { num = num, status = LabStr( lab ), lab = lab }, c )
	end
	sumItem{pid=pid,id=Item.GOLDP, num=num, lab=lab}
end
when{} function onLossGoldP(pid, num, lab, old, new)
	local c = Client.byPID(pid)
	local im = cfg_item[Item.GOLDP]
	if im.lognum > 0 and num >= im.lognum then
		CYLog.log( 'item_log', { itemid = Item.GOLDP, opid = LabStr( lab ), lab = lab, amount = -num, new=new }, c )
		CYLog.log( 'giftmoney', { num = -num, status = LabStr( lab ), lab = lab }, c )
	end
end

when{} function onStart() --删除己删除超期道具
	Log.sys('>>cleanup deleted items...')
	if Item.DELETEMETHOD == 'MARK' then --标记式
		_SQL:run('delete from item where mark=any($1) and time<$2',
			{Item.MARK.del, Item.MARK.sold}, _now(0) - Item.CLEANTIME)
	elseif Item.DELETEMETHOD == 'MOVE' then --标记式
		_SQL:run('delete from item where mark=any($1) and time<$2',
			{Item.MARK.del, Item.MARK.sold}, _now(0) - Item.CLEANTIME) --Item.CLEANTIME后改为只处理Item.MARK.sold的

		_SQL:run('delete from item_del where time<$1', _now(0) - Item.CLEANTIME)
		_SQL:run('insert into item_del select * from item where mark=$1', Item.MARK.del)
		_SQL:run('delete from item where mark=$1', Item.MARK.del)
	else error(Item.DELETEMETHOD)
	end
end
when{} function afterMerge()
	_SQL:run[[truncate itemwish;]]
end

--global use
cdefine.ignore.giveItem{pid=0, id=0, num=0, bind=Item.BIND.bind, lab='', mail=true, try=false, mailtime=0}
cdefine.ignore.giveItems{pid=0, list={}, lab='', mail=true, try=false, mailtime=0}
cdefine.ignore.giveEquip{pid=0, id=0, bind=Item.BIND.bind, mark='', pos=0, lab='', mail=true, try=false} --pos=0auto
when{} function giveItem(pid, id, num, bind, lab, mail, try, mailtime)
	assert(pid ~= 0, 'pid error')
	assert(lab ~= '', 'lab error')
	assert(num > 0, 'num error' .. num)
	return Item._add(pid, id, num, bind, lab, mail, try, mailtime)
end
when{} function giveItems(pid, list, lab, mail, try, mailtime)
	assert(pid ~= 0, 'pid error')
	assert(lab ~= '', 'lab error')
	if #list==0 then return true end
	if #list==1 then
		local v = list[1]
		local id = toint(v[1] or v.id)
		local num = toint(v[2] or v.num or 1)
		local bind = toint(v[3] or v.bind or 1)
		return Item._add(pid, id, num, bind, lab, mail, try, mailtime)
	else
		return Item._adds(pid, list, lab, mail, try, mailtime)
	end
end
when{} function giveEquip(pid, id, bind, mark, pos, lab, mail, try)
	assert(pos == toint(pos), 'pos must int '..pos)
	assert(pid ~= 0, 'pid error')
	if bind==Item.BIND.usebind then bind=Item.BIND.bind end
	assert(lab ~= '', 'lab error')
	local im = cfg_item[id]
	assert(im, 'giveEquip invalid item id '..id)
	local piletime = im.piletime
	local limitmin = im.limitmin
	if im.job1 then --职业转义
		local role = _ORM'player':where{ pid = pid }:select( )[1]
		id = im['job'..role.job]
		assert(id, 'job1 but no job'..role.job)
		im = cfg_item[id]
	end
	if mark == '' then
		local wear = im.wear
		if wear == 'wingspirit' then
			mark = 'wingspirit'
		else
			local To = Cfg.cfg_part{ part = wear }
			if To then
				mark = 'equip'
			else
				local t = string.split( wear, '_')
				if t[1] and t[2] then
					mark = t[1]
					pos = toint(pos)
					if not pos then return false end
				end
			end
		end
	end
	local itmark = Item.MARK[mark]
	assert( itmark, 'invalid Item.MARK:'..mark )
	local itnew = Item.new(id)
	if piletime then --TODO 隐患,叠时道具只能在没有的时候才能给成
		local r = _ORM'item':where{pid=pid, id=itnew.id}:select()
		if r then
			return false
		end
	end
	local giveit = function()
		itnew.sid = dbsid( 'item', pid )
		itnew.pid = pid
		itnew.mark = itmark
		itnew.pos = pos
		itnew.bind = bind
		itnew.num = 1
		if limitmin then
			itnew.timeto = (_now(60) + limitmin) * 60000000
		end
		Item.flow(itnew, 'giveequip_'..lab)
		_ORM'item':insert(itnew)
		onGetItem{pid=pid, id=id, num=1, bind=bind, lab='rolecreate'}
	end
	local c = Client.byPID(pid)
	if mark=='equip' then--normal 1种wear对1装位
		local To = Cfg.cfg_part{ part = im.wear }
		assert(To, 'invalid wear '..im.wear)
		To = To[1]
		assert(To, 'invalid wear '..im.wear)
		pos = To.id
		local oldit = Item.get(pid, mark, pos)
		if oldit then return false end
		if try then return true end
		giveit()
		CallPlayer(pid).EquipUp{T={pos=pos, it=itnew}}
		onEquip{pid=pid, pos=pos, it=itnew}
		if c then
			CallGsByPid( pid ).Equip{Token=c.getToken(), Pos=pos, It=itnew}
		end
	elseif mark=='wingspirit' then --翅魂 1种对多装位
		local max = Item.getMaxBlank(pid, mark)
		if pos == 0 then --atuo
			for i=1, max do
				local oldit = Item.get(pid, mark, i)
				if not oldit then
					pos = i
					break
				end
			end
			if pos == 0 then return false end
		else
			if pos < 1 or pos > max then error(pos..'not in [pos, maxpos]'..max) end
			local oldit = Item.get(pid, mark, pos)
			if oldit then return false end
		end
		if try then return true end
		giveit()
		CallPlayer(pid).WingSpiritUp{T={pos=pos, it=itnew}}
		if c then
			CallGsByPid( pid ).WingSpiritUp{Token=c.getToken(), T={pos=pos, it=itnew}}
		end
	else
		local ecfg = Cfg.cfg_equip[mark]
		if ecfg then	--1种wear对1装位
			local max = ecfg.num
			pos = toint( string.gsub( im.wear, mark..'_', '' ) )
			assert(pos<=max, 'no wear pos '..im.wear)
			local oldit = Item.get(pid, mark, pos)
			if oldit then return false end
			if try then return true end
			giveit()
			CallPlayer( pid ).ComEquipUp{T={key=mark,pos=pos, it=itnew}}
			if c then
				CallGsByPid( pid ).ComEquip{Token=c.getToken(), Pos=pos, It=itnew, Key=mark}
			end
		else --未做或不可自动装的
			error('invalid equip mark '..mark)
		end
	end
	return true
end

--RPC from gs------------------------
cdefine.gs.GSGiveItems{ Token = '', List = { }, Lab = '' }
cdefine.gs.GSDelItems{ Token = '', List = { }, Lab = '' }
cdefine.gs.NpcWelfare{ Token = '', Key='', List = { }, Circle='daily', Lab = '' }
cdefine.gs.GiveItemByPicks{Token='', T=EMPTY, ZoneID=0}
cdefine.gs.DelItemById{Token='', Id=0, Num=0, Lab=''}
cdefine.gs.ConsumeItem{Token='', Pos=0, Id=0, Num=0, Sid=0, Sel=0, Lab=''}
cdefine.gs.SendMonDropMail{Token='', Texts=EMPTY, List=EMPTY, Lab=''}

when{ } function GSGiveItems( Token, List, Lab ) -- ( param, net, id )
	local c = Client.byToken( Token )
	if not c then return end
	local r = giveItems{ pid = c.getPID(), list = List, lab = Lab, mail = true }

	CallGsByPid( c.getPID() ).GiveItemsBack{ Token = c.getToken(), Lab = Lab }
end
when{ } function GSDelItems( Token, List, Lab ) -- = function( param, net, id )
	local c = Client.byToken( Token )
	if not c then return end
	local flag = true
	for _, v in ipairs( List ) do
		if Item.have( c.getPID(), v[1] ) < v[2] then
			CallPlayer( c.getPID() ).Warn{ Msg = _T'材料不足' }
			flag = false
			break
		end
	end

	if flag then
		for _, v in ipairs( List ) do
			Item.delById( c.getPID(), v[1], v[2], Lab )
		end
	end

	CallGsByPid( c.getPID() ).DelItemsBack{ Token = c.getToken(), Result = flag, Lab = Lab }
end

when{ } function NpcWelfare(Token, Key, List, Circle, Lab)
	local c = Client.byToken( Token )
	if not c then return end
	local pid = c.getPID()
	if Role.getDaily(pid, Key) then return end
	if giveItems{ pid = pid, list = List, lab = Lab, mail = false } then
		Role.setDaily(pid, Key, _now(0), Circle=='daily' )
		CallPlayer(pid).ShowRewards{List=List}
	else
		CallPlayer(pid).Msg{K='baglimit'}
	end
end

when{} function GiveItemByPicks(Token, T, ZoneID)
	if _from == Cross.getNet() then
		Log.sys('Cross_getNet_from')
	end
	local c = Client.byToken(Token)
	if not c then return end
	local pid = c.getPID()
	local name = c.getName()
	local rlist = {}
	for i, t in pairs(T) do
		local r, ins
		if pid then
			if cfg_zone[ZoneID].type==0 then -- 防沉迷
				for _, v in pairs(t.list) do
					v[2] = AntiAddiction.getNum(pid, v[1], v[2], 'pickup_pre')
				end
				for ii = #t.list, 1, -1 do
					local v = t.list[ii]
					if v[2] <= 0 then
						table.remove(t.list, ii)
					end
				end
			end
			if #t.list == 0 then
				r = true
			else
				r, ins = Item._adds(pid, t.list, 'pickup', t.mail)
				-- if t.applypart and t.applypart > 0 then--策划加成参数给客户端显示用

				-- end
				if t.from and t.from[1]=='mon' then
					local monid = t.from[2]
					local itemid = t.list[1][1]
					if Cfg.cfg_pickupnotice{itemid=itemid, monid=monid} then
						local T = { event = 'pickupdrop', name=name,item=ins[1], monid=monid }
						CallOnline( ).EventNotice{ T = T }
						--CallOnline( ).EventNotice{ T ={ event ='kill_item', name = name, from=monid,get=ins[1] } }
					end
				end
			end
		end
		if r then
			rlist[t.guid] = 1
		else
			rlist[t.guid] = 0
		end
	end
	CallGsByPid(pid).PickUpResult{Result=rlist}	--TODO 原用_from不能用CallGsByPid, pid不存在时也要来源要处理可拾取锁 但因为中转proxy不能用_from,GS3分钟会清理
end

when{} function DelItemById(Token, Id, Num, Lab)
	local c = Client.byToken(Token)
	if not c then return end
	local pid = c.getPID()
	if Item.delById(pid, Id, Num, Lab) then
	else
		Item._numToGS(pid, c.getToken(), Id)--CallGsByPid( pid ).ItemNum{Token=c.getToken(), Id=Id, Num=Item.have(pid, Id)}
	end
end

when{} function ConsumeItem(Token, Pos, Id, Num, Sid, Sel, Lab)
	_zdm('<<ConsumeItem',Pos, Id, Num, Sid, Sel, Lab)
	local c = Client.byToken(Token)
	if not c then return end
	local pid = c.getPID()
	local im = cfg_item[Id]
	if not im then return end
	local it = Item.get(pid, 'bag', Pos)
	if not it then return end
	if it.sid ~= Sid then return end
	--check condition
	local condition = im.condition

	if im.checkunlock then
		if not LockMgr.isUnlock( pid, im.checkunlock ) then
			LockMgr.unlock( pid, im.checkunlock )
		end
	end

	local action = im.action
	for k, v in pairs(action) do --checkaction
		local f1 = cs_itemActionc[k]
		if f1 then
			local ok, res = f1( c, Id, k, v, Num, Sel, it )
			-- assert( ok, res or 'use fail' )
			if not ok then
				_wl( res or 'use fail', debug.traceback( ) )
				return
			end
		end
	end
	for k, v in pairs(action) do --doaction
		local f = cs_itemAction[k]
		Log.sys('cs_itemAction_'..k, pid, Id, Num)
		if f then
			f(c, Id, k, v, Num, Sel, it)
		end --没有的可能是gs_itemAction
	end
	if action.dayitem or action.luckyid then --实例计次cs_itemAction内部处理删除

	else --可直接删除的
		assert(Item.delByPos(pid, Pos, Num, Lab), 'delByPosError')
	end
	Item._numToGS(pid, c.getToken(), Id)--CallGsByPid( pid ).ItemNum{Token=c.getToken(), Id=Id, Num=Item.have(pid, Id)}
end

when{} function SendMonDropMail(Token, Texts, List, Lab)
	local c = Client.byToken(Token)
	if not c then return end
	local pid = c.getPID()
	Mail.send(pid, _T'[系统]', Texts[1] or '', Texts[2] or '', List, Lab)
end

--RPC from client-------------------------
cdefine.c.AskUseItem{Pos=0, Num=0, Sid=0, Sel=0}
cdefine.c.AskAddDepot{}
cdefine.c.AskSortItem{Mark=''}
cdefine.c.AskDelItem{Mark='', Pos=0, Sid=0}
cdefine.c.AskSplitItem{Mark='', Pos=0, Num=0, Sid=0}
cdefine.c.AskMoveItem{Type='', From=0, To=0, Sid=0, Num=0, Lab='' } --Num除公会仓库,都要整格操作
cdefine.c.AskGetBlank{ To = 0 }
cdefine.c.AskLockItem{ Mark='', Pos=0, Sid = 0, Lock=1 } --锁定实例(暂只有神魂用)
cdefine.c.AskEquipStepUp{Key='', Pos=0, Sid=0}

when{} function AskLockItem(Mark, Pos, Sid, Lock)
	if Mark ~= 'wingspiritdepot' and Mark ~= 'wingspiritbag' then return end --(暂只有神魂用)
	local c = Client.byNet(_from)
	local pid = c.getPID()
	local it = Item.get(pid, Mark, Pos)
	if not it then return end
	if it.sid ~= Sid then return end
	if Lock == 1 then
		if Item.getv(it, 'lock')==1 then return end
		it = Item.setv(it, 'lock', 1)
	else
		if Item.getv(it, 'lock')~=1 then return end
		it = Item.setv(it, 'lock', 0)
	end
	if Mark == 'wingspiritbag' then
		CallPlayer(pid).WingSpiritBagUp{T={pos=Pos, it=it}} --(暂只有神魂用)
	elseif Mark == 'wingspiritdepot' then
		CallPlayer(pid).WingSpiritDepotUp{T={pos=Pos, it=it}} --(暂只有神魂用)
	end
end
when{} function AskUseItem(Pos, Num, Sid, Sel)
	_zdm('<<AskUseItem',Pos, Num, Sid, Sel)
	local c = Client.byNet(_from)
	local pid = c.getPID()
	if not pid then return end
	if Item.isLockBag(pid, Pos) then return end
	local it = Item.get(pid, 'bag', Pos)
	if not it then return end
	if it.sid~=Sid then return end
	Num = Num or 1
	if it.num<Num then return end
	if not cfg_item[it.id].usenolock then
		if Security.locked(c) then return end
	end
	_zdm('>>AskConsumeItem',it.id, Pos, Num, Sid, Sel)
	local getincd = Item.getv( it, 'getincd' )
	if getincd and _now(1) < getincd then return end
	if Item.cd(pid, it.id) then return end
	CallGsByPid( pid ).AskConsumeItem{Token=c.getToken(), Id=it.id, Pos=Pos, Num=Num, Sid=Sid, Sel=Sel}
end
when{} function AskAddDepot()
	local c = Client.byNet(_from)
	local pid = c.getPID()
	if not pid then return end
	local p = _ORM'player':where{ pid = pid }:select( )[1]
	local nextpage = p.depotpageex + 1
	local cfg = cfg_depot[Item.BASEDEPOT+nextpage]
	if not cfg then return end
	if not Item.delById(pid, cfg.item, cfg.num, 'AddDepot') then return end
	_ORM'player':where{ pid = pid }:update{depotpageex=nextpage}
	CallPlayer(pid).AddDepotPage{Page=nextpage}
end
when{} function AskGetBlank( To )
	--_zdm('AskGetBlank___', To)
	local c = Client.byNet(_from)
	local pid = c.getPID()
	if not pid then return end
	local p = _ORM'player':where{ pid = pid }:select( )[1]
	local currblank = Item.BASEBAGBLANK + p.bagblankex
	local nextblank = currblank + 1
	local cfg = cfg_bag[nextblank]
	if not cfg then return end
	local r = _ORM:table'playercd':where{pid=pid, k='itemslot'}:select()
	local onlinesec = Role.getOnlineSec( pid )
	local cdTime
	local list
	local rewardnum
	if To == 0 then --自然冷却解锁
		local gone = onlinesec - r[1].time
		if gone < cfg.min*60 then return end
		_ORM'player':where{ pid = pid }:update{ bagblankex = p.bagblankex+1}
		list = {{cfg.item1, cfg.num1, cfg.bind1} }
		if cfg.item2 then
			list[2] = {cfg.item2, cfg.num2, cfg.bind2}
		end
		giveItems{ pid = pid, list= list, lab='itemslot'}
		cdTime = r[1].time + cfg.min*60
		_ORM:table'playercd':where{pid=pid, k='itemslot'}:update{ time = cdTime}
	else	--花钱解锁
		if Security.locked(c) then return end
		if To <= currblank then return end
		local rm = r[1].time + cfg.min*60 - onlinesec
		local sec = rm > 0 and rm or 0
		local gold = math.ceil(sec/60/cfg.permin) * cfg.costgold
		list = {{cfg.item1, cfg.num1, cfg.bind1} }
		if cfg.item2 then
			list[2] = {cfg.item2, cfg.num2, cfg.bind2}
		end
		for i = currblank + 2, To do
			local cfg = cfg_bag[i]
			if cfg then
				gold = gold + math.ceil(cfg.min/cfg.permin) * cfg.costgold
				list[1][2] = list[1][2] + cfg.num1
				if list[2] then
					list[2][2] = list[2][2] + cfg.num2
				end
			else
				To = i
				break
			end
		end
		cdTime = onlinesec
		if gold > 0 and not Item.delById( pid, cfg.gold, gold, 'itemslot') then return end
		_ORM'player':where{ pid = pid }:update{ bagblankex = To-Item.BASEBAGBLANK }
		giveItems{ pid = pid, list= list, lab='itemslot'}
		_ORM:table'playercd':where{pid=pid, k='itemslot'}:update{ time = cdTime}
	end
	local bagblankex = _ORM:table'player':where{pid=pid}:select()[1].bagblankex
	CallPlayer( pid ).UpdateBlank{Bagblankex=bagblankex, Reward=list, Num=rewardnum, CdTime=cdTime}
end

when{Mark='BAG'}   function AskSortItem(Mark)
	local c = Client.byNet(_from)
	if not c then return end
	if Cd(c, 'sortbag', Item.BAGSORTCD) then return end --处理CD
	if table.count(c.lockbagblank)>0 then return end --交易锁定
	Item._sortBag(c.getPID(), 'bag')
end
when{Mark='DEPOT'} function AskSortItem(Mark)
	local c = Client.byNet(_from)
	if Cd(c, 'sortdepot', Item.DEPOTSORTCD) then return end --处理CD
	Item._sortBag(c.getPID(), 'depot')
end

when{_order=0}   function AskDelItem(Mark, Pos, Sid, _args)
	if Pos~=toint(Pos) then _args._stop=true end
end
when{Mark='BAG'}   function AskDelItem(Mark, Pos, Sid)
	local pid = PIDByNet(_from)
	if not pid then return end
	local it = Item.get(pid, 'bag', Pos)
	if not it then return end
	if Item.isLockBag(pid, Pos) then return end
	if it.sid~=Sid then return end
	if cfg_item[it.id].nodel then return end --不可销毁
	if Item.isLock(pid, it.id) then p.Msg{K='itemlocked'} end
	Item.delByPos(pid, Pos, it.num, 'delbag')
end
when{Mark='DEPOT'} function AskDelItem(Mark, Pos, Sid)
	local pid = PIDByNet(_from)
	if not pid then return end
	local it = Item.get(pid, 'depot', Pos)
	if not it then return end
	if it.sid~=Sid then return end
	if cfg_item[it.id].nodel then return end --不可销毁
	if Item.isLock(pid, it.id) then p.Msg{K='itemlocked'} end
	Item.delByDepotPos(pid, Pos)
end
when{Mark='GUILDDEPOT'} function AskDelItem(Mark, Pos, Sid)
	local pid = PIDByNet(_from)
	if not pid then return end
	if not Guild.isLeader(pid) then return end --and not Guild.isCoLeader(pid) then return end
	local r = _ORM'player':where{pid=pid}:select()[1]
	local gsid = r.guild
	if gsid==0 then return end
	local it = _ORM'guilditem':where{pid=gsid, pos=Pos}:select()
	if not it then return end
	it = it[1]
	if not DEBUGNOCHECK then
		if it.sid ~= Sid then return end
	end
	if cfg_item[it.id].nodel then return end --不可销毁
	_ORM'guilditem':where{sid=it.sid}:delete( )
	CallGuildOf(pid).GuildDepotUp{ T={pos=Pos} }
	local im = cfg_item[it.id]
	local itname = '['..Item.getName(it)..']'
	local pile = im.pile or 0
	if pile > 0 then
		itname = itname..'x'..it.num
	end
	Guild._log(gsid, 6, mstr{_T'<<<name>>>销毁了公会仓库中的<<<item>>>', name=r.name, item=itname })
end

when{_order=0}   function AskSplitItem(Mark, Pos, Num, _args)
	if Pos~=toint(Pos) then _args._stop=true return end
	if Num~=toint(Num) then _args._stop=true return end
	if Num<1 then _args._stop=true return end
end
when{Mark='BAG'}   function AskSplitItem(Mark, Pos, Num, Sid)
	local pid = PIDByNet(_from)
	if not pid then return end
	local free, first = Item.getFreeBag(pid)
	if free==0 then return end
	local it = Item.get(pid, 'bag', Pos)
	if it.num<=1 then return end
	if it.num<=Num then return end
	if not DEBUGNOCHECK then
		if it.sid ~= Sid then return end
	end
	it = _ORM'item':where{sid=it.sid}:returning( ):update{num=it.num-Num}[1]
	local itnew = Item.new(it.id)--split
	itnew.sid = dbsid( 'item', pid )
	itnew.pid = pid
	itnew.mark = it.mark
	itnew.pos = first
	itnew.bind = it.bind
	itnew.num = Num
	itnew.timeto = it.timeto
	_ORM'item':insert(itnew)
	CallPlayer(pid).BagUp{T={pos=Pos, it=it}}
	CallPlayer(pid).BagUp{T={pos=first, it=itnew}}
end
when{Mark='DEPOT'} function AskSplitItem(Mark, Pos, Num, Sid)
	local pid = PIDByNet(_from)
	if not pid then return end
	local free, first = Item.getFreeBag(pid)
	if free==0 then return end
	local it = Item.get(pid, 'bag', Pos)
	if it.num<=1 then return end
	if it.num<=Num then return end
	if not DEBUGNOCHECK then
		if it.sid ~= Sid then return end
	end
	it = _ORM'item':where{sid=it.sid}:returning( ):update{num=it.num-Num}[1]
	local itnew = Item.new(it.id) --split
	itnew.sid = dbsid( 'item', pid )
	itnew.pid = pid
	itnew.mark = it.mark
	itnew.pos = first
	itnew.bind = it.bind
	itnew.num = Num
	itnew.timeto = it.timeto
	_ORM'item':insert(itnew)
	CallPlayer(pid).DepotUp{T={pos=Pos, it=it}}
	CallPlayer(pid).DepotUp{T={pos=first, it=itnew}}
end

when{_order=0}  function AskMoveItem(Type, From, To, Sid, Num, _args)
	_zdm('AskMoveItem', Type, From, To, Sid)
	if From~=toint(From)
	or To~=toint(To)
	or Num~=toint(Num)
	or From<1
	or To<1
	or (string.sub(Type,1,3)=='Bag' and Item.isLockBag(pid, From))
	or (string.sub(Type,-3,-1)=='Bag' and Item.isLockBag(pid, To))
	then
		_args._stop=true
	end
end
when{Type='Bag2Bag'}  function AskMoveItem( Type, From, To, Sid ) --CS
	local pid = PIDByNet(_from)
	if not pid then return end
	if From==To then return end
	if From>Item.getMaxBlank(pid, 'bag') then return end
	if To>Item.getMaxBlank(pid, 'bag') then return end
	local itf = Item.get(pid, 'bag', From)
	if not itf then return end
	if not DEBUGNOCHECK then
		if itf.sid ~= Sid then return end
	end
	local itt = Item.get(pid, 'bag', To)
	if itt then
		if itt.id==itf.id then
			local im = cfg_item[itt.id]
			local pile = im.pile or 0
			if pile>0 and itt.timeto==itf.timeto and (itt.bind==itf.bind or itt.bind==Item.BIND.bind) then --可叠and同限时and(同绑状态/合向绑)合向itt
				local need = pile-itt.num
				if need==0 then return end
				if itf.num>need then --合并余
					itf = _ORM'item':where{sid=itf.sid}:returning( ):update{num=itf.num-need}[1] --源剩
					itt = _ORM'item':where{sid=itt.sid}:returning( ):update{num=pile}[1] --目标满堆
					CallPlayer(pid).BagUp{T={pos=From, it=itf}}
					CallPlayer(pid).BagUp{T={pos=To, it=itt}}
				else
					local newt = itt.num+itf.num
					Item.realDelete(itf)--源删
					itt = _ORM'item':where{sid=itt.sid}:returning( ):update{num=newt}[1] --目标和
					CallPlayer(pid).BagUp{T={pos=From}}
					CallPlayer(pid).BagUp{T={pos=To, it=itt}}
				end
			else --交换
				itf = _ORM'item':where{sid=itf.sid}:returning( ):update{pos=To}[1]
				itt = _ORM'item':where{sid=itt.sid}:returning( ):update{pos=From}[1]
				CallPlayer(pid).BagUp{T={pos=From, it=itt}}
				CallPlayer(pid).BagUp{T={pos=To, it=itf}}
			end
		else --交换
			itf = _ORM'item':where{sid=itf.sid}:returning( ):update{pos=To}[1]
			itt = _ORM'item':where{sid=itt.sid}:returning( ):update{pos=From}[1]
			CallPlayer(pid).BagUp{T={pos=From, it=itt}}
			CallPlayer(pid).BagUp{T={pos=To, it=itf}}
		end
	else --移动itf
		itf = _ORM'item':where{sid=itf.sid}:returning( ):update{pos=To}[1]
		CallPlayer(pid).BagUp{T={pos=From}}
		CallPlayer(pid).BagUp{T={pos=To, it=itf}}
	end
end
when{Type='Depot2Depot'}  function AskMoveItem( Type, From, To, Sid ) --CS
	local pid = PIDByNet(_from)
	if not pid then return end
	if From==To then return end
	if From>Item.getMaxBlank(pid, 'depot') then return end
	if To>Item.getMaxBlank(pid, 'depot') then return end
	local itf = Item.get(pid, 'depot', From)
	if not itf then return end
	if not DEBUGNOCHECK then
		if itf.sid ~= Sid then return end
	end
	local itt = Item.get(pid, 'depot', To)
	if itt then
		if itt.id==itf.id then
			local im = cfg_item[itt.id]
			local pile = im.pile or 0
			if pile>0 and itt.timeto==itf.timeto and (itt.bind==itf.bind or itt.bind==Item.BIND.bind) then --可叠and(同绑状态/合向绑)合向itt
				local need = pile-itt.num
				if need==0 then return end
				if itf.num>need then
					itf = _ORM'item':where{sid=itf.sid}:returning( ):update{num=itf.num-need}[1]
					itt = _ORM'item':where{sid=itt.sid}:returning( ):update{num=pile}[1]
					CallPlayer(pid).DepotUp{T={pos=From, it=itf}}
					CallPlayer(pid).DepotUp{T={pos=To, it=itt}}
				else
					local newt = itt.num+itf.num
					Item.realDelete(itf)--源删
					itt = _ORM'item':where{sid=itt.sid}:returning( ):update{num=newt}[1]
					CallPlayer(pid).DepotUp{T={pos=From}}
					CallPlayer(pid).DepotUp{T={pos=To, it=itt}}
				end
			else --交换
				itf = _ORM'item':where{sid=itf.sid}:returning( ):update{pos=To}[1]
				itt = _ORM'item':where{sid=itt.sid}:returning( ):update{pos=From}[1]
				CallPlayer(pid).DepotUp{T={pos=From, it=itt}}
				CallPlayer(pid).DepotUp{T={pos=To, it=itf}}
			end
		else --交换
			itf = _ORM'item':where{sid=itf.sid}:returning( ):update{pos=To}[1]
			itt = _ORM'item':where{sid=itt.sid}:returning( ):update{pos=From}[1]
			CallPlayer(pid).DepotUp{T={pos=From, it=itt}}
			CallPlayer(pid).DepotUp{T={pos=To, it=itf}}
		end
	else --移动itf
		itf = _ORM'item':where{sid=itf.sid}:returning( ):update{pos=To}[1]
		CallPlayer(pid).DepotUp{T={pos=From}}
		CallPlayer(pid).DepotUp{T={pos=To, it=itf}}
	end
end
when{Type='Bag2Depot'}  function AskMoveItem( Type, From, To, Sid ) --CS
	local c = Client.byNet(_from)
	local pid = c.getPID()
	if not pid then return end
	if From>Item.getMaxBlank(pid, 'bag') then return end
	if To>Item.getMaxBlank(pid, 'depot') then return end
	local itf = Item.get(pid, 'bag', From)
	if not itf then return end
	if not DEBUGNOCHECK then
		if itf.sid ~= Sid then return end
	end
	local itt = Item.get(pid, 'depot', To)
	if itt then
		if itt.id==itf.id then
			local im = cfg_item[itt.id]
			local pile = im.pile or 0
			if pile>0 and itt.timeto==itf.timeto and (itt.bind==itf.bind or itt.bind==Item.BIND.bind) then --可叠and(同绑状态/合向绑)合向itt
				local need = pile-itt.num
				if need==0 then return end
				if itf.num>need then
					itf = _ORM'item':where{sid=itf.sid}:returning( ):update{num=itf.num-need}[1]
					itt = _ORM'item':where{sid=itt.sid}:returning( ):update{num=pile}[1]
					CallPlayer(pid).BagUp{T={pos=From, it=itf}}
					CallPlayer(pid).DepotUp{T={pos=To, it=itt}}
				else
					local newt = itt.num+itf.num
					Item.realDelete(itf)--源删
					itt = _ORM'item':where{sid=itt.sid}:returning( ):update{num=newt}[1]
					CallPlayer(pid).BagUp{T={pos=From}}
					CallPlayer(pid).DepotUp{T={pos=To, it=itt}}
				end
			else --交换
				itf = _ORM'item':where{sid=itf.sid}:returning( ):update{pos=To, mark=Item.MARK.depot}[1]
				itt = _ORM'item':where{sid=itt.sid}:returning( ):update{pos=From, mark=Item.MARK.bag}[1]
				CallPlayer(pid).BagUp{T={pos=From, it=itt}}
				CallPlayer(pid).DepotUp{T={pos=To, it=itf}}
			end
		else --交换
			itf = _ORM'item':where{sid=itf.sid}:returning( ):update{pos=To, mark=Item.MARK.depot}[1]
			itt = _ORM'item':where{sid=itt.sid}:returning( ):update{pos=From, mark=Item.MARK.bag}[1]
			CallPlayer(pid).BagUp{T={pos=From, it=itt}}
			CallPlayer(pid).DepotUp{T={pos=To, it=itf}}
		end
		Item._numToGS(pid, c.getToken(), itt.id)--CallGsByPid( pid ).ItemNum{Token=c.getToken(), Id=itt.id, Num=Item.have(pid, itt.id)}
	else --移动itf
		itf = _ORM'item':where{sid=itf.sid}:returning( ):update{pos=To, mark=Item.MARK.depot}[1]
		CallPlayer(pid).BagUp{T={pos=From}}
		CallPlayer(pid).DepotUp{T={pos=To, it=itf}}
	end
	Item._numToGS(pid, c.getToken(), itf.id)--CallGsByPid( pid ).ItemNum{Token=c.getToken(), Id=itf.id, Num=Item.have(pid, itf.id)}
end
when{Type='Depot2Bag'}  function AskMoveItem( Type, From, To, Sid ) --CS
	local c = Client.byNet(_from)
	local pid = c.getPID()
	if not pid then return end
	if From>Item.getMaxBlank(pid, 'depot') then return end
	if To>Item.getMaxBlank(pid, 'bag') then return end
	local itf = Item.get(pid, 'depot', From)
	if not itf then return end
	if not DEBUGNOCHECK then
		if itf.sid ~= Sid then return end
	end
	local itt = Item.get(pid, 'bag', To)
	if itt then
		if itt.id==itf.id then
			local im = cfg_item[itt.id]
			local pile = im.pile or 0
			if pile>0 and itt.timeto==itf.timeto and (itt.bind==itf.bind or itt.bind==Item.BIND.bind) then --可叠and(同绑状态/合向绑)合向itt
				local need = pile-itt.num
				if need==0 then return end
				if itf.num>need then
					itf = _ORM'item':where{sid=itf.sid}:returning( ):update{num=itf.num-need}[1]
					itt = _ORM'item':where{sid=itt.sid}:returning( ):update{num=pile}[1]
					CallPlayer(pid).DepotUp{T={pos=From, it=itf}}
					CallPlayer(pid).BagUp{T={pos=To, it=itt}}
				else
					local newt = itt.num+itf.num
					Item.realDelete(itf)--源删
					itt = _ORM'item':where{sid=itt.sid}:returning( ):update{num=newt}[1]
					CallPlayer(pid).DepotUp{T={pos=From}}
					CallPlayer(pid).BagUp{T={pos=To, it=itt}}
				end
			else --交换
				itf = _ORM'item':where{sid=itf.sid}:returning( ):update{pos=To, mark=Item.MARK.bag}[1]
				itt = _ORM'item':where{sid=itt.sid}:returning( ):update{pos=From, mark=Item.MARK.depot}[1]
				CallPlayer(pid).DepotUp{T={pos=From, it=itt}}
				CallPlayer(pid).BagUp{T={pos=To, it=itf}}
			end
		else --交换
			itf = _ORM'item':where{sid=itf.sid}:returning( ):update{pos=To, mark=Item.MARK.bag}[1]
			itt = _ORM'item':where{sid=itt.sid}:returning( ):update{pos=From, mark=Item.MARK.depot}[1]
			CallPlayer(pid).DepotUp{T={pos=From, it=itt}}
			CallPlayer(pid).BagUp{T={pos=To, it=itf}}
		end
		Item._numToGS(pid, c.getToken(), itt.id)--CallGsByPid( pid ).ItemNum{Token=c.getToken(), Id=itt.id, Num=Item.have(pid, itt.id)}
	else --移动itf
		itf = _ORM'item':where{sid=itf.sid}:returning( ):update{pos=To, mark=Item.MARK.bag}[1]
		CallPlayer(pid).DepotUp{T={pos=From}}
		CallPlayer(pid).BagUp{T={pos=To, it=itf}}
	end
	Item._numToGS(pid, c.getToken(), itf.id)--CallGsByPid( pid ).ItemNum{Token=c.getToken(), Id=itf.id, Num=Item.have(pid, itf.id)}
end
when{Type='Bag2Equip'}  function AskMoveItem( Type, From, To, Sid, Lab ) --CS2GS
	local c = Client.byNet(_from)
	local pid = c.getPID()
	if From>Item.getMaxBlank(pid, 'bag') then return end
	local it = Item.get(pid, 'bag', From)
	if not it then return end
	if not DEBUGNOCHECK then
		if it.sid ~= Sid then return end
	end
	local im = cfg_item[it.id]
	if not im.wear then return end
	To = Cfg.cfg_part{ part = im.wear }
	if not To then return end
	To = To[1]
	if not To then return end
	To = To.id
	local lvlimit, sexlimit, joblimit, timeout, uselimit, needwake = Item.isLimit( pid, it )
	_lj('AskMoveItem.b2e2', lvlimit, sexlimit, joblimit, timeout, uselimit, needwake)
	if lvlimit then return end
	if sexlimit then return end
	if joblimit then return end
	if timeout then return end
	if needwake then return end
	local iton = Item.get(pid, 'equip', To)
	if iton then
		iton = _ORM'item':where{sid=iton.sid}:returning( ):update{pos=From, mark=Item.MARK.bag}[1]
	end
	local bind = it.bind == Item.BIND.usebind and Item.BIND.bind or it.bind
	it = _ORM'item':where{sid=it.sid}:returning( ):update{pos=To, mark=Item.MARK.equip, bind=bind}[1]
	CallPlayer(pid).BagUp{T={pos=From, it=iton}}
	CallPlayer(pid).EquipUp{T={pos=To, it=it}}
	CallGsByPid( pid ).Equip{Token=c.getToken(), Pos=To, It=it}
	onEquip{pid=pid, pos=To, it=it, oldit=iton, lab=Lab}
end
when{Type='Equip2Bag'}  function AskMoveItem( Type, From, To, Sid ) --CS2GS
	local c = Client.byNet(_from)
	local pid = c.getPID()
	local it = Item.get(pid, 'equip', From)
	if not it then return end
	if not DEBUGNOCHECK then
		if it.sid ~= Sid then return end
	end
	local iton = Item.get(pid, 'bag', To)
	if iton then
		AskMoveItem{Type='Bag2Equip', From=To, To=From, Sid=Sid}
		return
	end
	if To>Item.getMaxBlank(pid, 'bag') then return end
	it = _ORM'item':where{sid=it.sid}:returning( ):update{pos=To, mark=Item.MARK.bag}[1]
	CallPlayer(pid).EquipUp{T={pos=From}}
	CallPlayer(pid).BagUp{T={pos=To, it=it}}
	onUnEquip{pid=pid, pos=From, it=it}
	CallGsByPid( pid ).UnEquip{Token=c.getToken(), Pos=From}
end

when{ Type = 'Bag2GuildDepot' } function AskMoveItem( Type, From, Sid, Num )
	local c = Client.byNet(_from)
	if not c then return end
	local pid = c.getPID()
	if not pid then return end
	if From>Item.getMaxBlank(pid, 'bag') then _zdm(1) return end
	local itf = Item.get(pid, 'bag', From)
	if not itf then _zdm(2) return end
	if not DEBUGNOCHECK then
		if itf.sid ~= Sid then _zdm(3) return end
	end
	if itf.bind == Item.BIND.bind then _zdm(4) return end
	if Item.timeout( itf ) then return end
	if Num > itf.num then _zdm(5) return end
	local im = cfg_item[itf.id]
	if not im.guildin then _zdm(6) return end
	if not im.guildout then _zdm(7) return end
	if not im.guildmax then _zdm(8) return end
	if im.guildinonce and Num>im.guildinonce then return end
	if Item.isLockBag(pid, itf.pos) then return end
	if Item.isLock(pid, itf.id) then return end
	local r = _ORM'player':where{pid=pid}:select()[1]
	local gsid = r.guild
	if gsid==0 then _zdm(9) return end
	if r.guilddepotin >= cfg_guild.depotintimes then _zdm(10) return end
	local maxblank = Guild.getDepotBlank( gsid )
	local its = _ORM'guilditem':where{pid=gsid}:select() or {}
	local sum = 0
	local currhave
	local currall = {}
	for i, it in pairs(its) do
		currall[it.pos] = it
		if it.id == itf.id then
			sum = sum + it.num
			currhave = it
		end
	end
	if sum >= im.guildmax then _zdm(11) return end
	local pile = im.pile or 0
	local it = currhave
	local itname = '['..Item.getNameById(itf.id)..']'
	if pile > 1 then
		pile = im.guildmax
		if currhave then
			it = _ORM'guilditem':where{sid=it.sid}:returning( ):update{num=it.num+Num}[1]
		else
			local first
			for i=1, maxblank do
				if not currall[i] then
					first = i
					break
				end
			end
			if not first then _zdm(12) return end
			it = table.newclone(itf)
			it.sid = dbsid( 'item', pid )
			it.pid = gsid
			it.mark = Item.MARK.guild
			it.pos = first
			it.num = Num
			it.time = _now(0)
			Item.flow(it, 'guilddepotin')
			_ORM'guilditem':insert(it)
		end
		if Num == itf.num then
			assert(Item.delByPos(pid, itf.pos, Num, 'guilddepot'),'delByPosError') --按包位删, 计数道具不入
		else
			local old = Item.have(pid, itf.id, true)
			local new = old -Num
			itf = _ORM'item':where{sid=itf.sid}:returning( ):update{num=itf.num-Num}[1]
			onLossItem{pid=pid, id=itf.id, num=Num, bind=itf.bind, lab='guilddepot', old=old, new=new}
			CallPlayer(pid).BagUp{T={pos=itf.pos, it=itf}}
		end
		itname = itname..'x'..Num
	else
		local first
		for i=1, maxblank do
			if not currall[i] then
				first = i
				break
			end
		end
		if not first then _zdm(13) return end
		it = table.newclone(itf)
		it.pid = gsid
		it.mark = Item.MARK.guild
		it.pos = first
		it.time = _now(0)
		Item.flow(it, 'guilddepotin')
		_ORM'guilditem':insert(it)
		assert(Item.delByPos(pid, itf.pos, Num, 'guilddepot'), 'delByPosError')
	end
	local guildin = im.guildin * Num
	giveItem{pid=pid, id=cfg_guild.devote, num=guildin, lab='guilddepot'}
	giveItem{pid=pid, id=cfg_guild.devoteacc, num=guildin, lab='guilddepot'}
	_ORM'player':where{ pid = pid }:update{guilddepotin=r.guilddepotin+1}
	CallGuildOf(pid).GuildDepotUp{ T={pos=it.pos, it=it, pid=pid} }
	Guild._log(gsid, 5, mstr{_T'<<<name>>>存入了<<<item>>>', name=r.name, item= itname })
end
when{ Type = 'GuildDepot2Bag' } function AskMoveItem( Type, From, To, Sid, Num )
	local c = Client.byNet(_from)
	if not c then return end
	local pid = c.getPID()
	if not pid then  return end
	local r = _ORM'player':where{pid=pid}:select()[1]
	local gsid = r.guild
	if gsid==0 then return end
	local itf = _ORM'guilditem':where{pid=gsid, pos=From}:select()
	if not itf then return end
	itf = itf[1]
	if not DEBUGNOCHECK then
		if itf.sid ~= Sid then return end
	end
	if itf.num < Num then return end
	local im = cfg_item[itf.id]
	if Item.have( pid, cfg_guild.devote ) < im.guildout * Num then
		return
	end
	Item.delById(pid, cfg_guild.devote, im.guildout * Num, 'guilddepot')
	Item.giveCopy( pid, itf, 'guilddepot', Num )
	local itname = '['..Item.getName(itf)..']'
	local pile = im.pile or 0
	if pile > 0 then
		itname = itname..'x'..Num
	end
	if itf.num == Num then
		_ORM'guilditem':where{sid=itf.sid}:delete( )
		CallGuildOf(pid).GuildDepotUp{ T={pos=itf.pos} }
	else
		itf = _ORM'guilditem':where{sid=itf.sid}:returning( ):update{num=itf.num-Num}[1]
		CallGuildOf(pid).GuildDepotUp{ T={pos=itf.pos, it=itf} }
	end
	Guild._log(gsid, 6, mstr{_T'<<<name>>>取出了<<<item>>>', name=r.name, item=itname })
end
