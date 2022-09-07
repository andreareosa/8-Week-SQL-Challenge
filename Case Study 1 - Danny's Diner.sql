
/*--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	8 Week SQL Challenge
	Case Study #1 - Danny's Diner
	LINK: https://8weeksqlchallenge.com/case-study-1/
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/


USE CaseStudy1
GO

CREATE SCHEMA dannys_diner

-----------------------------------------------------------------------------------------------CREATE DATASET--------------------------------------------------------------------------------------------
CREATE TABLE dannys_diner.sales(
	 customer_id nvarchar(1)
	,order_date date
	,product_id int
)

INSERT INTO dannys_diner.sales
VALUES 
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');

-- MENU
CREATE TABLE dannys_diner.menu(
	 product_id int
	,product_name nvarchar(5)
	,price int
)

INSERT INTO dannys_diner.menu
VALUES 
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');

-- MEMBERS
CREATE TABLE dannys_diner.members(
	 customer_id nvarchar(1)
	,join_date date
)

INSERT INTO dannys_diner.members
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


--------------------------------------------------------------------------------------CASE STUDY QUESTIONS-----------------------------------------------------------------------------------------------
-- 1.  What is the total amount each customer spent at the restaurant?
SELECT 
s.customer_id 
,SUM(m.price) as amount_spent

FROM dannys_diner.sales s
	INNER JOIN dannys_diner.menu m on s.product_id = m.product_id

GROUP BY s.customer_id

-- 2.  How many days has each customer visited the restaurant?
SELECT 
s.customer_id
,COUNT(DISTINCT s.order_date) as nr_days_visted

FROM dannys_diner.sales s

GROUP BY s.customer_id

-- 3.  What was the first item(s) from the menu purchased by each customer?
SELECT DISTINCT a.customer_id,a.product_name

FROM (SELECT 
	  s.customer_id
	  ,m.product_name
	  ,s.order_date
	  ,RANK() OVER (PARTITION BY customer_id ORDER BY order_date) as product_rank
	  
	  FROM dannys_diner.sales s
	  	INNER JOIN dannys_diner.menu m on s.product_id = m.product_id
) a

WHERE product_rank = 1

-- 4.  What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT TOP 1 m.product_name,COUNT(m.product_name) as times_purchased
FROM dannys_diner.sales s
	INNER JOIN dannys_diner.menu m on s.product_id = m.product_id

GROUP BY m.product_name
ORDER BY COUNT(m.product_name) DESC

-- 5.  Which item was the most popular for each customer?
SELECT 
b.customer_id
,b.product_name
,b.product_rank
FROM (
	  SELECT 
	  s.customer_id
	  ,m.product_name
	  ,RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(m.product_name) DESC) as product_rank
	  
	  FROM dannys_diner.sales s
		INNER JOIN dannys_diner.menu m on s.product_id = m.product_id
	  	  
	  GROUP BY s.customer_id,m.product_name
	   
) b
WHERE b.product_rank = 1

-- 6.  Which item was purchased first by the customer after they became a member?
SELECT 
a.customer_id
,a.product_name
FROM (
	  SELECT 
	  s.customer_id
	  ,s.order_date
	  ,m.product_name
	  ,RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) as item_rank
	  
	  FROM dannys_diner.sales s
	  	INNER JOIN dannys_diner.menu m on s.product_id = m.product_id 
	  	INNER JOIN dannys_diner.members ms on s.customer_id = ms.customer_id AND s.order_date >= ms.join_date 
) a
WHERE a.item_rank = 1

-- 7.  Which item was purchased just before the customer became a member?
SELECT a.customer_id,a.product_name
FROM(
	 SELECT 
	 s.customer_id
	 ,s.order_date
	 ,m.product_name
	 ,RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) as item_rank
	 
	 FROM dannys_diner.sales s
	 	INNER JOIN dannys_diner.members ms on s.customer_id = ms.customer_id 
	 	INNER JOIN dannys_diner.menu m on m.product_id = s.product_id
	 
	 WHERE s.order_date < ms.join_date
) a
WHERE item_rank = 1

-- 8.  What is the total items and amount spent for each member before they became a member?
SELECT 
s.customer_id
,COUNT(s.product_id) as total_items
,SUM(m.price) as amount_spent

FROM dannys_diner.sales s
	INNER JOIN dannys_diner.members ms on s.customer_id = ms.customer_id AND s.order_date < ms.join_date
	INNER JOIN dannys_diner.menu m on m.product_id = s.product_id

GROUP BY s.customer_id

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT
a.customer_id
,SUM(a.price * a.multiplier * a.points) as points
FROM (
	 SELECT 
	 s.customer_id
	 ,m.price 
	 ,CASE
	 	WHEN m.product_name = 'sushi' THEN 2
	     ELSE 1
	 END AS multiplier
	 ,10 as points
	 
	 FROM dannys_diner.sales s
	 	INNER JOIN dannys_diner.menu m on m.product_id = s.product_id
) a
GROUP BY a.customer_id

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH price_points AS ( 
	SELECT 
	s.customer_id
	,s.order_date
	,ms.join_date
	,m.price 
	,m.product_name
	,CASE
		WHEN m.product_name = 'sushi' THEN 20 * m.price
		WHEN s.order_date between ms.join_date and DATEADD(DAY,6,ms.join_date) THEN 20 * m.price
	    ELSE 10 * m.price
	END AS points
	
	FROM dannys_diner.sales s
		INNER JOIN dannys_diner.menu m on m.product_id = s.product_id
		INNER JOIN dannys_diner.members ms on s.customer_id = ms.customer_id
	
	WHERE s.order_date <= '2021-01-31'
)
SELECT 
customer_id
,SUM(points) as points

FROM price_points 
GROUP BY customer_id


----------------------------------------------------------------------------------------BONUS QUESTIONS--------------------------------------------------------------------------------------------------

-- Join All The Things
SELECT 
s.customer_id
,s.order_date
,m.product_name
,m.price
,CASE 
	WHEN s.order_date >= ms.join_date THEN 'Y'
	ELSE 'N'
END AS member

FROM dannys_diner.sales s
	INNER JOIN dannys_diner.menu m on s.product_id = m.product_id
	LEFT JOIN dannys_diner.members ms on s.customer_id = ms.customer_id

-- Rank All The Things
with join_all as (
	SELECT 
	s.customer_id
	,s.order_date
	,m.product_name
	,m.price
	,CASE 
		WHEN s.order_date >= ms.join_date THEN 'Y'
		ELSE 'N'
	END AS member
	
	FROM dannys_diner.sales s
		INNER JOIN dannys_diner.menu m on s.product_id = m.product_id
		LEFT JOIN dannys_diner.members ms on s.customer_id = ms.customer_id
)

SELECT 
customer_id
,order_date
,product_name
,price
,member
,CASE 
	WHEN member = 'Y' THEN RANK() OVER (PARTITION BY customer_id,member ORDER BY order_date)
	ELSE NULL
END AS ranking

FROM join_all 