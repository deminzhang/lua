do return end
_G.Shop = {}
local unpack = table.unpack or unpack
function Shop._buy(pid,shopid,idx,num)	--购买
	if num<1 then return 1 end
	if num~=toint(num) then return 2 end
	local shop = cfg_shop[shopid]
	if not shop then return 3 end
	local goods = shop['item'..idx]
	if not goods then return 4 end
	if Item.getFreeBag(pid)==0 then return 5 end
	local id,bind,price,money,lv,limit = unpack(goods)
	local cost = price*num
	if Item.have(pid,money)<cost then return 6 end
	if lv and lv> 0 then
		if lv > Role.getLevel( pid ) then
			return 6.5
		end
	end
	local goodskey = 'shop'..shopid..'|'..idx
	if not giveItem{pid=pid,id=id,num=num,bind=bind,lab=goodskey,mail=false,try=true} then return 7 end
	local key = string.format('%d_%d_%d',shopid,idx,id)
	if limit and limit>0 then
		_zdm('limit ', shopid,idx,id, key)
		local r = _ORM'shoplimit':where{pid=pid,goods_key=key}:select()
		local get = r and r[1].times or 0
		local times = get+num
		if times > limit then return 8 end
		local now = _now(0)
		local r = _ORM'shoplimit':where{pid=pid,goods_key=key}:returning( ):update{times=times,time=now}
		if not r then
			local sl = DefaultDB.get'shoplimit'
			sl.pid = pid
			sl.goods_key = key
			sl.times = times
			sl.time = now
			_ORM'shoplimit':insert(sl)
		end
		CallPlayer(pid).Shoplimit{Key=key, Times=times}
	end
	local lab = 'shop'..key
	Item.delById(pid,money,cost,lab)
	giveItem{pid=pid,id=id,num=num,bind=bind,lab=lab,mail=false,try=false}
end
function Shop._sell(pid,Sid,Pos)	--出售
	if Item.isLockBag(pid,Pos) then return end
	local it = Item.get(pid,'bag',Pos)
	if not it then return end
	if it.sid~=Sid then return end
	if Item.isLock(pid,it.id) then p.Msg{K='itemlocked'} end
	local im = cfg_item[it.id]
	if im.nosell then return end --不可销毁
	if not im.sellprice then return end
	if im.sellprice<=0 then return end
	local sum = im.sellprice*it.num
	giveItem{pid=pid,id=Item.COINB,num=sum,bind=1,lab='sold',mail=false,try=false}
	assert(Item.delByPos(pid,Pos,it.num,'sold'), 'delByPosError')	--'sold'逻辑有关不许改
	_from.Sold{T=it}
end
function Shop._buyback(pid,Sid)	--回购
	local it = Item.getBySid( Sid, pid,'sold')--回购
	if not it then return end
	
	local im = cfg_item[it.id]
	local sum = im.sellprice*it.num
	if Item.have(pid,Item.COINB)<sum then return end
	if Item.getFreeBag(pid)==0 then return 5 end
	if not Item.giveInstance(pid,it,'buyback') then end
	Item.delById(pid,Item.COINB,sum,'buyback')
	_from.BuyBack{Sid=it.sid}
end
--event----------------------------------------
when{} function loadConfigCS()
	DefaultDB.add( 'shoplimit', {
		pid = 0,		--玩家id
		goods_key = '',	--货号=商店id_店品idx_道具id(附道具id防配置换货)
		times = 0,		--本周期购买次数
		time = 0,		--更新时间
	} )
	dofile'config/cfg_shop.lua'
end
when{} function checkConfig()
	for id,v in pairs(cfg_shop) do
		for i=1,math.huge do
			local goods = v['item'..i]
			if goods then
				local id,bind,price,money,lv,limit, limittype = unpack(goods)
				assert(cfg_item[id], id..'invalid item in shop')
				assert(bind==Item.BIND.unbind or bind==Item.BIND.bind or bind==Item.BIND.equipbind, bind..'bind must 0/1/2 im cfg_shop['..id)
				assert(cfg_item[money], money..'invalid money in shop')
				assert(price>0, price..'invalid price in shop')
			else break
			end
		end
	end
end
when{} function cleanupUser(pid)
	_SQL:run('delete from shoplimit where pid=$1', pid)
end
when{step='login'} function getUserInfo(uid,pid,info,step)
	info.shoplimit = {}
	local now = _now()
	local r = _ORM'shoplimit':where{pid=pid}:select()
	if r then
		for i, v in pairs(r) do
			local t = v.goods_key:split('_')
			local shopid, idx, id = toint(t[1]), toint(t[2]), toint(t[3])
			local shop = cfg_shop[shopid]
			local norest
			if shop then
				local goods = shop['item'..idx]
				if goods then
					local id,bind,price,money,lv,limit,limittype = unpack( goods )
					if limittype==1 then
						norest = true
					end
				end
			end	
			if norest or sameDay(v.time/1000, now) then
				info.shoplimit[v.goods_key] = v.times
			end
		end
	end
	--dump(info.shoplimit)
end
when{} function onNewDay(pid, login)--sameDay判定,不需处理
	local r = _ORM'shoplimit':where{pid=pid}:select()
	if r then
		local keys = {}
		for k, v in pairs(r) do
			local t = v.goods_key:split('_')
			local shopid, idx, id = toint(t[1]), toint(t[2]), toint(t[3])
			local shop = cfg_shop[shopid]
			if shop then
				local goods = shop['item'..idx]
				if goods then
					local id,bind,price,money,lv,limit,limittype = unpack( goods )
					if limittype~=1 then
						keys[#keys+1] = v.goods_key
					end
				else
					keys[#keys+1] = v.goods_key
				end
			else
				keys[#keys+1] = v.goods_key
			end
		end
		if #keys>0 then
			_ORM'shoplimit':where{pid=pid, goods_key=keys}:delete()
		end
	end
end

--RPC------------------------------------------
cdefine.c.ShopBuy{ShopId=0,Idx=0,Num=0}
cdefine.c.ShopSell{Sid=0,Pos=0}
cdefine.c.ShopBuyBack{Sid=0}
when{} function ShopBuy(ShopId, Idx, Num )
	local c = Client.byNet(_from)
	if not c then return end
	if Cd(c,'ShopBuy',300) then return end
	Shop._buy(c.getPID(),ShopId, Idx, Num)
end
when{} function ShopSell(Sid, Pos)
	local c = Client.byNet(_from)
	if not c then return end
	if Cd(c,'ShopSell',300) then return end
	Shop._sell(c.getPID(),Sid,Pos)
end
when{} function ShopBuyBack(Sid)
	local c = Client.byNet(_from)
	if not c then return end
	if Cd(c,'ShopBuyBack',300) then return end
	Shop._buyback(c.getPID(),Sid)
end
