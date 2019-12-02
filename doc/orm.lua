
_G.ORM = {}
ORM._caches = {}

function ORM:run(stmt,...)
	--"select a,b from tbl_character where a=?;", 123,456)
	--"select b,a from tbl_character where b=?;", 123,456)
	--"select a,b from tbl_character where a=? and b=?;", 123,456)
	if ORM._caches[stmt] then
	else
		ORM._caches[stmt] = {}
	end
	if ORM._caches[stmt][...] then return ORM._caches[stmt][...] end
	ORM._caches[stmt][...] = db:run(stmt,...)
	
end