DROP PROCEDURE IF EXISTS `battle_chart_hourly`;

DELIMITER $$

CREATE PROCEDURE `battle_chart_hourly`()
BEGIN

SELECT 
    FROM_UNIXTIME(t_complete.`hour`) as `GMT`,
    CONVERT_TZ(FROM_UNIXTIME(t_complete.`hour`),'+00:00','-06:00') as `CST`,
	t_complete.completed, 
	t_complete.renown, 
	t_complete.avg_minutes, 
	ROUND(t_complete.avg_renown, 1) `avg_renown`,
	(60 * t_complete.avg_renown / t_complete.avg_minutes) `renown/minutes`,
	t_failed.aborts,
	t_failed.diverged

	FROM
	( 
		SELECT
			create_time,
			(ROUND(create_time / 3600000) * 3600) as `hour`,
			count(*) as `completed`,
			sum(renown) as `renown`,
			ROUND(AVG(end_time - create_time) / 60000, 1) as `avg_minutes`,
			ROUND(AVG(num_turns)) as `avg_turns`,
			AVG(renown) as `avg_renown`,
			SUM(surrender) as surrenders
		from
			battle
		where
			num_turns > 0 AND aborted IS NULL
		group by 			
			(ROUND(create_time / 3600000) * 3600),
			to_days(FROM_UNIXTIME(create_time / 1000))
	) t_complete

	JOIN
	(
		SELECT
		(ROUND(create_time / 3600000) * 3600) as `hour`,
		COUNT(*) as `failed`,
		SUM(aborted) as `aborts`,
		SUM(diverged) as `diverged`
		from battle
		where
			num_turns = 0 OR aborted = 1
		group by 
			(ROUND(create_time / 3600000) * 3600),
			to_days(FROM_UNIXTIME(create_time / 1000))
	) t_failed

	ON (t_complete.`hour` = t_failed.`hour`)

order by t_complete.create_time asc;

END$$

DELIMITER ;


DROP PROCEDURE IF EXISTS `battle_chart_daily`;

DELIMITER $$

CREATE PROCEDURE `battle_chart_daily`()
BEGIN

SELECT 
    FROM_UNIXTIME(t_complete.`day`) as `GMT`,
    CONVERT_TZ(FROM_UNIXTIME(t_complete.`day`),'+00:00','-06:00') as `CST`,
	t_complete.completed, 
	t_complete.renown, 
	t_complete.avg_minutes, 
	ROUND(t_complete.avg_renown, 1) `avg_renown`,
	(60 * t_complete.avg_renown / t_complete.avg_minutes) `renown/minutes`,
	t_failed.aborts,
	t_failed.diverged

	FROM
	( 
		SELECT
			create_time,
			@_day as `day`,
			count(*) as `completed`,
			sum(renown) as `renown`,
			ROUND(AVG(end_time - create_time) / 60000, 1) as `avg_minutes`,
			ROUND(AVG(num_turns)) as `avg_turns`,
			AVG(renown) as `avg_renown`,
			SUM(surrender) as surrenders
		from
			battle
		where
			num_turns > 0 AND aborted IS NULL
		group by 			
			@_day:=(ROUND(create_time / (24 *3600000)) * (24*3600))
	) t_complete

	JOIN
	(
		SELECT
			@_day as `day`,
			COUNT(*) as `failed`,
			SUM(aborted) as `aborts`,
			SUM(diverged) as `diverged`
		from battle
		where
			num_turns = 0 OR aborted = 1
		group by 
			@_day:=(ROUND(create_time / (24 *3600000)) * (24*3600))
	) t_failed

	ON (t_complete.`day` = t_failed.`day`)

order by t_complete.create_time asc;

END$$

DELIMITER ;
