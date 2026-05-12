ALTER TABLE `battle_party` ADD COLUMN `timer` INT(4) NOT NULL DEFAULT 0  AFTER `is_victor` ;

update battle_party
join battle
on battle.battle_id = battle_party.battle_id
set battle_party.timer = battle.timer;

ALTER TABLE `battle` DROP COLUMN `timer` ;

ALTER TABLE `vs_find` 
	CHANGE COLUMN `account_id` `account_id` BIGINT(8) NOT NULL  , 
	CHANGE COLUMN `vs_power` `vs_power` INT(4) NOT NULL  , 
	CHANGE COLUMN `elo` `elo` INT(4) NOT NULL  , 
	CHANGE COLUMN `vs_data` `vs_data` VARCHAR(2048) NOT NULL  , 
	CHANGE COLUMN `min_timer` `timer` INT(4) NOT NULL  , 
	CHANGE COLUMN `friendly` `friendly` TINYINT(4) NOT NULL  ;

