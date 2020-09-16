
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

#define PB_OPT 1 //optional 2
#define PB_SIG 1 //singular 3
#define PB_REP 2 //repeated
#define PB_REQ 3 //required 2

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
	else if (x < 1 << 35)
		return 5;
	else if (x < 1 << 42)
		return 6;
	else if (x < 1 << 49)
		return 7;
	else if (x < 1 << 56)
		return 8;
	else if (x < 1 << 63)
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

static void EncodeFieldType(int fn, char wt, char* buf, int* p)
{
	if (fn < 16)
		buf[(*p)++] = (fn << 3) + wt;
	else {
		buf[(*p)++] = (fn << 3) | 0x80 + wt;
		EncodeVarint(fn >> 4, buf, p);
	}
}
// This is the format for the
// fixed64, sfixed64, and double protocol buffer types.
static void EncodeFixed64(size_t x, char* buf, size_t* p)
{
	buf[(*p)++] = (unsigned char)x;
	buf[(*p)++] = (unsigned char)(x >> 8);
	buf[(*p)++] = (unsigned char)(x >> 16);
	buf[(*p)++] = (unsigned char)(x >> 24);
	buf[(*p)++] = (unsigned char)(x >> 32);
	buf[(*p)++] = (unsigned char)(x >> 40);
	buf[(*p)++] = (unsigned char)(x >> 48);
	buf[(*p)++] = (unsigned char)(x >> 56);
}
// This is the format for the
// fixed32, sfixed32, and float protocol buffer types.
static void EncodeFixed32(size_t x, char* buf, size_t* p)
{
	buf[(*p)++] = (unsigned char)x;
	buf[(*p)++] = (unsigned char)(x >> 8);
	buf[(*p)++] = (unsigned char)(x >> 16);
	buf[(*p)++] = (unsigned char)(x >> 24);
}
// This is the format used for the sint64 protocol buffer type.
static void EncodeZigzag64(size_t x, char* buf, size_t* p)
{
	// use signed number to get arithmetic right shift.
	EncodeVarint((size_t)((x << 1) ^ (size_t)((long long)x >> 63)),buf,p);
}
// This is the format used for the sint32 protocol buffer type.
static void EncodeZigzag32(size_t x, char* buf, size_t * p)
{
	// use signed number to get arithmetic right shift.
	EncodeVarint((size_t)(((unsigned)x << 1) ^ (unsigned)(((int)x >> 31))), buf, p);
}
// This is the format used for the proto2 string type.
static void EncodeStringBytes(char s[], char* buf, size_t* p)
{
	size_t len = sizeof(s);
	EncodeVarint(len, buf, p);
	memcpy(buf + *p, s, len);
	(*p) += len;
}

static void EncodeBytes(lua_State* L, int idx, int fn, char* buf, int* p)
{
	size_t len; const char* s = lua_toBytes(L, idx, &len);
	if (len == 0)return;
	EncodeFieldType(fn, WIRE_BYTES, buf, p);
	EncodeVarint(len, buf, p);
	memcpy(buf + *p, s, len);
	(*p) += len;
}

static int encode_tab(lua_State* L, int idx, char *buf, size_t*p)
{
	if (!lua_istable(L, idx))
		lua_errorEx(L, "#1 must table for duplicate");
	lua_getmetatable(L, idx);
	lua_getfield(L, -1, "message"); //meta.fields
	lua_getfield(L, -2, "syntax"); 
	const char* syntax = lua_tostring(L, -1);
	int proto2 = syntax==NULL || strcmp(syntax, "proto3");
	lua_pop(L, 1);
	int top = lua_gettop(L);
	for (int i = 1;; i++, lua_settop(L, top))
	{
		lua_rawgeti(L, top, i);//field=fields[i]
		if (lua_isnil(L, -1)) break;

		lua_rawgeti(L, top + 1, 1);//field[1] fieldtype
		int ktp = lua_tointeger(L, -1);
		lua_pop(L, 1);

		lua_rawgeti(L, top + 1, 2);//field[2] TP
		int tp = lua_tointeger(L, -1);
		lua_pop(L, 1);

		lua_rawgeti(L, top + 1, 4);//field[4] FN
		int fn = lua_tointeger(L, -1);
		lua_pop(L, 1);

		lua_getfield(L, top + 1, "packed");
		int packed = lua_isnil(L, -1) ? (proto2 ? 0 : 1): lua_toboolean(L, -1);
		lua_pop(L, 1);

		lua_rawgeti(L, top + 1, 3); //field[3] name
		char* name = lua_tostring(L, -1);
		lua_gettable(L, idx); //t[k]

		int vtp = lua_type(L, -1);
		//check
		switch (ktp) {
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
			if (ktp == PB_REP) {
				int size = lua_objlen(L, -1);
				if (packed) {
					EncodeFieldType(fn, WIRE_BYTES, buf, p);
					EncodeVarint(size * sizeof(char), buf, p); //protobuf2[packed=true] or protobuf3
					for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						int v = lua_toboolean(L, -1);
						EncodeVarint(v, buf, p);
					}
				}
				else {
					for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						int v = lua_toboolean(L, -1);
						EncodeFieldType(fn, WIRE_VARINT, buf, p);
						EncodeVarint(v, buf, p);
					}
				}
			}
			else {
				int v = lua_toboolean(L, -1);
				EncodeFieldType(fn, WIRE_VARINT, buf, p);
				EncodeVarint(v, buf, p);
			}
			break;
		}
		case PBint32:
		case PBint64:
		case PBuint32:
		case PBuint64:
		case PBenum:{
			//TODO check value in lua_getfield(L, top + 1, "enum");
			if (ktp == PB_REP) {
				int len = lua_objlen(L, -1);
				if (packed) {
					EncodeFieldType(fn, WIRE_BYTES, buf, p);
					int Len = 0;
					for (int j = 1; j <= len; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						double V = lua_tonumber(L, -1);
						long long v = (long long)V;
						Len += SizeVarint(v);
					}
					EncodeVarint(Len, buf, p);
					for (int j = 1; j <= len; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						double V = lua_tonumber(L, -1);
						long long v = (long long)V;
						if (v != (long long)v)
							lua_errorEx(L, "%d not intX", v);

						EncodeVarint(v, buf, p);
					}
				}
				else {
					for (int j = 1; j <= len; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						double V = lua_tonumber(L, -1);
						long long v = (long long)V;
						if (v != (long long)v)
							lua_errorEx(L, "%d not intX", v);
						EncodeFieldType(fn, WIRE_VARINT, buf, p);

						EncodeVarint(v, buf, p);
					}
				}
			}
			else {
				double V = lua_tonumber(L, -1);
				long long v = (long long)V;
				if (v != (long long)v)
					lua_errorEx(L, "%d not intX", v);
				EncodeFieldType(fn, WIRE_VARINT, buf, p);

				EncodeVarint(v, buf, p);
			}
			break;
		}
		case PBsint32: { //PBzigzag32
			if (ktp == PB_REP) {
				int size = lua_objlen(L, -1);
				if (packed) {
					EncodeFieldType(fn, WIRE_BYTES, buf, p);
					EncodeVarint(size * sizeof(int), buf, p); //protobuf2[packed=true] or protobuf3
					for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						double V = lua_tonumber(L, -1);
						long long v = (long long)V;
						if (v != (long long)v)
							lua_errorEx(L, "%d not FIXED64", v);
						EncodeZigzag32((size_t)v, buf, p);
					}
				}
				else {
					for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						double V = lua_tonumber(L, -1);
						long long v = (long long)V;
						if (v != (long long)v)
							lua_errorEx(L, "%d not sint32", v);
						EncodeFieldType(fn, WIRE_VARINT, buf, p);
						EncodeZigzag32((size_t)v, buf, p);
					}
				}
			}
			else {
				double V = lua_tonumber(L, -1);
				long long v = (long long)V;
				if (v != (long long)v)
					lua_errorEx(L, "%d not sint32", v);
				EncodeFieldType(fn, WIRE_VARINT, buf, p);
				EncodeZigzag32((size_t)v, buf, p);
				break;
			}
		}
		case PBsint64: {//PBzigzag64
			if (ktp == PB_REP) {
				int size = lua_objlen(L, -1);
				if (packed) {
					EncodeFieldType(fn, WIRE_BYTES, buf, p);
					EncodeVarint(size * sizeof(long long), buf, p); //protobuf2[packed=true] or protobuf3
					for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						double V = lua_tonumber(L, -1);
						long long v = (long long)V;
						if (v != (long long)v)
							lua_errorEx(L, "%d not sint64", v);
						EncodeZigzag64((size_t)v, buf, p);
					}
				}
				else {
					for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						double V = lua_tonumber(L, -1);
						long long v = (long long)V;
						if (v != (long long)v)
							lua_errorEx(L, "%d not sint64", v);
						EncodeFieldType(fn, WIRE_VARINT, buf, p);
						EncodeZigzag64((size_t)v, buf, p);
					}
				}
			}
			else {
				double V = lua_tonumber(L, -1);
				long long v = (long long)V;
				if (v != (long long)v)
					lua_errorEx(L, "%d not sint64", v);
				EncodeFieldType(fn, WIRE_VARINT, buf, p);
				EncodeZigzag64((size_t)v, buf, p);
			}
			break;
		}
		case PBfixed64:
		case PBsfixed64: {
			if (ktp == PB_REP) {
				int size = lua_objlen(L, -1);
				if (packed) {
					EncodeFieldType(fn, WIRE_BYTES, buf, p);
					EncodeVarint(size * sizeof(long long), buf, p); //protobuf2[packed=true] or protobuf3
					for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						double V = lua_tonumber(L, -1);
						long long v = (long long)V;
						if (v != (long long)v)
							lua_errorEx(L, "%d not FIXED64", v);
						EncodeFixed64(v, buf, p);
					}
				}
				else {
					for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						double V = lua_tonumber(L, -1);
						long long v = (long long)V;
						if (v != (long long)v)
							lua_errorEx(L, "%d not FIXED64", v);
						EncodeFieldType(fn, WIRE_FIXED64, buf, p);
						EncodeFixed64(v, buf, p);
					}
				}
			}
			else {
				double V = lua_tonumber(L, -1);
				long long v = (long long)V;
				if (v != (long long)v)
					lua_errorEx(L, "%d not int or long", v);
				EncodeFieldType(fn, WIRE_FIXED64, buf, p);
				EncodeFixed64(v, buf, p);
			}
			break;
		}
		case PBdouble: {
			if (ktp == PB_REP) {
				int size = lua_objlen(L, -1);
				if (packed) {
					EncodeFieldType(fn, WIRE_BYTES, buf, p);
					EncodeVarint(size * sizeof(double), buf, p); //protobuf2[packed=true] or protobuf3
					for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						double V = lua_tonumber(L, -1);
						*(double*)(buf + (*p)) = V;
						(*p) += sizeof(double);
					}
				}
				else {
					for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						EncodeFieldType(fn, WIRE_FIXED64, buf, p);
						double V = lua_tonumber(L, -1);
						*(double*)(buf + (*p)) = V;
						(*p) += sizeof(double);
					}
				}
			}
			else {
				EncodeFieldType(fn, WIRE_FIXED64, buf, p);
				double V = lua_tonumber(L, -1);
				*(double*)(buf + (*p)) = V;
				(*p) += sizeof(double);
			}
			break;
		}
		case PBfixed32:
		case PBsfixed32: {
			if (ktp == PB_REP) {
				int size = lua_objlen(L, -1);
				if (packed) {
					EncodeFieldType(fn, WIRE_BYTES, buf, p);
					EncodeVarint(size * sizeof(int), buf, p); //protobuf2[packed=true] or protobuf3
					for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						double V = lua_tonumber(L, -1);
						long long v = (long long)V;
						if (v != (long long)v)
							lua_errorEx(L, "%d not FIXED32", v);
						EncodeFixed32(v, buf, p);
					}
				}
				else {
					for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						double V = lua_tonumber(L, -1);
						long long v = (long long)V;
						if (v != (long long)v)
							lua_errorEx(L, "%d not FIXED32", v);
						EncodeFieldType(fn, WIRE_FIXED32, buf, p);
						EncodeFixed32(v, buf, p);
					}
				}
			}
			else {
				double V = lua_tonumber(L, -1);
				long long v = (long long)V;
				if (v != (long long)v)
					lua_errorEx(L, "%d not FIXED32", v);
				EncodeFieldType(fn, WIRE_FIXED32, buf, p);
				EncodeFixed32(v, buf, p);
			}
			break;
		}
		case PBfloat: {
			if (ktp == PB_REP) {
				int size = lua_objlen(L, -1);
				if (packed) {
					EncodeFieldType(fn, WIRE_BYTES, buf, p);
					EncodeVarint(size * sizeof(float), buf, p);
					for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						double V = lua_tonumber(L, -1);
						*(float*)(buf + (*p)) = V;
						(*p) += sizeof(float);
					}
				}
				else {
					for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						EncodeFieldType(fn, WIRE_FIXED32, buf, p);
						double V = lua_tonumber(L, -1);
						*(float*)(buf + (*p)) = V;
						(*p) += sizeof(float);
					}
				}
			}
			else {
				double V = lua_tonumber(L, -1);
				float v = (float)V;
				EncodeFieldType(fn, WIRE_FIXED32, buf, p);
				*(float*)(buf + (*p)) = v; //跟golang byte值一致
				(*p) += sizeof(float);
			}
			break;
		}
		case PBstring: {
			if (ktp == PB_REP) {
				int size = lua_objlen(L, -1);
				for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
					lua_rawgeti(L, -1, j);
					size_t len; const char* s = lua_tolstring(L, -1, &len);
					EncodeFieldType(fn, WIRE_BYTES, buf, p);
					EncodeVarint(len, buf, p);
					memcpy(buf + *p, s, len);
					(*p) += len;
				}
			}
			else {
				size_t len; const char* s = lua_tolstring(L, -1, &len);
				EncodeFieldType(fn, WIRE_BYTES, buf, p);
				EncodeVarint(len, buf, p);
				memcpy(buf + *p, s, len);
				(*p) += len;
			}
			break;
		}
		case PBbytes: {
			EncodeBytes(L, -1, fn, buf, p);
			break;
		}
		default:
			if (ktp == PB_REP) {
				int size = lua_objlen(L, -1);
				for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
					lua_rawgeti(L, -1, j);
					lua_getfield(L, -1, "Marshal");
					lua_insert(L, -2);
					lua_call(L, 1, 1);
					EncodeBytes(L, -1, fn, buf, p);
				}
				break;
			}
			else {
				if (vtp == LUA_TTABLE) {
					int tt = lua_gettop(L);
					lua_getfield(L, -1, "Marshal");
					lua_insert(L, -2);
					lua_call(L, 1, 1);
					EncodeBytes(L, -1, fn, buf, p);
					break;
				}
			}
			lua_errorEx(L, "unsurrpot encode vtype %s", lua_typename(L, vtp));
			break;
		}
	}
	return 0;
}
static int lua_proto_encode(lua_State* L)
{
	if (lua_isnone(L, 1))
		lua_errorEx(L, "[C]invalid #1 no data to encode");

	int top = lua_gettop(L);
	//char buf[MAX_CODE_LEN + 1];
	char *buf = (char*)malloc(MAX_CODE_LEN + 1);
	size_t len = 0;
	encode_tab(L, 1, buf, &len);
	if (len > MAX_CODE_LEN) {
		lua_errorEx(L, "protobuf encode tolong %d", len);
	}
	if (len == 0)return 0;
	char* buff1 = (char*)lua_newBytes(L, len);
	memcpy(buff1, buf, len);
	free(buf);
	return 1;
}
/**decode********************************************************/

//0 1010 101 //0是否最后一字节 FN1010 WT101
//1 0001 101,00000001 //FN1010 WT101
//varLen BLLLLLLL BXXXXXXX bHHHHHHH B是否有下一字节
static size_t DecodeVarint(lua_State *L, const char* s, size_t* p, size_t len) {
	if ((*p) > len)
		lua_errorEx(L, "ErrUnexpectedEOF");

	size_t x = (size_t)s[(*p)++]; //first byte
	if (x < 0x80)
		return x;

	x -= 0x80LL;
	size_t b = (size_t)(s[(*p)++]);
	x += b << 7;
	if (b < 0x80)
		return x;

	x -= 0x80LL << 7;
	b = (size_t)(s[(*p)++]);
	x += b << 14;
	if (b < 0x80)
		return x;

	x -= 0x80LL << 14;
	b = (size_t)(s[(*p)++]);
	x += b << 21;
	if (b < 0x80)
		return x;

	x -= 0x80LL << 21;
	b = (size_t)(s[(*p)++]);
	x += b << 28;
	if (b < 0x80)
		return x;

	x -= 0x80LL << 28;
	b = (size_t)(s[(*p)++]);
	x += b << 35;
	if (b < 0x80)
		return x;

	x -= 0x80LL << 35;
	b = (size_t)(s[(*p)++]);
	x += b << 42;
	if (b < 0x80)
		return x;

	x -= 0x80LL << 42;
	b = (size_t)(s[(*p)++]);
	x += b << 49;
	if (b < 0x80)
		return x;

	x -= 0x80LL << 49;
	b = (size_t)(s[(*p)++]);
	x += b << 56;
	if (b < 0x80)
		return x;

	x -= 0x80LL << 56;
	b = (size_t)(s[(*p)++]);
	x += b << 63;
	if (b < 0x80)
		return x;

	lua_errorEx(L, "ErrOverflow");
}

static DecodeFieldType(char* buf, int* p, int *fn, int*wt)
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

static int lua_proto_decode(lua_State* L)
{
	//L1: buf
	size_t len;
	const char* s = lua_toBytes(L, 1, &len);
	//L2: ret table
	//L3: metatable
	lua_getmetatable(L, 2);
	//L4: metatable.fields
	lua_getfield(L, -1, "fields");
	lua_getfield(L, -2, "syntax");
	const char* syntax = lua_tostring(L, -1);
	int proto2 = syntax == NULL || strcmp(syntax, "proto3");
	lua_pop(L, 1);

	size_t p = 0;
	int fn = 0;	//feild number
	int wt;	//wire type
	size_t varLen;
	char* val;
	int top = lua_gettop(L);
	while (p < len) {
		DecodeFieldType(s, &p, &fn, &wt);
		lua_rawgeti(L, 4, fn);//field=fields[i]
		if (lua_isnil(L, -1))
			lua_errorEx(L, "undefined field %d", fn);

		lua_rawgeti(L, top + 1, 1);//field[1] fieldtype
		int ktp = lua_tointeger(L, -1);
		lua_pop(L, 1);

		lua_rawgeti(L, top + 1, 2);//field[2] TP
		int tp = lua_tointeger(L, -1);
		lua_pop(L, 1);

		lua_getfield(L, top + 1, "packed");
		int packed = lua_isnil(L, -1) ? (proto2 ? 0 : 1) : lua_toboolean(L, -1);
		lua_pop(L, 1);

		lua_rawgeti(L, top + 1, 3); //field[3] name
		char* name = lua_tostring(L, -1);

		if (ktp == PB_REP) {
			lua_createtable(L, 4, 0);
			if (packed) {

			}
			else {

			}
			lua_settable(L, 2);
		}
		else {

		}

		switch (tp) {
		case PBbool: {
			int b = (unsigned int)s[p++];
			lua_pushboolean(L, b);
			lua_settable(L, 2);
			break;
		}
		case PBint32:
		case PBint64:
		case PBuint32:
		case PBuint64:
		case PBenum:{
			varLen = DecodeVarint(L, s, &p, len);

			break;
		}
		case PBsint32:
		case PBsint64: {

			break;
		}
		case PBfixed64:
		case PBsfixed64: {
			long long v = R64(s + p);
			lua_pushnumber(L, v);
			lua_settable(L, 2);
			p += sizeof(long long);
			break;
		}
		case PBdouble: {
			double v = RDb(s + p);
			lua_pushnumber(L, v);
			lua_settable(L, 2);
			p += sizeof(double);
			break;
		}
		case PBfixed32:
		case PBsfixed32: {
			int v = R32(s + p);
			lua_pushnumber(L, v);
			lua_settable(L, 2);
			p += sizeof(int);
			break;
		}
		case PBfloat: { //encode时double转float, decode时float tonumber会有损失精度
			float v = RFl(s + p);
			double V = (double)v;
			lua_pushnumber(L, V);
			lua_settable(L, 2);
			p += sizeof(float);
			break;
		}
		case PBstring: {
			varLen = DecodeVarint(L, s, &p, len);
			lua_pushlstring(L, s + p, varLen);
			lua_settable(L, 2);
			p += varLen;
			break;
		}
		case PBbytes: {
			varLen = DecodeVarint(L, s, &p, len);
			char *ub = lua_newBytes(L, varLen);
			memcpy(ub, s + p, varLen);
			lua_settable(L, 2);
			p += varLen;
			break;
		}
		default: {

			break;
		}
		}
		lua_settop(L, top);
	}
	lua_settop(L, 2);
	return 1;
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
	lua_pushinteger(L, PB_OPT);
	lua_setfield(L, -2, "OPT");
	lua_pushinteger(L, PB_REP);
	lua_setfield(L, -2, "REP");
	lua_pushinteger(L, PB_REQ);
	lua_setfield(L, -2, "REQ");

	lua_setglobal(L, GLOBAL_LIB_NAME);
}
