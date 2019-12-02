--string.lua
--[[in C===================================================================
_G._md5sum(filename, bytes) 文件md5
string:md5(first, last, bytes)字串md5, 默认first 1, last-1, bytes原始字节
string:to16l(first,signed) first默认1, signed带符号
string:to16b(first,signed) first默认1, signed带符号, 高位在前
string.from16l(int) 
string.from16b(int) 高位在前
string:to32l(first,signed) first默认1, signed带符号
string:to32b(first,signed) first默认1, signed带符号, 高位在前
string.from32l(int) 
string.from32b(int) 高位在前
string:to64l(first,signed) first默认1, signed带符号, 
string:to64b(first,signed) first默认1, signed带符号, 高位在前
string.from64l(int) 
string.from64b(int) 高位在前
string:enurl()
string:deurl()
string:debase64(first, last, bytes, mode) 解码base64字符串。
	mode必须为enbase64时使用的mode参数，默认'+/='
string:enbase64(first, last, bytes, mode) base64编码字符串。
	mode为模式设置串，62编码为字符1，63编码为字符2，用字符3做尾部对齐，无字符3不对齐，默认为'+/='，对于一些url使用场合，可能为'-_'
string:sha1(first, last, bytes)字串sha1。默认first 1, last-1, bytes原始字节
string:hmacsha1(key, first, last, bytes)字串hmacsha1。默认first 1, last-1, bytes原始字节
string:hmacmd5(key, first, last, bytes)字串对于key的hmac-md5。默认first 1, last-1, bytes原始字节
string:ulen(first) utf8字符串长度 first默认1
string:ucs(first, last, bytes)将utf-8字符串转换成小头ucs-2
string:utf(first, last, bytes)将小头ucs-2字符串转换成utf-8
string:lead(l) --s以l开头
string:tail(t) --s以t结尾
string.xor(s1, s2) 
--ing
//string:des3de(key, from)DES3解密
//string:des3en(key, from)DES3加密
//string:rsaprikeyde(key, from [, length] )
//string:rsaprikeyen(key, from [, length] )
//string:rsapubkeyde(key, from [, length] )
//string:rsapubkeyen(key, from [, length] )
//string:rsaverify(key, str, sign ) 

--zlib
local files = {filename1=filebytes1,filename2=bytes2,...}
local zipbytes = _zip(files)
local files = _unzip(zipbytes)
local d = _inflate('abcdefgabcdefgabcdefgabcdefg')
print(_deflate(d))

string:crc32(len, crc) --len默认#s, crc

Lang["zh-cn"] = {
  ["确定"] = "确定",
  ["$1级"] = "$1级",
  ["$1被$2杀死了"] = "$1被$2杀死了",
}
Lang["en-us"] = {
  ["确定"] = "Confirm",
  ["$1 级"] = "LV $1",	--按语言习惯调整参数位置
  ["$1被$2杀死了"] = "$2 kills $1", --自由调语序的翻译
}
LANG_SET = 'en-us'
local showStr = _F(_T"$1级", 100)
--]]
--lua===================================================================
-- _G.Lang = {}
-- _G.LANG_SET = 'zh-cn'
function _G._T(str,...)	--只翻译,用工具挑出_T前缀的文字
	-- local l = Lang[LANG_SET]
	-- str = l and l[str] or str
	return str
end
getmetatable("").__add = function(s,v)
	return s..tostring(v)
end
--$i制格式化 ('$1,$2,$1'):formatS('abc',123) == 'abc,123,abc'
function string.formatS(fmt,...)
	local argn = select('#',...)
	local n = 0
	if argn>0 then
		local a = {...}
		fmt,n = fmt:gsub('(%$)(%d+)',function(s,i)
			return tostring(a[tonumber(i)])
		end)
	end
	--assert(_PUBLIC or argn==n, fmt..' args not match')
	return fmt
end
--{key}制格式化 ('{name},{level}'):formatK{name='abc',level=123} == 'abc,123'
function string.formatK(fmt,args)
	local n = 0
	fmt,n = fmt:gsub('(%{)(.-)(%})',function(s,k,e)
		return args[k]
	end)
	return fmt
end

function string.MD5(s) --大写md5
	return string.upper(string.md5(s))
end
--split by delimiter
function string.split(s, delimiter) --s以delimiter分割
	if ''==s then return {} end
	local insert = table.insert
	local t, i, j, k = {}, 1, 1, 1
	while i <= #s+1 do
		j, k = s:find(delimiter, i)
		j, k = j or #s+1, k or #s+1
		insert(t, s:sub(i, j-1))
		i = k + 1
	end
	return t
end
function string.splitNum(s, delimiter) --s以delimiter分割数字
	local t = {}
	local insert = table.insert
	for num in s:gmatch("[+%-]?[%d%.]+") do
		insert(t,tonumber(num))
	end
	return t
end
--trans ip number to *.*.*.*
function string.int2inet(ip)
	local s = string.format('%08x',ip)
	local sub = string.sub
	return string.format('%s.%s.%s.%s',toint('0x'..sub(s,1,2)),toint('0x'..sub(s,3,4)),toint('0x'..sub(s,5,6)),toint('0x'..sub(s,7,8)))
end

function string.tohex( c, i )
	return string.format( "0x%02X", string.byte( c, i ) )
end

function string.trim(s) --以空格修剪字串
	return (s:gsub('^%s*(.-)%s*$', '%1'))
end
--字串宽.英为1,汉为2
function string.width(str)
    local bytes = { string.byte(str, 1, #str) }
    local len, begin = 0, false
    for _, byte in ipairs(bytes) do
        if byte < 128 or byte >= 192 then
            begin = false
            len = len + 1
        elseif not begin then
            begin = true
            len = len + 1
        end
    end
    return len
end
--取开头的字母或汉字
function string.preWord(str)
	return str:byte(1, 1) < 128 and str:sub(1,1) or str:sub(1,3) 
end
-- 生成_复合键
function string.k_k(...) 
	local n = select("#", ...)
	if n == 1 then return select(1, ...) end
	local fmt = '%s'..('_%s'):rep(n-1)
	return fmt:format(...)
end