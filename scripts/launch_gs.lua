--launch_gs.lua
----------------------------------------------------------------
debug.dump(os.info)
dofile'gs/gs_queue.lua'
dofile'gs/gs_define.lua'
dofile'gs/gs_net.lua'
dofile'gs/gs_logic.lua'
dofile'lib/vector2.lua'
dofile'lib/vector3.lua'
dofile'common/object.lua'
dofile'gs/gs_callout.lua'
dofile'gs/gs_zone.lua'
dofile'gs/gs_attr.lua'
dofile'gs/gs_unit.lua'
dofile'gs/gs_role.lua'
dofile'gs/gs_monster.lua'
dofile'gs/gs_login.lua'
dofile'gs/gs_item.lua'
dofile'gs/gs_skill.lua'
----------------------------------------------------------------
--start
loadConfig{}
afterConfig{}
checkConfig{}
onStart{}
print('>>gs_real_start version=',os.info.version)
do return end
error('this is end of launch')