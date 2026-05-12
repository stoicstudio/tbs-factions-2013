
DELIMITER $$

DROP PROCEDURE IF EXISTS `battle_actions`$$

CREATE  PROCEDURE `battle_actions`()
BEGIN
select battle_action, COUNT(*) as count from battle_action where battle_action != 'abl_end' GROUP BY battle_action ORDER BY count DESC;
END$$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS `battle_classes`$$

CREATE PROCEDURE `battle_classes`()
BEGIN
select entity_class, COUNT(*) as `count` from battle_party_def GROUP BY entity_class ORDER BY `count` DESC;
END$$

DELIMITER ;

delimiter $$

DROP PROCEDURE IF EXISTS `battle_vitals`$$

CREATE PROCEDURE `battle_vitals`()
BEGIN
select COUNT(battle_renown) as completed, 
SUM(IF(battle_end_time, NULL, 1)) as `in progress`,
ROUND(AVG(battle_end_time-battle_create_time)/60000) as `avg minutes`,
ROUND(AVG(battle_turns)) as `avg turns`,
ROUND(SUM(battle_end_time-battle_create_time)/(SUM(battle_turns)*1000)) as `turn length`,
ROUND(AVG(battle_renown)/2, 1) as `player renown/battle`,
ROUND(
	(AVG(battle_renown)/2)*3600000/(AVG(battle_end_time-battle_create_time))
, 1)
 as `player renown/hour`,
COUNT(NULLIF(battle_aborted, 0)) as aborts, 
COUNT(NULLIF(battle_surrender, 0)) as surrenders,
COUNT(NULLIF(battle_divergence, 0)) as divergence
from battle;

END$$


delimiter $$

DROP PROCEDURE IF EXISTS `battle_chart`$$

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
group by hour(FROM_UNIXTIME(battle_create_time / 1000))
order by battle_create_time asc;

END$$

DELIMITER ;