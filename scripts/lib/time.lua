
--[[in C===================================================================
os.clock() TODO: 使用平台的clock() 计算方法可能不准
function _now(unit) --2000年起的时间
	error('in C') 
	unit默认0.001 return ms
	unit=1 return sec
	unit=0 return usec
end
function os.utc(unit) --2000年起的时间-时差
	error('in C') 
	unit默认0.001 return ms
	unit=1 return sec
	unit=0 return usec
end
function os.now(unit) --2000年起的时间
	error('in C') 
	unit默认0.001 return ms
	unit=1 return sec
	unit=0 return usec
end
function _time(datetable,time,unit) --time转datetable
	error('in C') 
	unit默认0.001 return datetable={year=,month=,day=,min=,sec=,msec=,usec=msec*1000+usec,wday=,yday=}
end
function _time(unit,datetable) --datetable转time
	error('in C') 
	unit默认0.001 return ms
end
function _timestr(time) --sql时间用. time默认取os.now(), _timestr(0)>>'2000-01-01 00:00:00.000000' 
	error('in C') 
end
--]]
--lua===================================================================
function formatDate(t, fmt)
	
	return
end
function sameDayS(sec1,sec2)
	return (sec1 - sec1%86400) == (sec2 - sec2%86400)
end
function sameDay(ms1,ms2)
	return (ms1 - ms1%86400000) == (ms2 - ms2%86400000)
end