
DROP PROCEDURE IF EXISTS reset_accounts;

DELIMITER $$

CREATE PROCEDURE `reset_accounts`()
BEGIN
delete from unit_roster;
delete from unit_party;
delete from achievement;
delete from friend_battle_record;
delete from account_info;
delete from unlocks;
delete from iap;
delete from ranking;

END$$

DELIMITER ;