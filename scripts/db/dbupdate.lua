--dbupdate.lua
dofile'db/cfg_dbupdate.lua'
dofile'db/cfg_dbsequeue.lua'
local t = string.split(os.info.dbhost, ':')
local host, port = t[1], t[2]
local dbtype = os.info.dbtype
os.info.dbname = string.format(os.info.dbname, os.info.server_id)	--数据库名
if dbtype=='postgres' then
	_G._SQL = _pgsql(host, port, os.info.dbuser, os.info.dbpass, os.info.dbname )
elseif dbtype=='mysql' then
	_G._SQL = _mysql(host, port, os.info.dbuser, os.info.dbpass, os.info.dbname )
else
	error('Unsupported dbtype:'..tostring(dbtype))
end
_G._MDB = _MDB or _sqlite3(':memory:') --memorydb
--===========数据库增量逻辑===================
local print = print
local fatal = print
local initdbsqls = {
	'db/table.sql',
	--'db/log.sql',
}
local function updateDataBase(sql)
	--do return end
	if not sql then return end
	assert(os.info.server_id, 'no os.info.server_id')
	local r
	if dbtype=='postgres' then
		r = sql:run([[select count(*) from pg_class where relname='version']])
	else
		r = sql:run([[select count(*) from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=? and TABLE_NAME='version';]], os.info.dbname)
		--r = sql:run([[show tables like 'version';]], os.info.dbname)
	end
	local newver = #cfg_dbupdate
	local server_idn = tonumber(os.info.server_id)
	if r and r[1].count==0 then	--初始化
		print('>>DataBase Initing!______________')
		sql:begin()
		local f = function( )
			for i, file in ipairs(initdbsqls)do
				local sqlstr = io.readall( file )
				assert( sqlstr,'can not find file: '..file)
				sql:runs( sqlstr )
			end
			if dbtype=='postgres' then
				sql:run([[insert into version(serverid, merged, ver) values ($1, false, $2)]], server_idn,newver)
			else
				sql:run([[insert into version(serverid, merged, ver) values (?, false, ?)]], server_idn,newver)
				sql:run([[set @@auto_increment_increment=1000;]])
				sql:run([[set @@auto_increment_offset=?;]], server_idn)
			end
		end
		local res, ret = pcall( f )
		if res then
			sql:commit()
			print('>>DataBase Init OK!_____________' )
		else
			sql:rollback()
			print('>>DataBase Init Fail!_____________' )
			assert( false, ret )
		end
	else						--增量初始化
		print('>>DataBaseCheckUpdate!server_id=',os.info.server_id )
		local vers = sql:run([[select * from version]] )
		local rr = sql:run([[select * from version where serverid = $1]], server_idn )
		local oldver = rr and rr[1].ver
		for k, v in pairs( vers ) do
			assert( v.serverid > 0, "merged not finish" )
			assert( v.ver == oldver, "merged server db version not same" )
		end
		print('>>DB Old Version:'..oldver..'______________')
		print('>>DB New Version:'..newver..'______________')
		assert(newver>=oldver,'db version had upgrade!your server version is too low!')
		sql:begin()
		while oldver<newver do
			oldver = oldver +1
			print('>>DB Update To Version:'..oldver..'...____________')
			local f = cfg_dbupdate[oldver]
			local fsql = function( )
				f(sql)
				if dbtype=='postgres' then
					sql:run([[update version set ver = $1;]],oldver)
				else
					sql:run([[update version set ver = ?;]],oldver)
				end
			end
			local res, ret = xpcall( fsql, function( ret )
				sql:rollback()
				fatal( debug.traceback( ), res, ret )
			end )
			if not res then
				assert(false,ret)
			end
			print('>>DB Update To Version:'..oldver..' OK!___________')
		end
		sql:commit()
	end
	_G.cfg_dbupdate = nil --没用了释放
end

local dbCheckMerge = function( )
	-- 1 load version table
	local result = _SQL:run'select * from version'
	local versioncheck
	for i,v in ipairs( result ) do
		if not versioncheck then versioncheck = v.ver
		else assert( v.ver == versioncheck, 'version not same!!!' ) end
	end

	-- 2 check new merge
	local newmerge = false
	for i, v in ipairs( result ) do
		if v.merged == false and v.serverid ~= os.info.server_id then
			newmerge = true
			break
		end
	end

	-- 3 process idx
	if not newmerge then return end
	for k, v in pairs( dbsididx ) do
		local ids = k .. 'ids'
		local tb = k:sub( -1, -1 ) == '_' and k:sub( 1, -2 ) or k
		local pkey = v

		local sql = [[select nextval(']] .. ids .. [[');]]
		local sqltb = 'select max(' .. pkey .. ')::int8 from ' .. tb .. ';'

		local res = _SQL:run(sql)
		local restb = _SQL:run( sqltb )

		local idsval = res[1].nextval
		local tbmax = restb[1].max or 0

		print( sql, ids, idsval )
		print( sqltb, ids, tbmax )

		print( math.max( idsval, tbmax ) )
		assert( idsval > tbmax, ( 'table %s error on ids %d, max %d' ):format( tb, idsval, tbmax ) )
	end

	_SQL:begin( )
	local res = _SQL:run([[update version set merged=true where serverid<>$1 and merged=false returning *]], os.info.server_id )
	afterMerge{mergeversion = res }
	--_SQL:run([[update serverdata set mergeservertime = $1]], os.now( 0 ) )
	_SQL:commit( )
end

when{_order=0}
function onStart()
	updateDataBase(_SQL) --初始化/增量
	--dbCheckMerge()	 --合服检查
end