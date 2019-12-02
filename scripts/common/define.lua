--define.lua
print('>>common define')
_G.EMPTY = setmetatable({},{__newindex=function()error('EMPTY is a readonly table') end})
--common init
define.loadConfig{}		--配置加载/初始化
define.afterConfig{}	--配置交叉关联与重组
define.checkConfig{}	--配置检查
define.onStart{}		--正式启动
--common loop
define.onSecond{}		--秒循环
define.onUpdate{}		--主帧循环
define.onMonitor{}		--统计循环
define.onDaemon{}		--守护循环