ALTER TABLE `session_history` 
CHANGE COLUMN `session_end` `session_end` BIGINT(8) NULL DEFAULT NULL  , 
CHANGE COLUMN `session_timeout` `session_timeout` TINYINT(4) NULL DEFAULT NULL;  
