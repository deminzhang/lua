
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

--protoc.exe --lua_out=. ../protocol/*.proto  --proto_path=../protocol/
function proto.protoc(lua_out, proto_path)
	
	local pk = [[----------------------------------------
local proto = proto
local OPT  = proto.OPT 
local REQ  = proto.REQ 
local REP  = proto.REP 
local bool  = proto.bool 
local enum  = proto.enum 
local int32 = proto.int32
local int64 = proto.int64
local uint32 = proto.uint32
local uint64 = proto.uint64
local sint32  = proto.sint32 
local sint64  = proto.sint64 
local fixed32  = proto.fixed32 
local fixed64  = proto.fixed64 
local sfixed32  = proto.sfixed32 
local sfixed64  = proto.sfixed64 
local double  = proto.double 
local string  = proto.string 
local bytes  = proto.bytes 
local float  = proto.float 
local _map  = proto.Map 
----------------------------------------
%s
return _pb
]]
	dump(io.list(proto_path))
	for _, fn in pairs(io.list(proto_path)) do
		local ff = fn:gmatch('(%w+)%.proto')()
		if ff then
			local f = io.open(proto_path..'/'..fn,'rb')
			local t = f:read("*a")
			f:close()
			local n = 0
			local fw = io.open('proto/'..ff..'.lua','wb')
			t,n = t:gsub("//(.-)\r\n","--%1\r\n") --comment
			repeat
				t,n = t:gsub("(\r\n\r\n\r\n)","\r\n\r\n")
			until n==0
			local syntax = t:gmatch("syntax%s*=%s*\"(%w+)\"%s*;")() or 'proto2'
			if syntax=='proto3' then
				if t:gmatch('%[(default%s*=)')() then
					error('Explicit default values are not allowed in proto3')
				end
			end
			local packname = t:gmatch('package%s+([%w_]+)%s*;')() or 'protos'
			
			t,n = t:gsub('syntax%s*=%s*(\"%w+\")%s*;',"local syntax = %1") --syntax
			t,n = t:gsub('package%s+([%w_]+)%s*;','local _pb = proto.package(\"%1\",syntax)')
			t,n = t:gsub('import%s+\"([%w_]+)%.proto\";','local %1 = proto.import\"proto.%1\"') --import TODO
			
			-- repeat --嵌套message 提到local
			-- t,n = t:gsub('(message%s*[%w_]+%s*{.-)(message%s*[%w_]+%s*{.-})(.-})', '%2\n%1%3') 
			-- until n==0
			
			t,n = t:gsub('enum%s*([%w_]+)%s*{(.-)}','local %1 = {%2}\n_pb.enum.%1 = %1')
			t,n = t:gsub('message%s*([%w_]+)%s*{(.-)}','local %1 = {%2}\n_pb.message.%1 = %1')
			t,n = t:gsub('([%w_]+%.?[%w_]+)%s+([%w_]+)%s*=%s*(%d+)%s*%[(.-)%]%s*;','{OPT, %1, \"%2\", %3, %4},')
			t,n = t:gsub('([%w_]+%.?[%w_]+)%s+([%w_]+)%s*=%s*(%d+)%s*;','{OPT, %1, \"%2\", %3},')
			t,n = t:gsub('map<(%w+),([%w_]+)>%s*([%w_]+)%s*=%s*(%d+)%s*;','{OPT, _map(%1,%2), \"%3\", %4},')
			t,n = t:gsub('(required%s*{OPT)','{REQ')
			t,n = t:gsub('(optional','')
			t,n = t:gsub('(repeated%s*{OPT)','{REP')
			t = pk:format(t)
			fw:write(t)
			fw:close()
		end
	end
	
end


function proto.import(pname)
	
end
-- if proto.package==nil then
function proto.package(pname, syntax)
	local pack = proto.loaded[pname]
	if pack then return pack end
	pack = {}
	proto.loaded[pname] = pack
	return setmetatable(pack, {
		__index = {
			enum = setmetatable({},{__newindex=function(self, name, enum)
				local value = {}
				for k,v in pairs(enum) do
					assert(value[v]==nil,name..' duplicated enum value:'..v)
					assert(math.floor(v)==v, name..' enum value must be int32'..v)
					value[v] = k
				end
				local enum_meta = {__index={pbtype = proto.enum, syntax = syntax, value=value}}
				setmetatable(enum,enum_meta)
				rawset(pack,name,enum)
				return enum
			end}),
			message = setmetatable({},{__newindex=function(self, name, msg)
				local fields = {} 
				for _,v in pairs(msg) do
					local flab = v[1]
					local ftp = v[2]
					if type(ftp)=='table' then
						assert(ftp.pbtype~=proto.message or syntax==ftp.syntax, 'sub message syntax必须相同')
						ftp = ftp.pbtype
					end
					local fname = v[3]
					local fn = v[4]
					assert(fields[fn]==nil,name..' duplicated field:'..fn)
					
					if syntax=='proto3' then
						assert(v[1]==proto.OPT or v[1]==proto.REP, 'proto3 unsupported '..fname)
						assert(v.default==nil,'[default] proto3 unsupported')
					end
					if ftp==proto.map and flab~=proto.OPT then
						error('Field labels are not allowed on map fields')
					end
					if not proto.primitive[ftp] then
						assert(v.packed~=true, '[packed=] can only be specified for repeated primitive fields:'..fname)
					end
					fields[fn] = v 
				end
				local message_meta = { syntax = syntax, message = msg, fields = fields}
				message_meta.__index = {
					syntax = syntax,
					pbtype = proto.message,
					encode = proto.encode,
					decode = function(buf)
						return proto.decode(buf, setmetatable({}, message_meta))
					end,
				}
				message_meta.__call = function(self,t)
					return setmetatable(t, message_meta)
				end
				rawset(pack,name,msg)
				return setmetatable(msg, message_meta)
			end}),
		}
	})
end
-- end

function protobufdev()
	assert(proto,'proto required')
	dump(proto)
	local t = {}
	
	local fs = proto.protoc('proto/', 'proto/')
	----------------------------------------------------
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
	local sint64  = proto.sint64 
	local fixed32  = proto.fixed32 
	local fixed64  = proto.fixed64 
	local sfixed32  = proto.sfixed32 
	local sfixed64  = proto.sfixed64 
	local double  = proto.double 
	local string  = proto.string 
	local bytes  = proto.bytes 
	local float  = proto.float 
	
	local syntax = "proto3"
	local _pb = proto.package('test2',syntax)
	--local common = proto.import('common.proto')

	local TestEnum = {
		MONDAY = 0,
		SUNDAY = 1,
	}
	_pb.enum.TestEnum = TestEnum
	
	local TestChild = {
		{OPT, sint64, 'Fsint64',1 },
		{OPT, sint64, 'Fsint64',2 },
	}
	_pb.message.TestChild = TestChild
	
	local TestType = {
		{OPT, int32, 'Fint32', 1},
		{OPT, int64, 'Fint64', 2},
		{OPT, uint32, 'Fuint32', 3},
		{OPT, uint64, 'Fuint64', 4},
		{OPT, sint32, 'Fsint32', 5},
		{OPT, sint64, 'Fsint64', 6},
		{OPT, fixed32, 'Ffixed32', 7},
		{OPT, fixed64, 'Ffixed64', 8},
		{OPT, double, 'Fdouble', 9},
		{OPT, float, 'Ffloat', 10}, --warning:lua用float通信会损失精度,建议浮点都用double
		{OPT, bool, 'Fbool', 11},
		{OPT, TestEnum, 'Fenum', 12},
		{OPT, proto.Map(int64,int32), 'Fmap', 13},
		{REP, TestChild, 'Frepmessage', 14},
		{REP, bool, 'Frepeatbool', 15},
		{OPT, string, 'Fstring', 16},
		{OPT, bytes, 'Fbytes', 17},
		{OPT, sfixed32, 'Fsfixed32', 18},
		{OPT, sfixed64, 'Fsfixed64', 19},
		{REP, int32, 'Frepeatint', 20},
		{REP, bool, 'Frepeatbool2', 21},
		{REP, int32, 'Frepeatint2', 22},
		{REP, string, 'Fstring2', 23},
		{OPT, TestChild, 'Fmessage', 24},
		{REP, TestChild, 'Frepc', 25},
	}
	_pb.message.TestType = TestType
	
	------------------------------------------
	local protos = _pb
	local b = protos.TestChild{
		Fsint64 = 123,
	}:encode()
	print("TestType:",b)
	local t0 = protos.TestType{
		Fint32 = -2100000000,
		Fint64 = -123000000000,
		Fuint32 = 4100000000,
		Fuint64 = 123000000000,
		Fsint32 = -123000000,
		Fsint64 = 123000000000,
		
		Ffixed32 = -123000000,
		Ffixed64 = 12300000000,
		Fdouble = math.pi, 
		Ffloat = math.pi,
		Fbool = true,
		Fbool = false,
		Fstring = "abcde",
		Fbytes = 'abc',
		Fsfixed32 = -123000000,
		Fsfixed64 = -12300000000,
		-- Frepeatbool = {true, false, true},
		-- Frepeatbool2 = {true, false, true},
		-- Frepeatint = {255, 65536},
		-- Frepeatint2 = {255, 65536},
		-- Fstring2 = {"abc","abcd"},
		-- Fenum = protos.TestEnum.SUNDAY,
		-- Fmessage = protos.TestChild{
			-- Fsint64 = 123,
		-- },
		-- Frepc = {protos.TestChild{
			-- Fsint64 = 123,
		-- },protos.TestChild{
			-- Fsint64 = 234,
		-- }},
		Fmap = {[3]=7,[6]=5},
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
