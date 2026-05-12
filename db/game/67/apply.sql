ALTER TABLE `iap_txn` ADD COLUMN `total_usd_estimate` INT(4) NOT NULL DEFAULT 0  AFTER `currency` ;

ALTER TABLE `iap_cart` ADD COLUMN `usd_estimate` INT(4) NOT NULL DEFAULT 0  AFTER `unit_price` ;

ALTER TABLE `iap_cart` 
	ADD COLUMN `sale` TINYINT NOT NULL DEFAULT 0  AFTER `usd_estimate` , 
	ADD COLUMN `normal_usd_cents` INT(4) NOT NULL DEFAULT 0  AFTER `sale` ;

update iap_cart SET usd_estimate = unit_price, normal_usd_cents=unit_price;

