
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
	local f = io.open('proto/test2.proto','rb')
	local t = f:read("*a")
	f:close()
	local n = 0
	t = [[-------------------------------
local proto = proto
local OPT = proto.OPT
local REP = proto.REP
local REQ = proto.REQ
local bool  = proto.bool 
local enum  = proto.enum 
local int32 = proto.int32
local int64 = proto.int64
local uint32 = proto.uint32
local uint64 = proto.uint64
local sint32  = proto.sint32 
local zigzag32  = proto.zigzag32 
local zigzag64  = proto.zigzag64 
local fixed64  = proto.fixed64 
local sfixed64  = proto.sfixed64 
local double  = proto.double 
local string  = proto.string 
local bytes  = proto.bytes 
local fixed32  = proto.fixed32 
local float  = proto.float 
local message  = proto.message 
local map  = proto.map 

]]..t
	t,n = string.gsub(t,"//(.-)\n","--%1\n") --comment
	t,n = string.gsub(t,"Anytax%s*=%s*(%w+);","local syntax = %2") --syntax
	t,n = string.gsub(t,"syntax%s*=%s*(%w+);","local syntax = %2") --syntax
	t,n = string.gsub(t,"package%s+(%w+)%s*;","local _pb = proto.package(syntax)") --package
	t,n = string.gsub(t,"import%s+\"(%w+)%.proto\";","local %1 = require\"proto.%1\"") --import TODO
	
	-- repeat --嵌套message 提到local
	-- t,n = string.gsub(t,"(message%s*%w+%s*{.-)(message%s*%w+%s*{.-})(.-})", "%2\n%1%3") 
	-- until n==0
	
	t,n = string.gsub(t,"enum%s*(%w+)%s*{(.-)}","local %1 = _pb:enum('%1',{%2})") --enum
	t,n = string.gsub(t,"message%s*(%w+)%s*{(.-)}","local %1 = _pb:message('%1',{%2})") --message
	t,n = string.gsub(t,"(%w+%.?%w+)%s+(%w+)%s*=%s*(%d+)%s*%[(.+)%]%s*;","{OPT, %1, %2, %3, %4},")--field[packed=,default=]
	t,n = string.gsub(t,"(%w+%.?%w+)%s+(%w+)%s*=%s*(%d+)%s*;","{OPT, %1, %2, %3},")--field
	t,n = string.gsub(t,"map<(%w+),(%w+)>%s*(%w+)%s*=%s*(%d+)%s*;","{OPT, map, %3, %4, map={%1,%2},},") --map field
	t,n = string.gsub(t,"(required%s*{OPT)","{REQ") --assert(proto2
	t,n = string.gsub(t,"(optional","")				--if proto3
	t,n = string.gsub(t,"(repeated%s*{OPT)","{REP")
	t,n = t.."\nreturn _pb"
	t = '-------------------------------'..t
	print(t,n)
	
end

-- if proto.package==nil then
function proto.package(syntax)
	local pack = {}
	return setmetatable(pack, {
		__index = {
			enum = function(self, name, enum)
				local value = {}
				for k,v in pairs(enum) do
					assert(value[v]==nil,name.." duplicated enum value:"..v)
					value[v] = k 
				end
				setmetatable(enum,{__index={pbtype = proto.enum, value=value}})
				rawset(self,name,enum)
				return enum
			end,
			message = function(self, name, msg)
				local fields = {} 
				for _,v in pairs(msg) do
					local flab = v[1]
					local ftp = v[2]
					if type(ftp)=='table' then
						ftp = ftp.pbtype
					end
					local fname = v[3]
					local fn = v[4]
					assert(fields[fn]==nil,name.." duplicated field:"..fn)
					if syntax=='proto3' then
						assert(v[1]==proto.OPT or v[1]==proto.REP, 'proto3 unsupported '..fname)
						assert(v.default==nil,"[default] proto3 unsupported")
					end
					if ftp==proto.map and flab~=proto.OPT then
						error('Field labels are not allowed on map fields')
					end
					if not proto.primitive[ftp] then
						assert(v.packed~=true, '[packed=] can only be specified for repeated primitive fields:'..fname)
					end
					fields[fn] = v 
				end
				local _meta = {name=name,syntax = syntax, message = msg, fields = fields}
				_meta.__index = {
					pbtype = proto.message,
					encode = proto.encode,
					decode = function(buf)
						print("decode:",name)
						return proto.decode(buf, setmetatable({}, _meta))
					end,
				}
				_meta.__call = function(self,t)
					return setmetatable(t, _meta)
				end
				local m = {}
				if name~='_' then
					rawset(self, name, m)
				end
				return setmetatable(m, _meta)
			end,
		}
	})
end
-- end

function protobufdev()
	assert(proto,'proto required')
	dump(proto)
	local t = {}
	
	local fs = proto.protoc('test2.proto', file)
	----------------------------------------------------
	local syntax = "proto2"
	local _pb = proto.package(syntax)
	local map = function(ktp,vtp)
		return setmetatable({ktp,vtp},{__index={pbtype = proto.map}})
	end

	local TestEnum = _pb:enum("TestEnum",{
		MONDAY = 0,
		SUNDAY = 1,
	})
	
	local TestChild = _pb:message("TestChild",{
		{proto.OPT, proto.sint64, 'Fsint64',1 },
	})
	
	local TestType = _pb:message("TestType",{
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
		{proto.OPT, TestEnum, 'Fenum', 12},
		{proto.OPT, map(proto.int64,proto.int32), 'Fmap', 13},
		{proto.REP, TestChild, 'Frepmessage', 14},
		{proto.REP, proto.bool, 'Frepeatbool', 15},
		{proto.OPT, proto.string, 'Fstring', 16},
		{proto.OPT, proto.bytes, 'Fbytes', 17},
		{proto.OPT, proto.sfixed32, 'Fsfixed32', 18},
		{proto.OPT, proto.sfixed64, 'Fsfixed64', 19},
		{proto.REP, proto.int32, 'Frepeatint', 20},
		{proto.REP, proto.bool, 'Frepeatbool2', 21},
		{proto.REP, proto.int32, 'Frepeatint2', 22},
		{proto.REP, proto.string, 'Fstring2', 23},
		{proto.OPT, TestChild, 'Fmessage', 24},
		{proto.REP, TestChild, 'Frepc', 25},
	})
	
	------------------------------------------
	
	local b = _pb.TestChild{
		Fsint64 = 123,
	}:encode()
	print("TestType:",b)
	local t0 = _pb.TestType{
		-- Fint32 = -2100000000,
		-- Fint64 = -123000000000,
		-- Fuint32 = 4100000000,
		-- Fuint64 = 123000000000,
		-- Fsint32 = -123000000,
		-- Fsint64 = 123000000000,
		
		-- Ffixed32 = -123000000,
		-- Ffixed64 = 12300000000,
		-- Fdouble = math.pi, 
		-- Ffloat = math.pi,
		-- Fbool = true,
		-- Fbool = false,
		Fstring = "abcde",
		-- Fbytes = 'abc',
		-- Fsfixed32 = -123000000,
		-- Fsfixed64 = -12300000000,
		-- Frepeatbool = {true, false, true},
		-- Frepeatbool2 = {true, false, true},
		-- Frepeatint = {255, 65536},
		-- Frepeatint2 = {255, 65536},
		Fstring2 = {"abc","bvdd"},
		-- Fenum = _pb.TestEnum.SUNDAY,
		-- Fmessage = _pb.TestChild{
			-- Fsint64 = 123,
		-- },
		-- Frepc = {_pb.TestChild{
			-- Fsint64 = 123,
		-- },_pb.TestChild{
			-- Fsint64 = 234,
		-- }},
		-- Fmap = {[3]=7,[6]=5},
	}
	local b = t0:encode()
	print(#b,"TestType:",b)
	local t = _pb.TestType.decode(b)
	dump(t0)
	dump(t)
	for k,v in pairs(t0) do
		if t[k]~=v then
			print("not eq:",k)
		end
	end
	
end
protobufdev()
