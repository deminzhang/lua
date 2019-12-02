set -e
PATH=$PATH:/usr/local/postgres/bin
FORMAT=binary
FORMAT=
LOG=
TEMPD=`mktemp -d`
IGNORES="weekrankdata cs_crosstowertop cs_king_player allexchangestock allexchangelog alllotlog bigtime actrank worldboss serverdata crossdailytask crossfight crossfightpoint comactdata crosspvptopv1 crosspvptopv3 crosspvptop crosstrialrank goldboss crossmapboss jayacttime betpool betresult allbetlist allbetinfo"
CLEARS="alllotlog allexchangelog weekrankdata"
export PGPASSWORD=lost
export PGCONNECT_TIMEOUT=50
PG="psql -U sm"
getip(){
	local dom=s$1.mfwz.xiyou.xiyou-g.com
	ping $dom -c 1 | sed -n '1p' | sed -r 's/.*(\.[0-9]+\.[0-9]+)\).*/\1/g' | awk '{printf 192.168$1}'
}
getip2(){
	echo -n 127.0.0.1
}
msec(){
	echo $(($(date +%s%N)/1000000))
}
timer1(){ T1=`msec` ;}
timer2(){ T2=$(($(msec)-$T1)) ;}
log(){ LOG=$LOG$1 ; }
logc(){
	for i in $@; do
		log $i
		log ,
	done
}
dump(){
	local host=$1 port=$2 db=$3 tn
	rm -rf $TEMPD && mkdir -m 777 $TEMPD
	log 'read|'
	local ts=`$PG -h $host -p $port -F' ' -Atc "select tablename FROM pg_tables where schemaname='public'" $db `
	for tn in $ts; do
		local rn=`$PG -h $host -p $port -At -d $db -c "select count(*) from $tn"`
		echo -n $host $db $tn '->  '
		timer1
		[[ $IGNORES =~ $(printf %s "\<""$tn""\>") ]] && echo "-----SKIP-----" && continue
		$PG -h $host -p $port -c "copy $FORMAT $tn to STDOUT" $db > $TEMPD/$tn.csv
		timer2
		echo $rn 'done in ' $T2
		logc $tn $T2 $rn `stat -c%s $TEMPD/$tn.csv`
	done
	log '|'
}
copyto(){
	local host=$1 port=$2 db=$3 d
	for d in `ls $TEMPD`; do
		local tn=`basename $d .csv`
		echo -n $host $db $tn " <- "
		timer1
		psql -U postgres -h $host -p $port -c "copy $FORMAT $tn FROM '$TEMPD/$d'" $db
		timer2
		logc $tn $T2
	done
	rm -rf $TEMPD
	log '|'
}
getids(){
	local host=$1 port=$2 db=$3
	$PG -h $host -p $port -Atc "select 'select sequence_name,last_value from '|| relname||';' FROM pg_class c where c.relkind='S' order by relname" $db | $PG -h $host -p $port -At -F ' ' $db
}
getcols(){
	local host=$1 port=$2 db=$3
	$PG -h $host -p $port -P pager=off -Atc "select table_name||array_agg(column_name::text)::text n from(select table_name ,column_name from information_schema.columns where table_schema='public'order by table_name, ordinal_position) c group by table_name" $db
}
getver(){
	local host=$1 port=$2 db=$3 server=$4
	$PG -h $host -p $port -Atc "select ver from version where serverid=$server" $db
}
gettime(){
	local host=$1 port=$2 db=$3 server=$4
	$PG -h $host -p $port -Atc "select (year, month, day, hour, min, sec)::text from bigtime where serverid=$server" $db
}
cleartb(){
	local tn
	for tn in $CLEARS; do
		psql -U postgres -h $TIP -p $TPORT -d $TDB -Atc "delete from $tn"
	done
}
backup(){
	echo $FIP $FDB $TIP $TDB
	dump $FIP $FPORT $FDB
	psql -U postgres -c "insert into version values(-1, false, 0)" $TDB
	copyto $TIP $TPORT $TDB
	psql -U postgres -c "delete from version where serverid=-1" $TDB
	cleartb
}
doseqs(){
	local ia=(`getids $FIP $FPORT $FDB`)
	local ib=(`getids $TIP $TPORT $TDB`)
	[[ "${#ia[@]}" -ne "${#ib[@]}" ]] && echo ${#ia[@]} ${#ib[@]} seq count not match && exit 4
	for i in `seq 1 2 ${#ia[@]}`; do
		local j=$(( i - 1 ))
		[[ $IGNORES =~ $(printf %s "\<""${ia[$j]}""\>") ]] && continue
		[[ ${ia[$i]} -lt ${ib[$i]} ]] && continue
		PGPASSWORD= psql -U postgres -h $TIP -p $TPORT -d $TDB\
			-Atc "select setval('${ia[$j]}'::varchar, ${ia[$i]})" >/dev/null && echo "+ seq" ${ia[$j]} ${ia[$i]}' done'
	done
}
check(){
	local va=`getver $FIP $FPORT $FDB $FROM`
	local vb=`getver $TIP $TPORT $TDB $TO`
	[[ "$va" != "$vb" ]] && echo $va $vb 'ver not match' && exit 2
	local ta=`gettime $FIP $FPORT $FDB $FROM`
	local tb=`gettime $TIP $TPORT $TDB $TO`
#	[[ "$ta" != "$tb" ]] && echo $ta $tb $FROM 'bigtime not match' && exit 3
	local a=(`getcols $FIP $FPORT $FDB`)
	local b=(`getcols $TIP $TPORT $TDB`)
	for i in {0..1000}; do
		local a0=${a[$i]}
		local b0=${b[$i]}
		[[ "$a0" = "$b0" ]] && [[ -z "$a0" ]] && break
		[[ "$a0" != "$b0" ]] && echo $a0 && echo -e $b0 "\n!!! $FROM  table schema NOT match" && exit 1
	done
	echo + check done $FROM $TO
}
report(){
	echo $LOG | curl -X POST --data-binary @- 119.29.205.241:9005 >/dev/null 2>&1
}
onerr(){
	report
}
checkall(){
	local i
	for i in `seq $2 $3`; do
		check $1 $i
	done
}
doall(){
	SERVER=$1
	shift
	echo $@ $SERVER
	for s in $@; do
		echo $s
		getargs $SERVER $s
		check
	done
	for s in $@; do
		getargs $SERVER $s
		doseqs
		backup
	done
	echo all done
	rm -rf $TEMPD
}
trap onerr 0
getargs(){
	local from=$2 to=$1
	read FIP FPORT FDB TIP TPORT TDB FROM TO <<<\
		`echo  $from $to | sed "s/[:,]/ /g" | awk '{printf("%s %s sm%05d %s %s sm%05d %d %d", $1,$2,$3,$4,$5,$6,$3,$6)}'`
}
[[ -z $1 ]] && echo './merge.sh 127.0.0.1:5432,1 ip:5432,4 ip:5432,7 ip:5432,10' && exit -1
#alias getip=getip2
#getargs 127.0.0.1:5432,99982 localhost:5432
logc `date +%s`  $@; log '|'
doall $@
logc `date +%s` '|done'
#dump $FIP $FPORT $FDB
#check
#doseqs
#backup
# sh m.sh 127.0.0.1:5432,99982 127.0.0.1:5432,1
