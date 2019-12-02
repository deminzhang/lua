 
#include "LuaString.h"  
#define F(x,y,z) ((x & y) | (~x & z))  
#define G(x,y,z) ((x & z) | (y & ~z))  
#define H(x,y,z) (x^y^z)  
#define I(x,y,z) (y ^ (x | ~z))  
#define ROTATE_LEFT(x,n) ((x << n) | (x >> (32-n)))  
#define FF(a,b,c,d,x,s,ac) { a += F(b,c,d) + x + ac; a = ROTATE_LEFT(a,s); a += b; }  
#define GG(a,b,c,d,x,s,ac) { a += G(b,c,d) + x + ac; a = ROTATE_LEFT(a,s); a += b; }  
#define HH(a,b,c,d,x,s,ac) { a += H(b,c,d) + x + ac; a = ROTATE_LEFT(a,s); a += b; }  
#define II(a,b,c,d,x,s,ac) { a += I(b,c,d) + x + ac; a = ROTATE_LEFT(a,s); a += b; }

typedef struct {
	unsigned int count[2];
	unsigned int state[4];
	unsigned char buffer[64];
}md5_state_t;
void md5_init(md5_state_t *context);
void md5_append(md5_state_t *context, unsigned char *input, unsigned inputlen);
void md5_finish(md5_state_t *context, unsigned char digest[16]);

unsigned char PADDING[] = { 0x80,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 };
static void MD5Encode(unsigned char *output, unsigned *input, unsigned len)
{
	unsigned i = 0, j = 0;
	while (j < len)
	{
		output[j] = input[i] & 0xFF;
		output[j + 1] = (input[i] >> 8) & 0xFF;
		output[j + 2] = (input[i] >> 16) & 0xFF;
		output[j + 3] = (input[i] >> 24) & 0xFF;
		i++;
		j += 4;
	}
}
static void MD5Decode(unsigned *output, unsigned char *input, unsigned len)
{
	unsigned i = 0, j = 0;
	while (j < len)
	{
		output[i] = (input[j]) |
			(input[j + 1] << 8) |
			(input[j + 2] << 16) |
			(input[j + 3] << 24);
		i++;
		j += 4;
	}
}
static void MD5Transform(unsigned state[4], unsigned char block[64])
{
	unsigned a = state[0];
	unsigned b = state[1];
	unsigned c = state[2];
	unsigned d = state[3];
	unsigned x[64];
	MD5Decode(x, block, 64);
	FF(a, b, c, d, x[0], 7, 0xd76aa478); /* 1 */
	FF(d, a, b, c, x[1], 12, 0xe8c7b756); /* 2 */
	FF(c, d, a, b, x[2], 17, 0x242070db); /* 3 */
	FF(b, c, d, a, x[3], 22, 0xc1bdceee); /* 4 */
	FF(a, b, c, d, x[4], 7, 0xf57c0faf); /* 5 */
	FF(d, a, b, c, x[5], 12, 0x4787c62a); /* 6 */
	FF(c, d, a, b, x[6], 17, 0xa8304613); /* 7 */
	FF(b, c, d, a, x[7], 22, 0xfd469501); /* 8 */
	FF(a, b, c, d, x[8], 7, 0x698098d8); /* 9 */
	FF(d, a, b, c, x[9], 12, 0x8b44f7af); /* 10 */
	FF(c, d, a, b, x[10], 17, 0xffff5bb1); /* 11 */
	FF(b, c, d, a, x[11], 22, 0x895cd7be); /* 12 */
	FF(a, b, c, d, x[12], 7, 0x6b901122); /* 13 */
	FF(d, a, b, c, x[13], 12, 0xfd987193); /* 14 */
	FF(c, d, a, b, x[14], 17, 0xa679438e); /* 15 */
	FF(b, c, d, a, x[15], 22, 0x49b40821); /* 16 */

										   /* Round 2 */
	GG(a, b, c, d, x[1], 5, 0xf61e2562); /* 17 */
	GG(d, a, b, c, x[6], 9, 0xc040b340); /* 18 */
	GG(c, d, a, b, x[11], 14, 0x265e5a51); /* 19 */
	GG(b, c, d, a, x[0], 20, 0xe9b6c7aa); /* 20 */
	GG(a, b, c, d, x[5], 5, 0xd62f105d); /* 21 */
	GG(d, a, b, c, x[10], 9, 0x2441453); /* 22 */
	GG(c, d, a, b, x[15], 14, 0xd8a1e681); /* 23 */
	GG(b, c, d, a, x[4], 20, 0xe7d3fbc8); /* 24 */
	GG(a, b, c, d, x[9], 5, 0x21e1cde6); /* 25 */
	GG(d, a, b, c, x[14], 9, 0xc33707d6); /* 26 */
	GG(c, d, a, b, x[3], 14, 0xf4d50d87); /* 27 */
	GG(b, c, d, a, x[8], 20, 0x455a14ed); /* 28 */
	GG(a, b, c, d, x[13], 5, 0xa9e3e905); /* 29 */
	GG(d, a, b, c, x[2], 9, 0xfcefa3f8); /* 30 */
	GG(c, d, a, b, x[7], 14, 0x676f02d9); /* 31 */
	GG(b, c, d, a, x[12], 20, 0x8d2a4c8a); /* 32 */

										   /* Round 3 */
	HH(a, b, c, d, x[5], 4, 0xfffa3942); /* 33 */
	HH(d, a, b, c, x[8], 11, 0x8771f681); /* 34 */
	HH(c, d, a, b, x[11], 16, 0x6d9d6122); /* 35 */
	HH(b, c, d, a, x[14], 23, 0xfde5380c); /* 36 */
	HH(a, b, c, d, x[1], 4, 0xa4beea44); /* 37 */
	HH(d, a, b, c, x[4], 11, 0x4bdecfa9); /* 38 */
	HH(c, d, a, b, x[7], 16, 0xf6bb4b60); /* 39 */
	HH(b, c, d, a, x[10], 23, 0xbebfbc70); /* 40 */
	HH(a, b, c, d, x[13], 4, 0x289b7ec6); /* 41 */
	HH(d, a, b, c, x[0], 11, 0xeaa127fa); /* 42 */
	HH(c, d, a, b, x[3], 16, 0xd4ef3085); /* 43 */
	HH(b, c, d, a, x[6], 23, 0x4881d05); /* 44 */
	HH(a, b, c, d, x[9], 4, 0xd9d4d039); /* 45 */
	HH(d, a, b, c, x[12], 11, 0xe6db99e5); /* 46 */
	HH(c, d, a, b, x[15], 16, 0x1fa27cf8); /* 47 */
	HH(b, c, d, a, x[2], 23, 0xc4ac5665); /* 48 */

										  /* Round 4 */
	II(a, b, c, d, x[0], 6, 0xf4292244); /* 49 */
	II(d, a, b, c, x[7], 10, 0x432aff97); /* 50 */
	II(c, d, a, b, x[14], 15, 0xab9423a7); /* 51 */
	II(b, c, d, a, x[5], 21, 0xfc93a039); /* 52 */
	II(a, b, c, d, x[12], 6, 0x655b59c3); /* 53 */
	II(d, a, b, c, x[3], 10, 0x8f0ccc92); /* 54 */
	II(c, d, a, b, x[10], 15, 0xffeff47d); /* 55 */
	II(b, c, d, a, x[1], 21, 0x85845dd1); /* 56 */
	II(a, b, c, d, x[8], 6, 0x6fa87e4f); /* 57 */
	II(d, a, b, c, x[15], 10, 0xfe2ce6e0); /* 58 */
	II(c, d, a, b, x[6], 15, 0xa3014314); /* 59 */
	II(b, c, d, a, x[13], 21, 0x4e0811a1); /* 60 */
	II(a, b, c, d, x[4], 6, 0xf7537e82); /* 61 */
	II(d, a, b, c, x[11], 10, 0xbd3af235); /* 62 */
	II(c, d, a, b, x[2], 15, 0x2ad7d2bb); /* 63 */
	II(b, c, d, a, x[9], 21, 0xeb86d391); /* 64 */
	state[0] += a;
	state[1] += b;
	state[2] += c;
	state[3] += d;
}
void md5_init(md5_state_t *context)
{  
     context->count[0] = 0;  
     context->count[1] = 0;  
     context->state[0] = 0x67452301;  
     context->state[1] = 0xEFCDAB89;  
     context->state[2] = 0x98BADCFE;  
     context->state[3] = 0x10325476;  
}  
void md5_append(md5_state_t *context,unsigned char *input,unsigned inputlen)
{  
    unsigned i = 0,index = 0,partlen = 0;  
    index = (context->count[0] >> 3) & 0x3F;  
    partlen = 64 - index;  
    context->count[0] += inputlen << 3;  
    if(context->count[0] < (inputlen << 3))  
       context->count[1]++;  
    context->count[1] += inputlen >> 29;  
      
    if(inputlen >= partlen)  
    {  
       memcpy(&context->buffer[index],input,partlen);  
       MD5Transform(context->state,context->buffer);  
       for(i = partlen;i+64 <= inputlen;i+=64)  
           MD5Transform(context->state,&input[i]);  
       index = 0;          
    }    
    else  
    {  
        i = 0;  
    }  
    memcpy(&context->buffer[index],&input[i],inputlen-i);  
}  
void md5_finish(md5_state_t *context,unsigned char digest[16])
{  
    unsigned index = 0,padlen = 0;  
    unsigned char bits[8];  
    index = (context->count[0] >> 3) & 0x3F;  
    padlen = (index < 56)?(56-index):(120-index);  
    MD5Encode(bits,context->count,8);  
    md5_append(context,PADDING,padlen);  
    md5_append(context,bits,8);  
    MD5Encode(digest,context->state,16);  
}  
static void mdBytes(unsigned char pre[64], unsigned char bytes[], size_t first, size_t last1, unsigned char Re[16])
{
	md5_state_t state;
	md5_init(&state);
	if (pre)
		md5_append(&state, pre, 64);
	md5_append(&state, bytes + first, last1 - first);
	md5_finish(&state, Re);
}
static int lua_md5(lua_State *L) {
	size_t n, i, j;
	unsigned char *s = (unsigned char*)lua_toBytes(L, 1, &n);
	int first = luaL_optinteger(L, 2, 1);
	int last = luaL_optinteger(L, 3, -1);
	i = indexn0(first, n);
	j = indexn(last, n);
	i > j && (j = i);

	md5_state_t state;
	unsigned char digest[16];
	md5_init(&state);
	md5_append(&state, s+i, j-i);
	md5_finish(&state, digest);
	if (lua_toboolean(L, 4)) {
		lua_pushlstring(L, digest, 16);
		return 1;
	}
	char md5[33];
	sprintf(md5, "%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x\0",
		digest[0], digest[1], digest[2], digest[3], digest[4], digest[5], digest[6], digest[7], digest[8],
		digest[9], digest[10], digest[11], digest[12], digest[13], digest[14], digest[15]);
	lua_pushstring(L, md5);
	return 1;
}
static int lua_md5sum(lua_State *L) {
	const char *fn = lua_tostring(L, 1);
	FILE *fp = fopen(fn, "rb");
	if (!fp)
		lua_errorEx(L, "_md5sum open file fail:%s\n", fn);

	unsigned char ReadBuffer[65536];
	size_t ReadBytes = 0;
	md5_state_t state;
	unsigned char digest[16];
	md5_init(&state);
	for(;;)	{
		ReadBytes = fread(ReadBuffer, 1, 65536, fp);
		if (ReadBytes > 0)
			md5_append(&state, (unsigned char *)ReadBuffer, ReadBytes);
		if (feof(fp)){
			md5_finish(&state, digest);
			break;
		}
	}
	fclose(fp);
	fp = NULL;
	if (lua_toboolean(L, 2)) {
		lua_pushlstring(L, digest, 16);
		return 1;
	}
	char md5[33];
	sprintf(md5, "%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x\0",
		digest[0], digest[1], digest[2], digest[3], digest[4], digest[5], digest[6], digest[7], digest[8],
		digest[9], digest[10], digest[11], digest[12], digest[13], digest[14], digest[15]);
	lua_pushstring(L, md5);
	return 1;
}
static int lua_str_hmacmd5(lua_State *L)
{
	size_t n, i, j, kn;
	unsigned char *s = (unsigned char*)lua_toBytes(L, 1, &n);
	unsigned char *ks = (unsigned char*)lua_toBytes(L, 2, &kn);
	int first = luaL_optinteger(L, 3, 1);
	int last = luaL_optinteger(L, 4, -1);
	i = indexn0(first, n);
	j = indexn(last, n);

	unsigned char key[64], keyi[64], rei[16];
	if (kn > 64) {
		mdBytes(NULL, ks, 0, kn, key);
		memset(key + 16, 0, 48);
	}
	else {
		memcpy(key, ks, kn);
		memset(key + kn, 0, 64 - kn);
	}
	for (int d = 0; d < 64; d++)
		keyi[d] = key[d] ^ 0x36;
	for (int d = 0; d < 64; d++)
		key[d] ^= 0x5c;
	mdBytes(keyi, s, i, i <= j ? j : i, rei);
	unsigned char re[16];
	mdBytes(key, rei, 0, 16, re);
	if (lua_toboolean(L, 5)) {
		lua_pushlstring(L, re, 16);
		return 1;
	}
	char hex[40];
	for (int d = 0; d < 16; d++)
		hex[d + d] = "0123456789abcdef"[re[d] >> 4 & 15],
		hex[d + d + 1] = "0123456789abcdef"[re[d] & 15];
	lua_pushlstring(L, hex, 32);
	return 1;
}
static void shaRounds(unsigned char x[64], unsigned re[5])
{
	unsigned char bx[320] = {
		x[3],x[2],x[1],x[0], x[7],x[6],x[5],x[4], x[11],x[10],x[9],x[8], x[15],x[14],x[13],x[12],
		x[19],x[18],x[17],x[16], x[23],x[22],x[21],x[20], x[27],x[26],x[25],x[24], x[31],x[30],x[29],x[28],
		x[35],x[34],x[33],x[32], x[39],x[38],x[37],x[36], x[43],x[42],x[41],x[40], x[47],x[46],x[45],x[44],
		x[51],x[50],x[49],x[48], x[55],x[54],x[53],x[52], x[59],x[58],x[57],x[56], x[63],x[62],x[61],x[60],
	};
	unsigned *w = (unsigned *)bx;
	for (unsigned W, i = 16; i < 80; i++)
		W = w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16],
		w[i] = (W << 1) | (W >> 31);
	unsigned a = re[0], b = re[1], c = re[2], d = re[3], e = re[4], f, t;
	for (int i = 0; i < 20; i++)
		f = (b & c) | (~b & d),
		t = ((a << 5) | (a >> 27)) + f + e + 0x5A827999 + w[i],
		e = d, d = c, c = (b << 30) | (b >> 2), b = a, a = t;
	for (int i = 20; i < 40; i++)
		f = b ^ c ^ d,
		t = ((a << 5) | (a >> 27)) + f + e + 0x6ED9EBA1 + w[i],
		e = d, d = c, c = (b << 30) | (b >> 2), b = a, a = t;
	for (int i = 40; i < 60; i++)
		f = (b & c) | (d & (b | c)),
		t = ((a << 5) | (a >> 27)) + f + e + 0x8F1BBCDC + w[i],
		e = d, d = c, c = (b << 30) | (b >> 2), b = a, a = t;
	for (int i = 60; i < 80; i++)
		f = b ^ c ^ d,
		t = ((a << 5) | (a >> 27)) + f + e + 0xCA62C1D6 + w[i],
		e = d, d = c, c = (b << 30) | (b >> 2), b = a, a = t;
	re[0] += a, re[1] += b, re[2] += c, re[3] += d, re[4] += e;
}
static void shaBytes(unsigned char pre[64], unsigned char bytes[], size_t first, size_t last1, unsigned char Re[20])
{
	unsigned re[5];
	re[0] = 0x67452301, re[1] = 0xEFCDAB89, re[2] = 0x98BADCFE, re[3] = 0x10325476, re[4] = 0xC3D2E1F0;
	unsigned char x[64];
	size_t d;
	if (pre)
		shaRounds(pre, re);
	for (d = first; d + 63 < last1; d += 64)
		shaRounds(bytes + d, re);
	memcpy(x, bytes + d, last1 - d), d = last1 - d;
	memset(x + d, 0, 4 - d % 4), x[d] = 0x80, d += 4 - d % 4; // append bit 1
	if (d > 56)
		memset(x + d, 0, 64 - d), shaRounds(x, re), d = 0;
	if (d < 56)
		memset(x + d, 0, 56 - d);
	((long long*)x)[7] = (long long)(last1 - first + (pre ? 64 : 0)) << 3;
	unsigned char be[8] = { x[63], x[62], x[61], x[60], x[59], x[58], x[57], x[56] };
	((long long*)x)[7] = *(long long*)be;
	shaRounds(x, re);
	unsigned char *l = (unsigned char *)re;
	unsigned char L[20] = { l[3],l[2],l[1],l[0], l[7],l[6],l[5],l[4], l[11],l[10],l[9],l[8],
		l[15],l[14],l[13],l[12], l[19],l[18],l[17],l[16] };
	memcpy(Re, L, 20);
}
static void shaHex(unsigned char bytes[], size_t first, size_t last1, char hex[40])
{
	unsigned char re[20];
	shaBytes(NULL, bytes, first, last1, re);
	for (int d = 0; d < 20; d++) {
		hex[d + d] = "0123456789abcdef"[re[d] >> 4 & 15];
		hex[d + d + 1] = "0123456789abcdef"[re[d] & 15];
	}
}
static int str_sha1(lua_State *L)
{
	size_t n, i, j;
	unsigned char *s = (unsigned char*)lua_toBytes(L, 1, &n);
	int first = luaL_optinteger(L, 2, 1);
	int last = luaL_optinteger(L, 3, -1);

	i = indexn0(first, n);
	j = indexn(last, n);
	i > j && (j = i);

	if (lua_toboolean(L, 4)){
		unsigned char re[20];
		shaBytes(NULL, s, i, j, re);
		lua_pushlstring(L, re, 20);
		return 1;
	}
	char hex[40];
	shaHex(s, i, i <= j ? j : i, hex);
	lua_pushlstring(L, hex, 40);
	return 1;
}
static int str_hmacsha1(lua_State *L)
{
	size_t n, i, j, kn;
	unsigned char *s = (unsigned char*)lua_toBytes(L, 1, &n);
	unsigned char *ks = (unsigned char*)lua_toBytes(L, 2, &kn);
	int first = luaL_optinteger(L, 3, 1);
	int last = luaL_optinteger(L, 4, -1);
	i = indexn0(first, n);
	j = indexn(last, n);

	unsigned char key[64], keyi[64], rei[20];
	if (kn > 64)
		shaBytes(NULL, ks, 0, kn, key), memset(key + 16, 0, 48);
	else
		memcpy(key, ks, kn), memset(key + kn, 0, 64 - kn);
	for (int d = 0; d < 64; d++)
		keyi[d] = key[d] ^ 0x36;
	for (int d = 0; d < 64; d++)
		key[d] ^= 0x5c;
	shaBytes(keyi, s, i, i <= j ? j : i, rei);
	if (lua_toboolean(L, 5)){
		unsigned char re[20];
		shaBytes(key, rei, 0, 20, re);
		lua_pushlstring(L, re, 20);
		return 1;
	}
	unsigned char re[20]; char hex[40];
	shaBytes(key, rei, 0, 20, re);
	for (int d = 0; d < 20; d++)
		hex[d + d] = "0123456789abcdef"[re[d] >> 4 & 15],
		hex[d + d + 1] = "0123456789abcdef"[re[d] & 15];
	lua_pushlstring(L, hex, 40);
	return 1;
}
static int lua_str_ucs(lua_State *L)
{
	size_t n; unsigned char *cs = (unsigned char*)lua_toBytes(L, 1, &n);
	size_t i = indexn0(luaL_optint(L, 2, 1), n);
	size_t j = indexn(luaL_optint(L, 3, -1), n);
	int bdata = lua_isboolean(L, 4);
	unsigned char *c, *cj = cs + j;
	for (n = 0, c = cs + i; c < cj; c++)
		(*c <= 0x7f || *c >= 0xc0) && (n += 2);
	if (lua_isstring(L, 4) && lua_tostring(L, 4)[0] == 'c')
	{
		for (c = cs + i; c < cj; )
			if (*c <= 0x7f)
				lua_pushinteger(L, *c++);
			else if (*c >= 0xe0){
				lua_pushinteger(L, c[0] - 0xe0 << 12 | c[1] - 0x80 << 6 | c[2] - 0x80);
				c += 3;
			}
			else if (*c >= 0xc0) {
				lua_pushinteger(L, c[0] - 0xc0 << 6 | c[1] - 0x80);
				c += 2;
			}
			else
				c++;
		return n >> 1;
	}
	unsigned short *ws = (unsigned short*)malloc(n);
	unsigned short *w;
	for (c = cs + i, w = ws; c < cj; )
		if (*c <= 0x7f)
			*w++ = *c++;
		else if (*c >= 0xe0) {
			*w++ = c[0] - 0xe0 << 12 | c[1] - 0x80 << 6 | c[2] - 0x80;
			c += 3;
		}
		else if (*c >= 0xc0) {
			*w++ = c[0] - 0xc0 << 6 | c[2] - 0x80;
			c += 2;
		}
		else
			c++;
	if (!bdata)
		lua_pushlstring(L, (char*)ws, n);
	free(ws);
	return 1;
}
static int lua_str_utf(lua_State *L)
{
	size_t n; unsigned short *ws = (unsigned short*)lua_toBytes(L, 1, &n);
	size_t i = indexn0(luaL_optint(L, 2, 1), n >> 1);
	size_t j = indexn(luaL_optint(L, 3, -1), n >> 1);
	int bdata = lua_isboolean(L, 4);
	unsigned short *w, *wj = ws + j;
	for (n = 0, w = ws + i; w < wj; w++)
		n += *w <= 0x7f ? 1 : *w <= 0x7ff ? 2 : 3;
	char *cs = (char*)malloc(n), *c;
	for (w = ws + i, c = cs; w < wj; w++)
		*w <= 0x7f ? *c++ = (char)*w
		: *w <= 0x7ff ? (*c++ = (char)(*w >> 6 | 0xc0), *c++ = (char)(*w & 0x3f | 0x80))
		: (*c++ = (char)(*w >> 12 | 0xe0), *c++ = (char)(*w >> 6 & 0x3f | 0x80), *c++ = (char)(*w & 0x3f | 0x80));
	if (!bdata)
		lua_pushlstring(L, cs, n);
	free(cs);
	return 1;
}
static int lua_str_to16l(lua_State *L) {
	size_t len = 0;
	const char *s = lua_toBytes(L, 1, &len);
	int first = luaL_optint(L, 2, 1);
	short v = R16(s + first - 1);
	int bSigned = lua_toboolean(L, 3);
	if(bSigned)
		lua_pushinteger(L, v);
	else
		lua_pushnumber(L, (unsigned)v);
	return 1;
}
static int lua_str_to16b(lua_State *L) {
	size_t len = 0;
	char *s0 = (char *)lua_toBytes(L, 1, &len);
	int first = luaL_optint(L, 2, 1);
	short v = R16l(s0 + first - 1);
	int bSigned = lua_toboolean(L, 3);
	if (bSigned)
		lua_pushinteger(L, v);
	else
		lua_pushnumber(L, (unsigned)v);
	return 1;
}
static int lua_str_to32l(lua_State *L) {
	size_t len = 0;
	const char *s = lua_toBytes(L, 1, &len);
	int first = luaL_optint(L, 2, 1);
	int v = R32(s + first - 1);
	int bSigned = lua_toboolean(L, 3);
	if (bSigned)
		lua_pushinteger(L, v);
	else
		lua_pushnumber(L, (unsigned)v);
	return 1;
}
static int lua_str_to32b(lua_State *L) {
	size_t len = 0;
	char *s0 = (char *)lua_toBytes(L, 1, &len);
	int first = luaL_optint(L, 2, 1);
	int v = R32l(s0 + first - 1);
	int bSigned = lua_toboolean(L, 3);
	if (bSigned)
		lua_pushinteger(L, v);
	else
		lua_pushnumber(L, (unsigned)v);
	return 1;
}
static int lua_str_to64l(lua_State *L) {
	size_t len = 0;
	const char *s = lua_toBytes(L, 1, &len);
	int first = luaL_optint(L, 2, 1);
	long long v = R64(s + first - 1);
	int bSigned = lua_toboolean(L, 3);
	if (bSigned)
		lua_pushnumber(L, v);
	else
		lua_pushnumber(L, (unsigned)v);
	return 1;
}
static int lua_str_to64b(lua_State *L) {
	size_t len = 0;
	char *s0 = (char *)lua_toBytes(L, 1, &len);
	int first = luaL_optint(L, 2, 1);
	long long v = R64l(s0 + first - 1);
	int bSigned = lua_toboolean(L, 3);
	if (bSigned)
		lua_pushnumber(L, v);
	else
		lua_pushnumber(L, (unsigned)v);
	return 1;
}
static int lua_str_from16l(lua_State *L) {
	int n = luaL_checkint(L, 1);
	const char *s = (const char*)&n;
	lua_pushlstring(L, s, 2);
	return 1;
}
static int lua_str_from16b(lua_State *L) {
	int n = luaL_checkint(L, 1);
	const char *s = (const char*)&n;
	char S[] = { s[1],s[0] };
	lua_pushlstring(L, S, 2);
	return 1;
}
static int lua_str_from32l(lua_State *L) {
	int n = luaL_checkint(L, 1);
	const char *s = (const char*)&n;
	lua_pushlstring(L, s, 4);
	return 1;
}
static int lua_str_from32b(lua_State *L) {
	int n = luaL_checkint(L, 1);
	const char *s = (const char*)&n;
	char S[] = { s[3],s[2],s[1],s[0] };
	lua_pushlstring(L, S, 4);
	return 1;
}
static int lua_str_from64l(lua_State *L) {
	int n = luaL_checkint(L, 1);
	const char *s = (const char*)&n;
	lua_pushlstring(L, s, 8);
	return 1;
}
static int lua_str_from64b(lua_State *L) {
	int n = luaL_checkint(L, 1);
	const char *s = (const char*)&n;
	char S[] = { s[7],s[6],s[5],s[4],s[3],s[2],s[1],s[0] };
	lua_pushlstring(L, S, 4);
	return 1;
}
static int lua_str_enurl(lua_State *L) {
	size_t len = 0;
	unsigned char *s = (unsigned char *)lua_toBytes(L, 1, &len);
	unsigned char *c;
	unsigned char *to = s + len;
	size_t n = 0;
	for (c = s; c < to; c++)
		if (*c >= '0' && *c <= '9' || *c >= 'A' && *c <= 'Z' || *c >= 'a' && *c <= 'z' || *c == '-' || *c == '_' || *c == '.')
			n += 1;
		else
			n += 3;
	unsigned char *es = (unsigned char*)malloc(n);
	unsigned char *e;
	for (c = s, e = es; c < to; )
		if (*c >= '0' && *c <= '9' || *c >= 'A' && *c <= 'Z' || *c >= 'a' && *c <= 'z' || *c == '-' || *c == '_' || *c == '.')
			(void)(*e++ = *c++);
		else
			(*e++ = '%', *e++ = "0123456789ABCDEF"[*c >> 4 & 15], *e++ = "0123456789ABCDEF"[*c & 15], c++);
	lua_pushlstring(L, (char*)es, n);
	free(es);
	return 1;
}
static int lua_str_deurl(lua_State *L) {
	size_t len = 0;
	unsigned char *es = (unsigned char *)lua_toBytes(L, 1, &len);
	size_t n = 0;
	unsigned char *e, *ej = es + len;
	for (e = es; e < ej; n++)
		e += *e == '%' ? 3 : 1;
	unsigned char *s = (unsigned char*)malloc(n);
	unsigned char *c;
	for (e = es, c = s; e < ej; )
		if (*e != '%')
			(void)(*c++ = *e++);
		else if (e + 3 > ej)
			(*c++ = '%', e += 3);
		else
			(*c++ = (char)((e[1] >= 'A' ? e[1] - 'A' + 10 : e[1] - '0') << 4 | (e[2] >= 'A' ? e[2] - 'A' + 10 : e[2] - '0') & 15), e += 3);
	lua_pushlstring(L, (char*)s, n);
	free(s);
	return 1;
}
static int lua_str_enbase64(lua_State *L){
	size_t n;
	unsigned char *s = (unsigned char*)lua_toBytes(L, 1, &n);
	size_t i = indexn0(luaL_optint(L, 2, 1), n);
	size_t j = indexn(luaL_optint(L, 3, -1), n);
	int bdata = lua_toboolean(L, 4);
	char S[66] = { "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=" };
	lua_isstring(L, 5) && memcpy(S + 62, lua_tostring(L, 5), lua_objlen(L, 5) < 3 ? lua_objlen(L, 5) : 3);
	const char *pad = lua_isstring(L, 5) && lua_objlen(L, 5) < 3 ? NULL : S + 64;
	n = i < j ? j - i : 0, n = pad ? (n + 2) / 3 << 2 : n / 3 * 4 + (n % 3 * 8 + 5) / 6;
	unsigned char *c, *cj = s + j;
	unsigned char *es = (unsigned char*)malloc(n);
	unsigned char *e;
	for (c = s + i, e = es; c < cj - 2; c += 3)
		*e++ = S[c[0] >> 2], *e++ = S[(c[0] & 3) << 4 | c[1] >> 4],
		*e++ = S[(c[1] & 15) << 2 | c[2] >> 6], *e++ = S[c[2] & 63];
	if (c == cj - 1)
		*e++ = S[c[0] >> 2], *e++ = S[(c[0] & 3) << 4], pad && (*e++ = *pad, *e++ = *pad);
	else if (c == cj - 2)
		*e++ = S[c[0] >> 2], *e++ = S[(c[0] & 3) << 4 | c[1] >> 4],
		*e++ = S[(c[1] & 15) << 2], pad && (*e++ = *pad);
	if (!bdata)
		lua_pushlstring(L, (char*)es, n);
	free(es);
	return 1;
}
static int lua_str_debase64(lua_State *L){
	size_t n; unsigned char *es = (unsigned char*)lua_toBytes(L, 1, &n);
	size_t i = indexn0(luaL_optint(L, 2, 1), n);
	size_t j = indexn(luaL_optint(L, 3, -1), n);
	int bdata = lua_toboolean(L, 4);
	const char *mode = lua_tostring(L, 5);
	const char *pad = mode ? lua_objlen(L, 5) < 3 ? NULL : mode + 2 : "=";
	pad && i < j && es[j - 1] == *pad && j--, pad && i < j && es[j - 1] == *pad && j--;
	unsigned char S[256];
	memset(S, 0, 256);
	S[mode && lua_objlen(L, 5) > 1 ? mode[1] : '/'] = 63;
	S[mode && lua_objlen(L, 5) > 0 ? mode[0] : '+'] = 62;
	for (unsigned char x = 0; x < 62; x++)
		S["ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"[x]] = x;
	n = i < j ? j - i : 0, n = n / 4 * 3 + (n % 4 * 6 + 2) / 8;
	unsigned char *e, *ej = es + j;
	unsigned char *s = (unsigned char*)malloc(n);
	unsigned char *c;
	for (e = es + i, c = s; e < ej - 3; e += 4)
		*c++ = S[e[0]] << 2 | S[e[1]] >> 4, *c++ = (S[e[1]] & 15) << 4 | S[e[2]] >> 2,
		*c++ = (S[e[2]] & 3) << 6 | S[e[3]];
	if (e == ej - 1)
		*c++ = S[e[0]] << 2;
	else if (e == ej - 2)
		*c++ = S[e[0]] << 2 | S[e[1]] >> 4;
	else if (e == ej - 3)
		*c++ = S[e[0]] << 2 | S[e[1]] >> 4, *c++ = (S[e[1]] & 15) << 4 | S[e[2]] >> 2;
	if (!bdata)
		lua_pushlstring(L, (char*)s, n);
	free(s);
	return 1;
}
static int lua_str_lead(lua_State *L)
{
	size_t len; unsigned char *s = (unsigned char*)lua_toBytes(L, 1, &len);
	size_t l2; unsigned char *s2 = (unsigned char*)lua_toBytes(L, 2, &l2);
	lua_pushboolean(L, len >= l2 && memcmp(s, s2, l2) == 0);
	return 1;
}
static int lua_str_tail(lua_State *L)
{
	size_t len; unsigned char *s = (unsigned char*)lua_toBytes(L, 1, &len);
	size_t l2; unsigned char *s2 = (unsigned char*)lua_toBytes(L, 2, &l2);
	lua_pushboolean(L, len >= l2 && memcmp(s + len - l2, s2, l2) == 0);
	return 1;
}
static int lua_str_xor(lua_State *L)
{
	size_t n; unsigned char *s = (unsigned char*)lua_toBytes(L, 1, &n);
	size_t n2; unsigned char *s2 = (unsigned char*)lua_toBytes(L, 2, &n2);
	char *r = (char*)malloc(n);
	for (unsigned i = 0; i < n; i++)
		r[i] = s[i] ^ s2[i % n2];
	lua_pushlstring(L, r, n);
	free(r);
	return 1;
}
//static int lua_str_tobyte(lua_State *L)
//{
//	size_t l; unsigned char *s = (unsigned char*)lua_toBytes(L, 1, &l);
//	size_t i = indexn0(luaL_optint(L, 2, 1), l);
//	
//}
static int lua_bytes_tostr(lua_State *L)
{
	if (lua_isstring(L, 1))
		return 1;
	size_t len; unsigned char *s = (unsigned char*)lua_toBytes(L, 1, &len);
	size_t i = indexn0(luaL_optint(L, 2, 1), len);
	size_t j = indexn(luaL_optint(L, 3, -1), len);
	lua_pushlstring(L, s, len);
	return 1;
}
//reg2lua-------------------------------------------------------
void lua_openstringEx(lua_State *L)
{
	lua_register(L, "_md5sum", lua_md5sum);
	lua_getglobal(L, "string");
	lua_pushcfunction(L, lua_str_to16l);
	lua_setfield(L, -2, "to16l");
	lua_pushcfunction(L, lua_str_to16b);
	lua_setfield(L, -2, "to16b");
	lua_pushcfunction(L, lua_str_to32l);
	lua_setfield(L, -2, "to32l");
	lua_pushcfunction(L, lua_str_to32b);
	lua_setfield(L, -2, "to32b");
	lua_pushcfunction(L, lua_str_to64l);
	lua_setfield(L, -2, "to64l");
	lua_pushcfunction(L, lua_str_to64b);
	lua_setfield(L, -2, "to64b");
	lua_pushcfunction(L, lua_str_from16l);
	lua_setfield(L, -2, "from16l");
	lua_pushcfunction(L, lua_str_from16b);
	lua_setfield(L, -2, "from16b");
	lua_pushcfunction(L, lua_str_from32l);
	lua_setfield(L, -2, "from32l");
	lua_pushcfunction(L, lua_str_from32b);
	lua_setfield(L, -2, "from32b");
	lua_pushcfunction(L, lua_str_from64l);
	lua_setfield(L, -2, "from64l");
	lua_pushcfunction(L, lua_str_from64b);
	lua_setfield(L, -2, "from64b");
	lua_pushcfunction(L, lua_str_enurl);
	lua_setfield(L, -2, "enurl");
	lua_pushcfunction(L, lua_str_deurl);
	lua_setfield(L, -2, "deurl");
	lua_pushcfunction(L, lua_str_enbase64);
	lua_setfield(L, -2, "enbase64");
	lua_pushcfunction(L, lua_str_debase64);
	lua_setfield(L, -2, "debase64");
	lua_pushcfunction(L, lua_md5);
	lua_setfield(L, -2, "md5");
	lua_pushcfunction(L, lua_str_hmacmd5);
	lua_setfield(L, -2, "hmacmd5");
	lua_pushcfunction(L, str_sha1);
	lua_setfield(L, -2, "sha1");
	lua_pushcfunction(L, str_hmacsha1);
	lua_setfield(L, -2, "hmacsha1");
	lua_pushcfunction(L, lua_str_ucs);
	lua_setfield(L, -2, "ucs");
	lua_pushcfunction(L, lua_str_utf);
	lua_setfield(L, -2, "utf");
	lua_pushcfunction(L, lua_str_lead);
	lua_setfield(L, -2, "lead");
	lua_pushcfunction(L, lua_str_tail);
	lua_setfield(L, -2, "tail");
	lua_pushcfunction(L, lua_str_xor);
	lua_setfield(L, -2, "xor");
	lua_pushcfunction(L, lua_bytes_tostr);
	lua_setfield(L, -2, "tostr"); 
	
	lua_pop(L, 1);
}
