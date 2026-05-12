ALTER TABLE `battle_move` ADD COLUMN `ordinal` INT(4) NOT NULL  AFTER `battle_num_steps` ;

ALTER TABLE `battle_action` ADD COLUMN `ordinal` INT(4) NOT NULL  AFTER `battle_action_executed_id` , ADD COLUMN `terminator` TINYINT NOT NULL  AFTER `ordinal` ;

ALTER TABLE `battle_action` 
	ADD INDEX `battle_id` (`battle_id` ASC) 
	, ADD INDEX `battle_turn` (`battle_id` ASC, `battle_turn` ASC) ;

ALTER TABLE `battle_move` 
	ADD INDEX `battle_id` (`battle_id` ASC) 
	, ADD INDEX `battle_turn` (`battle_id` ASC, `battle_turn` ASC) ;
