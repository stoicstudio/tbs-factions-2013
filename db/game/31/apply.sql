ALTER TABLE `unit_roster` 
	ADD COLUMN `stat_kil` INT(4) NOT NULL DEFAULT 0  AFTER `stat_rnk` ;

ALTER TABLE `battle_party_def` 
	ADD COLUMN `stat_kil` INT(4) NOT NULL DEFAULT 0  AFTER `stat_rnk` ;
