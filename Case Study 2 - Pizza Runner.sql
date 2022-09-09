
/*---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	8 Week SQL Challenge - Case Study #2 - Pizza Runner
	LINK: https://8weeksqlchallenge.com/case-study-2/

	RDBMS used: Microsfot SQL Server
	Author: André Areosa
	Date: 09/09/2022

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

USE CaseStudy1
GO

CREATE SCHEMA pizza_runner;

-----------------------------------------------------------------------------------------------CREATE DATASET----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TABLE 1: runners
DROP TABLE IF EXISTS pizza_runner.runners;
CREATE TABLE pizza_runner.runners(
	 runner_id int
	,registration_date date
);

INSERT INTO pizza_runner.runners
VALUES 
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');

-- TABLE 2: customer_orders
DROP TABLE IF EXISTS pizza_runner.customer_orders;
CREATE TABLE pizza_runner.customer_orders(
	 order_id int
	,customer_id int
	,pizza_id int
	,exclusions nvarchar(4)
	,extras nvarchar(4)
	,order_time datetime
);

INSERT INTO pizza_runner.customer_orders
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');

-- TABLE 3: runner_orders
DROP TABLE IF EXISTS pizza_runner.runner_orders;
CREATE TABLE pizza_runner.runner_orders(
	 order_id int
	,runner_id int
	,pickup_time nvarchar(19)
	,distance nvarchar(7)
	,duration nvarchar(10)
	,cancellation nvarchar(23)
);

INSERT INTO pizza_runner.runner_orders
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');

-- TABLE 4: pizza_names
DROP TABLE IF EXISTS pizza_runner.pizza_names;
CREATE TABLE pizza_runner.pizza_names(
	 pizza_id int
	,pizza_name text
);

INSERT INTO pizza_runner.pizza_names
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');

-- TABLE 5: pizza_recipes
DROP TABLE IF EXISTS pizza_runner.pizza_recipes;
CREATE TABLE pizza_runner.pizza_recipes (
   pizza_id int
  ,toppings text
);

INSERT INTO pizza_runner.pizza_recipes
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');

-- TABLE 6: pizza_toppings
DROP TABLE IF EXISTS pizza_runner.pizza_toppings;
CREATE TABLE pizza_runner.pizza_toppings (
   topping_id int
  ,topping_name text
)

INSERT INTO pizza_runner.pizza_toppings
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');


-----------------------------------------------------------------------------------------------DATA CLEANSING----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- 1) CLEAN CUSTOMER_ORDERS TABLE

-- Copy data from customer_orders to a new table to avoid any data loss of the original table
DROP TABLE IF EXISTS pizza_runner.customer_orders_cleaned;
SELECT *
INTO pizza_runner.customer_orders_cleaned
FROM pizza_runner.customer_orders

-- Update blank and 'null' values
UPDATE pizza_runner.customer_orders_cleaned
SET exclusions = CASE 
				     WHEN exclusions = '' OR exclusions = 'null' THEN NULL
					 ELSE exclusions 
					 END 
,extras =		CASE 
					WHEN extras = '' OR extras = 'null' THEN NULL
					ELSE extras 
					END 

-- Split exclusions and extras column as we have more than 1 value per column
ALTER TABLE pizza_runner.customer_orders_cleaned
ADD exclusions_2 int NULL, extras_2 int NULL

UPDATE pizza_runner.customer_orders_cleaned
SET exclusions = CASE 
					WHEN len(exclusions) > 1
					THEN substring(exclusions,1,charindex(',',exclusions)-1)
					ELSE exclusions
					END 
,exclusions_2 =  CASE
					WHEN len(exclusions) > 1
					THEN trim(substring(exclusions,charindex(',',exclusions)+1,len(exclusions)))
					ELSE NULL
					END 
,extras =		 CASE 
					WHEN len(extras) > 1
					THEN substring(extras,1,charindex(',',extras)-1)
					ELSE extras
					END 
,extras_2 =		 CASE
					WHEN len(extras) > 1
					THEN trim(substring(extras,charindex(',',extras)+1,len(extras)))
					ELSE NULL
					END 

-- Check data types
SELECT TABLE_NAME,COLUMN_NAME,DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'customer_orders_cleaned'

-- Fix data types
ALTER TABLE pizza_runner.customer_orders_cleaned
ALTER COLUMN exclusions int

ALTER TABLE pizza_runner.customer_orders_cleaned
ALTER COLUMN extras int

-- 2) CLEAN RUNNER ORDERS TABLE

-- Copy data from customer_orders to a new table to avoid any data loss of the original table
DROP TABLE IF EXISTS pizza_runner.runner_orders_cleaned
SELECT *
INTO pizza_runner.runner_orders_cleaned
FROM pizza_runner.runner_orders

-- Clean needed columns
UPDATE pizza_runner.runner_orders_cleaned
SET distance = 	CASE
					WHEN distance = 'null' THEN NULL
					WHEN distance LIKE '%km%' THEN TRIM('km' FROM distance)
					ELSE distance
					END 
,duration =		CASE
					WHEN duration = 'null' THEN NULL
					WHEN duration LIKE '%minutes' THEN TRIM('minutes' FROM duration)
					WHEN duration LIKE '%mins' THEN TRIM('mins' FROM duration)
					WHEN duration LIKE '%minute' THEN TRIM('minute' FROM duration)
					ELSE duration
					END
,pickup_time =	CASE
					WHEN pickup_time = 'null' THEN NULL
					ELSE pickup_time
					END
,cancellation = CASE
					WHEN cancellation = 'null' or cancellation = 'NaN' or cancellation = '' THEN NULL
					ELSE cancellation
					END

-- Check data types
SELECT TABLE_NAME,COLUMN_NAME,DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'runner_orders_cleaned'

-- Fix data types
ALTER TABLE pizza_runner.runner_orders_cleaned
ALTER COLUMN pickup_time datetime

ALTER TABLE pizza_runner.runner_orders_cleaned
ALTER COLUMN distance float

ALTER TABLE pizza_runner.runner_orders_cleaned
ALTER COLUMN duration int

SELECT *
FROM pizza_runner.pizza_toppings

-- 3) FIX OTHER TABLES
ALTER TABLE pizza_runner.pizza_names
ALTER COLUMN pizza_name nvarchar(20)

ALTER TABLE pizza_runner.pizza_toppings
ALTER COLUMN topping_name nvarchar(20)

-----------------------------------------------------------------------------------------------CASE STUDY QUESTIONS----------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------A. PIZZA METRICS------------------------------------------------------------------------------------------------------------

-- A1. How many pizzas were ordered?
SELECT COUNT(c.pizza_id) as pizzas_ordered
FROM pizza_runner.customer_orders_cleaned c

-- A2. How many unique orders were made?
SELECT COUNT(DISTINCT order_id) as unique_orders
FROM pizza_runner.customer_orders_cleaned c

-- A3. How many successful orders were delivered by each runner?
SELECT ro.runner_id,COUNT(ro.order_id) as nr_orders_delivered
FROM pizza_runner.runner_orders_cleaned ro 

WHERE ro.distance IS NOT NULL
GROUP BY ro.runner_id

-- A4. How many of each type of pizza was delivered?
SELECT p.pizza_name,COUNT(p.pizza_id) as nr_pizzas_delivered
FROM pizza_runner.customer_orders_cleaned c
	INNER JOIN pizza_runner.pizza_names p on c.pizza_id = p.pizza_id
	INNER JOIN pizza_runner.runner_orders_cleaned ro on c.order_id = ro.order_id

WHERE ro.distance IS NOT NULL
GROUP BY p.pizza_name

-- A5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT c.customer_id
,p.pizza_name
,COUNT(p.pizza_name) as nr_pizzas_ordered

FROM pizza_runner.customer_orders_cleaned c
	INNER JOIN pizza_runner.pizza_names p on c.pizza_id = p.pizza_id

GROUP BY c.customer_id,p.pizza_name
ORDER BY c.customer_id

-- A6. What was the maximum number of pizzas delivered in a single order?
SELECT TOP 1 c.order_id,COUNT(c.pizza_id) as pizzas_per_order
FROM pizza_runner.customer_orders_cleaned c
GROUP BY c.order_id
ORDER BY 2 DESC

-- A7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT a.customer_id
,SUM(a.pizzas_with_no_changes) as nr_pizzas_with_no_changes
,COUNT(a.pizza_id)-SUM(a.pizzas_with_no_changes) nr_pizzas_with_changes
FROM (
	  SELECT c.customer_id
	  ,c.pizza_id
	  ,CASE
	  	WHEN c.exclusions IS NULL AND c.exclusions_2 IS NULL AND c.extras IS NULL AND c.extras_2 IS NULL THEN 1
	  	ELSE 0
	  END AS pizzas_with_no_changes
	  
	  FROM pizza_runner.customer_orders_cleaned c
	  	INNER JOIN pizza_runner.runner_orders_cleaned ro on c.order_id = ro.order_id
	  
	  WHERE ro.distance IS NOT NULL
) a
GROUP BY a.customer_id


-- A8. How many pizzas were delivered that had both exclusions and extras?
SELECT COUNT(c.pizza_id) as nr_pizza_delivered

FROM pizza_runner.customer_orders_cleaned c
	INNER JOIN pizza_runner.runner_orders_cleaned ro on c.order_id = ro.order_id

WHERE ro.cancellation IS NULL 
	AND exclusions IS NOT NULL
	AND extras IS NOT NULL

-- A9. What was the total volume of pizzas ordered for each hour of the day?
SELECT 
DATEPART(HOUR,c.order_time) as hour_of_the_day
,COUNT(c.order_id) as nr_pizzas_ordered

FROM pizza_runner.customer_orders_cleaned c

GROUP BY DATEPART(HOUR,c.order_time) 


-- A10. What was the volume of orders for each day of the week?
SELECT 
DATENAME(DW,c.order_time) as day_of_the_week
,COUNT(c.order_id) as nr_pizzas_ordered

FROM pizza_runner.customer_orders_cleaned c

GROUP BY DATENAME(DW,c.order_time)

--------------------------------------------------------------------------------------B. RUNNER AND CUSTOMER EXPERIENCE-------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--B1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT CONCAT(DATENAME(WEEK,registration_date),' ','week') as year_week, COUNT(runner_id) as nr_runners
FROM pizza_runner.runners
GROUP BY CONCAT(DATENAME(WEEK,registration_date),' ','week')

--B2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT r.runner_id
,AVG(DATEDIFF(minute,c.order_time,r.pickup_time)) as avg_time

FROM pizza_runner.runner_orders_cleaned r
	INNER JOIN pizza_runner.customer_orders_cleaned c on r.order_id = c.order_id

WHERE distance IS NOT NULL

GROUP BY runner_id

--B3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
SELECT nr_pizzas,AVG(preparation_time) as preparation_time
FROM(	
	 SELECT 
	 c.order_id
	 ,COUNT(c.pizza_id) as nr_pizzas
	 ,DATEDIFF(minute,c.order_time,r.pickup_time) as preparation_time
	 
	 FROM pizza_runner.customer_orders_cleaned c
	 	INNER JOIN pizza_runner.runner_orders_cleaned r on c.order_id = r.order_id

	WHERE r.distance IS NOT NULL
	 
	 GROUP BY c.order_id,DATEDIFF(minute,c.order_time,r.pickup_time)
) a
GROUP BY nr_pizzas
-- + pizzas + preparation time therefore the number of pizzas seems to be correlated to the preparation time

--B4. What was the average distance travelled for each customer?
SELECT c.customer_id
,ROUND(AVG(distance),1) as avg_distance

FROM pizza_runner.runner_orders_cleaned r
	INNER JOIN pizza_runner.customer_orders_cleaned c on r.order_id = c.order_id

WHERE r.distance IS NOT NULL

GROUP BY c.customer_id

--B5. What was the difference between the longest and shortest delivery times for all orders?
SELECT MAX(a.delivery_time) - MIN(a.delivery_time) as diff_max_min
FROM( 	
	 SELECT DISTINCT r.order_id
	 ,DATEDIFF(MINUTE,c.order_time,r.pickup_time) as delivery_time
	 
	 FROM pizza_runner.runner_orders_cleaned r
	 	INNER JOIN pizza_runner.customer_orders_cleaned c on r.order_id = c.order_id
	 
	 WHERE r.distance IS NOT NULL
) a

--B6. What was the average speed for each runner for each delivery and do you notice any trend for these values? 															
SELECT runner_id
,order_id
,pickup_time
,distance
,ROUND(distance*60/duration,2) as speed_kmh

FROM pizza_runner.runner_orders_cleaned
WHERE distance IS NOT NULL 
	AND duration IS NOT NULL

ORDER BY runner_id,pickup_time
--Runners seem to increase their speed from orders to orders but the speed is not correlated to distance

--B7. What is the successful delivery percentage for each runner?
SELECT a.runner_id
,SUM(a.delivered_order)/CAST(COUNT(a.delivered_order) as FLOAT) * 100 as successful_delivery_prc

FROM(
	SELECT runner_id
	,order_id
	,CASE
		WHEN distance IS NOT NULL THEN 1
		ELSE 0
	END as delivered_order
	
	FROM pizza_runner.runner_orders_cleaned

) a

GROUP BY a.runner_id

--------------------------------------------------------------------------------------C. INGREDIENT OPTIMISATION -------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- C.1 What are the standard ingredients for each pizza?
SELECT table_name,column_name,data_type
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'pizza_recipes';

ALTER TABLE pizza_runner.pizza_recipes
ALTER COLUMN toppings nvarchar(30);

DROP TABLE IF EXISTS #pizza_recipes2
SELECT pizza_id,toppings,value as topping_id
INTO #pizza_recipes2
FROM pizza_runner.pizza_recipes
CROSS APPLY STRING_SPLIT(toppings,',');

SELECT p.pizza_name,STRING_AGG(t.topping_name,',') as standard_ingredients
FROM pizza_runner.pizza_names p
	INNER JOIN #pizza_recipes2 r on p.pizza_id = r.pizza_id
	INNER JOIN pizza_runner.pizza_toppings t on r.topping_id = t.topping_id

GROUP BY p.pizza_name

-- C.2 What was the most commonly added extra?
with extra_1 as (
				 SELECT p.topping_name,
				 COUNT(p.topping_name) as times_added
				 
				 FROM pizza_runner.customer_orders_cleaned c
					INNER JOIN pizza_runner.pizza_toppings p on c.extras = p.topping_id 

				 WHERE c.extras IS NOT NULL
				 GROUP BY p.topping_name
)


SELECT p2.topping_name,COUNT(p2.topping_name) as times_added

FROM pizza_runner.customer_orders_cleaned c
	INNER JOIN pizza_runner.pizza_toppings p2 on c.extras_2 = p2.topping_id 

WHERE c.extras IS NOT NULL
GROUP BY p2.topping_name,p2.topping_name


UNION ALL

SELECT * FROM extra_1

ORDER BY times_added DESC

-- C.3 What was the most common exclusion?
SELECT p.topping_name,
COUNT(p.topping_name) as times_removed

FROM pizza_runner.customer_orders_cleaned c
	INNER JOIN pizza_runner.pizza_toppings p on c.exclusions = p.topping_id 

WHERE c.exclusions IS NOT NULL
GROUP BY p.topping_name

UNION ALL

SELECT p2.topping_name
,COUNT(p2.topping_name) as times_removed

FROM pizza_runner.customer_orders_cleaned c
	INNER JOIN pizza_runner.pizza_toppings p2 on c.exclusions_2 = p2.topping_id 

WHERE c.exclusions IS NOT NULL
GROUP BY p2.topping_name,p2.topping_name

ORDER BY times_removed DESC

/* C.4 Generate an order item for each record in the customers_orders table in the format of one of the following:
			Meat Lovers
			Meat Lovers - Exclude Beef
			Meat Lovers - Extra Bacon
			Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers*/

SELECT p.pizza_name
,t.topping_name as extras
,t3.topping_name as extras_2
,t2.topping_name as exclusions
,t4.topping_name as exclusions_2
,CASE 
	WHEN t.topping_name IS NOT NULL 
		AND t2.topping_name IS NULL 
	THEN CONCAT(p.pizza_name,' - Extra ',t.topping_name)
	
	WHEN t.topping_name IS NOT NULL 
		AND t3.topping_name IS NOT NULL
		AND t2.topping_name IS NULL 
	THEN CONCAT(p.pizza_name,' - Extra ',t.topping_name,', ',t3.topping_name)
	
	WHEN t.topping_name IS NULL 
		AND t2.topping_name IS NOT NULL 
	THEN CONCAT(p.pizza_name,' - Exclude ',t2.topping_name)

	WHEN t.topping_name IS NULL 
		AND t2.topping_name IS NOT NULL 
		AND t4.topping_name IS NOT NULL
	THEN CONCAT(p.pizza_name,' - Exclude ',t2.topping_name,', ',t4.topping_name)

	WHEN t.topping_name IS NOT NULL 
			AND t3.topping_name IS NOT NULL 
			AND t2.topping_name IS NOT NULL 
			AND T4.topping_name IS NOT NULL 
	THEN CONCAT(p.pizza_name,' - Exclude ',t2.topping_name,', ',t4.topping_name,' - Extra ',t.topping_name,', ',t3.topping_name)
	
	WHEN t.topping_name IS NOT NULL 
			AND t3.topping_name IS NOT NULL 
			AND t2.topping_name IS NOT NULL 
			AND T4.topping_name IS NULL 
	THEN CONCAT(p.pizza_name,' - Exclude ',t2.topping_name,' - Extra ',t.topping_name,', ',t3.topping_name)

	ELSE p.pizza_name
END AS generated_order

FROM pizza_runner.customer_orders_cleaned c
	INNER JOIN pizza_runner.pizza_names p on c.pizza_id = p.pizza_id
	LEFT JOIN pizza_runner.pizza_toppings t on c.extras = t.topping_id
	LEFT JOIN pizza_runner.pizza_toppings t2 on c.exclusions = t2.topping_id
	LEFT JOIN pizza_runner.pizza_toppings t3 on c.extras_2 = t3.topping_id
	LEFT JOIN pizza_runner.pizza_toppings t4 on c.exclusions_2 = t4.topping_id

-- C.5 Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
--			For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

-- STEP 1: Create a new customer_orders table with a sk_row column to identify each row because we can have equal rows as one customer can order 2 equal pizzas in the same order
DROP TABLE IF EXISTS pizza_runner.customers_orders2;
SELECT *,ROW_NUMBER() OVER(ORDER BY order_id) as sk_row
INTO pizza_runner.customers_orders2
FROM pizza_runner.customer_orders_cleaned;

-- STEP 2: Count how many times each ingredient is used (count extras and removed exclusions)
DROP TABLE IF EXISTS #ordered_ingredients;
SELECT 
CONCAT(c.order_id,c.sk_row) as sk_pizza
,p.pizza_name as pizza_name
,CASE
	WHEN t.topping_name = t2.topping_name THEN CONCAT('2x',t.topping_name) -- extras
	WHEN t.topping_name = t4.topping_name THEN CONCAT('2x',t.topping_name) -- extras_2
	WHEN t.topping_name = t3.topping_name THEN '' -- exclusions
	WHEN t.topping_name = t5.topping_name THEN '' -- exclusions_2
	ELSE t.topping_name
END AS final_ingredients

INTO #ordered_ingredients
FROM pizza_runner.customers_orders2 c
	INNER JOIN pizza_runner.pizza_names p on c.pizza_id = p.pizza_id
	INNER JOIN #pizza_recipes2 r on p.pizza_id = r.pizza_id
	INNER JOIN pizza_runner.pizza_toppings t on r.topping_id = t.topping_id
	-- extras
	LEFT JOIN pizza_runner.pizza_toppings t2 on c.extras = t2.topping_id
	LEFT JOIN pizza_runner.pizza_toppings t4 on c.extras_2 = t4.topping_id
	-- exclusions
	LEFT JOIN pizza_runner.pizza_toppings t3 on c.exclusions = t3.topping_id
	LEFT JOIN pizza_runner.pizza_toppings t5 on c.exclusions_2 = t5.topping_id
;

-- STEP 3: Use RANK() to order ingredients_for_pizza the ingredient list for each pizza and reshape data using STRING_AGG to answer the question
SELECT 
sk_pizza
,CONCAT(a.pizza_name,': ',STRING_AGG(final_ingredients,',')) as ingredients_for_pizza

FROM(
	SELECT sk_pizza 
	,pizza_name
	,final_ingredients
	,CASE	
		WHEN final_ingredients = '' THEN NULL
		ELSE RANK() OVER(PARTITION BY sk_pizza ORDER BY pizza_name,final_ingredients)
	END AS ingredients_rank
	
	FROM #ordered_ingredients
) a
WHERE a.ingredients_rank IS NOT NULL
GROUP BY sk_pizza,a.pizza_name 

-- C.6 What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
SELECT a.pizza_ingredient
,SUM(a.ingredient_quantity) as quantity
FROM(
	 SELECT c.order_id
	 ,c.pizza_id
	 ,t.topping_name as pizza_ingredient
	 ,t2.topping_name as extras
	 ,t4.topping_name as extras_2
	 ,t3.topping_name as exclusions
	 ,t5.topping_name as exclusions_2
	 ,CASE 
	 	WHEN t.topping_name = t2.topping_name THEN 2
	 	WHEN t.topping_name = t4.topping_name THEN 2
	 	WHEN t.topping_name = t3.topping_name THEN 0
	 	WHEN t.topping_name = t5.topping_name THEN 0
	 	ELSE 1
	 END AS ingredient_quantity
	 
	 FROM pizza_runner.customer_orders_cleaned c
	 	INNER JOIN pizza_runner.runner_orders_cleaned r on c.order_id = r.order_id
	 	INNER JOIN #pizza_recipes2 r2 on c.pizza_id = r2.pizza_id
	 	LEFT JOIN pizza_runner.pizza_toppings t on r2.topping_id = t.topping_id
	 	LEFT JOIN pizza_runner.pizza_toppings t2 on c.extras = t2.topping_id
	 	LEFT JOIN pizza_runner.pizza_toppings t3 on c.exclusions = t3.topping_id
	 	LEFT JOIN pizza_runner.pizza_toppings t4 on c.extras_2 = t4.topping_id
	 	LEFT JOIN pizza_runner.pizza_toppings t5 on c.exclusions_2 = t5.topping_id
	 
	 WHERE 1=1 
	 	AND r.distance IS NOT NULL 
) a

GROUP BY a.pizza_ingredient
ORDER BY SUM(a.ingredient_quantity) DESC

--------------------------------------------------------------------------------------D. PRICING AND RATINGS------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- D1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
SELECT SUM(a.price) as sales_value
FROM(
     SELECT p.pizza_name
     ,CASE
     	WHEN p.pizza_name = 'Meatlovers' THEN 12
     	ELSE 10
     END AS price
     
     FROM pizza_runner.customer_orders_cleaned c
     	INNER JOIN pizza_runner.pizza_names p on c.pizza_id = p.pizza_id
		INNER JOIN pizza_runner.runner_orders_cleaned r on c.order_id = r.order_id

	WHERE r.distance IS NOT NULL
) a

-- D2. What if there was an additional $1 charge for any pizza extras? Add cheese is $1 extra
SELECT SUM(a.price) + SUM(a.extras_fee) as sales_value	
FROM(	
	 SELECT p.pizza_name
	 ,CASE
	 	WHEN p.pizza_name = 'Meatlovers' THEN 12
	 	ELSE 10
	 END AS price
	 ,CASE
	 	WHEN c.extras IS NOT NULL AND c.extras_2 IS NOT NULL THEN 2
		WHEN c.extras IS NOT NULL AND c.extras_2 IS NULL THEN 1
	 	ELSE 0
	END AS extras_fee
	 
	 FROM pizza_runner.customer_orders_cleaned c
	 	INNER JOIN pizza_runner.pizza_names p on c.pizza_id = p.pizza_id
		INNER JOIN pizza_runner.runner_orders_cleaned r on c.order_id = r.order_id

	WHERE r.distance IS NOT NULL
) a


-- D3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset:
-- generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.*/
DROP TABLE IF EXISTS pizza_runner.rating; 
CREATE TABLE pizza_runner.rating(
	 rating_id int
	,order_id int
	,rating int constraint check_rating CHECK(rating between 1 and 5)
	,comment nvarchar(50)
);

INSERT INTO pizza_runner.rating 
VALUES
( 1,1,2,'Took more time than estimated')
,(2,2,4,'')
,(3,3,4,'')
,(4,4,5,'Really good service')
,(5,5,2, '')
,(6,6, NULL,'') -- order not delivered
,(7,7,5,'')
,(8,8,4,'Great service')
,(9,9, NULL, '') -- order not delivered
,(10,10,1,'The pizza arrived upside down, really disappointed');



-- D4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
/*		- customer_id
		- order_id
		- runner_id
		- rating
		- order_time
		- pickup_time
		- Time between order and pickup
		- Delivery distance
		- Delivery duration
		- Average speed
		- Total number of pizzas*/

DROP TABLE IF EXISTS #general_info;

SELECT c.customer_id
,c.order_id
,r.runner_id
,rt.rating
,c.order_time
,r.pickup_time
,DATEDIFF(minute,c.order_time,r.pickup_time) as datediff_order_pickup
,r.duration
,r.distance
,ROUND(AVG(distance*60/duration),2) as avg_speed
,COUNT(c.pizza_id) as total_nr_pizzas
INTO #general_info

FROM pizza_runner.customer_orders_cleaned c
	INNER JOIN pizza_runner.runner_orders_cleaned r on c.order_id = r.order_id
	INNER JOIN pizza_runner.rating rt on c.order_id = rt.order_id

WHERE r.distance IS NOT NULL

GROUP BY c.customer_id
,c.order_id
,r.runner_id
,rt.rating
,c.order_time
,r.pickup_time
,DATEDIFF(minute,c.order_time,r.pickup_time)
,r.duration
,r.distance
;

SELECT *
FROM #general_info

-- D5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
DECLARE @total_amount float = (SELECT SUM(a.price) as sales_value
						 FROM(
						      SELECT p.pizza_name
						      ,CASE
						      	WHEN p.pizza_name = 'Meatlovers' THEN 12
						      	ELSE 10
						      END AS price
						      
						      FROM pizza_runner.customer_orders_cleaned c
						      	INNER JOIN pizza_runner.pizza_names p on c.pizza_id = p.pizza_id
						 		INNER JOIN pizza_runner.runner_orders_cleaned r on c.order_id = r.order_id
						 
						 	WHERE r.distance IS NOT NULL
						 ) a
						 )



SELECT @total_amount - (SUM(r.distance) * 0.3) as final_sales_value
FROM pizza_runner.runner_orders_cleaned r


--------------------------------------------------------------------------------------E. BONUS QUESTIONS----------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- If Danny wants to expand his range of pizzas - how would this impact the existing data design?
-- Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?
INSERT INTO pizza_runner.pizza_names
VALUES
(3,'Supreme')

INSERT INTO pizza_runner.pizza_recipes
VALUES
(3,'1,2,3,4,5,6,7,8,9,10,11,12')