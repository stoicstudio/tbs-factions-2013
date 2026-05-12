ALTER TABLE `battle_party_def` 
	ADD COLUMN `stat_rnk` INT(4) NULL DEFAULT NULL  AFTER `stat_brk` ;

DELETE FROM `unit_roster`;