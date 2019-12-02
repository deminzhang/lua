#ifndef _TIME_H_
#define _TIME_H_
#include "lua.h"
#include <math.h>
#ifdef _WIN32
#include <windows.h>
#include <time.h>
#else
#include <unistd.h>
#include <sys/time.h>
#endif
#include "LuaScript.h"

long long timeNow(double unit, int utc);
long long time_Now(double unit, int utc);
const char *time2date(long long time, int *y, int *M, int *d, int *h, int *m, int *s,
	int *msec, int *usec, int *wday, int *yday, int *mday);
long long date2time(int y, int M, int d, int h, int m, int s, int usec);
void int8todatestr(char *s, long long time);

int lua_utc(lua_State *L);
int lua_now(lua_State *L);
LUA_API void set__now();
int lua__now(lua_State *L);
int lua__time(lua_State *L);
int lua_timestr(lua_State *L);

#endif // !_TIME_H_
