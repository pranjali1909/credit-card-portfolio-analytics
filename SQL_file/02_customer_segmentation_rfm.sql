/*
---------------------------------------------------------------
Credit Card Portfolio Analytics
Customer Segmentation using RFM Analysis
---------------------------------------------------------------

Description:
This script builds an RFM (Recency, Frequency, Monetary)
customer segmentation framework using SQL Window Functions.

Workflow:
1. Aggregate customer transaction metrics
2. Calculate Recency
3. Assign RFM Quartile Scores
4. Classify customers into business segments

Author: Pranjali Jadkar
---------------------------------------------------------------
*/


/*=============================================================
1. Customer Aggregation
One row per customer with transaction metrics
=============================================================*/

SELECT
    cc_num,
    COUNT(*) AS txn_count,
    ROUND(SUM(amt), 2) AS monetary,
    ROUND(AVG(amt), 2) AS avg_ticket,
    MAX(trans_date_trans_time) AS last_txn_date
FROM transactions
GROUP BY cc_num
ORDER BY monetary DESC;

/*=============================================================
2. Customer Count
=============================================================*/

SELECT
    COUNT(DISTINCT cc_num) AS total_customers
FROM transactions;

/*=============================================================
3. Customer Metrics with Recency and Value Quartile
=============================================================*/

WITH customer_agg AS (
    SELECT
        cc_num,
        COUNT(*) AS frequency_of_spend,
        ROUND(SUM(amt), 2) AS monetary,
        ROUND(AVG(amt), 2) AS avg_ticket,
        MAX(trans_date_trans_time) AS last_txn_date
    FROM transactions
    GROUP BY cc_num
),
ref_date AS (
    SELECT
        MAX(trans_date_trans_time) AS max_date
    FROM transactions
)
SELECT
    c.cc_num,
    c.frequency_of_spend,
    c.monetary,
    c.last_txn_date,
    CAST(julianday(r.max_date) - julianday(c.last_txn_date) AS INTEGER) AS recency_days,
    NTILE(4) OVER (ORDER BY c.monetary DESC) AS value_quartile
FROM customer_agg c, ref_date r
ORDER BY c.monetary DESC;

/*=============================================================
4. Final RFM Segmentation
=============================================================*/

WITH customer_agg AS (
    SELECT
        cc_num,
        COUNT(*) AS frequency,
        ROUND(SUM(amt), 2) AS monetary,
        MAX(trans_date_trans_time) AS last_txn_date,
        MIN(gender) AS gender,
        MIN(state) AS state,
        MIN(job) AS job,
        MIN(dob) AS dob
    FROM transactions
    GROUP BY cc_num
),
ref_date AS (
    SELECT MAX(trans_date_trans_time) AS max_date
    FROM transactions
),
rfm_base AS (
    SELECT
        c.cc_num,
        c.frequency,
        c.monetary,
        c.gender,
        c.state,
        c.job,
        CAST((julianday(r.max_date) - julianday(c.dob)) / 365.25 AS INTEGER) AS age,
        CAST(julianday(r.max_date) - julianday(c.last_txn_date) AS INTEGER) AS recency_days
    FROM customer_agg c, ref_date r
),
rfm_scored AS (
    SELECT *,
        NTILE(4) OVER (ORDER BY recency_days ASC) AS r_quartile,
        NTILE(4) OVER (ORDER BY frequency DESC) AS f_quartile,
        NTILE(4) OVER (ORDER BY monetary DESC) AS m_quartile
    FROM rfm_base
)

SELECT *,
    CASE
        WHEN r_quartile <= 2 AND f_quartile <= 2 AND m_quartile <= 2 THEN 'Champions / VIP'
        WHEN r_quartile >= 3 AND f_quartile <= 2 AND m_quartile <= 2 THEN 'At Risk / Win-Back'
        WHEN r_quartile <= 2 AND (f_quartile <= 2 OR m_quartile <= 2) THEN 'Loyal / Core'
        WHEN r_quartile <= 2 THEN 'Promising / New'
        WHEN f_quartile <= 2 OR m_quartile <= 2 THEN 'Needs Attention'
        ELSE 'Hibernating / Low Priority'
    END AS segment
FROM rfm_scored
ORDER BY monetary DESC;

/*=============================================================
5. Recency Distribution
=============================================================*/

SELECT
    CASE
        WHEN recency_days <= 7 THEN '0-7 Days'
        WHEN recency_days <= 30 THEN '8-30 Days'
        WHEN recency_days <= 90 THEN '31-90 Days'
        ELSE '90+ Days' END AS recency_bucket,    
    COUNT(*) AS customer_count
FROM final_df
GROUP BY recency_bucket
ORDER BY MIN(recency_days);