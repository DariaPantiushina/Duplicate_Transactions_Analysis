-- dim_user
DROP TABLE IF EXISTS dim.dim_user;
CREATE TABLE dim.dim_user AS
SELECT DISTINCT user_id
FROM stg.stg_transactions
WHERE user_id IS NOT NULL;

-- dim_provider
DROP TABLE IF EXISTS dim.dim_provider;
CREATE TABLE dim.dim_provider AS
SELECT DISTINCT provider
FROM stg.stg_transactions
WHERE provider IS NOT NULL;

-- dim_date
DROP TABLE IF EXISTS dim.dim_date;
CREATE TABLE dim.dim_date AS
WITH dates AS (
    SELECT generate_series(
        (SELECT MIN(txn_date)::date FROM stg.stg_transactions),
        (SELECT MAX(txn_date)::date FROM stg.stg_transactions),
        interval '1 day'
    )::date AS date_value
)
SELECT
    date_value,
    EXTRACT(year FROM date_value)::int AS year,
    EXTRACT(month FROM date_value)::int AS month,
    EXTRACT(day FROM date_value)::int AS day,
    EXTRACT(dow FROM date_value)::int AS weekday
FROM dates;