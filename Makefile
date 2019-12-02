OUTNAME=luaserver
PATH_LUAJIT=luajit
USEPGSQL=-DUSEPOSTGRES
USEMYSQL=-DUSEMYSQL
USESQLITE3=-DUSESQLITE3
PATH_POSTGRES=postgresql-9.6.2
PATH_MYSQL=mysql-connector-c-6.1.11-src
#PATH_ZLIB=zlib-1.2.11
PATH_ZLIB=$(PATH_MYSQL)/zlib
#-std=c99 用了c99 有些posix标准中h中的struct 会找不到定义
#需要-D_GNU_SOURCE 或-D_BSD_SOURCE -D_SVID_SOURCE
#AUTO -DUSENETEPOLL
#备CC = gcc -std=c99 -D_GNU_SOURCE -D_BSD_SOURCE -D_SVID_SOURCE -DUSEMYSQL
CC = gcc -std=c99 -D_GNU_SOURCE $(USEPGSQL) $(USEMYSQL) $(USESQLITE3)
INCLUEDS= -Isrc -Iinclude -I$(PATH_LUAJIT)/src \
	-Iinclude/mysql -I$(PATH_ZLIB)
	#-I/usr/local/pgsql/include
	# -I/usr/include/mysql
LIBS = -lm -ldl -lpthread *.a
all :
	if [ ! -f libluajit.a ]; then $(MAKE) libluajit; fi
	if [ ! -f libpq.a ]&&[ $(USEPGSQL) ]; then $(MAKE) libpq; fi
	if [ ! -f libmysqlclient.a ]&&[ $(USEMYSQL) ]; then $(MAKE) libmysql; fi
	if [ ! -f libzlib.a ]; then $(MAKE) libzlib; fi
	if [ $(USESQLITE3) ]; then $(MAKE) sqlite3; fi
	$(CC) -c src/LuaNet.c $(INCLUEDS)
	$(CC) -c src/LuaCode.c $(INCLUEDS)
	$(CC) -c src/LuaQueue.c $(INCLUEDS)
	$(CC) -c src/LuaScript.c $(INCLUEDS) 
	$(CC) -c src/LuaTime.c $(INCLUEDS) 
	$(CC) -c src/LuaString.c $(INCLUEDS) 
	$(CC) -c src/LuaZip.c $(INCLUEDS) 
	$(CC) -c src/LuaSqlite3.c $(INCLUEDS)
	$(CC) -c src/LuaPostgres.c $(INCLUEDS)
	$(CC) -c src/LuaMySql.c $(INCLUEDS)
	$(CC) -c src/server.c $(INCLUEDS)
	g++ -o $(OUTNAME) *.o $(LIBS)
	@echo build $(OUTNAME) OK 
libluajit:
	cd $(PATH_LUAJIT); $(MAKE)
	cp $(PATH_LUAJIT)/src/libluajit.a ./
sqlite3:
	if [ ! -f sqlite3.o ]; then $(CC) -c include/sqlite3.c $(INCLUEDS); fi
libpq:
	#first run
	cd $(PATH_POSTGRES);if [ ! -f config.status ]; then chmod 777 configure;./configure; fi
	#only make libpg
	$(MAKE) -C $(PATH_POSTGRES)/src/interfaces
	cp $(PATH_POSTGRES)/src/interfaces/libpq/libpq.a ./
	@echo build libpq.a OK 
libmysql:
	#first run
	cd $(PATH_MYSQL);if [ ! -f Makefile ]; then cmake -G "Unix Makefiles"; fi
	cd $(PATH_MYSQL);$(MAKE)
	cp $(PATH_MYSQL)/libmysql/libmysqlclient.a ./
	@echo build libmysqlclient.a OK 
libzlib:
	cd $(PATH_ZLIB);if [ ! -f libzlib.a ]; then $(MAKE); fi
	cp $(PATH_ZLIB)/libzlib.a ./
clean :
	rm -f $(OUTNAME) *.o
	@echo clean OK 
cleanall :
	cd $(PATH_LUAJIT); $(MAKE) $@
	cd $(PATH_POSTGRES); $(MAKE) $@
	rm -f $(OUTNAME) *.o *.a
	@echo cleanall OK 