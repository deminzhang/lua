--gs_logic.lua
----------------------------------------------------------------
--inner event
when{_order=0}
function event.onSecond()
	onSecond{_delay=1000}
end
when{_order=0}
function event.onUpdate()
	--World.update
	onUpdate{_delay=CONFIG.UPDATE_INTVAL}
end
when{_order=0}
function event.onMonitor()
	onMonitor{_delay=CONFIG.PROFILER_INTVAL}
	print(string.format('[MONITOR]:Net=%d Timer=%d Zone=%d Unit=%d(Role=%d Mon=%d)',
		Net.count(),Timer.count(),Zone.count(),Unit.count(),
		Unit.count('role'),Unit.count('monster') )
		)
end
function event.onDaemon()
	onDaemon{_delay=CONFIG.DAEMON_INTVAL}
	--if some loop crashed restart it
end
function event.onStart()
	onSecond{_delay=0}
	onUpdate{_delay=0}
	onMonitor{_delay=0}
	onDaemon{_delay=0}
end

----------------------------------------------------------------
--RPC
define.Hello{T=''}
when{}
function event.Hello(T)
	print('Hello2GS',T,_from)
end
