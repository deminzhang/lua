--中文
create table log (--创建/在线等
-- 全局字段
  id            bigserial primary key,	-- 自增主键
  server_id     int not null,			-- 服务器ID
  time          timestamp not null,		-- 日志时刻
  op            varchar(64) not null,	-- 操作事件
  uid        	varchar(64),			-- 用户名	(op=launch时为null, 其他非null)
  role          varchar(64),			-- 角色名	(op=launch/signup时为null, 其他非null)
  lv        	int,					-- 角色等级	(op=launch/signup/newrole时为null, 其他非null)
  job           varchar(64),			-- 职业名	(op=launch/signup时为null, 其他非null,
  map           varchar(64),			-- 地图名	(op=launch/signup/newrole/recharge/bonu时为null, 其他非null)如果游戏不分职业则为null)
  online        bigint,                 -- 从创建角色开始累积在线时长(秒)
  step			varchar,		   		-- 主线任务名或id
-- 字符类型
  s1            varchar,
  s2            varchar,
  s3            varchar,
  s4            varchar,
  s5            varchar,
  s6            varchar,
  s7            varchar,
  s8            varchar,
  s9            varchar,
  s10           varchar,
-- 数字类型
  i1            bigint,
  i2            bigint,
  i3            bigint,
  i4            bigint,
  i5            bigint,
  i6            bigint,
  i7            bigint,
  i8            bigint,
  i9            bigint,
  i10           bigint,
-- 时间类型
  t1            timestamp,
  t2            timestamp
);
create index on log( time );
create table log2 (--临时
-- 全局字段
  id            bigserial primary key,	-- 自增主键
  server_id     int not null,			-- 服务器ID
  time          timestamp not null,		-- 日志时刻
  op            varchar(64) not null,	-- 操作事件
  uid        	varchar(64),			-- 用户名	(op=launch时为null, 其他非null)
  role          varchar(64),			-- 角色名	(op=launch/signup时为null, 其他非null)
  lv        	int,					-- 角色等级	(op=launch/signup/newrole时为null, 其他非null)
  job           varchar(64),			-- 职业名	(op=launch/signup时为null, 其他非null,
  map           varchar(64),			-- 地图名	(op=launch/signup/newrole/recharge/bonu时为null, 其他非null)如果游戏不分职业则为null)
  online        bigint,                 -- 从创建角色开始累积在线时长(秒)
  step			varchar,		   		-- 主线任务名或id
-- 字符类型
  s1            varchar,
  s2            varchar,
  s3            varchar,
  s4            varchar,
  s5            varchar,
  s6            varchar,
  s7            varchar,
  s8            varchar,
  s9            varchar,
  s10           varchar,
-- 数字类型
  i1            bigint,
  i2            bigint,
  i3            bigint,
  i4            bigint,
  i5            bigint,
  i6            bigint,
  i7            bigint,
  i8            bigint,
  i9            bigint,
  i10           bigint,
-- 时间类型
  t1            timestamp,
  t2            timestamp
);
create index on log2( time );
create table log3 (--游戏
-- 全局字段
  id            bigserial primary key,	-- 自增主键
  server_id     int not null,			-- 服务器ID
  time          timestamp not null,		-- 日志时刻
  op            varchar(64) not null,	-- 操作事件
  uid        	varchar(64),			-- 用户名	(op=launch时为null, 其他非null)
  role          varchar(64),			-- 角色名	(op=launch/signup时为null, 其他非null)
  lv        	int,					-- 角色等级	(op=launch/signup/newrole时为null, 其他非null)
  job           varchar(64),			-- 职业名	(op=launch/signup时为null, 其他非null,
  map           varchar(64),			-- 地图名	(op=launch/signup/newrole/recharge/bonu时为null, 其他非null)如果游戏不分职业则为null)
  online        bigint,                 -- 从创建角色开始累积在线时长(秒)
  step			varchar,		   		-- 主线任务名或id
-- 字符类型
  s1            varchar,
  s2            varchar,
  s3            varchar,
  s4            varchar,
  s5            varchar,
  s6            varchar,
  s7            varchar,
  s8            varchar,
  s9            varchar,
  s10           varchar,
-- 数字类型
  i1            bigint,
  i2            bigint,
  i3            bigint,
  i4            bigint,
  i5            bigint,
  i6            bigint,
  i7            bigint,
  i8            bigint,
  i9            bigint,
  i10           bigint,
-- 时间类型
  t1            timestamp,
  t2            timestamp
);
create index on log3( time );

create table online (
  server_id     int not null primary key,
  time          timestamp default CURRENT_TIMESTAMP,
  online        int not null,
  payaccnum		int
);

--=============================================
------------------ op=launch 服务器启动
------------------ op=signup 用户注册
-- s1     渠道名
-- s2     ip
------------------ op=newrole 创建角色
-- s1     渠道名
-- s2     性别(可选)
------------------ op=signin 登录
-- s1     客户端(web desk)
-- s2     ip
-- s3     行会(可选)
------------------ op=signout 退出(角色5min之内没有任何事件/keepalive)
-- s1     客户端(web desk)
-- s2     ip
-- i1	  本次上线累积时长(秒)
-- i2	  本日累积在线时间(秒)
------------------ op=online 在线人数
-- i1     在线人数
------------------ op=death 角色死亡
-- s1     击杀者类型: player/monster(玩家/怪物)
-- s2     击杀者名字
------------------ op=task 任务
-- s1     任务名
-- s2     任务种类(主线 日常 其它)
-- s3     任务操作(开始 结束 放弃)
-- i1     任务step/id
------------------ op=upgrade 升级
-- lv  新的等级
------------------ op=currency 货币的获得或消耗
-- s1     获得或消耗方式
--			金币:	gm测试/GM赠送/drop/大富翁/收租/交易/寄卖/传送/技能/购买/商城/boss传送/
--				赏金押金/战场奖励/拼图奖励/poker/sell/LOST大宝箱/强化/战兽改名/战兽培养/修补裂缝
--			能量:	聚能/塔罗牌/技能/星图
--			阵营积分: gm测试/冰火战场/阵营击杀/阵营商店
-- s2     货币类型(金币 能量 阵营积分)
-- i1     货币数量的变化(>0获得, <0消耗)
-- i2     货币余额
------------------ op=map 跳转地图
-- s1     当前地图名
-- map    前往地图名
------------------ op=mon 杀怪(arpg只记结束时刻信息)
-- s1     怪物名
-- i1     怪物id
-- i2     怪物等级
------------------ op=killp 杀人
-- s1     对方名字
-- i1     对方等级
------------------ op=recharge 充值
-- s1     订单号
-- s2     渠道名
-- i1     充值金额
-- i2     充值获得金币数量
-- i3     金币余额
------------------ op=mall 商城购买
-- s1     道具名
-- s2     商城活动名
-- i1     道具数量
-- i2     消耗元宝数量
-- i3     元宝余额
-- i4     消耗绑定元宝数量
-- i5     绑定元宝余额
------------------ op=item 道具的获得和消耗
-- s1     道具名
-- s2     道具类型(绑定 非绑定)
-- s3     道具获得和消耗方式: (drop 强化 GM给予 商城 交易买 活动赠送 其他)
-- i1     道具数量的变化(n>0增加, n<0减少)
-- i2     道具剩余数量
-- i3	  id
------------------ op=bonu 获得额外元宝
-- s1     获得方式(充值赠送 GM赠送 活动赠送 其他)	--寄卖收入,gm测试,礼包
-- i1     获得元宝数量
-- i2     元宝余额
------------------ op=cost 元宝消费
-- s1     消费方式(商城 兑换货币 加速 锻造 其它) how
			--lost交易//重置任务//捐款//扩背包/扩仓库/扩符文包
			--//购买
			--//洗炼/强化/拆取/打孔/重打孔
			--//战兽扩格/战兽复活/升级XP技/战兽主动/战兽被动/战兽培养/重置合体
			--//boss传送/称号升级/副本传送/重置副本奖励
-- s2     消费标签(战兽 坐骑 装备 灵石 铜钱 战魂 加速 锻造 其它) where
			--lost寄卖//任务//公会//包格//商店//装备//战兽//其它
-- i1     消耗元宝数量
-- i2     元宝余额
-- i3     消耗绑定元宝数量
-- i4     绑定元宝余额

------------------ op=skill 使用技能
-- s1技能目标
-- s2技能分类
-- s3技能名称
-- i1技能Id
------------------ op=star 强化
-- s1 结果: 成功/失败
-- s2 装备位名称
-- s3 装备名称
-- i1 目标星级
-- i2 装备位编号
-- i3 进度
-- i4 装备sid
-- i5 装备id
------------------ op=enchase 镶嵌
-- i1 镶嵌位置 1~14
-- i2 子位置1~5
-- i3 等级
------------------ op=wash 洗炼
-- s1 类型: 洗属性/洗值
------------------ op=ridelv 坐骑升阶
-- s1 结果: 成功/失败
-- i1 目标阶级
------------------ op=petlv 战兽升阶
-- s1 结果: 成功/失败
-- i1 目标阶级
------------------ op=mlbstepup 魔龙臂升级
-- s1 结果: 成功/失败
-- i1 目标阶级
------------------ op=xplv 合体技升级
-- s1 结果: 成功/失败
-- s2 技能组名
-- i1 战兽序号1~6
-- i2 目标级别
-- i3 技能序号1,2
------------------ op=skilllv 主动技能升级
-- s1 结果: 成功/失败
-- i1 技能组ID
-- i2 级别
------------------ op=starlv 星图升级
-- s1 结果: 成功/失败
-- i1 星座编号
-- i2 星星编号
------------------ op=title 获得称号
-- s1 称号名称
-- i1 称号id
------------------ op=military 爵位
-- i1 增加点数
-- i2 总点数
-- i3 旧级别
-- i4 新级别
------------------ op=tflv 合体升阶
-- s1 结果: 成功/失败
-- i1 结果阶级1~...
-- i2 结果点数0~9,10(最后一阶满为10,其余满10进阶)
------------------ op=feed 侍从喂养
-- i1 新加好感度
-- i2 旧级别
-- i3 新级别
-- i4 本次喂食装备数量
------------------ op=relic 遗迹修复
-- i1 遗迹组id
-- i2 当前遗迹已升的数量
-- i3 当前遗迹ID
------------------ op=tf 合体
-- i1 合体skillid
------------------ op=dungeonenter 进入副本(扣次数)
-- map 副本名称
-- i1 副本id
-- i2 己用次数
------------------ op=dungeon 通关副本
-- s1 副本名称
-- s2 通关方式:通关/失败
-- s3 通关标志:赏金
-- i1 副本id
------------------ op=friend 好友
-- s1 操作: 添加/删除
-- s2 被加方名字
-- i1 加方好友数
-- i2 被加方sid
------------------ op=muse 聚能
-- t1     开始时刻
-- time   结束时刻
------------------ op=team 组队(不分队长,进入就算)
-- s1 入队\离队(in/out)
-- i1 无
------------------ op=exchange 交易(一次交易按收益方记两条记录,单号相同)
-- s1 交易单号 日期+同一时间多个交易序列
-- s2 交易目标帐号
-- s3 无易目标角色
-- i1 获得金币
-- i2~i10 获得道具sid (只能记6个无数量)
------------------ op=sign 签到
-- i1 当月累积签到数
-- i2 累积总签到数
------------------ op=home 家园
-- s1 操作: 进入/浇水/除草/除虫/采集/占领成功/占领失败/反抗成功/反抗失败/收租/帮助除虫/帮助除草/帮助浇水
------------------ op=bigrich 大富翁
-- s1 操作: 进入/roll
------------------ op=tfgather 采蘑菇
-- s1 操作: 进入/采集/技能
------------------ op=tunnel 魔魂殿
-- s1 操作: 进入/通过
-- i1 关数
------------------ op=cmd 使用测试指令
-- s1	指令名
-- s2~s10 指令参数1~9

------------------ op=boss 击杀世界boss
-- s1 boss名
-- i1 bossid

------------------ op=poker 塔罗牌
-- s1 操作: 领取奖励/洗牌
-- s2 牌面
-- s3 是否花费元宝洗牌

------------------ op=hero 守护英雄
-- s1 操作: 进入/退出
-- i1 轮次

------------------ op=maze 时空秘境
-- s1 操作: 进入/退出
-- i1 迷宫层数

------------------ op=icefire 冰火战场
-- s1 操作: 进入/退出
-- s2 胜利/失败

------------------ op=campfight 阵营争夺战
-- s1 胜利/失败

------------------ op=killmsg 刺杀信使
-- s1 操作: 进入/退出
-- s2 胜利/失败

------------------ op=minefight 矿石争夺战
-- s1 操作: 进入/退出

------------------ op=campbuy 阵营积分购买
-- s1 道具名
-- i1 道具数量
-- i2 消耗阵营积分数量
-- i3 阵营积分余额

------------------ op=camptask 阵营日常任务
-- s1 操作：完成本环'onedone'/下一环newtask/完成所有环alldone
-- s2 消耗元宝完成（'pay' or 'nature'）
-- i1 当前环
-- i2 当前环完成数目
-- i3 当前环奖励系数id
-- i4 当前环难度系数id

------------------ op=bounty 赏金任务
-- s1 操作:发布/领取/完成(release/get/done)
-- s2 任务奖励类型
-- s3 任务类型
-- i1 任务等级
-- t1 过期时间

------------------ op=chat 聊天记录
-- s1  From 角色名
-- s2 频道
-- s3 信息
-- s4 目标玩家
------------------ op=addexp 经验获得
-- s1 来源: buff/test/kill/bigrich/campfight/homeservant/maze/prozd/
--			battle/muse/worldprocess/skillfail/giftfail/tflvfail/starfail
-- i1 新加值

------------------ op=passmovie 跳过剧情对话
-- s1 是否跳过(yes/no)
-- s2 对话类型(movtalknpc/movbg)
-- i1 对话id
------------------ op=trial 英雄试炼
-- s1 进入/通过
-- i1 层数
------------------ op=trial2 神佑试炼
-- s1 进入/通过
-- i1 层数
------------------ op=trial3 天赋试炼
-- s1 进入/通过
-- i1 层数


