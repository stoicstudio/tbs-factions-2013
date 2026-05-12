START TRANSACTION;

CREATE  TABLE `ranking` (
  `account_id` BIGINT(8) NOT NULL ,
  `battle_wins` INT(4) NULL ,
  `battle_losses` INT(4) NULL ,
  `battle_elo` INT(4) NULL ,
  PRIMARY KEY (`account_id`) );

DELETE FROM `version` LIMIT 100;
REPLACE INTO `version` (`version_number`) VALUES (4);

COMMIT;
