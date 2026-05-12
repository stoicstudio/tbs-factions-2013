CREATE  TABLE `steam_dlc` (
  `account_id` BIGINT(8) NOT NULL ,
  `dlc_appid` INT(4) NOT NULL ,
  `dlc_iap` VARCHAR(32) NOT NULL ,
  `dlc_time` BIGINT(8) NOT NULL ,
  PRIMARY KEY (`account_id`, `dlc_appid`) );
