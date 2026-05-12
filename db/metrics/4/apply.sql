ALTER TABLE `reliable`
	ADD COLUMN `reliable_total` BIGINT(4) NULL DEFAULT NULL  AFTER `reliable_max` , 
	ADD COLUMN `ackpool_avg` BIGINT(4) NULL DEFAULT NULL  AFTER `reliable_total` , 
	ADD COLUMN `ackpool_max` BIGINT(4) NULL DEFAULT NULL  AFTER `ackpool_avg` ,
	ADD COLUMN `ackpool_total` BIGINT(4) NULL DEFAULT NULL  AFTER `ackpool_max` ;