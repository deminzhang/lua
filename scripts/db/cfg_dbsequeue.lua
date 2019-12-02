--数据库表序列主键

local cfg_dbsequeue = { --[table] = squeue
	player = 'playerids',
	item = 'itemids',
	mail = 'mailids',
	gmail = 'gmailids',
}
for t, q in pairs(cfg_dbsequeue) do
	cfg_dbsequeue[t] = string.format("select nextval('%s')", q)
end

_G.GetSeqId = function(t, id)
	assert(t and cfg_dbsequeue[t], 'dbsid invalid t')
	assert(id)
	local res = _SQL:run(cfg_dbsequeue[t])
	assert(res)
	return res[1].nextval + id%10000 --以id后4位为服id
end

_G.GetSeqIdS = function(t, server_id)
	assert(t and cfg_dbsequeue[t], 'dbsid invalid t')
	local res = _SQL:run(cfg_dbsequeue[t])
	assert(res)
	return res[1].nextval + server_id or os.info.server_id
end