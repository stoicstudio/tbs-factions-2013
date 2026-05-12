-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE PROCEDURE `db_usage_by_storage_engine` ()
BEGIN
SELECT
    IFNULL(ENGINE,'Total') "Storage Engine",
    LPAD(CONCAT(FORMAT(DAT/POWER(1024,pw1),2),' ',
    SUBSTR(units,pw1*2+1,2)),17,' ') "Data Size",
    LPAD(CONCAT(FORMAT(NDX/POWER(1024,pw2),2),' ',
    SUBSTR(units,pw2*2+1,2)),17,' ') "Index Size",
    LPAD(CONCAT(FORMAT(TBL/POWER(1024,pw3),2),' ',
    SUBSTR(units,pw3*2+1,2)),17,' ') "Total Size"
FROM
(
    SELECT ENGINE,DAT,NDX,TBL,
    IF(px>4,4,px) pw1,IF(py>4,4,py) pw2,IF(pz>4,4,pz) pw3
    FROM 
    (SELECT *,
        FLOOR(LOG(IF(DAT=0,1,DAT))/LOG(1024)) px,
        FLOOR(LOG(IF(NDX=0,1,NDX))/LOG(1024)) py,
        FLOOR(LOG(IF(TBL=0,1,TBL))/LOG(1024)) pz
        FROM
        (SELECT
            ENGINE,
            SUM(data_length) DAT,
            SUM(index_length) NDX,
            SUM(data_length+index_length) TBL
        FROM
        (
           SELECT engine,data_length,index_length FROM
           information_schema.tables WHERE table_schema NOT IN
           ('information_schema','performance_schema','mysql')
           AND ENGINE IS NOT NULL
        ) AAA GROUP BY ENGINE WITH ROLLUP
) AAA ) AA) A,(SELECT ' BKBMBGBTB' units) B;
END$$

CREATE PROCEDURE `db_usage_by_database` ()
BEGIN
SELECT
    IFNULL(DB,'Total') "Database",
    LPAD(CONCAT(FORMAT(DAT/POWER(1024,pw1),2),' ',
    SUBSTR(units,pw1*2+1,2)),17,' ') "Data Size",
    LPAD(CONCAT(FORMAT(NDX/POWER(1024,pw2),2),' ',
    SUBSTR(units,pw2*2+1,2)),17,' ') "Index Size",
    LPAD(CONCAT(FORMAT(TBL/POWER(1024,pw3),2),' ',
    SUBSTR(units,pw3*2+1,2)),17,' ') "Total Size"
FROM
(
    SELECT DB,DAT,NDX,TBL,
    IF(px>4,4,px) pw1,IF(py>4,4,py) pw2,IF(pz>4,4,pz) pw3
    FROM 
    (SELECT *,
        FLOOR(LOG(IF(DAT=0,1,DAT))/LOG(1024)) px,
        FLOOR(LOG(IF(NDX=0,1,NDX))/LOG(1024)) py,
        FLOOR(LOG(IF(TBL=0,1,TBL))/LOG(1024)) pz
    FROM
    (SELECT
        DB,
        SUM(data_length) DAT,
        SUM(index_length) NDX,
        SUM(data_length+index_length) TBL
    FROM
    (
       SELECT table_schema DB,data_length,index_length FROM
       information_schema.tables WHERE table_schema NOT IN
       ('information_schema','performance_schema','mysql')
       AND ENGINE IS NOT NULL
    ) AAA GROUP BY DB WITH ROLLUP
) AAA) AA) A,(SELECT ' BKBMBGBTB' units) B;
END$$

CREATE PROCEDURE `db_usage_by_all` ()
BEGIN
SELECT
    IF(ISNULL(DB)+ISNULL(ENGINE)=2,'Database Total',
    CONCAT(DB,' ',IFNULL(ENGINE,'Total'))) "Reported Statistic",
    LPAD(CONCAT(FORMAT(DAT/POWER(1024,pw1),2),' ',
    SUBSTR(units,pw1*2+1,2)),17,' ') "Data Size",
    LPAD(CONCAT(FORMAT(NDX/POWER(1024,pw2),2),' ',
    SUBSTR(units,pw2*2+1,2)),17,' ') "Index Size",
    LPAD(CONCAT(FORMAT(TBL/POWER(1024,pw3),2),' ',
    SUBSTR(units,pw3*2+1,2)),17,' ') "Total Size"
FROM
(
    SELECT DB,ENGINE,DAT,NDX,TBL,
    IF(px>4,4,px) pw1,IF(py>4,4,py) pw2,IF(pz>4,4,pz) pw3
    FROM 
    (SELECT *,
        FLOOR(LOG(IF(DAT=0,1,DAT))/LOG(1024)) px,
        FLOOR(LOG(IF(NDX=0,1,NDX))/LOG(1024)) py,
        FLOOR(LOG(IF(TBL=0,1,TBL))/LOG(1024)) pz
    FROM
    (SELECT
        DB,ENGINE,
        SUM(data_length) DAT,
        SUM(index_length) NDX,
        SUM(data_length+index_length) TBL
    FROM
    (
       SELECT table_schema DB,ENGINE,data_length,index_length FROM
       information_schema.tables WHERE table_schema NOT IN
       ('information_schema','performance_schema','mysql')
       AND ENGINE IS NOT NULL
    ) AAA GROUP BY DB,ENGINE WITH ROLLUP
) AAA) AA) A,(SELECT ' BKBMBGBTB' units) B;
END$$

CREATE  TABLE `metrics_days` (
	start_date	DATETIME NOT NULL,
	users	INT(4) NOT NULL,
	firsts	INT(4) NOT NULL,
	returned	INT(4) NOT NULL,
	session_length_mins	INT(4) NOT NULL,
	buyers	INT(4) NOT NULL,
	total_usd	INT(4) NOT NULL,
	ppu	FLOAT NOT NULL,
	arpu	FLOAT NOT NULL,
	arppu	FLOAT NOT NULL,
	btl_conv	INT(4) NOT NULL,
	vs_conv	INT(4) NOT NULL,
	returned_pct	FLOAT NOT NULL,
	btl_conv_pct	FLOAT NOT NULL,
	vs_conv_pct	FLOAT NOT NULL,
	vs_success_wait	INT(4) NOT NULL,
	vs_fail_wait	INT(4) NOT NULL,
	vs_success_pct	FLOAT NOT NULL,
	complete TINYINT NOT NULL,
PRIMARY KEY (start_date) )$$

  CREATE  TABLE `metrics_weeks` (
	start_date	DATETIME NOT NULL,
	users	INT(4) NOT NULL,
	firsts	INT(4) NOT NULL,
	returned	INT(4) NOT NULL,
	session_length_mins	INT(4) NOT NULL,
	buyers	INT(4) NOT NULL,
	total_usd	INT(4) NOT NULL,
	ppu	FLOAT NOT NULL,
	arpu	FLOAT NOT NULL,
	arppu	FLOAT NOT NULL,
	btl_conv	INT(4) NOT NULL,
	vs_conv	INT(4) NOT NULL,
	returned_pct	FLOAT NOT NULL,
	btl_conv_pct	FLOAT NOT NULL,
	vs_conv_pct	FLOAT NOT NULL,
	vs_success_wait	INT(4) NOT NULL,
	vs_fail_wait	INT(4) NOT NULL,
	vs_success_pct	FLOAT NOT NULL,
 	complete TINYINT NOT NULL,
 PRIMARY KEY (start_date) )$$
  
  CREATE  TABLE `metrics_months` (
	start_date	DATETIME NOT NULL,
	users	INT(4) NOT NULL,
	firsts	INT(4) NOT NULL,
	returned	INT(4) NOT NULL,
	session_length_mins	INT(4) NOT NULL,
	buyers	INT(4) NOT NULL,
	total_usd	INT(4) NOT NULL,
	ppu	FLOAT NOT NULL,
	arpu	FLOAT NOT NULL,
	arppu	FLOAT NOT NULL,
	btl_conv	INT(4) NOT NULL,
	vs_conv	INT(4) NOT NULL,
	returned_pct	FLOAT NOT NULL,
	btl_conv_pct	FLOAT NOT NULL,
	vs_conv_pct	FLOAT NOT NULL,
	vs_success_wait	INT(4) NOT NULL,
	vs_fail_wait	INT(4) NOT NULL,
	vs_success_pct	FLOAT NOT NULL,
	complete TINYINT NOT NULL,
  PRIMARY KEY (start_date) )$$
  
  -- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------

CREATE PROCEDURE `metrics_days` ()
BEGIN

declare _start_datetime DATETIME;
DECLARE _end_datetime DATETIME;

declare _start_ms BIGINT(8);
declare _end_ms BIGINT(8);

select NOW() into _end_datetime;
select IFNULL(MAX(start_date), '2013-01-01') INTO _start_datetime from metrics_days WHERE complete=1;

set _start_ms = UNIX_TIMESTAMP(_start_datetime) * 1000;
set _end_ms = UNIX_TIMESTAMP(_end_datetime) * 1000;

replace into metrics_days
select 
t_users._date
, users
, firsts
, returned
, round(session_length_mins) session_length_mins
, IFNULL(buyers, 0) buyers
, IF(total_usd is not null, round(total_usd, 0), 0) total_usd
, IF(buyers is not null and users is not null and users != 0, format(buyers/users, 3), 0) ppu
, IF(total_usd is not null and users is not null and users != 0, format(total_usd/users, 3), 0) arpu
, IF(total_usd is not null and buyers is not null and users != 0, format(total_usd/buyers, 2), 0) arppu 
, IFNULL(btl_conv, 0) btl_conv
, IFNULL(vs_conv, 0) vs_conv
, IF(returned is not null and firsts is not null and firsts != 0, format(returned/firsts, 2), 0) returned_pct
, IF(btl_conv is not null and firsts is not null and firsts != 0, format(btl_conv/firsts, 2), 0) btl_conv_pct
, IF(vs_conv is not null and firsts is not null and firsts != 0, format(vs_conv/firsts, 2), 0) vs_conv_pct
, IF(vs_success_wait is not null, round(vs_success_wait), 0) vs_success_wait
, IF(vs_fail_wait is not null, round(vs_fail_wait), 0) vs_fail_wait
, IF(vs_success_pct is not null, format(vs_success_pct, 2), 0) vs_success_pct
, IF((t_users._date + INTERVAL 1 DAY) < NOW(), 1, 0) complete

from

(
	select 
		date(FROM_UNIXTIME(session_start/1000)) as _date
		, count(distinct account_id) users
		, count(distinct IF(session_history.login_count = 1, account_id, NULL)) firsts
		, count(distinct IF(session_history.login_count = 1 and account_info.login_count> 1, account_id, NULL)) returned
		, AVG(session_history.session_end - session_history.session_start) / (1000 * 60) session_length_mins
	from session_history
	join account_info
	using (account_id)
	where 
		session_start>= _start_ms
		and session_start < _end_ms
		and session_end is not null
	group by _date
) t_users

join
(
	(
		select 
			date(FROM_UNIXTIME(txn_init_time/1000)) as _date
			, sum(total_usd_estimate)/100 as total_usd 
			, count(distinct account_id) buyers 
		from iap_txn 
		where 
			success=1 
			and total_usd_estimate > 0 
			and txn_init_time >= _start_ms
			and txn_init_time < _end_ms
		group by _date
	) t_buyers,
	(
		select 
			date(auth_account.create_date) as _date
			, COUNT(distinct battle_party.account_id) as btl_conv
		from battle_party
		join auth_account
		on (battle_party.account_id = auth_account.account_id)
		where
			auth_account.create_date >= _start_datetime
			and auth_account.create_date < _end_datetime
		group by _date
	) t_btl_conv,
	(
		select 
			date(auth_account.create_date) as _date
			, COUNT(distinct vs_find.account_id) as vs_conv
		from vs_find
		join auth_account
		on (vs_find.account_id = auth_account.account_id)
		where
			auth_account.create_date >= _start_datetime
			and auth_account.create_date < _end_datetime
		group by _date
	) t_vs_conv,
	(
		select
			date(FROM_UNIXTIME(vs_start_time/1000)) as _date
			, AVG(IF(vs_battle_id IS NOT NULL, vs_end_time-vs_start_time, NULL)) / 1000 vs_success_wait
			, AVG(IF(vs_battle_id IS NULL, vs_end_time-vs_start_time, NULL)) / 1000 vs_fail_wait
			, COUNT(vs_battle_id) / COUNT(*) vs_success_pct
		from vs_find
		where
			vs_start_time >= _start_ms
			and vs_end_time < _end_ms
			and vs_end_time is not null
		group by _date
	) t_vs_stats
)

on 
(
	t_users._date=t_buyers._date 
	and t_users._date = t_btl_conv._date
	and t_users._date = t_vs_conv._date
	and t_users._date = t_vs_stats._date
);

END$$


CREATE PROCEDURE `metrics_weeks` ()
BEGIN

declare _start_datetime DATETIME;
DECLARE _end_datetime DATETIME;

declare _start_ms BIGINT(8);
declare _end_ms BIGINT(8);

select NOW() into _end_datetime;
select IFNULL(MAX(start_date), '2013-01-01') INTO _start_datetime from metrics_days WHERE complete=1;

set _start_ms = UNIX_TIMESTAMP(_start_datetime) * 1000;
set _end_ms = UNIX_TIMESTAMP(_end_datetime) * 1000;


-- this one by weeks!

replace into metrics_weeks
select 
t_users._date
, users
, firsts
, returned
, round(session_length_mins) session_length_mins
, IFNULL(buyers, 0) buyers
, IF(total_usd is not null, round(total_usd, 0), 0) total_usd
, IF(buyers is not null and users is not null and users != 0, format(buyers/users, 3), 0) ppu
, IF(total_usd is not null and users is not null and users != 0, format(total_usd/users, 3), 0) arpu
, IF(total_usd is not null and buyers is not null and users != 0, format(total_usd/buyers, 2), 0) arppu 
, IFNULL(btl_conv, 0) btl_conv
, IFNULL(vs_conv, 0) vs_conv
, IF(returned is not null and firsts is not null and firsts != 0, format(returned/firsts, 2), 0) returned_pct
, IF(btl_conv is not null and firsts is not null and firsts != 0, format(btl_conv/firsts, 2), 0) btl_conv_pct
, IF(vs_conv is not null and firsts is not null and firsts != 0, format(vs_conv/firsts, 2), 0) vs_conv_pct
, IF(vs_success_wait is not null, round(vs_success_wait), 0) vs_success_wait
, IF(vs_fail_wait is not null, round(vs_fail_wait), 0) vs_fail_wait
, IF(vs_success_pct is not null, format(vs_success_pct, 2), 0) vs_success_pct
, IF((t_users._date + INTERVAL 1 DAY) < NOW(), 1, 0) complete

from

(
	select 
		date(FROM_DAYS(FLOOR(TO_DAYS(FROM_UNIXTIME(session_start/1000)) / 7) * 7 + 1)) as _date		
		, count(distinct account_id) users
		, count(distinct IF(session_history.login_count = 1, account_id, NULL)) firsts
		, count(distinct IF(session_history.login_count = 1 and account_info.login_count> 1, account_id, NULL)) returned
		, AVG(session_history.session_end - session_history.session_start) / (1000 * 60) session_length_mins
	from session_history
	join account_info
	using (account_id)
	where 
		session_start>= _start_ms
		and session_start < _end_ms
		and session_end is not null
	group by _date
) t_users

join
(
	(
		select 
		date(FROM_DAYS(FLOOR(TO_DAYS(FROM_UNIXTIME(txn_init_time/1000)) / 7) * 7 + 1)) as _date		
			, sum(total_usd_estimate)/100 as total_usd 
			, count(distinct account_id) buyers 
		from iap_txn 
		where 
			success=1 
			and total_usd_estimate > 0 
			and txn_init_time >= _start_ms
			and txn_init_time < _end_ms
		group by _date
	) t_buyers,
	(
		select
			date(FROM_DAYS(FLOOR(TO_DAYS(auth_account.create_date) / 7) * 7 + 1)) as _date		
			, COUNT(distinct battle_party.account_id) as btl_conv
		from battle_party
		join auth_account
		on (battle_party.account_id = auth_account.account_id)
		where
			auth_account.create_date >= _start_datetime
			and auth_account.create_date < _end_datetime
		group by _date
	) t_btl_conv,
	(
		select 
			date(FROM_DAYS(FLOOR(TO_DAYS(auth_account.create_date) / 7) * 7 + 1)) as _date		
			, COUNT(distinct vs_find.account_id) as vs_conv
		from vs_find
		join auth_account
		on (vs_find.account_id = auth_account.account_id)
		where
			auth_account.create_date >= _start_datetime
			and auth_account.create_date < _end_datetime
		group by _date
	) t_vs_conv,
	(
		select
			date(FROM_DAYS(FLOOR(TO_DAYS(FROM_UNIXTIME(vs_start_time/1000)) / 7) * 7 + 1)) as _date		
			, AVG(IF(vs_battle_id IS NOT NULL, vs_end_time-vs_start_time, NULL)) / 1000 vs_success_wait
			, AVG(IF(vs_battle_id IS NULL, vs_end_time-vs_start_time, NULL)) / 1000 vs_fail_wait
			, COUNT(vs_battle_id) / COUNT(*) vs_success_pct
		from vs_find
		where
			vs_start_time >= _start_ms
			and vs_end_time < _end_ms
			and vs_end_time is not null
		group by _date
	) t_vs_stats
)

on 
(
	t_users._date=t_buyers._date 
	and t_users._date = t_btl_conv._date
	and t_users._date = t_vs_conv._date
	and t_users._date = t_vs_stats._date
);

END$$

CREATE PROCEDURE `metrics_months` ()
BEGIN

declare _start_datetime DATETIME;
DECLARE _end_datetime DATETIME;

declare _start_ms BIGINT(8);
declare _end_ms BIGINT(8);

select NOW() into _end_datetime;
select IFNULL(MAX(start_date), '2013-01-01') INTO _start_datetime from metrics_days WHERE complete=1;

set _start_ms = UNIX_TIMESTAMP(_start_datetime) * 1000;
set _end_ms = UNIX_TIMESTAMP(_end_datetime) * 1000;

-- this one by months!

replace into metrics_months
select 
t_users._date
, users
, firsts
, returned
, round(session_length_mins) session_length_mins
, IFNULL(buyers, 0) buyers
, IF(total_usd is not null, round(total_usd, 0), 0) total_usd
, IF(buyers is not null and users is not null and users != 0, format(buyers/users, 3), 0) ppu
, IF(total_usd is not null and users is not null and users != 0, format(total_usd/users, 3), 0) arpu
, IF(total_usd is not null and buyers is not null and users != 0, format(total_usd/buyers, 2), 0) arppu 
, IFNULL(btl_conv, 0) btl_conv
, IFNULL(vs_conv, 0) vs_conv
, IF(returned is not null and firsts is not null and firsts != 0, format(returned/firsts, 2), 0) returned_pct
, IF(btl_conv is not null and firsts is not null and firsts != 0, format(btl_conv/firsts, 2), 0) btl_conv_pct
, IF(vs_conv is not null and firsts is not null and firsts != 0, format(vs_conv/firsts, 2), 0) vs_conv_pct
, IF(vs_success_wait is not null, round(vs_success_wait), 0) vs_success_wait
, IF(vs_fail_wait is not null, round(vs_fail_wait), 0) vs_fail_wait
, IF(vs_success_pct is not null, format(vs_success_pct, 2), 0) vs_success_pct
, IF((t_users._date + INTERVAL 1 DAY) < NOW(), 1, 0) complete

from

(
	select 
		date(FROM_DAYS(TO_DAYS(FROM_UNIXTIME(session_start/1000)) + 1 - DAYOFMONTH(FROM_UNIXTIME(session_start/1000)))) as _date		
		, count(distinct account_id) users
		, count(distinct IF(session_history.login_count = 1, account_id, NULL)) firsts
		, count(distinct IF(session_history.login_count = 1 and account_info.login_count> 1, account_id, NULL)) returned
		, AVG(session_history.session_end - session_history.session_start) / (1000 * 60) session_length_mins
	from session_history
	join account_info
	using (account_id)
	where 
		session_start>= _start_ms
		and session_start < _end_ms
		and session_end is not null
	group by _date
) t_users

join
(
	(
		select 
		date(FROM_DAYS(TO_DAYS(FROM_UNIXTIME(txn_init_time/1000)) + 1 - DAYOFMONTH(FROM_UNIXTIME(txn_init_time/1000)))) as _date		
			, sum(total_usd_estimate)/100 as total_usd 
			, count(distinct account_id) buyers 
		from iap_txn 
		where 
			success=1 
			and total_usd_estimate > 0 
			and txn_init_time >= _start_ms
			and txn_init_time < _end_ms
		group by _date
	) t_buyers,
	(
		select
			date(FROM_DAYS(TO_DAYS(auth_account.create_date) + 1 - DAYOFMONTH(auth_account.create_date))) as _date		
			, COUNT(distinct battle_party.account_id) as btl_conv
		from battle_party
		join auth_account
		on (battle_party.account_id = auth_account.account_id)
		where
			auth_account.create_date >= _start_datetime
			and auth_account.create_date < _end_datetime
		group by _date
	) t_btl_conv,
	(
		select 
			date(FROM_DAYS(TO_DAYS(auth_account.create_date) + 1 - DAYOFMONTH(auth_account.create_date))) as _date		
			, COUNT(distinct vs_find.account_id) as vs_conv
		from vs_find
		join auth_account
		on (vs_find.account_id = auth_account.account_id)
		where
			auth_account.create_date >= _start_datetime
			and auth_account.create_date < _end_datetime
		group by _date
	) t_vs_conv,
	(
		select
			date(FROM_DAYS(TO_DAYS(FROM_UNIXTIME(vs_start_time/1000)) + 1 - DAYOFMONTH(FROM_UNIXTIME(vs_start_time/1000)))) as _date		
			, AVG(IF(vs_battle_id IS NOT NULL, vs_end_time-vs_start_time, NULL)) / 1000 vs_success_wait
			, AVG(IF(vs_battle_id IS NULL, vs_end_time-vs_start_time, NULL)) / 1000 vs_fail_wait
			, COUNT(vs_battle_id) / COUNT(*) vs_success_pct
		from vs_find
		where
			vs_start_time >= _start_ms
			and vs_end_time < _end_ms
			and vs_end_time is not null
		group by _date
	) t_vs_stats
)

on 
(
	t_users._date=t_buyers._date 
	and t_users._date = t_btl_conv._date
	and t_users._date = t_vs_conv._date
	and t_users._date = t_vs_stats._date
);

END$$

delimiter ;