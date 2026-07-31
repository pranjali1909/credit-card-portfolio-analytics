/*
---------------------------------------------------------------
Credit Card Portfolio Analytics
Portfolio Analysis
---------------------------------------------------------------

Description:
This script analyzes portfolio spending patterns across multiple
business dimensions, including merchant categories, transaction
timing, and geographic distribution.

Analyses Included:
1. Spend by Merchant Category
2. Spend by Hour of Day
3. Spend by Day of Week
4. Spend by State

Author: Pranjali Jadkar
---------------------------------------------------------------
*/


/*=============================================================
1. Spend by Merchant Category
=============================================================*/

SELECT
    category,
    COUNT(*) AS txn_count,
    ROUND(SUM(amt), 2) AS total_spend,
    ROUND(AVG(amt), 2) AS avg_ticket
FROM transactions
GROUP BY category
ORDER BY total_spend DESC;



/*=============================================================
2. Spend by Hour of Day
=============================================================*/

SELECT
    CAST(strftime('%H', trans_date_trans_time) AS INTEGER) AS hour_of_day,
    COUNT(*) AS txn_count,
    ROUND(SUM(amt), 2) AS total_spend,
    ROUND(AVG(amt), 2) AS avg_spend
FROM transactions
GROUP BY hour_of_day
ORDER BY hour_of_day;



/*=============================================================
3. Spend by Day of Week
=============================================================*/

SELECT
    CASE CAST(strftime('%w', trans_date_trans_time) AS INTEGER)
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday' END AS day_of_week,
    COUNT(*) AS txn_count,
    ROUND(SUM(amt), 2) AS total_spend,
    ROUND(AVG(amt), 2) AS avg_spend
FROM transactions
GROUP BY 1
ORDER BY CAST(strftime('%w', trans_date_trans_time) AS INTEGER);

/*=============================================================
4. Top 15 States by Portfolio Spend
=============================================================*/

SELECT
    state,
    COUNT(*) AS txn_count,
    ROUND(SUM(amt), 2) AS total_spend,
    COUNT(DISTINCT cc_num) AS unique_customers

FROM transactions

GROUP BY state

ORDER BY total_spend DESC

LIMIT 15;