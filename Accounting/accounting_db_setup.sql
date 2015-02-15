DROP TABLE IF EXISTS `affiliate_cash_balance`;
CREATE TABLE `affiliate_cash_balance` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `affiliate_id` int(10) unsigned NOT NULL default '0',
  `balance` decimal(12,2) NOT NULL default '0.00',
  PRIMARY KEY  (`id`),
  KEY `affiliate_id` (`affiliate_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `affiliate_cash_transactions`;
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
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `agent_cash_balance`;
CREATE TABLE `agent_cash_balance` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `agent_id` int(10) unsigned NOT NULL default '0',
  `balance` decimal(12,2) NOT NULL default '0.00',
  `total_spent` decimal(12,2) NOT NULL default '0.00',
  PRIMARY KEY  (`id`),
  KEY `agent_id` (`agent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `agent_cash_transactions`;
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
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `agent_promo_balance`;
CREATE TABLE `agent_promo_balance` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `agent_id` int(10) unsigned NOT NULL default '0',
  `balance` decimal(12,2) NOT NULL default '0.00',
  `balance_available` decimal(12,2) NOT NULL default '0.00',
  PRIMARY KEY  (`id`),
  KEY `agent_id` (`agent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `agent_promo_transactions`;
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
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `agent_cc_transaction_balance`;
CREATE TABLE `agent_cc_transaction_balance` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `agent_id` int(10) unsigned NOT NULL default 0,
  `transaction_id` varchar(64) NOT NULL default '',
  `balance_remaining` decimal(12,2) NOT NULL default '0.00',
  PRIMARY KEY (`id`),
  KEY `agent_id` (`agent_id`),
  UNIQUE `transaction_id` (`transaction_id`),
  KEY `balance_remaining` (`balance_remaining`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
  
DROP TABLE IF EXISTS `cash_balance`;
CREATE TABLE `cash_balance` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `balance` decimal(12,2) NOT NULL default '0.00',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `cash_transactions`;
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
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `credit_card_processing_log`;
CREATE TABLE `credit_card_processing_log` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `agent_id` int(10) unsigned NOT NULL default 0,
  `amount` decimal(10,2) NOT NULL default '0.00',
  `card_id` int(10) unsigned NOT NULL default 0,
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
  `avs` char(4),
  `error_code` varchar(16),
  `error_code_description` varchar(16),
  `time` timestamp NOT NULL default CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `agent_id` (`agent_id`),
  KEY `transaction_id` ( `transaction_id`),
  KEY `error_code` (`error_code`),
  KEY `card_name` (`card_name`),
  KEY `card_mask` (`card_mask`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `promo_balance`;
CREATE TABLE `promo_balance` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `balance` decimal(12,2) NOT NULL default '0.00',
  `balance_available` DECIMAL(12,2) NOT NULL default '0.00',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `promo_transactions`;
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
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `promo_payout_multiplier`;
CREATE TABLE `promo_payout_multiplier` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `agent_id` int(10) unsigned NOT NULL default '0',
  `multiplier` decimal(5,2) NOT NULL default '0.10',
  PRIMARY KEY  (`id`),
  KEY `agent_id` (`agent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `receipt_types`;
CREATE TABLE `receipt_types` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `type` varchar(45) default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `type_UNIQUE` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `receipts`;
CREATE TABLE `receipts` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `receipt_type_id` int(10) unsigned NOT NULL default '0',
  `people_id_credited` int(10) unsigned NOT NULL default '0',
  `people_id_debited` int(10) unsigned NOT NULL default '0',
  `transaction_id` varchar(64),
  `lead_id` int(10) unsigned,
  `amount` decimal(10,2) NOT NULL default '0.00',
  `notes` varchar(255) default NULL,
  `timestamp` timestamp NOT NULL default CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`),
  KEY `receipt_type_id` (`receipt_type_id`),
  KEY `people_id_credited` (`people_id_credited`),
  KEY `people_id_debited` (`people_id_debited`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `reconciliation_log`;
CREATE TABLE `reconciliation_log` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `receipt_id` int(10) unsigned NOT NULL default '0',
  `people_id` int(10) unsigned NOT NULL default '0',
  `specified_amount` decimal(12,2) NOT NULL default '0.00',
  `allowed_amount` decimal(12,2) NOT NULL default '0.00',
  `error_amount` decimal(12,2) NOT NULL default '0.00',
  `date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`),
  KEY `receipt_id` (`receipt_id`),
  KEY `people_id` (`people_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO receipt_types ( type ) VALUES ( 'Credit Card Fund' );
INSERT INTO receipt_types ( type ) VALUES ( 'Credit Card Refund' );
INSERT INTO receipt_types ( type ) VALUES ( 'Add Promo Credit' );
INSERT INTO receipt_types ( type ) VALUES ( 'Delete Promo Credit' );
INSERT INTO receipt_types ( type ) VALUES ( 'Delete Promo Credit -- Lead Refund' );
INSERT INTO receipt_types ( type ) VALUES ( 'Add Promo Credit -- Lead Purchase' );
INSERT INTO receipt_types ( type ) VALUES ( 'Closing Account' );
INSERT INTO receipt_types ( type ) VALUES ( 'Closing Account -- Promo Adjustment' );
INSERT INTO receipt_types ( type ) VALUES ( 'Affiliate Payment Made' );
INSERT INTO receipt_types ( type ) VALUES ( 'Affiliate Payment Received' );
INSERT INTO receipt_types ( type ) VALUES ( 'Lead Sale -- Cash' );
INSERT INTO receipt_types ( type ) VALUES ( 'Lead Sale -- Promo' );
INSERT INTO receipt_types ( type ) VALUES ( 'Lead Refund -- Cash' );
INSERT INTO receipt_types ( type ) VALUES ( 'Lead Refund -- Promo' );
INSERT INTO receipt_types ( type ) VALUES ( 'Lead Purchase' );
INSERT INTO receipt_types ( type ) VALUES ( 'Lead Return' );
INSERT INTO receipt_types ( type ) VALUES ( 'Lead Return -- Bogus Data' );
INSERT INTO receipt_types ( type ) VALUES ( 'Lead Return -- Juvenile' );
INSERT INTO receipt_types ( type ) VALUES ( 'Lead Return -- Duplicate' );
INSERT INTO receipt_types ( type ) VALUES ( 'Reversal of Lead Return' );
INSERT INTO receipt_types ( type ) VALUES ( 'Starting Balance -- Cash' );
INSERT INTO receipt_types ( type ) VALUES ( 'Starting Balance -- Promo' );
INSERT INTO receipt_types ( type ) VALUES ( 'Balance Adjustment -- Cash' );
INSERT INTO receipt_types ( type ) VALUES ( 'Balance Adjustment -- Promo' );
INSERT INTO receipt_types ( type ) VALUES ( 'Other' );

INSERT INTO cash_balance ( balance ) VALUES ( 0 );
INSERT INTO promo_balance ( balance, balance_available ) VALUES ( 0, 0 );
