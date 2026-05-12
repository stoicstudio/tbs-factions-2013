-- MySQL dump 10.13  Distrib 5.5.28, for osx10.6 (i386)
--
-- Host: tbs-db.stoicstudio.com    Database: tbs_dev_live
-- ------------------------------------------------------
-- Server version	5.5.27-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `auth_account`
--

ALTER SCHEMA DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci ;

DROP TABLE IF EXISTS `auth_account`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `auth_account` (
  `account_id` bigint(8) NOT NULL AUTO_INCREMENT,
  `steam_id` bigint(8) DEFAULT NULL COMMENT 'steam id',
  `vbb_id` bigint(8) DEFAULT NULL COMMENT 'stoicstudio.com vbb userid',
  `create_date` datetime NOT NULL COMMENT 'creation time',
  `last_date` datetime DEFAULT NULL COMMENT 'last login',
  `superuser` tinyint(1) DEFAULT NULL COMMENT 'Can the user do anything',
  `enabled` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Can the user login',
  `flags` int(4) NOT NULL DEFAULT '0' COMMENT 'A Bitvector of authorization flags\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\n\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\n		BETA(0x0001),\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\n		FAKE_ACCOUNTS(0x0002);\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\n\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\n',
  `vbb_name` varchar(64) DEFAULT NULL COMMENT 'Last known name',
  `child_number` int(4) DEFAULT NULL,
  `parent_id` bigint(8) DEFAULT NULL,
  `display_name` varchar(64) DEFAULT NULL,
  `name` varchar(45) DEFAULT NULL COMMENT 'DEPRECATED',
  PRIMARY KEY (`account_id`),
  UNIQUE KEY `account_id_UNIQUE` (`account_id`),
  KEY `steam_id_idx` (`steam_id`)
) ENGINE=InnoDB;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `auth_steam`
--

DROP TABLE IF EXISTS `auth_steam`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `auth_steam` (
  `steam_id` int(11) NOT NULL,
  `account_id` varchar(45) NOT NULL,
  PRIMARY KEY (`steam_id`),
  KEY `steam_id_idx` (`steam_id`)
) ENGINE=InnoDB;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `auth_vbb`
--

DROP TABLE IF EXISTS `auth_vbb`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `auth_vbb` (
  `vbb_name` varchar(128) NOT NULL,
  `vbb_id` int(4) DEFAULT NULL,
  `account_id` int(4) DEFAULT NULL,
  PRIMARY KEY (`vbb_name`),
  KEY `vbb_id_idx` (`vbb_id`)
) ENGINE=InnoDB;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `session`
--

DROP TABLE IF EXISTS `session`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `session` (
  `session_key` bigint(8) NOT NULL,
  `user_id` bigint(8) NOT NULL,
  `session_date` datetime NOT NULL,
  `display_name` varchar(128) NOT NULL,
  PRIMARY KEY (`session_key`),
  UNIQUE KEY `session_key_UNIQUE` (`session_key`)
) ENGINE=InnoDB;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `unit_party`
--

DROP TABLE IF EXISTS `unit_party`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `unit_party` (
  `user_id` bigint(8) NOT NULL,
  `party_json` varchar(1024) DEFAULT NULL,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `user_id_UNIQUE` (`user_id`)
) ENGINE=InnoDB;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `unit_roster`
--

DROP TABLE IF EXISTS `unit_roster`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `unit_roster` (
  `user_id` bigint(8) NOT NULL,
  `unit_json` varchar(1024) DEFAULT NULL
) ENGINE=InnoDB;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2012-10-30  9:10:09

DROP TABLE IF EXISTS `version`;
CREATE  TABLE `version` (
  `version_number` INT(4) NOT NULL
 );
 
REPLACE `version` SET `version_number` = 0;