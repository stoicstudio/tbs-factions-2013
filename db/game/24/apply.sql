ALTER TABLE `account_info`
	ADD COLUMN `game_location` VARCHAR(64) NULL DEFAULT NULL  AFTER `account_renown` ;

CREATE  TABLE `session_history` (
  `session_key` BIGINT(8) NOT NULL ,
  `user_id` VARCHAR(45) NOT NULL ,
  `display_name` VARCHAR(45) NOT NULL ,
  `session_start` BIGINT(8) NOT NULL ,
  `session_end` BIGINT(8) NOT NULL ,
  `session_timeout` TINYINT NOT NULL ,
  PRIMARY KEY (`session_key`) );
