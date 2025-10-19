-- marts_provider_metrics
DROP TABLE IF EXISTS marts.marts_provider_metrics;
CREATE TABLE marts.marts_provider_metrics AS
WITH duplicates AS (
    SELECT
        user_id,
        amount,
        provider,
        DATE_TRUNC('second', txn_date) AS txn_time,
        COUNT(*) AS txn_count
    FROM fact.fact_transactions
    GROUP BY 1,2,3,4
    HAVING COUNT(*) > 1
)
SELECT
    f.provider,
    COUNT(DISTINCT f.txn_id) AS total_txns,
    COALESCE(SUM(CASE 
					WHEN d.txn_count > 1 THEN 1 ELSE 0 
				END), 0) AS duplicate_txns,  
    ROUND(SUM(CASE 
				WHEN d.txn_count > 1 THEN 1 ELSE 0 
			END)::numeric / COUNT(DISTINCT f.txn_id), 4) AS duplicate_share, 
    COUNT(DISTINCT c.cb_id) AS chargebacks,
    ROUND(COUNT(DISTINCT c.cb_id)::numeric / COUNT(DISTINCT f.txn_id), 4) AS chargeback_rate
FROM fact.fact_transactions f
LEFT JOIN duplicates d USING (user_id, amount, provider)
LEFT JOIN fact.fact_chargebacks c USING (txn_id)
GROUP BY f.provider
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