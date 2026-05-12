
DROP procedure IF EXISTS `battle_chart_weekdays`;

DELIMITER $$

CREATE PROCEDURE `battle_chart_weekdays`()
BEGIN

SELECT 
	_dayofweek
	, _dayname `Day of Week`
	,ROUND(AVG(_count)) `Average Battles`
	, SUM(_count) `Total Battles`
	, COUNT(*) `Day Count`
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


DROP procedure IF EXISTS `battle_chart_dayhours`;

DELIMITER $$

CREATE PROCEDURE `battle_chart_dayhours`()
BEGIN


SELECT 
	_hour `Hour GMT`,
	MOD(24 + _hour-6, 24) `Hour CST`,
	ROUND(AVG(_count)) `Average Battles`
	, SUM(_count) `Total Battles`
	, MAX(_count) `Max Battles`
	, COUNT(*) `Hour Count`
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


