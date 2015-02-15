-- MySQL dump 10.11
--
-- Host: localhost    Database: accounting
-- ------------------------------------------------------
-- Server version	5.0.77

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
-- Table structure for table `affiliate_cash_balance`
--

DROP TABLE IF EXISTS `affiliate_cash_balance`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `affiliate_cash_balance` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `affiliate_id` int(10) unsigned NOT NULL default '0',
  `balance` decimal(12,2) NOT NULL default '0.00',
  PRIMARY KEY  (`id`),
  KEY `affiliate_id` (`affiliate_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `affiliate_cash_transactions`
--

DROP TABLE IF EXISTS `affiliate_cash_transactions`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `affiliate_cash_transactions` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `affiliate_id` int(10) unsigned NOT NULL default '0',
  `receipt_id` int(10) unsigned NOT NULL default '0',
  `amount` decimal(10,2) NOT NULL default '0.00',
  `balance` decimal(12,2) NOT NULL default '0.00',
  `date` timestamp NOT NULL default CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`),
  KEY `affiliate_id` (`affiliate_id`),
  KEY `receipt_id` (`receipt_id`),
  KEY `amount` (`amount`),
  KEY `balance` (`balance`),
  KEY `timestamp` (`date`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `agent_cash_balance`
--

DROP TABLE IF EXISTS `agent_cash_balance`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `agent_cash_balance` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `agent_id` int(10) unsigned NOT NULL default '0',
  `balance` decimal(12,2) NOT NULL default '0.00',
  `total_spent` decimal(12,2) NOT NULL default '0.00',
  PRIMARY KEY  (`id`),
  KEY `agent_id` (`agent_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `agent_cash_transactions`
--

DROP TABLE IF EXISTS `agent_cash_transactions`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `agent_cash_transactions` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `agent_id` int(10) unsigned NOT NULL default '0',
  `receipt_id` int(10) unsigned NOT NULL default '0',
  `amount` decimal(10,2) NOT NULL default '0.00',
  `balance` decimal(12,2) NOT NULL default '0.00',
  `date` timestamp NOT NULL default CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`),
  KEY `agent_id` (`agent_id`),
  KEY `receipt_id` (`receipt_id`),
  KEY `amount` (`amount`),
  KEY `balance` (`balance`),
  KEY `timestamp` (`date`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `agent_cc_transaction_balance`
--

DROP TABLE IF EXISTS `agent_cc_transaction_balance`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `agent_cc_transaction_balance` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `agent_id` int(10) unsigned NOT NULL default '0',
  `transaction_id` varchar(64) NOT NULL default '',
  `balance_remaining` decimal(12,2) NOT NULL default '0.00',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `transaction_id` (`transaction_id`),
  KEY `agent_id` (`agent_id`),
  KEY `balance_remaining` (`balance_remaining`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `agent_promo_balance`
--

DROP TABLE IF EXISTS `agent_promo_balance`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `agent_promo_balance` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `agent_id` int(10) unsigned NOT NULL default '0',
  `balance` decimal(12,2) NOT NULL default '0.00',
  `balance_available` decimal(12,2) NOT NULL default '0.00',
  PRIMARY KEY  (`id`),
  KEY `agent_id` (`agent_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `agent_promo_transactions`
--

DROP TABLE IF EXISTS `agent_promo_transactions`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `agent_promo_transactions` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `agent_id` int(10) unsigned NOT NULL default '0',
  `receipt_id` int(10) unsigned NOT NULL default '0',
  `amount` decimal(10,2) NOT NULL default '0.00',
  `amount_available` decimal(10,2) NOT NULL default '0.00',
  `balance` decimal(12,2) NOT NULL default '0.00',
  `balance_available` decimal(10,2) default NULL,
  `date` timestamp NOT NULL default CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`),
  KEY `agent_id` (`agent_id`),
  KEY `receipt_id` (`receipt_id`),
  KEY `amount` (`amount`),
  KEY `balance` (`balance`),
  KEY `timestamp` (`date`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `cash_balance`
--

DROP TABLE IF EXISTS `cash_balance`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `cash_balance` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `balance` decimal(12,2) NOT NULL default '0.00',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `cash_transactions`
--

DROP TABLE IF EXISTS `cash_transactions`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `cash_transactions` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `receipt_id` int(10) unsigned NOT NULL default '0',
  `amount` decimal(10,2) NOT NULL default '0.00',
  `balance` decimal(12,2) NOT NULL default '0.00',
  `date` timestamp NOT NULL default CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`),
  KEY `receipt_id` (`receipt_id`),
  KEY `amount` (`amount`),
  KEY `balance` (`balance`),
  KEY `timestamp` (`date`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `credit_card_processing_log`
--

DROP TABLE IF EXISTS `credit_card_processing_log`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `credit_card_processing_log` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `agent_id` int(10) unsigned NOT NULL default '0',
  `amount` decimal(10,2) NOT NULL default '0.00',
  `card_id` int(10) unsigned NOT NULL default '0',
  `card_name` varchar(255) NOT NULL default 'Unknown',
  `card_address` varchar(255) NOT NULL default 'Unknown',
  `card_city` varchar(255) NOT NULL default 'Unknown',
  `card_state` char(2) NOT NULL default 'XX',
  `card_zip` char(5) NOT NULL default '00000',
  `card_mask` char(12) NOT NULL default '411111**11',
  `exp_month` char(2) NOT NULL default '00',
  `exp_year` char(4) NOT NULL default '0000',
  `transaction_id` varchar(64) NOT NULL default '0',
  `approved` varchar(16) NOT NULL default 'Unknown',
  `avs` char(4) default NULL,
  `error_code` varchar(16) default NULL,
  `error_code_description` varchar(16) default NULL,
  `time` timestamp NOT NULL default CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`),
  KEY `agent_id` (`agent_id`),
  KEY `transaction_id` (`transaction_id`),
  KEY `error_code` (`error_code`),
  KEY `card_name` (`card_name`),
  KEY `card_mask` (`card_mask`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `lead_transaction_lu`
--

DROP TABLE IF EXISTS `lead_transaction_lu`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `lead_transaction_lu` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `transaction_id` varchar(64) NOT NULL default '',
  `lead_id` int(10) unsigned NOT NULL default '0',
  `amount` decimal(12,2) NOT NULL default '0.00',
  `date` timestamp NOT NULL default CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`),
  KEY `transaction_id` (`transaction_id`),
  KEY `lead_id` (`lead_id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `promo_balance`
--

DROP TABLE IF EXISTS `promo_balance`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `promo_balance` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `balance` decimal(12,2) NOT NULL default '0.00',
  `balance_available` decimal(12,2) NOT NULL default '0.00',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `promo_payout_multiplier`
--

DROP TABLE IF EXISTS `promo_payout_multiplier`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `promo_payout_multiplier` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `agent_id` int(10) unsigned NOT NULL default '0',
  `multiplier` decimal(5,2) NOT NULL default '0.10',
  PRIMARY KEY  (`id`),
  KEY `agent_id` (`agent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `promo_transactions`
--

DROP TABLE IF EXISTS `promo_transactions`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `promo_transactions` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `receipt_id` int(10) unsigned NOT NULL default '0',
  `amount` decimal(10,2) NOT NULL default '0.00',
  `amount_available` decimal(10,2) NOT NULL default '0.00',
  `balance` decimal(12,2) NOT NULL default '0.00',
  `balance_available` decimal(12,2) NOT NULL default '0.00',
  `date` timestamp NOT NULL default CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`),
  KEY `receipt_id` (`receipt_id`),
  KEY `amount` (`amount`),
  KEY `balance` (`balance`),
  KEY `timestamp` (`date`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `receipt_types`
--

DROP TABLE IF EXISTS `receipt_types`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `receipt_types` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `type` varchar(45) default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `type_UNIQUE` (`type`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `receipts`
--

DROP TABLE IF EXISTS `receipts`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `receipts` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `receipt_type_id` int(10) unsigned NOT NULL default '0',
  `people_id_credited` int(10) unsigned NOT NULL default '0',
  `people_id_debited` int(10) unsigned NOT NULL default '0',
  `transaction_id` varchar(64) default NULL,
  `lead_id` int(10) unsigned default NULL,
  `amount` decimal(10,2) NOT NULL default '0.00',
  `notes` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  KEY `receipt_type_id` (`receipt_type_id`),
  KEY `people_id_credited` (`people_id_credited`),
  KEY `people_id_debited` (`people_id_debited`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `reconciliation_log`
--

DROP TABLE IF EXISTS `reconciliation_log`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `reconciliation_log` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `receipt_id` int(10) unsigned NOT NULL default '0',
  `people_id` int(10) unsigned NOT NULL default '0',
  `specified_amount` decimal(12,2) NOT NULL default '0.00',
  `allowed_amount` decimal(12,2) NOT NULL default '0.00',
  `error_amount` decimal(12,2) NOT NULL default '0.00',
  `date` timestamp NOT NULL default CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`),
  KEY `receipt_id` (`receipt_id`),
  KEY `people_id` (`people_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2010-04-08 17:26:54
