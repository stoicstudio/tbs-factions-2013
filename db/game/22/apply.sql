ALTER TABLE `battle`
	ADD COLUMN `victor_delta_elo` INT(4) NULL DEFAULT NULL  AFTER `battle_create_data` , 
	ADD COLUMN `victor_delta_power` INT(4) NULL DEFAULT NULL  AFTER `victor_delta_elo` ;
	
ALTER TABLE `vs_find` 
	ADD COLUMN `elo` INT(4) NULL  AFTER `vs_power` ;

ALTER TABLE `battle_party` 
	ADD COLUMN `elo` INT(4) NULL DEFAULT NULL  AFTER `battle_surrender_turn` , 
	ADD COLUMN `power` INT(4) NULL DEFAULT NULL  AFTER `elo` ;

DROP PROCEDURE IF EXISTS `battle_chart`;

DELIMITER $$

CREATE PROCEDURE `battle_chart`()
BEGIN

SELECT 
    FROM_UNIXTIME(ROUND(create_time / 3600000) * 3600) as `GMT`,
    CONVERT_TZ(FROM_UNIXTIME(ROUND(create_time / 3600000) * 3600),'+00:00','-06:00') as `CST`,
    count(*) as `started`,
    count(end_time) as `ended`,
    sum(renown) as `renown`,
    ROUND(AVG(end_time - create_time) / 60000) as `avg minutes`,
    ROUND(AVG(num_turns)) as `avg turns`,
    ROUND(SUM(end_time - create_time) / (SUM(num_turns) * 1000)) as `turn length`,
    ROUND(AVG(renown) / 2, 1) as `player renown/battle`,
    ROUND((AVG(renown) / 2) * 3600000 / (AVG(end_time - create_time)),
            1) as `player renown/hour`,
    COUNT(NULLIF(aborted, 0)) as aborts,
    COUNT(NULLIF(surrender, 0)) as surrenders,
    COUNT(NULLIF(diverged, 0)) as diverged
from
    battle
group by 
	hour(FROM_UNIXTIME(create_time / 1000)),
	to_days(FROM_UNIXTIME(create_time / 1000))
order by create_time asc;

END$$

DELIMITER ;