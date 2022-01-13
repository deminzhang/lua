


--login.lua
local GetRoleInfo = function( uid, pid )
	local role = _SQL:run('select * from role where pid=$1', pid)[1]
	local info = {
		serverid = os.info.server_id,
		role = role,
	}
	info.item = Item.getByPid(pid)
	info.res = Res.getByPid(pid)
	info.buff = Buff.getByPid(pid)
	info.mail = Mail.getByPid(pid)
	--...更多后续系统数据加入
	--...
	return info
end

--item.lua
when{}
function event.getUserInfo(uid,pid,info,step)
	info.item = getByPid(pid)
end
--res.lua
when{}
function event.getUserInfo(uid,pid,info,step)
	info.res = getByPid(pid)
end
--login.lua
local GetRoleInfo = function( uid, pid )
	local role = _SQL:run('select * from role where pid=$1', pid)[1]
	local info = {
		serverid = os.info.server_id,
		role = role,
	}
	getUserInfo{uid=uid,pid=pid,info=info,step='gs'}
	return info
end
