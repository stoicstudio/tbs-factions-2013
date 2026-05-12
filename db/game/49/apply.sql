
DROP PROCEDURE IF EXISTS user_chart_daily;

DELIMITER $$

CREATE PROCEDURE `user_chart_daily`()
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

order by t_first._day;


END $$

DELIMITER ;