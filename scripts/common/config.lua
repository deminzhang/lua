print('>>config.lua')
--游戏结构配置
_G.CONFIG = {
	ROLE_CREATE_GOLD = 0, 		--新建角色充初始充值币 --TODO转设计配置
	--程序开发控制
	DISCONNECT_KICK_DELAY = 10, --掉线可重连时间s
	UPDATE_INTVAL = 100,		--主祯间隔ms
	PROFILER_INTVAL = 5000,		--性能统计间隔ms
	DAEMON_INTVAL = 9000,		--守护循环间隔ms
	TEST_AI_ALWAYS_AWAKE = true,--AI压力测试开关.无人视野也跑
	LEAK_CHECK = false,			--对象泄漏检查
}

local rawget = rawget
local rawset = rawset
local dofile = dofile
local pcall = pcall

_G.Cfg = setmetatable({},{
	__index = function(t,k)
		local v = rawget(t,k)
		if v then return v end
		local fn = ('config/%s.lua'):format(k)
		local ok, v = pcall(dofile,fn)
		if ok then
			--setmetatable(v,{__newindex=function() error('config data is readonly:'..k) end})
			rawset(t,k,v)
			--onLoadConfig{k=k,v=v}
			return v
		else
			error(v)
		end
	end,
})
