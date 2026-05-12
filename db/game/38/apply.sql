ALTER TABLE `unit_roster` 
ADD COLUMN `start_date` BIGINT(8) NULL  AFTER `unit_name`,
ADD COLUMN `stat_bat` BIGINT(8) NOT NULL DEFAULT 0  AFTER `stat_kil`;

UPDATE `unit_roster` SET `start_date`=(UNIX_TIMESTAMP()*1000);
