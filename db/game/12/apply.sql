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
	to_days(FROM_UNIXTIME(battle_create_time / 1000))
order by battle_create_time asc;

END$$

DELIMITER ;


DROP procedure IF EXISTS `battle_chart_dayhours`;

DELIMITER $$
CREATE PROCEDURE `battle_chart_dayhours` ()
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
			@_hour:=HOUR(FROM_UNIXTIME(battle_create_time / 1000)),
			@_day:=DAY(FROM_UNIXTIME(battle_create_time / 1000)) 

	) temp

group by _hour;
END$$

DELIMITER ;

DROP procedure IF EXISTS `battle_chart_weekdays`;
DELIMITER $$
CREATE PROCEDURE `battle_chart_weekdays` ()
BEGIN

SELECT 
	_dayofweek
	, _dayname `Day of Week`
	,ROUND(AVG(_count)) `Average Battles`
	, _count `Total Battles`
from
	(
		select 
			DAYNAME(FROM_UNIXTIME(battle_create_time/1000)) _dayname,
			@_dayofweek _dayofweek,
			@_week _week
			,COUNT(*) _count

		from battle
 		group by 
 			@_dayofweek:=WEEKDAY(FROM_UNIXTIME(battle_create_time / 1000))
 			,@_week:=WEEK(FROM_UNIXTIME(battle_create_time / 1000))
	) temp

group by _dayofweek;
END$$
DELIMITER ;


