ALTER TABLE `account_info` ADD INDEX `lobby_id` (`lobby_id` ASC) ;
ALTER TABLE `session` ADD INDEX `account_id` (`account_id` ASC) ;
ALTER TABLE `unit_roster` ADD INDEX `account_id` (`account_id` ASC) ;

ALTER TABLE `battle_renown` ADD INDEX `renown_time` (`renown_time` ASC) ;
ALTER TABLE `battle_renown` ADD INDEX `account_id` (`account_id` ASC) ;
ALTER TABLE `battle` ADD INDEX `create_time` (`create_time` ASC) ;
ALTER TABLE `battle` ADD INDEX `end_time` (`end_time` ASC) ;
ALTER TABLE `auth_account` ADD INDEX `create_date` (`create_date` ASC) ;
ALTER TABLE `vs_find` ADD INDEX `account_id` (`account_id` ASC) ;
ALTER TABLE `battle_party` ADD INDEX `account_id` (`account_id` ASC) ;
ALTER TABLE `session_history` ADD INDEX `account_id` (`account_id` ASC) ;
ALTER TABLE `renown` ADD INDEX `renown_reason` (`renown_reason` ASC) ;

ALTER TABLE `iap_steam` CHANGE COLUMN `errordesc` `errordesc` VARCHAR(256) NULL DEFAULT NULL  ;

DROP PROCEDURE IF EXISTS renown_grant;

DELIMITER $$

CREATE PROCEDURE `renown_grant`(IN _id_param BIGINT(8), IN _delta_param INT(4), IN _admin_param VARCHAR(128))
BEGIN
update account_info set account_renown=account_renown+_delta_param where account_id=_id_param;
insert into renown 
	SELECT 
		account_info.account_id, 
		_delta_param, 
		account_renown,
		'ADMIN',
		_admin_param,
		UNIX_TIMESTAMP()*1000
	from account_info where account_id = _id_param;
END $$

DELIMITER ;

