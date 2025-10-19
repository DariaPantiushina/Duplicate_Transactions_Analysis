DROP TABLE IF EXISTS fact.fact_transactions;
CREATE TABLE fact.fact_transactions AS
SELECT
    t.txn_id,
    t.user_id,
    t.provider,
    t.txn_date,
    t.amount,
    t.currency,
    t.status
FROM stg.stg_transactions t;

DROP TABLE IF EXISTS fact.fact_chargebacks;
CREATE TABLE fact.fact_chargebacks AS
SELECT
    c.cb_id,
    c.txn_id,
    c.cb_date,
    c.reason
FROM stg.stg_chargebacks c;