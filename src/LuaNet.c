
#include "LuaNet.h"

//http://www.cnblogs.com/wuyuxuan/p/5541598.html IPV6

#ifdef _WIN32
	#define ERRNO WSAGetLastError() //see winerror.h
	#define ioctl ioctlsocket
#else
	#define ERRNO errno //see errno.h
	#define SOCKET int
	#define INVALID_SOCKET  (SOCKET)(~0)
	#define SOCKET_ERROR            (-1)
	#define closesocket close
#endif

#ifdef __linux //linux
	#define USENETEPOLL
#endif
#ifdef USENETEPOLL
	#ifndef __linux
	#error "netepoll only support in __linux"
	#endif
	#include <sys/epoll.h>
	#define EPOLLFD_SIZE 5000	//最大个数
	#define MAX_EVENTS 50		//一次检查个数
	#define EPOLL_TIME_OUT 1	//0会使CPU占用过高
//EPOLLIN：          触发该事件，表示对应的文件描述符上有可读数据。(包括对端SOCKET正常关闭)；
//EPOLLOUT：         触发该事件，表示对应的文件描述符上可以写数据；
//EPOLLPRI：         表示对应的文件描述符有紧急的数据可读（这里应该表示有带外数据到来）；
//EPOLLERR：         表示对应的文件描述符发生错误；
//EPOLLHUP：         表示对应的文件描述符被挂断；
//EPOLLRDHUP：       对端断开；
//EPOLLET：          将EPOLL设为边缘触发(Edge Triggered)模式，这是相对于水平触发(Level Triggered)来说的。
//EPOLLONESHOT：     只监听一次事件，当监听完这次事件之后，如果还需要继续监听这个socket的话，需要再次把这个socket加入到EPOLL队列里
#endif


#define Range(x, min_, max_) (x < min_ ? min_ : x > max_ ? max_ : x)

#define META_NAME "[NET]"
#define ACCEPTTIMEOUT 10 //秒 同一listener:accept时间过长跳过
//#define LENONHEAD //len on head of bytes. must use with LuaCode together

//state
#define NETLISN 1
#define NETCONN 2
#define NETCLOSE 4
#define NETRECV 8
#define NETSHARE 32
#define BUFFERSIZE (1024*1024*4) //receive
#define NETBUFLEN (1024*1024) //SO_RCVBUF
//CentOS release 6.3 (Final)
//下套接字接受缓冲区 SO_RCVBUF = 43690 bytes, 发送缓冲区 SO_SNDBUF = 9800 bytes
//windows 下
//下套接字接受缓冲区 SO_RCVBUF = 8192 bytes, 发送缓冲区 SO_SNDBUF = 8192 bytes

//struct/static-----------------------------------------------
typedef struct TCPNet {
	SOCKET sock;
	int af_family;
	int state;
	int len;		//wait recv len
	time_t timeout;
	int decode;		//recv push to lua
	int forceref;//Listener在没close前/异步connect回调前 防回收的强引用
	char *seps[4];
	int sepsref[4];
	//int bufIdx; //TODO private use
	//char* buf; //TODO private use
	struct TCPNet *next;
} TCPNet;

static TCPNet *_Listeners = NULL;
static TCPNet *_Nets = NULL;	//非listener
static char *_Buf = NULL; //单线程复用reuse
static int _BufIdx = 0;
#ifdef USENETEPOLL
static int epoll_fd;
#endif
//-------------------------------------------------------
#ifdef _WIN32 //windows adapt linux
static int inet_aton(const char *cp, struct in_addr *inp)
{
	unsigned a = 0, b = 0, c = 0, d = 0;
	int n = 0, r;
	unsigned long addr = 0;
	r = sscanf(cp, "%u.%u.%u.%u%n", &a, &b, &c, &d, &n);
	if (r == 0 || n == 0) return 0;
	cp += n;
	if (*cp) return 0;
	if (a > 255 || b > 255 || c > 255 || d > 255) return 0;
	if (inp) {
		addr += a; addr <<= 8;
		addr += b; addr <<= 8;
		addr += c; addr <<= 8;
		addr += d;
		inp->s_addr = htonl(addr);
	}
	return 1;
}
static unsigned char WSAStarted = 0; //winsock inited
#endif
static int sockpair0;

//option set
static void net_setblocking(SOCKET ps, int blocking) {
	int argp = blocking ? 0 : 1;
	ioctl(ps, FIONBIO, (unsigned long*)&argp);
}
static void net_setnodelay(SOCKET ps, int nodelay) {
	int bTCPnodelay = nodelay ? 1 : 0;
	setsockopt(ps, IPPROTO_TCP, TCP_NODELAY, (const char*)&bTCPnodelay, sizeof(int));
}
//net manager--------------------------------------------------------------------------------
static void net_add(TCPNet *net, int sock, int state)
{
#ifdef USENETEPOLL
	struct epoll_event e = { state == NETCONN ? EPOLLOUT : state == NETLISN || state == NETSHARE ? EPOLLIN : 0, net };
	epoll_ctl(epoll_fd, EPOLL_CTL_ADD, sock, &e);
#endif
}
static void net_addlistener(TCPNet *net)
{
	net->next = _Listeners;
	_Listeners = net;
}
static void net_dellistener(TCPNet *net) //TOCHECK
{
	if (!net) return;
	TCPNet *node = _Listeners;
	if (node == net) {
		_Listeners = node->next;
		return;
	}
	while (node) {
		if (node->next == net)
		{
			node->next = net->next;
			//net->next = NULL; //循环中要还利用
			return;
		}
		else
			node = node->next;
	}
}
static void net_addreceiver(TCPNet *net)
{
	net->next = _Nets;
	_Nets = net;
}
static void net_delreceiver(TCPNet *net) //TOCHECK
{
	if (!net) return;
	TCPNet *node = _Nets;
	if (node == net){
		_Nets = node->next;
		return;
	}
	while (node) {
		if (node->next == net)
		{
			node->next = net->next;
			//net->next = NULL; //循环中要还利用
			return;
		}
		else
			node = node->next;
	}
}
static void net_close(lua_State *L, TCPNet *net, const char *res, int code)
{
	if (net->forceref) {
		lua_unref(L, net->forceref); //del forceref
		net->forceref = 0;
	}
	net_setblocking(net->sock, 1);	/* close can take a long time on WIN32 */
	closesocket(net->sock);
#ifdef USENETEPOLL
	epoll_ctl(epoll_fd, EPOLL_CTL_DEL, net->sock, NULL); // must del shared socket
#endif
	if (net->state == NETLISN || net->state == NETSHARE)
		net_dellistener(net);
	else
		net_delreceiver(net);
	net->state = NETCLOSE;
	int i;
	for (i = 0 ; i < 4; i ++ ){
		lua_unref(L, net->sepsref[i]);
		net->sepsref[i] = 0;
	}
	//onclose
	lua_getUserdata(L, net);
	lua_getfieldUD(L, -1, "._onClose");
	if (lua_isfunction(L, -1)){ //onClose(net, resaon, errcode)
		lua_pushvalue(L, -2);
		if (res)
			lua_pushstring(L, res);
		else
			lua_pushnil(L);
		lua_pushnumber(L, code);
		//beforecall
		if (lua_pcall(L, 3, 0, 0) != 0) {
			//errorCall
			luaL_where(L, 1);
			lua_concat(L, 2);
			fprintf(stderr, "[C]err:%s\n", lua_tostring(L, -1));
			//lua_errorEx(L, "%s\n", lua_tostring(L, -1)); //崩
		}
		//aftercall
	}
	else
		lua_errorEx(L, "[C]onClose missing");
}
//loop
static void net_accept(lua_State *L, TCPNet *listener)
{
	if (listener->state == NETCLOSE) return; //had closed
	SOCKET sock;
	int taken = 0;
	time_t t = time(NULL);
	for (;;) {//accept until none or timeout
#ifdef _WIN32

#else
		if (listener->state == NETSHARE) {
			struct iovec e = { _Buf, NETBUFLEN };
			char cmsg[CMSG_SPACE(4)];
			struct msghdr m = { NULL, 0, &e, 1, cmsg, CMSG_LEN(4), 0 };
			int n = recvmsg(listener->sock, &m, 0);
			if (n <= 0) return;
			struct cmsghdr *c = CMSG_FIRSTHDR(&m);
			if (!c || c->cmsg_type != SCM_RIGHTS)
				return;
			sock = *(int*)CMSG_DATA(c);
			taken = n;
		}
		else
#endif
			if ((sock = accept(listener->sock, NULL, NULL)) == SOCKET_ERROR)
				return; //accept until none

		net_setblocking(sock, 0);
		net_setnodelay(sock, 0);
		lua_getUserdata(L, listener); //lst;
		lua_getfieldUD(L, -1, "._onListen");//lst;onlisten
		//new client
		TCPNet *net = (TCPNet*)lua_newuserdata(L, sizeof(TCPNet));//wv;ojb;onlisten;clnt
		net->af_family = listener->af_family;
		net->sock = sock;
		net->state = NETRECV;
		net->timeout = 0; //if no luanet_setReceive close soon
		memset(net->seps, 0, sizeof(net->seps));
		memset(net->sepsref, 0, sizeof(net->sepsref));
		net_addreceiver(net);
		net_add(net, sock, NETRECV);
		luaL_getmetatable(L, META_NAME);
		lua_setmetatable(L, -2);
		lua_setUserdata(L);//lst;onlisten,net
		lua_getfieldUD(L, -3, "._onClose");//lst;onlisten,net,onClose
		lua_setfieldUD(L, -2, "._onClose");//lst;onlisten,net
		//lua_replace(L, -2);//p1:newnet //wv;ojb;onlisten;clnto
		lua_pushvalue(L, -3);//p2:listener //lst;onlisten,net,lst
		if (net->af_family == AF_INET6) {
			char str[INET6_ADDRSTRLEN];
			struct sockaddr_in6 ad;
			int adz = sizeof(ad);
			getpeername(sock, (struct sockaddr*)&ad, &adz);
			lua_pushstring(L, inet_ntop(AF_INET6, &ad.sin6_addr, str, sizeof(str)));
			lua_pushnumber(L, ntohs(ad.sin6_port));
			getsockname(listener->sock, (struct sockaddr*)&ad, &adz);
			lua_pushstring(L, inet_ntop(AF_INET6, &ad.sin6_addr, str, sizeof(str)));
			lua_pushnumber(L, ntohs(ad.sin6_port));
		}
		//else if (net->af_family == AF_UNIX) { //TODO v4/v6? share过来的源af_family不知道
		//}
		else {
			char str[INET_ADDRSTRLEN];
			struct sockaddr_in ad;
			int adz = sizeof(ad);
			getpeername(sock, (struct sockaddr*)&ad, &adz);
			lua_pushstring(L, inet_ntop(AF_INET, &ad.sin_addr, str, sizeof(str)));
			lua_pushnumber(L, ntohs(ad.sin_port));
			getsockname(listener->sock, (struct sockaddr*)&ad, &adz);
			lua_pushstring(L, inet_ntop(AF_INET, &ad.sin_addr, str, sizeof(str)));
			lua_pushnumber(L, ntohs(ad.sin_port));
		}

		if (taken){
			lua_getref(L, _BufIdx);
			lua_setBytesLen(L, -1, taken);
		}
		else
			lua_pushnil(L); //p7:win no share
		//beforecall
		//onListen(conn, listener, cip, cport, sip, sport, share)
		if (lua_pcall(L, 7, 0, 0) != 0) { //errorCall
			fprintf(stderr, "accept %s\n", lua_tostring(L, -1));
		} //aftercall
		if (net->timeout==0)
			fprintf(stderr, "[C]net not set recvive when onListen, will close soon\n", lua_tostring(L, -1));

		//accept for too long time
		if (time(NULL) - t > ACCEPTTIMEOUT) {
			fprintf(stdout, "accept for too long time,skip\n");
			break;
		}
		lua_settop(L, 0);
	}
}
static void net_receive(lua_State *L, TCPNet *net)
{
	int len = net->len;
	int tostr = net->decode;

	int taken = recv(net->sock, _Buf, len, MSG_PEEK); //check len
	if (taken == 0) {
		net_close(L, net, "peer reset", 0);
		return;
	}
	if (taken < 0) {
		net_close(L, net, NULL, ERRNO);
		return; //
	}
	if (taken < len) {
		if (time(NULL) > net->timeout) {
			net_close(L, net, "timeout", 0);
		}
		return;
	}

	recv(net->sock, _Buf, len, 0); //real recv
	//net->timeout = 0x7fffffff; //if not reset onReceive use last
	_Buf[taken] = '\0';
	lua_getUserdata(L, net);
	lua_getfieldUD(L, -1, "._onReceive");
	//TODO assert(onReceive,"no set onReceive")

	lua_pushvalue(L, -2);
	if (tostr)
		lua_pushlstring(L, _Buf, taken);
	else {
		lua_getref(L, _BufIdx);//TODO 复用buff 如果lua中保存 要拷贝
		lua_setBytesLen(L, -1, taken);
	}
	//beforecall
	if (lua_pcall(L, 2, 0, 0) != 0) {
		//errorCall
		luaL_where(L, 1);
		lua_concat(L, 2);
		fprintf(stderr, "[C]receive err:%s\n", lua_tostring(L, -1));
	}
	//aftercall
}
static void net_receiveSep(lua_State *L, TCPNet *net)
{
	int len = net->len;
	int tostr = net->decode;

	int taken = recv(net->sock, _Buf, len, MSG_PEEK); //check len
	if (taken == 0) {
		net_close(L, net, "peer reset", 0);
		return;
	}
	if (taken < 0) {
		net_close(L, net, NULL, ERRNO);
		return; //
	}

	size_t sn = 0;
	int rev = 0;
	int si;
	int i = 0;
	size_t n;// = strlen(net->seps[si]); //strlen不支持带\0字符
	char *sep = NULL;
	for (si = 0; net->seps[si]; si++)
	{
		lua_getref(L, net->sepsref[si]); //己支持\0
		sep = (char *)lua_tolstring(L, -1, &n);
		lua_pop(L, 1);
		i = 0;
		do
			if (memcmp(_Buf + i, sep, n) == 0)
			{
				sn = i;
				rev = 1;
				break;
			}
		while (++i < taken);

		if (rev) {
			taken = n + sn;
			recv(net->sock, _Buf, taken, 0);
			break;
		}
	}
	if (!rev) {
		if (time(NULL) > net->timeout) {
			net_close(L, net, "timeout", 0);
		}
		return;
	}

	//net->timeout = 0x7fffffff;
	_Buf[taken] = '\0';
	lua_getUserdata(L, net);
	int t = lua_type(L, -1);
	lua_getfieldUD(L, -1, "._onReceive");
	lua_pushvalue(L, -2);
	if (tostr)
		lua_pushlstring(L, _Buf, taken);
	else{
		lua_getref(L, _BufIdx);//TODO 复用buff 如果lua中保存 要拷贝
		lua_setBytesLen(L, -1, taken);
	}

	int argn = 2;
	if (sep) {
		lua_pushlstring(L, sep, n); //push sep
		argn = 3;
	}
	//beforecall
	if (lua_pcall(L, argn, 0, 0) != 0) {
		//errorCall
		luaL_where(L, 1);
		lua_concat(L, 2);
		fprintf(stderr, "[C]receiveSep err:%s\n", lua_tostring(L, -1));
	}
	//aftercall
}
static void net_accepting(lua_State *L)
{
	TCPNet *listener = _Listeners;
	while (listener != NULL) {
		net_accept(L, listener);
		listener = listener->next;
	}
}
static void net_onconn(lua_State *L, TCPNet *net)
{
	net->state = NETRECV;
	if (net->forceref) {
		lua_unref(L, net->forceref); //del forceref
		net->forceref = 0;
	}

	lua_getUserdata(L, net);
	lua_getfieldUD(L, -1, "._onConnect");
	lua_pushvalue(L, -2);
	SOCKET sock = net->sock;

	if (net->af_family == AF_INET6) {
		char str[INET6_ADDRSTRLEN];
		struct sockaddr_in6 ad;
		int adz = sizeof(ad);
		getpeername(sock, (struct sockaddr*)&ad, &adz);
		lua_pushstring(L, inet_ntop(AF_INET6, &ad.sin6_addr, str, sizeof(str)));
		lua_pushnumber(L, ntohs(ad.sin6_port));
		getsockname(sock, (struct sockaddr*)&ad, &adz);
		lua_pushstring(L, inet_ntop(AF_INET6, &ad.sin6_addr, str, sizeof(str)));
		lua_pushnumber(L, ntohs(ad.sin6_port));
	}
	else {
		char str[INET_ADDRSTRLEN];
		struct sockaddr_in ad;
		int adz = sizeof(ad);
		getpeername(sock, (struct sockaddr*)&ad, &adz);
		lua_pushstring(L, inet_ntop(AF_INET, &ad.sin_addr, str, sizeof(str)));
		lua_pushnumber(L, ntohs(ad.sin_port));
		getsockname(sock, (struct sockaddr*)&ad, &adz);
		lua_pushstring(L, inet_ntop(AF_INET, &ad.sin_addr, str, sizeof(str)));
		lua_pushnumber(L, ntohs(ad.sin_port));
	}
	//beforecall
	if (lua_pcall(L, 5, 0, 0) != 0) { //errorCall
		luaL_where(L, 1);
		lua_concat(L, 2);
		fprintf(stderr, "onConnectErr %s\n", lua_tostring(L, -1));
	} //aftercall
}
#ifdef USENETEPOLL
static void net_epolling(lua_State *L)
{
	struct epoll_event es[MAX_EVENTS];
	int nfds = epoll_wait(epoll_fd, es, MAX_EVENTS, EPOLL_TIME_OUT);
	TCPNet *net = NULL;
	for (int i = nfds; --i >= 0; )
	{
		net = (TCPNet*)es[i].data.ptr;
		if (es[i].events & (EPOLLERR | EPOLLHUP | EPOLLRDHUP))
			net_close(L, net, es[i].events & EPOLLRDHUP ? "peer reset" : net->state == NETCONN ? "connect failed" : NULL, 0);
		else if (es[i].events & (EPOLLIN | EPOLLOUT))
			switch (net->state)
			{
			case NETRECV:
				if (net->seps[0])
					net_receiveSep(L, net);
				else
					net_receive(L, net);
				break;
			case NETCONN:
				net_onconn(L, net);
				break;
			default:
				break;
			}
	}
}
#else
static void net_selecting(lua_State *L)
{
	if (!_Nets) return;
	fd_set rfds, wfds, efds;
	fd_set *rp = NULL, *wp = NULL, *ep = NULL;
	struct timeval tv;
	FD_ZERO(&rfds);
	FD_ZERO(&wfds);
	FD_ZERO(&efds);
	SOCKET max_fd = 0;
	TCPNet *net = _Nets;
	while (net != NULL) {
		SOCKET sock = net->sock;
		//fprintf(stderr, "sock%d state %d\n",sock, net->state);
		switch (net->state) {
		case NETRECV:
		case NETCONN:
		case NETSHARE:
			FD_SET(sock, &rfds);
			FD_SET(sock, &wfds);
			FD_SET(sock, &efds);
			max_fd = max_fd > sock ? max_fd : sock;
			break;
		default: break;
		}
		net = net->next;
	}
	rp = &rfds, wp = &wfds, ep = &efds;
	tv.tv_sec = tv.tv_usec = 0;
	//linux need max_fd+1 
	int ret = select(max_fd+1, rp, wp, ep, &tv);
	if (ret == -1) {
		fprintf(stderr, "select error:%d\n", ERRNO);
		return;//error
	}
	if (ret == 0) return;//timeout
	net = _Nets;
	SOCKET sock;
	while (net != NULL) {
		sock = net->sock;
		if (net->state != NETCLOSE)	{
			switch (net->state)	{
			case NETRECV:
				if (FD_ISSET(sock, rp)) {
					if (net->seps[0])
						net_receiveSep(L, net);
					else
						net_receive(L, net);
				}
				//if (FD_ISSET(sock, wp)) //?
				//	fprintf(stderr, "NETRECV wp\n");
				break;
			case NETCONN:
				if (FD_ISSET(sock, wp))
					net_onconn(L, net);
				else if (time(NULL) > net->timeout)
					net_close(L, net, "timeout", 0);
				break;
			default:
				break;
			}
			if (FD_ISSET(sock, ep)) {
				ret = ERRNO;
				if (ret)
					fprintf(stderr, "select error:%d\n", ret);
			}
		}
		net = net->next;
	}
}
#endif
//lua meta--------------------------------------------------------------------------------
static int luanet_gc(lua_State *L)
{
	TCPNet *net = (TCPNet*)lua_touserdata(L, -1);
	if (net->state == NETCLOSE) return 0;
	net_close(L, net, "collect", 0);
	if (net->state == NETLISN || net->state == NETSHARE)
		fprintf(stderr, "listener was __gc without closed");
	return 0;
}
static int luanet_close(lua_State *L) //主动关闭
{
	TCPNet *net = (TCPNet*)luaL_checkudata(L, 1, META_NAME);
	if (net->state == NETCLOSE)
		lua_pushboolean(L, 0);
	else{
		const char * res;
		if (lua_isstring(L, 2))
			res = lua_tostring(L, 2);
		else{
			luaL_where(L, 1);
			res = lua_tostring(L, -1);
		}
		net_close(L, net, res, 0);
		lua_pushboolean(L, 1);
	}
	return 1;
}
static int luanet_closed(lua_State *L)
{
	TCPNet *net = (TCPNet*)luaL_checkudata(L, 1, META_NAME);
	if (net->state == NETCLOSE)
		lua_pushboolean(L, 1);
	else
		lua_pushboolean(L, 0);
	return 1;
}
static int luanet_getfd(lua_State *L)
{
	TCPNet *net = (TCPNet*)luaL_checkudata(L, 1, META_NAME);
	lua_pushinteger(L, net->sock);
	return 1;
}
static int luanet_setReceive(lua_State *L) //receive(net, sep4..., len, onReceive, timeout, tostr)
{
	char *seps[4] = {NULL};
	int i =2;
	for (i = 2; i < 6; i++)
	{
		if (lua_type(L, i) == LUA_TSTRING) {
			size_t n = 0;
			seps[i - 2] = (char *)lua_tolstring(L, i, &n); //支持带\0字符
		}
		else {
			seps[i - 2] = NULL;
			break;
		}
	}
	if (lua_type(L, i) == LUA_TSTRING) 
		lua_errorEx(L, "receive:too many separators");

	size_t len = (size_t)lua_tointeger(L, i);
	if (len<1)	
		lua_errorEx(L, "#%d must be 1<integer<1048576", i);

	int funcidx;
	if (!lua_isfunction(L, i + 1))
		lua_errorEx(L, "#%d must be a function onReceive", i + 1);

	else funcidx = i + 1;
	int tm = (int)lua_tonumber(L, i + 2);
	int tostr = lua_toboolean(L, i + 3);

	TCPNet *net = (TCPNet*)luaL_checkudata(L, 1, META_NAME);
	if (net->state == NETCLOSE) return 0;
#ifdef USENETEPOLL
	struct epoll_event e = { EPOLLIN | EPOLLRDHUP, net };
	epoll_ctl(epoll_fd, EPOLL_CTL_MOD, net->sock, &e);
#endif
	for (i = 0; i < 4; i++) {
		if (net->seps[i] != seps[i]) {
			if (net->seps[i]) { //old
				lua_unref(L, net->sepsref[i]);
				net->sepsref[i] = 0;
				if (seps[i]) { //new
					net->seps[i] = seps[i];
					lua_pushvalue(L, i + 2);
					net->sepsref[i] = lua_ref(L, -1);
				}
				else
					net->seps[i] = NULL;
			} else {
				if (seps[i]) {
					net->seps[i] = seps[i];
					lua_pushvalue(L, i + 2);
					net->sepsref[i] = lua_ref(L, -1);
				}
			}
		}
	}
	net->len = len;
	net->timeout = time(NULL) + Range(tm, 1, 86400);
	net->decode = tostr;
	lua_pushvalue(L, 1);
	lua_pushvalue(L, funcidx);
	lua_setfieldUD(L, -2, "._onReceive");

//#ifndef _WIN32
//	if (len > 4096)
//	{
//		int b, z = sizeof(b);
//		getsockopt(net->sock, SOL_SOCKET, SO_RCVBUF, (char*)&b, (socklen_t*)&z);
//#if __linux
//		b = b + 1 >> 1;
//#endif
//		if (b < len + 1024)
//			b = len + 1024,
//			setsockopt(net->sock, SOL_SOCKET, SO_RCVBUF, (char*)&b, sizeof(b));
//	}
//#endif

	return 0;
}
static int luanet_send(lua_State *L)
{
	TCPNet *net = (TCPNet*)luaL_checkudata(L, 1, META_NAME);
	if (net->state == NETCLOSE) {
//#ifdef _DEBUG
		fprintf(stderr,"net was closed!");
//#endif
		return 0;
	}
	size_t len = 0;
	const char *s = (char *)lua_toBytes(L, 2, &len);
#ifdef LENONHEAD
	len = (int)(*s);
	len += 4;
#else 
	size_t l = luaL_optnumber(L, 3, 0);
	if (l != 0)
		len = min(l, len);
#endif

	int n = 0, i;
	size_t b;
	int z = sizeof(b);
	for(i=1;;i++){
		n = send(net->sock, s, len, 0);
		if (n == SOCKET_ERROR) //复制到发送缓存里了
		{
			int ret = ERRNO;
#ifdef _WIN32
			if (ret != ERROR_IO_PENDING && ret != WSAEWOULDBLOCK) //ERROR_IO_PENDING发送中
#else
			if (ret != EAGAIN && ret != EPIPE)
#endif
			{
				net_close(L, net, NULL, ret);
				return 0;
			}
		}
		else if (n < len) {
			b = 0;
			getsockopt(net->sock, SOL_SOCKET, SO_SNDBUF, (char*)&b, &z);
#ifndef _WIN32 //#ifdef LINUX
			b = b + 1 >> 1;
#endif
			if (i > 3) { //too long
				lua_errorEx(L, "SendBufferOverflow%d>%d\n", len, n);
				return 0;
			}

			len -= n;
			s = s + n;
			b += i * 0x4000;
			setsockopt(net->sock, SOL_SOCKET, SO_SNDBUF, (char*)&b, sizeof(b));
		}
		else break;
	}
	return 0;
}

static int luanet_setnodelay(lua_State *L)
{
	TCPNet *net = (TCPNet*)luaL_checkudata(L, 1, META_NAME);
	if (net->state == NETCLOSE) {
		lua_errorEx(L, "net was closed!");
		return 0;
	}
	int nodelay = lua_toboolean(L, 2);
	net_setnodelay(net->sock, nodelay);
	return 0;
}
static int luanet_share(lua_State *L)
{
#ifdef _WIN32
	lua_errorEx(L, "net share unsupport in windows");
	//HANDLE hPipe = CreateNamedPipe("", PIPE_ACCESS_DUPLEX,
	//	PIPE_TYPE_MESSAGE | PIPE_READMODE_MESSAGE | PIPE_WAIT,
	//	PIPE_UNLIMITED_INSTANCES, 0, 0, NMPWAIT_WAIT_FOREVER, 0);

#else //走双工pipe管道
	TCPNet *net = (TCPNet*)luaL_checkudata(L, 1, META_NAME);
	if (net->state <= NETCLOSE){
		lua_errorEx(L, "net unconnected");
		return 0;
	}
	size_t n; 
	const char *name = lua_tolstring(L, 2, &n);
	if (name[0] != '@' || n <= 1 || n > 128) {
		lua_errorEx(L, "invalid share name");
		return 0;
	}
	struct sockaddr_un ad;
	ad.sun_family = AF_UNIX;
	memcpy(ad.sun_path, name, n);
	ad.sun_path[0] = 0;
	memset(ad.sun_path + n, 0, sizeof(ad.sun_path) - n);
	const char *s = lua_tolstring(L, 3, &n);
	int from = luaL_optint(L, 4, 1);
	int to = luaL_optint(L, 5, -1);
	const char *S = s + indexn(to, n);
	s += indexn0(from, n);
	if (s >= S) {
		lua_errorEx(L, "invalid length");
		return 0;
	}
	struct iovec e = { (void*)s, S - s };
	char cmsg[CMSG_SPACE(4)];
	struct msghdr m = { (void*)&ad, sizeof(ad), &e, 1, cmsg, CMSG_LEN(4), 0 };
	struct cmsghdr *c = CMSG_FIRSTHDR(&m);
	c->cmsg_level = SOL_SOCKET;
	c->cmsg_type = SCM_RIGHTS;
	c->cmsg_len = m.msg_controllen;
	*(int*)CMSG_DATA(c) = net->sock;
	int sock = sockpair0;
	int r = sendmsg(sock, &m, 0);
	if (r <= 0) {
		lua_pushstring(L, strerror(ERRNO));
		return 1;
	}
#endif
	return 0;
}
static int luanet_macaddr(lua_State *L)
{
	TCPNet *net = (TCPNet*)luaL_checkudata(L, 1, META_NAME);
	char s[20];
#ifdef _WIN32 
	//http://blog.csdn.net/analogous_love/article/details/49130865
	//http://blog.csdn.net/weiyumingwww/article/details/17554461
	//http://www.cnblogs.com/annie-fun/p/6406630.html
	DWORD AdapterInfoSize = 0;
	if (ERROR_BUFFER_OVERFLOW != GetAdaptersInfo(NULL, &AdapterInfoSize)){
		lua_errorEx(L, "GetAdaptersInfo Failed! ErrorCode: %d", GetLastError());
		return 0;
	}
	void* buffer = malloc(AdapterInfoSize);
	if (buffer == NULL)
		lua_errorEx(L, "malloc failed!");

	PIP_ADAPTER_INFO pAdapt = (PIP_ADAPTER_INFO)buffer;
	if (ERROR_SUCCESS != GetAdaptersInfo(pAdapt, &AdapterInfoSize)){
		free(buffer);
		lua_errorEx(L, "GetAdaptersInfo Failed! ErrorCode: %d", GetLastError());
		return 0;
	}
	if (pAdapt == NULL) return 0;
	while (pAdapt != NULL) {
		//pAdapt->Address; //macAddr
		//pAdapt->AdapterName; //regname
		//pAdapt->Index;	//id
		//pAdapt->Description;
		//pAdapt->IpAddressList.IpAddress;
		//pAdapt->AddressLength
		sprintf(s, "%02X-%02X-%02X-%02X-%02X-%02X",
			(unsigned char)pAdapt->Address[0],
			(unsigned char)pAdapt->Address[1],
			(unsigned char)pAdapt->Address[2],
			(unsigned char)pAdapt->Address[3],
			(unsigned char)pAdapt->Address[4],
			(unsigned char)pAdapt->Address[5],
			(unsigned char)pAdapt->Address[6]);
		break;
		//pAdapt = pAdapt->Next;
	}
	free(buffer);
#else //http://www.cnblogs.com/quicksnow/p/3299172.html
	struct ifreq ifreq0;
	//strcpy(ifreq0.ifr_name, "eth0"); //指定网卡
	if (ioctl(net->sock, SIOCGIFHWADDR, &ifreq0)<0){
		perror("ioctl");
		return 0;
	}
	sprintf(s,"%02x:%02x:%02x:%02x:%02x:%02x\0",
		(unsigned char)ifreq0.ifr_hwaddr.sa_data[0],
		(unsigned char)ifreq0.ifr_hwaddr.sa_data[1],
		(unsigned char)ifreq0.ifr_hwaddr.sa_data[2],
		(unsigned char)ifreq0.ifr_hwaddr.sa_data[3],
		(unsigned char)ifreq0.ifr_hwaddr.sa_data[4],
		(unsigned char)ifreq0.ifr_hwaddr.sa_data[5]);
#endif
	lua_pushstring(L, s);
	return 1;
}

//lua global----------------------------------
static int luanet_hostips(lua_State *L)//DNS
{
	const char *addr = lua_tostring(L, 1);
	if (addr == NULL) { //本机
		char local[101]; gethostname(local, 100), local[100] = 0;
		addr = local;
	}
	//DNS
	struct addrinfo *answer, hint, *curr;
	memset(&hint, 0, sizeof(hint));
	hint.ai_family = AF_UNSPEC;
	hint.ai_socktype = SOCK_STREAM;
	char ipstr2[128];
	struct sockaddr_in  *addr_ipv4;
	struct sockaddr_in6 *addr_ipv6;
	int ret = getaddrinfo(addr, NULL, &hint, &answer);
	if (ret != 0)  return 0;
	lua_settop(L, 0);
	
	char *ptr;
	for (curr = answer; curr != NULL; curr = curr->ai_next) {
		switch (curr->ai_family) {
		case AF_INET: {
			char str[INET_ADDRSTRLEN];
			addr_ipv4 = (struct sockaddr_in *)(curr->ai_addr);
			ptr = (char *)inet_ntop(AF_INET, &addr_ipv4->sin_addr, str, sizeof(str));
			if (ptr)
				lua_pushstring(L, ptr);
			break;
		}
		case AF_INET6: {
			char str[INET6_ADDRSTRLEN];
			addr_ipv6 = (struct sockaddr_in6 *)(curr->ai_addr);
			ptr = (char *)inet_ntop(AF_INET6, &addr_ipv6->sin6_addr, str, sizeof(str));
			if (ptr)
				lua_pushstring(L, ptr);
			break;
		}
		case AF_UNIX:
			printf("AF_UNIX\n");
			break;
		case AF_UNSPEC:
			printf("AF_UNSPEC unspecified\n");
			break;
		default:
			printf("unknown ai_family %d\n", curr->ai_family);
			break;
		}
	}
	return lua_gettop(L);
}

static int luanet_listen(lua_State *L)
{
	size_t len;
	const char *addr = luaL_checklstring(L, 1, &len);
	if (!lua_isfunction(L, 2)) 
		lua_errorEx(L, "#2 must be a function onListen(net, listener, ip, port, myip, myport, share)");

	if (!lua_isfunction(L, 3)) 
		lua_errorEx(L, "#3 must be a function onClose(net, err, errcode)");

	int state = NETLISN;
	SOCKET sock;
	int addr_family = AF_UNSPEC;
	if (addr[0] == '@') { //TODO netshare listen pipe window暂无
#ifdef _WIN32
		if (len > 128) 
			lua_errorEx(L, "net share address too long");

		lua_errorEx(L, "net share only linux support");
		//window pipe or UDP
		//\\.\pipe\pipename
		//"\\\\.\\pipe\\Name_pipe_demon_get"
		//char p[255];
		//sprintf(p, "\\\\.\\pipe\\%s\0", addr+1);
		//HANDLE hPipe = CreateNamedPipe(p, PIPE_ACCESS_DUPLEX,
		//	PIPE_TYPE_MESSAGE | PIPE_READMODE_MESSAGE | PIPE_WAIT,
		//	PIPE_UNLIMITED_INSTANCES, 0, 0, NMPWAIT_WAIT_FOREVER, 0);
		//sock = (SOCKET)hPipe;
		//state = NETSHARE;
		return 0;
#else 
		if (len > 128) 
			lua_errorEx(L, "net share address too long");

		addr_family = AF_UNIX;
		sock = socket(addr_family, SOCK_DGRAM, 0);
		if (sock == -1){
			lua_errorEx(L, "listen init error: %s", strerror(ERRNO));
			return 0;
		}
		int on = 1;
		ioctl(sock, FIONBIO, (unsigned long*)&on);
		struct sockaddr_un ad;
		ad.sun_family = addr_family;
		memcpy(ad.sun_path, addr, len);
		ad.sun_path[0] = 0;
		memset(ad.sun_path + len, 0, sizeof(ad.sun_path) - len);
		if (bind(sock, (struct sockaddr*)&ad, sizeof(ad)))
			lua_errorEx(L, "listen init error: %s", strerror(ERRNO));

		state = NETSHARE;
#endif
	}
	else 	{
		char host[255] = { '\0' };
		int port = 0; //int不能直接用u_short否则sscanf会造成报错
		//TODO: 待改可析":::port"/"[::]:port"/"x.x.x.x:port"
		if (addr[0] == '[') // TODO or 两个以上的:
		{ //ipv6 "[::]:port"
			sscanf(addr, "[%[^]]]:%u[^\n]", &host, &port);
			addr_family = AF_INET6;
		}
		else {	//ipv4 "x.x.x.x:port"
			sscanf(addr, "%[^:]:%u[^\n]", &host, &port);
			addr_family = AF_INET;
		}
		if (port <= 0 || port > 65535) 
			lua_errorEx(L, "invalid listen port%d\n", port);


		struct sockaddr_in  sa_ipv4;
		struct sockaddr_in6 sa_ipv6;
		if (addr_family == AF_INET6){
			memset(&sa_ipv6, 0, sizeof(sa_ipv6));
			sa_ipv6.sin6_family = addr_family;
			sa_ipv6.sin6_port = htons((unsigned short)port);
			if(strcmp(host, "*"))
				inet_pton(AF_INET6, host, &sa_ipv6.sin6_addr);
		}
		else if (addr_family == AF_INET) {
			memset(&sa_ipv4, 0, sizeof(sa_ipv4));
			sa_ipv4.sin_family = addr_family;
			sa_ipv4.sin_port = htons((unsigned short)port);

			if (strcmp(host, "*"))
				inet_pton(AF_INET, host, &sa_ipv4.sin_addr);
		}
		else
			lua_errorEx(L,"AF_UNSPEC?\n");

#ifdef _WIN32  //IOCP
		if ((sock = WSASocket(addr_family, SOCK_STREAM, IPPROTO_TCP, NULL, 0, WSA_FLAG_OVERLAPPED)) == INVALID_SOCKET) {
#else
		if ((sock = socket(addr_family, SOCK_STREAM, IPPROTO_TCP)) == INVALID_SOCKET) {
#endif
			lua_errorEx(L, "socket init failed with error %d\n", ERRNO);
			return 0;
		}
		//bind
		int err;
		if (addr_family == AF_INET)
			err = bind(sock, (struct sockaddr*)&sa_ipv4, sizeof(struct sockaddr_in));
		else
			err = bind(sock, (struct sockaddr*)&sa_ipv6, sizeof(struct sockaddr_in6));
		if (err < 0) 
			lua_errorEx(L, "bind error:%d\n", ERRNO);

		//set blocking
		net_setblocking(sock, 0);
		net_setnodelay(sock, 0);
		int on = 1;
		setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, (char*)&on, sizeof(on));
		on = NETBUFLEN;
		setsockopt(sock, SOL_SOCKET, SO_RCVBUF, (char*)&on, sizeof(on));
		//listen backlog:最大握手队列win:5,unix:10 accept移走
		listen(sock, 10);
	}
	//tolua
	TCPNet *net = (TCPNet*)lua_newuserdata(L, sizeof(TCPNet));
	net->af_family = addr_family;
	net->sock = sock;
	net->state = state;
	memset(net->seps, 0, sizeof(net->seps));
	memset(net->sepsref, 0, sizeof(net->sepsref));
	net_addlistener(net);
	net_add(net, sock, state);
	lua_pushvalue(L, lua_upvalueindex(1)); //luaL_getmetatable(L, META_NAME);
	lua_setmetatable(L, -2);
	lua_setUserdata(L);
	lua_pushvalue(L, 2);
	lua_setfieldUD(L, -2, "._onListen");
	lua_pushvalue(L, 3);
	lua_setfieldUD(L, -2, "._onClose");
	lua_pushvalue(L, -1);
	net->forceref = lua_ref(L, -1);
	return 1;
}

static int luanet_connect(lua_State *L)
{
	const char *host = luaL_checkstring(L, 1);
	u_short port = (u_short)luaL_checkint(L,2);

	if (port == 0 || port > 0xffff)
		lua_errorEx(L, "#2 invalid listen port:%d\n", port);
	if (!lua_isfunction(L, 3)) 
		lua_errorEx(L, "#3 must be a function onConnect");
	if (!lua_isfunction(L, 4)) 
		lua_errorEx(L, "#4 must be a function onClose");
	int tm = (int)lua_tonumber(L, 5);

	//DNS
	struct addrinfo *answer, hint, *curr;
	memset(&hint, 0, sizeof(hint));
	hint.ai_family = AF_UNSPEC;
	hint.ai_socktype = SOCK_STREAM;
	char ipstr2[128];
	struct sockaddr_in  *addr_ipv4;
	struct sockaddr_in6 *addr_ipv6;
	int ret = getaddrinfo(host, NULL, &hint, &answer);
	if (ret != 0) 
		lua_errorEx(L, "getaddrinfo fail %d\n", ERRNO);

	int addr_family = AF_INET;
	for (curr = answer; curr != NULL; curr = curr->ai_next) {
		switch (curr->ai_family) {
		case AF_UNSPEC:
			printf("AF_UNSPEC\n" );
			break;
		case AF_INET:
			addr_family = AF_INET;
			addr_ipv4 = (struct sockaddr_in *)(curr->ai_addr);
			inet_ntop(AF_INET, &addr_ipv4->sin_addr, ipstr2, sizeof(ipstr2));
			addr_ipv4->sin_port = htons(port);
			break;
		case AF_INET6:
			addr_family = AF_INET6;
			addr_ipv6 = (struct sockaddr_in6 *)(curr->ai_addr);
			inet_ntop(AF_INET6, &addr_ipv6->sin6_addr, ipstr2, sizeof(ipstr2));
			addr_ipv6->sin6_port = htons(port);
			break;
		}
		break; //use first
	}

	SOCKET sock;
#ifdef _WIN32 //IOCP
	if ((sock = WSASocket(addr_family, SOCK_STREAM, IPPROTO_TCP, NULL, 0, WSA_FLAG_OVERLAPPED)) == INVALID_SOCKET){
#else
	if ((sock = socket(addr_family, SOCK_STREAM, IPPROTO_TCP)) == INVALID_SOCKET){
#endif
		freeaddrinfo(answer);
		lua_errorEx(L, "socket( ) failed: %d\n", ERRNO);
	}
	net_setblocking(sock, 0);
	net_setnodelay(sock, 0);
	int on = NETBUFLEN;
	setsockopt(sock, SOL_SOCKET, SO_RCVBUF, (char*)&on, sizeof(on));
	int err;
	if(addr_family == AF_INET)
		err = connect(sock, (struct sockaddr*)addr_ipv4, sizeof(struct sockaddr_in));
	else
		err = connect(sock, (struct sockaddr*)addr_ipv6, sizeof(struct sockaddr_in6));
	freeaddrinfo(answer);
	if (err != 0) {
		err = ERRNO;
#ifdef _WIN32
		if (err != WSAEALREADY && err != WSAEWOULDBLOCK && err != WSAEINPROGRESS){
#else
		if (err != EINPROGRESS && err != EAGAIN ){
#endif
			lua_errorEx(L, "connect error: %d", err);
		}
	}
	//tolua
	TCPNet *net = (TCPNet*)lua_newuserdata(L, sizeof(TCPNet));
	net->sock = sock;
	net->af_family = addr_family;
	net->timeout = time(NULL) + Range(tm, 1, 86400);
	net->state = NETCONN;
	memset(net->seps, 0, sizeof(net->seps));
	memset(net->sepsref, 0, sizeof(net->sepsref));
	net->len = 0;
	net->forceref = 0;
	net_addreceiver(net);
	net_add(net, sock, NETCONN);
	lua_pushvalue(L, lua_upvalueindex(1)); //luaL_getmetatable(L, META_NAME);
	lua_setmetatable(L, -2);
	lua_setUserdata(L);
	lua_pushvalue(L, 3);
	lua_setfieldUD(L, -2, "._onConnect");
	lua_pushvalue(L, 4);
	lua_setfieldUD(L, -2, "._onClose");
	//异步但直连成功 去掉,统一走异步
	lua_pushvalue(L, -1);
	net->forceref = lua_ref(L, -1); //force ref while connecting
	return 1;
}

//global
LUAEXTEND_API void luanet_loop(lua_State *L)
{
#ifdef USENETEPOLL
	net_epolling(L);
#else
	net_selecting(L);
#endif
#ifndef CLIENT
	net_accepting(L);
#endif
	lua_settop(L, 0);
}

LUAEXTEND_API void luanet_setsharesock(int sock0) {
	sockpair0 = sock0;
}

LUAEXTEND_API void luaopen_net_G(lua_State *L, const char* name) {
	//init
#ifdef _WIN32
	if (!WSAStarted) {
		WSADATA wsd;
		if (WSAStartup(0x0202, &wsd) == SOCKET_ERROR) {
			WSACleanup();
			lua_errorEx(L, "Init Socket Failed!");
		}
	}
#else
#ifdef USENETEPOLL
	//printf("Net Use EPOLL\n");
	epoll_fd = epoll_create(EPOLLFD_SIZE);
#else
	//printf("Net Use select\n");
	signal(SIGPIPE, SIG_IGN);
#endif
#endif

	//static local-------------------------------------
	_Listeners = NULL;
	_Nets = NULL;
	_Buf = lua_newBytes(L, BUFFERSIZE);
	lua_setBytesLen(L, -1, 0);
	_BufIdx = lua_ref(L, -1);
	//reg to lua-------------------------------------
	struct luaL_Reg methods[] = {
		{ "__gc",   luanet_gc },
		{ "close",  luanet_close },
		{ "closed", luanet_closed },
		{ "receive",luanet_setReceive },
		{ "send", 	luanet_send },
		//{ "sendbin", 	luanet_sendBinary },
		{ "nagle", 	luanet_setnodelay },
		{ "share", 	luanet_share },
		{ "getfd",  luanet_getfd },
		{ "macaddr",luanet_macaddr },
		//{ "setfd",  luanet_setfd },
		//{ "getpeername", luanet_getpeername },
		//{ "getsockname", luanet_getsockname },
		//{ "setonlisten", luanet_setonlisten },
		//{ "setonclose",  luanet_setonclose 
		//{ "setonconnect",luanet_setonconnect },

		{ NULL, NULL },
	};
	lua_regMetatable(L, META_NAME, methods, 1);
	//_G
	//luaL_getmetatable(L, META_NAME);
	//lua_pushcclosure(L, luanet_listen, 1), lua_setglobal(L, "_listen");
	//luaL_getmetatable(L, META_NAME);
	//lua_pushcclosure(L, luanet_connect, 1), lua_setglobal(L, "_connect");
	//lua_register(L, "_hostips", luanet_hostips);

	lua_createtable(L, 0, 4);
#ifndef CLIENT
	luaL_getmetatable(L, META_NAME);
	lua_pushcclosure(L, luanet_listen, 1);
	lua_setfield(L, -2, "listen");
#endif
	luaL_getmetatable(L, META_NAME);
	lua_pushcclosure(L, luanet_connect, 1);
	lua_setfield(L, -2, "connect");

	lua_pushcfunction(L, luanet_hostips);
	lua_setfield(L, -2, "hostips");
	lua_setglobal(L, name);
}
LUAEXTEND_API int luaopen_net(lua_State *L) {
	//init
#ifdef _WIN32
	if (!WSAStarted) {
		WSADATA wsd;
		if (WSAStartup(0x0202, &wsd) == SOCKET_ERROR) {
			WSACleanup();
			lua_errorEx(L, "Init Socket Failed!");
		}
	}
#else
#ifdef USENETEPOLL
	//printf("Net Use EPOLL\n");
	epoll_fd = epoll_create(EPOLLFD_SIZE);
#else
	//printf("Net Use select\n");
	signal(SIGPIPE, SIG_IGN);
#endif
#endif

	//static local-------------------------------------
	_Listeners = NULL;
	_Nets = NULL;
	_Buf = lua_newBytes(L, BUFFERSIZE);
	lua_setBytesLen(L, -1, 0);
	_BufIdx = lua_ref(L, -1);
	//reg to lua-------------------------------------
	struct luaL_Reg methods[] = {
		{ "__gc",   luanet_gc },
		{ "close",  luanet_close },
		{ "closed", luanet_closed },
		{ "receive",luanet_setReceive },
		{ "send", 	luanet_send },
		//{ "sendbin", 	luanet_sendBinary },
		{ "nagle", 	luanet_setnodelay },
		{ "share", 	luanet_share },
		{ "getfd",  luanet_getfd },
		{ "macaddr",luanet_macaddr },
		//{ "setfd",  luanet_setfd },
		//{ "getpeername", luanet_getpeername },
		//{ "getsockname", luanet_getsockname },
		//{ "setonlisten", luanet_setonlisten },
		//{ "setonclose",  luanet_setonclose 
		//{ "setonconnect",luanet_setonconnect },

		{ NULL, NULL },
	};
	lua_regMetatable(L, META_NAME, methods, 1);
	//_G
	//luaL_getmetatable(L, META_NAME);
	//lua_pushcclosure(L, luanet_listen, 1), lua_setglobal(L, "_listen");
	//luaL_getmetatable(L, META_NAME);
	//lua_pushcclosure(L, luanet_connect, 1), lua_setglobal(L, "_connect");
	//lua_register(L, "_hostips", luanet_hostips);

	lua_createtable(L, 0, 4);
#ifndef CLIENT
	luaL_getmetatable(L, META_NAME);
	lua_pushcclosure(L, luanet_listen, 1);
	lua_setfield(L, -2, "listen");
#endif
	luaL_getmetatable(L, META_NAME);
	lua_pushcclosure(L, luanet_connect, 1);
	lua_setfield(L, -2, "connect");

	lua_pushcfunction(L, luanet_hostips);
	lua_setfield(L, -2, "hostips");
	return 1;
}

