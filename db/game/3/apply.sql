START TRANSACTION;

ALTER TABLE `unit_roster` 
	ADD COLUMN `unit_id` VARCHAR(64) NOT NULL  AFTER `user_id` , 
	ADD COLUMN `unit_key` VARCHAR(128) NOT NULL  AFTER `unit_id` ,
	ADD COLUMN `entity_class` VARCHAR(32) NOT NULL  AFTER `unit_key` ,
	ADD COLUMN `name` VARCHAR(128)  NULL  AFTER `entity_class` ,
	ADD COLUMN `stat_strength` INT(4) NULL, 
	ADD COLUMN `stat_armor` INT(4) NULL,
	ADD COLUMN `stat_willpower` INT(4) NULL, 
	ADD COLUMN `stat_exertion` INT(4) NULL,
	ADD COLUMN `stat_armor_break` INT(4) NULL,
	DROP COLUMN `unit_json`,
	ADD PRIMARY KEY (`unit_key`) ;

	

DELETE FROM `version` LIMIT 100;
REPLACE INTO `version` (`version_number`) VALUES (3);

COMMIT;
