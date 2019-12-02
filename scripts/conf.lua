print('>>conf.lua')
--运营配置
_DEVELOPMENT = false 					--开发版本
--服ID位长选用4,即角色id后4位为服ID
local info = os.info
info.version = 0.1000	 				--版本
info.pack = nil	 						--版本zip包,无则用散文件
info.sname = 'comb'						--服务名
info.server_id = 1						--服务器id
info.platform = ''						--平台

info.dbtype = 'postgres'				--数据库类型 postgres/mysql
info.dbhost = '127.0.0.1:5432'			--数据库地址
info.dbuser = 'comb'					--数据库用户
info.dbpass = 'comb'					--数据库密码
info.dbname = 'comb%04d'				--数据库库名格式comb0001

info.listen_ccs = 'ccs.comb.com:9000' 	--ccs
info.listen = 's1.comb.com:9000' 			--gate
info.listen_rule = '%s@%s_%04d_%04s'	--pipe={gate}@{sname}{server_id}{line}

info.gaten = 2							--子gate数
info.gs_num = 1							--world num 地图战斗服个数
info.dun_num = 2						--dungeon num 副本线个数
----------------------------------------------------------------
--id分配
--type	server_id	line
--ccs	0			0
--cs	1~9999		0
--gs	1~9999		1~99
--cgs	0			100~999
----------------------------------------------------------------
--logic format
--info.listen_cs1 = 's1.comb.com:9000@comb0001line0000'
--info.listen_gs1 = 's1.comb.com:9000@comb0001line0001'
--info.listen_cgs1 = 'cgs1.comb.com:9111@comb0000line0001' 	--cgs1