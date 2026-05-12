DROP TABLE IF EXISTS `iap_txn`;
CREATE  TABLE `iap_txn` (
  `txn_id` BIGINT(8) NOT NULL AUTO_INCREMENT ,
  `total_price` INT(4) NOT NULL ,
  `currency` CHAR(3) NOT NULL ,
  `total_count` INT(4) NOT NULL ,
  `account_id` BIGINT(8) NULL ,
  `session_key` BIGINT(8) NOT NULL ,
  `txn_init_time` BIGINT(8) NOT NULL ,
  `txn_end_time` BIGINT(8) NULL DEFAULT NULL ,
  `success` TINYINT NOT NULL DEFAULT 0 COMMENT 'Success on the backend' ,
  `failed` TINYINT NOT NULL DEFAULT 0 ,
  PRIMARY KEY (`txn_id`) ,
  INDEX `account_id` (`account_id` ASC) );

  DROP TABLE IF EXISTS `iap_steam`;
CREATE  TABLE `iap_steam` (
  `txn_id` BIGINT(8) NOT NULL ,
  `steam_txn_id` BIGINT(8) NULL DEFAULT NULL ,
  `steam_id` BIGINT(8) NOT NULL ,
  `errorcode` INT(4) NULL DEFAULT NULL ,
  `errordesc` INT(4) NULL DEFAULT NULL ,
  `init_ok` TINYINT NOT NULL DEFAULT 0 ,
  `init_fail` TINYINT NOT NULL DEFAULT 0 ,
  `client_approved` TINYINT NOT NULL DEFAULT 0 ,
  `finalize_ok` TINYINT NOT NULL DEFAULT 0 ,
  `finalize_fail` TINYINT NOT NULL DEFAULT 0 ,
  PRIMARY KEY (`txn_id`) );

DROP TABLE IF EXISTS `iap_cart`;
CREATE  TABLE `iap_cart` (
  `txn_id` BIGINT(8) NOT NULL ,
  `cart_index` INT(4) NOT NULL ,
  `item_id` VARCHAR(32) NOT NULL ,
  `item_id_hash` INT(4) NOT NULL ,
  `qty` INT(4) NOT NULL ,
  `unit_price` INT(4) NOT NULL ,
  PRIMARY KEY (`txn_id`, `cart_index`) ,
  INDEX `item_id` (`item_id` ASC) );
