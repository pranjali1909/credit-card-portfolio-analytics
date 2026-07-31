/*
---------------------------------------------------------------
Credit Card Portfolio Analytics
Revenue Leakage Analysis
---------------------------------------------------------------

Description:
This script evaluates portfolio revenue leakage by analyzing
flagged transactions across merchant categories, transaction
timing, and geographic regions.

Analyses Included:
1. Revenue Leakage Overview
2. Merchant Category Analysis
3. Hourly Analysis
4. State-wise Analysis

Author: Pranjali Jadkar
---------------------------------------------------------------
*/


/*=============================================================
1. Revenue Leakage Overview
=============================================================*/

SELECT
    is_fraud,
    COUNT(*) AS txn_count,
    ROUND(SUM(amt), 2) AS total_amt,
    ROUND(AVG(amt), 2) AS avg_amt,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM transactions),3) AS pct_of_txns
FROM transactions
GROUP BY is_fraud;

/*=============================================================
2. Revenue Leakage by Merchant Category
=============================================================*/

WITH flagged_df AS (
    SELECT
        category,
        COUNT(*) AS txn_count,
        SUM(is_fraud) AS incident_count,
        ROUND(100.0 * SUM(is_fraud) / COUNT(*),3) AS incident_rate_pct,
        ROUND(SUM(CASE WHEN is_fraud = 1 THEN amt ELSE 0 END),2) AS incident_dollar_value
    FROM transactions
    GROUP BY category
)
SELECT *,
    ROUND(incident_dollar_value / incident_count,2) AS dollar_loss_per_incident
FROM flagged_df
ORDER BY incident_rate_pct DESC;


/*=============================================================
3. Revenue Leakage by Hour of Day
=============================================================*/

SELECT
    CAST(strftime('%H', trans_date_trans_time) AS INTEGER) AS hour_of_day,
    COUNT(*) AS txn_count,
    SUM(is_fraud) AS incident_count,
    ROUND(100.0 * SUM(is_fraud) / COUNT(*),3) AS incident_rate_pct,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN amt ELSE 0 END),2) AS incident_dollar_value,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN amt ELSE 0 END)/NULLIF(SUM(is_fraud),0),2) AS dollar_loss_per_txn
FROM transactions
GROUP BY hour_of_day
ORDER BY hour_of_day;

/*=============================================================
4. Revenue Leakage by State
=============================================================*/

WITH flagged_df AS (
    SELECT
        state,
        COUNT(*) AS txn_count,
        SUM(is_fraud) AS incident_count,
        ROUND(100.0 * SUM(is_fraud) / COUNT(*),3) AS incident_rate_pct,
        ROUND(SUM(CASE WHEN is_fraud = 1 THEN amt ELSE 0 END),2) AS incident_dollar_value
    FROM transactions
    GROUP BY state
    HAVING COUNT(*) >= 100
)
SELECT *,
    ROUND(incident_dollar_value / incident_count,2) AS dollar_loss_per_incident
FROM flagged_df
ORDER BY incident_rate_pct DESC;