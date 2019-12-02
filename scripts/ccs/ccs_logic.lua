--ccs_logic.lua
----------------------------------------------------------------
when{_order=0}
function event.onSecond()
	onSecond{_delay=1000}
end
when{_order=0}
function event.onMonitor()
	onMonitor{_delay=CONFIG.PROFILER_INTVAL}
	print(string.format('[MONITOR]:Net=%d ',
		Net.count() )
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
end
----------------------------------------------------------------
--RPC
define.Hello{T=''}
when{}
function event.Hello(T)
	print('Hello2CCS',T,_from)
end