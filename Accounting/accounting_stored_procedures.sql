DELIMITER $$
DROP PROCEDURE IF EXISTS `accounting`.`addPromoCredit`$$
CREATE PROCEDURE `accounting`.`addPromoCredit`(
  IN agent_id_given INT UNSIGNED,
  IN amount DECIMAL(10,2),
  IN amount_available DECIMAL(10,2),
  OUT result INT )
BEGIN
  DECLARE receipt_id INT UNSIGNED;
  DECLARE people_id INT UNSIGNED;
  DECLARE agent_balance DECIMAL(10,2);
  DECLARE promo_balance DECIMAL(12,2);
  DECLARE agent_balance_available DECIMAL(10,2);
  DECLARE promo_balance_available DECIMAL(12,2);
  DECLARE last_time TIMESTAMP;
  DECLARE count INT UNSIGNED;
  DECLARE error_condition INT;

  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    SET error_condition = 1;

  SET result = 1;
  SET error_condition = 0;

  START TRANSACTION;
  SET people_id = getPeopleID( agent_id_given );
  SET receipt_id = insertReceipt( 'Add Promo Credit', people_id, 0, '',
                                  0, amount, '' );
  SELECT count( agent_id ) INTO count
    FROM agent_promo_balance
    WHERE agent_id = agent_id_given FOR UPDATE;

  IF ( count = 0 )
  THEN
    INSERT INTO agent_promo_balance ( agent_id, balance, balance_available )
      VALUES ( agent_id_given, 0, 0 );
  END IF;

  IF ( error_condition = 1 )
  THEN
    ROLLBACK;
    SET result = '0';
  ELSE
    COMMIT;
  END IF;

  IF ( error_condition = 0 )
  THEN
    START TRANSACTION;

    SELECT balance, balance_available
      INTO agent_balance, agent_balance_available
      FROM agent_promo_balance
      WHERE agent_id = agent_id_given FOR UPDATE;
    SELECT balance, balance_available
      INTO promo_balance, promo_balance_available
      FROM promo_balance
      WHERE id = 1 FOR UPDATE;

    IF ( ISNULL( agent_balance ) )
    THEN
      SET agent_balance = 0;
    END IF;
    IF ( ISNULL(agent_balance_available) )
    THEN
      SET agent_balance_available = 0;
    END IF;
    IF ( ISNULL(promo_balance) )
    THEN
      SET promo_balance = 0;
    END IF;
    IF ( ISNULL(promo_balance_available) )
    THEN
      SET promo_balance_available = 0;
    END IF;

    SET agent_balance = agent_balance + amount;
    SET agent_balance_available = agent_balance_available + amount_available;

    INSERT INTO agent_promo_transactions ( agent_id, receipt_id, amount,
                                           amount_available, balance,
                                           balance_available )
      VALUES ( agent_id_given, receipt_id, amount, amount_available,
               agent_balance, agent_balance_available );
    UPDATE agent_promo_balance
      SET balance = agent_balance, balance_available = agent_balance_available
      WHERE agent_id = agent_id_given;

    SET promo_balance = promo_balance - amount;
    SET promo_balance_available = promo_balance_available - amount_available;

    INSERT INTO promo_transactions ( receipt_id, amount, amount_available,
                                     balance, balance_available )
      VALUES ( receipt_id, -amount, -amount_available,
               promo_balance, promo_balance_available );
    UPDATE promo_balance
      SET balance = promo_balance,
          balance_available = promo_balance_available
      WHERE id = 1;

    IF ( error_condition = 1 )
    THEN
      ROLLBACK;
      SET result = '0';
    ELSE
      COMMIT;
    END IF;
  END IF;
END$$

DROP PROCEDURE IF EXISTS `accounting`.`closeAccount`$$
CREATE PROCEDURE `accounting`.`closeAccount` (
   IN agent_id_given INT UNSIGNED,
   OUT result INT )
BEGIN
  DECLARE receipt_id_cash INT UNSIGNED;
  DECLARE receipt_id_promo INT UNSIGNED;
  DECLARE people_id INT UNSIGNED;
  DECLARE agent_balance DECIMAL(10,2);
  DECLARE agent_promo_balance DECIMAL(10,2);
  DECLARE agent_promo_balance_available DECIMAL(10,2);
  DECLARE cash_balance DECIMAL(12,2);
  DECLARE promo_balance DECIMAL(12,2);
  DECLARE promo_balance_available DECIMAL(12,2);
  DECLARE error_condition INT;
  DECLARE count INT;
  DECLARE notes VARCHAR(45);
  DECLARE l_last_row_fetched INT;
  DECLARE amount_remaining DECIMAL(12,2);
  DECLARE balance_remaining DECIMAL(12,2);
  DECLARE cc_transaction_id VARCHAR(64);

  DECLARE id_cursor CURSOR FOR 
    SELECT id, balance_remaining FROM agent_cc_transaction_balance 
      WHERE agent_id = agent_id and balance_remaining > 0 ORDER BY id ASC;

  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    SET error_condition = 1;
  DECLARE CONTINUE HANDLER FOR NOT FOUND
    SET l_last_row_fetched = 1;

  SET result = 1;
  SET error_condition = 0;
  SET amount_remaining = amount;

  START TRANSACTION;
  SET people_id = getPeopleID( agent_id_given );

  SELECT count( agent_id ) INTO count
    FROM agent_cash_balance
    WHERE agent_id = agent_id_given FOR UPDATE;

  IF ( count = 0 )
  THEN
    INSERT INTO agent_cash_balance ( agent_id, balance )
      VALUEs ( agent_id_given, 0 );
  END IF;

  SELECT count( agent_id ) INTO count
    FROM agent_promo_balance
    WHERE agent_id = agent_id_given FOR UPDATE;

  IF ( count = 0 )
  THEN
    INSERT INTO agent_promo_balance ( agent_id, balance, balance_available )
      VALUE ( agent_id_given, 0, 0 );
  END IF;

  IF ( error_condition = 1 )
  THEN
    ROLLBACK;
    SET result = '0';
  ELSE
    COMMIT;
  END IF;

  IF ( error_condition = 0 )
  THEN
    START TRANSACTION;

    SELECT balance 
      INTO agent_balance 
      FROM agent_cash_balance 
      WHERE agent_id = agent_id_given FOR UPDATE;
    SELECT balance, balance_available 
      INTO agent_promo_balance, agent_promo_balance_available 
      FROM agent_promo_balance 
      WHERE agent_id = agent_id_given FOR UPDATE;
    SELECT balance
      INTO cash_balance
      FROM cash_balance
      WHERE id = 1 FOR UPDATE;
    SELECT balance, balance_available
      INTO promo_balance, promo_balance_available
      FROM promo_balance
      WHERE id = 1 FOR UPDATE;

    IF ( ISNULL( agent_balance ) )
    THEN
      SET agent_balance = 0;
    END IF;
    IF ( ISNULL( agent_promo_balance ) )
    THEN
      SET agent_promo_balance = 0;
    END IF;
    IF ( ISNULL( agent_promo_balance_available ) )
    THEN
      SET agent_promo_balance = 0;
    END IF;
    IF ( ISNULL( cash_balance ) )
    THEN
      SET error_condition = 1;
    END IF;
    IF ( ISNULL( promo_balance ) )
    THEN
      SET error_condition = 1;
    END IF;
    IF ( ISNULL( promo_balance_available ) )
    THEN
      SET error_condition = 1;
    END IF;

    IF ( error_condition = 0 )
    THEN
      OPEN id_cursor;
      id_cursor_loop:LOOP
        FETCH id_cursor INTO cc_transaction_id, balance_remaining;

        IF ( l_last_row_fetched = 1 )
        THEN
          SET error_condition = 0;
          LEAVE id_cursor_loop;
        END IF;
  
        IF ( balance_remaining >= amount_remaining )
        THEN
          UPDATE agent_cc_transaction_balance 
            SET balance_remaining = balance_remaining - amount_remaining
            WHERE id = cc_transaction_id;
          LEAVE id_cursor_loop;
        ELSE
          UPDATE agent_cc_transaction_balance 
            SET balance_remaining = 0 WHERE id = cc_transaction_id;
          SET amount_remaining = amount_remaining - balance_remaining;
        END IF;
      END LOOP id_cursor_loop;
      CLOSE id_cursor;

      SET cash_balance = cash_balance + agent_balance;
      SET promo_balance = promo_balance + agent_promo_balance;
      SET promo_balance_available = promo_balance_available + agent_promo_balance_available;

      SET receipt_id_cash = insertReceipt ( 'Closing Account', 0, people_id, '', 0, agent_balance, '' );
      SET receipt_id_promo = insertReceipt( 'Closing Account -- Promo Adjustment',
        			  		 0, people_id, '', 0, agent_promo_balance, '' );

      INSERT INTO agent_cash_transactions( agent_id, receipt_id, amount, balance )
        VALUES ( agent_id_given, receipt_id_cash, -agent_balance, 0 );
      INSERT INTO cash_transactions( receipt_id, amount, balance )
        VALUES ( receipt_id_cash, agent_balance, cash_balance );
      INSERT INTO agent_promo_transactions( agent_id, receipt_id, 
                                            amount, amount_available,
	 			            balance, balance_available )
	VALUES ( agent_id_given, receipt_id_promo, -agent_promo_balance,
	          -agent_promo_balance_available, 0, 0 );
      INSERT INTO promo_transactions ( receipt_id, amount, amount_available, balance, balance_available )
        VALUES ( receipt_id_promo, agent_promo_balance, agent_promo_balance_available,
	         promo_balance, promo_balance_available );

      UPDATE agent_cash_balance SET balance = 0 where agent_id = agent_id_given;
      UPDATE agent_promo_balance SET balance = 0, balance_available = 0 WHERE agent_id = agent_id_given;
      UPDATE cash_balance SET balance = cash_balance WHERE id = 1;
      UPDATE promo_balance 
        SET balance = promo_balance,
            balance_available = promo_balance_available 
        WHERE id = 1;
    END IF;

    IF ( error_condition = 1 )
    THEN
      ROLLBACK;
      SET result = '0';
    ELSE
      COMMIT;
    END IF;
  END IF;
END$$

DROP PROCEDURE IF EXISTS `accounting`.`creditCardFund`$$
CREATE PROCEDURE `accounting`.`creditCardFund`(
  IN agent_id_given INT UNSIGNED,
  IN amount DECIMAL(10,2),
  IN trans_id VARCHAR(64),
  OUT result INT )
BEGIN
  DECLARE receipt_id INT UNSIGNED;
  DECLARE people_id INT UNSIGNED;
  DECLARE count INT UNSIGNED;
  DECLARE agent_balance DECIMAL(10,2);
  DECLARE cash_balance DECIMAL(12,2);
  DECLARE last_time TIMESTAMP;
  DECLARE error_condition INT;

  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    SET error_condition = 1;

  SET result = 1;
  SET error_condition = 0;

  START TRANSACTION;
  SELECT count( agent_id ) INTO count
    FROM agent_cash_balance
    WHERE agent_id = agent_id_given FOR UPDATE;

  IF ( count = 0 )
  THEN
    INSERT INTO agent_cash_balance ( agent_id, balance ) VALUES ( agent_id_given, 0 );
  END IF;

  IF ( error_condition = 1 )
  THEN
    ROLLBACK;
    SET result = '0';
  ELSE
    COMMIT;
  END IF;

  IF ( error_condition = 0 )
  THEN
    START TRANSACTION;

     SET people_id = getPeopleID( agent_id_given );
     SET receipt_id = insertReceipt( 'Credit Card Fund', people_id, 0,
                                  trans_id, 0, amount, '' );

    INSERT INTO agent_cc_transaction_balance ( agent_id, transaction_id,
                                               balance_remaining )
      VALUES ( agent_id_given, trans_id, amount );
    SELECT balance INTO agent_balance
      FROM agent_cash_balance
      WHERE agent_id = agent_id_given FOR UPDATE;
    SELECT balance INTO cash_balance
      FROM cash_balance
      WHERE id = 1 FOR UPDATE;

    IF ( ISNULL( agent_balance ) )
    THEN
      SET agent_balance = 0;
    END IF;
    IF ( ISNULL(cash_balance) )
    THEN
      SET cash_balance = 0;
    END IF;

    SET agent_balance = agent_balance + amount;
    INSERT INTO agent_cash_transactions ( agent_id, receipt_id, amount, balance )
      VALUES ( agent_id_given, receipt_id, amount, agent_balance );
    UPDATE agent_cash_balance
      SET balance = agent_balance
      WHERE agent_id = agent_id_given;

    SET cash_balance = cash_balance - amount;
    INSERT INTO cash_transactions ( receipt_id, amount, balance )
      VALUES ( receipt_id, -amount, cash_balance );
    UPDATE cash_balance SET balance = cash_balance WHERE id = 1;

    IF ( error_condition = 1 )
    THEN
      ROLLBACK;
      SET result = '0';
    ELSE
      COMMIT;
    END IF;
  END IF;
END$$

DROP PROCEDURE IF EXISTS `accounting`.`creditCardRefund`$$
 CREATE PROCEDURE `creditCardRefund`(
  IN agent_id_given INT UNSIGNED,
  IN amount DECIMAL(10,2),
  IN trans_id VARCHAR(64),
  OUT result INT )
BEGIN
  DECLARE receipt_id INT UNSIGNED;
  DECLARE people_id INT UNSIGNED;
  DECLARE count INT UNSIGNED;
  DECLARE agent_balance DECIMAL(10,2);
  DECLARE cash_balance DECIMAL(12,2);
  DECLARE last_time TIMESTAMP;
  DECLARE cc_transaction_id INT UNSIGNED;
  DECLARE cc_balance_remaining DECIMAL(12,2);
  DECLARE amount_remaining DECIMAL(12,2);
  DECLARE error_condition INT;
  DECLARE l_last_row_fetched INT;
  DECLARE found_rows INT;
  DECLARE difference DECIMAL(12,2);
  DECLARE notes VARCHAR(255);

  DECLARE id_cursor CURSOR FOR
    SELECT id, balance_remaining FROM agent_cc_transaction_balance
      WHERE agent_id = agent_id_given AND balance_remaining > 0 ORDER BY id ASC;

  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    SET error_condition = 1;
  DECLARE CONTINUE HANDLER FOR NOT FOUND
    SET l_last_row_fetched = 1;

  SET result = 1;
  SET error_condition = 0;
  SET amount_remaining = amount;

  START TRANSACTION;
  SELECT count( agent_id ) INTO count
    FROM agent_cash_balance
    WHERE agent_id = agent_id_given FOR UPDATE;

  IF ( count = 0 )
  THEN
    INSERT INTO agent_balance ( agent_id, balance ) VALUES ( agent_id_given, 0 );
  END IF;
  IF ( error_condition = 1 )
  THEN
    ROLLBACK;
    SET result = '0';
  ELSE
    COMMIT;
  END IF;

  IF ( error_condition = 0 )
  THEN
    START TRANSACTION;

    SET people_id = getPeopleID( agent_id_given );
    SET receipt_id = insertReceipt( 'Credit Card Refund', 0, people_id,
                                    trans_id, 0, amount, '' );

    SELECT balance INTO agent_balance
      FROM agent_cash_balance
      WHERE agent_id = agent_id_given FOR UPDATE;
    SELECT balance INTO cash_balance FROM cash_balance WHERE id = 1 FOR UPDATE;

    IF ( ISNULL( agent_balance ) )
    THEN
      SET agent_balance = 0;
    END IF;
    IF ( ISNULL(cash_balance) )
    THEN
      SET cash_balance = 0;
    END IF;

    OPEN id_cursor;

    id_cursor_loop:LOOP
      FETCH id_cursor INTO cc_transaction_id, cc_balance_remaining;

      IF ( l_last_row_fetched = 1 )
      THEN
        SET error_condition = 0;
        LEAVE id_cursor_loop;
      END IF;

      IF ( cc_balance_remaining >= amount_remaining )
      THEN
        SET cc_balance_remaining = cc_balance_remaining - amount_remaining;
        UPDATE agent_cc_transaction_balance
          SET balance_remaining = cc_balance_remaining
          WHERE id = cc_transaction_id;
        LEAVE id_cursor_loop;
      ELSE
        DELETE FROM agent_cc_transaction_balance WHERE id = cc_transaction_id;
        SET amount_remaining = amount_remaining - cc_balance_remaining;
      END IF;

    END LOOP id_cursor_loop;
    CLOSE id_cursor;

    SET cash_balance = cash_balance + amount;
    INSERT INTO cash_transactions ( receipt_id, amount, balance )
      VALUES ( receipt_id, amount, cash_balance );
    UPDATE cash_balance SET balance = cash_balance WHERE id = 1;

    IF ( amount > agent_balance )
    THEN
      SET difference = amount - agent_balance;
      SET notes = CONCAT( '$', difference,
                          ' over account balance refunded' );
      SET result = '2';
      UPDATE receipts SET notes = notes where id = receipt_id LIMIT 1;
      INSERT INTO reconciliation_log ( receipt_id, people_id, specified_amount,
                                       allowed_amount, error_amount )
        VALUES ( receipt_id, people_id, amount, agent_balance, difference );
      SET amount = agent_balance;
      DELETE FROM agent_cc_transaction_balance WHERE agent_id = agent_id_given;
    END IF;

    SET agent_balance = agent_balance - amount;
    INSERT INTO agent_cash_transactions ( agent_id, receipt_id, amount, balance )
      VALUES ( agent_id_given, receipt_id, -amount, agent_balance );
    UPDATE agent_cash_balance
      SET balance = agent_balance
      WHERE agent_id = agent_id_given;

    IF ( error_condition = 1 )
    THEN
      ROLLBACK;
      SET result = '0';
    ELSE
      COMMIT;
    END IF;
  END IF;
END$$

DROP PROCEDURE IF EXISTS `accounting`.`removePromoCredit`$$
CREATE PROCEDURE `accounting`.`removePromoCredit`(
  IN agent_id INT UNSIGNED,
  IN amount DECIMAL(10,2),
  OUT result INT )
BEGIN
  DECLARE receipt_id INT UNSIGNED;
  DECLARE people_id INT UNSIGNED;
  DECLARE agent_balance DECIMAL(10,2);
  DECLARE agent_balance_available DECIMAL(10,2);
  DECLARE promo_balance DECIMAL(12,2);
  DECLARE promo_balance_available DECIMAL(10,2);
  DECLARE amount_available DECIMAL(10,2);
  DECLARE last_time TIMESTAMP;
  DECLARE count INT UNSIGNED;
  DECLARE error_condition INT;
  DECLARE difference DECIMAL(10,2);
  DECLARE _notes VARCHAR(255);

  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    SET error_condition = 1;

  SET result = 1;
  SET error_condition = 0;
  SET amount_available = amount;

  START TRANSACTION;

  SELECT count( agent_id ) INTO count
    FROM agent_promo_balance
    WHERE agent_id = agent_id FOR UPDATE;

  IF ( count = 0 )
  THEN
    INSERT INTO agent_promo_balance ( agent_id, balance, balance_available )
      VALUES ( agent_id, 0, 0 );
  END IF;

  IF ( error_condition = 1 )
  THEN
    ROLLBACK;
    SET result = '0';
  ELSE
    COMMIT;
  END IF;

  IF ( error_condition = 0 )
  THEN
    START TRANSACTION;

    SET people_id = getPeopleID( agent_id );
    SET receipt_id = insertReceipt( 'Delete Promo Credit', 0, people_id,
                                  '', 0, amount, '' );

    SELECT balance, balance_available
      INTO agent_balance, agent_balance_available
      FROM agent_promo_balance
      WHERE agent_id = agent_id FOR UPDATE;
    SELECT balance, balance_available
      INTO promo_balance, promo_balance_available
      FROM promo_balance
      WHERE id = 1 FOR UPDATE;

    IF ( ISNULL( agent_balance ) )
    THEN
      SET agent_balance = 0;
    END IF;
    IF ( ISNULL(agent_balance_available) )
    THEN
      SET agent_balance_available = 0;
    END IF;
    IF ( ISNULL(promo_balance) )
    THEN
      SET promo_balance = 0;
    END IF;
    IF ( ISNULL(promo_balance_available) )
    THEN
      SET promo_balance_available = 0;
    END IF;

    IF ( amount > agent_balance )
    THEN
      SET difference = amount - agent_balance;
      SELECT notes INTO _notes
        FROM receipts
        WHERE id = receipt_id;
      UPDATE receipts
        SET notes=concat('$', difference, ' over agent promo credit balance refunded.  ',
                         _notes)
        WHERE id = receipt_id;
      INSERT INTO reconciliation_log ( receipt_id, people_id, specified_amount,
                                       allowed_amount, error_amount )
        VALUES ( receipt_id, people_id, amount, agent_balance, difference );
      SET amount = agent_balance;
    END IF;

    IF ( amount_available > agent_balance_available )
    THEN
      SET amount_available = agent_balance_available;
    END IF;

    SET agent_balance = agent_balance - amount;
    SET agent_balance_available = agent_balance_available - amount_available;

    IF ( agent_balance_available < 0 )
    THEN
      SET agent_balance_available = 0;
    END IF;

    INSERT INTO agent_promo_transactions ( agent_id, receipt_id, amount,
                                           amount_available, balance,
                                           balance_available )
      VALUES ( agent_id, receipt_id, -amount, -amount_available,
               agent_balance, agent_balance_available );
    UPDATE agent_promo_balance
      SET balance = agent_balance, balance_available = agent_balance_available
      WHERE agent_id = agent_id;

    SET promo_balance = promo_balance + amount;
    SET promo_balance_available = promo_balance_available + amount_available;

    INSERT INTO promo_transactions ( receipt_id, amount, amount_available,
                                     balance, balance_available )
      VALUES ( receipt_id, amount, amount_available, promo_balance,
               promo_balance_available );
    UPDATE promo_balance
      SET balance = promo_balance,
          balance_available = promo_balance_available
      WHERE id = 1;

   IF ( error_condition = 1 )
    THEN
      ROLLBACK;
      SET result = '0';
    ELSE
      COMMIT;
    END IF;
  END IF;
END$$

DROP FUNCTION IF EXISTS `accounting`.`getAffiliatePeopleID`$$
CREATE FUNCTION `accounting`.`getAffiliatePeopleID`(
  affiliate_id INT UNSIGNED ) RETURNS int(10) unsigned
    READS SQL DATA
BEGIN
  DECLARE people INT UNSIGNED;

  DECLARE CONTINUE HANDLER FOR 1329
    SET people=0;

  SELECT people_id INTO people FROM `leads`.`affiliates` WHERE id=affiliate_id;
  RETURN(people);
END$$

DROP FUNCTION IF EXISTS `accounting`.`getPeopleID`$$
CREATE FUNCTION `accounting`.`getPeopleID`(
  agent_id INT UNSIGNED ) RETURNS int(10) unsigned
    READS SQL DATA
BEGIN
  DECLARE people INT UNSIGNED;

  DECLARE CONTINUE HANDLER FOR 1329
    SET people=0;

  SELECT people_id INTO people FROM `leads`.`agents` WHERE id=agent_id;
  RETURN(people);
END$$

DROP FUNCTION IF EXISTS `accounting`.`getReceiptTypeID`$$
CREATE FUNCTION `accounting`.`getReceiptTypeID`(
  description VARCHAR(45) ) RETURNS int(10) unsigned
    DETERMINISTIC
BEGIN
  DECLARE receipt_type_id INT UNSIGNED;

  DECLARE CONTINUE HANDLER FOR 1329
    SET receipt_type_id=0;

  SELECT id INTO receipt_type_id FROM receipt_types WHERE type=description;
  RETURN(receipt_type_id);
END$$

DROP FUNCTION IF EXISTS `accounting`.`insertReceipt`$$
CREATE FUNCTION `accounting`.`insertReceipt`(
  receipt_type VARCHAR(45),
  people_id_credited INT UNSIGNED,
  people_id_debited INT UNSIGNED,
  trans_id VARCHAR(64),
  lead_id  INT UNSIGNED,
  amount DECIMAL(10,2),
  notes VARCHAR(255) ) RETURNS int(10) unsigned
    DETERMINISTIC
BEGIN
  DECLARE receipt_type_id INT UNSIGNED;
  DECLARE receipt_id INT UNSIGNED;
  SET receipt_type_id = getReceiptTypeID(receipt_type);
  INSERT INTO receipts ( receipt_type_id, people_id_credited,
                         people_id_debited, transaction_id,
                         lead_id, amount, notes )
    VALUES ( receipt_type_id, people_id_credited, people_id_debited,
             trans_id, lead_id, amount, notes );
  SELECT LAST_INSERT_ID() INTO receipt_id;
  RETURN(receipt_id);
END$$

DROP PROCEDURE IF EXISTS `accounting`.`affiliatePaymentMade`$$
CREATE PROCEDURE `accounting`.`affiliatePaymentMade`(
  IN affiliate_id INT unsigned,
  IN amount DECIMAL(12,2),
  OUT result INT )
BEGIN
  DECLARE receipt_id INT UNSIGNED;
  DECLARE people_id INT UNSIGNED;
  DECLARE affiliate_balance DECIMAL(12,2);
  DECLARE cash_balance DECIMAL(12,2);
  DECLARE count INT;
  DECLARE error_condition INT;

  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    SET error_condition = 1;

  SET result = 1;
  SET error_condition = 0;

  START TRANSACTION;

  SELECT count( affiliate_id ) INTO count
    FROM affiliate_cash_balance
    WHERE affiliate_id = affiliate_id FOR UPDATE;

  IF ( count = 0 )
  THEN
    INSERT INTO affiliate_cash_balance ( affiliate_id, balance )
      VALUES ( affiliate_id, 0 );
  END IF;
  IF ( error_condition = 1 )
  THEN
    ROLLBACK;
    SET result = 0;
  ELSE
    COMMIT;
  END IF;

  IF ( error_condition = 0 )
  THEN
    START TRANSACTION;

    SET people_id = getAffiliatePeopleID( affiliate_id );
    SET receipt_id = insertReceipt( 'Affiliate Payment Made', 0, people_id, '',
                                  0, amount, '' );

    SELECT balance INTO affiliate_balance
      FROM affiliate_cash_balance
      WHERE affiliate_id = affiliate_id FOR UPDATE;
    SELECT balance INTO cash_balance
      FROM cash_balance
      WHERE id = 1 FOR UPDATE;

    SET affiliate_balance = affiliate_balance - amount;
    INSERT INTO affiliate_cash_transactions ( affiliate_id, receipt_id,
                                              amount, balance )
      VALUES ( affiliate_id, receipt_id, -amount, affiliate_balance );
    UPDATE affiliate_cash_balance
      SET balance = affiliate_balance WHERE affiliate_id = affiliate_id;

    SET cash_balance = cash_balance + amount;
    INSERT INTO cash_transactions ( receipt_id, amount, balance )
      VALUES ( receipt_id, amount, cash_balance );
    UPDATE cash_balance SET balance = cash_balance WHERE id = 1;

    IF ( error_condition = 1 )
    THEN
      ROLLBACK;
      SET result = '0';
    ELSE
      COMMIT;
    END IF;
  END IF;
END$$

DROP PROCEDURE IF EXISTS `accounting`.`affiliatePaymentReceived`$$
CREATE PROCEDURE `accounting`.`affiliatePaymentReceived`(
  IN affiliate_id INT unsigned,
  IN amount DECIMAL(12,2),
  OUT result INT )
BEGIN
  DECLARE receipt_id INT UNSIGNED;
  DECLARE people_id INT UNSIGNED;
  DECLARE affiliate_balance DECIMAL(12,2);
  DECLARE cash_balance DECIMAL(12,2);
  DECLARE count INT;
  DECLARE error_condition INT;

  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    SET error_condition = 1;

  SET result = 1;
  SET error_condition = 0;

  START TRANSACTION;
  SELECT count( affiliate_id ) INTO count
    FROM affiliate_cash_balance
    WHERE affiliate_id = affiliate_id FOR UPDATE;

  IF ( count = 0 )
  THEN
    INSERT INTO affiliate_cash_balance ( affiliate_id, balance )
      VALUES ( affiliate_id, 0 );
  END IF;

  IF ( error_condition = 1 )
  THEN
    ROLLBACK;
    SET result = 0;
  ELSE
    COMMIT;
  END IF;

  IF ( error_condition = 0 )
  THEN
    START TRANSACTION;

    SET people_id = getAffiliatePeopleID( affiliate_id );
    SET receipt_id = insertReceipt( 'Affiliate Payment Received', people_id,
                                  0, '', 0, amount, '' );

    SELECT balance INTO affiliate_balance
      FROM affiliate_cash_balance
      WHERE affiliate_id = affiliate_id FOR UPDATE;
    SELECT balance INTO cash_balance
      FROM cash_balance
      WHERE id = 1 FOR UPDATE;

    SET affiliate_balance = affiliate_balance + amount;
    INSERT INTO affiliate_cash_transactions ( affiliate_id, receipt_id,
                                              amount, balance )
      VALUES ( affiliate_id, receipt_id, amount, affiliate_balance );
    UPDATE affiliate_cash_balance
      SET balance = affiliate_balance
      WHERE affiliate_id = affiliate_id;

    SET cash_balance = cash_balance - amount;
    INSERT INTO cash_transactions ( receipt_id, amount, balance )
      VALUES ( receipt_id, -amount, cash_balance );
    UPDATE cash_balance SET balance = cash_balance WHERE id = 1;

    IF ( error_condition = 1 )
    THEN
      ROLLBACK;
      SET result = '0';
    ELSE
      COMMIT;
    END IF;
  END IF;
END$$

DROP PROCEDURE IF EXISTS `accounting`.`changePromoCredit`$$
CREATE PROCEDURE `accounting`.`changePromoCredit`(
  IN agent_id INT UNSIGNED,
  IN new_available_amount DECIMAL(10,2),
  OUT result INT )
BEGIN
  DECLARE current_balance_available DECIMAL(10,2);
  DECLARE current_balance DECIMAL(10,2);
  DECLARE difference DECIMAL(10,2);
  DECLARE error_condition INT;

  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    SET error_condition = 1;

  SET result = 1;
  SET error_condition = 0;

  START TRANSACTION;

  SELECT balance, balance_available INTO current_balance, current_balance_available
    FROM agent_promo_balance
    WHERE agent_id = agent_id FOR UPDATE;

  IF ( current_balance_available > new_available_amount )
  THEN
    SET difference = current_balance_available - new_available_amount;
    IF ( difference < 0 )
    THEN
      SET difference = 0;
    END IF;

    CALL addPromoCredit( agent_id, difference, 0, @result );
    CALL removePromoCredit( agent_id, difference, @result );
  ELSE
    IF ( current_balance < new_available_amount )
    THEN
      SET new_available_amount = current_balance;
    END IF;

    CALL addPromoCredit( agent_id, 0.00, new_available_amount, @result );
  END IF;

  IF ( error_condition = 1 )
  THEN
    ROLLBACK;
    SET result = '0';
  ELSE
    COMMIT;
  END IF;
END$$

DROP PROCEDURE IF EXISTS `accounting`.`leadPurchase`$$
CREATE PROCEDURE `accounting`.`leadPurchase`(
  IN lead_id INT unsigned,
  IN affiliate_id_given INT unsigned,
  IN amount DECIMAL(10,2),
  OUT result INT )
BEGIN
  DECLARE receipt_id INT UNSIGNED;
  DECLARE people_id INT UNSIGNED;
  DECLARE affiliate_cash_balance DECIMAL(10,2);
  DECLARE cash_balance DECIMAL(12,2);
  DECLARE count INT;
  DECLARE error_condition INT;

  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    SET error_condition = 1;

  SET result = 1;
  SET error_condition = 0;

  START TRANSACTION;
  SELECT count( affiliate_id ) INTO count
    FROM affiliate_cash_balance
    WHERE affiliate_id = affiliate_id_given FOR UPDATE;

  IF ( count = 0 )
  THEN
    INSERT INTO affiliate_cash_balance ( affiliate_id, balance )
      VALUES ( affiliate_id_given, 0 );
  END IF;

  IF ( error_condition = 1 )
  THEN
    ROLLBACK;
    SET result = '0';
  ELSE
    COMMIT;
  END IF;

  IF ( error_condition = 0 )
  THEN
    START TRANSACTION;

    SELECT balance INTO affiliate_cash_balance
      FROM affiliate_cash_balance
      WHERE affiliate_id = affiliate_id_given FOR UPDATE;
    SELECT balance INTO cash_balance
      FROM cash_balance WHERE id = 1 FOR UPDATE;

    SET people_id = getAffiliatePeopleID( affiliate_id_given );
    SET receipt_id = insertReceipt( 'Lead Purchase', people_id, 0, '', lead_id, amount, '' );
    SET affiliate_cash_balance = affiliate_cash_balance + amount;
    SET cash_balance = cash_balance - amount;

    INSERT INTO affiliate_cash_transactions ( affiliate_id, receipt_id,
                                              amount, balance )
      VALUES ( affiliate_id_given, receipt_id, amount, affiliate_cash_balance );

    INSERT INTO cash_transactions( receipt_id, amount, balance )
      VALUES ( receipt_id, -amount, cash_balance );

    UPDATE affiliate_cash_balance
      SET balance = affiliate_cash_balance
      WHERE affiliate_id = affiliate_id_given;
    UPDATE cash_balance SET balance = cash_balance WHERE id = 1;

    IF ( error_condition = 1 )
    THEN
      ROLLBACK;
      SET result = '0';
    ELSE
      COMMIT;
    END IF;
  END IF;
END$$

DROP PROCEDURE IF EXISTS `accounting`.`leadRefund`$$
CREATE PROCEDURE `accounting`.`leadRefund`(
  IN lead_id_given INT unsigned,
  IN agent_id_given INT unsigned,
  IN affiliate_id_given INT unsigned,
  OUT result INT )
BEGIN
  DECLARE receipt_id INT UNSIGNED;
  DECLARE agent_people_id INT UNSIGNED;
  DECLARE affiliate_people_id INT UNSIGNED;
  DECLARE agent_cash_balance DECIMAL(10,2);
  DECLARE agent_promo_balance DECIMAL(10,2);
  DECLARE agent_promo_balance_available DECIMAL(10,2);
  DECLARE promo_balance DECIMAL(12,2);
  DECLARE promo_balance_available DECIMAL(12,2);
  DECLARE affiliate_cash_balance DECIMAL(12,2);
  DECLARE cash_balance DECIMAL(12,2);
  DECLARE amount DECIMAL(10,2);
  DECLARE count INT;
  DECLARE promo_sale INT;
  DECLARE receipt_description VARCHAR(64);
  DECLARE error_condition INT;

  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    SET error_condition = 1;

  SET result = 1;
  SET error_condition = 0;
  SET promo_sale = 0;

  SELECT count(r.id) INTO count
    FROM receipts r, receipt_types rt
    WHERE r.lead_id = lead_id_given
      AND r.people_id_debited = getPeopleID( agent_id_given )
      AND rt.id = r.receipt_type_id
      AND rt.type = 'Lead Sale -- Promo';

  IF ( count > 0 )
  THEN
    SET promo_sale = 1;
  ELSE
    SELECT count(r.id) INTO count
    FROM receipts r, receipt_types rt
    WHERE r.lead_id = lead_id_given
      AND r.people_id_debited = getPeopleID( agent_id_given )
      AND rt.id = r.receipt_type_id
      AND rt.type = 'Lead Sale -- Cash';

    IF ( count = 0 )
    THEN
      SET error_condition = 1;
      SET result = 0;
    END IF;
  END IF;

  IF ( error_condition = 0 )
  THEN
    START TRANSACTION;

    SET agent_people_id = getPeopleID( agent_id_given );
    SET affiliate_people_id = getAffiliatePeopleID( affiliate_id_given );

    IF ( promo_sale = 1 )
    THEN
      SELECT balance, balance_available
        INTO agent_promo_balance, agent_promo_balance_available
        FROM agent_promo_balance
        WHERE agent_id = agent_id_given FOR UPDATE;
      SELECT balance, balance_available
        INTO promo_balance, promo_balance_available
        FROM promo_balance
        WHERE id = 1 FOR UPDATE;
      SELECT balance INTO affiliate_cash_balance
        FROM affiliate_cash_balance
        WHERE affiliate_id = affiliate_id_given FOR UPDATE;
      SELECT balance INTO cash_balance
        FROM cash_balance
        WHERE id = 1 FOR UPDATE;

	  IF ( ISNULL( agent_promo_balance ) )
	  THEN
	    SET agent_promo_balance = 0;
	  END IF;

  	  IF ( ISNULL( agent_promo_balance_available ) )
  	  THEN
  	    SET agent_promo_balance_available = 0;
  	  END IF;
  	  
  	  IF ( ISNULL( promo_balance ) )
  	  THEN
  	    SET promo_balance = 0;
  	  END IF;
  	  
  	  IF ( ISNULL( promo_balance_available ) )
  	  THEN
  	    SET promo_balance_available = 0;
  	  END IF;
  	  
  	  IF ( ISNULL( affiliate_cash_balance ) )
  	  THEN
  	    SET affiliate_cash_balance = 0;
  	  END IF;
  	  
  	  IF ( ISNULL( cash_balance ) )
  	  THEN
  	    SET cash_balance = 0;
  	  END IF;
      	
      SELECT r.amount INTO amount
        FROM receipts r, receipt_types rt
        WHERE r.lead_id = lead_id_given 
          AND r.people_id_credited = 0
          AND r.people_id_debited = agent_people_id
          AND r.receipt_type_id = rt.id
          AND rt.type = 'Lead Sale -- Promo';
          	
      SET receipt_id = insertReceipt( 'Lead Refund -- Promo', agent_people_id, 0,
                                      '', lead_id_given, amount, '' );
      SET agent_promo_balance = agent_promo_balance + amount;
      SET agent_promo_balance_available = agent_promo_balance_available + amount;
      SET promo_balance = promo_balance - amount;
      SET promo_balance_available = promo_balance_available - amount;

      INSERT INTO agent_promo_transactions ( agent_id, receipt_id, amount,
                                             amount_available, balance,
                                             balance_available )
        VALUES ( agent_id_given, receipt_id, amount, amount, agent_promo_balance,
                 agent_promo_balance_available );
	  UPDATE agent_promo_balance SET balance = agent_promo_balance, balance_available = agent_promo_balance_available
	  	WHERE agent_id = agent_id_given;

      INSERT INTO promo_transactions ( receipt_id, amount, amount_available,
                                       balance, balance_available )
        VALUES ( receipt_id, -amount, -amount, promo_balance, promo_balance_available );
      UPDATE promo_balance
        SET balance = promo_balance,
            balance_available = promo_balance_available
        WHERE id = 1;
    ELSE
      SELECT r.amount INTO amount
        FROM receipts r, receipt_types rt
        WHERE r.lead_id = lead_id_given 
          AND r.people_id_credited = agent_people_id
          AND r.people_id_debited = 0
          AND r.receipt_type_id = rt.id
          AND rt.type = 'Add Promo Credit -- Lead Purchase';

      SELECT balance, balance_available INTO agent_promo_balance, agent_promo_balance_available 
        FROM agent_promo_balance WHERE agent_id = agent_id_given FOR UPDATE;
      SELECT balance, balance_available INTO promo_balance, promo_balance_available
        FROM promo_balance WHERE id = 1;
        
      IF ( ISNULL( agent_promo_balance ) )
	  THEN
	    SET agent_promo_balance = 0;
	  END IF;

  	  IF ( ISNULL( agent_promo_balance_available ) )
  	  THEN
  	    SET agent_promo_balance_available = 0;
  	  END IF;
  	  
  	  IF ( ISNULL( promo_balance ) )
  	  THEN
  	    SET promo_balance = 0;
  	  END IF;
  	  
  	  IF ( ISNULL( promo_balance_available ) )
  	  THEN
  	    SET promo_balance_available = 0;
  	  END IF;
      SET agent_promo_balance_available = agent_promo_balance_available - amount;
      
      IF ( agent_promo_balance_available < 0 )
      THEN
        SET agent_promo_balance_available = 0;
      END IF;
      
      SET promo_balance_available = promo_balance_available + amount;
      SET receipt_id = insertReceipt( 'Delete Promo Credit -- Lead Refund', agent_people_id, 0, '', lead_id_given, amount, '' );
      	
      INSERT INTO agent_promo_transactions ( agent_id, receipt_id, amount, amount_available, balance, balance_available )
  	    VALUES ( agent_id_given, receipt_id, 0, -amount, agent_promo_balance, agent_promo_balance_available );
  	  INSERT INTO promo_transactions ( receipt_id, amount, amount_available, balance, balance_available )
  	  	VALUES ( receipt_id, 0, amount, promo_balance, promo_balance_available );
  	  UPDATE agent_promo_balance SET balance = agent_promo_balance, balance_available = agent_promo_balance_available
  	  	WHERE agent_id = agent_id_given;
  	  UPDATE promo_balance SET balance = promo_balance, balance_available = promo_balance_available
  	  	WHERE id = 1;

      SELECT balance INTO agent_cash_balance FROM agent_cash_balance WHERE agent_id = agent_id_given FOR UPDATE;
      SELECT balance INTO cash_balance FROM cash_balance WHERE id = 1 FOR UPDATE;
      SELECT balance INTO affiliate_cash_balance
        FROM affiliate_cash_balance
        WHERE affiliate_id = affiliate_id_given FOR UPDATE;

      SELECT r.amount INTO amount
        FROM receipts r, receipt_types rt
        WHERE r.lead_id = lead_id_given 
          AND r.people_id_credited = 0
          AND r.people_id_debited = agent_people_id
          AND r.receipt_type_id = rt.id
          AND rt.type = 'Lead Sale -- Cash';

      SET receipt_id = insertReceipt( 'Lead Refund -- Cash', agent_people_id, 0,
                                      '', lead_id_given, amount, '' );
      SET agent_cash_balance = agent_cash_balance + amount;
      SET cash_balance = cash_balance - amount;

      INSERT INTO agent_cash_transactions ( agent_id, receipt_id, amount, balance )
        VALUES ( agent_id_given, receipt_id, amount, agent_cash_balance );
      UPDATE agent_cash_balance SET balance = agent_cash_balance WHERE agent_id = agent_id_given;

      INSERT INTO cash_transactions ( receipt_id, amount, balance )
        VALUES ( receipt_id, -amount, balance );
      UPDATE cash_balance SET balance = cash_balance WHERE id = 1;
     	
    END IF;
    
    SELECT r.amount INTO amount
      FROM receipts r, receipt_types rt
      WHERE r.lead_id = lead_id_given 
        AND r.people_id_credited = affiliate_people_id
        AND r.people_id_debited = 0
        AND r.receipt_type_id = rt.id
        AND rt.type = 'Lead Purchase';
        
    SET receipt_id = insertReceipt( 'Lead Return', 0, affiliate_people_id,
                                    '', lead_id_given, amount, '' );
    SET affiliate_cash_balance = affiliate_cash_balance - amount;
    INSERT INTO affiliate_cash_transactions ( affiliate_id, receipt_id, amount, balance )
      VALUES ( affiliate_id_given, receipt_id, -amount, affiliate_cash_balance );

    SET cash_balance = cash_balance + amount;
    INSERT INTO cash_transactions ( receipt_id, amount, balance )
      VALUES ( receipt_id, amount, cash_balance );

    UPDATE affiliate_cash_balance
      SET balance = affiliate_cash_balance
      WHERE affiliate_id = affiliate_id_given;
    UPDATE cash_balance
      SET balance = cash_balance
      WHERE id = 1;

    IF ( error_condition = 1 )
    THEN
      ROLLBACK;
      SET result = '0';
    ELSE
      COMMIT;
    END IF;
  END IF;
END$$

DROP PROCEDURE IF EXISTS `accounting`.`leadSale`$$
CREATE PROCEDURE `accounting`.`leadSale`(
  IN lead_id INT unsigned,
  IN agent_id_given INT unsigned,
  IN amount DECIMAL(10,2),
  OUT result INT )
BEGIN
  DECLARE receipt_id INT UNSIGNED;
  DECLARE people_id INT UNSIGNED;
  DECLARE agent_cash_balance DECIMAL(10,2);
  DECLARE agent_promo_balance DECIMAL(10,2);
  DECLARE agent_promo_balance_available DECIMAL(10,2);
  DECLARE promo_balance DECIMAL(12,2);
  DECLARE promo_balance_available DECIMAL(12,2);
  DECLARE cash_balance DECIMAL(12,2);
  DECLARE promo_multiplier DECIMAL(5,2);
  DECLARE additional_promo_credit DECIMAL(6,2);
  DECLARE count INT;
  DECLARE promo_sale INT;
  DECLARE receipt_description VARCHAR(64);
  DECLARE error_condition INT;

  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    SET error_condition = 1;

  SET AUTOCOMMIT = 0;
  SET result = 1;
  SET error_condition = 0;
  SET promo_sale = 0;

  START TRANSACTION;
  SELECT count( agent_id ) INTO count
    FROM agent_cash_balance
    WHERE agent_id = agent_id_given FOR UPDATE;

  IF ( count = 0 )
  THEN
    INSERT INTO agent_cash_balance ( agent_id, balance ) VALUES ( agent_id_given, 0 );
  END IF;

  SELECT count( agent_id ) INTO count
    FROM agent_promo_balance
    WHERE agent_id = agent_id_given FOR UPDATE;
  IF ( count = 0 )
  THEN
    INSERT INTO agent_promo_balance ( agent_id, balance, balance_available )
      VALUES ( agent_id_given, 0, 0 );
  END IF;

  IF ( error_condition = 1 )
  THEN
    ROLLBACK;
    SET result = '0';
  ELSE
    COMMIT;
  END IF;

  IF ( error_condition = 0 )
  THEN
    START TRANSACTION;
    SELECT balance, balance_available
      INTO agent_promo_balance, agent_promo_balance_available
      FROM agent_promo_balance
      WHERE agent_id = agent_id_given FOR UPDATE;
    SELECT balance, balance_available INTO promo_balance, promo_balance_available
      FROM promo_balance
       WHERE id = 1 FOR UPDATE;

    IF ( agent_promo_balance_available > amount )
    THEN
      SET promo_sale = 1;
      SET receipt_description = 'Lead Sale -- Promo';
    ELSE
      SET receipt_description = 'Lead Sale -- Cash';
      SELECT balance INTO agent_cash_balance
        FROM agent_cash_balance
        WHERE agent_id = agent_id_given FOR UPDATE;
      SELECT balance INTO cash_balance
        FROM cash_balance
        WHERE id = 1 FOR UPDATE;
    END IF;

    SET people_id = getPeopleID( agent_id_given );
    SET receipt_id = insertReceipt( receipt_description, 0, people_id, '',
                                    lead_id, amount, '' );
    IF ( promo_sale = 1 )
    THEN
      SET agent_promo_balance_available = agent_promo_balance_available - amount;
      SET agent_promo_balance = agent_promo_balance - amount;
      SET promo_balance_available = promo_balance_available + amount;
      SET promo_balance = promo_balance;

      INSERT INTO agent_promo_transactions ( agent_id, receipt_id, amount,
                                             amount_available, balance,
                                             balance_available )
        VALUES ( agent_id_given, receipt_id, -amount, -amount, agent_promo_balance,
                 agent_promo_balance_available );
      INSERT INTO promo_transactions ( receipt_id, amount, amount_available,
                                       balance, balance_available )
        VALUES ( receipt_id, amount, amount, promo_balance,
                 promo_balance_available );

      UPDATE agent_promo_balance
        SET balance = agent_promo_balance,
            balance_available = agent_promo_balance_available
        WHERE agent_id = agent_id_given;
      UPDATE promo_balance
        SET balance = promo_balance,
            balance_available = promo_balance_available
        WHERE id = 1;
    ELSE
      SET agent_cash_balance = agent_cash_balance - amount;
      SET cash_balance = cash_balance + amount;

      INSERT INTO agent_cash_transactions ( agent_id, receipt_id, amount, balance )
        VALUES ( agent_id_given, receipt_id, -amount, agent_cash_balance );
      INSERT INTO cash_transactions ( receipt_id, amount, balance )
        VALUES ( receipt_id, amount, cash_balance );

      UPDATE agent_cash_balance
        SET balance = agent_cash_balance
        WHERE agent_id = agent_id_given;
      UPDATE cash_balance SET balance = cash_balance WHERE id = 1;

      SELECT multiplier INTO promo_multiplier
        FROM promo_payout_multiplier WHERE agent_id = agent_id_given;

      IF ( ISNULL( promo_multiplier ) )
      THEN
        SET promo_multiplier = 0.1;
      END IF;

      SELECT FORMAT( amount * promo_multiplier, 2 ) INTO additional_promo_credit;

      IF ( agent_promo_balance >= additional_promo_credit )
      THEN
        SET receipt_id = insertReceipt( 'Add Promo Credit -- Lead Purchase',
                                        people_id, 0, '', lead_id,
                                        additional_promo_credit, '' );

        SELECT balance_available INTO agent_promo_balance_available
          FROM agent_promo_balance
          WHERE agent_id = agent_id_given;

        SET agent_promo_balance_available =
          agent_promo_balance_available + additional_promo_credit;
        SET promo_balance_available =
          promo_balance_available - additional_promo_credit;

        INSERT INTO agent_promo_transactions ( agent_id, receipt_id, amount,
                                               amount_available, balance,
                                               balance_available )
          VALUES ( agent_id_given, receipt_id, 0, additional_promo_credit,
                   agent_promo_balance, agent_promo_balance_available );

        INSERT INTO promo_transactions ( receipt_id, amount, amount_available,
                                         balance, balance_available )
          VALUES ( receipt_id, 0, -additional_promo_credit, promo_balance,
                   promo_balance_available );

        UPDATE agent_promo_balance
          SET balance = agent_promo_balance,
              balance_available = agent_promo_balance_available
          WHERE agent_id = agent_id_given;
        UPDATE promo_balance
          SET balance = promo_balance,
              balance_available = promo_balance_available
          WHERE id = 1;
      END IF;
    END IF;
    IF ( error_condition = 1 )
    THEN
      ROLLBACK;
      SET result = '0';
    ELSE
      COMMIT;
    END IF;
  END IF;
END$$

DELIMITER ;
