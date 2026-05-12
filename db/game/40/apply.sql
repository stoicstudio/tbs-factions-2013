ALTER TABLE `account_info` ADD COLUMN `renown_boost_expiry` BIGINT(8) NOT NULL DEFAULT 0  AFTER `last_online` ;

CREATE  TABLE `friend_battle_record` (
  `account_id_0` BIGINT(8) NOT NULL ,
  `account_id_1` BIGINT(8) NOT NULL ,
  `wins_0` INT(4) NOT NULL ,
  `wins_1` INT(4) NOT NULL ,
  `last_time` BIGINT(8) NOT NULL ,
  PRIMARY KEY (`account_id_0`, `account_id_1`) );

