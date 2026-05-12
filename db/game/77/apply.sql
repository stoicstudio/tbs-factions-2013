ALTER TABLE `vs_find` 
	ADD COLUMN `tourney_id` INT(4) NOT NULL DEFAULT 0  AFTER `friendly` ;

ALTER TABLE `battle` 
	ADD COLUMN `tourney_id` INT(4) NOT NULL DEFAULT 0  AFTER `friendly` ;

update battle
join
	battle_party
	on (battle.battle_id = battle_party.battle_id AND battle_party.battle_party_index = 0)
set 
	battle.tourney_id = battle_party.tourney_id;

