CREATE TABLE stg.transactions (
    txn_id VARCHAR(20),
    user_id VARCHAR(20),
    amount NUMERIC(10,2),
    currency CHAR(3),
    txn_date TIMESTAMP,
    status VARCHAR(20),
    provider VARCHAR(50)
);

CREATE TABLE stg.chargebacks (
    cb_id VARCHAR(20),
    txn_id VARCHAR(20),
    cb_date TIMESTAMP,
    reason VARCHAR(100)
);

--############################################################--

DROP TABLE IF EXISTS stg.stg_transactions;
CREATE TABLE stg.stg_transactions AS
SELECT DISTINCT
    txn_id,
    user_id,
    CAST(amount AS NUMERIC(10,2)) AS amount,
    UPPER(currency) AS currency,
    CAST(txn_date AS TIMESTAMP) AS txn_date,
    status,
    provider
FROM transactions
WHERE status IN ('SUCCESS', 'FAILED', 'REFUNDED')
  AND amount > 0
  AND currency IS NOT NULL;

DROP TABLE IF EXISTS stg.stg_chargebacks;
CREATE TABLE stg.stg_chargebacks AS
SELECT DISTINCT
    cb_id,
    txn_id,
    CAST(cb_date AS TIMESTAMP) AS cb_date,
    TRIM(reason) AS reason
FROM chargebacks
WHERE cb_id IS NOT NULL AND txn_id IS NOT NULL;