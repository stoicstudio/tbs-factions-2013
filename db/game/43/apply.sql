ALTER TABLE `battle_renown` 
CHANGE COLUMN `user_id` `account_id` BIGINT(8) NOT NULL  , 
CHANGE COLUMN `battle_party_renown` `total_renown` INT(4) NOT NULL  , 
ADD COLUMN `session_key` BIGINT(8)  NULL  AFTER `battle_id` , 
ADD COLUMN `party_index` INT(4) NOT NULL  AFTER `total_renown` , 
ADD COLUMN `brat_kills` INT(4) NOT NULL  AFTER `party_index` , 
ADD COLUMN `brat_underdog` INT(4) NOT NULL  AFTER `brat_kills` , 
ADD COLUMN `brat_daily` INT(4) NOT NULL  AFTER `brat_underdog` , 
ADD COLUMN `brat_friend` INT(4) NOT NULL  AFTER `brat_daily` , 
ADD COLUMN `brat_boost` INT(4) NOT NULL  AFTER `brat_friend` , 
ADD COLUMN `brat_streak` INT(4) NOT NULL  AFTER `brat_boost` , 
ADD COLUMN `brat_expert` INT(4) NOT NULL  AFTER `brat_streak` , 
ADD COLUMN `achievement_renown` INT(4) NOT NULL  AFTER `brat_expert`;

update battle_renown set party_index=account_id;

ALTER TABLE `battle_party` 
ADD INDEX `battle_id` (`battle_id` ASC) ;

update battle_renown
join battle_party
on (battle_renown.battle_id = battle_party.battle_id and battle_renown.party_index = battle_party.battle_party_index)
set 
battle_renown.session_key = battle_party.session_key,
battle_renown.account_id = battle_party.account_id;


