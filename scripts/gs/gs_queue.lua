--do return end
--[[in C===================================================================
_queue(beforeCall, afterCall, errCall)
_enqueue(delay, from, nameorfunc, args)
_subqueue(start)
_callin(from, data)
--]]
--lua===================================================================
_queue(function( fn, args ) --beforecall begins
	-- _SQL:begin()
	_MDB:begin()
	--GMLog:begin()
	--print('begin', fn)
	_subqueue( true ) --启动子队列
end, function( fn ) --aftercall commits
	-- _SQL:commit()
	_MDB:commit()
	--GMLog:commit()
	--print('commit', fn)
	_subqueue( true ) --提交己启动队列,重新启动新子队列
	_subqueue( false )--回滚子队列
end, function( fn, err ) --errorcall rollbacks
	-- _SQL:rollback( )
	_MDB:rollback()
	--GMLog:rollback( )
	--print('rollback', fn, err)
	print(fn,err)
	_subqueue( false ) --回滚子队列
end)