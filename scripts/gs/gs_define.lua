--gs_define.lua
print('>>gs_define')
----------------------------------------------------------------
--global class
_G.Zone = class(Object)
_G.Unit = class(Object)
_G.Monster = class(Unit)
_G.Role = class(Unit)
_G.NPC = class(Unit)

----------------------------------------------------------------
--player system
define.defineRole{role=EMPTY}
define.loadUserInfo{info=EMPTY,role=EMPTY}
--common system
define.onUseSkill{p=EMPTY,target=EMPTY,skillid=0}
define.onGethit{p=EMPTY,from=EMPTY,skillid=0}
define.onDie{entity=EMPTY,killer=EMPTY,skillid=0}
define.onRoleDie{p=EMPTY,killer=EMPTY,skillid=0}
define.onMonDie{mon=EMPTY,killer=EMPTY,skillid=0}
