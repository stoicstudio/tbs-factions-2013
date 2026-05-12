ALTER TABLE `battle` 
	CHANGE COLUMN `battle_scene` `scene` VARCHAR(128) NULL DEFAULT NULL  , 
	CHANGE COLUMN `battle_create_time` `create_time` BIGINT(8) NULL DEFAULT NULL  , 
	CHANGE COLUMN `battle_end_time` `end_time` BIGINT(8) NULL DEFAULT NULL  , 
	CHANGE COLUMN `battle_victor_team` `victor_team` VARCHAR(64) NULL DEFAULT NULL  , 
	CHANGE COLUMN `battle_surrender` `surrender` TINYINT(4) NULL DEFAULT NULL  , 
	CHANGE COLUMN `battle_turns` `num_turns` INT(4) NULL DEFAULT NULL  , 
	CHANGE COLUMN `battle_aborted` `aborted` INT(4) NULL DEFAULT NULL  , 
	CHANGE COLUMN `battle_renown` `renown` INT(4) NULL DEFAULT NULL  , 
	CHANGE COLUMN `battle_divergence` `divergence_turn` INT(4) NULL DEFAULT NULL  , 
	ADD COLUMN `diverged` TINYINT NULL DEFAULT NULL  AFTER `divergence_turn` , 
	ADD COLUMN `num_turns_complete` INT(4) NULL DEFAULT NULL  AFTER `diverged` , 
	ADD COLUMN `ready_for_cleanup` TINYINT NULL DEFAULT NULL  AFTER `num_turns_complete` ,
	ADD COLUMN `battle_create_data` VARCHAR(16386) NULL DEFAULT NULL  AFTER `ready_for_cleanup` ;
	
DROP TABLE IF EXISTS `battle_aborts`;
DROP TABLE IF EXISTS `battle_readies`;
DROP TABLE IF EXISTS `battle_surrenders`;
DROP TABLE IF EXISTS `battle_exists`;
DROP TABLE IF EXISTS `battle_syncs`;

CREATE  TABLE `battle_aborts` (
  `battle_id` VARCHAR(128) NOT NULL ,
  `value` BIGINT(8) NOT NULL ,
  PRIMARY KEY (`battle_id`, `value`) );

CREATE  TABLE `battle_readies` (
  `battle_id` VARCHAR(128) NOT NULL ,
  `value` BIGINT(8) NOT NULL ,
  PRIMARY KEY (`battle_id`, `value`) );

CREATE  TABLE `battle_surrenders` (
  `battle_id` VARCHAR(128) NOT NULL ,
  `value` BIGINT(8) NOT NULL ,
  PRIMARY KEY (`battle_id`, `value`) );

CREATE  TABLE `battle_exits` (
  `battle_id` VARCHAR(128) NOT NULL ,
  `value` BIGINT(8) NOT NULL ,
  PRIMARY KEY (`battle_id`, `value`) );

CREATE  TABLE `battle_sync` (
  `battle_id` VARCHAR(128) NOT NULL ,
  `turn` INT(4) NOT NULL ,
  `complete` TINYINT NULL ,
  `divergence` TINYINT NULL ,
  `hash` BIGINT(8) NULL ,
  `party_syncs` VARCHAR(1024) NULL ,
  PRIMARY KEY (`battle_id`, `turn`) );
  
 UPDATE `battle` set `end_time`=`create_time`,`aborted`=1 WHERE `end_time` IS NULL;

DROP PROCEDURE IF EXISTS `battle_chart`;
 
DELIMITER $$

CREATE PROCEDURE `battle_chart`()
BEGIN

SELECT 
    FROM_UNIXTIME(ROUND(create_time / 3600000) * 3600) as `time`,
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

DROP PROCEDURE IF EXISTS `battle_chart_dayhours`;

DELIMITER $$

CREATE PROCEDURE `battle_chart_dayhours`()
BEGIN

SELECT 
	_hour `Hour GMT`,
	MOD(24 + _hour-6, 24) `Hour CST`,
	ROUND(AVG(_count)) `Average Battles`
	, _count `Total Battles`
from
	(
		select 
			@_hour _hour,
			@_day _day,
			COUNT(*) _count

		from battle
		group by 
			@_hour:=HOUR(FROM_UNIXTIME(create_time / 1000)),
			@_day:=DAY(FROM_UNIXTIME(create_time / 1000)) 

	) temp

group by _hour;
END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS `battle_chart_weekdays`;

DELIMITER $$

CREATE PROCEDURE `battle_chart_weekdays`()
BEGIN

SELECT 
	_dayofweek
	, _dayname `Day of Week`
	,ROUND(AVG(_count)) `Average Battles`
	, _count `Total Battles`
from
	(
		select 
			DAYNAME(FROM_UNIXTIME(create_time/1000)) _dayname,
			@_dayofweek _dayofweek,
			@_week _week
			,COUNT(*) _count

		from battle
 		group by 
 			@_dayofweek:=WEEKDAY(FROM_UNIXTIME(create_time / 1000))
 			,@_week:=WEEK(FROM_UNIXTIME(create_time / 1000))
	) temp

group by _dayofweek;
END$$

DELIMITER ;


DROP PROCEDURE IF EXISTS `battle_vitals`;

DELIMITER $$

CREATE PROCEDURE `battle_vitals`()
BEGIN
select COUNT(renown) as completed, 
SUM(IF(end_time, NULL, 1)) as `in progress`,
ROUND(AVG(end_time-create_time)/60000) as `avg minutes`,
ROUND(AVG(num_turns)) as `avg turns`,
ROUND(SUM(end_time-create_time)/(SUM(num_turns)*1000)) as `turn length`,
ROUND(AVG(renown)/2, 1) as `player renown/battle`,
ROUND(
	(AVG(renown)/2)*3600000/(AVG(end_time-create_time))
, 1)
 as `player renown/hour`,
COUNT(NULLIF(aborted, 0)) as aborts, 
COUNT(NULLIF(surrender, 0)) as surrenders,
COUNT(NULLIF(diverged, 0)) as diverged
from battle;

END$$

DELIMITER ;

