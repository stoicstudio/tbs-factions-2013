ALTER TABLE `unit_roster` 
	CHANGE COLUMN `stat_strength` `stat_str` INT(4) NULL DEFAULT NULL  , 
	CHANGE COLUMN `stat_armor` `stat_arm` INT(4) NULL DEFAULT NULL  , 
	CHANGE COLUMN `stat_willpower` `stat_wil` INT(4) NULL DEFAULT NULL  , 
	CHANGE COLUMN `stat_exertion` `stat_exe` INT(4) NULL DEFAULT NULL  , 
	CHANGE COLUMN `stat_armor_break` `stat_brk` INT(4) NULL DEFAULT NULL , 
	CHANGE COLUMN `name` `unit_name` VARCHAR(128) NULL DEFAULT NULL;
	
CREATE TABLE `account_info` (
  `account_id` bigint(8) NOT NULL,
  `account_renown` int(4) DEFAULT '0',
  PRIMARY KEY (`account_id`)
);


CREATE TABLE `battle` (
  `battle_id` varchar(128) NOT NULL,
  `battle_scene` varchar(128) DEFAULT NULL,
  `battle_create_time` bigint(8) DEFAULT NULL,
  `battle_end_time` bigint(8) DEFAULT NULL,
  `battle_victor_team` varchar(64) DEFAULT NULL,
  `battle_surrender` tinyint(4) DEFAULT NULL,
  `battle_turns` int(4) DEFAULT NULL,
  `battle_aborted` int(4) DEFAULT NULL,
  `battle_renown` int(4) DEFAULT NULL,
  PRIMARY KEY (`battle_id`)
);



CREATE TABLE `battle_action` (
  `battle_id` varchar(128) DEFAULT NULL,
  `battle_msg_num` int(4) DEFAULT NULL,
  `battle_turn` int(4) DEFAULT NULL,
  `user_id` bigint(8) DEFAULT NULL,
  `entity_id` varchar(64) DEFAULT NULL,
  `battle_tiles` varchar(1024) DEFAULT NULL,
  `battle_target_ids` varchar(1024) DEFAULT NULL,
  `battle_action` varchar(64) DEFAULT NULL,
  `battle_action_level` int(4) DEFAULT NULL,
  `battle_action_executed_id` int(4) DEFAULT NULL
);




CREATE TABLE `battle_move` (
  `battle_id` varchar(128) DEFAULT NULL,
  `battle_msg_num` int(4) DEFAULT NULL,
  `battle_turn` int(4) DEFAULT NULL,
  `user_id` bigint(8) DEFAULT NULL,
  `entity_id` varchar(64) DEFAULT NULL,
  `battle_tiles` varchar(1024) DEFAULT NULL,
  `battle_tile_end_x` int(4) DEFAULT NULL,
  `battle_tile_end_y` int(4) DEFAULT NULL,
  `battle_num_steps` int(4) DEFAULT NULL
);




CREATE TABLE `battle_party` (
  `battle_id` varchar(128) DEFAULT NULL,
  `battle_team` varchar(45) DEFAULT NULL,
  `battle_party_index` int(4) DEFAULT NULL,
  `user_id` bigint(8) DEFAULT NULL,
  `display_name` varchar(128) DEFAULT NULL,
  `match_handle` int(4) DEFAULT NULL,
  `battle_surrender_turn` int(4) DEFAULT NULL
);




CREATE TABLE `battle_party_def` (
  `battle_id` varchar(128) DEFAULT NULL,
  `user_id` bigint(8) NOT NULL,
  `unit_id` varchar(64) NOT NULL,
  `entity_class` varchar(32) NOT NULL,
  `unit_name` varchar(128) DEFAULT NULL,
  `stat_str` int(4) DEFAULT NULL,
  `stat_arm` int(4) DEFAULT NULL,
  `stat_wil` int(4) DEFAULT NULL,
  `stat_exe` int(4) DEFAULT NULL,
  `stat_brk` int(4) DEFAULT NULL
);




CREATE TABLE `battle_renown` (
  `battle_id` varchar(128) NOT NULL,
  `user_id` bigint(8) NOT NULL,
  `battle_party_renown` int(4) NOT NULL
);

CREATE TABLE `renown` (
  `account_id` bigint(8) NOT NULL,
  `renown_delta` int(4) NOT NULL,
  `renown_total` int(4) NOT NULL,
  `renown_reason` varchar(32) NOT NULL,
  `renown_note` varchar(128) NOT NULL,
  `renown_time` bigint(8) NOT NULL
);


