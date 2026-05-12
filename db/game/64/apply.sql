ALTER TABLE `session_history`
ADD COLUMN `steam_overlay` TINYINT NULL DEFAULT NULL  AFTER `os_language` ;
