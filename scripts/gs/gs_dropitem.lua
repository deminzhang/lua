--
--gs_dropitem.lua
_G.DropItem = {}
----------------------------------------------------------------
local DropItem = DropItem
local _meta = Object.newMeta(DropItem)
----------------------------------------------------------------
DropItem.OWNTIME = 120000	--默认归属时间
DropItem.LIFTTIME = 120000	--默认存在时间
DropItem.DROPINTVAL = 200	--批暴落间隔
DropItem.PICKUPDIS = 300		--拾取距离
DropItem.COMBINE_FREQ = 1000--合并暴落间隔
----------------------------------------------------------------

function DropItem.new(id)


end

----------------------------------------------------------------
