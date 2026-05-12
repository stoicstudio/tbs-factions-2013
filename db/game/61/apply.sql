ALTER TABLE `account_info`
ADD COLUMN `roster_rows` INT(4) NOT NULL DEFAULT 1  AFTER `login_count` ;
