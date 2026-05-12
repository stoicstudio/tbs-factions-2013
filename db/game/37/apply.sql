ALTER TABLE `account_info` ADD COLUMN `battle_count` INT(4) NOT NULL DEFAULT 0  AFTER `lobby_ready` ;

ALTER TABLE `battle` CHANGE COLUMN `friendly` `friendly` TINYINT(4) NOT NULL DEFAULT 0  ;

ALTER TABLE `battle_party` 
	CHANGE COLUMN `user_id` `account_id` BIGINT(8) NULL DEFAULT NULL  , 
	ADD COLUMN `friendly` TINYINT(4) NOT NULL DEFAULT 0  AFTER `power` , 
	ADD COLUMN `session_key` BIGINT(8) NULL DEFAULT NULL AFTER `friendly` , 
	ADD COLUMN `create_time` BIGINT(8) NOT NULL DEFAULT 0  AFTER `session_key` , 
	ADD COLUMN `end_time` BIGINT(8) NULL  AFTER `create_time` , 
	ADD COLUMN `is_victor` TINYINT(4) NOT NULL DEFAULT 0  AFTER `end_time` , 
	ADD COLUMN `renown` INT(4) NULL DEFAULT NULL  AFTER `end_time` , 
	ADD COLUMN `battle_count` INT(4) NULL DEFAULT NULL  AFTER `renown` , 
	ADD COLUMN `on_starting_team` TINYINT(4) NOT NULL DEFAULT 0  AFTER `battle_count` , 
	ADD COLUMN `complete` TINYINT(4) NOT NULL DEFAULT 0  AFTER `on_starting_team` ;

update battle_party as t1 
join
	battle as t2 on (t1.battle_id = t2.battle_id)
set
	t1.create_time=t2.create_time,
	t1.end_time=t2.end_time,
	t1.complete=(t2.end_time is not null and t2.aborted is null and (t2.diverged is null or t2.diverged = 0)),
	t1.is_victor=(t2.victor_team is not null and t2.victor_team = t1.account_id),
	t1.on_starting_team=(t2.starting_team is not null and t2.starting_team = t1.account_id);

	
update battle_party as t1
set
t1.friendly=(select friendly from battle where battle.battle_id = t1.battle_id);


update account_info 
set 
	battle_count=(select (battle_wins+battle_losses+friend_battles) from ranking where account_info.account_id = ranking.account_id);

