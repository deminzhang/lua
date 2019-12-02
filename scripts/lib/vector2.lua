
if _Vector2 then return end --if inC return
_G._Vector2 = {} --TODO xyz待改为123

local Epsilon=0.00001
local sqrt = math.sqrt
local format = string.format
local _meta
local function new(x,y)
	return setmetatable({x=x or 0, y=y or 0},_meta)
end
_meta = {__call = new, __index = _Vector2,
	__eq = function(a,b)	-- ==
		return abs(a.x-b.x)<Epsilon and abs(a.y-b.y)<Epsilon
	end,
	__unm = function(v)		-- -
		return new(-v.x, -v.y)
	end,
	__mul = function(a,b) 	-- *
		local tb=type(b)
		if tb=='number' then
			return new(a.x*b,a.y*b)
		else
			error(format('#2 number expected ,got %s',tb))
		end
	end,
	__div = function(v,b)	-- /
		return new(v.x/b,v.y/b)
	end,
	-- __tostring = function(self)
		-- return format('Vector2(%f,%f)',self.x,self.y)
	-- end,
}
_Vector2.new = new

function _Vector2:add(v2,out)
	out = out or new()
	out.x = self.x + v2.x
	out.y = self.y + v2.y
	return out
end
_meta.__add = _Vector2.add

function _Vector2:sub(v2,out)
	out = out or new()
	out.x = self.x - v2.x
	out.y = self.y - v2.y
	return out
end
_meta.__sub = _Vector2.sub

function _Vector2:mul(n,out)
	out = out or new()
	out.x = self.x * n
	out.y = self.y * n
	return out
end
_meta.__mul = _Vector2.mul

function _Vector2:div(n,out)
	out = out or new()
	out.x = self.x / n
	out.y = self.y / n
	return out
end
_meta.__div = _Vector2.div

function _Vector2:set(x,y)
	self.x = x or self.x
	self.y = y or self.y
	return self
end
--点乘
function _Vector2.dot(v1,v2)
	return v1.x*v2.x + v1.y*v2.y
end
--叉乘
function _Vector2.cross(v1,v2)
	return v1.x*v2.y - v1.y*v2.x
end
--绝对值
function _Vector2:absolute()

	return self
end
--距离
function _Vector2.distance(a,b)
	return sqrt((a.x-b.x)^2+(a.y-b.y)^2)
end
--模
function _Vector2:magnitude()
	return sqrt(self.x^2+self.y^2)
end
--copy归一
function _Vector2:normalize()
	return new(self.x,self.y):normalized()
end
--self归一
function _Vector2:normalized()
	local x,y = self.x,self.y
	if x==0 and y==0 then return self end
    local dis = sqrt(x^2 + y^2)
    if dis > Epsilon then
		self.x = x/dis
		self.y = y/dis
    end
	return self
end
--缩放
function _Vector2.scale(a,b,out)
	if out then
		out.x,out.y = a.x*b.x,a.y*b.y
		return out
	else
		return new(a.x*b.x,a.y*b.y)
	end
end

function _Vector2:clone()
	return new(self.x,self.y)
end
