DROP procedure IF EXISTS `battle_chart`;

DELIMITER $$

CREATE PROCEDURE `battle_chart`()
BEGIN

SELECT 
    FROM_UNIXTIME(ROUND(battle_create_time / 3600000) * 3600) as `time`,
    count(*) as `started`,
    count(battle_end_time) as `ended`,
    sum(battle_renown) as `renown`,
    ROUND(AVG(battle_end_time - battle_create_time) / 60000) as `avg minutes`,
    ROUND(AVG(battle_turns)) as `avg turns`,
    ROUND(SUM(battle_end_time - battle_create_time) / (SUM(battle_turns) * 1000)) as `turn length`,
    ROUND(AVG(battle_renown) / 2, 1) as `player renown/battle`,
    ROUND((AVG(battle_renown) / 2) * 3600000 / (AVG(battle_end_time - battle_create_time)),
            1) as `player renown/hour`,
    COUNT(NULLIF(battle_aborted, 0)) as aborts,
    COUNT(NULLIF(battle_surrender, 0)) as surrenders,
    COUNT(NULLIF(battle_divergence, 0)) as divergence
from
    battle
group by 
	hour(FROM_UNIXTIME(battle_create_time / 1000)),
	day(FROM_UNIXTIME(battle_create_time / 1000))
order by battle_create_time asc;

END$$

DELIMITER ;

