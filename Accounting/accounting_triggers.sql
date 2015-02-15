-- MySQL dump 10.11
--
-- Host: localhost    Database: accounting
-- ------------------------------------------------------
-- Server version	5.0.77
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

/*!50003 SET @SAVE_SQL_MODE=@@SQL_MODE*/;

DELIMITER ;;
/*!50003 SET SESSION SQL_MODE="" */;;
/*!50003 CREATE */ /*!50017 DEFINER=`bjones`@`%` */ /*!50003 TRIGGER `updateAffiliateBalance` AFTER UPDATE ON `affiliate_cash_balance` FOR EACH ROW BEGIN
    UPDATE `leads`.`affiliates` SET balance=NEW.balance WHERE id=NEW.affiliate_id;
  END */;;

DELIMITER ;
/*!50003 SET SESSION SQL_MODE=@SAVE_SQL_MODE*/;

/*!50003 SET @SAVE_SQL_MODE=@@SQL_MODE*/;

DELIMITER ;;
/*!50003 SET SESSION SQL_MODE="" */;;
/*!50003 CREATE */ /*!50017 DEFINER=`bjones`@`%` */ /*!50003 TRIGGER `updateAgentBalance` AFTER UPDATE ON `agent_cash_balance` FOR EACH ROW BEGIN
    UPDATE `leads`.`agents` SET balance=NEW.balance WHERE id=NEW.agent_id;
  END */;;

DELIMITER ;
/*!50003 SET SESSION SQL_MODE=@SAVE_SQL_MODE*/;

/*!50003 SET @SAVE_SQL_MODE=@@SQL_MODE*/;

DELIMITER ;;
/*!50003 SET SESSION SQL_MODE="" */;;
/*!50003 CREATE */ /*!50017 DEFINER=`bjones`@`%` */ /*!50003 TRIGGER `updateAgentPromoBalance` AFTER UPDATE ON `agent_promo_balance` FOR EACH ROW BEGIN
    UPDATE `leads`.`agents` SET promo_balance=NEW.balance WHERE id=NEW.agent_id;
    UPDATE `leads`.`agents` SET promo_balance_available=NEW.balance_available where id=NEW.agent_id;
  END */;;

DELIMITER ;
/*!50003 SET SESSION SQL_MODE=@SAVE_SQL_MODE*/;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2010-04-08 17:28:16
