do return end
--cs_itemAction.lua 道具消耗功能
--create by dmz 2015-7-29
_G.cs_itemAction = {}
_G.cs_itemActionc = {} --check
local unpack = table.unpack or unpack
--定量道具
function cs_itemAction.item(role, id, key, val, Num, Sel)
	local pid = role.getPID()
	local iid, num, bind = val[1], val[2] * Num, val[3]
	local ok, r = giveItem{pid=pid, id=iid, num=num, bind=bind, lab='item'..id, mail=true, try=false}
	if cfg_item[id].showget then
		CallPlayer(pid).PackItemShow{Id=id, List=r}
	end
	return true
end

--采矿
function cs_itemAction.addenergy( role, id, key, val, Num, Sel )
	local pid = role.getPID( )
	local s = _ORM"mining":where{ pid = pid }:select( )
	local energy = s[1].energy + val.count

	local data = _ORM"mining":where{ pid = pid }:returning( ):update{ energy = energy }[1]
	CallPlayer( pid ).SyncMiningInfo{ Info = data }
	return true
end

--解包道具
function cs_itemAction.pack(role, id, key, val, Num, Sel)
	local pid = role.getPID()
	local cfg = cfg_pack[val]
	local p = _ORM'player':where{ pid = pid }:select( )[1]
	local list = {}
	for ii = 1, Num do
		local idx
		if cfg.sexsub then
			idx = p.sex
		elseif cfg.jobsub then
			idx = p.job
		else
			if cfg.wish then
				if cfg.wish[1] == 0 then --server
					local iw = _ORM'itemwish':where{iid=id}:select()
					local wn = iw and iw[1].num or 0
					wn = wn + 1
					--print0('_____________________w0',wn)
					if wn >= cfg.wish[2] then
						wn = 0
						idx = cfg.wish[3]
					end
					if iw then
						_ORM'itemwish':where{iid=id}:update{num=wn}
					else
						if wn > 0 then
							_ORM'itemwish':insert{iid=id, num=wn}
						end
					end
				elseif cfg.wish[1] == 1 then --person
					local iw = _ORM'itemwish_person':where{pid=pid, iid=id}:select()
					local wn = iw and iw[1].num or 0
					wn = wn + 1
					--print0('_____________________w1',wn)
					if wn >= cfg.wish[2] then
						wn = 0
						idx = cfg.wish[3]
					else
					end
					if iw then
						_ORM'itemwish_person':where{pid=pid, iid=id}:update{num=wn}
					else
						if wn > 0 then
							_ORM'itemwish_person':insert{pid=pid, iid=id, num=wn}
						end
					end
				end
			end
			if not idx then
				idx = math.weight(cfg.weight)
			end
		end
		assert(idx, tostring(idx))
		local sublist = cfg['sub'..idx]
		assert(sublist, idx)
		for i,v in pairs(sublist) do
			local iid, bind, rate, minn, maxn = unpack(v)
			if math.random(100) <= rate then
				local num = math.random(minn, maxn)
				list[#list+1] = {iid, num, bind}
			end
		end
	end
	--_zdm( 'cs_itemAction.pack', id, val )
	--dump(list)
	local ok, r = giveItems{ pid = pid, list = list, lab = 'item'..id, mail = true }
	if cfg_item[id].showget then
		CallPlayer(pid).PackItemShow{Id=id, List=r}
	end
	return true
end
--可选消耗解包道具
function cs_itemAction.mulpack(role, id, key, val, Num, Sel)
	local pid = role.getPID()
	local mulpackid = val
	local mulpack = cfg_mulpack[mulpackid]
	local packid = mulpack['pack'..Sel]
	local costid = mulpack['need'..Sel]
	local costnum = mulpack['num'..Sel]
	if costid and costnum and costnum >0 then
		Item.delById(pid, costid, costnum*Num, 'item_'..id )
	end
	local cfg = cfg_pack[packid]
	local p = _ORM'player':where{ pid = pid }:select( )[1]
	local list = {}
	for ii = 1, Num do
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
		for i,v in pairs(sublist) do
			local iid, bind, rate, minn, maxn = unpack(v)
			if math.random(100) <= rate then
				local num = math.random(minn, maxn)
				list[#list+1] = {iid, num, bind}
			end
		end
	end
	local ok, r = giveItems{ pid = pid, list = list, lab = 'item'..id, mail = true }
	if cfg_item[id].showget then
		CallPlayer(pid).PackItemShow{Id=id, List=r}
	end
	return true
end
function cs_itemActionc.mulpack(role, id, key, val, Num, Sel)
	local mulpackid = val
	local mulpack = cfg_mulpack[mulpackid]
	local packid = mulpack['pack'..Sel]
	if not packid then return false end
	local costid = mulpack['need'..Sel]
	local costnum = mulpack['num'..Sel]
	if costid and costnum and costnum >0 then
		local pid = role.getPID()
		if Item.have(pid, costid) < costnum*Num then return false end
	end
	return true
end
--充值礼包
function cs_itemAction.rechargepack(role, id, key, val, Num, Sel)
	cs_itemAction.pack(role, id, 'pack', val.pack, Num, Sel)
	return true
end
function cs_itemActionc.rechargepack(role, id, key, val, Num, Sel)
	local rechargetimes = _ORM'account':where{ uid = role.getUID( ) }:select( )[1].rechargetimes
	if rechargetimes < val.times then
		return
	end
	return true
end

--限次及可变消耗
function cs_itemAction.costitem(role, id, key, val, Num, Sel)
	local costid = val.costid
	local cfg = cfg_itemcost[costid]
	local pid = role.getPID()
	local times = Num
	local use = _ORM'itemuse':where{ pid = pid, id = id }:select( )
	if use then
		local now = _now()
		if cfg.circle == 'daily' then
			if sameDay(use[1].time/1000, now) then
				times = use[1].times + Num
			end
		elseif cfg.circle == 'weekly' then
			if sameWeek(use[1].time/1000, now) then
				times = use[1].times + Num
			end
		else error(cfg.circle)
		end
	end
	local needid
	if cfg.need and cfg.need > 0 then
		needid = cfg.need
	end
	_zdm(needid,'needid')
	if needid and needid > 0 then
		if cfg.baseline>0 and times>cfg.baseline then--超普限
			local more = times-cfg.baseline
			local neednum = cfg.base +more*cfg.app
			if neednum>0 then
				local r = Item.delById(pid, cfg.appneed, neednum*Num, 'item_'..id)
				assert(r, 'del faill')
			end
		else--扣普
			if cfg.num>0 then
				local r = Item.delById(pid, cfg.need, cfg.num*Num, 'item_'..id)
				assert(r, 'del faill')
			end
		end
	end
	if use then
		_ORM'itemuse':where{ pid = pid, id = id }:update{ times = times, time = _now(0) }
	else
		local r = DefaultDB.get'itemuse'
		r.pid = pid
		r.id = id
		r.times = times
		r.time = _now(0)
		_ORM'itemuse':insert( r )
	end
	CallPlayer(pid).ItemUseUp{ T={id=costid, times = times, time = _now(0)} }
	cs_itemAction.item(role, id, 'item', val.item, Num, Sel)
	return true
end

function cs_itemActionc.costitem(role, id, key, val, Num, Sel)
	local costid = val.costid
	local cfg = cfg_itemcost[costid]
	if not cfg then return end
	if cfg.base and cfg.base > 0 then --可变消耗不可批用
		assert(Num == 1, 'Num~=1 可变消耗不可批用')
	end

	local pid = role.getPID()
	local now = _now()
	local times = Num --Num由客户端计算
	local use = _ORM'itemuse':where{ pid = pid, id = id }:select( )
	if use then
		if cfg.circle == 'daily' then
			if sameDay(use[1].time/1000, now) then
				times = use[1].times
				if cfg.limit and cfg.limit>0 and (times+Num) > cfg.limit then
					return false, Num..'daily limit'..cfg.limit
				end
			else
			end
		elseif cfg.circle == 'weekly' then
			if sameWeek(use[1].time/1000, now) then
				times = use[1].times
				if cfg.limit and cfg.limit>0 and (times+Num) > cfg.limit then
					return false, Num..'weekly limit'..cfg.limit
				end
			else
			end
		else error(cfg.circle)
		end
	end
	if cfg.limit and cfg.limit>0 and Num > cfg.limit then
		return false, Num..'>limit'..cfg.limit
	end
	local needid
	if cfg.need and cfg.need > 0 then
		needid = cfg.need
	end
	if needid and needid > 0 then
		if cfg.baseline>0 and times+1>cfg.baseline then--超普限
			local more = times+1-cfg.baseline
			local neednum = cfg.base +more*cfg.app
			if neednum>0 then
				if Item.have(pid, cfg.appneed) < neednum*Num then return end
			end
		else--扣普
			if cfg.num>0 then
				if Item.have(pid, cfg.need) < cfg.num*Num then return end
			end
		end
	end
	return true
end
--限次及可变消耗
function cs_itemAction.costpack(role, id, key, val, Num, Sel)
	local costid = val.costid
	local cfg = cfg_itemcost[costid]
	local pid = role.getPID()
	local times = Num
	local use = _ORM'itemuse':where{ pid = pid, id = id }:select( )
	if use then
		local now = _now()
		if cfg.circle == 'daily' then
			if sameDay(use[1].time/1000, now) then
				times = use[1].times + Num
			end
		elseif cfg.circle == 'weekly' then
			if sameWeek(use[1].time/1000, now) then
				times = use[1].times + Num
			end
		else error(cfg.circle)
		end
	end
	local needid
	if cfg.need and cfg.need > 0 then
		needid = cfg.need
	end
	_zdm(needid,'needid')
	if needid and needid > 0 then
		if cfg.baseline>0 and times>cfg.baseline then--超普限
			local more = times-cfg.baseline
			local neednum = cfg.base +more*cfg.app
			if neednum>0 then
				local r = Item.delById(pid, cfg.appneed, neednum*Num, 'item_'..id)
				assert(r, 'del faill')
			end
		else--扣普
			if cfg.num>0 then
				local r = Item.delById(pid, cfg.need, cfg.num*Num, 'item_'..id)
				assert(r, 'del faill')
			end
		end
	end
	if use then
		_ORM'itemuse':where{ pid = pid, id = id }:update{ times = times, time = _now(0) }
	else
		local r = DefaultDB.get'itemuse'
		r.pid = pid
		r.id = id
		r.times = times
		r.time = _now(0)
		_ORM'itemuse':insert( r )
	end
	CallPlayer(pid).ItemUseUp{ T={id=id, times = times, time = _now(0)} }

	cs_itemAction.pack(role, id, 'pack', val.pack, Num, Sel)
	return true
end
cs_itemActionc.costpack = cs_itemActionc.costitem

--属性丹
function cs_itemAction.attrpill(role, id, key, val, Num, Sel)
	error('client method! roll back!') --客户端行为,如果到这里说明是封包
end
--称号卡
function cs_itemAction.title(role, id, key, val, Num, Sel)
	local pid = role.getPID()
	local titleid = val.id
	local limitday = val.day
	Title.add(pid, titleid, limitday)
	return true
end
function cs_itemActionc.title(role, id, key, val, Num, Sel)
	local pid = role.getPID()
	local titleid = val.id
	local have, timeto = Title.have( pid, titleid)
	if have then
		if timeto == 0 then return false end
	end
	return true
end
--聊天称号卡
function cs_itemAction.chattitle(role, id, key, val, Num, Sel)
	local pid = role.getPID()
	local titleid = val[1]
	local limitday = val[2]
	ChatTitle.getNew( pid, titleid, limitday )
	return true
end
--活力增加道具
function cs_itemAction.addpower(role, id, key, val, Num, Sel)
	local pid = role.getPID( )
	local add = val.count * Num
	if CSPower.checkAdd( pid ) then
		CSPower.add( pid, add, 'itemadd' )
	end
	return true
end
--按级给经验
function cs_itemAction.lvexp(role, id, key, val, Num, Sel)
	local pid = role.getPID( )
	for i=1, Num do
		local lv = Role.getLevel( pid )
		local t = {}
		for lv, exp in pairs(val) do
			t[#t+1] = {lv=lv, exp=exp}
		end
		table.sort(t, table.asc('lv') )
		local use = 1
		for i, v in ipairs(t) do
			if lv >= v.lv then
				use = i
			else
				break
			end
		end
		local exp = t[use].exp
		giveItem{pid=pid, id=Item.EXP, num=exp, bind=bind, lab='item'..id, mail=true, try=false}
	end
	return true
end
function cs_itemActionc.lvexp(role, id, key, val, Num, Sel)
	local pid = role.getPID( )
	return Role.getLevel( pid ) < math.min(MAX_LEVEL, #cfg_levelup)
end
--日包
function cs_itemAction.dayitem(role, id, key, val, Num, Sel, it)
	local pid = role.getPID()
	local used = Item.getv(it, 'usetimes') or 0
	local usetime = Item.getv(it, 'usetime') or 0
	local item = val[used+1]
	local costitem = item[3]
	local costnum = item[4] or 0
	if costitem and costnum>0 then
		Item.delById(pid, costitem, costitem, 'item_'..id )
	end
	local iid, num, bind = item[1], item[2], item[3]
	giveItem{pid=pid, id=iid, num=num, bind=bind, lab='item'..id, mail=true, try=false}
	if val[used+2] then
		it = Item.setv(it, 'usetimes', used + 1)
		it = Item.setv(it, 'usetime', _now())
		CallPlayer(pid).BagUp{T={pos=it.pos, it=it}}
	else
		assert( Item.delByPos(pid, it.pos, Num, 'use'), 'delByPosError')
	end
	return true
end
function cs_itemActionc.dayitem(role, id, key, val, Num, Sel, it)
	local used = Item.getv(it, 'usetimes') or 0
	local usetime = Item.getv(it, 'usetime') or 0
	local now = _now()
	if sameDay(usetime, now) then return end
	local item = val[used+1]
	local costitem = item[3]
	local costnum = item[4] or 0
	if costitem and costnum>0 then
		if Item.have(pid, costitem) < costnum then return end
	end
	return true
end
--幸运数礼包
function cs_itemAction.luckyid(role, id, key, val, Num, Sel, it)
	local lucknum = Item.getv(it, 'lucknum')
	if lucknum then return end --己开
	local cfg = cfg_luckpack[val]
	if not cfg then return end
	local idx = math.weight(cfg.weight)
	local lnum = cfg.luckn[idx]
	local it = Item.setv(it, 'lucknum', lnum)
	local pid = role.getPID()
	CallPlayer(pid).BagUp{T={pos=it.pos, it=it}}
	CallPlayer(pid).ShowLuckyPack{It=it}
	return true
end
function cs_itemActionc.luckyid(role, id, key, val, Num, Sel, it)
	local lucknum = Item.getv(it, 'lucknum')
	if lucknum then return end --己开
	local cfg = cfg_luckpack[val]
	if not cfg then return end
	return true
end

function cs_itemAction.ifunlock(role, id, key, val, Num, Sel, it) --ifunlock={unlock='XXXX', item={itemA, num, bind}, elseitem={itemB, num, bind}}
	local pid = role.getPID()
	if LockMgr.isUnlock(pid, val.unlock) then
		giveItem{pid=pid, id=val.item[1], num=val.item[2]*Num, bind=val.item[3], lab='item'..id, mail=true, try=false}
	else
		giveItem{pid=pid, id=val.elseitem[1], num=val.elseitem[2]*Num, bind=val.elseitem[3], lab='item'..id, mail=true, try=false}
	end
	return
end

when{} function afterConfig()
	-- 成长系统展示皮肤
	for k, v in pairs( Cfg.cfg_growsys{ } ) do
		if v.avachange then
			local func = function( role, id, key, val, num, Sel )
				return GrowSYS.openNewAva( role.getPID( ), k, val.ava, val.time, val.andshow )
			end
			local func1 = function( role, id, key, val, num, Sel )
				return GrowSYS.openNewAva( role.getPID( ), k, val.ava, val.time, val.andshow, true )
			end

			cs_itemAction[k..'ava'] = func
			cs_itemActionc[k..'ava'] = func1
			cfg_enum_item_action[k..'ava'] = {id=k..'ava'}
		end

		if v.fritem or v.frstar then
			local func = function( role, id, key, val, num, Sel )
				return GrowSYS.addFrApt( role.getPID( ), k, val * num )
			end
			local func1 = function( role, id, key, val, num, Sel )
				return GrowSYS.addFrApt( role.getPID( ), k, val * num, true )
			end

			cs_itemAction[k..'_frapt'] = func
			cs_itemActionc[k..'_frapt'] = func1
			cfg_enum_item_action[k..'_frapt'] = {id=k..'_frapt'}
		end

		if v.upbless then
			-- 祝福值卡
			local func = function( role, id, key, val, num, Sel )
				assert( num == 1, 'error pile use'..id )
				return GrowSYS.addBless( role.getPID( ), k, val.trytime, val.bless )
			end
			local func1 = function( role, id, key, val, num, Sel )
				assert( num == 1, 'error pile use'..id )
				return GrowSYS.addBless( role.getPID( ), k, val.trytime, val.bless, true )
			end

			cs_itemAction[k..'_upbless'] = func
			cs_itemActionc[k..'_upbless'] = func1
			cfg_enum_item_action[k..'_upbless'] = {id=k..'_upbless'}

			-- 升级卡
			local func = function( role, id, key, val, num, Sel )
				assert( num == 1, 'error pile use'..id )
				return GrowSYS.upLv( role.getPID( ), k, val.lv, val.items )
			end
			local func1 = function( role, id, key, val, num, Sel, try )
				assert( num == 1, 'error pile use'..id )
				return GrowSYS.upLv( role.getPID( ), k, val.lv, val.items, try )
			end

			cs_itemAction[k..'_uplv'] = func
			cs_itemActionc[k..'_uplv'] = func1
			cfg_enum_item_action[k..'_uplv'] = {id=k..'_uplv'}
		end

		if v.upapt then
			-- 成长值卡
			local func = function( role, id, key, val, num, Sel )
				assert( num == 1, 'error pile use'..id )
				return GrowSYS.addApt( role.getPID( ), k, val.apt )
			end
			local func1 = function( role, id, key, val, num, Sel, try )
				assert( num == 1, 'error pile use'..id )
				return GrowSYS.addApt( role.getPID( ), k, val.apt, try )
			end

			cs_itemAction[k..'_upapt'] = func
			cs_itemActionc[k..'_upapt'] = func1
			cfg_enum_item_action[k..'_upapt'] = {id=k..'_upapt'}

			-- 升星卡
			local func = function( role, id, key, val, num, Sel )
				assert( num == 1, 'error pile use'..id )
				return GrowSYS.upStar( role.getPID( ), k, val.lv, val.items )
			end
			local func1 = function( role, id, key, val, num, Sel, try )
				assert( num == 1, 'error pile use'..id )
				return GrowSYS.upStar( role.getPID( ), k, val.lv, val.items, try )
			end

			cs_itemAction[k..'_upstar'] = func
			cs_itemActionc[k..'_upstar'] = func1
			cfg_enum_item_action[k..'_upstar'] = {id=k..'_upstar'}
		end
	end
end

--藏宝图
function cs_itemAction.trek(role, Id, key, val, Num, Sel, it)
	local pid = role.getPID( )
	if Num ~= 1 then ErrHint( _T'藏宝图使用数量只能为1') end
	if not LockMgr.isUnlock(pid, 'trek') then ErrHint( _T'藏宝图功能尚未开启, 请先提升等级') end
	local t = NewTrek.getInfo( pid )
	if t and t.quality ~= -1 then ErrHint( _T'当前有未完成的藏宝任务') end
	local can, add = VIP.getVipPri( pid, 'addtreasure' )
	local maxnum = 0
	if can then
		maxnum = cfg_trek.quota + add
	else
		maxnum = cfg_trek.quota
	end
	if (t and t.count or 0) >= maxnum then ErrHint{ Msg = _T"今日寻宝次数已用尽" } return end

	NewTrek.comMarks( pid, val.quality )
	return true
end

--升级丹
function cs_itemAction.lvup(role, id, key, val, Num, Sel)
	local pid = role.getPID()
	for i=1, Num do
		local p = _ORM'player':where{ pid = pid }:select( )[1]
		if p.level < val.lvless then
			local exp = cfg_levelup[p.level].exp - cfg_levelup[p.level-1].exp
			Log.sys('cs_itemAction_lvup2', pid, id, Num, exp)
			giveItem{pid=pid, id=Item.EXP, num=exp, lab='item'..id, mail=true, try=false}
		else
			-- if p.level >= #cfg_levelup then
				-- local po = _ORM'playeroften':where{ pid = pid }:select( )[1]
				-- if po.exp >= cfg_levelup[maxlv].exp then
					-- return i-1
				-- end
			-- end
			giveItem{pid=pid, id=Item.EXP, num=val.elseexp, lab='item'..id, mail=true, try=false}
		end
	end
	return true
end
--vip
function cs_itemAction.vip(role, id, key, val, Num, sel)
	local isvip, t = VIP.isV( role.getPID( ), val.type )
	if t == -1 then return end
	VIP.xopen( role.getPID( ), val )
	return true
end
function cs_itemAction.xvip(role, id, key, val, Num, sel)
	local isvip, t = VIP.isV( role.getPID( ), val.type )
	if not isvip then return end
	if t == -1 then return end
	VIP.xopen( role.getPID( ), val )
	return true
end

function cs_itemAction.hallow(role, id, key, val, Num, Sel)
	Hallows.activeHallow( role, val )
end

function cs_itemActionc.hallow(role, id, key, val, Num, Sel)
	return Hallows.checkMyHallows( role, val )
end

function cs_itemAction.cutepet(role, id, key, val, Num, Sel)
	local pid = role.getPID( )
	LockMgr.unlock( pid, key..val )
end

function cs_itemActionc.cutepet(role, id, key, val, Num, Sel)
	local pid = role.getPID( )
	if not LockMgr.isUnlock( pid, 'cutepet' ) then return false end
	local lv = GrowSYS.getLv( pid, key..val )
	if( lv and lv > 0 ) then
		return false
	end
	return true
end

function cs_itemAction.cardsysid(role, id, key, val, Num, Sel)
	local pid = role.getPID( )

	local freepos = CardSys.getFreeBagPos( pid, 1 )
	if( #freepos < 1 ) then
		assert(false,'usecardsysiderror'..pid..' '..id..' '..#freepos)
		return
	end

	local info = {}
	_ORM'cardsys':insert{ pid = pid, mark = CardSys.markBag, pos = freepos[1], id = val, lv = 1,exp = 0 }
	info.addbag = { freepos[1] }
	info.useitem = val
	CardSys.syn( pid, info )
end

function cs_itemActionc.cardsysid(role, id, key, val, Num, Sel)
	local pid = role.getPID( )
	if not LockMgr.isUnlock( pid, 'cardsys' ) then return false end

	local freebagposes = CardSys.getFreeBagPos( pid, 1 )
	if( #freebagposes == 0 ) then
		return false
	end

	return true
end

function cs_itemAction.cardsysqua(role, id, key, val, Num, Sel)
	local pid = role.getPID( )

	local freepos = CardSys.getFreeBagPos( pid, 1 )
	if( #freepos < 1 ) then
		assert(false,'usecardsysquaerror'..pid..' '..id..' '..#freepos)
		return
	end
	local cardid = CardSys.quaToIds[ val ][ math.random( 1, #CardSys.quaToIds[ val ] ) ]

	local info = {}
	_ORM'cardsys':insert{ pid = pid, mark = CardSys.markBag, pos = freepos[1], id = cardid, lv = 1,exp = 0 }
	info.addbag = { freepos[1] }
	info.useitem = cardid
	CardSys.syn( pid, info )
end

function cs_itemActionc.cardsysqua(role, id, key, val, Num, Sel)
	local pid = role.getPID( )
	if not LockMgr.isUnlock( pid, 'cardsys' ) then return false end

	local freebagposes = CardSys.getFreeBagPos( pid, 1 )
	if( #freebagposes == 0 ) then
		return false
	end

	return true
end

function cs_itemAction.kidok(role, id, key, val, Num, Sel)
	local pid = role.getPID( )

	if( not Marry.ismarry( pid ) ) then
		return
	end
	local otherpid = Marry.getPid1( pid )
	if( not otherpid ) then
		return
	end

	local kidsys = MarryKid.get( pid )
	if( not kidsys ) then
		return
	elseif( not isSameTable( kidsys, MarryKid.get( otherpid ) ) ) then
		Log.sys( 'kidokerror',pid,otherpid )
		return
	elseif( MarryKid.getState( kidsys ) ~= 'pregnant' ) then
		return
	end

	_ORM:table'kidsys':where{ pid1 = kidsys.pid1, pid2 = kidsys.pid2, id = kidsys.id }:update{ birthtime = _now(0) - MarryKid.pregnanttime*3600000000 - 10000000 }

	local newkidsys = MarryKid.get( pid )
	CallPlayer( pid ).UpdateMarryKid{ Info = { update = newkidsys } }
	CallPlayer( otherpid ).UpdateMarryKid{ Info = { update = newkidsys } }
end

function cs_itemActionc.kidok(role, id, key, val, Num, Sel)
	local pid = role.getPID( )
	local kidsys = MarryKid.get( pid )
	if not kidsys then
		return false
	elseif( MarryKid.getState( kidsys ) ~= 'pregnant' ) then
		return false
	end

	return true
end

function cs_itemAction.nobilityval(role, id, key, val, Num, Sel)
	return Nobility.addPoint( role.getPID( ), val.val * Num )
end

function cs_itemActionc.nobilityval(role, id, key, val, Num, Sel)
	return Nobility.addPoint( role.getPID( ), val.val * Num, true )
end