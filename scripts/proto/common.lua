----------------------------------------
local proto = proto
local OPT, REQ, REP  = proto.OPT, proto.REQ, proto.REP
local bool  = proto.bool 
local enum  = proto.enum 
local int32 = proto.int32
local int64 = proto.int64
local uint32 = proto.uint32
local uint64 = proto.uint64
local sint32  = proto.sint32 
local sint64  = proto.sint64 
local fixed32  = proto.fixed32 
local fixed64  = proto.fixed64 
local sfixed32  = proto.sfixed32 
local sfixed64  = proto.sfixed64 
local double  = proto.double 
local string  = proto.string 
local bytes  = proto.bytes 
local float  = proto.float 
local _map  = proto.Map 
----------------------------------------
local syntax = "proto3"
local _P = proto.package("protos",syntax)
local _M  = _P.Message
local _E  = _P.Enum

--/////////////////////////////////////////////////////
--18245 21536 GET 
--20559 21332 POST
--除主键req和数组rep,其它全部opt

--服务器数据 仅上线时同步一次
local Server = _M{
	{OPT, int64, "time", 3}, 	--服务器时间
	{OPT, int32, "appid", 4}, 	--游戏ID
	{OPT, int32, "region", 5}, 	--游戏服ID
	{OPT, string, "chatUrl", 6}, 	--聊天服地址
	{OPT, string, "version", 7}, 	--后端版本标识
}
_P.Server = Server

--角色信息(公)
local User = _M{
	{OPT, int64, "uid", 1},	--UID
	{OPT, string, "name", 2},	--角色名
	{OPT, int32, "gender", 3},	--性别
	{OPT, int32, "icon", 4},	--头像
	{OPT, int32, "iconB", 5},	--头像
	{OPT, int32, "level", 6},	--级别
	{OPT, int32, "cityX", 7},	--城坐标X
	{OPT, int32, "cityY", 8},	--城坐标Y
	{OPT, int64, "power", 10},	--战力
	{OPT, int64, "allianceId", 11},	--联盟Id
}
_P.User = User
local UserPK = _M{
	{OPT, int64, "uid", 1},	--UID
}
_P.UserPK = UserPK

--日常限制(适合量大分组,统一重置)
local UserLimit = _M{
	{OPT, string, "group", 1},	-- shop:商店 vipShop:VIP商店 mysticShop:神秘商店 mall:商城 mixed:杂项
    {OPT, string, "key", 2}, 	-- shop*:商品ID mall:商品ID mixed:约定
    {OPT, int32, "num", 3}, 	-- 日用量
}
_P.UserLimit = UserLimit
local UserLimitPK = _M{
	{OPT, string, "group", 1},	-- shop:商店 vipShop:VIP商店 mysticShop:神秘商店 mall:商城
    {OPT, string, "key", 2}, 	-- shop*:商品ID mall:商品ID
}
_P.UserLimitPK = UserLimitPK

--角色计数(散杂又需时间计算)
local UserCount = _M{
	{OPT, int32, "cid", 1},	--前后端约定
	{OPT, int64, "val", 2},	--val
	--Ticker
	{OPT, int64, "time", 4},	--上次变化时间(0不变)
	--{OPT, int64, "rest", 3},	//上次值
	--{OPT, float, "rate", 5},	//变化值(/ms,0不变)
}
_P.UserCount = UserCount
local UserCountPK = _M{
	{OPT, int32, "cid", 1},	--
}
_P.UserCountPK = UserCountPK

--角色前端标记
local UserMark = _M{
	{OPT, int32, "cid", 1},	--前端自定义
	{OPT, int64, "val", 2},	--val
}
_P.UserMark = UserMark
local UserMarkPK = _M{
	{OPT, int32, "cid", 1},	--前端自定义
}
_P.UserMarkPK = UserMarkPK

local IdNum = _M{
	{OPT, int32, "cid", 1},	--配置ID
	{OPT, int64, "num", 2},	--数量
}
_P.IdNum = IdNum
--道具
local Item = _M{
	{OPT, int64, "sid", 1},	--主键
	{OPT, int32, "cid", 2},	--配置ID
	{OPT, int64, "num", 3},	--数量
	{OPT, int64, "show", 4},	--显示至
}
_P.Item = Item
local ItemPK = _M{
	{OPT, int64, "sid", 1},	--配置ID
}
_P.ItemPK = ItemPK
local ItemArray = _M{
    {REP, IdNum, "item", 1}, 	--数组
}
_P.ItemArray = ItemArray

--资源/计数
local Res = _M{
	{OPT, int32, "cid", 1},	--配置ID
	{OPT, int64, "num", 2},	--数量
	{OPT, int64, "time", 3},	--上次变化时间(0不变)
	{OPT, float, "rate", 4},	--变化值(/ms,0不变)
}
_P.Res = Res
local ResPK = _M{
	{OPT, int32, "cid", 1},	--配置ID
}
_P.ResPK = ResPK
local ResArray = _M{
    {REP, IdNum, "res", 1}, 	--数组
}
_P.ResArray = ResArray

--神秘商店商品
local ShopGoods = _M{
	{OPT, int32, "cid", 1},	--配置ID
	{OPT, int32, "num", 2},	--余量
}
_P.ShopGoods = ShopGoods
local ShopGoodsPK = _M{
	{OPT, int32, "cid", 1},	--配置ID
}
_P.ShopGoodsPK = ShopGoodsPK

--神秘商店刷新
local ShopFlush = _M{
	{OPT, int64, "lastFlush", 1},	--上次刷新时间
	{OPT, int32, "times", 2},	--手动刷新次数
}
_P.ShopFlush = ShopFlush

--变化器
local Ticker = _M{
	{OPT, int64, "rest", 1},	--上次值
	{OPT, int64, "time", 2},	--上次变化时间(0不变)
	{OPT, float, "rate", 3},	--变化值(/ms,0不变)
}
_P.Ticker = Ticker

--世界格子
local Tile = _M{
	{OPT, int32, "x", 1},	--坐标X
	{OPT, int32, "y", 2},	--坐标Y
	{OPT, int32, "tp", 3},	--类型 TileConfig.id
	{OPT, int32, "tp2", 4},	--子类型 按各类型定义
	{OPT, int32, "level", 5},	--级别 按各类型定义
	
	{OPT, int64, "uid", 6},	--所属玩家(缺省0无)
	{OPT, int64, "allianceId", 7},	--所属联盟(缺省0无)
	
	{REP, int64, "troopId", 8},	--驻扎部队sid组
	
	{OPT, Ticker, "durability", 9}, --建筑耐久度(TODO)
	{OPT, Ticker, "resVal", 10},	--资源采集度
	
	--{REP, int64, "building", 11},	//建筑表现id组 TODO
	--{REP, int64, "datas", 12},	//附加实例数据 TODO
	
}
_P.Tile = Tile
local TilePK = _M{
	{OPT, int32, "x", 1},	--X
	{OPT, int32, "y", 2},	--Y
}
_P.TilePK = TilePK

--兵种单元
local Unit = _M{
    {OPT, int32, "cid", 1}, 	-- 配置ID
    {OPT, int32, "num", 2}, 	-- 数量
    {OPT, int64, "uid", 3}, 	-- 所属(可能联军有用)
}
_P.Unit = Unit
local UnitPK = _M{
    {OPT, int32, "cid", 1}, 	-- 配置ID
}
_P.UnitPK = UnitPK
local UnitArray = _M{
    {REP, Unit, "unit", 1}, 	--数组
}
_P.UnitArray = UnitArray

--城建建筑
local Building = _M{
	{OPT, int64, "sid", 1},	--主键(实例ID)
	{OPT, int32, "tp", 2},	--类型(配表ID)
	{OPT, int32, "level", 3},	--级别
	
	{OPT, int64, "uid", 6},	--所属玩家(弃x,对外缩略优化再议)
	{OPT, int32, "pos", 7},	--位置索引(建造选位时前端提供,0:内城不需要索引)
	--{OPT, int32, "stat", 8},	//状态(用再加)
}
_P.Building = Building
local BuildingPK = _M{
	{OPT, int64, "sid", 1},	--主键
}
_P.BuildingPK = BuildingPK
--领地区域解锁
local CityArea = _M{
	{OPT, int32, "cid", 1},	--配置ID
}
_P.CityArea = CityArea

--资源产出
local ResOut = _M{
	{OPT, int32, "cid", 1},	--资源ID
	{OPT, int64, "resTime", 2},	--上次结算时间
	{OPT, float, "resOut", 3},	--产量/s
	{OPT, int32, "resVal", 4},	--已产出
	{OPT, int32, "resMax", 5},	--容量上限
}
_P.ResOut = ResOut
local ResOutPK = _M{
	{OPT, int32, "cid", 1},	--资源ID
}
_P.ResOutPK = ResOutPK

--工作队列
local Job = _M{
	{OPT, int64, "sid", 1},	--主键
	{OPT, int32, "tp", 2},	--类(1建筑/升级 2拆建 3训兵 4升兵 5疗兵 6科技 7城防)
	{OPT, int64, "stTime", 3},	--开始时间
	{OPT, int64, "edTime", 4},	--结束时间
	{OPT, int64, "bid", 5},	--指定建筑sid(限 建/升/拆)
	{OPT, int32, "techId", 6},	--科技配置cid
	{OPT, int32, "unitTp", 7},	--训/升兵配置cid(查询用冗余)
	{REP, Unit, "unit", 8},	--产品组(兵/疗(兵种,数量))
	{OPT, int64, "sumTime", 9},	--初始总时间
}
_P.Job = Job
local JobPK = _M{
	{OPT, int64, "sid", 1},	--主键
}
_P.JobPK = JobPK

--英雄
local Hero = _M{
    {OPT, int64, "sid", 1}, 	-- sid
    {OPT, int64, "uid", 2}, 	-- uid
    {OPT, int32, "cid", 3}, 	-- 表ID
    {OPT, int32, "level", 4}, 	-- 等级
    {OPT, int32, "exp", 5}, 	-- 经验
    {OPT, int32, "step", 6}, 	-- 品阶
    {OPT, int32, "stat", 7}, 	-- 状态0空闲1出征2重伤?
}
_P.Hero = Hero
local HeroPK = _M{
    {OPT, int64, "sid", 1}, 	-- sid
}
_P.HeroPK = HeroPK
--招募数据
local Recruit = _M{
    {OPT, int64, "useTimesLow", 1}, 	-- 普通每日已用免费次数
    {OPT, int64, "nextFreeTimeHigh", 2}, -- 高招下次免费时间
    {OPT, int32, "timesHigh", 3}, 	-- 高招保底计数
    {OPT, int64, "nextFreeTimeLow", 4}, -- 普招下次免费时间
}
_P.Recruit = Recruit

--部队
local Troop = _M{
	{OPT, int64, "sid", 1},	--主键
	{OPT, int64, "uid", 2},	--所属玩家
	{OPT, int32, "tp", 3},	--行动(1采,2侦,3驻,4集,5打怪,6打人,7联攻怪,8联攻人,9联防人)
	{OPT, int32, "stat", 4},	--行动状态(1集结2出发3停留(驻采战)4返回)
	{OPT, int32, "sx", 5},	--起点坐标
	{OPT, int32, "sy", 6},	--起点坐标
	{OPT, int32, "tx", 7},	--目标坐标
	{OPT, int32, "ty", 8},	--目标坐标
	{OPT, int32, "ttp", 9},	--目标类型 Tile.tp
	{OPT, int64, "tval", 10},	--目标值 Tile.val
	{OPT, int64, "lsid", 11},	--所属联军部队sid
	{OPT, int64, "st", 12},	--出发时间(中途加速修正)
	{OPT, int64, "et", 13},	--到达时间(0驻扎 中途加速修正)
	{OPT, int64, "sumTime", 14},	--初始总时间
	{REP, int64, "hero", 15},	--英雄sid(主将,副将,副将)
	{REP, Unit, "unit", 16},	--兵种数量
	{REP, Res, "res", 17},	--携带资源
}
_P.Troop = Troop
local TroopPK = _M{
	{OPT, int64, "sid", 1},	--主键
}
_P.TroopPK = TroopPK

--集结联军概要
local Rally = _M{
	{OPT, int64, "sid", 1},	--主键 主部队sid
	{OPT, int64, "uid", 2},	--发起者uid
	{OPT, int64, "goTime", 3},	--集结截止时间
	
	{OPT, int32, "troopMax", 4},	--部队数上限
	{OPT, int32, "troopNum", 5},	--当前部队数
	{OPT, int32, "unitMax", 6},	--兵单位上限
	{OPT, int32, "unitNum", 7},	--当前兵单位数
}
_P.Rally = Rally
local RallyPK = _M{
	{OPT, int64, "sid", 1},	--主键
}
_P.RallyPK = RallyPK

--科技
local Tech = _M{
	{OPT, int32, "cid", 1},	--主键
	{OPT, int32, "lv", 2},	--级别
}
_P.Tech = Tech
local TechPK = _M{
	{OPT, int32, "cid", 1},	--主键
}
_P.TechPK = TechPK
--Buff
local Buff = _M{
	{OPT, int32, "cid", 1},	--主键
	{OPT, string, "src", 2},	--源 building,tech,item,vip,hero,...
	{OPT, float, "val", 3},	--值
	{OPT, int64, "timeOut", 4},	--限时至 (无或0:无限时)
}
_P.Buff = Buff
local BuffPK = _M{
	{OPT, int32, "cid", 1},	--主键
	{OPT, string, "src", 2},	--源
}
_P.BuffPK = BuffPK
--Buff总结果(测试用)
local BuffCalc = _M{
	{OPT, int32, "cid", 1},	--主键
	{OPT, float, "val", 3},	--值
}
_P.BuffCalc = BuffCalc
local BuffCalcPK = _M{
	{OPT, int32, "cid", 1},	--主键
}
_P.BuffCalcPK = BuffCalcPK

--邮件
local Mail = _M{
    {OPT, int64, "sid", 1},	-- 主键
    {OPT, int32, "tp", 2}, 	-- 类型:1系统2玩家3侦查情报4战报5行动报告6联盟
	{OPT, int64, "fromUid", 3}, 	-- 发送者玩家UID
	{OPT, string, "fromName", 4}, 	-- 发送者玩家名
    {OPT, int32, "cid", 5},	-- 邮件模板表ID
	{OPT, string, "title", 6}, 	-- 标题参数|分割
	{OPT, string, "content", 7}, 	-- 正文参数|分割
    {OPT, int64, "time", 8},	-- 发送时间
    {OPT, int64, "timeOut", 9},	-- 过期时间
    {OPT, int64, "reportId", 10},	-- 附件战报ID
    {OPT, int64, "intelId", 11},	-- 附件情报ID
	{REP, IdNum, "item", 12}, 	-- 附件道具组
	{REP, IdNum, "res", 13},	-- 附件资源/计数组
    {OPT, bool, "read", 14},	-- 己阅
    {OPT, bool, "take", 15},	-- 己领(无附件默认false)
    {OPT, bool, "favor", 16},	-- 已收藏(过期仍保留)
	{OPT, bool, "win", 17}, 	-- 战报使用是否胜利
}
_P.Mail = Mail
local MailPK = _M{
    {OPT, int64, "sid", 1},	-- ID
}
_P.MailPK = MailPK
--邮件计数
local MailNum = _M{
    {OPT, int32, "unread", 1}, 	-- 未读邮件数
    {OPT, int32, "all", 2}, 	-- 邮件数
}
_P.MailNum = MailNum

--task 主线支线任务
local Task = _M{
    {OPT, int64, "tid", 1},	--主键 任务Id
	{OPT, int32, "classify", 2},	--类别 主线1 支线2 每日3
	{OPT, int64, "num", 3},	--当前完成数量
	{OPT, int32, "tstate", 4},	--当前任务状态 0预备状态 1进行状态 2已完成 3已领取
}
_P.Task = Task
--task 主线支线任务 主键
local TaskPK = _M{
    {OPT, int64, "tid", 1},	--主键 任务Id
	{OPT, int32, "classify", 2},	--类别 主线1 支线2 每日3
}
_P.TaskPK = TaskPK

--ActicityReward 活跃度宝箱
local ActicityReward = _M{
    {OPT, int64, "dbid", 1},	--主键 宝箱id - 对应表
	{OPT, int32, "dbstate", 2},	--当前状态 0不可领取 1可领取 2已领取
}
_P.ActicityReward = ActicityReward

local CombatRecordPK = _M{
	{OPT, int64, "sid", 1},	--序主键
}
_P.CombatRecordPK = CombatRecordPK

--战报 兵种 英雄 箭塔 击杀内容
local CombatUnitInfo = _M{
	{OPT, int32, "unitTp", 1},	--步骑弓车 999箭塔 998英雄
	{REP, Hero, "hero", 2},	--英雄
	{OPT, int32, "killNum", 3},	--击败总数
	{OPT, int32, "deadNum", 4},	--死亡数量
	{OPT, int32, "woundedNum", 5},	--伤兵数量
	{OPT, int32, "lifeNum", 6},	--存活数量
	{REP, Buff, "buff", 7},	--buff
}
_P.CombatUnitInfo = CombatUnitInfo

--战报 详细内容
local CombatInfoDetail = _M{
	{OPT, string, "name", 1},	--玩家的名称
	{OPT, int32, "x", 2},	--出发点的x坐标
	{OPT, int32, "y", 3},	--出发点的y坐标
	{REP, Hero, "hero", 4},	--英雄
	{OPT, int32, "power", 5},	--战斗力
	{OPT, int32, "killNum", 7},	--击败总数
	{OPT, int32, "deadNum", 8},	--死亡数量
	{OPT, int32, "woundedNum", 9},	--伤兵数量
	{REP, CombatUnitInfo, "CombatUnitInfo", 10},	--
	{OPT, int32, "unitNum", 11},	--参战士兵数量
	{OPT, bool, "leader", 12},	--是否是队长
}
_P.CombatInfoDetail = CombatInfoDetail

--战报 信息内容
local CombatInfo = _M{
	{OPT, string, "name", 1},	--玩家的名称
	{OPT, int32, "x", 2},	--出发点的x坐标
	{OPT, int32, "y", 3},	--出发点的y坐标
	{OPT, int32, "maxAramyNum", 4},	--总兵数
	{OPT, int32, "lossAramyNum", 5},	--损失兵数 
	{OPT, int32, "lossPower", 7},	--损失战力
	{OPT, int32, "deadNum", 8},	--死亡数量 (存活=总兵数-损失兵数)
	{OPT, int32, "woundedNum", 9},	--伤兵数量
	{REP, CombatInfoDetail, "detail", 10},	--
	{OPT, int32, "infantryNum", 11},	--步兵数量
	{OPT, int32, "cavalryNum", 12},	--骑兵数量
	{OPT, int32, "bowmenNum", 13},	--弓兵数量
	{OPT, int32, "vehicledNum", 14},	--车兵数量
	{OPT, int32, "infantryPower", 15},	--步兵战力
	{OPT, int32, "cavalryPower", 16},	--骑兵战力
	{OPT, int32, "bowmenPower", 17},	--弓兵战力
	{OPT, int32, "vehicledPower", 18},	--车兵战力
	{OPT, int32, "infantryDead", 19},	--步兵死亡数
	{OPT, int32, "cavalryDead", 20},	--骑兵死亡数
	{OPT, int32, "bowmenDead", 21},	--弓兵死亡数
	{OPT, int32, "vehicledDead", 22},	--车兵死亡数
	{OPT, int32, "infantryKill", 23},	--步兵击杀数
	{OPT, int32, "cavalryKill", 24},	--骑兵击杀数
	{OPT, int32, "bowmenKill", 25},	--弓兵击杀数
	{OPT, int32, "vehicledKill", 26},	--车兵击杀数 
}
_P.CombatInfo = CombatInfo
--战报 头部内容
local CombatRecord = _M{
	{OPT, int64, "sid", 1},	--序主键
	{OPT, string, "combatId", 2},	--战斗id 用于播放战斗回放
	{OPT, int64, "userId", 3},	--userId
	{OPT, CombatInfo, "atk", 4},	--攻击方
	{OPT, CombatInfo, "def", 5},	--防守方
	{OPT, int64, "time", 6},	--发生的时间点(毫秒)
	{REP, IdNum, "item", 7}, 	--获得道具
	{REP, IdNum, "res", 8}, 	--获得资源
	{OPT, int32, "exp", 9}, 	--获得经验
	{OPT, bool, "win", 10}, 	--是否胜利
	{OPT, bool, "myDef", 11},	--是否是防守方
	{OPT, int32, "x", 12},	--战斗发生的x坐标
	{OPT, int32, "y", 13},	--战斗发生的y坐标
}
_P.CombatRecord = CombatRecord

--alliance 联盟
local Alliance = _M{
    {OPT, int64, "sid", 1},	--主键 联盟Id
	{OPT, string, "name", 2},	--联盟名字
	{OPT, string, "flag", 3},	--旗帜
	{OPT, string, "allianceManifesto", 4},	--宣言
	{OPT, string, "allianceMinName", 5},	--缩写
	{OPT, string, "language", 6},	--语言
	{OPT, int32, "autoPermit", 7},	--招募状态
	{OPT, int32, "level", 8},	--级别
	{OPT, int32, "onlineNum", 9},	--在线人数
	{OPT, bool, "leaderOnline", 10},	--帮主是否在线
	{OPT, int64, "allianceCombatPower", 11},	--联盟战斗力
	{REP, int32, "allianceXY", 12},	--联盟坐标
	{OPT, string, "leaderName", 13},	--盟主名字
	{OPT, int32, "currNum", 14},	--当前数量
	{OPT, int32, "maxNum", 15},	--最大数量
}
_P.Alliance = Alliance
local AlliancePK = _M{
    {OPT, int64, "sid", 1},	--主键 联盟Id
}
_P.AlliancePK = AlliancePK

-- 联盟成员列表
local AllianceMember = _M{
    {OPT, int64, "uid", 1},	--角色UID
	{OPT, string, "name", 2},	--角色名字
	{OPT, int32, "level", 3},	--级别
	{OPT, int32, "post", 4},	--职位(1盟主2副主3官员4成员5见习)
	{OPT, int64, "power", 5},	--战力
	{OPT, int32, "contribution", 6},	--贡献
	{OPT, int32, "cityX", 7},	--主城坐标X
	{OPT, int32, "cityY", 8},	--主城坐标Y
	{OPT, int64, "loginTime", 9},	--上次在线时间
	{OPT, int64, "joinTime", 10},	--入盟时间
	{OPT, int64, "forbiddenWords", 11},	--禁言至时间
	{OPT, int32, "icon", 12},	--头像
}
_P.AllianceMember = AllianceMember
local AllianceMemberPK = _M{
    {OPT, int64, "uid", 1},	--角色UID
}
_P.AllianceMemberPK = AllianceMemberPK

-- 联盟被申请列表
local AllianceApply = _M{
	{OPT, int64, "uid", 1},	--申请人角色UID
	{OPT, string, "name", 2},	--申请人角色名
    {OPT, int32, "icon", 3},	--头像
    {OPT, int32, "level", 4},	--级别
    {OPT, int64, "power", 5},	--战力
	{OPT, int64, "time", 6},	--时间
}
_P.AllianceApply = AllianceApply
local AllianceApplyPK = _M{
	{OPT, int64, "uid", 1},	--主键
}
_P.AllianceApplyPK = AllianceApplyPK

-- 我发出的申请列表(联盟列表用)
local UserAllianceApply = _M{
	{OPT, int64, "sid", 3},	--申请联盟ID
}
_P.UserAllianceApply = UserAllianceApply
local UserAllianceApplyPK = _M{
	{OPT, int64, "sid", 1},	--主键
}
_P.UserAllianceApplyPK = UserAllianceApplyPK

-- 联盟科技
local AllianceTech = _M{
    {OPT, int64, "cid", 1},	--配置ID
    {OPT, int32, "level", 2},	--级别
    {OPT, int32, "exp", 3},	--经验进度
    {OPT, bool, "recommend", 4},	--推荐
    {OPT, int64, "upTime", 5},	--升级完成时间(-1未在升级中)
}
_P.AllianceTech = AllianceTech
local AllianceTechPK = _M{
    {OPT, int64, "cid", 1},	--
}
_P.AllianceTechPK = AllianceTechPK

-- 联盟帮助列表
local AllianceHelp = _M{
    {OPT, int64, "sid", 1},	--等于求助者队列ID
    {OPT, int64, "uid", 2},	--求助者角色UID
    {OPT, int32, "tp", 3},	--同Job(1建筑/升级 5疗兵 6科技)
    {OPT, int32, "cid", 4},	--Job配置id
    {OPT, int32, "toLevel", 5},	--队列目标级别
    {OPT, int32, "times", 6},	--己帮次数
    {OPT, int32, "maxTimes", 7},	--最大可帮次数
}
_P.AllianceHelp = AllianceHelp
local AllianceHelpPK = _M{
    {OPT, int64, "sid", 1},	--sid
}
_P.AllianceHelpPK = AllianceHelpPK

-- 联盟动态
local AllianceLog = _M{
    {OPT, int64, "sid", 1},	--角色UID
    {OPT, int64, "cid", 2},	--类型
    {OPT, int64, "time", 3},	--时间
    {OPT, string, "detail", 4},	--参数组 逗号分切 前端多语言拼
}
_P.AllianceLog = AllianceLog
local AllianceLogPK = _M{
    {OPT, int64, "sid", 1},	--
}
_P.AllianceLogPK = AllianceLogPK

--更新
local Updates = _M{
	{OPT, Server, "server", 1},	--服务器数据
	{OPT, User, "user", 2},	--角色数据
	{REP, Item, "item", 3},	--道具
	{REP, Hero, "hero", 4},	--英雄
	{REP, Mail, "mail", 5},	--邮件(上线不带)
	{REP, MailNum, "mailNum", 6},	--邮件计数(上线带)
	{REP, Troop, "troop", 7},	--部队
	{REP, Tile, "tile", 8},	--格子
	{REP, User, "other", 9},	--其它角色数据
	{REP, Res, "res", 10},	--资源/计数
	{REP, Building, "building", 11},--建筑
	{REP, Unit, "unit", 12},	--兵种
	{REP, Unit, "wounded", 13},	--伤兵
	{REP, Job, "job", 14},	--工作队列
	{REP, Task, "task", 15},	--主线和支线任务
	{REP, Tech, "tech", 16},	--科技
	{REP, Buff, "buff", 17},	--buff
	{REP, ActicityReward, "box", 18},	--日常宝箱
	{REP, Alliance, "alliance", 19},	--联盟信息
	{REP, ResOut, "resOut", 20},	--资源产出
	{REP, Recruit, "recruit", 21}, 	--英雄招募数据
	--{REP, IdNum, "recruitResult", 22}, 	//英雄招募结果(以道具方式)
	{REP, Rally, "rally", 22},	--联军
	{REP, UserLimit, "userLimit", 23},	--日常计限量
	{REP, CombatRecord, "combatRecord", 24},	--战报
	{REP, ShopFlush, "mysteryShopFlush", 25},	--神秘商店刷新数据
	{REP, ShopGoods, "mysteryShopGoods", 26},	--神秘商店商品数据
	{REP, AllianceMember, "allianceMember", 27},	--联盟成员
	{REP, AllianceApply, "allianceApply", 28},	--联盟申请
	{REP, UserAllianceApply, "userAllianceApply", 29},	--我发出的申请列表
	{REP, AllianceLog, "allianceLog", 30},	--联盟日志
	{REP, AllianceHelp, "allianceHelp", 31},	--联盟帮助
	{REP, UserCount, "userCount", 32},	--个人统计
	{REP, UserMark, "userMark", 33},	--前端记录
	{REP, AllianceTech, "allianceTech", 34},	--联盟科技
	{REP, BuffCalc, "buffCalc", 36},	--buff总值
	{REP, CityArea, "cityArea", 37},	--领地区域解锁
}
_P.Updates = Updates
--删除(主键)
local Removes = _M{
	{REP, ItemPK, "item", 1},	--道具
	{REP, HeroPK, "hero", 2},	--英雄
	{REP, MailPK, "mail", 3},	--邮件
	{REP, TroopPK, "troop", 4},	--部队
	{REP, TilePK, "tile", 5},	--格子
	{REP, ResPK, "res", 6},	--资源/计数
	{REP, BuildingPK, "building", 7},--建筑
	{REP, UnitPK, "unit", 8},	--兵种
	{REP, UnitPK, "wounded", 9},	--伤兵
	{REP, JobPK, "job", 10},	--工作队列
	{REP, TechPK, "tech", 11},	--科技
	{REP, BuffPK, "buff", 12},	--buff
	{REP, TaskPK, "task", 13},	--任务
	{REP, RallyPK, "rally", 14},	--联军概要
	{REP, UserLimitPK, "userLimit", 23},	--日常计限量
	{REP, CombatRecordPK, "combatRecord", 24},	--战报
	{REP, ShopGoodsPK, "mysteryShopGoods", 26},	--神秘商店商品数据
	{REP, AllianceMemberPK, "allianceMember", 27},	--联盟成员
	{REP, AllianceApplyPK, "allianceApply", 28},	--联盟申请
	{REP, UserAllianceApplyPK, "userAllianceApply", 29},	--我发出的申请列表
	{REP, AllianceLogPK, "allianceLog", 30},	--联盟日志
	{REP, AllianceHelpPK, "allianceHelp", 31},	--联盟帮助
	{REP, UserCountPK, "userCount", 32},	--个人统计
	{REP, UserMarkPK, "userMark", 33},	--前端记录
	{REP, BuffCalcPK, "buffCalc", 36},	--buff总值(测试用)
}
_P.Removes = Removes

--*_C+1通用回应
--12主动推送
local Response_S = _M{
	{OPT, Updates, "updates", 2},	--全量更新 主键必带 rep变空数据必用
	{OPT, Removes, "removes", 3},	--删除,必须只有主键
	{OPT, Updates, "props", 4},	--增量更新 主键必带,opt只发变动的,rep变不可用
}
_P.Response_S = Response_S
--14通用错误
local Error_S = _M{
    {OPT, int32, "code", 2},        -- 正常返回为0, 否则为错误代码
    {OPT, string, "msg", 3},       	-- 错误信息
	{REP, string, "params", 4},	-- 错误参数,由错误号决定
}
_P.Error_S = Error_S

-----------------------------------------------------

--1
local Ping = _M{
}
_P.Ping = Ping
--2
local Pong = _M{
}
_P.Pong = Pong

return _P
