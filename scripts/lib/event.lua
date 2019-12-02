-- do return end
--TODO 待转到C

local function _event(define,use_G,event,when,call)
	if define then
		assert(not rawget(_G,define), define..' has defined')
	end
	if when then
		assert(not rawget(_G,when), when..' has defined')
	end
	if event then
		assert(not rawget(_G,event), event..' has defined')
	end
	if call then
		assert(not rawget(_G,call), call..' has defined')
	end
	----------------------------------------------------------------
	local type = type
	local assert = assert
	local rawget = rawget
	local rawset = rawset
	local pairs = pairs
	local ipairs = ipairs
	local insert = table.insert
	local remove = table.remove
	local format = string.format
	local setmetatable = setmetatable
	local gethook = debug.gethook
	local sethook = debug.sethook
	local getlocal = debug.getlocal
	local setlocal = debug.setlocal
	local huge = math.huge
	local byte = string.byte
	----------------------------------------------------------------
	local defined = {}			--k:name v:function
	local events = {}			--k:name v:{filter={},func=func}
	local arg_def = {}			--k:name v:{}
	local arg_type = {}			--k:name v:{}
	local lastsid = 0			--register serial id
	local _filter				--filter last set 
	----------------------------------------------------------------
	local _args
	local uphookf,uphookm,uphookc	--conflict with LuaStudio
	--调试防冲突,有些调试器无效只能用无hook方式
	local hook = function(...)
		sethook(uphookf,uphookm,uphookc)
		for i=1, huge do
			local k = getlocal(2,i)
			if k==nil then
				break
			else
				if k=='_args' then
					setlocal(2,i,_args)
				elseif byte(k)~=40 then -- not '(*temporary)'
					setlocal(2,i,_args[k])
				end
			end
		end
	end
	local event_def = setmetatable({},{
		__index = function(self, name)
			assert(not defined[name], 'duplicate event:'..name)
			assert(not _G[name], 'duplicate event:'..name)
			
			local run_once = true
			return function(param) --setdefaultarg
				assert(run_once,'define once')
				run_once = nil
				local fn
				if param then  --单表参数,有筛选筛选
					arg_type[name] = 'table'
					assert(type(param)=='table','define.'..name..' #')
					for k,v in pairs(param) do
						assert(k~='_order','arg key "_order" is take up')
						assert(k~='_delay','arg key "_delay" is take up')
						assert(k~='_tag','arg key "_tag" is take up')
						assert(k~='_unique','arg key "_unique" is take up')
						assert(k~='_skip','arg key "_skip" is take up')
						assert(k~='_stop','arg key "_stop" is take up')
					end
					
					fn = function(args,...)
						local tt = type(args)
						assert(tt=='table',name..'bad arg#1(table expected, got '..tt..')')
						for k, v in next,arg_def[name]do
							if args[k] == nil then
								args[k] = v
							end
						end
						if args._delay then
							_enqueue( args._delay, nil, name, args, ...)
							args._delay = nil
							return
						end
						_args = args
						local ret --use last return
						for i, e in ipairs(events[name]) do --sortby i
							if not e._skip then
								local match = true
								for k,v in pairs(e.filter) do
									if args[k] ~= v then
										match = false
										break
									end
								end
								if match then
									uphookf,uphookm,uphookc = gethook()
									sethook(hook, "c")
									ret = e.func()
									if args._stop then break end
								end
							end
						end
						_args = nil
						return ret
					end
				else			--任意参数,无筛选特性
					arg_type[name] = '...'
					
					fn = function(...)
						local ret --use last return
						for i, e in ipairs(events[name]) do --sortby i
							if not e._skip then
								ret = e.func(...)
							end
						end
						return ret
					end
				end
				arg_def[name] = param
				defined[name] = fn
				events[name] = {}
			end
		end,
		__call = function(self,...)
			--set something
			return self
		end,
	})
	local event_reg = setmetatable({},{
		__index = defined,
		__newindex = function(self,name,func)
			local e = events[name]
			assert(e,'undefined event:'..name)
			assert(type(func)=='function','event must be a function value')
			local filter, order, tag, unique = _filter
			_filter = nil
			if filter then
				if filter._order then
					order = filter._order
					filter._order = nil
					assert(type(order)=='number', '_order must be a number value')
				end
				if filter._tag then
					tag = filter._tag
					filter._tag = nil
				end
				if filter._unique then
					unique = filter._unique
					filter._unique = nil
				end
			end
			local info = debug.getinfo( 2 )
			lastsid = #e+1
			lastevent = name
			local idx = lastsid
			if unique then --重写覆盖标志
				for i,v in ipairs(e) do --注册是预处理不在乎效率
					if v.unique==unique then
						remove(e,i) --兼改_order,所在不在这里直改换
						idx = idx - 1
						break
					end
				end
			end
			if order then --有order靠前,order小者靠前
				for i,v in ipairs(e) do --注册是预处理不在乎效率
					if not v.order or order < v.order then
						idx = i
						break
					end
				end
			end
			local ev = {
				sid = lastsid, --注册序
				func = func,
				groupname = name,
				order = order, 		--执行序
				filter = filter or {},
				tag = tag,			--tag
				unique = unique,		--重写 unique_key
				src = format('%s|%s',info.source,info.currentline) --注册源
			}
			insert(e, idx, ev) --在注册时就排好序
		end,
		__call = function(self, filter) --筛选器/预定义_order
			local tt = type(filter)
			assert(tt=='table','bad argument #1(table expected, got '..tt..')')
			_filter = filter
			return self
		end,
	})
	local event_set = function(filter) --筛选器/预定义_order
		local tt = type(filter)
		assert(tt=='table','bad argument #1(table expected, got '..tt..')')
		_filter = filter
		return event_reg
	end
	local event_call = setmetatable({}, {__index = defined})
	----------------------------------------------------------------
	if use_G then
		setmetatable(_G, {
			__index = defined,
			__newindex = function(self,name,value)
				if _filter then
					if defined[name] then
						event_reg[name] = value
						return
					else
						error('can not register undefined event:'..name)
					end
				end
				if defined[name] then
					-- event_reg[name] = value
					-- return --default _filter={}
					error('can not register event directly,use when{} or event.')
				end
				rawset(self,name,value)
			end
		})
	end
	----------------------------------------------------------------
	if define then
		rawset(_G, define,event_def)--event_def
	end
	if when then
		rawset(_G, when, event_set)	--event_set
	end
	if event then
		rawset(_G, event,event_reg)	--event_reg
	end
	if call then
		rawset(_G, call, event_call)--event_call
	end
	return event_def,event_set,event_reg,event_call
end

--事件系统开启
--_event(定义方法,用_G的reg/call,注册方法,设置参数,触发方法
--_event('event_def',_G,'event_reg','event_set','event_call')
--_event('define',nil,'event','when','call')
-- local define, when, reg, call = _event()
-- _G.event = {def=define, set=when, reg=reg, call=call}
_event('define',_G,'event','when')
----------------------------------------------------------------

----------------------------------------------------------------
--[[sample switch
--注册参数
--_order:执行序,优先:_order小 > _order大 > 无_order. 无或_order相同按注册序
--_unique:唯一性,重复注册覆盖
--------------------------------
define.tt()			--定义tt为普通事件
when{} 
function tt(a,b,c)	--注册监听
	print('--tt1',a,b,c)
end
when{_unique='tta',_order=1} --注册监听
function tt(a,b,c)	--注册监听
	print('--tt2',a,b,c)
end
when{_unique='ttb',_order=0} --注册监听
function tt(a,b,c)	--注册监听
	print('--tt3',a,b,c)
end
--执行
tt(1,2,3)
--结果
--tt3 1 2 3
--tt2 1 2 3
--tt1 1 2 3
when{_unique='ttb',_order=2} --
function tt(a,b,c)	--重写监听
	print('--tt3',a,b,c)
end
--事件触发
tt(1,2,3)
--结果
--tt2 1 2 3
--tt3 1 2 3
--tt1 1 2 3
--------------------------------
define.TT{a=0,b=0,c=0} --定义TT为筛选器事件及默认参数
when{}
function TT(a,b,c)	--注册监听
	print('--TT1',a,b,c)
end
when{_order=0}
function TT(a,b,c)	--注册监听
	print('--TT2',a,b,c)
end
when{b=2}			--设置过滤
function TT(a,b,c)	--注册监听
	print('--TT3',a,b,c)
end
function event.TT(a,b,c)--注册简化写法
	print('--TT4',a,b,c)
end
--事件触发
TT{a=1,b=2}
--TT2 1 2 0
--TT1 1 2 0
--TT3 1 2 0
--TT4 1 2 0
--事件触发 TT3被过滤掉
TT{a=5,b=6}
--TT2 5 6 0
--TT1 5 6 0
--TT4 5 6 0
--------------------------------
-- _event('define',_G,'event') --最简
-- define.TTT{}
-- event{}
-- function TTT()
-- end
-- TTT{}
--不占用_G
-- _event('define',nil,'event','when','call')--细分
-- define.TTTT{}
-- when{}
-- function event.TTTT()
-- end
-- call.TTTT{}
--------------------------------
error('event sample is on,comment switch to off')
--sample]]