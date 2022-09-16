/*---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	8 Week SQL Challenge - Case Study 5 - Data Mart
	LINK: https://8weeksqlchallenge.com/case-study-5/

	RDBMS used: Microsfot SQL Server
	Author: André Areosa
	Date: 15/09/2022
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

---------------------------------------------------------------------------------------------------1. DATA CLEANSING---------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS data_mart.clean_weekly_sales;

SELECT 
week_date
,DATEPART(week,week_date) as week_number
,MONTH(week_date) as month_number
,YEAR(week_date) as calendar_year
,region
,platform
,segment
,CASE
	WHEN TRY_CONVERT(int,right_segment) = 1 THEN 'Young Adults'
	WHEN TRY_CONVERT(int,right_segment) = 2 THEN 'Middle Aged'
	WHEN TRY_CONVERT(int,right_segment) in (3,4) THEN 'Retirees'
	ELSE 'Unknown'
END AS age_band
,CASE
	WHEN LOWER(left_segment) = 'c' THEN 'Couples'
	WHEN LOWER(left_segment) = 'f' THEN 'Families'
	ELSE 'Unknown'
END AS demographic
,customer_type
,transactions
,sales
,ROUND(sales/CAST(transactions as float),2) as avg_transaction
INTO data_mart.clean_weekly_sales

FROM (
	  SELECT
	  CONVERT(date,week_date,3) as week_date -- Need to specify the input style. In this case it's 3 = 'dd/mm/yyyy'
	  ,region
	  ,platform
	  ,segment
	  ,RIGHT(segment,1) as right_segment
	  ,LEFT(segment,1) as left_segment
	  ,customer_type
	  ,transactions
	  ,sales
	  
	  FROM data_mart.weekly_sales
) a
;

-- NOTE: We should create dimension tables for: region, platform, age_band, demographic and customer_type but for simplicity sake I will keep the fact table as-is


---------------------------------------------------------------------------------------------------2. DATA EXPLORATION--------------------------------------------------------------------------------------------------------

-- 2.1 What day of the week is used for each week_date value?
SELECT DISTINCT week_date
,DATEPART(WEEKDAY,week_date) as weekday
,DATENAME(WEEKDAY,week_date) as weekday_name

FROM data_mart.clean_weekly_sales

ORDER BY week_date;


-- 2.2 What range of week numbers are missing from the dataset?
SELECT 
FORMAT(week_date,'yyyy') as year 
,MIN(week_number) as min_week_number
,MAX(week_number) as max_week_number
,CASE	
	WHEN MIN(week_number) = 1 AND MAX(week_number) = 52 THEN 'No ramge missing'
	ELSE CONCAT('0-',MIN(week_number)-1,' , ',MAX(week_number) +1,'-52')
END AS range_week_numbers_missing

FROM data_mart.clean_weekly_sales

GROUP BY FORMAT(week_date,'yyyy')
ORDER BY FORMAT(week_date,'yyyy');

-- This question can also be solved using recursive CTEs:
with recursive_CTE as (
	SELECT 1 as n
	
	UNION ALL

	SELECT n + 1 as n
	FROM recursive_CTE
	WHERE n < 52
)

SELECT * 
FROM recursive_CTE

EXCEPT 

SELECT DISTINCT week_number
FROM data_mart.clean_weekly_sales


-- 2.3 How many total transactions were there for each year in the dataset?
SELECT 
FORMAT(week_date,'yyyy') as year 
,SUM(transactions) as total_transactions

FROM data_mart.clean_weekly_sales

GROUP BY FORMAT(week_date,'yyyy');


-- 2.4 What is the total sales for each region for each month?
SELECT 
region
,FORMAT(week_date,'yyyy-MM') as year_month
,SUM(sales) as total_sales

FROM data_mart.clean_weekly_sales

GROUP BY region,FORMAT(week_date,'yyyy-MM')
ORDER BY region,FORMAT(week_date,'yyyy-MM');


-- 2.5 What is the total count of transactions for each platform
SELECT platform
,COUNT(transactions) as total_transactions

FROM data_mart.clean_weekly_sales

GROUP BY platform;

-- 2.6 What is the percentage of sales for Retail vs Shopify for each month?
with total_sales as (
		SELECT 
		FORMAT(week_date,'yyyy-MM') as year_month
		,SUM(CAST(sales as float)) as total_sales

		FROM data_mart.clean_weekly_sales
		GROUP BY FORMAT(week_date,'yyyy-MM')
)
,platform_sales as (
		SELECT 
		FORMAT(week_date,'yyyy-MM') as year_month
		,platform
		,SUM(CASE
			 WHEN platform = 'Shopify' THEN CAST(sales as float)
			 ELSE 0 
			 END) as shopify_sales
		,SUM(CASE
			 WHEN platform = 'Retail' THEN CAST(sales as float)
			 ELSE 0 
			 END) as retail_sales
		
		FROM data_mart.clean_weekly_sales
		
		GROUP BY FORMAT(week_date,'yyyy-MM'),platform
)

SELECT p.year_month
,p.platform
,CASE
	WHEN platform = 'Shopify' THEN ROUND(p.shopify_sales/t.total_sales * 100,2)
	ELSE ROUND(p.retail_sales/t.total_sales * 100,2)
END AS pct_sales

FROM platform_sales p
	INNER JOIN total_sales t on p.year_month = t.year_month

ORDER BY p.year_month,p.platform;


-- 2.7 What is the percentage of sales by demographic for each year in the dataset?
SELECT 
calendar_year
,demographic
,ROUND(demographic_sales/SUM(demographic_sales) OVER(PARTITION BY calendar_year) * 100,2) as pct_sales

FROM(
	 SELECT 
	 calendar_year
	 ,demographic
	 ,SUM(CAST(sales as float)) as demographic_sales
	 
	 FROM data_mart.clean_weekly_sales
	 
	 GROUP BY calendar_year,demographic
) a

ORDER BY calendar_year,demographic;


-- 2.8 Which age_band and demographic values contribute the most to Retail sales?
DECLARE @total_sales float = (SELECT SUM(CAST(sales as float)) FROM data_mart.clean_weekly_sales); 
							
SELECT TOP 1 *
,ROUND(sales/@total_sales * 100,1) as pct_sales
,RANK() OVER(ORDER BY sales DESC) as rank

FROM(
	 SELECT 
	 age_band
	 ,demographic
	 ,SUM(CAST(sales as float)) as sales
	 
	 FROM data_mart.clean_weekly_sales
	 
	 WHERE platform = 'Retail'
	 
	 GROUP BY age_band,demographic
) a

WHERE age_band <> 'Unknown'
	AND demographic <> 'Unknown' -- Most of age band and demographic characteristics are unknown therefore we should filter them from the result  

ORDER BY sales DESC;


-- 2.9 Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?

-- No. 
-- First of all: avg_transaction indicates the average sales per transactions therefore is not a size metric. 
-- Second: we can't use the average of an average to the calculate the average
SELECT 
calendar_year
,platform
,AVG(transactions) as avg_transaction_size

FROM data_mart.clean_weekly_sales

GROUP BY calendar_year,platform
ORDER BY calendar_year,platform;


-------------------------------------------------------------------------------------------3. BEFORE AND AFTER ANALYSIS--------------------------------------------------------------------------------------------------------
/*

This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.

Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.

We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before

*/

-- 3.1 What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?

-- 2020-06-15 = week 25 - the baseline week where the Data Mart sustainable packaging changes came into effect - so its already considered in the "after period"
-- 4 weeks before = week 21-24
-- 4 weeks after = week 25-28 

SELECT
before_sales as [4_weeks_before_sales]
,after_sales as [4_weeks_after_sales]
,after_sales - before_sales as variation_value
,ROUND((after_sales-before_sales)/after_sales * 100,2) as variation_pct

FROM(
	 SELECT 
	 SUM(CASE
	 	WHEN week_date between DATEADD(WEEK,-4,'2020-06-15') AND DATEADD(WEEK,-1,'2020-06-15') THEN CAST(sales as float)
	 	ELSE 0
	 END) AS before_sales
	 ,SUM(CASE
	 	WHEN week_date between '2020-06-15' AND DATEADD(WEEK,+3,'2020-06-15') THEN CAST(sales as float)
	 	ELSE 0
	 END) AS after_sales
	 
	 FROM data_mart.clean_weekly_sales 
) a

-- 3.2 What about the entire 12 weeks before and after?
SELECT
before_sales as [12_weeks_before_sales]
,after_sales as [12_weeks_after_sales]
,after_sales - before_sales as variation_value
,ROUND((after_sales-before_sales)/after_sales * 100,2) as variation_pct

FROM(
	 SELECT 
	 SUM(CASE
	 	WHEN week_date between DATEADD(WEEK,-12,'2020-06-15') AND DATEADD(WEEK,-1,'2020-06-15') THEN CAST(sales as float)
	 	ELSE 0
	 END) AS before_sales
	 ,SUM(CASE
	 	WHEN week_date between '2020-06-15' AND DATEADD(WEEK,+11,'2020-06-15') THEN CAST(sales as float)
	 	ELSE 0
	 END) AS after_sales
	 
	 FROM data_mart.clean_weekly_sales 
) a


-- 3.3 How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

-- 1: comparing 4 weeks before and after for 2018,2019 and 2020
SELECT
year
,before_sales as [4_weeks_before_sales]
,after_sales as [4_weeks_after_sales]
,after_sales - before_sales as variation_value
,ROUND((after_sales-before_sales)/after_sales * 100,2) as variation_pct

FROM(
	 SELECT 
	 calendar_year as year
	 ,SUM(CASE
	 	WHEN week_number between (25-4) AND (25-1) THEN CAST(sales as float)
	 	ELSE 0
	 END) AS before_sales
	 ,SUM(CASE
	 	WHEN week_number between 25 and (25+3) THEN CAST(sales as float)
	 	ELSE 0
	 END) AS after_sales
	 
	 FROM data_mart.clean_weekly_sales 
	 GROUP BY calendar_year
) a

ORDER BY year


-- 2: comparing 12 weeks before and after for 2018,2019 and 2020
SELECT
year
,before_sales as [12_weeks_before_sales]
,after_sales as [12_weeks_after_sales]
,after_sales - before_sales as variation_value
,ROUND((after_sales-before_sales)/after_sales * 100,2) as variation_pct

FROM(
	 SELECT 
	 calendar_year as year
	 ,SUM(CASE
	 	WHEN week_number between (25-12) AND (25-1) THEN CAST(sales as float)
	 	ELSE 0
	 END) AS before_sales
	 ,SUM(CASE
	 	WHEN week_number between 25 and (25+11) THEN CAST(sales as float)
	 	ELSE 0
	 END) AS after_sales
	 
	 FROM data_mart.clean_weekly_sales 
	 GROUP BY calendar_year
) a

ORDER BY year


-------------------------------------------------------------------------------------------4. BONUS QUESTION----------------------------------------------------------------------------------------------------------------

/*	
	Which of the following areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
	   - region
	   - platform
	   - age_band
	   - demographic
	   - customer_type
*/

-- Region: Oceania has the highest negative impact in sales performance
SELECT
region
,before_sales as [12_weeks_before_sales]
,after_sales as [12_weeks_after_sales]
,after_sales - before_sales as variation_value
,ROUND((after_sales-before_sales)/after_sales * 100,2) as variation_pct

FROM(
	 SELECT 
	 region
	 ,SUM(CASE
	 	WHEN week_date between DATEADD(WEEK,-12,'2020-06-15') AND DATEADD(WEEK,-1,'2020-06-15') THEN CAST(sales as float)
	 	ELSE 0
	 END) AS before_sales
	 ,SUM(CASE
	 	WHEN week_date between '2020-06-15' AND DATEADD(WEEK,+11,'2020-06-15') THEN CAST(sales as float)
	 	ELSE 0
	 END) AS after_sales
	 
	 FROM data_mart.clean_weekly_sales 
	 GROUP BY region
) a

ORDER BY region;

-- Platform: Retail has the highest negative impact in sales performance. On the other hand Shopify has showed a nearly 7% growth, however this growth didn't compensate over the drop in Retail.
SELECT
platform
,before_sales as [12_weeks_before_sales]
,after_sales as [12_weeks_after_sales]
,after_sales - before_sales as variation_value
,ROUND((after_sales-before_sales)/after_sales * 100,2) as variation_pct

FROM(
	 SELECT 
	 platform
	 ,SUM(CASE
	 	WHEN week_date between DATEADD(WEEK,-12,'2020-06-15') AND DATEADD(WEEK,-1,'2020-06-15') THEN CAST(sales as float)
	 	ELSE 0
	 END) AS before_sales
	 ,SUM(CASE
	 	WHEN week_date between '2020-06-15' AND DATEADD(WEEK,+11,'2020-06-15') THEN CAST(sales as float)
	 	ELSE 0
	 END) AS after_sales
	 
	 FROM data_mart.clean_weekly_sales 
	 GROUP BY platform
) a

ORDER BY platform;

-- Age bad: Unknown group has the highest negative impact
SELECT
age_band
,before_sales as [12_weeks_before_sales]
,after_sales as [12_weeks_after_sales]
,after_sales - before_sales as variation_value
,ROUND((after_sales-before_sales)/after_sales * 100,2) as variation_pct

FROM(
	 SELECT 
	 age_band
	 ,SUM(CASE
	 	WHEN week_date between DATEADD(WEEK,-12,'2020-06-15') AND DATEADD(WEEK,-1,'2020-06-15') THEN CAST(sales as float)
	 	ELSE 0
	 END) AS before_sales
	 ,SUM(CASE
	 	WHEN week_date between '2020-06-15' AND DATEADD(WEEK,+11,'2020-06-15') THEN CAST(sales as float)
	 	ELSE 0
	 END) AS after_sales
	 
	 FROM data_mart.clean_weekly_sales 
	 GROUP BY age_band
) a

ORDER BY age_band;

-- Demographic: Unknown group has the highest negative impact
SELECT
demographic
,before_sales as [12_weeks_before_sales]
,after_sales as [12_weeks_after_sales]
,after_sales - before_sales as variation_value
,ROUND((after_sales-before_sales)/after_sales * 100,2) as variation_pct

FROM(
	 SELECT 
	 demographic
	 ,SUM(CASE
	 	WHEN week_date between DATEADD(WEEK,-12,'2020-06-15') AND DATEADD(WEEK,-1,'2020-06-15') THEN CAST(sales as float)
	 	ELSE 0
	 END) AS before_sales
	 ,SUM(CASE
	 	WHEN week_date between '2020-06-15' AND DATEADD(WEEK,+11,'2020-06-15') THEN CAST(sales as float)
	 	ELSE 0
	 END) AS after_sales
	 
	 FROM data_mart.clean_weekly_sales 
	 GROUP BY demographic
) a

ORDER BY demographic;

-- Customer Type: Guest customer group has the highest negative impact
SELECT
customer_type
,before_sales as [12_weeks_before_sales]
,after_sales as [12_weeks_after_sales]
,after_sales - before_sales as variation_value
,ROUND((after_sales-before_sales)/after_sales * 100,2) as variation_pct

FROM(
	 SELECT 
	 customer_type
	 ,SUM(CASE
	 	WHEN week_date between DATEADD(WEEK,-12,'2020-06-15') AND DATEADD(WEEK,-1,'2020-06-15') THEN CAST(sales as float)
	 	ELSE 0
	 END) AS before_sales
	 ,SUM(CASE
	 	WHEN week_date between '2020-06-15' AND DATEADD(WEEK,+11,'2020-06-15') THEN CAST(sales as float)
	 	ELSE 0
	 END) AS after_sales
	 
	 FROM data_mart.clean_weekly_sales 
	 GROUP BY customer_type
) a

ORDER BY customer_type;


-- CONCLUSION: Before and after analysis shows that overall the sustainable packing changes had a negative sales impact. 