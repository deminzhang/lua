#include "LuaCode.h"


#define C_NIL 0			//
#define C_TRUE 1		//t
#define C_FALSE 2		//f
#define C_INT1 3		//b byte
#define C_INT2 4		//w short byte16
#define C_INT4 5		//i int	byte32
#define C_INT8 6		//l long byte64
#define C_FLOAT4 7		//f float
#define C_FLOAT8 8		//d double
#define C_STR1 9		//s string len<256
#define C_STR2 0xa		//S string len==byte16
#define C_STR4 0xb		//M string len==byte32   no len=int8 if MAXSTRLEN<0xffff no use
#define C_TABLE 0xc		//table start
#define C_REF 0xd		//refer a table or string>STRREFLEN
#define C_ENCODED 0xe	//encoded
#define C_END 0xf		//end of table or all

#define MAX_CODE_LEN 0xfff0		//max len of code buffer 最大编码长度
#define MAX_STR_LEN 0x4000		//max len of string 最大支持字串长度
#define STR_REF_LEN 5			//string can set ref min len 小于该长度字串不作重复引用记录
#define REF_LEN_TYPE unsigned	//unsigned short maybe enough 引用长度记录长度
#define USE_REF_TAB_AND_LONGSTR //refer table and longstring  是否引用压缩重复表和长字串
//#define LENONHEAD //len on head of bytes. must use with LuaNet together

//0xkTYPEvTYPE,k,v
//true = C_TRUE 1
//false = C_FALSE 1
//double = C_FLOAT8,double 9
//char = C_INT1,char 2
//short = C_INT2,short 3
//int = C_INT4,int 5
//int8 = C_INT8,int8 9
//0xkkkkvvvv,k,v
//double = C_FLOAT8,d8
//str1 = charlen,str
//str2 = shortlen,str
//str4 = intlen,str
//ref = idx
//refencode[pointer]=idx
//refdecode[idx]=value

static void encode(lua_State *L, int kidx, int vidx, int *offset, char *buff,int ref, int *refn);

#ifdef USE_REF_TAB_AND_LONGSTR
static unsigned char encode_ref(lua_State *L,int idx,int *p,char *buff,int ref,int *refn)
{
	lua_pushvalue(L, ref); //ref tab
	size_t pk = (size_t)lua_topointer(L, idx);
	lua_pushnumber(L, pk);
	lua_rawget(L, -2);
	if (lua_isnil(L, -1)){ //unrefed,new
		lua_pop(L, 1); //pop nil
		lua_pushnumber(L, pk);
		lua_pushnumber(L, ++(*refn));
		lua_rawset(L, -3); //new ref[pk] = *p
		lua_pop(L, 1); //pop ref tab
		return C_NIL;
	}
	//refed idx
	*(REF_LEN_TYPE*)(buff + (*p)) = (REF_LEN_TYPE)lua_tonumber(L, -1);
	(*p) += sizeof(REF_LEN_TYPE);
	lua_pop(L, 2); //pop pk,ref
	return C_REF;
}
#endif

static unsigned char encode_num(lua_State *L, int idx, int *p, char *buff)
{
	unsigned char ctype;
	double V = lua_tonumber(L, idx);
	long long v = (long long)V;
	if (V != V) //NaN
		lua_errorEx(L, "can't encode NaN");
	if (v != v << 10 >> 10) //out of bit54 
		lua_errorEx(L, "number %f out of signed 54bit range", V);
	if (v != V) { //double=0x6,double
		//if (V != (double)(float)V ){ //?check
			ctype = C_FLOAT8;
			*(double*)(buff + (*p)) = V;
			(*p) += sizeof(double);
		//}
		//else {
		//	ctype = C_FLOAT4;
		//	*(float*)(buff + (*p)) = V;
		//	(*p) += sizeof(float);
		//}
	}
	else if (v == (char)v) {
		ctype = C_INT1;
		*(char*)(buff + (*p)) = (char)v;
		(*p) += sizeof(char);
	}
	else if (v == (short)v) {
		ctype = C_INT2;
		*(short*)(buff + (*p)) = (short)v;
		(*p) += sizeof(short);
	}
	else if (v == (int)v) {
		ctype = C_INT4;
		*(int*)(buff + (*p)) = (int)v;
		(*p) += sizeof(int);
	}
	else {
		ctype = C_INT8;
		*(long long*)(buff + (*p)) = v;
		(*p) += sizeof(long long);
	}
	return ctype;
}
static unsigned char encode_str(lua_State *L, int idx, int *p, char *buff, int ref, int *refn)
{
	char ctype;
	size_t len;
	int isString = lua_isstring(L, idx);
	const char *s = lua_toBytes(L, idx, &len);
	if (len > MAX_STR_LEN)
		lua_errorEx(L, "encode string too long %d", len);

#ifdef USE_REF_TAB_AND_LONGSTR
	if (len >= STR_REF_LEN && encode_ref(L, idx, p, buff, ref, refn) == C_REF)
		return C_REF;
#endif
	if (isString) {
		if (len < 256) { //len=uchar
			ctype = C_STR1;
			*(unsigned char*)(buff + (*p)) = (unsigned char)len;
			(*p) += 1;
		}
		else if (len == (unsigned short)len) { //len=ushort
			ctype = C_STR2;
			*(unsigned short*)(buff + (*p)) = (unsigned short)len;
			(*p) += 2;
		}
		else { //len=int
			ctype = C_STR4;
			*(int*)(buff + (*p)) = (int)len;
			(*p) += 4;
		}
	}
	else {
		if (len > 0xffff)
			lua_errorEx(L, "encode string too long %d", len);
		ctype = C_ENCODED;
		*(unsigned short*)(buff + (*p)) = (unsigned short)len;
		(*p) += 2;
	}
	memcpy(buff+ *p, s, len);
	(*p) += len;
	return ctype;
}
static unsigned char encode_tab(lua_State *L, int idx, int *p, char *buff, int ref, int *refn)
{
#ifdef USE_REF_TAB_AND_LONGSTR
	if ( encode_ref(L, idx, p, buff, ref, refn) == C_REF)
		return C_REF;
#endif
	int top = lua_gettop(L);
	int tabn = 0;
	int pn = *p;
	(*p) += 4;
	for (lua_pushnil(L); lua_next(L, idx); lua_pop(L, 1))
	{
		if (lua_isnumber(L, -2)) { //numberkey must int*
			double V = lua_tonumber(L, -2);
			long long v = (long long)V;
			if (v != V || v != v << 10 >> 10)
				lua_errorEx(L, "number %f out of signed 54bit range", V);
		}
		encode(L, top+1, top+2, p, buff, ref, refn);
		tabn++;
	}
	*(int*)(buff + pn) = tabn;
	buff[(*p)++] = C_END;
	return C_TABLE;
}
static void encode(lua_State *L, int kidx, int vidx, int *p, char *buff, int ref, int *refn)
{
	unsigned char ktype = C_NIL;
	int kvtoffset = (*p)++;
	if (kidx != 0) {
		int kt = lua_type(L, kidx);
		switch (kt)
		{
		case LUA_TNUMBER:
			ktype = encode_num(L, kidx, p, buff);
			break;
		case LUA_TSTRING:
		case LUA_TUSERDATA:
			ktype = encode_str(L, kidx, p, buff, ref, refn);
			break;
		case LUA_TTABLE:
			ktype = encode_tab(L, kidx, p, buff, ref, refn);
			break;
		default:
			lua_errorEx(L, "unsurrpot encode ktype %s", lua_typename(L, kt));
			break;
		}
	}
	int vt = lua_type(L, vidx);
	switch (vt)
	{
	case LUA_TNIL:
		if (ktype==C_NIL) // not in table,in args
			buff[kvtoffset] = ktype << 4 | C_NIL;
		break;
	case LUA_TBOOLEAN:
		buff[kvtoffset] = ktype << 4 | (lua_toboolean(L, vidx) ? C_TRUE : C_FALSE);
		break;
	case LUA_TNUMBER:
		buff[kvtoffset] = ktype << 4 | encode_num(L, vidx, p, buff);
		break;
	case LUA_TSTRING:
	case LUA_TUSERDATA:
		buff[kvtoffset] = ktype << 4 | encode_str(L, vidx, p, buff, ref, refn);
		break;
	case LUA_TTABLE: 
		buff[kvtoffset] = ktype << 4 | encode_tab(L, vidx, p, buff, ref, refn);
		break;
	default:
		lua_errorEx(L, "unsurrpot encode vtype %s", lua_typename(L, vt));
		break;
	}
}

LUA_API int lua_encode(lua_State *L)
{
	if (lua_isnone(L, 1))
		lua_errorEx(L, "[C]invalid #1 no data to encode");

	int top = lua_gettop(L);
#ifdef USE_REF_TAB_AND_LONGSTR
	lua_createtable(L, 0, 100); //ref,use nrec because k is not serial number
#endif
	static char encodeBuffer[MAX_CODE_LEN + 1];
	int len = 0;
	int refn = 0;
	for (int i = 1; i <= top; i++)
		encode(L, 0, i, &len, encodeBuffer, top+1, &refn);
	encodeBuffer[len++] = C_END << 4;
	if (len > MAX_CODE_LEN)
		lua_errorEx(L, "encode string too long %d", len);
#ifdef LENONHEAD
	*(int*)(buff) = (int)len;
	len += 4;
#endif // LENONHEAD
	char *buff1 = (char*)lua_newBytes(L, len);
	memcpy(buff1, encodeBuffer, len);
	lua_pushinteger(L, len);
	return 2;
}

#ifdef USE_REF_TAB_AND_LONGSTR
static void decode_mem(lua_State *L, int midx) //记录引用
{
	lua_pushvalue(L, -1);
	lua_rawseti(L, midx, lua_objlen(L, midx) + 1);
}
static void decode_ref(lua_State *L, const char *s, size_t *pp, int midx)
{
	//lua_rawgeti(L, midx, (REF_LEN_TYPE)R32(s + *pp));
	lua_rawgeti(L, midx, *(REF_LEN_TYPE*)(s + *pp));
	(*pp) += sizeof(REF_LEN_TYPE);
}
#endif

static void decode_tab(lua_State *L, const char *s, size_t *pp, int midx)
{
	int n = R32(s + *pp);
	lua_createtable(L, 0, n);
#ifdef USE_REF_TAB_AND_LONGSTR
	decode_mem(L, midx);
#endif
	(*pp) += 4;
	unsigned char kvt, ktype, vtype;
	int lens;
	for (;;) {
		kvt = s[*pp];
		ktype = kvt >> 4;
		vtype = (unsigned char)(kvt << 4) >> 4;
		(*pp)++;
		if (kvt == C_END)  break;
		else{
			switch (ktype)	{
			case C_INT1: lua_pushnumber(L, (double)(char)s[*pp]); (*pp)++; break;
			case C_INT2: lua_pushnumber(L, (double)R16(s + *pp)); (*pp) += 2; break;
			case C_INT4: lua_pushnumber(L, (double)R32(s + *pp)); (*pp) += 4; break;
			case C_INT8: lua_pushnumber(L, (double)R64(s + *pp)); (*pp) += 8; break;
			case C_STR1:
				lens = (int)(unsigned char)s[*pp];
				(*pp)++;
				lua_pushlstring(L, s + *pp, lens);
#ifdef USE_REF_TAB_AND_LONGSTR
				if (lens >= STR_REF_LEN)  decode_mem(L, midx);
#endif
				(*pp) += lens;
				break;
			case C_STR2: 
				lens = (int)(unsigned short)R16(s + *pp);
				(*pp) += 2;
				lua_pushlstring(L, s + *pp, lens);
#ifdef USE_REF_TAB_AND_LONGSTR
				decode_mem(L, midx);
#endif
				(*pp) += lens;
				break;
			case C_STR4:
				lens = R32(s + *pp);
				(*pp) += 4;
				lua_pushlstring(L, s + *pp, lens);
#ifdef USE_REF_TAB_AND_LONGSTR
				decode_mem(L, midx);
#endif
				(*pp) += lens;
				break;
			case C_ENCODED:
				lens = (int)(unsigned short)R16(s + *pp);
				(*pp) += 2;
				char *data = lua_newBytes(L, lens);
				memcpy(data, s + *pp, lens);
				//lua_setBytesLen(L, -1, lens);
				decode_mem(L, midx);
				(*pp) += lens;
				break;
			case C_FLOAT4:	lua_pushnumber(L, (double)RFl(s + *pp));
				(*pp) += 4; break;
			case C_FLOAT8:	lua_pushnumber(L, RDb(s + *pp));
				(*pp) += 8; break;
			case C_TABLE:	decode_tab(L, s, pp, midx); break;
#ifdef USE_REF_TAB_AND_LONGSTR
			case C_REF:		decode_ref(L, s, pp, midx); break;
#endif
			default:
				lua_errorEx(L, "[C]invalid decode key type %d\n", ktype);
				break;
			}
			switch (vtype)	{
			case C_INT1: lua_pushnumber(L, (double)(char)s[*pp]); (*pp)++; break;
			case C_INT2: lua_pushnumber(L, (double)R16(s + *pp)); (*pp) += 2; break;
			case C_INT4: lua_pushnumber(L, (double)R32(s + *pp)); (*pp) += 4; break;
			case C_INT8: lua_pushnumber(L, (double)R64(s + *pp)); (*pp) += 8; break;
			case C_STR1: 
				lens = (int)(unsigned char)s[*pp];
				(*pp)++;
				lua_pushlstring(L, s + *pp, lens);
#ifdef USE_REF_TAB_AND_LONGSTR
				if (lens >= STR_REF_LEN)  decode_mem(L, midx);
#endif
				(*pp) += lens;
				break; 
			case C_STR2: 
				lens = (int)(unsigned short)R16(s + *pp);
				(*pp) += 2;
				lua_pushlstring(L, s + *pp, lens);
#ifdef USE_REF_TAB_AND_LONGSTR
				decode_mem(L, midx);
#endif
				(*pp) += lens;
				break; 
			case C_STR4: 
				lens = R32(s + *pp);
				(*pp) += 4;
				lua_pushlstring(L, s + *pp, lens);
#ifdef USE_REF_TAB_AND_LONGSTR
				decode_mem(L, midx);
#endif
				(*pp) += lens;
				break;
			case C_ENCODED:
				lens = (int)(unsigned short)R16(s + *pp);
				(*pp) += 2;
				char *data = lua_newBytes(L, lens);
				memcpy(data, s + *pp, lens);
				//lua_setBytesLen(L, -1, lens);
				decode_mem(L, midx);
				(*pp) += lens;
				break;
			case C_FLOAT4: lua_pushnumber(L, (double)RFl(s + *pp));
				(*pp) += 4;
				break;
			case C_FLOAT8: lua_pushnumber(L, RDb(s + *pp));
				(*pp) += 8;
				break;
			case C_TRUE:	lua_pushboolean(L, 1); break;
			case C_FALSE:	lua_pushboolean(L, 0); break;
			case C_TABLE:	decode_tab(L, s, pp, midx); break;
#ifdef USE_REF_TAB_AND_LONGSTR
			case C_REF:		decode_ref(L, s, pp, midx); break;
#endif
			default:
				lua_errorEx(L, "[C]invalid decode val type %d\n", vtype);
				break;
			}
			lua_rawset(L, -3);
		}
	}
}

LUA_API int lua_decode(lua_State *L)
{
	size_t len = 0;
#ifdef LENONHEAD
	const char *s;
	int type = lua_type(L, 1);
	switch (type) {
	case LUA_TSTRING:
		s = lua_tolstring(L, 1, &len);
		break;
	case LUA_TUSERDATA:{
		char *s0 = (char*)lua_touserdata(L, 1);
		len = (int)(*s0);
		s = s0 + 4;
		len -= 4;
		break;
	}
	default:
		lua_errorEx(L, "[C]invalid decode type %s", lua_typename(L, type));
		break;
	}
#else
	const char *s = (const char*)lua_toBytes(L, 1, &len);
#endif // LENONHEAD

	int lens;
#ifdef USE_REF_TAB_AND_LONGSTR
	lua_createtable(L, 64, 0); //reftab
#endif
	int top = lua_gettop(L);
	size_t p = 0;
	unsigned char kvt, ktype, vtype;
	while (p<len) {
		kvt = s[p];
		ktype = kvt >> 4;
		if (ktype == C_END)
			break;
		vtype = kvt << 4 >> 4;;
		p++; //type
		switch (vtype)	{
		case C_NIL:		lua_pushnil(L); break;
		case C_INT1:	lua_pushnumber(L, (double)(char)s[p]);	p++; break;
		case C_INT2:	lua_pushnumber(L, (double)R16(s + p));	p += 2; break;
		case C_INT4:	lua_pushnumber(L, (double)R32(s + p));	p += 4; break;
		case C_INT8:	lua_pushnumber(L, (double)R64(s + p));	p += 8; break;
		case C_STR1:
			lens = (int)(unsigned char)s[p]; p++;
			lua_pushlstring(L, s + p, lens);
#ifdef USE_REF_TAB_AND_LONGSTR
			if (lens >= STR_REF_LEN)  decode_mem(L, top);
#endif
			p += lens; break;
		case C_STR2:
			lens = (int)(unsigned short)R16(s + p); p += 2;
			lua_pushlstring(L, s + p, lens);
#ifdef USE_REF_TAB_AND_LONGSTR
			decode_mem(L, top);
#endif
			p += lens; break;
		case C_STR4:
			lens = (int)R32(s + p); p += 4;
			lua_pushlstring(L, s + p, lens);
#ifdef USE_REF_TAB_AND_LONGSTR
			decode_mem(L, top);
#endif
			p += lens; break;
		case C_ENCODED:
			lens = (int)(unsigned short)R16(s + p); p += 2;
			char *data = lua_newBytes(L, lens);
			memcpy(data, s + p, lens);
			//lua_setBytesLen(L, -1, lens);
			p += lens; break;
		case C_FLOAT4:	lua_pushnumber(L, (double)RFl(s + p));p += 4; break;
		case C_FLOAT8:	lua_pushnumber(L, RDb(s + p));	p += 8; break;
		case C_TRUE:	lua_pushboolean(L, 1); break;
		case C_FALSE:	lua_pushboolean(L, 0); break;
		case C_TABLE:	decode_tab(L, s, &p, top); break;
#ifdef USE_REF_TAB_AND_LONGSTR
		case C_REF:		decode_ref(L, s, &p, top); break;
#endif
		default:
			lua_errorEx(L, "[C]1invalid decode val type %d\n", vtype);
			break;
		}
	}
	return lua_gettop(L) - top;
}
