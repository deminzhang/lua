--export from ?.xlsx
_G.cfg_zone = {
	[1] = {id=1, type='normal', createOnNew=1,
		create={
			{type='mon',id=1,pos={x=5,y=1,z=5,r=0} },
			{type='mon',id=1,pos={x=15,y=1,z=5,r=0} },
			{type='mon',id=1,pos={x=5,y=1,z=15,r=0} },
			{type='mon',id=1,pos={x=15,y=1,z=15,r=0} },
			{type='mon',id=1,pos={x=25,y=1,z=5,r=0} },
			-- {type='npc',id=1,pos={x=,y=,z=,r=}},
			-- {type='mine',id=1,pos={x=,y=,z=,r=}},
			-- {type='trap',id=1,pos={x=,y=,z=,r=}},
		}
	},
	[2] = {id=2, type='normal', createOnNew=1,
		create={
			{type='mon',id=1,pos={x=5,y=1,z=5,r=0} },
			{type='mon',id=1,pos={x=15,y=1,z=5,r=0} },
			{type='mon',id=1,pos={x=5,y=1,z=15,r=0} },
			{type='mon',id=1,pos={x=15,y=1,z=15,r=0} },
			{type='mon',id=1,pos={x=25,y=1,z=5,r=0} },
		}
	},
	[3] = {id=3, type='private', createOnNew=false,
		create={
			{type='mon',id=1,pos={x=2,y=2,z=2,r=0} },
		}
	},
	[4] = {id=4, type='dungeon', createOnNew=false,
		create={
			{type='mon',id=1,pos={x=2,y=2,z=2,r=0} },
		}
	},
	[5] = {id=5, type='battle', createOnNew=false,
		create={
			{type='mon',id=1,pos={x=2,y=2,z=2,r=0} },
		}
	},
}
return cfg_zone