--cs_logic.lua
----------------------------------------------------------------
--inner event
when{_order=0}
function event.onSecond()
	onSecond{_delay=1000}
end
when{_order=0}
function event.onBigTime()
	onBigTime{_delay=60000}
end
when{_order=0}
function event.onUpdate()
	onUpdate{_delay=CONFIG.UPDATE_INTVAL}
end
when{_order=0}
function event.onMonitor()
	onMonitor{_delay=CONFIG.PROFILER_INTVAL}
	print(string.format('[MONITOR]:Net=%d Timer=%d Client=%d',
		Net.count(),Timer.count(),Client.count() )
		)
end
function event.onDaemon()
	onDaemon{_delay=CONFIG.DAEMON_INTVAL}
	--if some loop crashed restart it
end
function event.onStart()
	onSecond{}
	onUpdate{}
	onMonitor{}
	onDaemon{}
	onBigTime{}
end
----------------------------------------------------------------
--RPC
define.Hello{}
function event.Hello(T)
	print('Hello2CS',T,_from)
end

