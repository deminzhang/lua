#include "LuaProtoBuf.h"

//https://www.cnblogs.com/jadeshu/p/10663696.html
//https://cloud.tencent.com/developer/article/1520442
//https://solicomo.com/network-dev/protobuf-proto3-vs-proto2.html

//WIRE分类
#define WIRE_VARINT 0	//变长整型 int32, int64, uint32, uint64, sint32, sint64, bool, enum
#define WIRE_FIXED64 1	//固定8字节 fixed64, sfixed64, double
#define WIRE_BYTES 2	//需显式告知长度 string, bytes, 嵌套类型（embedded messages），repeated字段
#define WIRE_START 3	//{弃用
#define WIRE_END 4		//}弃用
#define WIRE_FIXED32 5	//固定4字节 fixed32, sfixed32, float
//flag分类
#define PBint32 1
#define PBint64 2
#define PBuint32 3
#define PBuint64 4
#define PBsint32 5
#define PBsint64 6
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
#define PBrep 20

#define LAB_OPT 1 //optional proto2
#define LAB_REP 2 //repeated
#define LAB_REQ 3 //required proto2
#define LAB_MAP 4 //更适合当lab

#define MAX_CODE_LEN 0xfff0		//max len of code buffer 最大编码长度

#define META_NAME "[PROTOBUF]"
#define GLOBAL_LIB_NAME "proto"

typedef struct {
	int wire;		//类型对应WIRE类型
	int packed;		//可使用packed
	int size;		//packed=true时,总长计算用单个的长度,0用varsize
	char* name;		//name
} _PT;
static _PT ProtoType[22] = { 0 };

static void init()
{
	ProtoType[PBint32] = (_PT){ WIRE_VARINT ,1,0,"int32" };
	ProtoType[PBint64] = (_PT){ WIRE_VARINT ,1,0,"int64" };;
	ProtoType[PBuint32] = (_PT){ WIRE_VARINT ,1,0,"uint32" };
	ProtoType[PBuint64] = (_PT){ WIRE_VARINT ,1,0,"uint64" };
	ProtoType[PBsint32] = (_PT){ WIRE_VARINT ,1,0,"sint32" };
	ProtoType[PBsint64] = (_PT){ WIRE_VARINT ,1,0,"sint64" };;
	ProtoType[PBbool] = (_PT){ WIRE_VARINT ,1,0,"bool" };
	ProtoType[PBenum] = (_PT){ WIRE_VARINT ,1,0,"enum" };

	ProtoType[PBfixed64] = (_PT){ WIRE_FIXED64 ,1,8,"fixed64" };
	ProtoType[PBsfixed64] = (_PT){ WIRE_FIXED64 ,1,8,"sfixed64" };
	ProtoType[PBdouble] = (_PT){ WIRE_FIXED64 ,1,8,"double" };

	ProtoType[PBstring] = (_PT){ WIRE_BYTES ,0,0,"string" };
	ProtoType[PBbytes] = (_PT){ WIRE_BYTES ,0,0,"bytes" };
	ProtoType[PBmessage] = (_PT){ WIRE_BYTES ,0,0,"message" };
	ProtoType[PBmap] = (_PT){ WIRE_BYTES ,0,0,"map" };
	ProtoType[PBrep] = (_PT){ WIRE_BYTES ,0,0,"rep" };

	ProtoType[PBfixed32] = (_PT){ WIRE_FIXED32 ,1,4,"fixed32" };
	ProtoType[PBsfixed32] = (_PT){ WIRE_FIXED32 ,1,4,"sfixed32" };
	ProtoType[PBfloat] = (_PT){ WIRE_FIXED32 ,1,4,"float" };
}

static unsigned char SizeVarint(size_t x) {
	if (x < 1 << 7) return 1;
	else if (x < 1 << 14) return 2;
	else if (x < 1 << 21) return 3;
	else if (x < 1 << 28) return 4;
	else if (x < 1LL << 35) return 5;
	else if (x < 1LL << 42) return 6;
	else if (x < 1LL << 49) return 7;
	else if (x < 1LL << 56) return 8;
	else if (x < 1LL << 63) return 9;
	return 10;
}

// This is the format for the
// int32, int64, uint32, uint64, bool, and enum protocol buffer types.
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
static void EncodeBytes(const char* s, size_t len, char* buf, size_t* p)
{
	EncodeVarint(len, buf, p);
	memcpy(buf + *p, s, len);
	(*p) += len;
}

static void EncodeField(lua_State* L, int idx, int tp, char* buf, size_t* p)
{
	switch (tp) {
	case PBbool: {
		int v = lua_toboolean(L, idx);
		EncodeVarint(v, buf, p);
		break;
	}
	case PBint64:
	case PBuint64: 
	case PBint32:
	case PBuint32:
	case PBenum: {
		double V = lua_tonumber(L, idx);
		long long v = (long long)V;
		if (v != (long long)v)
			lua_errorEx(L, "%d not varint", v);
		EncodeVarint(v, buf, p);
		break;
	}
	case PBsint32: { //PBzigzag32
		double V = lua_tonumber(L, idx);
		long long v = (long long)V;
		if (v != (int)v)
			lua_errorEx(L, "%f out range of sint32", V);
		EncodeZigzag32((size_t)v, buf, p);
		break;
	}
	case PBsint64: {//PBzigzag64
		double V = lua_tonumber(L, idx);
		long long v = (long long)V;
		if (v != (long long)v)
			lua_errorEx(L, "%d not sint64", v);
		EncodeZigzag64((size_t)v, buf, p);
		break;
	}
	case PBfixed64:
	case PBsfixed64: {
		double V = lua_tonumber(L, idx);
		long long v = (long long)V;
		if (v != (long long)v)
			lua_errorEx(L, "%d not int or long long", v);
		*(long long*)(buf + *p) = v;
		(*p) += 8;
		break;
	}
	case PBdouble: {
		double V = lua_tonumber(L, idx);
		*(double*)(buf + *p) = V;
		(*p) += 8;
		break;
	}
	case PBfixed32:
	case PBsfixed32: {
		double V = lua_tonumber(L, idx);
		long long v = (long long)V;
		if (v != (int)v)
			lua_errorEx(L, "%f out range of FIXED32", V);
		*(int*)(buf + *p) = V;
		(*p) += 4;
		break;
	}
	case PBfloat: {
		double V = lua_tonumber(L, idx);
		*(float*)(buf + *p) = V;
		*p += 4;
		break;
	}
	case PBstring: {
		size_t len; const char* s = lua_tolstring(L, idx, &len);
		EncodeBytes(s, len, buf, p); //空串允许!
		break;
	}
	case PBbytes: {
		size_t len; const char* s = lua_toBytes(L, idx, &len);
		//if (len == 0)??; //空串允许?
		EncodeBytes(s, len, buf, p);
		break;
	}
	case PBmessage: {
		lua_getfield(L, -1, "encode");
		lua_insert(L, -2);
		lua_call(L, 1, 1);
		size_t len; const char* s = lua_toBytes(L, idx, &len);
		//if (len == 0)??; //空串允许?
		EncodeBytes(s, len, buf, p);
		break;
	}
	case PBmap: {

		lua_errorEx(L, "unsupported map in map");
		break;
	}
	}
}

static size_t encode_tab(lua_State* L, char *buf)
{
	size_t p = 0;
	if (!lua_istable(L, 1))
		lua_errorEx(L, "#1 must table for duplicate");
	lua_getmetatable(L, 1);

	lua_getfield(L, -1, "syntax");
	const char* syntax = lua_tostring(L, -1);
	int proto2 = syntax == NULL || strcmp(syntax, "proto3");
	lua_pop(L, 1);

	lua_getfield(L, -1, "message"); //meta.fields
	int top = lua_gettop(L);
	for (int i = 1;; i++, lua_settop(L, top)) {
		lua_rawgeti(L, top, i);//field=fields[i]
		if (lua_isnil(L, -1)) break;
		//ff ff ff ff lab tpk tpv packed
		lua_rawgeti(L, top + 1, 0);//field[1] lab
		int lab0 = lua_tointeger(L, -1);
		lua_pop(L, 1);
		int lab = lab0 >> 24;
		int tp = lab0 >> 8 & 0xffff;
		int packed0 = lab0 & 0xff;
		int packed = ProtoType[tp].packed && (packed0 == 2 ? (proto2 ? 0 : 1) : packed0);

		lua_rawgeti(L, top + 1, 2);//field[2] TP
		lua_rawgeti(L, top + 1, 4);//field[4] FN
		int fn = lua_tointeger(L, -1);
		lua_pop(L, 1);

		lua_rawgeti(L, top + 1, 3); //field[3] name
		const char* name = lua_tostring(L, -1);
		lua_gettable(L, 1); //t[k]

		int vtp = lua_type(L, -1);
		switch (lab) {
		case LAB_MAP:
			if (vtp == LUA_TNIL) continue;
			int tpk = tp >> 16;
			int tpv = tp & 0xffff;
			int wirek = ProtoType[tpk].wire;
			int wirev = ProtoType[tpv].wire;
			for (lua_pushnil(L); lua_next(L, -2); lua_pop(L, 1)) {
				EncodeFieldType(fn, WIRE_BYTES, buf, &p);
				size_t old = p;
				p++; //留大概率1
				EncodeFieldType(1, wirek, buf, &p);
				EncodeField(L, -2, tpk, buf, &p);
				EncodeFieldType(2, wirev, buf, &p);
				EncodeField(L, -1, tpv, buf, &p);
				size_t kvlen = p - old - 1;
				unsigned char lenSize = SizeVarint(kvlen);
				if (lenSize > 1) //lenSize大概率是1 大于1时memcpy后移重写lenSize
					memcpy(buf + old + lenSize, buf + old + 1, kvlen);
				p = old;
				EncodeVarint(kvlen, buf, &p); //p+=lenSize
				p += kvlen;
			}
			break;
		case LAB_REP:
			if (vtp == LUA_TNIL) continue;
			if (vtp != LUA_TTABLE)
				lua_errorEx(L, "%s repeated table required, got %s", name, lua_typename(L, vtp));

			int size = lua_objlen(L, -1);
			if (packed) {
				EncodeFieldType(fn, WIRE_BYTES, buf, &p);
				int sumLen = ProtoType[tp].size;
				if (sumLen == 0)
					for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
						lua_rawgeti(L, -1, j);
						double V = lua_tonumber(L, -1);
						sumLen += SizeVarint((size_t)V);
					}
				else
					sumLen *= size;
				EncodeVarint(sumLen, buf, &p);
				for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
					lua_rawgeti(L, -1, j);
					EncodeField(L, -1, tp, buf, &p);
				}
			}
			else {
				int wire = ProtoType[tp].wire;
				for (int j = 1; j <= size; j++, lua_pop(L, 1)) {
					lua_rawgeti(L, -1, j);
					EncodeFieldType(fn, wire, buf, &p);
					EncodeField(L, -1, tp, buf, &p);
				}
			}
			break;
		case LAB_OPT:
			if (vtp == LUA_TNIL)continue;
		case LAB_REQ: //if protobuf2
			if (vtp == LUA_TNIL)
				lua_errorEx(L, "%s value required, got nil", name);

			EncodeFieldType(fn, ProtoType[tp].wire, buf, &p);
			EncodeField(L, -1, tp, buf, &p);
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

	size_t len = encode_tab(L, buf);
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

static void DecodeFieldVal(lua_State* L, int tp, const char *buf, size_t*p)
{
	size_t V;
	switch (tp) {
	case PBbool: {
		int b = (int)buf[(*p)++];
		lua_pushboolean(L, b);
		break;
	}
	case PBint32: 
	case PBenum:{
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
	case PBuint64:{
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
	case PBmessage: {
		V = DecodeVarint(L, buf, p);
		lua_rawgeti(L, 5, 2);
		lua_getfield(L, -1, "decode");
		lua_insert(L, -2);
		char* u = lua_newBytes(L, V); //TODO lua_pushlightuserdata(L, val);
		memcpy(u, buf + *p, V);
		lua_call(L, 2, 1); //decode(Msg,buf)
		*p += V;
		break;
	}
	case PBmap: {
		//in lua_proto_decode
		break;
	}
	default:
		lua_errorEx(L, "unknown proto type field: %s", lua_tostring(L, 6));
		break;
	}
}

static int lua_proto_decode(lua_State* L)
{
	//L1: table L2: buf
	size_t len;
	const char* buf = lua_toBytes(L, 2, &len);
	//L3: metatable
	lua_getmetatable(L, 1);
	lua_createtable(L, 0, 2);
	lua_pushvalue(L, -2);
	lua_setmetatable(L, -2);
	lua_replace(L, 1);
	//L4: metatable.fields
	lua_getfield(L, -1, "fields");
	lua_getfield(L, -2, "syntax");
	const char* syntax = lua_tostring(L, -1);
	int proto2 = syntax == NULL || strcmp(syntax, "proto3");
	lua_pop(L, 1);

	int top = lua_gettop(L);
	int fn, wt;	//wire type
	for (size_t p = 0; p < len; lua_settop(L, top)) {
		DecodeFieldType(buf, &p, &fn, &wt);
		lua_rawgeti(L, 4, fn);//L5 field=fields[i]
		if (lua_isnil(L, -1))
			lua_errorEx(L, "undefined field idx: %d", fn);
		//lab tpk tpv packed
		lua_rawgeti(L, 5, 0);//field[1] lab
		int lab0 = lua_tointeger(L, -1);
		lua_pop(L, 1);
		int lab = lab0 >> 24;
		int tp = lab0 >> 8 & 0xffff;
		int packed0 = lab0 & 0xff;
		int packed = ProtoType[tp].packed && (packed0 == 2 ? (proto2 ? 0 : 1) : packed0);

		lua_rawgeti(L, 5, 2);//field[2] TP
		lua_rawgeti(L, 5, 3); //field[3] name
		switch (lab)
		{
		case LAB_REP: 
			if (packed) {
				int plen = DecodeVarint(L, buf, &p);
				size_t oldp = p;
				lua_createtable(L, plen, 0); //new arr
				for (int i = 1; p - oldp < plen; i++) {
					DecodeFieldVal(L, tp, buf, &p);
					lua_rawseti(L, -2, i); //arr[++]=val
				}
				lua_settable(L, 1); //t[name]=arr
			}
			else {
				lua_gettable(L, 1);
				if (!lua_istable(L, -1)) {
					lua_createtable(L, 4, 0); //new 
					lua_rawgeti(L, 5, 3);//push name
					lua_pushvalue(L, -2);
					lua_settable(L, 1);//t[name]=arr
				}
				int i = lua_objlen(L, -1);
				DecodeFieldVal(L, tp, buf, &p);
				lua_rawseti(L, -2, ++i); //arr[+]=val
				lua_pop(L, 1); //pop arr
			}
			break;
		case LAB_MAP:  //PBmap
			lua_gettable(L, 1);//tab=t[name]
			if (!lua_istable(L, -1)) {
				lua_createtable(L, 0, 2); //new tab
				lua_rawgeti(L, 5, 3);//push name
				lua_pushvalue(L, -2);
				lua_settable(L, 1);//t[name]=tab
			}
			int plen = DecodeVarint(L, buf, &p);
			int tpk = tp >> 16;
			int tpv = tp & 0xffff;
			p++;//sub fn1
			DecodeFieldVal(L, tpk, buf, &p);
			p++;//sub fn2
			DecodeFieldVal(L, tpv, buf, &p);
			lua_settable(L, -3);
			break;
		default: 
			DecodeFieldVal(L, tp, buf, &p);
			lua_settable(L, 1);
			break;
		}
	}
	lua_settop(L, 1);
	return 1;
}

static int lua_protoc(lua_State* L)
{
	//in lua
	return 0;
}

static int lua_proto_package(lua_State* L) 
{
	//in lua
}

static int lua_proto_import(lua_State* L) 
{
	//in lua
}

static int lua_proto_utils(lua_State* L)
{
	//luaL_dostring(L,"");
	return 0;
}

static int lua_definemap(lua_State* L)
{
	int ktp = lua_tointeger(L, 1);
	int vtp = lua_tointeger(L, 2);
	lua_pushinteger(L, ktp << 16 | vtp);
	return 1;
}

LUA_API void luaopen_protobuf(lua_State* L)
{
	init();

	lua_createtable(L, 0, 2);
	lua_pushcfunction(L, lua_definemap);
	lua_setfield(L, -2, "Map");
	lua_pushcfunction(L, lua_proto_decode);
	lua_setfield(L, -2, "decode");
	lua_pushcfunction(L, lua_proto_encode);
	lua_setfield(L, -2, "encode");
	lua_createtable(L, 0, 0);
	lua_setfield(L, -2, "loaded"); //package loaded
	lua_pushinteger(L, LAB_OPT), lua_setfield(L, -2, "OPT");
	lua_pushinteger(L, LAB_REP), lua_setfield(L, -2, "REP");
	lua_pushinteger(L, LAB_REQ), lua_setfield(L, -2, "REQ");
	lua_pushinteger(L, LAB_MAP), lua_setfield(L, -2, "MAP");

	lua_createtable(L, 0, 0);
		lua_createtable(L, 0, 22);
		for (int i = 0; i < 22; i++)
			if (ProtoType[i].name != NULL)
				lua_pushinteger(L, i), lua_setfield(L, -2, ProtoType[i].name);
		lua_setfield(L, -2, "__index");
	lua_setmetatable(L, -2);

	lua_createtable(L, 0, 22);
	for (int i = 0; i < 22; i++) {
		if (ProtoType[i].packed)
			lua_pushboolean(L, 1), lua_rawseti(L, -2, i);
	}
	lua_setfield(L, -2, "packedType");

	lua_setglobal(L, GLOBAL_LIB_NAME);
	//方便用lua写的
	lua_proto_utils(L);
}