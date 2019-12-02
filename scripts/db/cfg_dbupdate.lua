--数据库增量
if false then --示例
	example_postgres = function( sql )
		--new table 新表
		sql:run[[
			create table TTT(
				sid				int8 not null,		-- sid
				CC1				int4 not null		--
			);
		]]
		sql:run([[create index [idxname] on TTT(CC1);]])--new index 建索引
		--new column 新字段 TODO 注意因为not null 新加的字段必须一个default 值要与DefaultDB一致
		sql:run[[alter table TTT add column CC2 int8 not null default 0;]]
		--change type of column --改字段类型
		sql:run[[alter table TTT alter column CC1 type int8;]]
		sql:run[[alter table TTT drop column if exists CC1; ]]--dropcolumn
		sql:run[[create sequence TTTsid increment 100000 start 100000 maxvalue 1125899906842000;]]--create sequence
		sql:run[[alter sequence TTTsid owned by TTT.sid;]]
		sql:run[[drop sequence if exists TTTsid; ]]--drop sequence
		sql:run[[truncate TTT; ]]--truncate table
		sql:run[[drop table if exists TTT; ]]--drop table
	end
	example_mysql = function( sql )
		--new table 新表
		sql:run[[
			CREATE TABLE `tbl_character_ext` (
			  `sid` bigint(20) NOT NULL COMMENT '注释',
			  `CC1` char(32) not null COMMENT '注释',
			  PRIMARY KEY (`sid`)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
		]]
		--new index 建索引
		sql:run([[create index [idxname] on TTT(CC1);]])
		--CREATE INDEX idx_actor_first_name ON actor (first_name);
		--new column 新字段 TODO 注意因为not null 新加的字段必须一个default 值要与DefaultDB一致
		sql:run[[alter table `TTT` add `CC1` varchar(255) DEFAULT '' COMMENT '注释';]]
		--change type of column --改字段类型
		sql:run[[alter table `TTT` modify column `CC1` char(30);]]
		--replace
		sql:run[[replace into TTT(id, time) values(1, now());]]			--if select then delete,insert else insert
		sql:run[[INSERT INTO TTT(id, times) VALUES(1, 1) ON DUPLICATE KEY UPDATE times=times+1;]] --if select then update else insert
		--dropcolumn
		sql:run[[alter table TTT drop column CC1; ]]
		--create sequence
		sql:run[[create sequence TTTsid increment 100000 start 100000 maxvalue 1125899906842000;]]
		sql:run[[alter sequence TTTsid owned by TTT.sid;]]
		--drop sequence
		sql:run[[drop sequence if exists TTTsid; ]]
		sql:run[[truncate TTT; ]]--truncate table
		--drop table
		sql:run[[DROP TABLE IF EXISTS `TTT`; ]]
		sql:run[[drop database dbname ]]
	end
end

_G.cfg_dbupdate = { --新的写最上方便,多人改动冲突后提者自理

	-- [2] = function( sql )
		--sql:run[[]]
	-- end,
	-- [1] = function( sql )
		--sql:run[[]]
	-- end,
}
