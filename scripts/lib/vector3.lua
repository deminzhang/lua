
if _Vector3 then return end --if inC return
_G._Vector3 = {} --TODO xyz待改为123

local Epsilon=0.00001
local sqrt = math.sqrt
local format = string.format
local _meta
local function new(x,y,z)
	return setmetatable({x=x or 0, y=y or 0, z=z or 0},_meta)
end
_meta = {__call = new, __index = _Vector3,
	__eq = function(a,b)	-- ==
		return abs(a.x-b.x)<Epsilon and abs(a.y-b.y)<Epsilon
			and abs(a.z-b.z)<Epsilon
	end,
	__unm = function(v)		-- -
		return new(-v.x, -v.y, -v.z)
	end,
	__mul = function(a,b)	-- *
		local tb=type(b)
		if tb=='number' then
			return new(a.x*b,a.y*b,a.z*b)
		else
			error(format('#2 number expected ,got %s',tb))
		end
	end,
	__div = function(v,b)	-- /
		return new(v.x/b,v.y/b,v.z/b)
	end,
	-- __tostring = function(self)
		-- return format('Vector3(%f,%f,%f)',self.x,self.y,self.z)
	-- end,
}
_Vector3.new = new

function _Vector3:add(v2,out)
	out = out or new()
	out.x = self.x + v2.x
	out.y = self.y + v2.y
	out.z = self.z + v2.z
	return out
end
_meta.__add = _Vector3.add

function _Vector3:sub(v2,out)
	out = out or new()
	out.x = self.x - v2.x
	out.y = self.y - v2.y
	out.z = self.z - v2.z
	return out
end
_meta.__sub = _Vector3.sub

function _Vector3:mul(n,out)
	out = out or new()
	out.x = self.x * n
	out.y = self.y * n
	out.z = self.z * n
	return out
end
_meta.__mul = _Vector3.mul

function _Vector3:div(n,out)
	out = out or new()
	out.x = self.x / n
	out.y = self.y / n
	out.z = self.z / n
	return out
end
_meta.__div = _Vector3.div

function _Vector3:set(x,y,z)
	self.x = x or self.x
	self.y = y or self.y
	self.z = z or self.z
	return self
end
--点乘
function _Vector3.dot(v1,v2)
	return v1.x*v2.x + v1.y*v2.y + v1.z*v2.z
end
--叉乘
function _Vector3.cross(v1,v2,out)
	out = out or new()
	out.x = v1.y*v2.z - v1.z*v2.y
	out.y = v1.z*v2.x - v1.x*v2.z 
	out.z = v1.x*v2.y - v1.y*v2.x
	return out
end
--绝对值
function _Vector3:absolute()

	return out
end
--距离
function _Vector3.distance(a,b)
	return sqrt((a.x-b.x)^2+(a.y-b.y)^2+(a.z-b.z)^2)
end
--模
function _Vector3:magnitude()
	return sqrt(self.x^2+self.y^2+self.z^2)
end
--copy归一
function _Vector3:normalize()
	return new(self.x,self.y,self.z):normalized()
end
--self归一
function _Vector3:normalized()
	local x,y,z = self.x,self.y,self.z
	if x==0 and y==0 and z==0 then return self end
    local dis = sqrt(x^2 + y^2 + z^2)
    if dis > Epsilon then
		self.x = x/dis
		self.y = y/dis
		self.z = z/dis
    end
	return self
end
--缩放
function _Vector3.scale(a,b,out)
	if out then
		out.x,out.y,out.z = a.x*b.x,a.y*b.y,a.z*b.z
		return out
	else
		return new(a.x*b.x,a.y*b.y,a.z*b.z)
	end
end

function _Vector3:clone()
	return new(self.x,self.y,self.z)
end
