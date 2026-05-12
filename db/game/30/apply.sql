DROP PROCEDURE IF EXISTS `battle_chart_daily`;

DELIMITER $$

CREATE PROCEDURE `battle_chart_daily`()
BEGIN
	
SELECT 
    FROM_UNIXTIME(t_complete.`day`) as `GMT`,
    CONVERT_TZ(FROM_UNIXTIME(t_complete.`day`),'+00:00','-06:00') as `CST`,
	t_complete.distinct_users,
	t_complete.completed, 
	ROUND(t_complete.completed / t_complete.distinct_users, 1) as `battles/user`,
	t_complete.renown, 
	t_complete.avg_minutes, 
	ROUND(t_complete.avg_renown/2, 1) `avg_renown/player`,
	ROUND(60 * t_complete.avg_renown/2 / t_complete.avg_minutes, 1) `renown/hour/player`,
	t_failed.aborts,
	t_failed.diverged

	FROM
	( 
		SELECT
			create_time,
			@_day as `day`,
			count(distinct t1.battle_id) as `completed`,
			sum(t1.renown) as `renown`,
			ROUND(AVG(t1.end_time - t1.create_time) / 60000, 1) as `avg_minutes`,
			ROUND(AVG(t1.num_turns)) as `avg_turns`,
			AVG(t1.renown) as `avg_renown`,
			SUM(t1.surrender) as surrenders,
			COUNT(distinct t1.battle_team) as `distinct_users`
		from
			battle as t1
		join 
			battle_party as t2
		on 
			(t1.battle_id = t2.battle_id)
		where
			num_turns > 0 AND aborted IS NULL
		group by 			
			@_day:=(FLOOR(create_time / (24 *3600000)) * (24*3600))
	) t_complete

	JOIN
	(
		SELECT
			@_day as `day`,
			COUNT(distinct t1.battle_id) as `failed`,
			SUM(aborted) as `aborts`,
			SUM(diverged) as `diverged`,
			COUNT(DISTINCT t2.battle_team) as `distinct_users`
		from
			battle as t1
		join 
			battle_party as t2
		on 
			(t1.battle_id = t2.battle_id)
		where
			num_turns = 0 OR aborted = 1
		group by 
			@_day:=(FLOOR(create_time / (24 *3600000)) * (24*3600))
	) t_failed

	ON (t_complete.`day` = t_failed.`day`)

order by t_complete.create_time asc;

END$$

DELIMITER  ;

delete from unit_party;
delete from unit_roster;
update account_info set account_renown=2000;

