
--[[in C===================================================================

--]]
--lua===================================================================
--[[
--]]

--protoc.exe --lua_out=. ../protocol/*.proto  --proto_path=../protocol/
function proto.protoc(lua_out, proto_path)
	local pk = [[----------------------------------------
local proto = proto
local OPT, REQ, REP  = proto.OPT, proto.REQ, proto.REP
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
			-- t = [[

-- message TA {
	-- int32 a = 1;
-- }
-- message TB1 {
	-- int32 a = 1;
	-- message TB_2A{
		-- int32 b = 1;
		-- message TB3{
			-- int32 c = 1;
		-- }
		-- TB3 f = 2;
	-- }
	-- TB_2A d = 2;
	-- message TB_2B{
		-- int32 e = 1;
	-- }
	-- TB_2B f = 3;
-- }

			-- ]]
			local n = 0
			local fw = io.open('proto/'..ff..'.lua','wb')
			t,n = t:gsub("//(.-)\r\n","--%1\r\n") --comment
			repeat
				t,n = t:gsub("(\r\n\r\n\r\n)","\r\n\r\n")
			until n==0
			repeat
				t,n = t:gsub("(\t\t)","\t")
			until n==0
			t,n = t:gsub("(\t})","}")
			
			local syntax = t:gmatch("syntax%s*=%s*\"(%w+)\"%s*;")() or 'proto2'
			if syntax=='proto3' then
				if t:gmatch('%[(default%s*=)')() then
					error('Explicit default values are not allowed in proto3')
				end
			end
			local packname = t:gmatch('package%s+([%w_]+)%s*;')() or 'protos'
			print('packname:',packname)
			
			t,n = t:gsub('syntax%s*=%s*(\"%w+\")%s*;',"local syntax = %1") --syntax
			t,n = t:gsub('package%s+([%w_]+)%s*;','local _pb = proto.package(\"%1\",syntax)')
			t,n = t:gsub('import%s+\"([%w_]+)%.proto\";','local %1 = proto.import\"proto.%1\"') --import TODO
			
			repeat --嵌套{} 内层提到local
				t,n = t:gsub('([%w_]+%s*[%w_]+%s*%{%s*)([^{}]-)([%w_]+%s*[%w_]+%s*%{)([^{}]-%}\r\n)(.-)','%3%4%1%2%5')
			until n==0
			
			t,n = t:gsub('enum%s*([%w_]+)%s*{(.-)}','local %1 = {%2}\r\n_pb.enum.%1 = %1')
			t,n = t:gsub('message%s*([%w_]+)%s*{(.-)}','local %1 = {%2}\r\n_pb.message.%1 = %1')
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

function proto.field(t)
	local lab = t[1]
	local tp = t[2]
	if type(t[2]) == 'table' then
		tp = t[2].pbtype
		if tp > 0xffff then
			lab = proto.MAP
		end
	end
	local packed = t.packed==nil and 2 or (t.packed and 1 or 0)
	if _VERSION>='Lua 5.3' then
		error('Lua 5.3+ open hero else close here')
		--t[0] = lab << 24 + tp << 8 + (t.packed and 1 or 0)
	elseif jit then --luajit
		t[0] = bit.lshift(lab, 24) + bit.lshift(tp, 8) + packed
	else
		t[0] = lab * math.pow(2,24) + tp * math.pow(2,8) + packed
	end
	return t
end

function proto.import(pname)
	-- local pack = require(pname)
	-- return pack
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
				-- assert(pack[name]==nil,name..' already defined in package '..pname)
				local value = {}
				for k,v in pairs(enum) do
					assert(pack[v]==nil,k..' already defined in package '..pname)
					assert(value[v]==nil,name..' duplicated enum value:'..v)
					assert(math.floor(v)==v, name..' enum value must be int32'..v)
					value[v] = k
					pack[v] = k
				end
				local _meta = {__index={pbtype = proto.enum, value=value}}
				setmetatable(enum,_meta)
				rawset(pack,name,enum)
				return enum
			end}),
			message = setmetatable({},{__newindex=function(self, name, msg)
				-- assert(pack[name]==nil,name..' already defined in package '..pname)
				local fields = {} 
				for _,v in ipairs(msg) do
					local flab = v[1]
					local ftp = v[2]
					if type(ftp)=='table' then
						ftp = ftp.pbtype
					end
					local fname = v[3]
					local fn = v[4]
					assert(fields[fn]==nil,name..' duplicated field:'..fn)
					proto.field(v)
					
					if syntax=='proto3' then
						assert(v[1]==proto.OPT or v[1]==proto.REP, 'proto3 unsupported '..fname)
						assert(v.default==nil,'[default] proto3 unsupported')
					end
					if ftp>0xffff and flab~=proto.OPT then
						error('Field labels are not allowed on map fields')
					end
					if not proto.packedType[ftp] then
						assert(v.packed~=true, '[packed=] can only be specified for repeated primitive fields:'..fname)
					end
					fields[fn] = v 
				end
				local _meta = { syntax = syntax, message = msg, fields = fields}
				_meta.__index = { pbtype = proto.message, encode = proto.encode, decode = proto.decode}
				if syntax~='proto3' then
					_meta.__index.decode = function(msg,buf)
						local r = proto.decode(msg,buf)
						for i,v in pairs(msg) do
							if r[v[3]]==nil and v.default~=nil then
								r[v[3]] = v.default
							end
						end
					end
				end
				_meta.__call = function(self,t)
					return setmetatable(t, getmetatable(self))
				end
				setmetatable(msg, _meta)
				rawset(pack,name,msg)
				return msg
			end}),
		}
	})
end
-- end

function protobuf_test()
	assert(proto,'proto required')
	dump(proto)
	local t = {}
	
	local fs = proto.protoc('proto/', 'proto/')
	----------------------------------------------------
	local proto = proto
	local OPT, REQ, REP  = proto.OPT, proto.REQ, proto.REP
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
	local _M  = proto.Map
	
	local syntax = "proto3"
	local _pb = proto.package('protos',syntax)
	-- local common = proto.import('common')

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
		{OPT, float, 'Ffloat', 10}, --warning: lua用float通信会损失精度
		{OPT, bool, 'Fbool', 11},
		{OPT, TestEnum, 'Fenum', 12},
		{OPT, _M(int64,int32), 'Fmap', 13},
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
	print("TestChild:",b)
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
		Frepeatbool = {true, false, true},
		Frepeatbool2 = {true, false, true},
		Frepeatint = {255, 65536},
		Frepeatint2 = {255, 65536},
		Fstring2 = {"","abcd"},
		Fenum = protos.TestEnum.SUNDAY,
		Fmessage = protos.TestChild{
			Fsint64 = 123,
		},
		Frepc = {protos.TestChild{
			Fsint64 = 123,
		},protos.TestChild{
			Fsint64 = 234,
		}},
		Fmap = {[3]=7,[6]=5},
	}
	local b = t0:encode()
	print(#b,"TestType:",b)
	local t = protos.TestType:decode(b)
	dump(t0)
	dump(t)
	for k,v in pairs(t0) do
		if t[k]~=v then
			print("not eq:",k)
		end
	end
	
end
protobuf_test()
