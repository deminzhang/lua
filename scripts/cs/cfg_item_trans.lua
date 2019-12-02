--cfg_itemTrans.lua 道具转义
--create by dmz 2015-2-7
_G.cfg_itemTrans = {}--k:im.trans,v:{id=道具id,have=取数方法,add=增加方法,sub=减少方法}
cfg_itemTrans.coins = {--游戏币+绑定游戏币
	have = function(pid)
		return Item.money(pid)
	end,
	add = function(pid,num,lab)
		--error('coins only surrpot cost! give') --TODO:仅用于消耗 先绑金后金币
		return cfg_itemTrans.coinb.add(pid,num,lab) --TODO:默认为绑金
	end,
	sub = function(pid,num,lab)
		Item.costMoney(pid,num,lab)
		return true
	end,
}
cfg_itemTrans.coin = {--游戏币
	id = Item.COIN,
	have = function(pid)
		return Role.getOften(pid).coin
	end,
	add = function(pid,num,lab)
		assert(num>0,num)
		num = AntiAddiction.getNum(pid, Item.COIN, num, lab)
		if num <= 0 then return true end
		local po = Role.getOften(pid)
		local old = po.coin
		local new = old + num
		Role.setOften(pid, 'coin', new, num>Role.SAVE_COIN_VAL)
		onGetCoin{pid=pid,num=num,lab=lab,old=old,new=new}
		CallPlayer(pid).Coin{Num=new,Add=num, Lab=lab}
		onGetMoney{ pid = pid, num = num,lab = lab }

		return true, new
	end,
	sub = function(pid,num,lab)
		assert(num>0,num)
		local old = Role.getOften(pid).coin
		local new = old - num
		Role.setOften(pid, 'coin', new, true)
		onLossCoin{pid=pid,num=num,lab=lab,old=old,new=new}
		CallPlayer(pid).Coin{Num=new,Add=-num, Lab=lab}
		return true
	end,
}
cfg_itemTrans.coinb = {--绑定游戏币
	id = Item.COINB,
	have = function(pid)
		return Role.getOften(pid).coinb
	end,

	add = function(pid,num,lab)
		assert(num>0,num)
		num = AntiAddiction.getNum(pid, Item.COINB, num, lab)
		if num == 0 then return true end
		local po = Role.getOften(pid)
		local old = po.coinb
		local new = old + num
		Role.setOften(pid, 'coinb', new, num>Role.SAVE_COINB_VAL)
		onGetCoinB{pid=pid,num=num,lab=lab,old=old,new=new}
		CallPlayer(pid).CoinB{Num=new,Add=num, Lab=lab}
		onGetMoney{ pid = pid, num = num, lab = lab }

		return true
	end,
	sub = function(pid,num,lab)
		assert(num>0,num)
		local old = Role.getOften(pid).coinb
		local new = old - num
		Role.setOften(pid, 'coinb', new, true)
		onLossCoinB{pid=pid,num=num,lab=lab,old=old,new=new}
		CallPlayer(pid).CoinB{Num=new,Add=-num, Lab=lab}
		return true
	end,
}
cfg_itemTrans.gold = {--充值币(元宝)
	id = Item.GOLD,
	have = function(pid)
		local uid = _ORM:table'player':where{pid=pid}:select()[1].uid
		local a = _ORM:table'account':where{uid=uid}:select()[1]
		return a.gold,a.accgold,a.costgold
	end,
	add = function(pid,num,lab,addacc)
		local uid = _ORM:table'player':where{pid=pid}:select()[1].uid
		local a = _ORM:table'account':where{uid=uid}:select()[1]
		local old = a.gold
		local oldacc = a.accgold
		local new = old + num
		local newacc = oldacc + (addacc and num or 0)
		a = _ORM'account':where{uid=uid}:returning():update{gold=new,accgold=newacc}[1]
		onGetGold{pid=pid,num=num, lab=lab, old=old, new=new, acc=newacc, cost=a.costgold}
		CallPlayer(pid).Gold{Num=new,Add=num,Acc=newacc,Cost=a.costgold}
		return true
	end,
	sub = function(pid,num,lab,nocost)
		local uid = _ORM:table'player':where{pid=pid}:select()[1].uid
		local a = _ORM:table'account':where{uid=uid}:select()[1]
		local old = a.gold
		local new = old - num
		local newcost = a.costgold + (nocost and 0 or num)
		if new<0 then return false end
		_ORM'account':where{uid=uid}:update{gold=new,costgold=newcost}
		onLossGold{pid=pid,num=num,lab=lab,old=old,new=new, acc=a.accgold, cost=newcost}
		CallPlayer(pid).Gold{Num=new,Add=-num,Acc=a.accgold,Cost=newcost}
		return true
	end,
}
cfg_itemTrans.goldp = {--代充值币(绑定元宝)
	id = Item.GOLDP,
	have = function(pid)
		return Role.getOften(pid).goldp
	end,
	add = function(pid,num,lab)
		assert(num>0,num)
		local old = Role.getOften(pid).goldp
		local new = old + num
		Role.setOften(pid, 'goldp', new, true)
		onGetGoldP{pid=pid,num=num,lab=lab,old=old,new=new}
		CallPlayer(pid).GoldP{Num=new,Add=num}
		return true
	end,
	sub = function(pid,num,lab)
		assert(num>0,num)
		local old = Role.getOften(pid).goldp
		local new = old - num
		Role.setOften(pid, 'goldp', new, true)
		onLossGoldP{pid=pid,num=num,lab=lab,old=old,new=new}
		CallPlayer(pid).GoldP{Num=new,Add=-num}
		return true
	end,
}
cfg_itemTrans.exp = {--经验
	have = function(pid)
		return Role.getOften(pid).exp
	end,
	add = function(pid, num, lab)
		if num <= 0 then return true end
		num = AntiAddiction.getNum(pid, Item.EXP, num, lab)
		if num <= 0 then return true end
		--if not PUBLIC then
			if _ORM'lockaddexp':where{ pid = pid }:select( ) then --memdb TODO 加经验中加经验,这不合法, 如果出现,想办法改掉
				Log.fatal('addExp in addExp', debug.traceback())
				error('addExp in addExp' )
			end
			_ORM'lockaddexp':insert{pid=pid}
		--end
		local r = _ORM'player':where{ pid = pid }:select( )[1]
		local po = Role.getOften(pid)
		local oldexp = po.exp
		local newexp = po.exp + num
		if Role.getLevel( pid ) >= 400 and LockMgr.isUnlock( pid, 'hone') then
			CallPlayer(pid).CHoneAddExp{Id=id, New=num, Lab=lab}
		end
		if  LockMgr.isUnlock( pid, 'expfairy') and lab == 'killmonster' then  --经验精灵
		    local getexp = 0
			local getcount = 0
			local s = _ORM'expfairy':where{ pid = pid }:select( )
			if s then
				getexp = s[1].getexp
				getcount = s[1].getcount
			end
			if getcount < Expfairy.MAXCOUNT then
				local lv = Role.getLevel( pid )
				local expadd = Expfairy.RATIO*num
				if expadd % 1 >= 0.5 then
					expadd = math.ceil( expadd )
				else
					expadd = math.floor( expadd )
				end
				getexp = getexp + expadd
				_ORM'expfairy':where{ pid = pid }:updateinsert{ pid = pid, getcount = getcount , getexp = getexp }
				CallPlayer( pid ).Expfairy_Syn{	Info = { getcount = getcount , getexp = getexp } }
			end
		end
		local lvexp = (r.level > 1)and (cfg_levelup[r.level].exp - cfg_levelup[r.level-1].exp) or cfg_levelup[r.level].exp
		-- todo LOG
		local oldlv = r.level
		local totalcost, finallevel = 0, r.level
		local maxlv = math.min(MAX_LEVEL, #cfg_levelup)
		local pt = Role.getTick(pid)
		if not r.notautolvup and newexp >= lvexp and maxlv > r.level then --升级
			for i = oldlv, maxlv - 1 do
				local lvexp1 = (i > 1) and (cfg_levelup[i].exp - cfg_levelup[i-1].exp) or cfg_levelup[i].exp
				if newexp - totalcost >= lvexp1 then
					totalcost = totalcost + lvexp1
					finallevel = finallevel + 1
				else
					break
				end
				local viplv = VIP.getLv( pid )
				RankDao.saveLevelRank( r, finallevel, viplv )
			end
			newexp = newexp - totalcost
			if finallevel >= maxlv then
				newexp = math.min(newexp, cfg_levelup[maxlv].exp)
			end
			_ORM'player':where{ pid = pid }:update{ level = finallevel }
			Role.setOften(pid, 'exp', newexp, true)
			local c = Client.byPID(pid)
			Log.sys('onRoleLevelUp',pid,oldlv,finallevel,lab,c and 'online' or 'offline',debug.traceback())
			local online = c and 'true' or 'false'
			local map = pt.zoneid or ''
			local uid = r.uid
			for level = oldlv + 1, finallevel do
				CYLog.log( 'upgrade', { pid=pid, uid=uid, level = level, map_id = map, online=online, lab=lab }, c )
			end
			onRoleLevelUp{ pid = pid, oldlv = oldlv, newlv = finallevel }
			CallPlayer( pid ).RoleLevelUp{ Level = finallevel, OldLevel = r.level }
		else
			if r.level >= maxlv then
				--if not PUBLIC then
					_ORM'lockaddexp':where{pid=pid}:delete()
				--end
				local maxexp = cfg_levelup[maxlv].exp - cfg_levelup[maxlv-1].exp
				num = math.min(maxexp, num)
				newexp = math.min(maxexp, newexp)
				if oldexp == newexp then --己在下级升级值不升不再长
					return true
				end
			end
			Role.setOften(pid, 'exp', newexp, lab~='pickup' and lab~='killmonster' or num>Role.SAVE_EXP_VAL)
		end
		--if not PUBLIC then
			_ORM'lockaddexp':where{pid=pid}:delete()
		--end
		CallPlayer( pid ).RoleAddExp{ Exp = num, Newexp = newexp, Lab=lab }

		onGetItem{ pid = pid, id = Item.EXP, num = num, bind = 0, lab = lab, old=oldexp, new=newexp }

		if _G.LOGEXP then
			local c = Client.byPID( pid )
			if c then
				local params = _G.ExpLogParam or {}
				params.oldlv = oldlv
				params.newlv = finallevel
				params.exp = num
				params.lab = lab
				assert(lab, 'nolab')
				local ins = c.getGameIns( )
				if ins then
					local data = ins.getData( )
					params.gname = data.gname
					params.gzone = data.gzone
				else
					params.zoneid = pt.zoneid
				end
				local logit
				if lab == 'killmonster' then
					if num >= cfg_levelup[oldlv].logkillexp then
						logit = true
					end
				else
					logit = true
				end
				if logit then
					XLog.log( 'addexp', pid,  params )
				end
			end
			_G.ExpLogParam = nil
		end

		return true
	end,
	sub = function(pid, num, lab)
		if num <= 0 then return end
		local po = Role.getOften(pid)
		if po.exp < num then return end
		local old = po.exp
		Role.setOften(pid, 'exp', po.exp - num, true)
		CallPlayer( pid ).RoleAddExp{ Exp = -num, Newexp = po.exp - num, Lab=lab }
		onLossItem{pid=pid, id=Item.EXP, num=num, bind=0, lab=lab, old=old, new=po.exp - num}
		return true
	end,
}
