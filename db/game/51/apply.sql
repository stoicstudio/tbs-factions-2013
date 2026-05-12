
ALTER TABLE `account_info` ADD COLUMN `ach_bat` INT(4) NOT NULL DEFAULT '0'  AFTER `login_count` , ADD COLUMN `ach_kil` INT(4) NOT NULL DEFAULT '0'  AFTER `ach_bat` , ADD COLUMN `ach_win` INT(4) NOT NULL DEFAULT '0'  AFTER `ach_kil` ;

CREATE  TABLE `achievement` (
  `account_id` BIGINT(8) NOT NULL ,
  `achievement` VARCHAR(32) NOT NULL ,
  `session_key` BIGINT(8) NOT NULL ,
  `date` BIGINT(8) NOT NULL ,
  PRIMARY KEY (`account_id`) ,
  UNIQUE INDEX `account_id_UNIQUE` (`account_id` ASC) );
  
  
  
  