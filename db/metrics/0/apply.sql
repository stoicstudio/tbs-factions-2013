-- MySQL dump 10.13  Distrib 5.5.28, for osx10.6 (i386)
--
-- Host: tbs-db.stoicstudio.com    Database: tbs_metrics_dev_john_graviton
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
-- Table structure for table `battle_action`
--

DROP TABLE IF EXISTS `battle_action`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `battle_action` (
  `userid` bigint(20) DEFAULT NULL,
  `username` varchar(256) DEFAULT NULL,
  `action` varchar(45) DEFAULT NULL,
  `battleid` varchar(256) DEFAULT NULL,
  `turn` int(11) DEFAULT NULL,
  `level` int(11) DEFAULT NULL,
  `entity` varchar(256) DEFAULT NULL,
  `timestamp` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `battle_deploy`
--

DROP TABLE IF EXISTS `battle_deploy`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `battle_deploy` (
  `userid` bigint(20) DEFAULT NULL,
  `username` varchar(256) DEFAULT NULL,
  `battleid` varchar(256) DEFAULT NULL,
  `timestamp` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `battle_results`
--

DROP TABLE IF EXISTS `battle_results`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `battle_results` (
  `userid` bigint(20) DEFAULT NULL,
  `username` varchar(256) DEFAULT NULL,
  `battleid` varchar(256) DEFAULT NULL,
  `result` int(11) DEFAULT NULL,
  `renownearned` int(11) DEFAULT NULL,
  `timestamp` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `session_cancel`
--

DROP TABLE IF EXISTS `session_cancel`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `session_cancel` (
  `userid` bigint(20) DEFAULT NULL,
  `username` varchar(256) DEFAULT NULL,
  `sessionkey` varchar(256) DEFAULT NULL,
  `timestamp` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `session_start`
--

DROP TABLE IF EXISTS `session_start`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `session_start` (
  `userid` bigint(20) DEFAULT NULL,
  `username` varchar(256) DEFAULT NULL,
  `sessionkey` varchar(256) DEFAULT NULL,
  `timestamp` timestamp NULL DEFAULT NULL,
  `partymember0` varchar(45) DEFAULT NULL,
  `partymember1` varchar(45) DEFAULT NULL,
  `partymember2` varchar(45) DEFAULT NULL,
  `partymember3` varchar(45) DEFAULT NULL,
  `partymember4` varchar(45) DEFAULT NULL,
  `partymember5` varchar(45) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `session_started`
--

DROP TABLE IF EXISTS `session_started`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `session_started` (
  `session_key` bigint(8) NOT NULL,
  `userid` bigint(8) DEFAULT NULL,
  `display_name` varchar(64) DEFAULT NULL,
  `ipaddress` varchar(32) DEFAULT NULL,
  `start_timestamp` timestamp NULL DEFAULT NULL,
  `start_time` bigint(8) DEFAULT NULL,
  `end_time` bigint(8) DEFAULT NULL,
  `client_os` varchar(64) DEFAULT NULL,
  `client_language` varchar(32) DEFAULT NULL,
  `client_screen_w` int(4) DEFAULT NULL,
  `client_screen_h` int(4) DEFAULT NULL,
  `client_screen_dpi` int(4) DEFAULT NULL,
  PRIMARY KEY (`session_key`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `version`
--

DROP TABLE IF EXISTS `version`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `version` (
  `version_number` int(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2012-11-02 15:28:20

