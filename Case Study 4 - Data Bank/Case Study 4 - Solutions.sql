/*---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	8 Week SQL Challenge - Case Study 4 - Data Bank
	LINK: https://8weeksqlchallenge.com/case-study-4/

	RDBMS used: Microsfot SQL Server
	Author: André Areosa
	Date: 14/09/2022
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/


-----------------------------------------------------------------------------------------A. CUSTOMER NODES EXPLORATION-------------------------------------------------------------------------------------------------------

--A.1 How many unique nodes are there on the Data Bank system?
SELECT COUNT(DISTINCT node_id) as unique_nodes
FROM data_bank.customer_nodes;


--A.2 What is the number of nodes per region?
SELECT r.region_id
,r.region_name
,COUNT(c.node_id) as nr_nodes

FROM data_bank.customer_nodes c
	INNER JOIN data_bank.regions r on c.region_id = r.region_id

GROUP BY r.region_id,r.region_name
ORDER BY r.region_id;


--A.3 How many customers are allocated to each region?
SELECT r.region_id
,r.region_name
,COUNT(DISTINCT c.customer_id) as nr_customers -- customers are randomly distributed across the nodes and this distribution changes frequently to reduce the risk of hackers 

FROM data_bank.customer_nodes c
	INNER JOIN data_bank.regions r on c.region_id = r.region_id

GROUP BY r.region_id,r.region_name
ORDER BY r.region_id;


--A.4 How many days on average are customers reallocated to a different node?
SELECT AVG(a.days_to_reallocate) as avg_days_to_reallocate -- = 416373 days. This result is impossible so probably there is some misleading data.
FROM(
	 SELECT 
	 DATEDIFF(day,start_date,end_date) as days_to_reallocate
	 
	 FROM data_bank.customer_nodes c
) a;

-- Find the misleading data
SELECT *
FROM data_bank.customer_nodes
ORDER BY end_date DESC

-- Ignore the misleading data
SELECT AVG(a.days_to_reallocate) as avg_days_to_reallocate
FROM(
	 SELECT 
	 DATEDIFF(day,start_date,end_date) as days_to_reallocate
	 
	 FROM data_bank.customer_nodes c
	 
	 WHERE end_date <> '9999-12-31'
) a;


--A.5 What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
SELECT b.region_id
,b.region_name
,MAX(b.median) as median
,MAX(b.percentile_80) as percentile_80
,MAX(b.percentile_95) as percentile_95

FROM (
	  SELECT 
	  a.region_id
	  ,a.region_name
	  ,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY a.days_to_reallocate) OVER (PARTITION BY a.region_id) as median
	  ,PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY a.days_to_reallocate) OVER (PARTITION BY a.region_id) as percentile_80
	  ,PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY a.days_to_reallocate) OVER (PARTITION BY a.region_id) as percentile_95
	
	  FROM(
	  	   SELECT 
	  	   c.customer_id
	  	   ,c.region_id
		   ,r.region_name
	  	   ,DATEDIFF(day,start_date,end_date) as days_to_reallocate
	  	   
	  	   FROM data_bank.customer_nodes c
		  	INNER JOIN data_bank.regions r on c.region_id = r.region_id
	  	   
	  	   WHERE end_date <> '9999-12-31'
	     ) a
) b
	
GROUP BY b.region_id,b.region_name
ORDER BY b.region_id;


-----------------------------------------------------------------------------------------B. CUSTOMER TRANSACTIONS------------------------------------------------------------------------------------------------------------

-- B.1 What is the unique count and total amount for each transaction type?
SELECT txn_type
,COUNT(*) as nr_transactions
,SUM(txn_amount) as total_amount

FROM data_bank.customer_transactions 

GROUP BY txn_type;


-- B.2 What is the average total historical deposit counts and amounts for all customers?
SELECT 
AVG(b.nr_deposits) as avg_deposits
,AVG(b.amount_deposits) as avg_amount

FROM(
	 SELECT customer_id
	 ,COUNT(*) as nr_deposits
	 ,AVG(txn_amount) as amount_deposits
	 
	 FROM data_bank.customer_transactions
	 WHERE txn_type = 'deposit'
	 
	 GROUP BY customer_id
) b;


-- B.3 For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
SELECT year_month
,COUNT(customer_id) as nr_customers

FROM (
	  SELECT customer_id
	  ,FORMAT(txn_date,'yyyy-MM') as year_month
	  ,SUM(CASE
	  		   WHEN txn_type = 'deposit' THEN 1
	  		   ELSE 0
		   END) as deposits
	  ,SUM(CASE
	  	   WHEN txn_type = 'purchase' THEN 1
	  	   ELSE 0
	       END) as purchases
	  ,SUM(CASE
	  	   WHEN txn_type = 'withdrawal' THEN 1
	  	   ELSE 0
	       END) as withdrawals
	  
	  FROM data_bank.customer_transactions 
	  GROUP BY customer_id,FORMAT(txn_date,'yyyy-MM')
) b

WHERE b.deposits > 1
	AND (b.purchases = 1 OR b.withdrawals = 1)

GROUP BY year_month
ORDER BY 1;

-- B.4 What is the closing balance for each customer at the end of the month?
DROP TABLE IF EXISTS #monthly_balances;

SELECT 
customer_id
,FORMAT(txn_date,'yyyy-MM') as year_month
,SUM(CASE
		 WHEN txn_type = 'deposit' THEN txn_amount
		 ELSE - txn_amount
		 END) as amount
INTO #monthly_balances

FROM data_bank.customer_transactions 
GROUP BY customer_id,FORMAT(txn_date,'yyyy-MM');


SELECT *
FROM #monthly_balances
WHERE customer_id = 11


SELECT 
customer_id
,year_month
,SUM(amount) OVER(PARTITION BY customer_id ORDER BY year_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as closing_balance 

FROM #monthly_balances;

-- NOTE: Information about ROWS clause: https://learnsql.com/blog/sql-window-functions-rows-clause/


-- B.5 What is the percentage of customers who increase their closing balance by more than 5%?
DECLARE @total_customers int = (SELECT COUNT(DISTINCT customer_id)
								FROM data_bank.customer_transactions);

-- Calculate the growth between customer's initial balance and customer's last balance
with rank_cte as (
			      SELECT 
			      customer_id
			      ,year_month
			      ,SUM(amount) OVER(PARTITION BY customer_id ORDER BY year_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as closing_balance 
			      ,RANK() OVER(PARTITION BY customer_id ORDER BY year_month) as balance_rank
			      
			      FROM #monthly_balances
)
,max_rank_cte as (
				  SELECT customer_id
				  ,MAX(balance_rank) as max_balance_rank

				  FROM rank_cte
				  GROUP BY customer_id
)
,last_balance as (
				  SELECT r.customer_id
				  ,r.closing_balance as last_balance
				  
				  FROM rank_cte r
					INNER JOIN max_rank_cte r2 on r.customer_id = r2.customer_id AND r.balance_rank = r2.max_balance_rank
)
,growth_balance as (				  
				    SELECT 
				    e.customer_id
				    ,r.closing_balance as initial_balance
				    ,e.last_balance as last_balance
				    ,ROUND((e.last_balance - r.closing_balance)/CAST(e.last_balance as float) * 100,2) as growth
				    			    
				    FROM last_balance e
				    	INNER JOIN rank_cte r on e.customer_id = r.customer_id and r.balance_rank = 1 -- retrieve customer's initial balance
				    
				    WHERE e.last_balance >= 0 -- if last balance is negative the growth will obviously be negative and consequently less than 5%
)

SELECT ROUND(COUNT(customer_id)/CAST(@total_customers as float) * 100,2) as [nr_customers_growth_more_than_5%]
FROM growth_balance 
WHERE growth > 5.00


-----------------------------------------------------------------------------------------C. DATA ALLOCATION CHALLENGE---------------------------------------------------------------------------------------------------------
-- 1: Calculate running customer balance column that includes the impact each transaction
DROP TABLE IF EXISTS #running_customer_balance;

with amount_cte as (
				    SELECT 
				    customer_id
				    ,txn_date
				    ,txn_type
				    ,CASE
				    	WHEN txn_type = 'deposit' THEN txn_amount
				    	ELSE - txn_amount
				    END as amount
				    
				    FROM data_bank.customer_transactions 
)

SELECT customer_id
,txn_date
,txn_type
,SUM(amount) OVER(PARTITION BY customer_id ORDER BY txn_date) as running_customer_balance
INTO #running_customer_balance

FROM amount_cte;

-- 2: Calculate customer balance at the end of each month
DROP TABLE IF EXISTS #monthly_customer_balance;

SELECT customer_id
,FORMAT(txn_date,'yyyy-MM') as year_month
,SUM(running_customer_balance) as monthly_balance
INTO #monthly_customer_balance

FROM #running_customer_balance
GROUP BY customer_id,FORMAT(txn_date,'yyyy-MM')
ORDER BY customer_id,FORMAT(txn_date,'yyyy-MM');

-- 3: Calculate minimum, average and maximum values of the running balance for each customer
DROP TABLE IF EXISTS #aggregated_running_customer_balance

SELECT customer_id
,FORMAT(txn_date,'yyyy-MM') as year_month
,MIN(running_customer_balance) as min_running_customer_balance
,MAX(running_customer_balance) as max_running_customer_balance
,AVG(running_customer_balance) as avg_running_customer_balance
INTO #aggregated_running_customer_balance

FROM #running_customer_balance
GROUP BY customer_id,FORMAT(txn_date,'yyyy-MM')
ORDER BY customer_id,FORMAT(txn_date,'yyyy-MM');


/*
Help the Data Bank team estimate how much data will need to be provisioned for each option:
	- Option 1: data is allocated based off the amount of money at the end of the previous month
	- Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
	- Option 3: data is updated real-time

Using all of the data available - how much data would have been required for each option on a monthly basis?
*/

-- Option 1:
SELECT year_month
,CASE
	WHEN LAG(monthly_amount,1) OVER(ORDER BY year_month) IS NULL THEN monthly_amount
	ELSE LAG(monthly_amount,1) OVER(ORDER BY year_month)
	END as previous_month_amount

FROM(  
	 SELECT 
	 year_month
	 ,SUM(IIF(monthly_balance>0,monthly_balance,0)) as monthly_amount -- Assumption: No data is allocated when the amount of money at the end of the month is negative
	 
	 FROM #monthly_customer_balance
	 GROUP BY year_month
) a

ORDER BY year_month

-- Option 2:
SELECT year_month
,CASE
	WHEN LAG(avg_monthly_balance,1) OVER(ORDER BY year_month) IS NULL THEN avg_monthly_balance
	ELSE LAG(avg_monthly_balance,1) OVER(ORDER BY year_month)
	END as previous_avg_monthly_balance

FROM(	
	 SELECT 
	 year_month
	 ,SUM(IIF(avg_running_customer_balance>0,avg_running_customer_balance,0)) as avg_monthly_balance
	 
	 FROM #aggregated_running_customer_balance
	 GROUP BY year_month
) a

ORDER BY year_month

-- Option 3
SELECT 
FORMAT(txn_date,'yyyy-MM') as year_month
,SUM(IIF(running_customer_balance>0,running_customer_balance,0)) as monthly_balance

FROM #running_customer_balance
GROUP BY FORMAT(txn_date,'yyyy-MM') 

