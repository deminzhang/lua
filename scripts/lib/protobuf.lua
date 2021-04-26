
--local proto = require("luaextend.proto")
local proto = _G.proto
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
return _P
]]
	dump(io.list(proto_path))
	local fs = {}
	for _, fn in pairs(io.list(proto_path)) do
		local ff = fn:gmatch('(%w+)%.proto')()
		if ff then
			local f = io.open(proto_path..'/'..fn,'rb')
			local t = f:read("*a")
			f:close()
			local n = 0
			-- local fw = io.open('proto/'..ff..'.lua','wb')
			local fw = io.open(lua_out..ff..'.lua','wb')
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
			t,n = t:gsub('package%s+([%w_]+)%s*;','local _P = proto.package(\"%1\",syntax)\r\nlocal _M  = _P.Message\r\nlocal _E  = _P.Enum')
			t,n = t:gsub('import%s+\"([%w_]+)%.proto\";','local %1 = proto.import\"proto/%1\"') --import TODO
			
			repeat --嵌套{} 内层提到local
				t,n = t:gsub('([%w_]+%s*[%w_]+%s*{%s*)([^{}]-)([%w_]+%s*)([%w_]+%s*){([^{}]-%}\r\n)(.-)',
				'%3 _S%4{--child%5%1%2%4 = %4,\r\n\t%6')
			until n==0
			repeat --去多余表
				t,n = t:gsub("(\t\t)","\t")
			until n==0
			repeat --去多子深
				t,n = t:gsub("(_S_S)","_S")
			until n==0
			repeat --去孙子
				t,n = t:gsub("(_S[%w_]+%s*=%s*_S[%w_]+,\r\n\t)","")
			until n==0
			
			t,n = t:gsub('enum%s*_S([%w_]-)%s*{(.-)}','local %1 = _E{%2}\r\n')
			t,n = t:gsub('message%s*_S([%w_]+)%s*{(.-)}','local %1 = _M{%2}\r\n')
			t,n = t:gsub('enum%s*([%w_]+)%s*{(.-)}','local %1 = _E{%2}\r\n_P.%1 = %1')
			t,n = t:gsub('message%s*([%w_]+)%s*{(.-)}','local %1 = _M{%2}\r\n_P.%1 = %1')
			t,n = t:gsub('([%w_]+%.?[%w_]+)%s+([%w_]+)%s*=%s*(%d+)%s*%[(.-)%]%s*;','{OPT, %1, \"%2\", %3, %4},')
			t,n = t:gsub('([%w_]+%.?[%w_]+)%s+([%w_]+)%s*=%s*(%d+)%s*;','{OPT, %1, \"%2\", %3},')
			t,n = t:gsub('map<(%w+),([%w_]+)>%s*([%w_]+)%s*=%s*(%d+)%s*;','{OPT, _map(%1,%2), \"%3\", %4},')
			t,n = t:gsub('(required%s*{OPT)','{REQ')
			t,n = t:gsub('(optional','')
			t,n = t:gsub('(repeated%s*{OPT)','{REP')
			t = pk:format(t)
			fw:write(t)
			fw:close()
			fs[fn] = t
		end
	end
	return fs
end

function proto.import(pname)
	local pack = require(pname)
	return pack
end
function proto.package(pname, syntax)
	local pack = proto.loaded[pname]
	if pack then return pack end
	pack = {}
	proto.loaded[pname] = pack
	local p_field = {}
	return setmetatable(pack, {
		__newindex=function(self, name, e)
			assert(p_field[name]==nil, 'duplicated field:'..name..' in '..pname)
			if e._pbtype == proto.message then
				p_field[name] = true
			elseif e._pbtype == proto.enum then
				p_field[name] = true
				for k,_ in pairs(e) do
					assert(p_field[k]==nil, 'duplicated field:'..k..' in '..pname)
					p_field[k] = true
				end
			end
			rawset(self,name,e)
		end,
		__index = {
			Enum = function(enum)
				local value = {}
				for k,v in pairs(enum) do
					assert(value[v]==nil,'duplicated enum value:'..v)
					assert(math.floor(v)==v, 'enum value must be int32'..v)
					value[v] = k
				end
				local _meta = {__index={_pbtype = proto.enum, value=value}}
				setmetatable(enum,_meta)
				return enum
			end,
			Message = function(msg)
				local fields = {} 
				for _,v in ipairs(msg) do
					local flab = v[1]
					local ftp = v[2]
					if type(ftp)=='table' then
						ftp = ftp._pbtype
					end
					local fname = v[3]
					local fn = v[4]
					assert(fields[fn]==nil,' duplicated field:'..fn)
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
				local _meta = {syntax = syntax, message = msg, fields = fields}
				_meta.__index = {_pbtype = proto.message, encode = proto.encode, decode = proto.decode}
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
				return msg
			end,

		},
	})
end

function proto.load(proto_path)
	local fs = {}
	for _, fn in pairs(io.list(proto_path)) do
		local ff = fn:gmatch('(%w+)%.lua')()
		proto.import(ff..'.lua')
	end
	
end

function protobuf_example()
	assert(proto,'proto required')
	proto.protoc('proto/', 'proto/')
	local protos = require('proto/test')
	
	local b = protos.TestType.TestChild{
		Fsint64 = 123,
	}:encode()
	print("TestChild:",b)
	local t0 = protos.TestType{
		Fint32 = 0x7FFFffff,
		Fint64 = 0x7FFFffffFFFFffff,
		Fuint32 = 4294967295.0,
		Fuint64 = 123000000000,
		Fsint32 = -123000000,
		Fsint64 = 123000000000,
		Ffixed32 = -123000000,
		Ffixed64 = 12300000000,
		Fdouble = math.pi, 
		Ffloat = math.pi,
		Fbool = true,
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
		Fmessage = protos.TestType.TestChild{
			Fsint64 = 123,
		},
		Frepc = {protos.TestType.TestChild{
			Fsint64 = 123,
		},protos.TestType.TestChild{
			Fsint64 = 234,
		}},
		Fmap = {
		[3]=7,
		[6]=5
		},
	}
	-- dump(protos.TestType)
	-- dump(t0)
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
--protobuf_example()
