ALTER TABLE `vs_find` ADD COLUMN `vs_type` TINYINT(1) NOT NULL DEFAULT 0  AFTER `tourney_id` ;

ALTER TABLE `battle_party` ADD COLUMN `vs_type_tmp` TINYINT(1) NOT NULL DEFAULT 0  AFTER `vs_type`;

UPDATE battle_party set vs_type_tmp=IF(vs_type='QUICK', 1, IF(vs_type='RANKED', 2, IF(vs_type='TOURNEY', 3, IF(vs_type='FRIEND', 4, 0))));

ALTER TABLE battle_party DROP COLUMN `vs_type`; 

ALTER TABLE `battle_party` CHANGE COLUMN `vs_type_tmp` `vs_type` TINYINT(1) NOT NULL DEFAULT 0  ;
