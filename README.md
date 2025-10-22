# Duplicate Transactions Analysis

**Business context**: Recently, some clients have reported cases of double charges - duplicate transactions appearing in their card statements after making payments.

**Key questions from management**:

1) How widespread is the issue?

2) Is the root cause a system bug or a malfunction on the side of specific banks or payment providers?

3) What impact does this have on the chargeback rate (refunds triggered by customer complaints)?

## Data Mart Schema

The architecture of the data mart includes **four layers**:

1. stg_ (**Staging**)

- **stg_transactions**(txn_id, user_id, amount, currency, txn_date, status, provider);

- **stg_chargebacks**(cb_id, txn_id, cb_date, reason)

Light data cleaning was applied during staging: data types were standardized, currencies converted to uppercase, explicit duplicates removed, and only valid transactions (positive amount, non-null currency, relevant statuses) were retained. Chargeback data was also cleaned for null IDs and trimmed text fields.

2. dim_ (**Dimensions**)

- **dim_user**(user_id);

- **dim_provider**(provider);

- **dim_date**(date_value, year, month, day, weekday)

Contains reference tables for consistent dimension data.

3. fact_ (**Facts**)

- **fact_transactions**(txn_id, user_id, provider, txn_date, amount, currency, status);

- **fact_chargebacks**(cb_id, txn_id, cb_date, reason)

Contains fact tables with transactional and chargeback data.

4. marts_ (**Analytics Marts**)

- **marts_provider_metrics**(provider, total_success_txns, duplicate_txns, duplicate_share, chargebacks, chargeback_rate);

- **marts_user_activity**(user_id, total_txns, total_amount, total_chargebacks, chargeback_rate);

- **marts_transactions_trend**(provider, txn_day, total_success_txns, duplicate_txns, duplicate_share)

Contains aggregated summary tables for reporting and visualization.
