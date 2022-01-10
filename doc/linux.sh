##linux基本操作--------------------------
##重启/关机
	reboot
	shutdown -h 0
##linux更新--------------------------
	#centos
	yum update
	cat /proc/version #查看版本
	#ubuntu
	do-release-upgrade
	apt-get update
	
##用户
	cat /etc/group #查看
	groupadd postgres #增加用户组
	useradd postgres -g postgres #增加用户并加到指定组
	-u username passwd #改用户密码
	vi ~/.bash_profile #修改寻bin路
	
##网络设置--------------------------
#查看网卡/新机联网
	ifconfig #查看网卡名如eth0
	vim /etc/sysconfig/network-scripts/ifcfg-eth0
	BOOTPROTO=dhcp 
	ONBOOT=no 改为 yes
#或替换
	sed -i -e 's/ONBOOT=no/ONBOOT=yes/g' /etc/sysconfig/network-scripts/ifcfg-eth0
#重启网络
	service network restart
	/etc/init.d/network restart
#设置ip
	ifconfig eth0 192.168.168.64
	ifconfig netmask 255.255.255.0
	ifconfig eth0 192.168.168.64 netmask 255.255.255.0
#设置硬件地址
	ifconfig eth0 hw ether xx:xx:xx:xx:xx:xx
#禁用/启用网卡
	ifconfig eth0 down
	ifconfig eth0 up
	/etc/init.d/network restart
	service network restart
#以上都是临时改网络，重启后还原为默认网络

#查看端口
	netstat -tunpl
	netstat -nap	#p所属进程
	netstat -napt	#只更tcp
	netstat -napu	#只列udp
	lsof -i :22		#查看22端口的进程
	
#防火墙sudo
	#centos7
	firewall-cmd --stat			#运行状态
	firewall-cmd --list-all			#列表
	firewall-cmd --add-port=80/tcp 	#80端口开放
	systemctl stop firewalld	#关闭
	systemctl restart firewalld #重启
	#配置/运行
	vim /etc/rc.d/rc.fw
	
	/etc/rc.d/rc.fw

##安装 系统级要root或sudo
#安装/卸载 -y自动确认
	yum -y instal [Package]
	yum remove [Package]
	[Package] -V		#查看版本号
	[Package] --help	#查看帮助
	
#centos加epel源
	cd /usr/local/src
	wget -c http://mirrors.kernel.org/fedora-epel/epel-release-latest-7.noarch.rpm
	rpm -ivh epel-release-latest-7.noarch.rpm
	yum repolist 
#安装常用 
  #centos
	yum -y install vim
	yum -y install gcc
	yum -y install gcc-c++
	yum -y install subversion 	#svn
	yum -y install lrzsz 		#rz上传sz下载
	yum -y install wget 		#下载
	yum -y install bzip2
	yum -y install p7zip 		#epel源
	yum -y install readline-devel
	yum -y install zlib-devel 	#zlib
	yum -y install cmake
	yum -y install mlocate 	#locate/updatedb
  #ubuntu
	apt-get install p7zip-full #7z
	apt-get install libreadline-dev
	apt-get install zlib1g-dev #zlib
	#apt-get install libtool
	#apt-get install git
	#apt-get install pkg-config
	#apt-get install libncurses5-dev
	
	
	
##文件管理--------------------------
#查找/更新
	locate filename
	updatedb
#创建
	touch f1 #无则创建空文件,有则改修改时间
	touch f{1,3} #批量创建空文件
	touch -c f1 #无则不创建
	touch -a f1 #更改访问时间
	touch -m f1 #更改修改时间
#复制/移动
	cp -r f1 f2
	mv f1 f2

#文件权限
	chmod 777 [filename]	#全权限
	chmod +x [filename]		#加可执行
	chmod a+r [filename] 	#所有用户可读
	chmod a+w [filename] 	#所有用户可写
	
#删文件-f确认 -r文件失
	rm 文件
	rm -f 文件
	rm -rf 文件夹
	
#压缩
	7za a filename.7z
	zip -r filename.zip ./*
	zip -r filename.zip foldername
	tar zcvf foldername.tar.gz foldername
#解压
	7za x filename.7z
	tar -xzvf filename.tar.gz
	tar -xvf filename.tar
	tar jxvf filename.tar.bz2
	unzip file.zip
	
	
##日期时间--------------------------
	#显示/格式显示
	date
	date '+%Y%m%d%H%M'
	#修改
	date -s 03/01/2019
	date -s 14:52:00
	#修改时区为北京时间
	rm /etc/localtime
	ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
#查进程/杀进程
	ps -e|grep 进程名称
	ps -ef|grep 进程名称 #f带pid ppid
	kill -9 进程号
	pkill -9 进程名称
	
##shell脚本
func()
{
	echo callFunc
}
func
if [ -z "$a" ]; then
	echo a is null
fi
if [ -n "$a" ]; then
	echo a is no null
fi
if [ $a -lt $b ]; then
	echo a < b
fi
if [ $a = $b ]; then
	echo a == b
fi
if [ $a -le $b ]; then
	echo a <= b
fi
if [ $a -gt $b ]; then
	echo a > b
fi
if [ $a -gt $b ]; then
	echo a >= b
fi
if [ $a -ne $b ]; then
	echo a != b
fi


##SVN--------------------------
	svn checkout --username demin_zhang --password ********** http://code.taobao.org/svn/luaserver 
	
##GIT--------------------------

	yum -y install git #安装
	git --version #版本
	yum remove git #卸载
	
	git init
	git config --global user.name "yongjian.liu"
	git config --global user.email "11.29"  
	git config user.name "yongjian.liu"  
	git config user.email "11.29"  
	
	git clone git@10.4.0.27:Crusade/Server.git #从远程库clone
	
	git remote add origin https://xxx.git  		#创建远程库
	git push origin master #push到远程
	
	git pull origin master
	git pull #拉remote库并合并
	git fetch --all  #1拉而不合
	git reset --hard origin/master #2强制重置跟远程库一样(等效于SVN删掉文件重update)
	git branch #查看本地分支 *为当前所用
	git branch dev #创建分支
	git checkout bname #切换分支
	git branch -D bname	#删除本地分支
	git checkout -b bname origin/bname #拉远程分支
	git commit -a 			#提交所有改动
	git add filename 		#加入要提交
	git commit -m "说明" 	#提交add过的
	git mv -f oldname newname #重命名
	git add -u newname #-u选项会更新已经追踪的文件和文件夹
	git status # 查看修改状态
	git commit -m "rename"
	git push origin master #push到远程
	#SVN没有的
	git stash #暂存本地开发 本地还原为跟库一样,此时可以pull或切换分支改BUG
	git stash list #列出暂存
	git stash pop #弹出暂存 改完BUG回来,弹出暂存的开发
	

##SSH--------------------------
	ssh localhost --测试己安：
	#安装
	apt-get install openssh-server	#ubuntu
	yum install openssh-server	#centos
	#配置
	vim /etc/ssh/sshd_config
		#Port 22				#默认端口22
		ClientAliveInterval 60	#每60分给终端发ping
		ClientAliveCountMax 3	#3次无响应则断开
		AuthorizedKeysFile      .ssh/authorized_keys	#信任公钥/root/.ssh/authorized_keys
	
	#启动/关闭/重启
	/etc/init.d/ssh start
	/etc/init.d/ssh stop
	service sshd restart
	systemctl restart sshd.service
	#连接/退出
	ssh localhost -p22
	exit

#密钥登陆
	#生成  -C"描述"
	ssh-keygen -b 2048 -t rsa -C"谁的主机"
	#回车3次 默认生成/root/.ssh/id_rsa*
	#将生成的*.pub内容拷到目标主机/root/.ssh/authorized_keys内
	scp -p ~/.ssh/id_rsa.pub root@10.45.11.29:/root/id_rsa.pub
	scp -p root@10.45.11.29:/data/app/web/dev-git/install/soft/xxtea-lua-master.zip /d/
	scp -p root@10.45.11.29:/data/app/web/pub-git/install/soft/lua-xxtea-1.0.tar.gz /d/
	#scp /c/Users/Administrator/.ssh/id_rsa.pub root@host:/root
	ssh root@10.45.11.29 "mkdir -p .ssh; cat id_rsa.pub >> /root/.ssh/authorized_keys"
	#即可免密登陆目标主机

##RPC远程运行
	ssh user@host -p22 "cd /data; ls"
	#脚本 eeooff eeooff 之间
	ssh user@host > /dev/null 2>&1 << eeooff
cd /home
touch abcdefg.txt
exit
eeooff
	echo done!

	
##rsync同步
	rsync -av  --exclude "*.git" -e "ssh -pPORT" SRCPATH root@IP:/data/TARPATH
	rsync -av  --exclude "*.svn" -e "ssh -pPORT" SRCPATH root@IP:/data/TARPATH
	
##安装postgresql数据库--------------
	apt-get install postgresql
	cd /
	mkdir data
	chown postgres /data
	cd /usr/lib/postgresql/9.5/bin
	su postgres
	chmod 777 /data
	./initdb --locale=C -E=UTF-8 /data
	cd /data
	
#源码安装postgresql9.6
	cd postgres-9.6.2
	./configure
	make
	make install
	groupadd postgres
	useradd postgres -g postgres
	
	mkdir -p /usr/local/pgsql/data
	chown -R postgres /usr/local/pgsql/.
	chown -R postgres /usr/local/pgsql/data
	chmod 777 /usr/local/pgsql/data
	su postgres
	/usr/local/pgsql/bin/initdb --locale=C -E=UTF-8 /usr/local/pgsql/data
	
	#cp postgresql/contrib/start-scripts/linux /etc/init.d/postgresql
	chmod +x /etc/init.d/postgresql
	
	vim /etc/init.d/postgresql
		PGDATA="/usr/local/pgsql/data"
	vim /usr/local/pgsql/data/postgresql.conf
		listen_addresses = '*'
	vim /usr/local/pgsql/data/pg_hba.conf
		host all all 0.0.0.0/0 md5
		
	/usr/local/pgsql/bin/pg_ctl -D /usr/local/pgsql/data -l logfile start
	/usr/local/pgsql/bin/pg_ctl -D /usr/local/pgsql/data start
	service postgresql start
	/etc/init.d/postgresql restart
	firewall-cmd --add-port=5432/tcp	#防火墙放行

#修改配置
	vim postgresql.conf
		listen_address = '*'		#line:59
	vim pg_hba.conf
		# IPv4 local connections:
		host    all             all             1.1.0.0/32            trust #外部访问ip/mask
#重启数据库
	/etc/init.d/postgresql stop
	/usr/lib/postgresql/9.5/bin/pg_ctl stop
	/usr/lib/postgresql/9.5/bin/pg_ctl -D /data start
	
#导入数据表
	cd [initdb.sh所在文件位]
	chmod 777 ./initdb.sh
	su postgres
	./initdb.sh
	exit #退出postgresql
	
##安装mysql
	https://www.cnblogs.com/jxrichar/p/9248480.html
	
	##https://www.cnblogs.com/jorzy/p/8455519.html
	wget http://repo.mysql.com/mysql57-community-release-el7-8.noarch.rpm
	rpm -ivh mysql57-community-release-el7-8.noarch.rpm
	yum install mysql-server
	service mysqld start
	
	grep "password" /var/log/mysqld.log	//找初始密码
	mysql -uroot -p	//空密
	mysql -uroot -pNoNeed4Pass32768
	>set global validate_password_policy=0; //降底安全级别,可测简单密码
	>set global validate_password_length=1; //降底密码长度要求,可测简单密码
	>ALTER USER 'root'@'localhost' IDENTIFIED BY 'NoNeed4Pass32768' EXPIRE NEVER; //永不过期
	>grant all privileges on *.* to root@"%" identified by "NoNeed4Pass32768";
	
	>grant all privileges on *.* to root@"localhost" identified by "NoNeed4Pass32768";
	>grant all privileges on *.* to root@"127.0.0.1" identified by "NoNeed4Pass32768";
	>grant all privileges on *.* to root@"61.148.75.238" identified by "NoNeed4Pass32768"; //公司
	>flush privileges;
	>\q
	#导入sql
	mysql -uroot -p -Ds1-fysg2_data < /data/app/web/s1-fysg2_game_kunlun_com/database/install.sql; 
	mysql -uroot -pNoNeed4Pass32768 -Dcrusade_999 < /data/app/slg/crusade/db/install.sql
	>source fullpathfilename;  //执行sql文件
	#导出sql
	mysqldump -u dbuser -p dbname > dbname.sql
	
	service mysqld start
	service mysqld stop
	service mysqld restart
	service mysqld status
	
	systemctl start mysqld
	service mysqld stop
	service mysqld restart
	systemctl status mysqld


##安装lua--------------------require readline
	wget http://www.lua.org/ftp/lua-5.1.5.tar.gz
	tar -xzvf lua-5.1.5.tar.gz
	cd lua-5.1.5
#指定安装位置？
	sed -i 's#^INSTALL_TOP=.*#INSTALL_TOP= /usr/local/lua-5.1.5#gi' ./Makefile
#如果系统为64位请执行下面这条命令
	#sed -i 's#^CFLAGS=.*#CFLAGS= -O2 -fPIC -Wall $(MYCFLAGS)#gi' ./src/Makefile
	make linux
	make install

##编译----------------------------------------------------
	.o	==win.obj
	.a	==win.lib
	.so	==win.dll

#gcc -o luat luat.c -I[include文件夹] -L[lib文件夹] [.a文件名] -l[.so库中间名] -lm -ldl
#gcc -o luat luat.c -I/usr/local/lua/include/ -L/usr/local/lua/lib/ /usr/local/lua/lib/liblua.a -llua -lm -ldl
gcc -o luat luat.c -I/home/lua-5.1.5/src/ -L/home/lua-5.1.5/src/ /home/lua-5.1.5/src/liblua.a -llua -lm -ldl
#gcc -o mylsvr mylsvr.c -Iluajit/src/ luajit/src/libluajit.a -lm -ldl	#只用静态库
#gcc -o mylsvr mylsvr.c -Iluajit/src/ -Iluasocket/src/ luajit/src/libluajit.a luasocket/src/libluasocket.a -lm -ldl	#只用静态库

#64位的安装32位兼容库
	apt-get install g++-multilib
	apt-get install libncurses5:i386
	apt-get install libc6:i386 libgcc1:i386 gcc-4.6-base:i386 libstdc++5:i386 libstdc++6:i386
	apt-get install ia32-libs
#指定编译32位
	gcc -m32

#makefile格式
objects = main.o need1.o
main : $(objects)
	gcc -o main $(objects)
#	ar cr libXXX.a $(objects)	#导出一个静态库
main.o: need1.h
need1.o: need1.h
.PHONY:clean
clean :
	-rm -f main *.o

##安装openresty
	http://blog.51cto.com/niming2008/2121354
	yum install openresty -y
	#if Require GeoIP
	#yum install epel-release
	#yum --enablerepo=epel install geoip
	#endif
	vim /usr/local/openresty/nginx/conf/nginx.conf #改端口
	#启动
	/usr/local/openresty/nginx/sbin/nginx -c /usr/local/openresty/nginx/conf/nginx.conf

##跨域
location = / {
    lua_code_cache on;
    add_header Access-Control-Allow-Origin *;
    add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept";
    add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
    content_by_lua_file $LUA_PATH/main.lua;
}	
	
#bad interpreter: No such file or directory解决
vim xxx.sh
:set ff=unix
:wq

##Redis
#!!!redis 没有密码的对外监听可能会被注入矿机
redis-cli -h localhost -p 6379
>GET key
>SET key val
>CONFIG GET key
>CONFIG SET protected-mode 'no'
>quit

##计划任务
crontab -e
crontab -l
ls /etc/cron.d/

