##linux��������--------------------------
##����/�ػ�
	reboot
	shutdown -h 0
##linux����--------------------------
	#centos
	yum update
	cat /proc/version #�鿴�汾
	#ubuntu
	do-release-upgrade
	apt-get update
	
##�û�
	cat /etc/group #�鿴
	groupadd postgres #�����û���
	useradd postgres -g postgres #�����û����ӵ�ָ����
	-u username passwd #���û�����
	vi ~/.bash_profile #�޸�Ѱbin·
	
##��������--------------------------
#�鿴����/�»�����
	ifconfig #�鿴��������eth0
	vim /etc/sysconfig/network-scripts/ifcfg-eth0
	BOOTPROTO=dhcp 
	ONBOOT=no ��Ϊ yes
#���滻
	sed -i -e 's/ONBOOT=no/ONBOOT=yes/g' /etc/sysconfig/network-scripts/ifcfg-eth0
#��������
	service network restart
	/etc/init.d/network restart
#����ip
	ifconfig eth0 192.168.168.64
	ifconfig netmask 255.255.255.0
	ifconfig eth0 192.168.168.64 netmask 255.255.255.0
#����Ӳ����ַ
	ifconfig eth0 hw ether xx:xx:xx:xx:xx:xx
#����/��������
	ifconfig eth0 down
	ifconfig eth0 up
	/etc/init.d/network restart
	service network restart
#���϶�����ʱ�����磬������ԭΪĬ������

#�鿴�˿�
	netstat -tunpl
	netstat -nap	#p��������
	netstat -napt	#ֻ��tcp
	netstat -napu	#ֻ��udp
	lsof -i :22		#�鿴22�˿ڵĽ���
	
#����ǽsudo
	#centos7
	firewall-cmd --stat			#����״̬
	firewall-cmd --list-all			#�б�
	firewall-cmd --add-port=80/tcp 	#80�˿ڿ���
	systemctl stop firewalld	#�ر�
	systemctl restart firewalld #����
	#����/����
	vim /etc/rc.d/rc.fw
	
	/etc/rc.d/rc.fw

##��װ ϵͳ��Ҫroot��sudo
#��װ/ж�� -y�Զ�ȷ��
	yum -y instal [Package]
	yum remove [Package]
	[Package] -V		#�鿴�汾��
	[Package] --help	#�鿴����
	
#centos��epelԴ
	cd /usr/local/src
	wget -c http://mirrors.kernel.org/fedora-epel/epel-release-latest-7.noarch.rpm
	rpm -ivh epel-release-latest-7.noarch.rpm
	yum repolist 
#��װ���� 
  #centos
	yum -y install vim
	yum -y install gcc
	yum -y install gcc-c++
	yum -y install subversion 	#svn
	yum -y install lrzsz 		#rz�ϴ�sz����
	yum -y install wget 		#����
	yum -y install bzip2
	yum -y install p7zip 		#epelԴ
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
	
	
	
##�ļ�����--------------------------
#����/����
	locate filename
	updatedb
#����
	touch f1 #���򴴽����ļ�,������޸�ʱ��
	touch f{1,3} #�����������ļ�
	touch -c f1 #���򲻴���
	touch -a f1 #���ķ���ʱ��
	touch -m f1 #�����޸�ʱ��
#����/�ƶ�
	cp -r f1 f2
	mv f1 f2

#�ļ�Ȩ��
	chmod 777 [filename]	#ȫȨ��
	chmod +x [filename]		#�ӿ�ִ��
	chmod a+r [filename] 	#�����û��ɶ�
	chmod a+w [filename] 	#�����û���д
	
#ɾ�ļ�-fȷ�� -r�ļ�ʧ
	rm �ļ�
	rm -f �ļ�
	rm -rf �ļ���
	
#ѹ��
	7za a filename.7z
	zip -r filename.zip ./*
	zip -r filename.zip foldername
	tar zcvf foldername.tar.gz foldername
#��ѹ
	7za x filename.7z
	tar -xzvf filename.tar.gz
	tar -xvf filename.tar
	tar jxvf filename.tar.bz2
	unzip file.zip
	
	
##����ʱ��--------------------------
	#��ʾ/��ʽ��ʾ
	date
	date '+%Y%m%d%H%M'
	#�޸�
	date -s 03/01/2019
	date -s 14:52:00
	#�޸�ʱ��Ϊ����ʱ��
	rm /etc/localtime
	ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
#�����/ɱ����
	ps -e|grep ��������
	ps -ef|grep �������� #f��pid ppid
	kill -9 ���̺�
	pkill -9 ��������
	
##shell�ű�
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

	yum -y install git #��װ
	git --version #�汾
	yum remove git #ж��
	
	git init
	git config --global user.name "yongjian.liu"
	git config --global user.email "11.29"  
	git config user.name "yongjian.liu"  
	git config user.email "11.29"  
	
	git clone git@10.4.0.27:Crusade/Server.git #��Զ�̿�clone
	
	git remote add origin https://xxx.git  		#����Զ�̿�
	git push origin master #push��Զ��
	
	git pull origin master
	git pull #��remote�Ⲣ�ϲ�
	git fetch --all  #1��������
	git reset --hard origin/master #2ǿ�����ø�Զ�̿�һ��(��Ч��SVNɾ���ļ���update)
	git branch #�鿴���ط�֧ *Ϊ��ǰ����
	git branch dev #������֧
	git checkout bname #�л���֧
	git branch -D bname	#ɾ�����ط�֧
	git checkout -b bname origin/bname #��Զ�̷�֧
	git commit -a 			#�ύ���иĶ�
	git add filename 		#����Ҫ�ύ
	git commit -m "˵��" 	#�ύadd����
	git mv -f oldname newname #������
	git add -u newname #-uѡ�������Ѿ�׷�ٵ��ļ����ļ���
	git status # �鿴�޸�״̬
	git commit -m "rename"
	git push origin master #push��Զ��
	#SVNû�е�
	git stash #�ݴ汾�ؿ��� ���ػ�ԭΪ����һ��,��ʱ����pull���л���֧��BUG
	git stash list #�г��ݴ�
	git stash pop #�����ݴ� ����BUG����,�����ݴ�Ŀ���
	

##SSH--------------------------
	ssh localhost --���Լ�����
	#��װ
	apt-get install openssh-server	#ubuntu
	yum install openssh-server	#centos
	#����
	vim /etc/ssh/sshd_config
		#Port 22				#Ĭ�϶˿�22
		ClientAliveInterval 60	#ÿ60�ָ��ն˷�ping
		ClientAliveCountMax 3	#3������Ӧ��Ͽ�
		AuthorizedKeysFile      .ssh/authorized_keys	#���ι�Կ/root/.ssh/authorized_keys
	
	#����/�ر�/����
	/etc/init.d/ssh start
	/etc/init.d/ssh stop
	service sshd restart
	systemctl restart sshd.service
	#����/�˳�
	ssh localhost -p22
	exit

#��Կ��½
	#����  -C"����"
	ssh-keygen -b 2048 -t rsa -C"˭������"
	#�س�3�� Ĭ������/root/.ssh/id_rsa*
	#�����ɵ�*.pub���ݿ���Ŀ������/root/.ssh/authorized_keys��
	scp -p ~/.ssh/id_rsa.pub root@10.45.11.29:/root/id_rsa.pub
	scp -p root@10.45.11.29:/data/app/web/dev-git/install/soft/xxtea-lua-master.zip /d/
	scp -p root@10.45.11.29:/data/app/web/pub-git/install/soft/lua-xxtea-1.0.tar.gz /d/
	#scp /c/Users/Administrator/.ssh/id_rsa.pub root@host:/root
	ssh root@10.45.11.29 "mkdir -p .ssh; cat id_rsa.pub >> /root/.ssh/authorized_keys"
	#�������ܵ�½Ŀ������

##RPCԶ������
	ssh user@host -p22 "cd /data; ls"
	#�ű� eeooff eeooff ֮��
	ssh user@host > /dev/null 2>&1 << eeooff
cd /home
touch abcdefg.txt
exit
eeooff
	echo done!

	
##rsyncͬ��
	rsync -av  --exclude "*.git" -e "ssh -pPORT" SRCPATH root@IP:/data/TARPATH
	rsync -av  --exclude "*.svn" -e "ssh -pPORT" SRCPATH root@IP:/data/TARPATH
	
##��װpostgresql���ݿ�--------------
	apt-get install postgresql
	cd /
	mkdir data
	chown postgres /data
	cd /usr/lib/postgresql/9.5/bin
	su postgres
	chmod 777 /data
	./initdb --locale=C -E=UTF-8 /data
	cd /data
	
#Դ�밲װpostgresql9.6
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
	firewall-cmd --add-port=5432/tcp	#����ǽ����

#�޸�����
	vim postgresql.conf
		listen_address = '*'		#line:59
	vim pg_hba.conf
		# IPv4 local connections:
		host    all             all             1.1.0.0/32            trust #�ⲿ����ip/mask
#�������ݿ�
	/etc/init.d/postgresql stop
	/usr/lib/postgresql/9.5/bin/pg_ctl stop
	/usr/lib/postgresql/9.5/bin/pg_ctl -D /data start
	
#�������ݱ�
	cd [initdb.sh�����ļ�λ]
	chmod 777 ./initdb.sh
	su postgres
	./initdb.sh
	exit #�˳�postgresql
	
##��װmysql
	https://www.cnblogs.com/jxrichar/p/9248480.html
	
	##https://www.cnblogs.com/jorzy/p/8455519.html
	wget http://repo.mysql.com/mysql57-community-release-el7-8.noarch.rpm
	rpm -ivh mysql57-community-release-el7-8.noarch.rpm
	yum install mysql-server
	service mysqld start
	
	grep "password" /var/log/mysqld.log	//�ҳ�ʼ����
	mysql -uroot -p	//����
	mysql -uroot -pNoNeed4Pass32768
	>set global validate_password_policy=0; //���װ�ȫ����,�ɲ������
	>set global validate_password_length=1; //�������볤��Ҫ��,�ɲ������
	>ALTER USER 'root'@'localhost' IDENTIFIED BY 'NoNeed4Pass32768' EXPIRE NEVER; //��������
	>grant all privileges on *.* to root@"%" identified by "NoNeed4Pass32768";
	
	>grant all privileges on *.* to root@"localhost" identified by "NoNeed4Pass32768";
	>grant all privileges on *.* to root@"127.0.0.1" identified by "NoNeed4Pass32768";
	>grant all privileges on *.* to root@"61.148.75.238" identified by "NoNeed4Pass32768"; //��˾
	>flush privileges;
	>\q
	#����sql
	mysql -uroot -p -Ds1-fysg2_data < /data/app/web/s1-fysg2_game_kunlun_com/database/install.sql; 
	mysql -uroot -pNoNeed4Pass32768 -Dcrusade_999 < /data/app/slg/crusade/db/install.sql
	>source fullpathfilename;  //ִ��sql�ļ�
	#����sql
	mysqldump -u dbuser -p dbname > dbname.sql
	
	service mysqld start
	service mysqld stop
	service mysqld restart
	service mysqld status
	
	systemctl start mysqld
	service mysqld stop
	service mysqld restart
	systemctl status mysqld


##��װlua--------------------require readline
	wget http://www.lua.org/ftp/lua-5.1.5.tar.gz
	tar -xzvf lua-5.1.5.tar.gz
	cd lua-5.1.5
#ָ����װλ�ã�
	sed -i 's#^INSTALL_TOP=.*#INSTALL_TOP= /usr/local/lua-5.1.5#gi' ./Makefile
#���ϵͳΪ64λ��ִ��������������
	#sed -i 's#^CFLAGS=.*#CFLAGS= -O2 -fPIC -Wall $(MYCFLAGS)#gi' ./src/Makefile
	make linux
	make install

##����----------------------------------------------------
	.o	==win.obj
	.a	==win.lib
	.so	==win.dll

#gcc -o luat luat.c -I[include�ļ���] -L[lib�ļ���] [.a�ļ���] -l[.so���м���] -lm -ldl
#gcc -o luat luat.c -I/usr/local/lua/include/ -L/usr/local/lua/lib/ /usr/local/lua/lib/liblua.a -llua -lm -ldl
gcc -o luat luat.c -I/home/lua-5.1.5/src/ -L/home/lua-5.1.5/src/ /home/lua-5.1.5/src/liblua.a -llua -lm -ldl
#gcc -o mylsvr mylsvr.c -Iluajit/src/ luajit/src/libluajit.a -lm -ldl	#ֻ�þ�̬��
#gcc -o mylsvr mylsvr.c -Iluajit/src/ -Iluasocket/src/ luajit/src/libluajit.a luasocket/src/libluasocket.a -lm -ldl	#ֻ�þ�̬��

#64λ�İ�װ32λ���ݿ�
	apt-get install g++-multilib
	apt-get install libncurses5:i386
	apt-get install libc6:i386 libgcc1:i386 gcc-4.6-base:i386 libstdc++5:i386 libstdc++6:i386
	apt-get install ia32-libs
#ָ������32λ
	gcc -m32

#makefile��ʽ
objects = main.o need1.o
main : $(objects)
	gcc -o main $(objects)
#	ar cr libXXX.a $(objects)	#����һ����̬��
main.o: need1.h
need1.o: need1.h
.PHONY:clean
clean :
	-rm -f main *.o

##��װopenresty
	http://blog.51cto.com/niming2008/2121354
	yum install openresty -y
	#if Require GeoIP
	#yum install epel-release
	#yum --enablerepo=epel install geoip
	#endif
	vim /usr/local/openresty/nginx/conf/nginx.conf #�Ķ˿�
	#����
	/usr/local/openresty/nginx/sbin/nginx -c /usr/local/openresty/nginx/conf/nginx.conf

##����
location = / {
    lua_code_cache on;
    add_header Access-Control-Allow-Origin *;
    add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept";
    add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
    content_by_lua_file $LUA_PATH/main.lua;
}	
	
#bad interpreter: No such file or directory���
vim xxx.sh
:set ff=unix
:wq

##Redis
#!!!redis û������Ķ���������ܻᱻע����
redis-cli -h localhost -p 6379
>GET key
>SET key val
>CONFIG GET key
>CONFIG SET protected-mode 'no'
>quit

##�ƻ�����
crontab -e
crontab -l
ls /etc/cron.d/

