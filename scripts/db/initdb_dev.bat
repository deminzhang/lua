@color 2e
@chcp 65001
@cls
@title InitDB
@path=../bin64
@rem luaserver.exe dbtype=mysql host=127.0.0.1:3306 admin=root adminpw=dmz user=comb pass=comb db=comb0001
@luaserver.exe dbtype=postgres host=127.0.0.1:5432 admin=postgres adminpw=postgres user=comb pass=comb db=comb0001
@pause