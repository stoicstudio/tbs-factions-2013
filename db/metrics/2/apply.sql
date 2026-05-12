ALTER TABLE `session_started` 
	DROP COLUMN `start_timestamp` , 
	RENAME TO  `session` ;

DROP TABLE IF EXISTS `vs_find` ;

CREATE TABLE `vs_find` (
    `session_key` bigint(8) NOT NULL,
    `match_handle` int(4) NOT NULL,
    `start_time` bigint(8) DEFAULT NULL,
    `end_time` bigint(8) DEFAULT NULL,
    `battle_id` varchar(128) DEFAULT NULL,
    `power` int(4) DEFAULT NULL,
    PRIMARY KEY (`session_key` , `match_handle`)
)  ENGINE=InnoDB DEFAULT CHARSET=latin1

