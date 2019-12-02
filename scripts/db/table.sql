-- 服务器版本表
create table version(
	serverid			int4 not null primary key,
	merged				boolean not null,
	ver					int4 not null
);

--服务器公共数据
create table serverdata(
	id					int8 not null primary key,--服务器ID
	gmopenservertime 	timestamp not null, --后台设置开服时间
	openservertime 		timestamp not null, --开服时间
	gmmergeservertime 	timestamp not null,  --后台设置合服时间
	mergeservertime 	timestamp not null,  --合服时间
	txopenservertime    timestamp not null  --腾讯时间
);
-- 账户表
create table account(
	uid					varchar(100) primary key,	--主键=server_id|plat_uid
	server_id			int not null,				--源服id
	plat_uid			varchar(100),				--平台源uid
	gold				int8 not null,				--充值币
	accgold 			int8 not null,				--叠积充值
	costgold 			int8 not null,				--叠积消费
	ip		 			varchar(32) not null,		--ip 注册--/上次登陆
	frozen 				timestamp not null, 		--封号
	frozenreason 		varchar(100) not null, 		--封号原因
	createtime			timestamp not null,			--创建时间
	rechargetimes		int not null				--充值次数
);
-- 角色表
create table player( --role/character
	pid					int8 not null primary key,
	name				varchar(100) not null,		--角色名
	uid					varchar(100) not null,		--帐号
	gender				int not null,				--性别
	job					int not null,				--职业
	level				int4 not null,				--级别
	createtime			timestamp not null,			--创建时间
	delflag				boolean not null,			--删除标记 --没用deltime<>0的原因是ORM不支持＜＞
	deltime				timestamp not null,			--删除时间
	prefab				boolean not null			--是否是预创建的
);
create sequence playerids increment 100000 start 100000 maxvalue 1125899906842000;--0x3FFFFFFFFFD90
alter sequence playerids owned by player.pid;
create index on player(name);
create index on player(uid);
create index on player(level);
-- 角色常变数据
create table playeroften(
	pid					int8 primary key,
	exp					int8 not null,						--经验
	coin				int8 not null,						--金币
	coinb				int8 not null,						--金币绑
	goldp				int8 not null,						--礼金
	force				int8 not null,						--战力
	attr				varchar not null,					--属性
	soul				int8 not null						--元神
);
-- 角色周期更新数据
create table playertick(
	pid					int8 not null primary key,
	lastonline			timestamp not null,					--上次上线时间
	onlinetime			timestamp not null,					--本次上线时间
	updatetime			timestamp not null,					--更新时间
	onlinecumul			int8 not null,						--防沉迷累积在线min
	onlinesum			int8 not null,						--总累积在线时间min
	zoneid				int8 not null,						--所在地图.仅野外
	x					float not null,
	y					float not null,
	hp					int8 not null,						--血量
	superhp				int8 not null,						--血池
	vit					int8 not null,						--体力
	onedayonlinetime    int not null    					--一天的累积时间
);
--角色switch数据
create table playerswitch(
	pid					int8 primary key, 					--玩家id
	headstate       	boolean not null, 					--头盔显隐
	fashionstate        boolean not null, 					--时装显隐
	teamjoin 			boolean not null, 					--申请自动
	teaminvite			boolean not null, 					--被邀请自动
	hidetequip			boolean not null 					--隐神装
);
--角色达成隐藏数据统计检查用 仅服务器用 只写一次
create table playerreach(
	pid					int8 not null,							--玩家id
	key					varchar not null,						--有就算
	primary key 		(pid, key)
);
--角色标志日常 key不可预料
create table playerdaily(
	pid					int8 not null,							--玩家id
	key					varchar not null,						--
	num					int not null,							--计次
	time				timestamp not null,						--创建时间
	daily				boolean not null,						--newday时清/开服清过期
	primary key 		(pid, key)
);
--角色冷却
create table playercd(
	pid					int8 not null, 						--玩家id
	k					varchar(32) not null, 				--key
	time 				timestamp not null,					--lasttime
	primary key 		(pid, k)
);

-- 充值成功记录
create table recharge(
	orderid				varchar primary key,					--定单号
	uid					varchar(100) not null,					--帐号account.uid
	daykey				int not null,							--日期键YYYYMMDD用于日充值统计查询
	channel				varchar not null,						--渠道
	rmb					int8 not null,							--现金值(分)
	gold				int8 not null,							--充值量
	fgold				int8 not null,							--充值后
	time				timestamp not null						--时间
);
create index on recharge(uid);
create index on recharge(uid,daykey);

-- 解锁
create table unlock(
	pid					int8 not null,							--玩家id
	key					varchar not null,						--有就算
	primary key 		(pid, key)
);

-- 物品表
create table item(
	sid					int8 not null primary key,				--实例id
	pid					int8 not null,							--玩家id
	id					int not null,							--模板id
	mark				int not null,							--位置
	pos					int not null,							--位置index
	num					int8 not null,							--堆叠量
	bind				int not null,							--绑定状态
	timeto				timestamp not null,						--到期时间
	time				timestamp not null,						--更新时间
	key					varchar[] not null,						--实例key
	val					int8[] not null,						--实例val
	flow				varchar not null						--流向记录..|..
);
create sequence itemids increment 10000 start 10000 maxvalue 1125899906842000;
alter sequence itemids owned by item.sid;
create index on item( id );			--跨多mark叠时道具用
create index on item( pid, mark );
create index on item( pid, mark, pos );--TODO:用逻辑缓存则不用,用ORM缓存则用
-- 物品表己删
create table item_del(
	sid					int8 not null primary key,				--实例id
	pid					int8 not null,							--玩家id
	id					int not null,							--模板id
	mark				int not null,							--位置
	pos					int not null,							--位置index
	num					int8 not null,							--堆叠量
	bind				int not null,							--绑定状态
	timeto				timestamp not null,						--到期时间
	time				timestamp not null,						--更新时间
	key					varchar[] not null,						--实例key
	val					int8[] not null,						--实例val
	flow				varchar not null						--流向记录..|..
);
-- 货币/道具计数表(不占格子道具)
create table itemnum(
	pid					int8 not null,							--玩家id
	id					int not null,							--模板id
	num					int8 not null,							--堆叠量
	primary key 		(pid, id)
);
-- 道具锁定(禁销毁禁交易)
create table itemlock(
	pid					int8 not null,							--玩家id
	id					int not null,							--模板id
	label				varchar not null,						--原因
	primary key 		(pid, id)
);
--道具使用限次
create table itemuse(
	pid					int8 not null,							--玩家id
	id					int not null,							--道具id
	times				int not null,							--本周期己用次数
	time				timestamp not null,						--使用时间
	primary key 		(pid, id)
);
--商店限购
create table shoplimit(
	pid					int8 not null,									--玩家id
	goods_key			varchar not null,								--货号=商店id_店品idx_道具id
	times				int not null,									--本周期购买次数
	time				timestamp not null,								--更新时间
	primary key 		(pid, goods_key)
);
create index on shoplimit(pid);
--邮件个人
create table mail(
	sid					int8 primary key,
	pid					int8 not null,									--玩家pid
	fromname			varchar(100) not null,							--发送者
	title				varchar(64) not null,							--标题
	content				varchar not null,								--正文
	time				timestamp not null,								--发送时间
	validtime			timestamp not null,								--过期时间
	label				varchar(64),									--道具源标志
	item1				int not null,
	item2				int not null,
	item3				int not null,
	item4				int not null,
	item5				int not null,
	item6				int not null,
	item7				int not null,
	item8				int not null,
	num1				int8 not null,
	num2				int8 not null,
	num3				int8 not null,
	num4				int8 not null,
	num5				int8 not null,
	num6				int8 not null,
	num7				int8 not null,
	num8				int8 not null,
	bind				int[8] not null,					--道具绑定0不1是2装绑
	checked				int not null,						--1己阅
	deal				int not null,						--1己领
	deleted				int not null,						--1己删
	isgmail       		int not null,						--1全服邮件
	gsid				int8 not null						--来自公共邮件
);
create sequence mailids increment 10000 start 10000 maxvalue 1125899906842000;
alter sequence mailids owned by mail.sid;
create index on mail( pid );
create index on mail( validtime );
--邮件公共
create table gmail(
	gsid				int8 primary key,						--实例id
	fromname			varchar(100) not null,					--发送者
	title				varchar(64) not null,					--标题
	content				varchar not null,						--正文
	time				timestamp not null,						--发送时间
	validtime			timestamp not null,						--过期时间
	label				varchar(64) not null,					--道具源标志
	item1				int not null,
	item2				int not null,
	item3				int not null,
	item4				int not null,
	item5				int not null,
	item6				int not null,
	item7				int not null,
	item8				int not null,
	num1				int8 not null,
	num2				int8 not null,
	num3				int8 not null,
	num4				int8 not null,
	num5				int8 not null,
	num6				int8 not null,
	num7				int8 not null,
	num8				int8 not null,
	bind				int[8] not null								--道具绑定0不1是
);
create sequence gmailids increment 10000 start 10000 maxvalue 1125899906842000;
alter sequence gmailids owned by gmail.gsid;
create index on gmail( time );
create index on gmail( validtime );
