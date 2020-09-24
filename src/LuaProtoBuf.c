
#include "LuaProtoBuf.h"

//https://www.cnblogs.com/jadeshu/p/10663696.html
//https://cloud.tencent.com/developer/article/1520442
//https://solicomo.com/network-dev/protobuf-proto3-vs-proto2.html

#define WIRE_VARINT 0	//变长整型 int32, int64, uint32, uint64, sint32, sint64, bool, enum
#define WIRE_FIXED64 1	//固定8字节 fixed64, sfixed64, double
#define WIRE_BYTES 2	//需显式告知长度 string, bytes, 嵌套类型（embedded messages），repeated字段
#define WIRE_START 3	//
#define WIRE_END 4		//
#define WIRE_FIXED32 5	//固定4字节 fixed32, sfixed32, float

#define PBint32 1
#define PBint64 2
#define PBuint32 3
#define PBuint64 4
#define PBsint32 5
#define PBzigzag32 5
#define PBsint64 6
#define PBzigzag64 6
#define PBbool 7
#define PBenum 8

#define PBfixed64 9
#define PBsfixed64 10
#define PBdouble 11

#define PBstring 12
#define PBbytes 13

#define PBfixed32 15
#define PBsfixed32 16
#define PBfloat 17
#define PBmessage 18
#define PBmap 19

#define PB_SIG 1 //singular proto3
#define PB_OPT 1 //optional proto2
#define PB_REP 2 //repeated
#define PB_REQ 3 //required proto2

#define MAX_CODE_LEN 0xfff0		//max len of code buffer 最大编码长度

#define META_NAME "[PROTOBUF]"
#define GLOBAL_LIB_NAME "proto"

static int lua_protoc(lua_State* L)
{
	//protoc("protos",files)
	return 0;
}

static unsigned char SizeVarint(size_t x) {
	if (x < 1 << 7)
		return 1;
	else if (x < 1 << 14)
		return 2;
	else if (x < 1 << 21)
		return 3;
	else if (x < 1 << 28)
		return 4;
	else if (x < 1LL << 35)
		return 5;
	else if (x < 1LL << 42)
		return 6;
	else if (x < 1LL << 49)
		return 7;
	else if (x < 1LL << 56)
		return 8;
	else if (x < 1LL << 63)
		return 9;
	return 10;
}

// This is the format for the
// int32, int64, uint32, uint64, bool, and enum
// protocol buffer types.
static void EncodeVarint(size_t x, char* buf, size_t* p)
{
	while (x >= 1 << 7) {
		buf[(*p)++] = (unsigned char)(x & 0x7f | 0x80);
		x >>= 7;
	}
	buf[(*p)++] = (unsigned char)x;
}

static void EncodeFieldType(int fn, char wt, char* buf, size_t* p)
{
	if (fn < 16)
		buf[(*p)++] = (fn << 3) + wt;
	else {
		buf[(*p)++] = (fn << 3) | 0x80 + wt;
		EncodeVarint(fn >> 4, buf, p);
	}
}
// This is the format used for the sint64 protocol buffer type.
static void EncodeZigzag64(size_t x, char* buf, size_t* p)
{
	EncodeVarint((size_t)((x << 1) ^ (size_t)((long long)x >> 63)),buf,p);
}
// This is the format used for the sint32 protocol buffer type.
static void EncodeZigzag32(size_t x, char* buf, size_t * p)
{
	EncodeVarint((size_t)(((unsigned)x << 1) ^ (unsigned)(((int)x >> 31))), buf, p);
}
// This is the format used for the proto2 string type.
static void EncodeString(int fn, char* s, char* buf, size_t* p)
{
	size_t len = sizeof(s);
	EncodeFieldType(fn, WIRE_BYTES, buf, p);
	EncodeVarint(len, buf, p);
	memcpy(buf + *p, s, len);
	(*p) += len;
}

static void EncodeBytes(lua_State* L, int idx, int fn, char* buf, size_t* p)
{
	size_t len; const char* s = lua_toBytes(L, idx, &len);
	if (len == 0)return;
	EncodeFieldType(fn, WIRE_BYTES, buf, p);
	EncodeVarint(len, buf, p);
	memcpy(buf + *p, s, len);
	(*p) += len;
}
static void EncodeField(lua_State* L, int idx, int fn, int tp, char* buf, size_t* p)
{
	switch (tp) {
	case PBbool: {
		int v = lua_toboolean(L, idx);
		EncodeFieldType(fn, WIRE_VARINT, buf, p);
		EncodeVarint(v, buf, p);
		break;
	}
	case PBint64:
	case PBuint64: {
		double V = lua_tonumber(L, idx);
		long long v = (long long)V;
		if (v != (long long)v)
			lua_errorEx(L, "%d not intX", v);
		EncodeFieldType(fn, WIRE_VARINT, buf, p);
		EncodeVarint(v, buf, p);
		break;
	}
	case PBint32:
	case PBuint32:
	case PBenum: {
		double V = lua_tonumber(L, idx);
		long long v = (long long)V;
		if (v != (long long)v)
			lua_errorEx(L, "%d not intX", v);
		EncodeFieldType(fn, WIRE_VARINT, buf, p);
		EncodeVarint(v, buf, p);
		break;
	}
	case PBsint32: { //PBzigzag32
		double V = lua_tonumber(L, idx);
		long long v = (long long)V;
		if (v != (int)v)
			lua_errorEx(L, "%f out range of sint32", V);
		EncodeFieldType(fn, WIRE_VARINT, buf, p);
		EncodeZigzag32((size_t)v, buf, p);
		break;
	}
	case PBsint64: {//PBzigzag64
		double V = lua_tonumber(L, idx);
		long long v = (long long)V;
		if (v != (long long)v)
			lua_errorEx(L, "%d not sint64", v);
		EncodeFieldType(fn, WIRE_VARINT, buf, p);
		EncodeZigzag64((size_t)v, buf, p);
		break;
	}
	case PBfixed64:
	case PBsfixed64: {
		double V = lua_tonumber(L, idx);
		long long v = (long long)V;
		if (v != (long long)v)
			lua_errorEx(L, "%d not int or long", v);
		EncodeFieldType(fn, WIRE_FIXED64, buf, p);
		W64(buf + *p, v), * p += 8;
		break;
	}
	case PBdouble: {
		EncodeFieldType(fn, WIRE_FIXED64, buf, p);
		double v = lua_tonumber(L, idx);
		WDb(buf + *p, v), * p += sizeof(double);
		break;
	}
	case PBfixed32:
	case PBsfixed32: {
		double V = lua_tonumber(L, idx);
		long long v = (long long)V;
		if (v != (int)v)
			lua_errorEx(L, "%f out range of FIXED32", V);
		EncodeFieldType(fn, WIRE_FIXED32, buf, p);
		W32(buf + *p, v), *p += 4;
		break;
	}
	case PBfloat: {
		double V = lua_tonumber(L, idx);
		float v = (float)V;
		EncodeFieldType(fn, WIRE_FIXED32, buf, p);
		WFl(buf + *p, v), *p += 4;
		break;
	}
	case PBstring: {
		size_t len; const char* s = lua_tolstring(L, idx, &len);
		EncodeString(fn, s, buf, p);
		break;
	}
	case PBbytes: {
		EncodeBytes(L, idx, fn, buf, p);
		break;
	}
	case PBmap: {
		lua_errorEx(L, "unsupported map in map");
		break;
	}
	}
}

static size_t encode_tab(lua_State* L, int idx, char *buf)
{
	size_t p = 0;
	if (!lua_istable(L, idx))
		lua_errorEx(L, "#1 must table for duplicate");
	lua_getmetatable(L, idx);

	lua_getfield(L, -1, "message"); //meta.fields
	lua_getfield(L, -2, "syntax");
	const char* syntax = lua_tostring(L, -1);
	int proto2 = syntax == NULL || strcmp(syntax, "proto3");
	lua_pop(L, 1);
	int top = lua_gettop(L);
	for (int i = 1;; i++, lua_settop(L, top)) {
		lua_rawgeti(L, top, i);//field=fields[i]
		if (lua_isnil(L, -1)) break;

		lua_rawgeti(L, top + 1, 1);//field[1] fieldlab
		int lab = lua_tointeger(L, -1);
		lua_pop(L, 1);

		lua_rawgeti(L, top + 1, 2);//field[2] TP
		int tp = lua_tointeger(L, -1);
		int typeIdx = lua_gettop(L);
		if (lua_istable(L, -1)) {
			lua_getfield(L, -1, "pbtype");
			tp = lua_tointeger(L, -1);
			lua_pop(L, 1);
		}

		lua_rawgeti(L, top + 1, 4);//field[4] FN
		int fn = lua_tointeger(L, -1);
		lua_pop(L, 1);

		lua_getfield(L, top + 1, "packed");
		int packed = lua_isnil(L, -1) ? (proto2 ? 0 : 1) : lua_toboolean(L, -1);
		lua_pop(L, 1);

		lua_rawgeti(L, top + 1, 3); //field[3] name
		const char* name = lua_tostring(L, -1);
		lua_gettable(L, idx); //t[k]

		int vtp = lua_type(L, -1);
		//check
		switch (lab) {
		case PB_REQ: //if protobuf2
			if (vtp == LUA_TNIL)
				lua_errorEx(L, "%s required, got nil", name);
			break;
		case PB_REP:
			if (vtp == LUA_TNIL) continue;
			if (vtp != LUA_TTABLE)
				lua_errorEx(L, "%s repeated table required, got %s", name, lua_typename(L, vtp));
			break;
		case PB_OPT:
			if (vtp == LUA_TNIL)continue;
		}
		//encodeval
		switch (tp) {
		case PBbool: {
			if (lab == PB_REP) {
				int size = lua_objlen(L, -1);
				if (packed) {
					EncodeFieldType(fn, WIRE_BYTES, buf, &p);
					EncodeVarint(size * sizeof(char), buf, &p); //protobuf2[packed=true] or protobuf3
					for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						int v = lua_toboolean(L, -1);
						EncodeVarint(v, buf, &p);
					}
				}
				else {
					for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						int v = lua_toboolean(L, -1);
						EncodeFieldType(fn, WIRE_VARINT, buf, &p);
						EncodeVarint(v, buf, &p);
					}
				}
			}
			else {
				int v = lua_toboolean(L, -1);
				EncodeFieldType(fn, WIRE_VARINT, buf, &p);
				EncodeVarint(v, buf, &p);
			}
			break;
		}
		case PBint64:
		case PBuint64: {
			//TODO check value in lua_getfield(L, top + 1, "value");
			if (lab == PB_REP) {
				int len = lua_objlen(L, -1);
				if (packed) {
					EncodeFieldType(fn, WIRE_BYTES, buf, &p);
					int Len = 0;
					for (int j = 1; j <= len; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						double V = lua_tonumber(L, -1);
						Len += SizeVarint((size_t)V);
					}
					EncodeVarint(Len, buf, &p);
					for (int j = 1; j <= len; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						double V = lua_tonumber(L, -1);
						long long v = (long long)V;
						if (v != (long long)v)
							lua_errorEx(L, "%d not intX", v);

						EncodeVarint(v, buf, &p);
					}
				}
				else {
					for (int j = 1; j <= len; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						double V = lua_tonumber(L, -1);
						long long v = (long long)V;
						if (v != (long long)v)
							lua_errorEx(L, "%d not intX", v);
						EncodeFieldType(fn, WIRE_VARINT, buf, &p);

						EncodeVarint(v, buf, &p);
					}
				}
			}
			else {
				double V = lua_tonumber(L, -1);
				long long v = (long long)V;
				if (v != (long long)v)
					lua_errorEx(L, "%d not intX", v);
				EncodeFieldType(fn, WIRE_VARINT, buf, &p);

				EncodeVarint(v, buf, &p);
			}
			break;
		}
		case PBint32:
		case PBuint32:
		case PBenum:  
		{
			if (lab == PB_REP) {
				int len = lua_objlen(L, -1);
				if (packed) {
					EncodeFieldType(fn, WIRE_BYTES, buf, &p);
					int Len = 0;
					for (int j = 1; j <= len; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						double V = lua_tonumber(L, -1);
						Len += SizeVarint((size_t)V);
					}
					EncodeVarint(Len, buf, &p);
					for (int j = 1; j <= len; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						double V = lua_tonumber(L, -1);
						long long v = (long long)V;
						if (v != (long long)v)
							lua_errorEx(L, "%d not intX", v);

						EncodeVarint(v, buf, &p);
					}
				}
				else {
					for (int j = 1; j <= len; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						double V = lua_tonumber(L, -1);
						long long v = (long long)V;
						if (v != (long long)v)
							lua_errorEx(L, "%d not intX", v);
						EncodeFieldType(fn, WIRE_VARINT, buf, &p);

						EncodeVarint(v, buf, &p);
					}
				}
			}
			else {
				double V = lua_tonumber(L, -1);
				long long v = (long long)V;
				if (v != (long long)v)
					lua_errorEx(L, "%d not intX", v);
				EncodeFieldType(fn, WIRE_VARINT, buf, &p);

				EncodeVarint(v, buf, &p);
			}
			break;
		}
		case PBsint32: { //PBzigzag32
			if (lab == PB_REP) {
				int size = lua_objlen(L, -1);
				if (packed) {
					EncodeFieldType(fn, WIRE_BYTES, buf, &p);
					EncodeVarint(size * sizeof(int), buf, &p); //protobuf2[packed=true] or protobuf3
					for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						double V = lua_tonumber(L, -1);
						long long v = (long long)V;
						if (v != (int)v)
							lua_errorEx(L, "%f out range of sint32", V);
						EncodeZigzag32((size_t)v, buf, &p);
					}
				}
				else {
					for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						double V = lua_tonumber(L, -1);
						long long v = (long long)V;
						if (v != (int)v)
							lua_errorEx(L, "%f out range of sint32", V);
						EncodeFieldType(fn, WIRE_VARINT, buf, &p);
						EncodeZigzag32((size_t)v, buf, &p);
					}
				}
			}
			else {
				double V = lua_tonumber(L, -1);
				long long v = (long long)V;
				if (v != (int)v)
					lua_errorEx(L, "%f out range of sint32", V);
				EncodeFieldType(fn, WIRE_VARINT, buf, &p);
				EncodeZigzag32((size_t)v, buf, &p);
			}
			break;
		}
		case PBsint64: {//PBzigzag64
			if (lab == PB_REP) {
				int size = lua_objlen(L, -1);
				if (packed) {
					EncodeFieldType(fn, WIRE_BYTES, buf, &p);
					EncodeVarint(size * sizeof(long long), buf, &p); //protobuf2[packed=true] or protobuf3
					for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						double V = lua_tonumber(L, -1);
						long long v = (long long)V;
						if (v != (long long)v)
							lua_errorEx(L, "%d not sint64", v);
						EncodeZigzag64((size_t)v, buf, &p);
					}
				}
				else {
					for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						double V = lua_tonumber(L, -1);
						long long v = (long long)V;
						if (v != (long long)v)
							lua_errorEx(L, "%d not sint64", v);
						EncodeFieldType(fn, WIRE_VARINT, buf, &p);
						EncodeZigzag64((size_t)v, buf, &p);
					}
				}
			}
			else {
				double V = lua_tonumber(L, -1);
				long long v = (long long)V;
				if (v != (long long)v)
					lua_errorEx(L, "%d not sint64", v);
				EncodeFieldType(fn, WIRE_VARINT, buf, &p);
				EncodeZigzag64((size_t)v, buf, &p);
			}
			break;
		}
		case PBfixed64:
		case PBsfixed64: {
			if (lab == PB_REP) {
				int size = lua_objlen(L, -1);
				if (packed) {
					EncodeFieldType(fn, WIRE_BYTES, buf, &p);
					EncodeVarint(size * sizeof(long long), buf, &p); //protobuf2[packed=true] or protobuf3
					for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						double V = lua_tonumber(L, -1);
						long long v = (long long)V;
						if (v != (long long)v)
							lua_errorEx(L, "%d not FIXED64", v);
						W64(buf + p, v), p += 8;
					}
				}
				else {
					for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						double V = lua_tonumber(L, -1);
						long long v = (long long)V;
						if (v != (long long)v)
							lua_errorEx(L, "%d not FIXED64", v);
						EncodeFieldType(fn, WIRE_FIXED64, buf, &p);
						W64(buf + p, v), p += 8;
					}
				}
			}
			else {
				double V = lua_tonumber(L, -1);
				long long v = (long long)V;
				if (v != (long long)v)
					lua_errorEx(L, "%d not int or long", v);
				EncodeFieldType(fn, WIRE_FIXED64, buf, &p);
				W64(buf + p, v), p += 8;
			}
			break;
		}
		case PBdouble: {
			if (lab == PB_REP) {
				int size = lua_objlen(L, -1);
				if (packed) {
					EncodeFieldType(fn, WIRE_BYTES, buf, &p);
					EncodeVarint(size * sizeof(double), buf, &p); //protobuf2[packed=true] or protobuf3
					for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						double V = lua_tonumber(L, -1);
						*(double*)(buf + p) = V;
						p += sizeof(double);
					}
				}
				else {
					for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						EncodeFieldType(fn, WIRE_FIXED64, buf, &p);
						double V = lua_tonumber(L, -1);
						*(double*)(buf + p) = V;
						p += sizeof(double);
					}
				}
			}
			else {
				EncodeFieldType(fn, WIRE_FIXED64, buf, &p);
				double v = lua_tonumber(L, -1);
				WDb(buf + p, v), p += sizeof(double);
			}
			break;
		}
		case PBfixed32:
		case PBsfixed32: {
			if (lab == PB_REP) {
				int size = lua_objlen(L, -1);
				if (packed) {
					EncodeFieldType(fn, WIRE_BYTES, buf, &p);
					EncodeVarint(size * sizeof(int), buf, &p); //protobuf2[packed=true] or protobuf3
					for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						double V = lua_tonumber(L, -1);
						long long v = (long long)V;
						if (v != (int)v)
							lua_errorEx(L, "%f out range of FIXED32", V);
						W32(buf + p, v), p += 4;
					}
				}
				else {
					for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						double V = lua_tonumber(L, -1);
						long long v = (long long)V;
						if (v != (int)v)
							lua_errorEx(L, "%f out range of FIXED32", V);
						EncodeFieldType(fn, WIRE_FIXED32, buf, &p);
						W32(buf + p, v), p += 4;
					}
				}
			}
			else {
				double V = lua_tonumber(L, -1);
				long long v = (long long)V;
				if (v != (int)v)
					lua_errorEx(L, "%f out range of FIXED32", V);
				EncodeFieldType(fn, WIRE_FIXED32, buf, &p);
				W32(buf + p, v), p += 4;
			}
			break;
		}
		case PBfloat: {
			if (lab == PB_REP) {
				int size = lua_objlen(L, -1);
				if (packed) {
					EncodeFieldType(fn, WIRE_BYTES, buf, &p);
					EncodeVarint(size * sizeof(float), buf, &p);
					for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						double V = lua_tonumber(L, -1);
						*(float*)(buf + p) = V;
						p += sizeof(float);
					}
				}
				else {
					for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						EncodeFieldType(fn, WIRE_FIXED32, buf, &p);
						double V = lua_tonumber(L, -1);
						*(float*)(buf + p) = V;
						p += sizeof(float);
					}
				}
			}
			else {
				double V = lua_tonumber(L, -1);
				float v = (float)V;
				EncodeFieldType(fn, WIRE_FIXED32, buf, &p);
				WFl(buf + p, v), p += 4;
			}
			break;
		}
		case PBstring:  {
			if (lab == PB_REP) {
				int size = lua_objlen(L, -1);
				for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
					lua_rawgeti(L, -1, j);
					size_t len; const char* s = lua_tolstring(L, -1, &len);
					EncodeString(fn, s, buf, &p);
				}
			}
			else {
				size_t len; const char* s = lua_tolstring(L, -1, &len);
				EncodeString(fn, s, buf, &p);
			}
			break;
		}
		case PBbytes: {
			EncodeBytes(L, -1, fn, buf, &p);
			break;
		}
		case PBmap: {
			lua_rawgeti(L, typeIdx, 1);
			int tpk = lua_tointeger(L, -1);
			lua_rawgeti(L, typeIdx, 2);
			int tpv = lua_tointeger(L, -1);
			lua_pop(L, 2);
			for (lua_pushnil(L); lua_next(L, typeIdx); lua_pop(L, 1)) {
				EncodeFieldType(fn, WIRE_BYTES, buf, &p);
				size_t old = p;
				EncodeVarint(0, buf, &p);
				EncodeField(L, -2, 1, tpk, buf, &p);
				EncodeField(L, -1, 2, tpv, buf, &p);
				size_t len = p - old - 1;
				unsigned char lenSize = SizeVarint(len);
				if(lenSize == 1)
					buf[old] = (unsigned char)len;
				else { //lenSize大概率是1 不是1时回退重来一次 或 memcpy后移
					p = old;
					EncodeVarint(len, buf, &p);
					EncodeField(L, -2, 1, tpk, buf, &p);
					EncodeField(L, -1, 2, tpv, buf, &p);
				}
			}
			break;
		}
		case PBmessage: {
			if (lab == PB_REP) {
				int size = lua_objlen(L, -1);
				for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
					lua_rawgeti(L, -1, j);
					lua_getfield(L, -1, "encode");
					lua_insert(L, -2);
					lua_call(L, 1, 1);
					EncodeBytes(L, -1, fn, buf, &p);
				}
				break;
			}
			else {
				if (vtp == LUA_TTABLE) {
					lua_getfield(L, -1, "encode");
					int f = lua_isnil(L, -1);
					lua_insert(L, -2);
					lua_call(L, 1, 1);
					EncodeBytes(L, -1, fn, buf, &p);
					break;
				}
			}
		}
		default:
ERR_ENCODE:
			lua_errorEx(L, "unsupported encode feild %s", name);
			break;
		}
	}
	return p;
}
static int lua_proto_encode(lua_State* L)
{
	if (lua_isnone(L, 1))
		lua_errorEx(L, "[C]invalid #1 no data to encode");

	int top = lua_gettop(L);
	//char buf[MAX_CODE_LEN + 1];
	char *buf = (char*)malloc(MAX_CODE_LEN + 1);
	if (buf == NULL)
		lua_errorEx(L, "[C]lua_proto_encode not enough memory");

	size_t len = encode_tab(L, 1, buf);
	if (len > MAX_CODE_LEN) 
		lua_errorEx(L, "protobuf encode tolong %d", len);
	
	if (len == 0)return 0;
	char* buff1 = (char*)lua_newBytes(L, len);
	memcpy(buff1, buf, len);
	free(buf);
	return 1;
}

/**decode********************************************************/

static size_t DecodeVarint(lua_State *L, const char* buf, size_t* p) {

	size_t x = (size_t)(unsigned char)buf[(*p)++];
	if (x < 0x80)
		return x;

	x -= 0x80;
	size_t b = (size_t)(unsigned char)buf[(*p)++];
	x += b << 7;
	if (b < 0x80)
		return x;

	x -= 0x80 << 7;
	b = (size_t)(unsigned char)buf[(*p)++];
	x += b << 14;
	if (b < 0x80)
		return x;

	x -= 0x80 << 14;
	b = (size_t)(unsigned char)buf[(*p)++];
	x += b << 21;
	if (b < 0x80)
		return x;

	x -= 0x80 << 21;
	b = (size_t)(unsigned char)buf[(*p)++];
	x += b << 28;
	if (b < 0x80)
		return x;

	x -= 0x80LL << 28;
	b = (size_t)(unsigned char)buf[(*p)++];
	x += b << 35;
	if (b < 0x80)
		return x;

	x -= 0x80LL << 35;
	b = (size_t)(unsigned char)buf[(*p)++];
	x += b << 42;
	if (b < 0x80)
		return x;
	
	x -= 0x80LL << 42;
	b = (size_t)(unsigned char)buf[(*p)++];
	x += b << 49;
	if (b < 0x80)
		return x;
	
	x -= 0x80LL << 49;
	b = (size_t)(unsigned char)buf[(*p)++];
	x += b << 56;
	if (b < 0x80)
		return x;

	x -= 0x80LL << 56;
	b = (size_t)(unsigned char)buf[(*p)++];
	x += b << 63;
	if (b < 0x80) {
		return x;
	}

	lua_errorEx(L, "ErrOverflow");
	return 0;
}

// This is the format used for the sint64 protocol buffer type.
static size_t DecodeZigzag64(lua_State* L, const char* s, size_t* p)
{
	size_t x = DecodeVarint(L, s, p);
	x = (x >> 1) ^ (size_t)(((long long)(x & 1) << 63) >> 63);
	return x;
}

// This is the format used for the sint32 protocol buffer type.
static size_t DecodeZigzag32(lua_State* L, const char* s, size_t* p) 
{
	size_t x = DecodeVarint(L, s, p);
	x = (size_t)(((unsigned)(x) >> 1) ^ (unsigned)(((int)(x & 1) << 31) >> 31));
	return x;
}

static void DecodeFieldType(const char* buf, size_t* p, int *fn, int*wt)
{
	unsigned char c = buf[(*p)++];
	*wt = c & 0x7;
	if (c >> 7) {
		*fn = 0;
		unsigned char h = buf[(*p)++];
		char* s = (char*)fn;
		s[0] = (c & 0x78) >> 3 | (h & 0xf)<<4 ;
		s[1] = h >> 4;
	}
	else
		*fn = (c & 0x78) >> 3;
}

static void DecodePushFieldVal(lua_State* L, int tp, const char *buf, size_t*p)
{
	size_t V;
	switch (tp) {
	case PBbool: {
		int b = (unsigned)buf[(*p)++];
		lua_pushboolean(L, b);
		break;
	}
	case PBint32: {
		V = DecodeVarint(L, buf, p);
		lua_pushnumber(L, (int)V);
		break;
	}
	case PBint64: {
		V = DecodeVarint(L, buf, p);
		lua_pushnumber(L, (long long)V);
		break;
	}
	case PBuint32: {
		V = DecodeVarint(L, buf, p);
		lua_pushnumber(L, (unsigned)V);
		break;
	}
	case PBuint64: 
	case PBenum: 
	{
		V = DecodeVarint(L, buf, p);
		lua_pushnumber(L, V);
		break;
	}
	case PBsint32:
		V = DecodeZigzag32(L, buf, p);
		lua_pushnumber(L, (int)V);
		break;
	case PBsint64: {
		V = DecodeZigzag64(L, buf, p);
		lua_pushnumber(L, (long long)V);
		break;
	}
	case PBfixed32:
	case PBsfixed32: {
		int v = R32(buf + *p);
		lua_pushnumber(L, v);
		*p += sizeof(int);
		break;
	}
	case PBfixed64:
	case PBsfixed64: {
		long long v = R64(buf + *p);
		lua_pushnumber(L, v);
		*p += sizeof(long long);
		break;
	}
	case PBdouble: {
		double v = RDb(buf + *p);
		lua_pushnumber(L, v);
		*p += sizeof(double);
		break;
	}
	case PBfloat: { //encode时double转float, decode时float tonumber会有损失精度
		float v = RFl(buf + *p);
		lua_pushnumber(L, v);
		*p += sizeof(float);
		break;
	}
	case PBstring: {
		V = DecodeVarint(L, buf, p);
		char* ss = buf + *p;
		lua_pushlstring(L, buf + *p, V);
		*p += V;
		break;
	}
	case PBbytes: {
		V = DecodeVarint(L, buf, p);
		char* ub = lua_newBytes(L, V);
		memcpy(ub, buf + *p, V);
		*p += V;
		break;
	}
	case PBmap: {
		//in lua_proto_decode
		break;
	}
	case PBmessage: {
		V = DecodeVarint(L, buf, p);
		lua_rawgeti(L, 5, 2);
		lua_getfield(L, -1, "decode");
		lua_replace(L, -2);
		char* u = lua_newBytes(L, V); //TODO lua_pushlightuserdata(L, val);
		memcpy(u, buf + *p, V);
		lua_call(L, 1, 1);
		*p += V;
		break;
	}
	default:
		lua_errorEx(L, "unknown proto type field: %s", lua_tostring(L, 6));
		break;
	}
}

static int lua_proto_decode(lua_State* L)
{
	//L1: buf
	size_t len;
	const char* buf = lua_toBytes(L, 1, &len);
	//L2: ret table
	//L3: metatable
	lua_getmetatable(L, 2);
	//L4: metatable.fields
	lua_getfield(L, -1, "fields");

	lua_getfield(L, -2, "syntax");
	const char* syntax = lua_tostring(L, -1);
	int proto2 = syntax == NULL || strcmp(syntax, "proto3");
	lua_pop(L, 1);

	int fn = 0;	//feild number
	int wt;	//wire type
	int top = lua_gettop(L);
	for (size_t p = 0; p < len; lua_settop(L, top)) {
		DecodeFieldType(buf, &p, &fn, &wt);
		lua_rawgeti(L, 4, fn);//L5 field=fields[i]
		if (lua_isnil(L, -1))
			lua_errorEx(L, "undefined field idx: %d", fn);

		lua_rawgeti(L, 5, 1);//field[1] fieldlab
		int lab = lua_tointeger(L, -1);
		lua_pop(L, 1);

		lua_rawgeti(L, 5, 2);//field[2] TP
		int tp = lua_tointeger(L, -1);
		int typeIdx = lua_gettop(L);
		if (lua_istable(L, -1)) {
			lua_getfield(L, -1, "pbtype");
			tp = lua_tointeger(L, -1);
			lua_pop(L, 1);
		}

		lua_getfield(L, 5, "packed");
		int packed = lua_isnil(L, -1) ? (proto2 ? 0 : 1) : lua_toboolean(L, -1);
		
		lua_pop(L, 1);

		lua_rawgeti(L, 5, 3); //L 6 field[3] name
		if (lab == PB_REP) {
			//TODO  if (primitive[tp] and packed)
			if (packed) {
				int plen = DecodeVarint(L, buf, &p);
				size_t oldp = p;
				lua_createtable(L, plen, 0); //new arr
				for (int i = 1; p - oldp < plen; i++) {
					DecodePushFieldVal(L, tp, buf, &p);
					lua_rawseti(L, -2, i); //arr[++]=val
				}
				lua_settable(L, 2); //t[name]=arr
			}
			else {
				lua_gettable(L, 2);
				if (!lua_istable(L, -1)) {
					lua_rawgeti(L, 5, 3);

					lua_createtable(L, 4, 0); //new arr
					DecodePushFieldVal(L, tp, buf, &p);
					lua_rawseti(L, -2, 1); //arr[1]=val

					lua_settable(L, 2);//t[name]=arr
				}
				else {
					int i = lua_objlen(L, -1);
					DecodePushFieldVal(L, tp, buf, &p);
					lua_rawseti(L, -2, ++i); //arr[+]=val
					lua_pop(L, 1); //pop arr
				}
			}
		}
		else {
			if (tp == PBmap) {
				lua_gettable(L, 2);//tab=t[name]
				if (!lua_istable(L, -1)) {
					lua_rawgeti(L, 5, 3);//push name
					lua_createtable(L, 0, 2); //new tab
					lua_settable(L, 2);//t[name]=tab
					lua_rawgeti(L, 5, 3);//push name
					lua_gettable(L, 2);//tab=t[name]
				}
				int plen = DecodeVarint(L, buf, &p);
				lua_rawgeti(L, typeIdx, 1);
				int tpk = lua_tointeger(L, -1);
				lua_rawgeti(L, typeIdx, 2);
				int tpv = lua_tointeger(L, -1);
				//lua_pop(L, 2);
				p++;//sub fn1
				DecodePushFieldVal(L, tpk, buf, &p);
				p++;//sub fn2
				DecodePushFieldVal(L, tpv, buf, &p);
				lua_settable(L, -5);
			}
			else {
				DecodePushFieldVal(L, tp, buf, &p);
				lua_settable(L, 2);
			}
		}
	}
	lua_settop(L, 2);
	return 1;
}

static int lua_proto_code(lua_State* L) 
{

}

static int lua_proto_package(lua_State* L)
{
	luaL_dostring(L,
		"function proto.package(syntax) \
		return setmetatable({}, { __newindex = function(self, name, message) \
			local fields = {} \
			for _,v in pairs(message) do fields[v[4]] = v end \
			local _meta = {name = name,syntax = syntax, message = message, fields = fields} \
			_meta.__index = { \
				encode = proto.encode, \
				decode = function(buf) \
					return proto.decode(buf, setmetatable({}, _meta)) \
				end, \
			} \
			_meta.__call = function(self,t) \
				return setmetatable(t, _meta) \
			end \
			rawset(self, name, setmetatable({}, _meta)) \
		end }) \
	end");
	return 0;
}

LUA_API void luaopen_protobuf(lua_State* L)
{
	lua_createtable(L, 0, 2);
	lua_pushcfunction(L, lua_protoc);
	lua_setfield(L, -2, "protoc");
	lua_pushcfunction(L, lua_proto_decode);
	lua_setfield(L, -2, "decode");
	lua_pushcfunction(L, lua_proto_encode);
	lua_setfield(L, -2, "encode");

	lua_pushinteger(L, PBint32);
	lua_setfield(L, -2, "int32");
	lua_pushinteger(L, PBint64);
	lua_setfield(L, -2, "int64");
	lua_pushinteger(L, PBuint32);
	lua_setfield(L, -2, "uint32");
	lua_pushinteger(L, PBuint64);
	lua_setfield(L, -2, "uint64");
	lua_pushinteger(L, PBsint32);
	lua_setfield(L, -2, "sint32");
	lua_pushinteger(L, PBzigzag32);
	lua_setfield(L, -2, "zigzag32");
	lua_pushinteger(L, PBsint64);
	lua_setfield(L, -2, "sint64");
	lua_pushinteger(L, PBzigzag64);
	lua_setfield(L, -2, "zigzag64");
	lua_pushinteger(L, PBbool);
	lua_setfield(L, -2, "bool");
	lua_pushinteger(L, PBenum);
	lua_setfield(L, -2, "enum");
	lua_pushinteger(L, PBfixed64);
	lua_setfield(L, -2, "fixed64");
	lua_pushinteger(L, PBsfixed64);
	lua_setfield(L, -2, "sfixed64");
	lua_pushinteger(L, PBdouble);
	lua_setfield(L, -2, "double");
	lua_pushinteger(L, PBstring);
	lua_setfield(L, -2, "string");
	lua_pushinteger(L, PBbytes);
	lua_setfield(L, -2, "bytes");
	lua_pushinteger(L, PBfixed32);
	lua_setfield(L, -2, "fixed32");
	lua_pushinteger(L, PBsfixed32);
	lua_setfield(L, -2, "sfixed32");
	lua_pushinteger(L, PBfloat);
	lua_setfield(L, -2, "float");
	lua_pushinteger(L, PBmessage);
	lua_setfield(L, -2, "message");
	lua_pushinteger(L, PBmap);
	lua_setfield(L, -2, "map");

	lua_pushinteger(L, PB_OPT);
	lua_setfield(L, -2, "OPT");
	lua_pushinteger(L, PB_REP);
	lua_setfield(L, -2, "REP");
	lua_pushinteger(L, PB_REQ);
	lua_setfield(L, -2, "REQ");

	lua_createtable(L, 0, 20);
		lua_pushinteger(L, PBint32);
		lua_pushinteger(L, PBint32);
		lua_settable(L, -3);
		lua_pushinteger(L, PBint64);
		lua_pushinteger(L, PBint64);
		lua_settable(L, -3);
		lua_pushinteger(L, PBuint32);
		lua_pushinteger(L, PBuint32);
		lua_settable(L, -3);
		lua_pushinteger(L, PBuint64);
		lua_pushinteger(L, PBuint64);
		lua_settable(L, -3);
		lua_pushinteger(L, PBsint32);
		lua_pushinteger(L, PBsint32);
		lua_settable(L, -3);
		lua_pushinteger(L, PBzigzag32);
		lua_pushinteger(L, PBzigzag32);
		lua_settable(L, -3);
		lua_pushinteger(L, PBsint64);
		lua_pushinteger(L, PBsint64);
		lua_settable(L, -3);
		lua_pushinteger(L, PBzigzag64);
		lua_pushinteger(L, PBzigzag64);
		lua_settable(L, -3);
		lua_pushinteger(L, PBbool);
		lua_pushinteger(L, PBbool);
		lua_settable(L, -3);
		lua_pushinteger(L, PBenum);
		lua_pushinteger(L, PBenum);
		lua_settable(L, -3);
		lua_pushinteger(L, PBfixed64);
		lua_pushinteger(L, PBfixed64);
		lua_settable(L, -3);
		lua_pushinteger(L, PBsfixed64);
		lua_pushinteger(L, PBsfixed64);
		lua_settable(L, -3);
		lua_pushinteger(L, PBdouble);
		lua_pushinteger(L, PBdouble);
		lua_settable(L, -3);
		lua_pushinteger(L, PBfixed32);
		lua_pushinteger(L, PBfixed32);
		lua_settable(L, -3);
		lua_pushinteger(L, PBsfixed32);
		lua_pushinteger(L, PBsfixed32);
		lua_settable(L, -3);
		lua_pushinteger(L, PBfloat);
		lua_pushinteger(L, PBfloat);
		lua_settable(L, -3);
	lua_setfield(L, -2, "primitive");

	lua_setglobal(L, GLOBAL_LIB_NAME);
	lua_proto_package(L);

}
