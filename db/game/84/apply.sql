ALTER TABLE `tourney` 
	ADD COLUMN `def_name` VARCHAR(32) NOT NULL DEFAULT 'none'  AFTER `parent_id`; 

UPDATE tourney set def_name=tourney_name;
	
ALTER TABLE `tourney` 
	DROP COLUMN `tourney_name` ,
	ADD COLUMN `def_rewards` VARCHAR(128) NOT NULL DEFAULT 0  AFTER `def_name` , 
	ADD COLUMN `def_entry_fee` TINYINT(2) NOT NULL DEFAULT 0  AFTER `def_rewards` , 
	ADD COLUMN `def_daily_limit` TINYINT(1) NOT NULL DEFAULT 0  AFTER `def_entry_fee` , 
	ADD COLUMN `def_power_requirement` TINYINT(1) NOT NULL DEFAULT 0  AFTER `def_daily_limit` ;

UPDATE tourney set def_rewards='[200,100,50]', def_entry_fee=20, def_daily_limit=5, def_power_requirement=6;