ALTER TABLE `battle_renown` ADD COLUMN `renown_time` BIGINT(8) NOT NULL  AFTER `achievement_renown` ;

update
battle_renown
join battle
on battle.battle_id = battle_renown.battle_id
set renown_time=battle.end_time;

