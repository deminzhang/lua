--Zone.TileMgr AOI
_G.TileMgr = {}
----------------------------------------------------------------
--const
local DEFAULT_TILEX = 1200 --默认总宽
local DEFAULT_TILEZ = 1200 --默认总宽
local DEFAULT_TILEW = 60 --默认格宽
local TILE_TYPE = 9 --7/9
----------------------------------------------------------------
--tolocal
local TileMgr = TileMgr
local new = table.new
local insert = table.insert
local ceil = math.ceil
----------------------------------------------------------------
--local
local function tileAddUnit(self, unit)
	local guid = unit.guid
	local units = self.units
	assert(not units[guid], guid)
	units[guid] = unit.type or true
	unit.tile = self
	if unit.type=='role' then
		self.roleNum = self.roleNum + 1
		--激活视野内sleep的AI单位到()--zone.unit_update
	end
end

local function tileDelUnit(self, unit)
	local guid = unit.guid
	local units = self.units
	assert(units[guid], guid)
	units[guid] = nil
	unit.tile = false
	if unit.type=='role' then
		self.roleNum = self.roleNum - 1
		--if视野内玩家或玩家控制单位数为0则sleep战斗中的返营后sleep()
	end
end
--九宫格
local function tileAllSight9(self,range)
	if self.tilesAdjacent then return self.tilesAdjacent end
	if not range then range = 1 end
	local t = {}
	local tiles = self.tileMgr
	local row, col = self.row, self.col
	for r = row-range, row+range do
		local a = tiles[r]
		if a then
			for c = col-range, col+range do
				local v = a[c]
				if v then t[v] = true end
			end
		end
	end
	self.tilesAdjacent = t
	return t
end
--蜂巢七宫格
local function tileAllSight7(self,range)
	if self.tilesAdjacent then return self.tilesAdjacent end
	--if not range then range = 1 end
	local t = {}
	local tiles = self.tileMgr
	local row, col = self.row, self.col
	for r = row-1, row+1 do
		local a = tiles[r]
		if a then
			if r==row then
				for c = col-1, col+1 do
					local v = a[c]
					if v then t[v] = true end
				end
			elseif row%2==0 then
				for c = col-1, col+1-1 do
					local v = a[c]
					if v then t[v] = true end
				end
			else
				for c = col-1+1, col+1 do
					local v = a[c]
					if v then t[v] = true end
				end
			end
		end
	end
	self.tilesAdjacent = t
	return t
end
----------------------------------------------------------------
--global
function TileMgr.new(tilex,tilez,tilew)
	tilex = tilex or DEFAULT_TILEX
	tilez = tilez or DEFAULT_TILEZ
	tilew = tilew or DEFAULT_TILEW
	local coln = ceil(tilex/tilew)
	local rown = ceil(tilez/tilew)
	local tm = {
		tilex = tilex,
		tilez = tilez,
		coln = coln,	--x向格数
		rown = rown,	--y(z)格数
		tilew = tilew, 	--格宽
		getTile = TileMgr.getTile, --坐标所属格子
	}
	for r = 1, rown do
		local t = {}
		insert(tm, t)
		for c = 1, coln do
			insert(t, {
				row = r, col = c, --行,列
				tileMgr = tm,
				units = {}, --[unit]=unit.type or true
				tilesAdjacent = false, --算一次
				roleNum = 0,
				allSight = TILE_TYPE==7 and tileAllSight7 or tileAllSight9,
				addUnit = tileAddUnit,
				delUnit = tileDelUnit,
			})
		end
	end
	return tm
end

function TileMgr.new7(coln,rown,tilew)
	coln = coln or DEFAULT_TILEX
	rown = rown or DEFAULT_TILEY
	tilew = tilew or DEFAULT_TILEW
	local tm = {
		maxX = coln*tilew,
		maxY = rown*tilew,
		coln = coln, --x向格数
		rown = rown, --y(z)格数
		width = tilew, --格宽
		getTile = TileMgr.getTile, --坐标所属格子
	}
	for r = 1, rown do
		local t = {}
		insert(tm, t)
		for c = 1, r%2==0 and (coln+1) or coln do --偶数列额外加一格
			insert(t, {
				row = r, col = c, --行,列
				tileMgr = tm,
				units = {}, --[unit]=unit.type or true
				tilesAdjacent = false, --算一次
				roleNum = 0,
				allSight = TILE_TYPE==7 and tileAllSight7 or tileAllSight9,
				addUnit = tileAddUnit,
				delUnit = tileDelUnit,
			})
		end
	end
	return tm
end

--九宫格 如地图(0,0)在中心需 + tiles.coln/2
function TileMgr.getTile(tileMgr, x, z) 
--r5[51][52][53][54][55]
--r4[41][42][43][44][45]
--r3[31][32][33][34][35]
--r2[21][22][23][24][25]
--r1[11][12][13][14][15]
-----c1  c2  c3  c4...coln
	local tilew = tileMgr.tilew
	local r = ceil(z/tilew)
	if tileMgr[r] then
		local c = ceil(x/tilew)
		return tileMgr[r][c]
	end
end
--蜂巢七宫格
function TileMgr.getTile7(tileMgr, x, z)
--r5[51][52][53][54][55]
--[41][42][43][44][45][46]
--r3[31][32][33][34][35]
--[21][22][23][24][25][26]
--r1[11][12][13][14][15]
-----c1  c2  c3  c4...coln
	local tilew = tileMgr.tilew
	local r = ceil(z/tilew)
	if tileMgr[r] then
		local c
		if r%2==0 then	--偶数列
			c = ceil((x+tilew/2)/tilew)
		else
			c = ceil(x/tilew)
		end
		return tileMgr[r][c]
	end
end

----------------------------------------------------------------
TileMgr.getTile = TILE_TYPE==7 and TileMgr.getTile7 or TileMgr.getTile
TileMgr.new = TILE_TYPE==7 and TileMgr.new7 or TileMgr.new
----------------------------------------------------------------
return TileMgr