print('>>conf.lua')
--运营配置
_DEVELOPMENT = true 					--开发版本
--服ID位长选用4,即角色id后4位为服ID
local info = os.info
info.version = 0.1000	 				--版本
info.pack = nil	 						--版本zip包,无则用散文件
info.serverName = 'comb'				--服务名
info.server_id = 1						--服务器id
info.platform = ''						--平台

info.dbtype = 'postgres'				--数据库类型 postgres/mysql
info.dbhost = '127.0.0.1:5432'			--数据库地址
info.dbuser = 'comb'					--数据库用户
info.dbpass = 'comb'					--数据库密码
info.dbname = 'comb%04d'				--数据库库名格式comb0001

info.listen_ccs = 'localhost:9000' 		--ccs
info.listen = 'localhost:9000' 			--listen={host}:{port0+server_id+line*10}

info.gs_num = 2							--world num 地图战斗服个数
info.dun_num = 1						--dungeon num 副本线个数
----------------------------------------------------------------
--id分配
--type	server_id	line
--ccs	0			0
--cs	1~9999		0
--gs	1~9999		1~99
--cgs	0			100~999
----------------------------------------------------------------
--logic format
-- info.listen_cs1 = 'localhost:9001' 		--cs
-- info.listen_gs1 = 'localhost:9011' 		--gs起始
-- info.listen_cgs1 = 'localhost:10001' 	--cgs起始