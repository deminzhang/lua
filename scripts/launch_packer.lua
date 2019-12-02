--zip packer
--打包除lannch.lua conf.lua bin*/的文件

function io.readall(filename)
	local file = io.open(filename, 'rb')
	assert(file,'open file fail:'..filename)
	local data = file:read('*a')
	file:close()
	return data
end


function io.list(dir, subdir)
	dir = dir or ''
	local dirs = {}
	local files = {}
	local p = ''
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

dump(io.list('.', true))