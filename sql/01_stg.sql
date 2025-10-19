CREATE TABLE stg.stg_transactions (
    txn_id VARCHAR(20),
    user_id VARCHAR(20),
    amount NUMERIC(10,2),
    currency CHAR(3),
    txn_date TIMESTAMP,
    status VARCHAR(20),
    provider VARCHAR(50),
    load_dttm TIMESTAMP DEFAULT now()
);

CREATE TABLE stg.stg_chargebacks (
    cb_id VARCHAR(20),
    txn_id VARCHAR(20),
    cb_date TIMESTAMP,
    reason VARCHAR(100),
    load_dttm TIMESTAMP DEFAULT now()
);