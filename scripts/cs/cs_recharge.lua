--cs_recharge.lua
local keyidx={'sid','uid','oid','money','gold','time','platform'}

--充值
function _G.Recharge(uid,order,channel,rmb,gold)--帐号，订单号，渠道名，充值RMB，得元宝
	local p = _ORM'player':where{ uid=uid, delflag=false }:select()
	if not p then return -11 end	--帐号或角色不存在
	p = p[1]
	local a = _ORM:table'account':where{uid=uid}:select()[1]
	local createserver = a.server_id --合服前源服id
	local orderid = createserver..'_'..order
	local oldlog = _ORM'recharge':where{ orderid=orderid }:select()
	if oldlog then return -12 end--重复使用的订单号
	local pid = p.pid
	local old = a.gold
	local oldacc = a.accgold
	local new = old + gold
	local newacc = oldacc + gold
	local newtimes = a.rechargetimes+1
	_ORM'account':where{uid=uid}:update{gold=new, accgold=newacc, rechargetimes=newtimes}
	--日志
	local d = _time({}, _now())
	local daykey = d.year*10000+d.month*100+d.day--日键，充值日查询用
	local lg = DefaultDB.get'recharge'	--可读额外日志
	lg.orderid	= orderid
	lg.uid		= uid
	lg.daykey	= daykey
	lg.channel	= channel
	lg.rmb		= rmb
	lg.gold		= gold
	lg.fgold	= new
	lg.time		= _now(0)
	_ORM'recharge':insert(lg)
	Log.sys('>>RechargeOK:', uid, order, channel, rmb, gold, p.pid, p.name)
	onGetGold{pid=pid,num=gold,lab='recharge',old=old,new=new, acc=newacc, cost=a.costgold}
	if channel~='gm' then
		CYLog.log( 'recharge', { roleid=pid,uid=uid,amount=gold,money=toint(rmb),channel=channel,balance=new,level=p.level,order=order, accgold=newacc, acccost=a.costgold}, Client.byPID(pid) )
	end
	CallPlayer(pid).Gold{Num=new,Add=gold,Acc=newacc,Cost=a.costgold, T={rechargetimes=newtimes,dailyrecharge=Role.getDailyRecharge(pid)} }
	return 1
end

--event ------------------------------
when{} function loadConfigCS()
	DefaultDB.add( 'recharge', {
		orderid	= 0,		--定单号
		uid		= '',		--帐号account.uid
		daykey	= 0,		--日期键YYYYMMDD用于日充值统计查询
		channel	= '',		--渠道
		rmb		= 0,		--现金值(分)
		gold	= 0,		--充值量
		fgold	= 0,		--充值后
		time	= 0,		--时间
	} )
end


_G.rechargeip = {
	'121.43.115.122',
	'121.43.115.123',
	'10.1.33.242',
	'124.65.159.118',
	'119.29.205.241',
	'47.88.5.230',		--191game的充值白名单
	'10.117.226.249',	--191game的充值白名单
	'124.236.131.132',	--191game的充值白名单
}

when{ Interface = 'pay', _order = 0 }function http( Params, _args )
	if _G.rechargeip then
		local invalid = true
		for i, v in ipairs( rechargeip ) do
			if v == _from.ipstr then invalid = false break end
		end
		if invalid then
			Log.sys( "rechargeinvalid", _from.ipstr, table.tostr( Params ) )
			_from:close'invalid_rechargeip'
			_args._stop = true
			return
		end
	end
end

if os.info.platform == 'tencent' then
	--[[
		openid	string	与APP通信的用户key，跳转到应用首页后，URL后会带该参数。由平台直接传给应用，应用原样传给平台即可。
		根据APPID以及QQ号码生成，即不同的appid下，同一个QQ号生成的OpenID是不一样的。
		appid	string	应用的唯一ID。可以通过appid查找APP基本信息。
		ts	string	linux时间戳。
		注意开发者的机器时间与腾讯计费开放平台的时间相差不能超过15分钟。
		payitem	string	物品信息。
		（1）接收标准格式为ID*price*num，回传时ID为必传项。批量购买套餐物品则用“;”分隔，字符串中不能包含"|"特殊字符。
		（2）ID表示物品ID，price表示单价（以Q点为单位，单价最少不能少于2Q点，1Q币=10Q点。单价的制定需遵循道具定价规范），num表示最终的购买数量。
		示例：
		批量购买套餐，套餐中包含物品1和物品2。物品1的ID为G001，该物品的单价为10Q点，购买数量为1；物品2的ID为G008，该物品的单价为8Q点，购买数量为2，则payitem为：G001*10*1;G008*8*2 。
		token	string	应用调用v3/pay/buy_goods接口成功返回的交易token。
		注意，交易token的有效期为15分钟，必须在获取到token后的15分钟内传递该token，否则将会返回token不存在的错误。
		billno	string	支付流水号（64个字符长度。该字段和openid合起来是唯一的）。
		version	string	协议版本号，由于基于V3版OpenAPI，这里一定返回“v3”。
		zoneid	string	在支付营销分区配置说明页面，配置的分区ID即为这里的“zoneid”。
		如果应用不分区，则为0。
		回调发货的时候，根据这里填写的zoneid实现分区发货。
		注：2013年后接入的寄售应用，此参数将作为分区发货的重要参数，如果因为参数传错或为空造成的收入损失，由开发商自行承担。
		providetype	string	发货类型，这里请传入0。
		0表示道具购买，1表示营销活动中的道具赠送，2表示交叉营销任务集市中的奖励发放。
		amt	string	Q点/Q币消耗金额或财付通游戏子账户的扣款金额。可以为空，若传递空值或不传本参数则表示未使用Q点/Q币/财付通游戏子账户。
		允许游戏币、Q点、抵扣券三者混合支付，或只有其中某一种进行支付的情况。用户购买道具时，系统会优先扣除用户账户上的游戏币，游戏币余额不足时，使用Q点支付，Q点不足时使用Q币/财付通游戏子账户。
		这里的amt的值将纳入结算，参与分成。
		注意，这里以0.1Q点为单位。即如果总金额为18Q点，则这里显示的数字是180。请开发者关注，特别是对账的时候注意单位的转换。
		payamt_coins	string	扣取的游戏币总数，单位为Q点。可以为空，若传递空值或不传本参数则表示未使用游戏币。
		允许游戏币、Q点、抵扣券三者混合支付，或只有其中某一种进行支付的情况。用户购买道具时，系统会优先扣除用户账户上的游戏币，游戏币余额不足时，使用Q点支付，Q点不足时使用Q币/财付通游戏子账户。
		游戏币由平台赠送或由好友打赏，平台赠送的游戏币不纳入结算，即不参与分成；好友打赏的游戏币按消耗量参与结算（详见：货币体系与支付场景）。
		pubacct_payamt_coins	string	扣取的抵用券总金额，单位为Q点。可以为空，若传递空值或不传本参数则表示未使用抵扣券。
		允许游戏币、Q点、抵扣券三者混合支付，或只有其中某一种进行支付的情况。用户购买道具时，可以选择使用抵扣券进行一部分的抵扣，剩余部分使用游戏币/Q点。
		平台默认所有上线支付的应用均支持抵扣券。自2012年7月1日起，金券银券消耗将和Q点消耗一起纳入收益计算（详见：货币体系与支付场景）。
		sig	string	请求串的签名，由需要签名的参数生成。
		（1）签名方法请见文档：腾讯开放平台第三方应用签名参数sig的说明。
		（2）按照上述文档进行签名生成时，需注意回调协议里多加了一个步骤：
		在构造源串的第3步“将排序后的参数(key=value)用&拼接起来，并进行URL编码”之前，需对value先进行一次编码 （编码规则为：除了 0~9 a~z A~Z !*() 之外其他字符按其ASCII码的十六进制加%进行表示，例如“-”编码为“%2D”）。
		（3）以每笔交易接收到的参数为准，接收到的所有参数除sig以外都要参与签名。为方便平台后续对协议进行扩展，请不要将参与签名的参数写死。
		（4）所有参数都是string型，进行签名时必须使用原始接收到的string型值。 开发商出于本地记账等目的，对接收到的某些参数值先转为数值型再转为string型，导致字符串部分被截断，从而导致签名出错。如果要进行本地记账等逻辑，建议用另外的变量来保存转换后的数值。
	]]
	when{ Interface = 'pay' } function http( Action, Params )
		Log.sys( "Recharge1", table.tostr( Params ) )
		local openid = Params.openid
		local zoneid = Params.zoneid
		local map = TecentMap[openid]
		local sid = zoneid == '0' and os.info.server_id or ( map and map[zoneid] )
		local uid0 = sid .. '|' .. openid
		local c = Client.byUID( uid0 )
		if not c then
			Net.sendJson( _from, { ret = 4, msg = '角色不在线' } )
			return
		end
		local appid = Params.appid
		local ts = Params.ts
		local payitem = Params.payitem
		local token = Params.token
		local billno = Params.billno
		local version = Params.version
		local providetype = Params.providetype
		local amt = Params.amt
		local payamt_coins = Params.payamt_coins
		local pubacct_payamt_coins = Params.pubacct_payamt_coins
		local sig = Params.sig
		Params.sig = nil
		local sign, sourcestr = getPaySign( Action, "/pay", Params )
		Log.sys( "RechargeSign", sig, sign, sourcestr )
		if CHECKTENCENTSIGN and sig ~= sign then
			Net.sendJson( _from, { ret = 4, msg = 'param sig error' } )
			return
		end
		local oid = openid.."|"..billno
		local money = toint( tonumber(amt) )	--rmb分
		local ss = string.split( payitem, "%*" )
		local gold
		local itemid = ss[1]
		local num = ss[3] or 1
		for _, idx in next, cfg_pay do
			if idx.payitem:lead( itemid ) then
				gold = idx.pay * toint( num )	--充值币
			end
		end
		local time = ts		--unix时间秒
		local platform = os.info.platform
		local sign = sig
		Log.sys( "Recharge2", uid0, oid, platform or '', money, gold )
		local r = Recharge( uid0, oid, platform or '', money, gold )
		Log.sys( "Recharge3", r )
		if r == 1 then
			Net.sendJson( _from, { ret = 0, msg = 'suc' } )
			--通知腾讯
			local info = c.getNet( )._logininfo
			--过早确认订单，腾讯会报错
			confirm_delivery{ cinfo = { openid, info, ts, payitem, token, billno, zoneid, amt, payamt_coins }, _delay = 1}
		else
			Net.sendJson( _from, { ret = 4, msg = tostring( r ) } )
		end
	end

	cdefine.ignore.confirm_delivery{ cinfo = { }}
	when{}
	function confirm_delivery( cinfo )
		local openid, info, ts, payitem, token, billno, zoneid, amt, payamt_coins =
		cinfo[1], cinfo[2], cinfo[3], cinfo[4], cinfo[5], cinfo[6], cinfo[7], cinfo[8], cinfo[9], cinfo[10]
		openapi_confirm_delivery( function( result )
			Log.sys( "rechargecomfire", openid, result )
		end, function( err )
			Log.sys( "rechargefail", openid, err )
		end, openid, info.openkey, info.rechargepf or info.pf, ts, payitem, token, billno, zoneid, 0, amt, payamt_coins )
	end
else
	when{ Interface = 'pay' } function http( Params )
		local response = function( s, s1 )
			Net.sendText( _from, tostring(s) )
			Log.sys( 'payrespond', s, s1 or 'noreason' )
		end
		Log.sys('pay', table.tostr( Params ), _from.ipstr )
		local sid = Params.sid				--服id
		local uid = Params.uid				--uid
		local oid = Params.oid				--定单号
		local money = toint(Params.money) 	--rmb分
		local gold = toint(Params.gold) 	--充值币
		local time = toint(Params.time)		--unix时间秒
		local platform = Params.platform
		local sign = Params.sign

		if not sid then response( -19, 'nosid' ) return end
		if not uid then response( -19, 'nouid' ) return end
		if not oid then response( -19, 'nooid' ) return end
		if not money then response( -19, 'nomoney' ) return end
		if not gold then response( -19, 'nogold' ) return end
		sid = WrapPlatSid( sid )
		if not NOPAYAUTH then
			if not time then response( -19, 'notime' ) return end
			if not platform then response( -19, 'noplatform' ) return end
			if not sign then response( -19, 'nosign' ) return end

			local timeout = math.abs( unixNow0( ) - time * 1000000 ) > 300000000
			if timeout then return response( -14, 'timeout' ) end 	--TODO 定单过期 关闭方便测试与补单
			if money <= 0 then response( -15, 'invalidmoney' ) return end
			if gold <= 0 then response( -16, 'invalidgold' ) return end

			local kvs = {}
			for i,k in ipairs(keyidx) do
				kvs[#kvs+1] = k..'='..Params[k]
			end

			local fmt = table.concat(kvs,'&')..Cfg_Plat.RechargeKey

			Log.sys( fmt )
			local csign = fmt:md5()
			Log.sys( fmt, csign, sign,'all' )
			if sign ~= csign then response( -17 ) return end
		end

		local uid0 = sid .. '|' .. uid
		local r = Recharge( uid0, oid, platform or '', money, gold )
		response( r )
		return
	end
end