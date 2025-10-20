-- 1) Detect suspicious duplicate transactions (same user_id, same amount, within 5 minutes)
SELECT
	  t1.user_id,
	  t1.amount,
	  t1.currency,
	  t1.txn_date AS txn_time_1,
	  t2.txn_date AS txn_time_2,
	  t1.provider
FROM fact.fact_transactions t1
JOIN fact.fact_transactions t2 ON t1.user_id = t2.user_id
                               AND t1.amount = t2.amount
                               AND t1.currency = t2.currency
                               AND t1.txn_id < t2.txn_id
                               AND t2.txn_date BETWEEN t1.txn_date AND t1.txn_date + INTERVAL '5 minute'
WHERE t1.status = 'SUCCESS' AND t2.status = 'SUCCESS';

-- 2) Suspicious duplicates share
WITH suspicious AS (
         SELECT DISTINCT 
						t1.txn_id
         FROM fact.fact_transactions t1
         JOIN fact.fact_transactions t2 ON t1.user_id = t2.user_id
                                        AND t1.amount = t2.amount
                                        AND t1.currency = t2.currency
                                        AND t1.txn_id < t2.txn_id
                                        AND t2.txn_date BETWEEN t1.txn_date AND t1.txn_date + INTERVAL '5 minute'
          WHERE t1.status = 'SUCCESS' AND t2.status = 'SUCCESS'
)
SELECT 
      COUNT(*) * 100.0 
				/ (SELECT COUNT(*) FROM fact.fact_transactions WHERE status = 'SUCCESS') AS pct_duplicates
FROM suspicious;

-- 3) Provider-wise comparison
WITH suspicious AS (
         SELECT 
			   t1.txn_id, 
               t1.provider
         FROM fact.fact_transactions t1
         JOIN fact.fact_transactions t2 ON t1.user_id = t2.user_id
                                        AND t1.amount = t2.amount
                                        AND t1.currency = t2.currency
                                        AND t1.txn_id < t2.txn_id
                                        AND t2.txn_date BETWEEN t1.txn_date AND t1.txn_date + INTERVAL '5 minute'
         WHERE t1.status = 'SUCCESS' AND t2.status = 'SUCCESS'
)
SELECT 
	  provider,
      COUNT(*) AS dup_count,
      COUNT(*) * 100.0 
				/ (SELECT COUNT(*) FROM fact.fact_transactions WHERE status = 'SUCCESS') AS dup_pct 
FROM suspicious
GROUP BY provider
ORDER BY dup_pct DESC;

-- 4) Duplicate transaction rate by provider
WITH suspicious AS (
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
provider_stats AS (
    SELECT
        provider,
        COUNT(DISTINCT txn_id) AS total_success_txns
    FROM fact.fact_transactions
    WHERE status = 'SUCCESS'
    GROUP BY provider
),
provider_dup AS (
    SELECT
        s.provider,
        COUNT(DISTINCT s.txn_id) AS duplicate_txns
    FROM suspicious s
    GROUP BY s.provider
),
merged AS (
    SELECT
        ps.provider,
        ps.total_success_txns,
        COALESCE(pd.duplicate_txns, 0) AS duplicate_txns,
        COALESCE(pd.duplicate_txns, 0) * 100.0 / ps.total_success_txns AS pct_duplicates
    FROM provider_stats ps
    LEFT JOIN provider_dup pd ON ps.provider = pd.provider
),
avg_dup AS (
    SELECT 
			AVG(pct_duplicates) AS avg_pct_duplicates 
	FROM merged
)
SELECT
    m.provider,
    m.total_success_txns,
    m.duplicate_txns,
    m.pct_duplicates,
    a.avg_pct_duplicates,
    CASE
        WHEN m.pct_duplicates > a.avg_pct_duplicates THEN 'above average'
        ELSE 'below or equal to average'
    END AS pct_duplicates_category
FROM merged m
CROSS JOIN avg_dup a
ORDER BY m.pct_duplicates DESC;

-- 5) Analysis of chargeback risk associated with duplicate transactions
WITH suspicious AS (
  			SELECT DISTINCT 
							t1.txn_id 
  			FROM fact.fact_transactions t1
  			JOIN fact.fact_transactions t2 ON t1.user_id = t2.user_id 
   											AND t1.amount = t2.amount
											AND t1.currency = t2.currency
   											AND t1.txn_id < t2.txn_id
   											AND t2.txn_date BETWEEN t1.txn_date AND t1.txn_date + INTERVAL '5 minute'
  			WHERE t1.status = 'SUCCESS' AND t2.status = 'SUCCESS'
)
SELECT 
  	CASE
		WHEN s.txn_id IS NOT NULL 
		THEN 'duplicate' ELSE 'non_duplicate' 
	END AS txn_type,
  	COUNT(DISTINCT t.txn_id) AS total_txns,
  	COUNT(DISTINCT cb.cb_id) AS total_chargebacks,
  	COUNT(DISTINCT cb.cb_id) * 100.0 
							/ COUNT(DISTINCT t.txn_id) AS chargeback_rate 
FROM fact.fact_transactions t
LEFT JOIN suspicious s ON t.txn_id = s.txn_id
LEFT JOIN fact.fact_chargebacks cb ON t.txn_id = cb.txn_id
GROUP BY 1
ORDER BY chargeback_rate DESC;