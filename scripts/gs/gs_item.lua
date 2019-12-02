--
--gs_item.lua
_G.Item = {}
----------------------------------------------------------------
local Item = Item
----------------------------------------------------------------
Item.COINS	= 5000000		--金币+绑金 仅消耗用 增加视为绑金
Item.COIN	= 5000001		--金币
Item.COINB	= 5000002		--绑金
Item.GOLD	= 5000003		--元宝
Item.GOLDP	= 5000004		--礼金
Item.EXP	= 5000005 		--经验
----------------------------------------------------------------


function Item.have(pid, id)


end

function Item.delById(pid, id, num, lab)

end

function Item.getv(it, key)	--取实例值
	for i,k in ipairs(it.key) do
		if k == key then
			return it.val[i]
		end
	end
end

function Item.getAttr(it,role)--计算属性

end

function Item.timeOut(it)
	local timeout = it.timeto > 0 and it.timeto <=_now(0)
	return timeout
end

function Item.cd(unit,id)
	
	return
end


----------------------------------------------------------------
--event
function event.loadConfig()
	dofile"config/cfg_item.lua"
end
function event.afterConfig()

end
function event.defineRole(role)
	role.item = {}
	role.itemCD = {}
end
function event.loadUserInfo(info, role)
	print('loadUserInfo.item')
	role.item = info.item or role.item
	role.itemCD = info.itemCD or role.itemCD

end
