#include "LuaTime.h"

#define IsLeapYear(year) (year % 4 == 0 && year % 100 != 0 || year % 400 == 0)

//#ifdef _WIN32
//const WORD moonday[] = { 0,31,28,31,30,31,30,31,31,30,31,30,31 };
//static double TimeFrom2000(SYSTEMTIME *st) //2000ÄêÆð
//{
//	WORD years = st->wYear - 2000;
//	WORD days = 365 * years;
//	days += (years + 1) / 4;
//	for (int m = 1; m<st->wMonth; m++)
//		days += moonday[m];
//	if (st->wMonth>2 && IsLeapYear(st->wYear))
//		days++;
//	days += st->wDay;
//	return (double)1000 * (86400 * days + 3600 * st->wHour + 60 * st->wMinute + st->wSecond) + (double)st->wMilliseconds;
//}
//#endif

static int timediff = 0;
static long long timelast = 0;
long long timeNow(double unit, int utc)
{
	long long us, uu;
#ifdef _WIN32
	static long long start = 0;
	if (!start)	{
		SYSTEMTIME st; FILETIME time;
		GetSystemTime(&st);
		SystemTimeToFileTime(&st, &time);
		//start = (long long)TimeFrom2000(&st) * 1000 - (long long)GetTickCount() * 1000;
		start = *(long long*)&time / 10 - 12591158400000000LL - (long long)GetTickCount() * 1000;
	}
	us = start + (long long)GetTickCount() * 1000;
#else
	struct timeval st;
	gettimeofday(&st, NULL);
	double d = st.tv_sec - 946684800LL;
	us = d * 1000000LL + st.tv_usec;
#endif
	if (us > timelast)
		timelast = us;
	else
		us = timelast;
	if (!utc)
		us += timediff * 1000000LL;
	uu = us / (unit * 1000000LL);
	return uu;
}
long long time_Now(double unit, int utc)
{
	long long us, uu;
		us = timelast;
	if (!utc)
		us += timediff * 1000000LL;
	uu = us / (unit * 1000000);
	return uu;
}
static void gettimezone()
{
#if _WIN32
	_get_timezone((long*)&timediff);
#else
	struct timeval tv;
	struct timezone tz;
	gettimeofday(&tv, &tz);
	timediff = -60 * tz.tz_minuteswest;
#endif
}

static int DATIME_D2000 = 365 * 2000 + 2003 / 4 - 2003 / 100 + 2003 / 400;
static int DATIME_DM[] = { 0, 0, 31, 31 + 28, 31 + 28 + 31, 31 + 28 + 31 + 30, 31 + 28 + 31 + 30 + 31, 31 + 28 + 31 + 30 + 31 + 30,
31 + 28 + 31 + 30 + 31 + 30 + 31, 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31, 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30,
31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31, 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30, 365, 365 + 31 };
static int DATIME_DMLEAP[] = { 0, 0, 31, 31 + 29, 31 + 29 + 31, 31 + 29 + 31 + 30, 31 + 29 + 31 + 30 + 31, 31 + 29 + 31 + 30 + 31 + 30,
31 + 29 + 31 + 30 + 31 + 30 + 31, 31 + 29 + 31 + 30 + 31 + 30 + 31 + 31, 31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 + 30,
31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31, 31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30, 366, 366 + 31 };
const char *time2date(long long time, int *y, int *M, int *d, int *h, int *m, int *s,
	int *msec, int *usec, int *wday, int *yday, int *mday)
{
	time += DATIME_D2000 * 86400000000LL;
	if (time < 0) return "year must >= 0";
	*usec = time % 1000000, *msec = time / 1000 % 1000;
	*s = time / 1000000 % 60, *m = time / 60000000LL % 60, *h = time / 3600000000LL % 24;
	int dtime = (int)(time / 86400000000LL);
	*wday = (dtime + 6) % 7;
	int year = dtime / 365, day;
	while ((day = 365 * year + (year + 3) / 4 - (year + 3) / 100 + (year + 3) / 400) > dtime)
		year--;
	dtime -= day;
	int *dm = year % 400 == 0 || year % 100 && year % 4 == 0 ? DATIME_DMLEAP : DATIME_DM;
	int mon = dtime / 28 + 1;
	while ((day = dm[mon]) > dtime)
		mon--;
	*d = dtime - day + 1, *M = mon, *y = year;
	*yday = dtime + 1, *mday = day + 1;
	return NULL;
}
long long date2time(int y, int M, int d, int h, int m, int s, int usec)
{
	d += 365 * y + (y + 3) / 4 - (y + 3) / 100 + (y + 3) / 400 - DATIME_D2000;
	d += (IsLeapYear(y) ? DATIME_DMLEAP : DATIME_DM)[M<1 ? 1 : M>12 ? 12 : M];
	long long time = (d - 1) * 86400000000LL + h * 3600000000LL + m * 60000000LL + s * 1000000LL + usec;
	return time;
}

int lua_utc(lua_State *L)
{
	double unit = 0.001f;
	if (lua_isnumber(L, 1))
		unit = lua_tonumber(L, 1);
	if (unit < 0.000001f)
		unit = 0.000001f;
	lua_pushnumber(L, timeNow(unit, 1));
	return 1;
}
int lua_now(lua_State *L)
{
	double unit = 0.001f;
	if (lua_isnumber(L, 1))
		unit = lua_tonumber(L, 1);
	if (unit < 0.000001f)
		unit = 0.000001f;
	gettimezone();
	lua_pushnumber(L, timeNow(unit, 0));
	return 1;
}
LUA_API void set__now()
{
	timeNow(0,1);
}
int lua__now(lua_State *L)
{
	double unit = 0.001f;
	if (lua_isnumber(L, 1))
		unit = lua_tonumber(L, 1);
	if (unit < 0.000001f)
		unit = 0.000001f;
	long long v = timelast / (unit * 1000000);
	lua_pushnumber(L, v);
	return 1;
}
void int8todatestr(char *s0, long long time)
{
	int y, M, d, h, m, s, msec, usec, wday, yday, mday;
	time2date(time, &y, &M, &d, &h, &m, &s, &msec, &usec, &wday, &yday, &mday);
	sprintf(s0, "%d-%02d-%02d %02d:%02d:%02d.%06d\0", y, M, d, h, m, s, usec);
}
int lua_timestr(lua_State *L) //"YYYY-DD-MM hh:mm:ss.mmmmmm";
{
	char s0[27];
#ifdef _WIN32
	SYSTEMTIME st;
	if(lua_isnumber(L, 1)) {
		long long time = (long long)lua_tonumber(L,1);
		int y, M, d, h, m, s, msec, usec, wday, yday, mday;
		time2date(time, &y, &M, &d, &h, &m, &s, &msec, &usec, &wday, &yday, &mday);
		st.wYear = y; st.wMonth = M; st.wDay = d;
		st.wHour = h; st.wMinute = m; st.wSecond = s;
		st.wMilliseconds = msec;
	}
	else
		GetSystemTime(&st);
	sprintf(s0, "%d-%02d-%02d %02d:%02d:%02d.%03d\0", st.wYear, st.wMonth, st.wDay, 
		st.wHour, st.wMinute, st.wSecond, st.wMilliseconds);
#else
	long long time;
	int y, M, d, h, m, s, msec, usec, wday, yday, mday;
	if (lua_isnumber(L, 1)) {
		time = (long long)lua_tonumber(L, 1);
	}
	else {
		gettimezone();
		time = timeNow(0, 0);
	}
	time2date(time, &y, &M, &d, &h, &m, &s, &msec, &usec, &wday, &yday, &mday);
	sprintf(s0, "%d-%02d-%02d %02d:%02d:%02d.%06d\0", y, M, d, h, m, s, usec);
#endif
	lua_pushstring(L, s0);
	return 1;
}
int lua__time(lua_State *L)
{
	int t1 = lua_type(L, 1);
	int t2 = lua_type(L, 2);
	long long time = 0;
	long long unit;
	if (t1 == LUA_TTABLE)
	{
		int y, M, d, h, m, s, msec, usec, wday, yday, mday;
		time = (long long)lua_tonumber(L, 2);
		unit = double2long(1000000 * luaL_optnumber(L, 3, 0.001));
		if(unit > 1)
			time = double2long((double)time * unit);
		time2date(time, &y, &M, &d, &h, &m, &s, &msec, &usec, &wday, &yday, &mday);
		lua_pushliteral(L, "year"),	lua_pushinteger(L, y), lua_rawset(L, 1);
		lua_pushliteral(L, "month"), lua_pushinteger(L, M), lua_rawset(L, 1);
		lua_pushliteral(L, "day"),	lua_pushinteger(L, d), lua_rawset(L, 1);
		lua_pushliteral(L, "hour"),	lua_pushinteger(L, h), lua_rawset(L, 1);
		lua_pushliteral(L, "min"),	lua_pushinteger(L, m), lua_rawset(L, 1);
		lua_pushliteral(L, "sec"),	lua_pushinteger(L, s), lua_rawset(L, 1);
		lua_pushliteral(L, "msec"),	lua_pushinteger(L, msec), lua_rawset(L, 1);
		lua_pushliteral(L, "usec"),	lua_pushinteger(L, usec), lua_rawset(L, 1);
		lua_pushliteral(L, "wday"),	lua_pushinteger(L, wday), lua_rawset(L, 1);
		lua_pushliteral(L, "yday"),	lua_pushinteger(L, yday), lua_rawset(L, 1);
		lua_pushliteral(L, "mday"),	lua_pushinteger(L, mday), lua_rawset(L, 1);
		lua_settop(L, 1);
	}
	else if (t1 == LUA_TNUMBER || t1 == LUA_TNIL)
	{
		if (t2 == LUA_TTABLE)
		{
			int y, M, d, h, m, s, usec;
			lua_pushstring(L, "year"), lua_rawget(L, 2), y = luaL_optinteger(L, -1, 0), lua_pop(L,1);
			lua_pushstring(L, "month"), lua_rawget(L, 2), M = luaL_optinteger(L, -1, 0), lua_pop(L, 1);
			lua_pushstring(L, "day"), lua_rawget(L, 2), d = luaL_optinteger(L, -1, 0), lua_pop(L, 1);
			lua_pushstring(L, "hour"), lua_rawget(L, 2), h = luaL_optinteger(L, -1, 0), lua_pop(L, 1);
			lua_pushstring(L, "min"), lua_rawget(L, 2), m = luaL_optinteger(L, -1, 0), lua_pop(L, 1);
			lua_pushstring(L, "sec"), lua_rawget(L, 2), s = luaL_optinteger(L, -1, 0), lua_pop(L, 1);
			lua_pushstring(L, "usec"), lua_rawget(L, 2);
			if (lua_isnumber(L, -1))
				usec = luaL_optinteger(L, -1, 0), lua_pop(L, 1);
			else
				lua_pushstring(L, "msec"), lua_rawget(L, 2), usec = luaL_optinteger(L, -1, 0) * 1000, lua_pop(L, 1);

			time = date2time(y, M, d, h, m, s, usec);
			unit = double2long(1000000 * luaL_optnumber(L, 1, 0.001));
			if (unit > 1)
				time = double2long((double)time * unit);
			lua_pushnumber(L, time);
		}
		else
			lua_errorEx(L, "#2 must table");
	}
	return 1;
}