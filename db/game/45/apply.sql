ALTER TABLE `battle_action`
	CHANGE COLUMN `battle_id` `battle_id` VARCHAR(128) NOT NULL  , 
	CHANGE COLUMN `battle_msg_num` `battle_msg_num` INT(4) NOT NULL  , 
	CHANGE COLUMN `battle_turn` `battle_turn` INT(4) NOT NULL  , 
	CHANGE COLUMN `user_id` `account_id` BIGINT(8) NOT NULL  , 
	CHANGE COLUMN `entity_id` `entity_id` VARCHAR(64) NOT NULL  , 
	CHANGE COLUMN `battle_action` `battle_action` VARCHAR(64) NOT NULL  , 
	CHANGE COLUMN `battle_action_level` `battle_action_level` INT(4) NOT NULL  , 
	CHANGE COLUMN `battle_action_executed_id` `battle_action_executed_id` INT(4) NOT NULL  ;

ALTER TABLE `battle_move` CHANGE COLUMN `battle_id` `battle_id` VARCHAR(128) NOT NULL  , CHANGE COLUMN `battle_msg_num` `battle_msg_num` INT(4) NOT NULL  , CHANGE COLUMN `battle_turn` `battle_turn` INT(4) NOT NULL  , CHANGE COLUMN `user_id` `account_id` BIGINT(8) NOT NULL  , CHANGE COLUMN `entity_id` `entity_id` VARCHAR(64) NOT NULL  , CHANGE COLUMN `battle_tiles` `battle_tiles` VARCHAR(1024) NOT NULL  , CHANGE COLUMN `battle_tile_end_x` `battle_tile_end_x` INT(4) NOT NULL  , CHANGE COLUMN `battle_tile_end_y` `battle_tile_end_y` INT(4) NOT NULL  , CHANGE COLUMN `battle_num_steps` `battle_num_steps` INT(4) NOT NULL  ;

ALTER TABLE `battle_party_def` CHANGE COLUMN `battle_id` `battle_id` VARCHAR(128) NOT NULL  , CHANGE COLUMN `user_id` `account_id` BIGINT(8) NOT NULL  , CHANGE COLUMN `stat_str` `stat_str` INT(4) NOT NULL  , CHANGE COLUMN `stat_arm` `stat_arm` INT(4) NOT NULL  , CHANGE COLUMN `stat_wil` `stat_wil` INT(4) NOT NULL  , CHANGE COLUMN `stat_exe` `stat_exe` INT(4) NOT NULL  , CHANGE COLUMN `stat_brk` `stat_brk` INT(4) NOT NULL  , CHANGE COLUMN `stat_rnk` `stat_rnk` INT(4) NOT NULL  , CHANGE COLUMN `stat_kil` `stat_kil` INT(4) NOT NULL  ;

ALTER TABLE `session` CHANGE COLUMN `user_id` `account_id` BIGINT(8) NOT NULL  ;

ALTER TABLE `session_history` CHANGE COLUMN `user_id` `account_id` BIGINT(8) NOT NULL  ;

ALTER TABLE `unit_party` CHANGE COLUMN `user_id` `account_id` BIGINT(8) NOT NULL  ;

ALTER TABLE `unit_roster` CHANGE COLUMN `user_id` `account_id` BIGINT(8) NOT NULL  , CHANGE COLUMN `start_date` `start_date` BIGINT(8) NOT NULL  , CHANGE COLUMN `stat_str` `stat_str` INT(4) NOT NULL  , CHANGE COLUMN `stat_arm` `stat_arm` INT(4) NOT NULL  , CHANGE COLUMN `stat_wil` `stat_wil` INT(4) NOT NULL  , CHANGE COLUMN `stat_exe` `stat_exe` INT(4) NOT NULL  , CHANGE COLUMN `stat_brk` `stat_brk` INT(4) NOT NULL  , CHANGE COLUMN `stat_rnk` `stat_rnk` INT(4) NOT NULL  ;


