DROP PROCEDURE IF EXISTS `reset_accounts`;

delimiter $$

CREATE PROCEDURE `reset_accounts`()
BEGIN
delete from unit_roster;
delete from unit_party;
delete from achievement;
delete from friend_battle_record;
update account_info set ach_bat=0, ach_kil=0, ach_win=0, roster_rows=1;
delete from unlocks;
delete from iap;

END
$$

delimiter ;

call reset_accounts;
