--math.lua
math.randomseed(tostring(os.time()):reverse():sub(1, 6))
function toint(number, round)
	number = tonumber(number)
	if round==nil then
		if number>0 then
			return math.floor(number)
		else
			return math.ceil(number)
		end
	elseif round==0.5 then
		return math.round(number)
	elseif round<=-1 then
		return math.floor(number)
	elseif round>=1 then
		return math.ceil(number)
	end
end
function math.round(v)	--四舍五入
	local fv = math.floor(v)
	return v-fv<0.5 and fv or fv+1
end
function math.range(v,min,max)--限值
	return v < min and min or v > max and max or v
end
function math.percent(v,m)	--百分
	return math.random(v)<(m or 100)
end
function math.isRayCross(ray1,ray2)
	error('not ready')
end
function math.isLineCross(line1,line2)
	error('not ready')
end