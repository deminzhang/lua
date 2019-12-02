#ifndef _LUANET_H
#define _LUANET_H

//FD_SETSIZE defauit win=64 linux=2048. if need change define it before socket.h/winsock2.h/winsock.h
//#define FD_SETSIZE 5000//define FD_SETSIZE before #include <winsock2.h>

#ifdef _WIN32
	#include <winsock2.h>
	#include <ws2tcpip.h>
	#include <Iphlpapi.h>  
	#pragma comment(lib, "ws2_32.lib")		//net
	#pragma comment(lib, "Iphlpapi.lib")	//GetAdaptersInfo
#else
	#include <errno.h>
	#include <sys/un.h>
	/* close function */
	#include <unistd.h>
	/* fnctnl function and associated constants */
	#include <sys/ioctl.h> 
	/* struct sockaddr */
	#include <sys/types.h>
	/* socket function */
	#include <sys/socket.h>
	/* struct timeval */
	#include <sys/time.h>
	/* gethostbyname and gethostbyaddr functions */
	#include <netdb.h>
	/* sigpipe handling */
	#include <signal.h>
	/* IP stuff*/
	#include <netinet/in.h>
	#include <arpa/inet.h>
	#include <net/if.h>
	/* TCP options (nagle algorithm disable) */
	#include <netinet/tcp.h>
#endif

//#include <stdlib.h>
//#include <stdio.h>
//#include <time.h> 
#include "LuaScript.h"

LUA_API void luanet_loop(lua_State *L);
LUA_API void luaopen_net(lua_State *L, int sock0);

#endif