#ifndef _BASE_H_
#define _BASE_H_

//#define LUA_LIB
//misc---------------------------------------------------------
//#ifndef BOOL
//	#define BOOL unsigned char
//	#define TRUE 1
//	#define FALSE 0
//#endif
//#ifndef __cplusplus
//	#define bool BOOL
//	#define true TRUE
//	#define false FALSE
//#endif
#if __linux
	#ifndef __USE_BSD
		#define __USE_BSD
	#endif
	#ifndef __USE_MISC
		#define __USE_MISC
	#endif
#elif __APPLE__ & __MACH__
	#define _MAC
#elif _WIN32
	#define usleep(us) Sleep(us/1000)
#else
	#error "unsupport os"
#endif


//base------------------------------------------------------------
//pqint2 SNNNNNNN NNNNNNNN
//pqint4 SNNNNNNN NNNNNNNN NNNNNNNN NNNNNNNN
//pqint8 SNNNNNNN NNNNNNNN NNNNNNNN NNNNNNNN MMMMMMMM MMMMMMMM MMMMMMMM MMMMMMMM
//float SEEEEEEE EMMMMMMM MMMMMMMM MMMMMMMM
//double SEEEEEEE EEEEMMMM MMMMMMMM MMMMMMMM MMMMMMMM MMMMMMMM MMMMMMMM MMMMMMMM

#define int8 char
#define uint8 unsigned char
#define int16 short
#define uint16 unsigned short
#define int32 int
#define uint32 unsigned int
#define int64 long long
#define uint64 unsigned long long
#define float32 float
#define float64 double

//low - high  host memory use " \0" >> 32
#define R16(p) *(short*)(p)
#define R32(p) *(int*)(p)
#define R64(p) *(long long*)(p)
#define RFl(p) *(float*)(p)
#define RDb(p) *(double*)(p)

#define W16(p,v) *(short*)(p) = (short)(v)
#define W32(p,v) *(int*)(p) = (int)(v)
#define W64(p,v) *(long long*)(p) = (long long)(v)
#define WFl(p,v) *(float*)(p) = (float)(v)
#define WDb(p,v) *(double*)(p) = (double)(v)

//high-low  net use "\0 " >> 32
static  short R16l(char *p)
{
	char s[] = { p[1], p[0] };
	return *(short *)s;
}
static  int R32l(char *p)
{
	char s[] = { p[3], p[2], p[1], p[0] };
	return *(int *)s;
}
static  long long R64l(char *p)
{
	char s[] = { p[7], p[6], p[5], p[4], p[3], p[2], p[1], p[0] };
	return *(long long*)s;
}
static  float RFll(char *p)
{
	int v = R32l(p);
	return *(float*)&v;
}
static  double RDbl(char *p)
{
	long long v = R64l(p);
	return *(double*)&v;
}
static  long long double2long(double d)
{
	long long v = (long long)d;
	return v < 0 && d > 0 ? v - 1 : v; // 0x8000000000000000LL->0x7FFFffffFFFFffffLL
}
static  int double2int(double d)
{
	int v = (int)d;
	return v < 0 && d > 0 ? v - 1 : v; // 0x80000000->0x7FFFffff
}
static  unsigned double2uint(double d)
{
	return d > 0 ? d < 4294967297.0 ? (unsigned)(long long)d : (unsigned)4294967296 : 0;
}

// return [1,n], or 0 if n is 0 //取x>0从头偏移,x<0从尾偏移
static  unsigned indexn(int x, unsigned n)
{
	return n == 0 ? 0 : x == 0 ? 1 :
		x < 0 ? (x += n + 1) > 0 ? (unsigned)x : 1 :
		(unsigned)x > n ? n : (unsigned)x;
}
static  unsigned indexn0(int x, unsigned n)
{
	return n ? indexn(x, n) - 1 : 0;
}

#endif // !_BASE_H_
