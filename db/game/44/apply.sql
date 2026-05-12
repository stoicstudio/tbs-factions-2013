
ALTER SCHEMA DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci ;

ALTER TABLE `session_history` 
	CHANGE COLUMN `session_timeout` `session_timeout` TINYINT(4) NOT NULL DEFAULT 0  , 
	ADD COLUMN `ipaddress` VARCHAR(32) NOT NULL  AFTER `login_count` , 
	ADD COLUMN `country` CHAR(2)  NULL COMMENT 'ISO 3166'  AFTER `ipaddress` , 
	ADD COLUMN `client_language` CHAR(2) NOT NULL COMMENT 'ISO 639-1'  AFTER `country` , 
	ADD COLUMN `currency` CHAR(3)  NULL COMMENT 'ISO 4217'  AFTER `client_language` , 
	ADD COLUMN `os` VARCHAR(32) NOT NULL  AFTER `currency` , 
	ADD COLUMN `screen_w` INT(4) NOT NULL  AFTER `os` , 
	ADD COLUMN `screen_h` INT(4) NOT NULL  AFTER `screen_w` , 
	ADD COLUMN `os_language` CHAR(2) NOT NULL COMMENT 'ISO 639-1' AFTER `screen_h` ;

	
CREATE  TABLE `chat` (
  `session_key` BIGINT(8) NOT NULL ,
  `chat_time` BIGINT(8) NOT NULL ,
  `room` VARCHAR(128) NOT NULL ,
  `msg` VARCHAR(2048) NOT NULL );
  
ALTER TABLE `account_info` 
	CHANGE COLUMN `account_renown` `account_renown` INT(4) NOT NULL DEFAULT '0'  , 
	CHANGE COLUMN `lobby_ready` `lobby_ready` TINYINT(4) NOT NULL DEFAULT 0  , 
	CHANGE COLUMN `daily_login_streak` `daily_login_streak` INT(4) NOT NULL DEFAULT '0'  , 
	CHANGE COLUMN `daily_login_time` `daily_login_time` BIGINT(8) NOT NULL DEFAULT '0'  , 
	CHANGE COLUMN `daily_login_bonus` `daily_login_bonus` INT(4) NOT NULL DEFAULT '0'  , 
	CHANGE COLUMN `last_online` `last_online` BIGINT(8) NOT NULL DEFAULT '0',
	CHANGE COLUMN `login_count` `login_count` INT(4) NOT NULL DEFAULT 0  ;
