drop table IF EXISTS `vs_find`; 

delimiter $$

CREATE TABLE `vs_find` (
  `session_key` bigint(8) NOT NULL,
  `vs_match_handle` int(4) NOT NULL,
  `vs_start_time` bigint(8) DEFAULT NULL,
  `vs_end_time` bigint(8) DEFAULT NULL,
  `vs_battle_id` varchar(128) DEFAULT NULL,
  `vs_power` int(4) DEFAULT NULL,
  `vs_data` varchar(2048) DEFAULT NULL,
  `vs_serverstopped` tinyint(4) DEFAULT NULL,
  PRIMARY KEY (`session_key`,`vs_match_handle`)
) $$

DELIMITER ;