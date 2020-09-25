--[[in C===================================================================
local pid = os.launch(workpath, args) --ret进程id
local pid, getpgid = os.id() --ret 进程id,父进程id
os.kill(pid)
--]]

local print = print
local load = load or loadstring
local unpack = table.unpack or unpack

function os.msec()
	return os.now and os.now() or os.clock()*1000
end
--function _mainloop() --if need update per frame
function dostring(s)
	return load(s)()
end
function io.readall(filename)
	local file = io.open(filename, 'rb')
	assert(file,'open file fail:'..filename)
	local data = file:read('*a')
	file:close()
	return data
end
if os.info.system == 'windows' then
	function io.list(dir, subdir)
		dir = dir or ''
		local dirs = {}
		local files = {}
		local p = ' '
		if subdir then p = ' /s' end
		for name in io.popen('@dir /ad-h/b "' .. dir ..'"'..p):lines() do
			--print(name)
			dirs[#dirs+1] = name
		end
		for name in io.popen('@dir /a-d-h/b "' .. dir ..'"'..p):lines() do
			--print(name, _md5sum(name))
			files[#files+1] = name
		end
		--error('not ready')
		return files, dirs
	end
else
	function io.list(dir)
		dir = dir or ''
		local dirs = {}
		local files = {}
		for name in io.popen([[ls -F | grep '/$']] .. dir):lines() do
			--print(name)
			dirs[#dirs+1] = name
		end
		for name in io.popen([[ls -F | grep -v '/$']] .. dir):lines() do
			--print(name, _md5sum(name))
			files[#files+1] = name
		end
		error('not ready')
		return files, dirs
	end
end
--io.list('./')
--多继承 有歧义
-- function _class(parents)
	-- assert(type(parents)=='table','table expected')
	-- local t = {}
	-- t.__index = t
	-- if #parents==0 then
		-- return t
	-- elseif #parents==1 then
		-- assert(type(parents[1])=='table','table expected')
		-- return setmetatable(t,parents[1])
	-- else
		-- local meta = function(k)
			-- for i,v in ipairs(parents)do
				-- assert(type(v)=='table','table expected')
				-- if v[k] then
					-- return v[k]
				-- end
			-- end
		-- end
		-- return setmetatable(t,{__index=meta})
	-- end
-- end
function class(base) --弃用多继承
	local t = {}
	if base then
		setmetatable(t,{__index=base})
	end
	return t
end