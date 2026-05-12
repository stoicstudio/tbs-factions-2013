CREATE  TABLE `iap` (
  `account_id` BIGINT(8) NOT NULL ,
  `item_id` VARCHAR(32) NOT NULL ,
  `purchase_count` INT(4) NOT NULL DEFAULT 0 ,
  PRIMARY KEY (`item_id`, `account_id`) );

CREATE  TABLE `unlocks` (
  `account_id` BIGINT(8) NOT NULL ,
  `unlock_id` VARCHAR(32) NOT NULL ,
  `unlock_time` BIGINT(8) NOT NULL ,
  `unlock_duration` BIGINT(8) NOT NULL DEFAULT 0 ,
  PRIMARY KEY (`account_id`, `unlock_id`) );

