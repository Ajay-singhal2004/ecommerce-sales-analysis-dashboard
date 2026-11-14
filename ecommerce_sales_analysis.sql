-- E-COMMERCE SALES ANALYSIS | MySQL 8+
-- Source: Clean_Ecommerce.csv (uploaded project)
-- Import the CSV into a MySQL table named orders first.
-- Column names must match the CSV, including lowercase `year` and `weekday`.
-- Important: CSV contains missing dates, prices and amounts. Aggregates ignore NULL values.
-- Sales is gross before discounts; Net_Amount is after discounts.
-- Profit is an estimated 20% of Net_Amount, not verified actual margin.
-- These are exploratory queries; cancelled/returned orders are included unless filtered.

-- 01. Data quality audit
SELECT COUNT(*) AS rows_total,
       COUNT(DISTINCT Order_ID) AS distinct_order_ids,
       SUM(Order_ID IS NULL OR TRIM(Order_ID) = '') AS missing_order_ids,
       SUM(Order_Date IS NULL) AS missing_order_dates,
       SUM(Unit_Price IS NULL) AS missing_unit_prices,
       SUM(Net_Amount IS NULL) AS missing_net_amounts
FROM orders;

-- 02. Overall KPIs (all order statuses)
SELECT COUNT(*) AS row_count,
       COUNT(DISTINCT Order_ID) AS unique_orders,
       ROUND(SUM(Sales), 2) AS gross_sales,
       ROUND(SUM(Net_Amount), 2) AS net_sales,
       ROUND(SUM(Profit), 2) AS estimated_profit,
       ROUND(SUM(Net_Amount) / NULLIF(COUNT(DISTINCT Order_ID), 0), 2) AS net_sales_per_unique_order
FROM orders;

-- 03. Monthly trend in chronological order (exclude missing dates)
SELECT YEAR(Order_Date) AS sales_year,
       MONTH(Order_Date) AS sales_month,
       DATE_FORMAT(Order_Date, '%M') AS month_name,
       COUNT(*) AS order_rows,
       ROUND(SUM(Net_Amount), 2) AS net_sales
FROM orders
WHERE Order_Date IS NOT NULL
GROUP BY YEAR(Order_Date), MONTH(Order_Date), DATE_FORMAT(Order_Date, '%M')
ORDER BY sales_year, sales_month;

-- 04. Sales and estimated profit by category
SELECT Category, COUNT(*) AS order_rows,
       ROUND(SUM(Net_Amount), 2) AS net_sales,
       ROUND(SUM(Profit), 2) AS estimated_profit
FROM orders
GROUP BY Category
ORDER BY net_sales DESC;

-- 05. Top products by net sales
SELECT Product, SUM(Qty) AS units,
       ROUND(SUM(Net_Amount), 2) AS net_sales
FROM orders
GROUP BY Product
ORDER BY net_sales DESC
LIMIT 10;

-- 06. Top cities by net sales
SELECT City, COUNT(*) AS order_rows,
       ROUND(SUM(Net_Amount), 2) AS net_sales
FROM orders
GROUP BY City
ORDER BY net_sales DESC
LIMIT 10;

-- 07. Payment method performance
SELECT Payment_Mode, COUNT(*) AS order_rows,
       ROUND(SUM(Net_Amount), 2) AS net_sales,
       ROUND(100.0 * SUM(Net_Amount) / NULLIF((SELECT SUM(Net_Amount) FROM orders), 0), 2) AS sales_share_pct
FROM orders
GROUP BY Payment_Mode
ORDER BY net_sales DESC;

-- 08. Order status breakdown
SELECT Order_Status, COUNT(*) AS order_rows,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM orders), 2) AS share_pct,
       ROUND(SUM(Net_Amount), 2) AS net_sales
FROM orders
GROUP BY Order_Status
ORDER BY order_rows DESC;

-- 09. Completed/delivered orders only (alternative view)
SELECT COUNT(*) AS delivered_rows,
       ROUND(SUM(Net_Amount), 2) AS delivered_net_sales,
       ROUND(SUM(Profit), 2) AS delivered_estimated_profit
FROM orders
WHERE Order_Status = 'Delivered';

-- 10. Highest estimated-profit products
SELECT Product, ROUND(SUM(Profit), 2) AS estimated_profit
FROM orders
GROUP BY Product
ORDER BY estimated_profit DESC;

-- 11. Average order value by status (one row per order assumed)
SELECT Order_Status,
       ROUND(SUM(Net_Amount) / NULLIF(COUNT(DISTINCT Order_ID), 0), 2) AS avg_net_amount_per_order
FROM orders
GROUP BY Order_Status;

-- 12. Missing-date and missing-sales diagnostic
SELECT
  CASE WHEN Order_Date IS NULL THEN 'Missing order date' ELSE 'Has order date' END AS date_quality,
  CASE WHEN Net_Amount IS NULL THEN 'Missing net amount' ELSE 'Has net amount' END AS sales_quality,
  COUNT(*) AS row_count
FROM orders
GROUP BY date_quality, sales_quality
ORDER BY row_count DESC;
