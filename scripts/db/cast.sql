--中文
drop cast if exists (timestamp as int8);
drop cast if exists (int8 as timestamp);
create cast (timestamp as int8) without function;
create cast (int8 as timestamp) without function;

-- TODO REPLACE INTO tbl(charId,deleteTime,occurTime) values ({0},{1},{2})",charId,0,external.getUnixTime())
--
-- CREATE FUNCTION replaceinto(key INT, data TEXT) RETURNS VOID AS 
-- $$ 
-- BEGIN 
	-- LOOP 
		-- UPDATE tb SET b = data WHERE a = key; 
		-- IF found THEN 
			-- RETURN; 
		-- END IF; 

		-- BEGIN 
			-- INSERT INTO tb(a,b) VALUES (key, data); 
			-- RETURN; 
		-- EXCEPTION WHEN unique_violation THEN 
			-- do nothing 
		-- END; 
	-- END LOOP; 
-- END; 
-- $$ 
-- LANGUAGE plpgsql; 
