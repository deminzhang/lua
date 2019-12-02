_G.const = {} --常量,可赋不可更
local tb = {}
setmetatable(const,{__index=tb,__newindex=function(t,k,v)
	assert(tb[k]==nil, k..' const can not be changed')
	tb[k] = v
end})
