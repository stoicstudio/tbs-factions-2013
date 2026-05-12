CREATE  TABLE `system_msg` (
  `system_msg_key` INT NOT NULL AUTO_INCREMENT ,
  `system_msg_time` BIGINT(8) NULL ,
  `system_msg_text` VARCHAR(1024) NULL ,
  PRIMARY KEY (`system_msg_key`) );
