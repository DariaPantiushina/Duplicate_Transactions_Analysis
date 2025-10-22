# Duplicate Transactions Analysis

**Business context**: During the week of October 1–7, 2024 some clients have reported cases of double charges - duplicate transactions appearing in their card statements after making payments.

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

## SQL-Analysis

1) Detect suspicious duplicate transactions (same user_id, same amount, within 5 minutes);

2) Suspicious duplicates share;

3) Provider-level analysis to identify duplication patterns (calculated duplicate transaction count and duplicate transaction percentage per provider);

4) Provider duplicate transaction benchmarking;

5) Analysis of chargeback risk associated with duplicate transactions

## Creating a Dashboard in Tableau 

["Dashboard"](tableau/dashboard.pdf), also available via public link: https://public.tableau.com/views/Duplicate_Transactions_Analysis/Dashboard1?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link:

1) **Trend line** (Weekly Duplicate Transactions) visualizes daily duplicate volumes, showing short-term spikes (notably on October 2), followed by stabilization;

2) **Horizontal иars** (Duplicate Share & Chargeback Rate by Provider). These bar charts compare providers side by side: 1) Duplicate share - EuroPay leads with 1.76%, followed by QuickPay and FinFlow; 2) Chargeback rate - QuickPay (3.45%) and FinFlow (3.28%) show the highest rates;

3) **Histogram** (Chargeback Rate Distribution) shows how users cluster around lower chargeback rates (< 0.5%), with a few high-risk outliers;

4) **Bubble chart** (Duplicate Share vs. Chargeback Rate) - the scatter plot correlates two risk metrics per provider, with bubble size representing total transaction volume. QuickPay’s bubble stands out for both higher duplication and chargebacks;

5) **Table** (Detailed Provider Metrics) consolidates all KPIs (total success transactions, duplicate counts, and chargebacks), allowing precise quantitative comparison across providers

## Findings & Business Insights & Recommendations

1) The share of duplicate transactions is above average for certain providers (e.g., EuroPay), indicating a system-level bug rather than user error;

2) Transactions involving duplicates show a higher chargeback rate compared to non-duplicate transactions (4.29% vs. 2.53%), indicating a critical user-impact issue;

3) While the overall number of duplicates is relatively low, their impact on chargeback rates and customer trust is disproportionately high

4) Recommendations:

- implement duplicate transaction monitoring (based on user_id + amount + timestamp);

- clearly inform users: "Any duplicate transaction will be automatically refunded within N hours";

- limit the retry mechanism blocking repeated attempts for 1–2 minutes;

- track duplicate statistics by provider and escalate cases where a provider shows a high duplication rate
