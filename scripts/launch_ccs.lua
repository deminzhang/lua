--launch_ccs.lua
----------------------------------------------------------------
dofile'ccs/ccs_net.lua'
dofile'ccs/ccs_logic.lua'

----------------------------------------------------------------
loadConfig{}
afterConfig{}
checkConfig{}
onStart{}
print('>>ccs_real_start version=',os.info.version)
do return end
error('this is end of launch')