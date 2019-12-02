#include "LuaZip.h"
#include "zlib.h"

//http://blog.sina.com.cn/s/blog_4c3591bd0100zzm6.html

// -1|2 str|data,zlibMode +1 data
 static int zip_deflate(lua_State *L)
 {
	 size_t n; const char *s = lua_toBytes(L, 1, &n);
	 size_t on = n+(n>>12)+(n>>14)+(n>>25)+13; // compressBound
	 lua_pushnil(L);
	 int top = lua_gettop(L) + 1;
	 char *os = lua_newBytes(L, on);
	 z_stream z;
	 memset(&z, 0, sizeof(z));
	 z.next_in = (Bytef*)s;
	 z.avail_in = n;
	 z.next_out = os;
	 z.avail_out = on;

	 //int err = deflateInit2_(&z, -1, 8, lua_toboolean(L, 2) ? 15 : -15, 8, 0, ZLIB_VERSION, sizeof(z));
	 int err = deflateInit2(&z, Z_DEFAULT_COMPRESSION, Z_DEFLATED, lua_toboolean(L, 2) ? 15 : -15, 8, Z_DEFAULT_STRATEGY);
	 if (err || (err = deflate(&z, 4), deflateEnd(&z), err) != 1) // Z_FINISH Z_STREAM_END
		 lua_errorEx(L, "lua_errorEx %d", err);
	 lua_setBytesLen(L, top, z.total_out);
	 return 1;
 }

void inflating(lua_State *L, const char *s, size_t n, size_t on, int raw)
{
	int top = lua_gettop(L) + 1;
	char *os = lua_newBytes(L, on);
	z_stream z;
	memset(&z, 0, sizeof(z));
	z.next_in = (Bytef*)s;
	z.avail_in = n;
	z.next_out = os;
	z.avail_out = on;

	int err = inflateInit2_(&z, raw ? -15 : 15, ZLIB_VERSION, sizeof(z));
	if (err || (err = inflate(&z, 4), inflateEnd(&z), err) != 1) // Z_FINISH Z_STREAM_END
		lua_errorEx(L, "lua_errorEx %d", err);
	lua_setBytesLen(L, top, z.total_out);
}
// -2|3 str|data,size,zlibMode +1 data
 static int zip_inflate(lua_State *L)
 {
	 size_t n; const char *s = lua_toBytes(L, 1, &n);
	 int on = luaL_checkint(L, 2);
	 if (on <= 0)
		 return lua_errorEx(L, "buffer overflow");
	 inflating(L, s, n, on, !lua_toboolean(L, 3));
	 return 1;
 }

// -1 {name=data} +1 zip
static int zip_zip(lua_State *L)
{
	if (!lua_istable(L, 1)) {
		lua_errorEx(L, "#1 must be a table value");
		return 0;
	}
	size_t en = 0, n = 0, c = 22, kn, vn;
	for (lua_pushnil(L); lua_next(L, 1); lua_pop(L, 1))
	{
		if (++en > 32767)
			lua_errorEx(L, "too many entry");
		lua_toBytes(L, -2, &kn), lua_toBytes(L, -1, &vn);
		if (kn > 32767)
			lua_errorEx(L, "name too long");
		n += 30+kn, n += vn+(vn>>12)+(vn>>14)+(vn>>25)+13, c += 46+kn;
	}
	int y, M, d, h, m, s, _;
	time2date(timeNow(0, 0), &y, &M, &d, &h, &m, &s, &_, &_, &_, &_, &_);
	int time = y << 25 | M << 21 | d << 16 | h << 11 | m << 5 | s >> 1;
	int top = lua_gettop(L)+1;	
	char *zip = lua_newBytes(L, n+c), *zn = zip+n, *z = zip, *zm; // top zip
	for (lua_pushnil(L); lua_next(L, 1); lua_pop(L, 1)) // top+1 key top+2 value
	{
		const char *k = lua_toBytes(L, top+1, &kn), *v = lua_toBytes(L, top+2, &vn);
		*(int*)z = 0x04034b50;
		*(short*)(z+4) = 0x14, *(short*)(z+6) = 0, *(short*)(z+8) = 8;
		*(int*)(z+10) = time, *(int*)(z+14) = crc32(crc32(0, NULL, 0), v, vn);
		*(int*)(z+22) = vn, *(short*)(z+26) = (short)kn, *(short*)(z+28) = 0;
		memcpy(z+30, k, kn);
		char *zv = z+30+kn;
		z_stream strm;
		memset(&strm, 0, sizeof(strm));
		strm.next_in = (Bytef*)v;
		strm.avail_in = vn;
		strm.next_out = zv;
		strm.avail_out = zv < zn ? zn - zv : 0;
		//int err = deflateInit2_(&strm, -1, 8, -15, 8, 0, ZLIB_VERSION, sizeof(strm));
		int err = deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, -15, 8, Z_DEFAULT_STRATEGY);
		if (err || (err = deflate(&strm, 4), deflateEnd(&strm), err) != 1) // Z_FINISH Z_STREAM_END
			lua_errorEx(L, "%s lua_errorEx %d", k, err);
		vn = strm.total_out;
		*(int*)(z + 18) = vn;

		z = zv+vn;
	}
	zn = zm = z;

	for (z = zip; z < zn; )
	{
		*(int*)zm = 0x02014b50, *(short*)(zm+4) = 0x14;
		memcpy(zm+6, z+4, 26);
		*(short*)(zm+32) = 0, *(short*)(zm+34) = 0, *(short*)(zm+36) = 0;
		*(int*)(zm+38) = 0, *(int*)(zm+42) = z-zip;
		int kn = *(short*)(z+26);
		memcpy(zm+46, z+30, kn);
		z += 30+kn+*(int*)(z+18), zm += 46+kn;
	}
	*(int*)zm = 0x06054b50, *(short*)(zm+4) = 0, *(short*)(zm+6) = 0;
	*(short*)(zm+8) = *(short*)(zm+10) = (short)en;
	*(int*)(zm+12) = zm-zn, *(int*)(zm+16) = zn-zip, *(short*)(zm+20) = 0;
	zm += 22;
	lua_setBytesLen(L, top, zm - zip);
	lua_pushvalue(L, top);
	return 1;
}

// -1 zip +1 {name=data}
static int zip_unzip(lua_State *L)
{
	size_t nn; const char *ss = lua_toBytes(L, 1, &nn), *s = ss;
	if (nn <= 30)
		return lua_errorEx(L, "bad zip");
	int top = lua_gettop(L)+1;
	lua_newtable(L); // top unzip
	for (ss += nn-30; s < ss && *(int*)s != 0x02014b50; )
	{
		short kind = *(short*)(s+8);
		if (*(int*)s != 0x04034b50 || *(short*)(s+6) & 0x80 || kind != 8 && kind != 0)
			return lua_errorEx(L, "unsupported zip");
		int crc = *(int*)(s+14);
		//18:4压缩后大小 ,22:4非压缩大小
		unsigned n = *(unsigned*)(s+18), on = *(unsigned*)(s+22); //x64
		size_t name = *(short*)(s+26), extra = *(short*)(s+28);
		if ((s += 30 + name + extra) >= ss - n) {
			printf(s);
			printf(ss - n);
			return lua_errorEx(L, "bad zip");
		}
		lua_pushlstring(L, s-name-extra, name); // top+1 name
		if (kind == 0 && n != on)
			return lua_errorEx(L, "bad zip %s", lua_tostring(L, top+1));
		if (kind == 8)
			inflating(L, s, n, on, 1); // top+2 data
		else
			memcpy(lua_newBytes(L, n), s, n); // top+2 data
		if (crc32(crc32(0, NULL, 0), (char*)lua_touserdata(L, top+2), on) != crc)
			return lua_errorEx(L, "bad crc %s", lua_tostring(L, top+1));
		lua_rawset(L, top);
		s += n;
	}
	lua_pushvalue(L, top);
	return 1;
}

static int str_crc32(lua_State *L)
{
	size_t n;
	const char *s = lua_toBytes(L, 1, &n);
	int len = luaL_optinteger(L, 2, n);
	int code = luaL_optinteger(L, 3, 0);
	if (len > n || len < 1)
		len = n;
	unsigned char c[4];
	*(unsigned long*)(&c) = crc32(code, s, len);
	char ss[9];
	sprintf(ss, "%02x%02x%02x%02x\0",
		c[3], c[2], c[1], c[0]);
	lua_pushstring(L, ss);
	return 1;
}

void luaopen_zip(lua_State *L)
{
	lua_register(L, "_deflate", zip_deflate);
	lua_register(L, "_inflate", zip_inflate);
	lua_register(L, "_zip", zip_zip);
	lua_register(L, "_unzip", zip_unzip);
	//lua_register(L, "_crc32", str_crc32);
	lua_getglobal(L, "string");
	lua_pushcfunction(L, str_crc32);
	lua_setfield(L, -2, "crc32");
	lua_pop(L, 1);
}
