-- marts_provider_metrics
DROP TABLE IF EXISTS marts.marts_provider_metrics;
CREATE TABLE marts.marts_provider_metrics AS
WITH suspicious_duplicates AS (
    SELECT DISTINCT 
        t1.txn_id,
        t1.provider
    FROM fact.fact_transactions t1
    JOIN fact.fact_transactions t2 ON t1.user_id = t2.user_id
        							AND t1.amount = t2.amount
        							AND t1.currency = t2.currency
        							AND t1.txn_id < t2.txn_id
        							AND t2.txn_date BETWEEN t1.txn_date AND t1.txn_date + INTERVAL '5 minute'
    WHERE t1.status = 'SUCCESS' AND t2.status = 'SUCCESS'
),
provider_success AS (
    SELECT
        provider,
        COUNT(DISTINCT txn_id) AS total_success_txns
    FROM fact.fact_transactions
    WHERE status = 'SUCCESS'
    GROUP BY provider
),
provider_suspicious_duplicates AS (
    SELECT
        s.provider,
        COUNT(DISTINCT s.txn_id) AS duplicate_txns
    FROM suspicious_duplicates s
    GROUP BY s.provider
),
merged_suspicious AS (
    SELECT
        ps.provider,
        ps.total_success_txns,
        COALESCE(psu.duplicate_txns, 0) AS duplicate_txns,
        ROUND(
            COALESCE(psu.duplicate_txns, 0)::numeric * 100.0 
            / NULLIF(ps.total_success_txns, 0),
            4
        ) AS duplicate_share
    FROM provider_success ps
    LEFT JOIN provider_suspicious_duplicates psu ON ps.provider = psu.provider
),
provider_chargebacks AS (
    SELECT
        f.provider,
        COUNT(DISTINCT c.cb_id) AS chargebacks,
        COUNT(DISTINCT f.txn_id) FILTER (WHERE f.status = 'SUCCESS') AS total_success_txns_for_cb,
        ROUND(
            COUNT(DISTINCT c.cb_id)::numeric * 100.0
            / NULLIF(COUNT(DISTINCT f.txn_id) FILTER (WHERE f.status = 'SUCCESS'), 0),
            4
        ) AS chargeback_rate
    FROM fact.fact_transactions f
    LEFT JOIN fact.fact_chargebacks c ON f.txn_id = c.txn_id
    GROUP BY f.provider
)
SELECT
    ms.provider,
    ms.total_success_txns,
    ms.duplicate_txns,
    ms.duplicate_share,
    COALESCE(c.chargebacks, 0) AS chargebacks,
    COALESCE(c.chargeback_rate, 0) AS chargeback_rate
FROM merged_suspicious ms
LEFT JOIN provider_chargebacks c ON ms.provider = c.provider
ORDER BY chargeback_rate DESC;

-- marts_user_activity
DROP TABLE IF EXISTS marts.marts_user_activity;
CREATE TABLE marts.marts_user_activity AS
SELECT
    f.user_id,
    COUNT(DISTINCT f.txn_id) AS total_txns,
    SUM(f.amount) AS total_amount,
    COUNT(DISTINCT c.cb_id) AS total_chargebacks,
    ROUND(COUNT(DISTINCT c.cb_id)::numeric / NULLIF(COUNT(DISTINCT f.txn_id), 0), 4) AS chargeback_rate
FROM fact.fact_transactions f
LEFT JOIN fact.fact_chargebacks c USING (txn_id)
GROUP BY f.user_id
ORDER BY total_amount DESC;