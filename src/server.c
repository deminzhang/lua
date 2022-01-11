
#include <stdio.h>
#include <stdlib.h>  
#include <math.h>
#ifdef __cplusplus
#include "lua.hpp"
extern "C" {
#endif
#include "LuaNet.h" //win front because #include <winsock2.h> must front
#include "LuaScript.h"
#include "LuaTime.h"
#include "LuaPostgres.h"
#include "LuaCode.h"
#include "LuaQueue.h"
#include "LuaMySql.h"
#include "LuaSqlite3.h"
#include "LuaZip.h"
#include "LuaProtoBuf.h"
#ifdef __cplusplus
}
#endif //__cplusplus

#ifdef _WIN32
	#include <winternl.h>
	#pragma comment(lib, "lua51.lib")		//lua
	
	#define OS "windows"
	#ifdef _WIN64
		#define ARCH "x64"
	#else
		#define ARCH "x86"
	#endif
	#ifdef _DEBUG
	#else
	#endif
	#ifdef _MSC_VER //>=
	#else
	#endif
#else
	#include <unistd.h>
	#include <sys/prctl.h>
	#include <sys/stat.h>
	#include <sys/types.h>
	#include <sys/wait.h>
	#include <pwd.h>
	#define MAX_PATH        260
	#define OS "linux"
	#ifdef __x86_64
		#define ARCH "x64"
	#else
		#define ARCH "x86"
	#endif
#endif //_WIN32

//--os------------------------------------------------------
#ifdef _WIN32 //linux�Դ�
#define getpid GetCurrentProcessId
static int getpgid(int id) //��pid
{
	if (!id)
		return getpid();
	HANDLE h = OpenProcess(PROCESS_QUERY_INFORMATION, 0, id); 
#ifdef _WIN64
	int (WINAPI *QueryProcess)(HANDLE p, int zero, long long  *s, long long len, void *nil)
		= (int(__stdcall *)(HANDLE, int, long long  *, long long, void *))
		GetProcAddress(GetModuleHandleA("ntdll.dll"), "NtQueryInformationProcess"); //��˵��NtWow64QueryInformationProcess64 64�������ȡ32λ��ĳ����
	long long s[6];
	(*QueryProcess)(h, ProcessBasicInformation, s, sizeof(s), NULL);
#else
	int (WINAPI *QueryProcess)(HANDLE p, int zero, int *s, int len, void *nil)
		= (int(__stdcall *)(HANDLE, int, int *, int, void *))
		GetProcAddress(GetModuleHandleA("ntdll.dll"), "NtQueryInformationProcess");
	int s[6];
	(*QueryProcess)(h, ProcessBasicInformation, s, sizeof(s), NULL);
#endif
	/* http://www.cnblogs.com/daxingxing/archive/2011/11/18/2254272.html
	PROCESS_BASIC_INFORMATION pbi;
	(*QueryProcess)(h, ProcessBasicInformation, &pbi, sizeof(pbi), NULL);
	//*/
	CloseHandle(h);
	return s[5];
}
#endif

static int lua_osid(lua_State *L)
{
	int p = lua_tointeger(L, 1);
	if (!p) p = getpid();
	int pp = getpgid(p);
	if (pp <= 0)
		return 0;
	lua_pushinteger(L, p); //pid
	lua_pushinteger(L, pp); //groupid
#ifdef _WIN32
	return 2;
#else
	lua_pushinteger(L, getsid(p));
	if (p == getpid()) {
		lua_pushinteger(L, getppid());//parentpid
		return 4;
	}
	return 3;
#endif
}

#ifndef _WIN32
static int socks[2]; //socketpair
#endif
static int lua_launch(lua_State *L)
{
	const char *s0 = luaL_checkstring(L, 1); //work path
	int top = lua_gettop(L);
#ifdef _WIN32
	char runPath[MAX_PATH];
	GetModuleFileNameA(NULL, runPath, MAX_PATH);
	char args[1002] = ". ", *s = args + 2;
	for (int i = 2; i <= top; i++) {
		s = (char*)memccpy(s, lua_tostring(L, i), '\0', args + sizeof(args) - s);
		if (!s)
			lua_errorEx(L, "launch arguments too long");
		s[-1] = i < top ? ' ' : '\0';
	}
	STARTUPINFOA si;
	memset(&si, 0, sizeof(si)), si.cb = sizeof(si);
	PROCESS_INFORMATION pid;
	if (!CreateProcessA(runPath, args, NULL, NULL, FALSE, CREATE_NEW_CONSOLE, NULL, s0, &si, &pid)){
		lua_errorEx(L, "launch error %s", strerror(errno));
		return 0;
	}
	CloseHandle(pid.hProcess);
	CloseHandle(pid.hThread);
	lua_pushinteger(L, pid.dwProcessId);
	return 1;
#else
	//��������ͨ��
	if (lua_objlen(L, 1) > 255)
		lua_errorEx(L, "directory too long");
	//���Ͳ������ӽ���
	char args[4 + 256 + 1000];
	*(int*)args = getpid();
	strcpy(args + 4, s0);
	char *s = args + 4 + 256;
	for (int i = 2; i <= top; i++)
		s = (char*)memccpy(s, lua_tostring(L, i), '\0', args + sizeof(args) - s);
		if (!s)
			lua_errorEx(L, "launch arguments too long");
	*s = '\0';
	send(socks[1], args, sizeof(args), 0);
	//���ӽ��������ɹ�pid�ظ�pid
	int ids[2] = { 0, 0 };
	while (recv(socks[1], ids, sizeof(ids), MSG_PEEK), ids[0] != getpid());
	recv(socks[1], ids, sizeof(ids), 0);
	if (ids[1] < 0)
		lua_errorEx(L, "launch error");

	lua_pushinteger(L, ids[1]);
	return 1;
#endif
}
static int lua_kill(lua_State *L)
{
	int id = luaL_checkinteger(L, 1);
	if (getpgid(id) != getpgid(0))
		lua_errorEx(L, "not child process");
#ifdef _WIN32
	HANDLE h = OpenProcess(PROCESS_TERMINATE, 0, id);
	if (!TerminateProcess(h, -1))
		lua_errorEx(L, "kill error %s", strerror(errno));
	CloseHandle(h);
#else
	if (kill(id, SIGKILL))
		lua_errorEx(L, "kill error %s", strerror(errno));
#endif
	return 0;
}
static int lua_sleep(lua_State *L)
{
	int ms = luaL_optinteger(L, 1, 0);
	usleep((ms>0 ? ms : 0)*1000);
	return 0;
}

//testcolor
#ifdef WIN32
HANDLE stdout_handle, stderr_handle;
#define TRED FOREGROUND_RED | FOREGROUND_INTENSITY
#define TGREEN FOREGROUND_GREEN | FOREGROUND_INTENSITY
#define TYELLOW FOREGROUND_GREEN | FOREGROUND_RED | FOREGROUND_INTENSITY
#define TNORMAL FOREGROUND_GREEN | FOREGROUND_RED | FOREGROUND_BLUE
#define TWHITE TNORMAL | FOREGROUND_INTENSITY
#define TBLUE FOREGROUND_BLUE | FOREGROUND_GREEN | FOREGROUND_INTENSITY
#else
#define TRED 1
#define TGREEN 2
#define TYELLOW 3
#define TNORMAL 4
#define TWHITE 5
#define TBLUE 6
#endif
void Color(unsigned color)
{
#ifdef WIN32
	SetConsoleTextAttribute(stdout_handle, (WORD)color);
#else
	static const char* colorstrings[TBLUE + 1] = {
		"",
		"\033[22;31m",
		"\033[22;32m",
		"\033[01;33m",
		"\033[0m",
		"\033[01;37m",
		"\033[1;34m",
	};
	fputs(colorstrings[color], stdout);
#endif
}
static int lua_color(lua_State *L)
{
	unsigned color = (unsigned)luaL_optinteger(L, 1, TNORMAL);
	color = color < 1 || color > 6 ? TNORMAL : color;
	Color(color);
	return 0;
}
//--main------------------------------------------------------

int main(int argc, char *argv[], char *envs[])
{
	//init----------------------------------
	char **args = argv + 1;
#ifdef _WIN32
	stderr_handle = GetStdHandle(STD_ERROR_HANDLE);
	stdout_handle = GetStdHandle(STD_OUTPUT_HANDLE);
	//SetConsoleTextAttribute(stderr_handle, (WORD)TRED);
	SetConsoleOutputCP(65001); SetConsoleCP(65001); //use lucida console can show UTF8 chars
#else
	//fputs(colorstrings[1], stderr);
	char runPath[MAX_PATH];
#ifdef __linux
	//printf("INFO process %d\n", getpid());
	//printf("INFO group %d\n", getpgid(0));
	//printf("INFO session %d\n", getsid(0));
	char *dir = getcwd(0, 0);
	if (!dir || !realpath(argv[0], runPath))
		return perror("ERROR getcwd"), errno;
	struct stat st; stat(dir, &st);
	//printf("INFO set user %d\n", st.st_uid);
	free(dir);
#else
	realpath(argv[0], runPath);
#endif
	setpgid(0, 0); //������id��Ϊ������id
	signal(SIGCHLD, SIG_IGN); //�й¸�init, ���ɸ����̹�����Դ, �Է���ʬ
	if (socketpair(AF_UNIX, SOCK_DGRAM, 0, socks))  //˫���ܵ�
		return perror("ERROR socketpair"), errno;
	struct timeval t = { 0, 250000 };
	setsockopt(socks[0], SOL_SOCKET, SO_RCVTIMEO, &t, sizeof(t));
	
	static char arg[4 + 256 + 1000];
	int id = fork();
	if (id < 0)  //fork fail
		return perror("ERROR fork"),errno;
	else if (id > 0) //fork parent
		for (args=NULL;;) //�����̸���launch
		{
			int status;
			if (waitpid(0, &status, WNOHANG) < 0 && errno == ECHILD) //pid=0 �ȴ�������ʶ������Ŀǰ������ͬ���κ��ӽ���
				return 0;
			if (recv(socks[0], arg, sizeof(arg), 0) < 0 && errno)
				continue;
			int ids[2] = { *(int*)arg, -1 };
			char *dir = getcwd(0, 0);
			if (chdir(arg + 4))
				perror("ERROR os.launch chdir");
			else if (ids[1] = fork(), ids[1] < 0)
				perror("ERROR os.launch fork");
			else if (ids[1] == 0)
				break;
			if (chdir(dir))
				perror("ERROR os.launch chdir");
			send(socks[0], ids, sizeof(ids), 0); //��arg���ӽ���
		}
	//else id==0 fork child
	// �������˳��ӽ��̽�SIGKILL�ź� !ע��linux���߳̾��ǽ���
	if (prctl(PR_SET_PDEATHSIG, SIGKILL)) //�������fork()��
		perror("ERROR prctl");
	luanet_setsharesock(socks[0]);
#endif
	//start lua----------------------------------
	lua_State *L = luaL_newstate();
	luaL_openlibs(L);
	luaopen_extend(L);
	luaopen_decode(L);
	luaopen_protobuf_G(L, "proto");

	//global----------------------------------
	lua_register(L, "_now", lua__now);
	lua_register(L, "_timestr", lua_timestr);
	lua_register(L, "_time", lua__time);

	//other----------------------------------
	luaopen_queue(L);
	luaopen_zip(L);
	luaopen_net_G(L, "_net");
#ifdef USEPOSTGRES
	luaopen_postgres(L);
#endif
#ifdef USEMYSQL
	luaopen_mysql(L);
#endif
#ifdef USESQLITE3
	luaopen_sqlite3(L);
#endif

	//io----------------------------------
	//lua_getglobal(L, "io");
	//lua_pushcfunction(L, lua_color);
	//lua_setfield(L, -2, "color");
	//lua_pop(L, 1);
	
	//os----------------------------------
	lua_getglobal(L, "os");
	lua_pushcfunction(L, lua_sleep);
	lua_setfield(L, -2, "sleep");
	lua_pushcfunction(L, lua_utc);
	lua_setfield(L, -2, "utc");
	lua_pushcfunction(L, lua_now);
	lua_setfield(L, -2, "now");
	lua_pushcfunction(L, lua_launch);
	lua_setfield(L, -2, "launch");
	lua_pushcfunction(L, lua_kill);
	lua_setfield(L, -2, "kill");
	lua_pushcfunction(L, lua_osid);
	lua_setfield(L, -2, "id");
	
	//os.envs----------------------------------
	lua_createtable(L, 0, 20);
	for (char **env = envs; *env; env++) {
		const char *eq = strchr(*env, '=');
		lua_pushlstring(L, *env, eq - *env), lua_pushstring(L, eq + 1), lua_rawset(L, -3);
	}
	lua_setfield(L, -2, "env");
	//os.info----------------------------------
	lua_createtable(L, 0, argc+1);
	lua_pushliteral(L, OS);
	lua_setfield(L, -2, "system");
	lua_pushliteral(L, ARCH);
	lua_setfield(L, -2, "arch");

#if _WIN32
	for (char *s; s = *args; args++) {
#else //linux�ӽ��̲���
	for (char *s = arg + 4 + 256; args ? (size_t)(s = *args) : (size_t)*s;
		args ? (void)args++ : (void)(s += strlen(s) + 1)) {
#endif
		char *eq = strchr(s, '=');
		if (eq)
			lua_pushlstring(L, s, eq - s), lua_pushstring(L, eq + 1), lua_rawset(L, -3); //info[k] = v
		else
			lua_pushstring(L, s), lua_pushboolean(L, 1), lua_rawset(L, -3); //info[k] = true
	}
	lua_setfield(L, -2, "info");
	lua_pop(L, 1); //pop os
	//check stack top==0
	int topidx = lua_gettop(L);
	if (topidx){
		fprintf(stderr, "[C]Warning:lua_gettop()=%d. Maybe some init defective\n", topidx);
		lua_close(L);
		for(;;) usleep(9999);
		return 0;
	}
	//--enter loop------------------------------------------------
	set__now();
	int ret = luaL_dofile(L, "launch.lua");
	if (ret == 0)
		for (;;) {
			set__now(); //business time
			for (int i = 0; i < 16; ++i) {
				luanet_loop(L); //head
				luanet_loop(L); //body
			}
			luaqueue_loop(L); //timers
			lua_getglobal(L, "_mainloop"); //main loop in lua
			if (lua_isfunction(L, -1)&&lua_pcall(L, 0, 0, 0) != 0) 
				fprintf(stderr, "%s\n", lua_tostring(L, -1));

			lua_settop(L, 0); //keepsafe
			usleep(0);
		}
	else
		fprintf(stderr, "%s\n", lua_tostring(L, -1));

	usleep(60000);
	lua_close(L);
	usleep(60000);
	return 0;
}
