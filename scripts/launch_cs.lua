--launch_cs.lua
----------------------------------------------------------------
debug.dump(os.env)
debug.dump(os.info)
--dofile--------------------------------------------------------
dofile'lib/sql.lua'
dofile'cs/cs_queue.lua'
dofile'cs/cs_define.lua'
dofile'db/dbupdate.lua'
dofile'cs/cs_net.lua'
dofile'cs/cs_callout.lua'
dofile'cs/cs_logic.lua'
dofile'cs/cs_client.lua'
dofile'cs/cs_login.lua'
dofile'cs/cs_item.lua'
----------------------------------------------------------------
--start
loadConfig{}
afterConfig{}
checkConfig{}
onStart{}
print('>>cs_real_start version=',os.info.version)
do return end
error('this is end of launch')