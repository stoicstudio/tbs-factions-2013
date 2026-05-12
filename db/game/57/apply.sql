
DROP PROCEDURE IF EXISTS battle_chart_daily;

DELIMITER $$

CREATE PROCEDURE `battle_chart_daily`(IN _limit_param INT(4))
BEGIN
 
SELECT 
    t_complete.`day` as `GMT`,
	t_distinct.distinct_users,
	t_complete.completed, 
	ROUND(t_complete.completed / t_distinct.distinct_users, 1) as `battles/user`,
	t_complete.renown, 
	t_complete.avg_minutes, 
	ROUND(t_complete.avg_renown/2, 1) `avg_renown/player`,
	ROUND(60 * t_complete.avg_renown/2 / t_complete.avg_minutes, 1) `renown/hour/player`,
	t_failed.aborts,
	t_failed.diverged,
	t_first.first_users

	FROM
	( 
		SELECT
			t1.create_time,
			@_day as `day`,
			count(distinct t1.battle_id) as `completed`,
			sum(t1.renown) as `renown`,
			ROUND(AVG(t1.end_time - t1.create_time) / 60000, 1) as `avg_minutes`,
			ROUND(AVG(t1.num_turns)) as `avg_turns`,
			AVG(t1.renown) as `avg_renown`,
			SUM(t1.surrender) as surrenders
		from
			battle as t1
		where
			num_turns > 0 AND aborted IS NULL
		group by 			
			@_day:=CAST(date(FROM_UNIXTIME(t1.create_time/1000)) as DATE)
	) t_complete

	JOIN
(
	(
		SELECT
			@_day as `day`,
			COUNT(distinct t1.battle_id) as `failed`,
			SUM(aborted) as `aborts`,
			COUNT(diverged) as `diverged`
		from
			battle as t1
		where
			num_turns = 0 OR aborted = 1
		group by 
			@_day:=CAST(date(FROM_UNIXTIME(t1.create_time/1000)) as DATE)
	) t_failed,
	(
		select 
			COUNT(distinct battle_party.account_id) as `distinct_users`,
			@_day as `day`
		from battle_party
		where
			battle_party.complete = 1
		group by 			
			@_day:=CAST(date(FROM_UNIXTIME(battle_party.create_time/1000)) as DATE)

	) t_distinct,
	(
		select 
			COUNT( auth_account.account_id) as `first_users`,
			@_day as `day`
		from auth_account
		group by 			
			@_day:=CAST(date(auth_account.create_date) as DATE)

	) t_first
)

ON (t_complete.`day` = t_failed.`day` and t_distinct.`day` = t_complete.`day` and t_first.`day` = t_complete.`day`)

WHERE 
	DATEDIFF(NOW(), t_complete.`day`) < _limit_param
order by t_complete.create_time asc;


END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS user_chart_daily;

DELIMITER $$

CREATE PROCEDURE `user_chart_daily`(IN _limit_param INT(4))
BEGIN

select 
t_first._day,
t_first.first_users,
t_distinct.distinct_users
from
	(
		select 
			COUNT( auth_account.account_id) as first_users,
			@_day _day
		from auth_account
		group by 			
			@_day:=CAST(date(auth_account.create_date) as DATE)

	) t_first

 left JOIN
	(
		select 
			COUNT(distinct session_history.account_id) as distinct_users,
			@_day _day
		from session_history
		group by 			
			@_day:=CAST(date(FROM_UNIXTIME(session_history.session_start/1000)) as DATE)

	) t_distinct

	on (t_distinct._day = t_first._day)

WHERE 
	DATEDIFF(NOW(), t_first._day) < _limit_param

order by t_first._day;


END$$

DELIMITER ;