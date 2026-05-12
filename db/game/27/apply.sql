CREATE  TABLE `battle_msg` (
  `key` BIGINT(8) NOT NULL AUTO_INCREMENT ,
  `battle_id` VARCHAR(128) NOT NULL ,
  `account_id` BIGINT(8) NOT NULL ,
  `battle_msg` VARCHAR(16384) NOT NULL ,
  PRIMARY KEY (`key`) );
