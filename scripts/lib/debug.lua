--if默认的error没debug.traceback rewrite
local DUMP_METATABLE = false

local error0 = error
function error(err)
	error0(debug.traceback(err,2))
end

local assert0 = assert
function assert(bool,err)
	assert0(bool,debug.traceback(err,2))
end

local print = print
function debug.print(...)
	local info = debug.getinfo( 2 )
	local dumpfrom = info.source .. '|' .. info.currentline --info.linedefined
	print(dumpfrom,...)
end
--_G.print = debug.print --show where print

local dumptab = {}
local push = table.push
local io_write = io.write
local file
local write = function(...)
	io_write(...)
	push(dumptab,...)
	if file then
		file:write(...)
	end
end
local dumped = {}
local function _dump(t,depth,lv,keysub)
	local tt = type(t)
	if lv then
		write("{ --",tostring(t),"\n")
	else
		if tt=='table' then
			write("[",tostring(t),"] = { --",tostring(t),"\n")
			lv = ''
			dumped[(t)] = true
		elseif tt=='userdata' then
			lv = ''
			write(tostring(t))
		elseif tt=='string' then
			write('"',t,'"\n')
			return
		else
			write(tostring(t),"\n")
			return
		end
	end
	local meta = getmetatable(t)
	if meta then
		if DUMP_METATABLE and type(meta)=='table' and not dumped[(meta)] then
			dumped[(meta)] = true
			write(lv,"  __metatable = ")
			_dump(meta,depth-1,lv..'  ',keysub)
		else
			write(lv,"  __metatable = ",tostring(meta),"\n")
		end
	end
	if tt=='table' then
		local idx = rawget(t,__index)
		if idx then
			write(lv,"  __index"," = ",tostring(idx),"\n")
		end
		local newidx = rawget(t,__newindex)
		if idx then
			write(lv,"  __newindex"," = ",tostring(newidx),"\n")
		end
		local keystr,valuestr
		for k,v in pairs(t) do
			local kt = type(k)
			local vt = type(v)
			local show = true
			if kt=='string' and vt~='table' then
				if keysub and not string.find(k,keysub) then
					show = false
				end
			end
			if show then
				if kt=='number' then
					keystr = lv.."  ["..k.."]"
				elseif kt=='table' then
					local meta = getmetatable(v)
					if meta then
						keystr = lv.."  ["..tostring(k).."](meta="..tostring(meta)..")"
					else
						keystr = lv.."  ["..tostring(k).."]"
					end
				else
					--TODO if k 中有非word加""
					keystr = lv.."  "..tostring(k)
				end
				if vt=='number' then
					write(keystr," = ",v,";\n")
				elseif vt=='string' then
					write(keystr," = '",v,"';\n")
				elseif vt=='table' then
					write(keystr," = ")
					if depth>1 and v~=_G and not dumped[(v)] then
						dumped[(v)] = true
						_dump(v,depth-1,lv..'  ',keysub)
					else
						write(tostring(v),';\n')
					end
				elseif vt=='userdata' then	--userdata
					local meta = getmetatable(v)
					if meta then
						write(keystr," = ")
						if depth>1 and v~=_G and not dumped[(v)] then
							dumped[(v)] = true
							_dump(v,depth-1,lv..'  ',keysub)
						else
							write(tostring(v),';\n')
						end
					else
						write(keystr," = ",tostring(v),';\n')
					end
				else	--userdata/function/boolean
					write(keystr," = ",tostring(v),';\n')
				end
			end
		end
	end
	write(lv.."};",'\n')
end
function dump(t,depth,logfile,keysub)
	if logfile then
		file = io.open(logfile, 'a')
	end
	local info = debug.getinfo( 2 )
	if info then
		local dumpfrom = info.source .. '|' .. info.currentline --info.linedefined
		write("Dump:",dumpfrom,'\n')
	else
		write("Dump:[C]",'\n')
	end
	_dump(t,depth or 5,nil,keysub)
	--print(table.concat(dumptab))
	dumped = {}
	dumptab = {}
	if file then
		file:close()
		file = nil
	end
end
debug.dump = dump

function debug.gc()
	collectgarbage('collect')
end

function debug.findupvalue(func, name)
	for i=1,math.huge do
		local k, v = debug.getupvalue(func, i)
		if k == nil then return end
		if k == name then
			return i, v
		end
	end
end

function debug.resetupvalue(func,name,newval)
	for i=1,math.huge do
		local k = debug.getupvalue(func, i)
		if k == nil then return false end
		if k == name then
			debug.setupvalue(func, i, newval)
			return true
		end
	end
end

--debug.findobj( _G, function(o)return o==? end, '_G' ) 
--debug.findobj( debug.getregistry(), function(o)return o==? end, '_REG') 
function debug.findobj( start, comp, root )
	local passed = { }
	passed[tostring] = true
	passed[debug] = true
	passed[table] = true
	-- TODO: more

	local getupvalues = function( f )
		local ups = { }
		local i = 1
		while true do
			local a, b = debug.getupvalue( f, i )
			if not a then break end
			i = i + 1
			ups[a] = b
		end
		return ups
	end

	local cp = function( t )
		local res = { }
		for k, v in pairs( t ) do res[k] = v end
		return res
	end

	local checktype = { }
	checktype['userdata'] = true
	checktype['table'] = true
	checktype['function'] = true

	local res = { }
	local stack = { }
	local function restrain( obj, name )
		if comp( obj ) then
			stack[#stack + 1] = name
			res[#res + 1] = cp( stack )
			stack[#stack] = nil
			return
		end
		if passed[obj] then return end
		if not obj then
			for i, v in ipairs( res ) do  print( v ) end
			assert( false )
		end
		passed[obj] = true
		if type( obj ) == 'function' then
			local mt = getupvalues( obj )
			local info = debug.getinfo( obj)
			stack[#stack + 1] = ('%s(function %s|%s)'):format( name, info.short_src,info.linedefined )
			restrain( mt, 'upvalues' )
			stack[#stack] = nil
		elseif type( obj ) == 'userdata' then
			local mt = getmetatable( obj )
			if mt then
				stack[#stack + 1] = ('%s(userdata)'):format( name )
				restrain( mt, 'metatables' )
				stack[#stack] = nil
			end
		elseif type( obj ) == 'table' then
			local mt = getmetatable( obj )
			local countk = true
			local countv = true
			if mt then
				stack[#stack + 1] = ('%s(table)%s'):format( name, mt )
				restrain( mt, 'metatable' )
				stack[#stack] = nil
				local mode = rawget(mt,'__mode')
				if mode then
					if mode:find( 'k' ) then countk = false end
					if mode:find( 'v' ) then countv = false end
				end
			end
			for k, v in pairs( obj ) do
				if countk and checktype[type( k )] then
					stack[#stack + 1] = ('%s(table)'):format( name )
					restrain( k, ('key%s|v=%s'):format( tostring( k ), tostring( v ) ) )
					stack[#stack] = nil
				end
				if countv and checktype[type( v )] then
					stack[#stack + 1] = ('%s(table)'):format( name )
					restrain( v, ('val|k=%s'):format( tostring( k ) ) )
					stack[#stack] = nil
				end
			end
		end
	end
	restrain( start, root or 'root' )
	return res
end

local clock = os.clock
local getinfo = debug.getinfo
function debug.profiler(maxsec, logfile) --统计性能,maxsec时间
	local t0 = clock()
	local t = {}
	debug.sethook(function(type,...)
		local info = getinfo(2)
		if info.short_src=='[C]' then return end
		if info.linedefined==0 then return end
		--debug.dump(info)
		local k = string.format('%s:%d\t%s',info.short_src,info.linedefined,info.name)
		if type=='call' then
			if not t[k] then
				info.count = 0
				info.sumtime = 0
				t[k] = info
			end
			t[k].time = clock()
		elseif type=='return' then
			local v = t[k]
			if v then
				local d = clock() - v.time
				v.count = v.count + 1
				v.sumtime = v.sumtime + d
				--debug.dump(t[k])
				--print(k,'|',v.count,v.sumtime,d)
			end
		end
		if maxsec>0 and clock()-t0>maxsec then
			debug.sethook()
			for k,v in pairs(t) do if v.sumtime==0 then t[k]=nil end end
			table.sort(t,table.desc'sumtime')
			--debug.dump(t)
			local file = io.open(logfile, 'a')
			for k,v in pairs(t)do
				print(k,v.count,v.sumtime,v.sumtime/v.count)
				file:write(k,'\t',v.count,'\t',v.sumtime,'\t',v.sumtime/v.count,'\n')
			end
			file:close()
			file = nil
		end
	end, "cr")
end

function debug.loopfind()
	local t0 = clock()
	local t = {}
	debug.sethook(function(type,...)
		local info = getinfo(2)
		if info.short_src=='[C]' then return end
		if info.linedefined==0 then return end
	end, "cr")
end

-- 检查死循环
-- local _cnts = {}
-- local _lv = 0
-- function FOR()
	-- _lv = _lv + 1
-- end
-- function DOFOR()
	-- _cnts[_lv] = (_cnts[_lv] or 0) + 1
	-- warn(_cnts[_lv] < 99999, 'too many loops')
-- end

-- local s = [[
	-- for i,v in pairs({}) do
		-- for i,v in pairs({}) do
		
		-- end
	-- end
	
	-- while true do
	-- end
	
	-- repeat
	-- until true
-- ]]
-- local s= string.gsub(s,'(for)(.-)(do)', 'FOR()%1%2%3 DO()')
-- local s= string.gsub(s,'(while)(.-)(do)', 'WHITLE()%1%2%3 DO()')
-- local s= string.gsub(s,'(repeat)(.-)(until)', 'RPT()%1 UTL()%2%3')
-- print(s)

