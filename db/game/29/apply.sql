-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
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
	ROUND(t_complete.avg_renown/2, 1) `avg_renown/player`,
	(60 * t_complete.avg_renown/2 / t_complete.avg_minutes) `renown/hour/player`,
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

ALTER TABLE `battle` 
	ADD COLUMN `first_blood_time` BIGINT(8) NULL  AFTER `victor_delta_power`,
	ADD COLUMN `starting_team` VARCHAR(64) NULL  AFTER `first_blood_time`;
	
