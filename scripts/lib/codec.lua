
--[[in C===================================================================
local data,len = _encode(p1,...) --p1 must not nil
local p1,... = _decode(pack)
_callin( net, data )
_callout( remote,onCallout:(remote,name,args,_encode(name,args)) 
--]]
--lua===================================================================
--[[
_decode = _decode or --in C
function( data ) --temp low test
	local a, b = string.find(data,'{')
	if a then
		local fn = string.sub(data,1,a-1)
		local args = load('return '..string.sub(data, b, -1) )()
		return fn, args
	end
end
_encode = _encode or --in C
function( rpc, data ) --temp low test
	local s
	if rpc then
		s = rpc..table.tostr(data)
	else
		s = table.tostr(data)
	end
	return s, #s
end
_callout = _callout or --in C
if not _callout( net ) then
	_callout( net, function( net, rpc, args, data, len )
		local data,len = _encode(rpc,args)
		net:send(string.from32l(len))
		net:send(data,len)
	end, 0 )
end
_G._callout = _callout or function(o,onCallout)
	local mt = getmetatable(o)
	local _index = mt and mt.__index
	if _index then
		if onCallout then
			assert(mt.__callout~=_index,'"already _callout with a different function'..tostring(_index))
		else
			return mt.__callout==_index
		end
	end
	local _rpcs = {}
	local callout = function(o,k)
		local l = string.sub(k,1,1)
		if l>='A' and l<='Z' then
			local cc = _rpcs[o]
			if not cc then
				cc = {}
				_rpcs[o] = cc
			end
			local c = cc[k]
			if not c then
				c = function(t)
					return onCallout(o,k,t,_encode(k,t))
				end
				cc[k] = c
			end
			return c
		end
		if type(_index)=='table' then
			return _index[k]
		elseif type(_index)=='function' then
			return _index(o,k)
		end
	end
	if mt then
		mt.__index = callout
		mt.__callout = callout
	else
		mt = {__index=callout,__callout=callout}
		setmetatable(o,mt)
	end
	return o
end
--]]

function proto.protoc(package, files)


end
--syntax="proto3" or "proto2"
function proto.package(syntax)

	return setmetatable({}, {__newindex = function(self, name, message)
		local fields = {} 
		for _,v in pairs(message) do fields[v[4]] = v end
		local _meta = {name=name,syntax = syntax, message = message, fields = fields}
		_meta.__index = {
			encode = proto.encode,
			decode = function(buf)
				print("decode:",name)
				return proto.decode(buf, setmetatable({}, _meta))
			end,
		}
		_meta.__call = function(self,t)
			return setmetatable(t, _meta)
		end
		rawset(self, name, setmetatable({}, _meta))
	end})
end

function protobufdev()
	assert(proto,'proto required')
	dump(proto)
	

	local syntax = "proto2"
	local protos = proto.package(syntax)

	local TestEnum = {
		MONDAY = 0,
		SUNDAY = 1,
	}
	rawset(protos,"TestEnum",TestEnum)
	
	protos.TestChild = {
		{proto.OPT, proto.sint64, 'Fsint64',1 },
	}
	
	protos.TestType = {
		{proto.OPT, proto.int32, 'Fint32', 1},
		{proto.OPT, proto.int64, 'Fint64', 2},
		{proto.OPT, proto.uint32, 'Fuint32', 3},
		{proto.OPT, proto.uint64, 'Fuint64', 4},
		{proto.OPT, proto.sint32, 'Fsint32', 5},--zigzag32
		{proto.OPT, proto.sint64, 'Fsint64', 6},--zigzag64
		{proto.OPT, proto.fixed32, 'Ffixed32', 7},
		{proto.OPT, proto.fixed64, 'Ffixed64', 8},
		{proto.OPT, proto.double, 'Fdouble', 9},
		{proto.OPT, proto.float, 'Ffloat', 10}, --warning:lua用float通信会损失精度,建议浮点都用double
		{proto.OPT, proto.bool, 'Fbool', 11},
		{proto.OPT, proto.enum, 'Fenum', 12, enum=TestEnum},
		{proto.REP, proto.message, 'Frepmessage', 14, msg=protos.TestChild},
		{proto.REP, proto.bool, 'Frepeatbool', 15},
		{proto.OPT, proto.string, 'Fstring', 16},
		{proto.OPT, proto.bytes, 'Fbytes', 17},
		{proto.OPT, proto.sfixed32, 'Fsfixed32', 18},
		{proto.OPT, proto.sfixed64, 'Fsfixed64', 19},
		{proto.REP, proto.int32, 'Frepeatint', 20},
		{proto.REP, proto.bool, 'Frepeatbool2', 21, packed=true},
		{proto.REP, proto.int32, 'Frepeatint2', 22, packed=true},
		{proto.REP, proto.string, 'Fstring2', 23},
		{proto.OPT, proto.message, 'Fmessage', 24, msg=protos.TestChild},
		{proto.REP, proto.message, 'Frepc', 25, msg=protos.TestChild},
	}
	
	local b = protos.TestChild{
		Fsint64 = 123,
	}:encode()
	print("TestType:",b)
	local t0 = protos.TestType{
		-- Fint32 = -2100000000,
		-- Fint64 = -123000000000,
		-- Fuint32 = 4100000000,
		-- Fuint64 = 123000000000,
		-- Fsint32 = -123000000,
		-- Fsint64 = 123000000000,
		
		-- Ffixed32 = -123000000,
		-- Ffixed64 = 12300000000,
		Fdouble = math.pi, 
		Ffloat = math.pi,
		-- Fbool = true,
		-- Fbool = false,
		-- Fstring = "abcde",
		-- Fbytes = 'abc',
		-- Fsfixed32 = -123000000,
		-- Fsfixed64 = -12300000000,
		-- Frepeatbool = {true, false, true},
		-- Frepeatbool2 = {true, false, true},
		-- Frepeatint = {255, 65536},
		-- Frepeatint2 = {255, 65536},
		-- Fstring2 = {"abc","bvdd"},
		-- Fenum = protos.TestEnum.SUNDAY,
		-- Fmessage = protos.TestChild{
			-- Fsint64 = 123,
		-- },
		-- Frepc = {protos.TestChild{
			-- Fsint64 = 123,
		-- },protos.TestChild{
			-- Fsint64 = 234,
		-- }},
		
	}
	local b = t0:encode()
	print(#b,"TestType:",b)
	local t = protos.TestType.decode(b)
	dump(t0)
	dump(t)
	for k,v in pairs(t0) do
		if t[k]~=v then
			print("not eq:",k)
		end
	end
	
end
protobufdev()
