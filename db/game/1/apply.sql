ALTER TABLE `session` ADD COLUMN `keepalive_date` BIGINT(8) NOT NULL;
ALTER TABLE `session` CHANGE COLUMN `session_date` `session_date` BIGINT(8) NOT NULL;

