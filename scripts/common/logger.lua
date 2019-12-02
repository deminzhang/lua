_G.Log = {_level=0}

local print = print
Log.print0 = print
function Log.print(...)
	print(os.date('%Y-%m-%d %X'),...)
end
function Log.sys(...)
	print(os.date('%Y-%m-%d %X'),...)
end
function Log.error(...)
	print('ERR',os.date('%Y-%m-%d %X'),...)
end
function Log.warn(...)
	print('WARN',os.date('%Y-%m-%d %X'),...)
end
function Log.debug(...)
	print('DEBUG',os.date('%Y-%m-%d %X'),...)
end
--_G.print = Log.sys
