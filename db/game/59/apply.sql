ALTER TABLE `unit_roster` 
	ADD COLUMN `appearance_index` INT(4) NOT NULL DEFAULT 0  AFTER `start_date` , 
	ADD COLUMN `appearances_unlocked` INT(4) NOT NULL DEFAULT 0  AFTER `appearance_index` ;
