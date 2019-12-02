--dbtype=postgres/mysql host=localhost:5432 admin=管理员 adminpw=管密码 user=游戏用户 pass=密码 db=数据库名
for k, v in pairs(os.info)do
	print(k,v)
end
dofile'../lib/string.lua'
dbtype = os.info.dbtype or "postgres"	--类型 mysql/postgres
dbtype = os.info.dbtype or "postgres"	--类型 mysql/postgres
host = os.info.host or "localhost:5432"	--连接
t = string.split(host, ':')
host, port = t[1], t[2]
adminuser = os.info.admin or 'postgres'
adminpass = os.info.adminpw or ''	--数据库管理员(开发人员用)密码因人而异,自适之
gameuser = os.info.user or 'comb'	--游戏用帐号
gamepass = os.info.pass or 'comb'	--游戏用密码
dbname = os.info.db or 'comb'		--操作库
-------------------------上为配置，下为逻辑----------------------------------------------
local _sql = dbtype=='postgres' and _pgsql or _mysql
local sql = _sql(host, port, adminuser, adminpass, dbtype )
print('>>initdb:',dbname)
local s = "drop database if exists "..dbname
print('>>run:',s)
sql:run(s)
if adminuser~=gameuser then
	if dbtype=='postgres' then
		xpcall( function( )
			local s = 'drop role if exists '..gameuser
			print( '>>run:', s )
			sql:run( s )
			local s = "create role " .. gameuser .. " with login password '"..gamepass.."'"
			print( '>>run:', s )
			sql:run( s )
		end, print )
	else
		xpcall( function( )


		end, print )
	end
end
local s
if dbtype=='postgres' then
	s = "create database "..dbname.." owner "..gameuser.." lc_collate 'C' encoding 'UTF8'"
else
	s = "CREATE DATABASE IF NOT EXISTS "..dbname.." DEFAULT CHARSET utf8 COLLATE utf8_general_ci;"
end
print('>>run:',s)
assert(sql:run(s))
if dbtype=='postgres' then
	print('>>admin postgres runs: cast.sql')
	file = io.open('cast.sql', 'r')
	assert(file)
	sqls = file:read('*a')
	file:close()
	sql:runs(sqls)
end
print('>>Done!!!')
os.exit(0)
