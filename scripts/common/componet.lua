--Componet.lua ing
_G.Componet = {}
----------------------------------------------------------------
local typeGroup = {}  --{[type] = {[obj]=componet,...},...}
local typeClass = {}
local comp2obj = table.weakkv()
----------------------------------------------------------------
function Componet.register(type,class)
	assert(typeGroup[type],'Componet.reg repeat:'..type)
	typeGroup[type] = table.weakk()
	typeClass[type] = class
	local meta = getmetatable(class)
	if meta then
		meta.__call = class.new or function() return {} end
	else
		class.new = function() return {} end
	end
end

function Componet.getClass(type)
	return type and typeClass[type] or typeClass
end

function Componet.getAllByType(type)
	return typeGroup[type]
end

function Componet.add(obj,type,...)
	assert(not typeGroup[type][obj], 'Componet.add repeat')
	local comp = typeClass[type].new(...)
	typeGroup[type][obj] = comp
	comp2obj[comp] = obj
end

function Componet.del(obj,type,...)
	local comp = typeGroup[type][obj]
	if comp then
		typeGroup[type][obj] = nil
		comp2obj[comp] = nil
	end
end

function Componet.get(obj,type)
	return typeGroup[type][obj]
end

function Componet.getObj(comp)
	return comp2obj[comp]
end


----------------------------------------------------------------

