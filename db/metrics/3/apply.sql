DROP TABLE IF EXISTS `chat`;

CREATE  TABLE `chat` (
  `chat_room` VARCHAR(128) NULL ,
  `session_key` BIGINT(8) NULL ,
  `chat_time` BIGINT(8) NULL ,
  `chat_msg` VARCHAR(1024) NULL );
