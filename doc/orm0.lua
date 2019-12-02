_class('ORM', Object)
function ORM.new( self, sql )
	local instance = Object.new( self )
	instance._sql = sql
	instance.pres = { } --[fname] = { [line] = { kind, statement, clos }  }
	instance._memdb = MemDB:new( )
	instance._tbs = { }
	instance.oldsession = { }
	instance.cachediffs = {} -- {clonetable, tableref, traceback}
	instance:runMem("mem.sql")
	return instance
end

function ORM.runMem( self, filename )
	self._memdb:runFile( filename )
end

function ORM.table( self, tablename )
	assert( PUBLIC or not self.session, self.session and self.session.trace, 'orm can not use more then once in one line' )
	if not self.session then
		self.session = table.clear( self.oldsession )
	end
	self.session.tablename = tablename
	if not PUBLIC then
		self.session.trace = debug.traceback( )
	end
	return self
end

function ORM.__call( self, markfile, markline )
	if markline and type( markline ) == 'number' then
		return self:mark( markfile, markline )
	else
		return self:table( markfile )
	end
end

function ORM.nowhere( self )
	self.session.nowhere = true
	return self
end

function ORM.where(self, kvs)
	if not next(kvs) then
		error( 'where is empty' )
	end
	self.session.where = kvs
	return self
end

function ORM.pkey( self, pkey )
	self.session.pkey = pkey
	return self
end

function ORM.index( self, index )
	self.session.index = index
	return self
end

function ORM.copy( self )
	self.session.copy = true
	return self
end

function ORM.mark( self, markfile, markline )
	if not self.session then
		self.session = table.clear( self.oldsession )
	end
	self.session.markfile = markfile
	self.session.markline = markline
	return self
end

function ORM.orderby( self, orderby1, desc1, orderby2, desc2, orderby3, desc3 )
	if not orderby1 then return end
	self.session.orderby = { orderby1, desc1, orderby2, desc2, orderby3, desc3 }
	--self.session.desc = desc
	return self
end

function ORM.returning( self )
	self.session.returning = true
	return self
end

function ORM.limit( self, n )
	self.session.limit = n
	return self
end

function ORM.full( self )
	self.session.full = true
	return self
end

function ORM.noPre( self )
	self.session.nopre = true
	return self
end

function ORM.norun( self )
	self.session.norun = true
	return self
end

function ORM.noCache( self )
	self.session.nocache = true
	return self
end

local function parsewhere( ws )
	local ks = table.keys( ws )
	table.sort( ks )
	local vs = { }
	for i, k in next, ks do
		vs[i] = ws[k]
	end
	return ks, vs
end

local int2dl, int2dv
local int2da, intf
local int2vs
local int2kvs
local function created( )
	if not int2dl then
		int2dl, int2dv, int2da, int2vs, int2kvs = { }, { }, { }, { }, { }
		for ii = 1, 40 do
			table.insert( int2dl, '$'..ii )
			table.insert( int2da, table.concat( {'any($', ii, ')'} ) )
			table.insert( int2dv, table.concat({ ') values (', table.concat( int2dl, ',' ),  ')' } ) )
			table.insert( int2vs, table.concat({ '(', table.concat( int2dl, ',' ),  ')' } ) )
		end
		intf = { _NIL = int2dl, _TRUE = int2dl, _FALSE = int2dl }
	end
end

function _G.int2d( ii, v )
	created( )
	if type(v)=='table' then
		return (intf[v] or int2da)[ii]
	end
	return int2dl[ii]
end

function _G.int2ds(ii)
	created( )
	return int2dv[ii]
end

function _G.int2dvs( clon, kvn )
	created( )
	int2kvs[clon] = int2kvs[clon] or { }
	local s = int2kvs[clon][kvn]
	if not s then
		local tb = { }
		for ii = 1, kvn do
			table.insert( tb, "(" )
			for kk = 1, clon do
				table.insert( tb, '$'..( (ii-1)*clon+kk ) )
				if kk ~= clon then table.insert( tb, ',' ) end
			end
			table.insert( tb, ")" )
			if ii ~= kvn then table.insert( tb, "," ) end
		end
		s = table.concat( tb, " " )
		int2kvs[clon][kvn] = s
	end
	return s
end

function ORM.findPre( self, n )
	if NOPRE then return end
	local line, source = self.session.markline, self.session.markfile
	if not line or not source then
		local info = debug.getinfo( 3 )
		line, source = info.currentline, info.source
	end
	local pres = self.pres
	local lines = pres[source]
	if not lines then return end
	local tb = lines[line]
	if not tb then return end
	if n then
		tb = tb[n]
		if not tb then return end
	end
	return tb[2], tb[3], tb[4], tb[5]
end

function ORM.template( self, tb )
	if not tb then return end
	local ntb = { }
	for ii = 1, #tb do
		ntb[ii] = 0
	end
	return table.template( ntb )
end

function ORM.cachePre( self, tb, n )
	local line, source = self.session.markline, self.session.markfile
	if not line or not source then
		local info = debug.getinfo( 3 )
		line, source = info.currentline, info.source
	end
	local pres = self.pres
	local lines = pres[source]
	if not lines then
		lines = {}
		pres[source] = lines
	end
	if not n then
		lines[line] = tb
	else
		lines[line] = lines[line] or { }
		lines[line][n] = tb
	end
	self.xpres = self.xpres or { }
	self.xpres[#self.xpres+1] = { source, line, n }
end

function ORM.mapping( self )
	local session = self.session
	local tbname = session.tablename
	local pkey = session.pkey
	local index = session.index
	self.session = nil
	if not USEMAPCACHE then return end
	return GetMapCache( ):newtb( tbname, pkey, index, session.full )
end

function ORM.get( self, pkey ) --用于那种只用主键读写的表
	local session = self.session
	local tbname = session.tablename
	self.session = nil
	return GetMapCache( ):get( tbname, pkey )
end

function ORM.set( self, pkey, ... )
	local session = self.session
	local tbname = session.tablename
	self.session = nil
	return GetMapCache( ):set( tbname, pkey, ... )
end

function ORM.selectex( self )
	local session = self.session
	local tbname = session.tablename
	local statement, clos, vls
	local where = session.where
	local stat={ 'select * from', tbname }
	if where then
		clos, vls = parsewhere( where )
		local len = #clos
		local any = len >= 1
		if any then
			table.insert( stat, 'where' )
		end
		for ii = 1, len do
			table.push( stat, clos[ii], '=', int2d( ii, vls[ii] ), 'and' )
		end
		if any then
			table.remove( stat )
		end
	end
	local orderby = session.orderby
	if orderby  then
		table.push( stat, 'order by' )
		local len = #orderby
		for ii = 1, len, 2 do
			table.push( stat, orderby[ii], orderby[ii+1] and 'desc' or 'asc' )
			if ii < len-1 then
				table.push( stat, ',' )
			end
		end
	end
	local limit = session.limit
	if limit then
		table.push( stat, 'limit', limit )
	end
	statement = table.concat( stat, ' ' )
	return statement, clos, vls
end

function ORM.select( self )
	local session = self.session
	local tbname = session.tablename
	if not tbname then error('select error table name is nil') end
	if not session.nowhere and not session.where then error( 'select error where is null' ) end
	local statement, clos, vls
	local nopre = session.nopre
	local copy = session.copy
	local nocache = session.nocache
	if not nopre then
		statement, clos, vls = self:findPre( )
	end
	if statement then
		local where = session.where
		if where then
			vls = vls or { }
			for ii = 1, #clos do
				vls[ii] = where[clos[ii]]
			end
		end
		if ORMCHECK then
			local cstatement, cclos, cvls = self:selectex( )
			if statement ~= cstatement then error( 'orm pre cache error, statement from cache do not equal from parse:'..statement.."|"..cstatement ) end
			if not table.equal( clos, cclos ) then error( 'orm pre cache error, clos from cache do not equal from parse:'..statement.."|"..cstatement ) end
			if not table.equal( vls, cvls ) then error( 'orm pre cache error, vls from cache do not equal from parse:'..statement.."|"..cstatement ) end
		end
	else
		statement, clos, vls = self:selectex( )
		if not nopre then self:cachePre( { 'select', statement, clos, vls, _now( 0 ) } ) end
	end
	self.session = nil
	--优先走映射缓存
	if GetMapCache( ):exist( tbname ) then
		return GetMapCache( ):select( tbname, session.where, clos )
	end
	local tb = self._memdb:getMemTable( tbname )
	local rt
	if tb then
		rt = tb:select( clos, vls )
	else
		if session.norun then return end
		rt = self._sql:select( tbname, statement, clos, vls, copy, nocache )
	end
	if not copy and CACHECHECK and rt and type(rt) == 'table' then
		table.insert(self.cachediffs, {table.newclone(rt), rt, string.format("[ORM CacheCheck]:table %s cache wrong:%s", tbname, debug.traceback())})
	end
	return rt
end

function ORM.updateex( self, kvs )
	local session = self.session
	local tbname = session.tablename
	local where = session.where
	local statement, clos, wclos, vls, wvls
	local stat = { 'update', tbname, 'set' }
	clos, vls = parsewhere( kvs )
	local len = #clos
	for ii = 1, len do
		table.push( stat, clos[ii], '=', int2d(ii), ',' )
	end
	table.remove( stat )
	if where then
		wclos, wvls = parsewhere( where )
		local wlen = #wclos
		local any = wlen >= 1
		if any then
			table.insert( stat, 'where' )
		end
		for ii = 1, wlen do
			table.push( stat, wclos[ii], '=', int2d( len + ii, wvls[ii] ), 'and' )
		end
		if any then
			table.remove( stat )
		end
	end
	if session.returning then
		table.insert( stat, 'returning *' )
	end
	statement = table.concat( stat, ' ' )
	return statement, clos, wclos, vls, wvls
end

function ORM.log( self, tbname )
	self._tbs[tbname] = 1
end

function ORM.update( self, kvs )
	if not kvs or not next( kvs ) then error( 'update error values is empty' ) end
	local session = self.session
	local tbname = session.tablename
	if not tbname then error( 'update error table name is nil' ) end
	if not session.nowhere and not session.where then error( 'update error where is null' ) end
	local where = session.where
	local statement, clos, wclos, vls, wvls
	local nopre = session.nopre
	if not nopre then
		statement, clos, wclos, vls, wvls = self:findPre( )
		vls = vls and vls( )
		wvls = wvls and wvls( )
	end
	if statement then
		vls = vls or { }
		for ii = 1, #clos do
			vls[ii] = kvs[clos[ii]]
		end
		if wclos then
			wvls = wvls or { }
			for ii = 1, #wclos do
				wvls[ii] = where[wclos[ii]]
			end
		end
		if ORMCHECK then
			local cstatement, cclos, cwclos, cvls, cwvls = self:updateex( kvs )
			if statement ~= cstatement then error( 'orm pre cache error, statement from cache do not equal from parse:'..statement.."|"..cstatement ) end
			if not table.equal( clos, cclos ) then error( 'orm pre cache error, clos from cache do not equal from parse:'..statement.."|"..cstatement ) end
			if not table.equal( wclos, cwclos ) then error( 'orm pre cache error, wclos from cache do not equal from parse:'..statement.."|"..cstatement ) end
			if not table.equal( vls, cvls ) then error( 'orm pre cache error, vls from cache do not equal from parse:'..statement.."|"..cstatement ) end
			if not table.equal( wvls, cwvls ) then error( 'orm pre cache error, wvls from cache do not equal from parse:'..statement.."|"..cstatement ) end
		end
	else
		statement, clos, wclos, vls, wvls = self:updateex( kvs )
		if not nopre then self:cachePre( { 'update', statement, clos, wclos, self:template( vls ), self:template( wvls ), _now( 0 ) } ) end
	end
	self.session = nil
	if GetMapCache( ):exist( tbname ) then
		assert( session.where )
		local r = GetMapCache( ):update( tbname, kvs, session.where, wclos, wvls, session.returning )
		-- Log.sys( "ORM.update#############", r )
		return r
	end
	local tb = self._memdb:getMemTable( tbname )
	if self._tbs[tbname] then
		-- Log.sys( "ORM-update", table.tostr( kvs ), table.tostr( where or EMPTY ), session.returning )
	end
	if tb then return tb:update( clos, vls, kvs, wclos, wvls, session.returning ) end
	return self._sql:update( tbname, statement, vls, wvls, kvs, where, session.returning )
end

function ORM.insertsex( self, kvs )
	local session = self.session
	local tbname = session.tablename
	local statement, clos, vlss
	local stat = { 'insert into', tbname }
	if kvs then
		vlss = { }
		local n = #kvs
		for ii = 1, n do
			local closi, vls = parsewhere( kvs[ii] )
			clos = closi
			table.push( vlss, unpack( vls ) )
		end
		table.push( stat, '(', table.concat( clos, ', ' ), ') values', int2dvs( #clos, n ) )--') values ('
	end
	if session.returning then
		table.insert( stat, 'returning *' )
	end
	statement = table.concat( stat, ' ' )
	return statement, clos, vlss
end

function ORM.inserts( self, kvs ) --因为fancy-server最大参数不可以超过127个,所以多了的话，需要拆
	if not next( kvs ) then
		self.session = nil
		return
	end
	local session = self.session
	session.returning = nil -- inserts不可以returning
	local tbname = session.tablename
	if not tbname then error( 'insert error table name is nil' ) end
	local n = #kvs
	if GetMapCache( ):exist( tbname ) then
		self.session = nil
		for ii = 1, n do
			GetMapCache( ):insert( tbname, kvs[ii] )
		end
		return
	end
	local session = self.session
	local tbname = session.tablename
	local statement, clos, vls
	local nopre = session.nopre
	if not nopre then
		statement, clos, vls = self:findPre( n )
		vls = vls and vls( )
	end
	if statement then
		vls = vls or { }
		for  ii = 1, n do
			for kk = 1, #clos do
				table.insert( vls, kvs[ii][clos[kk]] )
			end
		end
		if ORMCHECK then
			local cstatement, cclos, cvls = self:insertsex( kvs )
			if statement ~= cstatement then error( 'orm pre cache error, statement from cache do not equal from parse:'..statement.."|"..cstatement ) end
			if not table.equal( clos, cclos ) then error( 'orm pre cache error, clos from cache do not equal from parse:'..statement.."|"..cstatement ) end
			if not table.equal( vls, cvls ) then error( 'orm pre cache error, vls from cache do not equal from parse:'..statement.."|"..cstatement ) end
		end
	else
		statement, clos, vls = self:insertsex( kvs )
		if not nopre then self:cachePre( { 'insert', statement, clos, self:template( vls ), _now( 0 ) }, n ) end
	end
	local tb = self._memdb:getMemTable( tbname )
	if tb then
		self.session = nil
		for ii = 1, n  do
			tb:insert( clos, table.sub( vls, (ii-1)*n+1, ii*n ), kvs[ii] )
		end
		return n
	end

	local maxn = 127
	local clon = toint( maxn/#clos ) --单次插入的结果集行数
	local insertn = math.ceil( n/clon ) --总共的插入次数
	local pn = clon*#clos --单次插入，最小的value数量
	local rn = 0
	local statn = self:findPre( clon )
	for ii = 1, insertn do
		local maxpn, maxcn, statement, nvls, nkvs
		if ii ~= insertn then
			maxpn = ii*pn
			maxcn = ii*clon
			statement = statn
			nvls, nkvs = table.sub( vls, (ii-1)*pn+1, maxpn ), table.sub( kvs, (ii-1)*clon+1, maxcn )
			if not statn then
				statn = self:insertsex( nkvs )
				self:cachePre( { 'insert', statement, clos, nvls, _now( 0 ) }, #nkvs )
				statement = statn
			end
		else
			maxpn = #vls
			maxcn = n
			nvls, nkvs = table.sub( vls, (ii-1)*pn+1, maxpn ), table.sub( kvs, (ii-1)*clon+1, maxcn )

			statement = self:findPre( n - (insertn-1)*clon )
			if not statement then
				statement = self:insertsex( nkvs )
				self:cachePre( { 'insert', statement, clos, nvls, _now( 0 ) }, #nkvs )
			end
		end
		rn = rn + self._sql:inserts( tbname, statement, nvls, nkvs )
	end
	self.session = nil
	return rn
end

function ORM.insertex( self, kvs )
	local session = self.session
	local tbname = session.tablename
	local statement, clos, vls
	local stat = { 'insert into', tbname }
	if kvs then
		clos, vls = parsewhere( kvs )
		table.push( stat, '(', table.concat( clos, ', ' ), int2ds( #clos ) )--') values ('
	end
	table.insert( stat, 'returning *' )
	statement = table.concat( stat, ' ' )
	return statement, clos, vls
end

function ORM.insert( self, kvs )
	local session = self.session
	local tbname = session.tablename
	if not tbname then error( 'insert error table name is nil' ) end
	if not next( kvs ) then error( 'insert error value is empty' ) end
	if GetMapCache( ):exist( tbname ) then
		self.session = nil
		return GetMapCache( ):insert( tbname, kvs )
	end
	local statement, clos, vls
	local nopre = session.nopre
	if not nopre then
		statement, clos, vls = self:findPre( )
		vls = vls and vls( )
	end
	if statement then
		vls = vls or { }
		for ii = 1, #clos do
			vls[ii] = kvs[clos[ii]]
		end
		if ORMCHECK then
			local cstatement, cclos, cvls = self:insertex( kvs )
			if statement ~= cstatement then error( 'orm pre cache error, statement from cache do not equal from parse:'..statement.."|"..cstatement ) end
			if not table.equal( clos, cclos ) then error( 'orm pre cache error, clos from cache do not equal from parse:'..statement.."|"..cstatement ) end
			if not table.equal( vls, cvls ) then error( 'orm pre cache error, vls from cache do not equal from parse:'..statement.."|"..cstatement ) end
		end
	else
		statement, clos, vls = self:insertex( kvs )
		if not nopre then self:cachePre( { 'insert', statement, clos, self:template( vls ), _now( 0 ) } ) end
	end
	local tb = self._memdb:getMemTable( tbname )
	self.session = nil
	if tb then return tb:insert( clos, vls, kvs ) end
	return self._sql:insert( tbname, statement, vls, kvs )
end

function ORM.updateinsert( self, kvs )
	--TODO 优化，合成1个sql语句，考虑memtable
	local session = self.session
	session.returning = true
	self:noPre( )
	local rt = self:update( kvs )
	if rt and rt ~= 0  then return rt end
	self.session = session
	return self:insert( kvs )
end

function ORM.deleteex( self )
	local session = self.session
	local tbname = session.tablename
	local where = session.where
	local statement, clos, vls
	local stat = { 'delete from', tbname }
	if where then
		clos, vls = parsewhere( where )
		local len = #clos
		local any = len>=1
		if any then
			table.insert( stat, 'where' )
		end
		for ii = 1, len do
			table.push( stat, clos[ii], '=', int2d( ii, vls[ii] ), 'and' )
		end
		if any then
			table.remove( stat )
		end
	end
	if session.returning then
		table.insert( stat, 'returning *' )
	end
	statement = table.concat( stat, ' ' )
	return statement, clos, vls
end

function ORM.delete( self )
	local session = self.session
	local tbname = session.tablename
	if not tbname then error( 'delete errot table name is nil' ) end
	if not session.nowhere and not session.where then error( 'delete error where is null' ) end
	local where = session.where
	local nopre = session.nopre
	local statement, clos, vls
	if not nopre then
		statement, clos, vls = self:findPre( )
		vls = vls and vls( )
	end
	if statement then
		if clos then
			vls = vls or { }
			for ii = 1, #clos do
				vls[ii] = where[clos[ii]]
			end
		end
		if ORMCHECK then
			local cstatement, cclos, cvls = self:deleteex( )
			if statement ~= cstatement then error( 'orm pre cache error, statement from cache do not equal from parse:'..statement.."|"..cstatement ) end
			if not table.equal( clos, cclos ) then error( 'orm pre cache error, clos from cache do not equal from parse:'..statement.."|"..cstatement ) end
			if not table.equal( vls, cvls ) then error( 'orm pre cache error, vls from cache do not equal from parse:'..statement.."|"..cstatement ) end
		end
	else
		statement, clos, vls = self:deleteex( )
		if not nopre then self:cachePre( { 'delete', statement, clos, self:template( vls ), _now( 0 ) } ) end
	end
	self.session = nil
	if GetMapCache( ):exist( tbname ) then
		assert( session.where )
		return GetMapCache( ):delete( tbname, where, clos, session.returning )
	end
	local tb = self._memdb:getMemTable( tbname )
	if tb then return tb:delete( clos, vls, session.returning ) end
	return self._sql:delete(tbname, statement, vls, where, session.norun )
end

function ORM.truncate( self )
	local tbname = self.session.tablename
	self.session = nil
	local tb = self._memdb:getMemTable( tbname )
	if tb then return tb:truncate( ) end
	return self._sql:truncate( tbname, 'truncate table '..tbname )
end

function ORM.clearCache( tbname )
	local tb = self._memdb:getMemTable( tbname )
	if tb then tb:truncate( ) return end
	GetCache( ):cut( tbname )
end

function ORM.begin( self, fn )
	self._memdb:begin( fn )
	self._sql:begin( fn )
end

function ORM.commit( self )
	GetMapCache( ):commit( )
	if not self._sql:commit( ) then
		self:rollback( )
		return
	end
	self._memdb:commit( )
	GetMapCache( ):memcommit( )
end

function ORM.rollback( self )
	if self.xpres then
		for k, v in pairs( self.xpres ) do
			if v[3] then
				self.pres[v[1]][v[2]][v[3]] = nil
			else
				self.pres[v[1]][v[2]] = nil
			end
		end
		self.xpres = nil
	end
	self.session = nil
	self._memdb:rollback( )
	self._sql:rollback( )
	GetMapCache( ):rollback( )
end

function ORM.clean( self )
	GetCache( ):clean( )
	GetMapCache( ):clean( )
end

function ORM.cacheCheck(self)
	for i=1, #self.cachediffs do
		local diff = self.cachediffs[i]
		if not table.equal(diff[1], diff[2]) then
			return false, diff[3]
		end
	end
	self.cachediffs = {}
	return true
end