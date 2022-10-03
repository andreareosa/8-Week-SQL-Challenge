/*---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	8 Week SQL Challenge - Case Study 7 - Balanced Tree Clothing Co.
	LINK: https://8weeksqlchallenge.com/case-study-7/

	RDBMS used: Microsfot SQL Server
	Author: André Areosa
	Date: 03/10/2022
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

----------------------------------------------------------------------------------------------DATA-CLEANSING-----------------------------------------------------------------------------------------------------------------

UPDATE balanced_tree.sales
SET member = CASE 
			 WHEN member = 't' THEN 1
			 ELSE 0
			 END;

ALTER TABLE balanced_tree.sales
ALTER COLUMN member int;

SELECT TABLE_NAME,COLUMN_NAME,DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'sales'
	AND TABLE_SCHEMA = 'balanced_tree';

----------------------------------------------------------------------------------------1. HIGH LEVEL SALES ANALYSIS---------------------------------------------------------------------------------------------------------

-- 1.1 What was the total quantity sold for all products?
SELECT SUM(qty) as sold_quantity
FROM balanced_tree.sales;

-- 1.2 What is the total generated revenue for all products before discounts?
SELECT SUM(qty * price) as generated_revenue
FROM balanced_tree.sales;

-- 1.3 What was the total discount amount for all products?
SELECT 
SUM(ROUND(b.generated_revenue * b.pct_discount,2)) as discount_amount

FROM(
	 SELECT 
	 prod_id
	 ,SUM(qty * price) as generated_revenue
	 ,CAST(discount as float)/100 as pct_discount
	 FROM balanced_tree.sales
	 GROUP BY prod_id,CAST(discount as float)/100
) b;


----------------------------------------------------------------------------------------2. TRANSACTION ANALYSIS---------------------------------------------------------------------------------------------------------------

-- 2.1 How many unique transactions were there?
SELECT COUNT(DISTINCT txn_id) as unique_transactions
FROM balanced_tree.sales;

-- 2.2 What is the average unique products purchased in each transaction?
SELECT AVG(unique_products)	as avg_unique_products
FROM(
	SELECT txn_id
	,COUNT(DISTINCT prod_id) unique_products
	
	FROM balanced_tree.sales
	
	GROUP BY txn_id
) b;

-- 2.3 What are the 25th, 50th and 75th percentile values for the revenue per transaction?
ALTER TABLE balanced_tree.sales
ALTER COLUMN txn_id NVARCHAR(6);

SELECT DISTINCT 
PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY generated_revenue) OVER()  as percentile_25
,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY generated_revenue) OVER() as percentile_50
,PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY generated_revenue) OVER() as percentile_75

FROM(		
	 SELECT DISTINCT txn_id
	 ,SUM(qty * price) as generated_revenue
	 
	 FROM balanced_tree.sales
	 GROUP BY txn_id
) b;


-- 2.4 What is the average discount value per transaction?
SELECT
txn_id
,ROUND(AVG(txn_discount),2) as avg_discount

FROM(
	SELECT txn_id
	,(qty * price) * CAST(discount as float)/100 as txn_discount
	
	FROM balanced_tree.sales
) b

GROUP BY txn_id;

-- 2.5 What is the percentage split of all transactions for members vs non-members?
DECLARE @txn_total float = (SELECT COUNT(distinct txn_id) as txn_total
					  FROM balanced_tree.sales)

SELECT 
member
,COUNT(distinct txn_id)/@txn_total * 100 as pct_split
	
FROM balanced_tree.sales
GROUP BY member;

-- 2.6 What is the average revenue for member transactions and non-member transactions?
SELECT 
member
,ROUND(AVG(revenue),2) as avg_revenue

FROM(
	 SELECT
	 txn_id
	 ,member
	 ,SUM(CAST(qty*price as float)) as revenue
	 
	 FROM balanced_tree.sales
	 GROUP BY txn_id,member
) b

GROUP BY member;

----------------------------------------------------------------------------------------3. TRANSACTION ANALYSIS---------------------------------------------------------------------------------------------------------------

-- 3.1 What are the top 3 products by total revenue before discount?
SELECT TOP 3
prod_id
,SUM(qty * price) as revenue

FROM balanced_tree.sales
GROUP BY prod_id
ORDER BY 2 DESC;

-- 3.2 What is the total quantity, revenue and discount for each segment?
SELECT d.segment_name
,SUM(qty) as quantity
,SUM(qty * s.price) as revenue
,SUM(qty * s.price * (CAST(discount as float)/100)) as discount

FROM balanced_tree.sales s
	INNER JOIN balanced_tree.product_details d on s.prod_id = d.product_id

GROUP BY d.segment_name;

-- 3.3 What is the top selling product for each segment?
SELECT 
t.segment_name
,t.prod_id
,d.product_name
,t.quantity

FROM(
	SELECT *
	,RANK() OVER (PARTITION BY segment_name ORDER BY quantity DESC) as product_ranking
	
	FROM(	
		SELECT d.segment_name
		,s.prod_id
		,SUM(qty) as quantity
		
		FROM balanced_tree.sales s
			INNER JOIN balanced_tree.product_details d on s.prod_id = d.product_id
		
		GROUP BY d.segment_name
		,s.prod_id
	) b
) t
	INNER JOIN balanced_tree.product_details d on t.prod_id = d.product_id

WHERE t.product_ranking = 1;

-- 3.4 What is the total quantity, revenue and discount for each category?
SELECT d.category_name
,SUM(qty) as quantity
,SUM(qty * s.price) as revenue
,SUM(qty * s.price * (CAST(discount as float)/100)) as discount

FROM balanced_tree.sales s
	INNER JOIN balanced_tree.product_details d on s.prod_id = d.product_id

GROUP BY d.category_name;

-- 3.5 What is the top selling product for each category?
SELECT 
t.category_name
,t.prod_id
,d.product_name
,t.quantity

FROM(
	SELECT *
	,RANK() OVER (PARTITION BY category_name ORDER BY quantity DESC) as product_ranking
	
	FROM(	
		SELECT d.category_name
		,s.prod_id
		,SUM(qty) as quantity
		
		FROM balanced_tree.sales s
			INNER JOIN balanced_tree.product_details d on s.prod_id = d.product_id
		
		GROUP BY d.category_name
		,s.prod_id
	) b
) t
	INNER JOIN balanced_tree.product_details d on t.prod_id = d.product_id

WHERE t.product_ranking = 1;

-- 3.6 What is the percentage split of revenue by product for each segment?
SELECT 
p.segment_name
,s.prod_id
,p.product_name
,ROUND(SUM(s.qty * s.price)/a.segment_revenue * 100,1) as pct_revenue

FROM balanced_tree.sales s
	INNER JOIN balanced_tree.product_details p on s.prod_id = p.product_id
	LEFT JOIN (SELECT p.segment_name
				,CAST(SUM(s.qty * s.price) as float) as segment_revenue
				
				FROM balanced_tree.sales s
					INNER JOIN balanced_tree.product_details p on s.prod_id = p.product_id 
				GROUP BY p.segment_name
				) a on a.segment_name = p.segment_name

GROUP BY 
p.segment_name
,prod_id
,p.product_name
,a.segment_revenue

ORDER BY 1,4 DESC;


-- 3.7 What is the percentage split of revenue by segment for each category?
with category_revenue as (
	SELECT p.category_name
	,SUM(s.qty * s.price) as revenue

	FROM balanced_tree.sales s
		INNER JOIN balanced_tree.product_details p on s.prod_id = p.product_id

	GROUP BY p.category_name
)

SELECT 
p.category_name
,p.segment_name
,ROUND(SUM(s.qty * s.price)/CAST(r.revenue as float)*100,1) as pct_revenue

FROM balanced_tree.sales s
	INNER JOIN balanced_tree.product_details p on s.prod_id = p.product_id
	INNER JOIN category_revenue r on p.category_name = r.category_name

GROUP BY p.category_name,p.segment_name,r.revenue
ORDER BY 1,3 DESC;


-- 3.8 What is the percentage split of total revenue by category?
SELECT 
p.category_name
,ROUND(CAST(SUM(s.qty * s.price) as float)/ SUM(SUM(s.qty * s.price)) OVER()  * 100,1) as pct_revenue

FROM balanced_tree.sales s
	INNER JOIN balanced_tree.product_details p on s.prod_id = p.product_id

GROUP BY p.category_name
ORDER BY p.category_name;

-- 3.9 What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
DECLARE @total_txn float = (SELECT COUNT(DISTINCT txn_id) FROM balanced_tree.sales)

SELECT 
prod_id
,p.product_name
,ROUND(COUNT(DISTINCT txn_id)/@total_txn * 100,2) as txn_penetrated

FROM balanced_tree.sales s
	INNER JOIN balanced_tree.product_details p on s.prod_id = p.product_id

GROUP BY prod_id,p.product_name
ORDER BY 3 DESC;

-- 3.10 What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
DROP TABLE IF EXISTS #products;

SELECT 
s.txn_id
,product_id
INTO #products

FROM balanced_tree.sales s
	INNER JOIN balanced_tree.product_details p on s.prod_id = p.product_id;

SELECT *
FROM( 
    SELECT TOP 1
    p.product_id as prod_1
    ,p2.product_id as prod_2
    ,p3.product_id as prod_3
    ,COUNT(*) as times_bought_together
    
    FROM #products p
    	INNER JOIN #products p2 on p.txn_id = p2.txn_id
    		AND p.product_id < p2.product_id
    	
    	INNER JOIN #products p3 on p.txn_id = p3.txn_id
    		AND p.product_id < p3.product_id
    		AND p2.product_id < p3.product_id
    
    WHERE 1=1
    	--AND p.txn_id in ('030b14')	
    
    GROUP BY p.product_id 
    ,p2.product_id 
    ,p3.product_id 
  
  ORDER BY 4 DESC
) a


----------------------------------------------------------------------------------------4. REPORTING CHALLENGE---------------------------------------------------------------------------------------------------------------
/* 
	Write a single SQL script that combines all of the previous questions into a scheduled report that the Balanced Tree team can run at the beginning of each month to calculate the previous month’s values.

	Imagine that the Chief Financial Officer (which is also Danny) has asked for all of these questions at the end of every month.

	He first wants you to generate the data for January only - but then he also wants you to demonstrate that you can easily run the samne analysis for February without many changes (if at all).

	Feel free to split up your final outputs into as many tables as you need - but be sure to explicitly reference which table outputs relate to which question for full marks :)
*/

CREATE PROCEDURE sales_anaylsis (@start_date date, @end_date date)
AS
BEGIN 
  
  DROP TABLE IF EXISTS #sales_analysis;
  
  SELECT
  FORMAT(start_txn_time,'yyyy-MM') as year_month
  ,SUM(qty) as quantity_sold
  ,SUM(qty * price) as generated_revenue
  ,ROUND(SUM(qty * price * (CAST(discount as float)/100)),2) as discount_amount
  ,CURRENT_TIMESTAMP as procedure_timestamp
  
  FROM balanced_tree.sales
  
  WHERE CAST(start_txn_time as DATE) between @start_date and @end_date
  
  GROUP BY FORMAT(start_txn_time,'yyyy-MM')
  ORDER BY 1

END;

EXEC sales_anaylsis @start_date = '2021-01-01',@end_date = '2021-01-31';

-- We could have used dynamic dates to avoid using manual parameteres, however my data is not that recent. Example:
SELECT DATEADD(MONTH,DATEDIFF(MONTH,0,GETDATE() - 1),0) -- first day of previous month


----------------------------------------------------------------------------------------5. BONUS CHALLENGE-------------------------------------------------------------------------------------------------------------------
/*
	Use a single SQL query to transform the product_hierarchy and product_prices datasets to the product_details table.

	Hint: you may want to consider using a recursive CTE to solve this problem!
*/

SELECT 
p.product_id
,p.price
,CONCAT(h.level_text,' ',h2.level_name,' - ',h3.level_text) as product_name
,h2.parent_id as category_id
,h2.id as segment_id
,h.id as style_id
,h3.level_text as category_name
,h2.level_text as segment_name
,h.level_text as style_name

FROM balanced_tree.product_hierarchy h
	INNER JOIN balanced_tree.product_hierarchy h2 on h.parent_id = h2.id
	INNER JOIN balanced_tree.product_hierarchy h3 on h2.parent_id = h3.id
	INNER JOIN balanced_tree.product_prices p on h.id = p.id