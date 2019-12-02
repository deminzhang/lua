
--[[in C===================================================================
_pgsql() --postgresql 有array,boolean,returning
db = _pgsql(host, port, user, pass, database)
	--host'/'的开始为unix_socket
--缓存了pg_type里的基本类型的oid对typname, typlen, typcategory, typelem, typarray的缓存
local tb_result = db:run("select * from table where id=$1;", 123)
local insertid = db:run("insert ... returning id")[1].id
local affected_rows = db:run("insert ... ")
local affected_rows = db:run("update ... ")
local affected_rows = db:run("update ... returning count(*)")[1].count
db:runs("...;...;") --multiply run no returns
db:time() 'YYYY-MM-DD HH-MM-SS.uuuuuu'
db:begin() --begin
db:commit()
db:rollback()
db:close()
db:closed() return bool

_mysql() --mysql 有replace into
db = _mysql(host, port, user, pass, database)
	--host'/'的开始为unix_socket
db = _mysql("/var/run/mysqld/mysqld.sock", 0, user, pass, database)
--缓存了stmt和返回值的类型,尽量不用用拼好的串
local tb_result = db:run("select * from table where id=?;", 123) 
local insertid, affected_rows = db:run("insert ...")
local insertid, affected_rows = db:run("update ...")
db:runs("...;...;") --multiply run no returns
db:autocommit(bool) --default true
db:begin() --START TRANSACTION
db:commit()
db:rollback()
db:close()
db:closed() return bool

db = _sqlite3(source)
db = _sqlite3(':memory:') --memdb

--]]
--lua===================================================================
--[[ postgresql   
--1.基本类型
 sql:run("select oid, typname, typlen, typcategory, typelem, typarray from pg_type where typtype = 'b' order by oid") 
--2.是否存在表
 sql:run("select count(*) from pg_class where relname=$1", tbname)
--3.--改变表所属
 admin ALTER TABLE "public"."tb" OWNER TO "comb";


--]]
---[[ mysql
--1.设置变量表
 -- sql:run("show variables;")

--2.是否存在表
 -- sql:run("select count(*) from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=? and TABLE_NAME=?;", dbname, tbname)
--3.性能日志
-- SET global slow_query_log=1; -- 开
-- SET global long_query_time=0.1; --设0.1秒
-- SET global slow_query_log_file='/usr/local/mysql/data/mysql-slow_2017-10-01log' ;
--4.memdb
	-- db:run('DROP TABLE IF EXISTS `mmdbtest`;')
	-- db:run([[
		-- CREATE TABLE mmdbtest(
			-- `id` int(10) unsigned NOT NULL,
			-- PRIMARY KEY (`id`)
		-- ) ENGINE=MEMORY;
	-- ]])
	-- local r = db:run('SELECT * FROM mmdbtest;')
	-- dump(r)
	-- db:run('insert into mmdbtest(id) values(?);',1)
	-- db:run('insert into mmdbtest(id) values(?);',2)
	-- local r = db:run('SELECT * FROM mmdbtest;')
	-- dump(r)
	-- db:run('DROP TABLE IF EXISTS `mmdbtest`;')

--]]
---[[
--1.memdb
	-- local db = _sqlite3(':memory:')
	-- dump(db)
	-- local r = db:run("select datetime();")
	-- dump(r)
	-- db:run([[
		-- CREATE TABLE mmdbtest(
			-- id int PRIMARY KEY NOT NULL
		-- );
	-- ]])
	-- db:run('insert into mmdbtest(id) values(1);')
	-- db:run('insert into mmdbtest(id) values(2);')
	-- local r = db:run('SELECT * FROM mmdbtest;')
	-- dump(r)
	-- db:close()
-- ]]
