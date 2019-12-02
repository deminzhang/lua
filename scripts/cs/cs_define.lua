--cs_define.lua
print('>>cs_define')
--common init
define.afterMerge{}		--合服后处理过期及冲突(updateDataBase后)
--common loop
define.onBigTime{year=0,month=0,day=0,hour=0,min=0,sec=0}--分循环
--common login
define.onLogin{}		--帐号登陆
define.onCreateRole{uid=0,pid=0,name=0} --新建角色初始化
define.onRoleLogin{pid=0}	--登陆初始化
define.getUserInfo{uid=0, pid=0, info=EMPTY, step=''} --收集角色数据
define.cleanupUser{pid=0}	--正式删掉的号角清理数据
--common item
define.onGetItem{pid, it, id, num, bind, lab, old, new}
define.onLossItem{pid, it, id, num, bind, lab, old, new}
define.onGetCoin{pid, num, lab, old, new}
define.onLossCoin{pid, num, lab, old, new}
define.onGetCoinB{pid, num, lab, old, new}
define.onLossCoinB{pid, num, lab, old, new}
define.onGetGold{pid, num, lab, old, new, acc, cost}
define.onLossGold{pid, num, lab, old, new, acc, cost}
define.onGetGoldP{pid, num, lab, old, new}
define.onLossGoldP{pid, num, lab, old, new}
--common system
define.onUnlock{pid=0,k=''}		--功能解锁
define.onLock{pid=0,k=''}		--功能反锁
define.onActiveStat{k='',stat=0}--活动开关

