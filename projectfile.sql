## DATA ANALYSIS OF FAASO'S RESTAURANT

## Creating database
## Creating tables and Inserting data

create database fasoos;
drop table if exists driver;
use fasoos;
CREATE TABLE driver(driver_id integer,reg_date date); 

INSERT INTO driver(driver_id,reg_date) 
 VALUES (1,'2021-01-01'),
(2,'2021-01-03'),
(3,'2021-01-08'),
(4,'2021-01-15');


drop table if exists ingredients;
CREATE TABLE ingredients(ingredients_id integer,ingredients_name varchar(60)); 

INSERT INTO ingredients(ingredients_id ,ingredients_name) 
 VALUES (1,'BBQ Chicken'),
(2,'Chilli Sauce'),
(3,'Chicken'),
(4,'Cheese'),
(5,'Kebab'),
(6,'Mushrooms'),
(7,'Onions'),
(8,'Egg'),
(9,'Peppers'),
(10,'schezwan sauce'),
(11,'Tomatoes'),
(12,'Tomato Sauce');

drop table if exists rolls;
CREATE TABLE rolls(roll_id integer,roll_name varchar(30)); 

INSERT INTO rolls(roll_id ,roll_name) 
 VALUES (1	,'Non Veg Roll'),
(2	,'Veg Roll');

drop table if exists rolls_recipes;
CREATE TABLE rolls_recipes(roll_id integer,ingredients varchar(24)); 

INSERT INTO rolls_recipes(roll_id ,ingredients) 
 VALUES (1,'1,2,3,4,5,6,8,10'),
(2,'4,6,7,9,11,12');

drop table if exists driver_order;
CREATE TABLE driver_order(order_id integer,driver_id integer,pickup_time datetime,distance VARCHAR(7),duration VARCHAR(10),cancellation VARCHAR(23));
INSERT INTO driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation) 
 VALUES(1,1,'2021-01-01 18:15:34','20km','32 minutes',''),
(2,1,'2021-01-01 19:10:54','20km','27 minutes',''),
(3,1,'2021-01-03 00:12:37','13.4km','20 mins','NaN'),
(4,2,'2021-01-04 13:53:03','23.4','40','NaN'),
(5,3,'2021-01-08 21:10:57','10','15','NaN'),
(6,3,null,null,null,'Cancellation'),
(7,2,'2021-01-08 21:30:45','25km','25mins',null),
(8,2,'2021-01-10 00:15:02','23.4 km','15 minute',null),
(9,2,null,null,null,'Customer Cancellation'),
(10,1,'2021-01-11 18:50:20','10km','10minutes',null);


drop table if exists customer_orders;
CREATE TABLE customer_orders(order_id integer,customer_id integer,roll_id integer,not_include_items VARCHAR(4),extra_items_included VARCHAR(4),order_date datetime);
INSERT INTO customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date)
values (1,101,1,'','','2021-01-01  18:05:02'),
(2,101,1,'','','2021-01-01 19:00:52'),
(3,102,1,'','','2021-01-02 23:51:23'),
(3,102,2,'','NaN','2021-01-02 23:51:23'),
(4,103,1,'4','','2021-01-04 13:23:46'),
(4,103,1,'4','','2021-01-04 13:23:46'),
(4,103,2,'4','','2021-01-04 13:23:46'),
(5,104,1,null,'1','2021-01-08 21:00:29'),
(6,101,2,null,null,'2021-01-08 21:03:13'),
(7,105,2,null,'1','2021-01-08 21:20:29'),
(8,102,1,null,null,'2021-01-09 23:54:33'),
(9,103,1,'4','1,5','2021-01-10 11:22:59'),
(10,104,1,null,null,'2021-01-11 18:34:49'),
(10,104,1,'2,6','1,4','2021-01-11 18:34:49');

select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;

## Following business problems are solved which help to get better insights from the data

## 1. How many rolls were ordered?

select count(roll_id) from customer_orders;

## 2. How many unique customers orders were made?

select count(distinct customer_id) from customer_orders;

## 3. How many successful orders were delivered by each driver?

select driver_id , count(distinct order_id) from driver_order where cancellation not IN('Cancellation','Customer Cancellation')
group by driver_id;

## 4. How many of each type of roll was delivered?


SELECT roll_id
	,count(roll_id)
FROM customer_orders
WHERE order_id IN (
		SELECT order_id
		FROM (
			SELECT order_id
				,CASE 
					WHEN cancellation IN (
							'Cancellation'
							,'Customer Cancellation'
							)
						THEN 'c'
					ELSE 'nc'
					END AS order_cancel_details
			FROM driver_order
			) AS a
		WHERE a.order_cancel_details = 'nc'
		)
GROUP BY roll_id;


## 5. How many veg and non-veg rolls were ordered by each of the customer?

SELECT customer_id
	,roll_name
	,count(roll_name) AS roll_count
FROM rolls AS c
INNER JOIN customer_orders AS a ON a.roll_id = c.roll_id
GROUP BY roll_name
	,customer_id;


## 6. What are the maximum number of rolls delivered in a single order?

WITH cte
AS (
	SELECT order_id
		,count(roll_id) AS cnt
		,rank() OVER (
			ORDER BY count(roll_id) DESC
			) AS rnk
	FROM customer_orders
	WHERE order_id IN (
			SELECT order_id
			FROM (
				SELECT order_id
					,CASE 
						WHEN cancellation IN (
								'Cancellation'
								,'Customer Cancellation'
								)
							THEN 'c'
						ELSE 'nc'
						END AS order_cancel_details
				FROM driver_order
				) AS a
			WHERE a.order_cancel_details = 'nc'
			)
	GROUP BY order_id
	)
SELECT *
FROM cte
WHERE rnk = 1;



## cleaning data

CREATE TEMPORARY TABLE temp_customers_order AS
SELECT 
    order_id,
    customer_id,
    roll_id,
    CASE WHEN not_include_items IS NULL OR not_include_items = '' THEN 0 ELSE not_include_items END AS new_not_include_items,
    CASE WHEN extra_items_included IS NULL OR extra_items_included = '' OR extra_items_included = 'NaN' THEN 0 ELSE extra_items_included END AS new_extra_items_included,
    order_date 
FROM 
    customer_orders;


CREATE TEMPORARY TABLE temp_cte_driver_order AS
SELECT 
    order_id,
    driver_id,
    pickup_time,
    distance,
    duration,
    CASE WHEN cancellation IN ('Cancellation', 'Customer Cancellation') THEN 0 ELSE 1 END AS new_cancellation
FROM 
    driver_order;



## 7. For each customer,how many delivered rolls had atleast 1 change and how many had no changes?
select customer_id,change_no_change from
(SELECT *,
    CASE 
        WHEN new_not_include_items= 0 AND new_extra_items_included = 0 THEN 'no change'
        ELSE 'change'
    END AS change_no_change 
FROM temp_customers_order 
WHERE order_id IN (
    SELECT order_id 
    FROM temp_cte_driver_order 
    WHERE new_cancellation = 1
) )as a
group by customer_id,change_no_change;

## 8. How many rolls were delivered that had both extras and exclusions?

select change_no_change,count(change_no_change) as changes from
(SELECT *,
    CASE 
        WHEN new_not_include_items != 0 AND new_extra_items_included != 0 THEN 'both extra and exc'
        ELSE 'either one ext or exc'
    END AS change_no_change 
FROM temp_customers_order 
WHERE order_id IN (
    SELECT order_id 
    FROM temp_cte_driver_order 
    WHERE new_cancellation = 1
) )as a
group by change_no_change;

## 9. What was the total number of rolls ordered for each hour of the day?
select hour_range ,count(hour_range) as total_roll_ord_each_hr from
(select concat(Hour(order_date),'-',Hour(order_date)+1) as hour_range from customer_orders)as a
group by hour_range
order by hour_range;

## 10. What was the number of order for each day of the week?

select dayname(order_date) as day,count(distinct order_id)  from customer_orders 
group by day;

## 11. What was the average time in minutes it took for each driver to arrive at fassos hq to pickup the order?

WITH OrderDifferences AS (
    SELECT 
        a.order_id, 
        a.customer_id, 
        a.roll_id, 
        a.not_include_items, 
        a.extra_items_included, 
        a.order_date, 
        b.pickup_time, 
        TIMESTAMPDIFF(MINUTE, a.order_date, b.pickup_time) AS difference,
        b.driver_id
    FROM 
        customer_orders AS a
    INNER JOIN 
        driver_order AS b ON a.order_id = b.order_id
    WHERE 
        b.pickup_time IS NOT NULL
)

SELECT driver_id, SUM(difference) / COUNT(order_id) AS avg_time_difference
FROM (
    SELECT *, ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY difference) AS rnk  
    FROM OrderDifferences
) AS RankedData
WHERE rnk = 1
GROUP BY driver_id;

## 12. Is their any relationship between number of rolls and how long the order takes to prepare?
Select order_id,count(roll_id) as count_roll,sum(difference)/count(roll_id) as time_taken from 
(SELECT 
        a.order_id, 
        a.customer_id, 
        a.roll_id, 
        a.not_include_items, 
        a.extra_items_included, 
        a.order_date, 
        b.pickup_time, 
        TIMESTAMPDIFF(MINUTE, a.order_date, b.pickup_time) AS difference,
        b.driver_id
    FROM 
        customer_orders AS a
    INNER JOIN 
        driver_order AS b ON a.order_id = b.order_id
    WHERE 
        b.pickup_time IS NOT NULL)c
        group by order_id;
        
## 13. What was the average distance travelled for each customer?

Select customer_id,sum(distance)/count(order_id) as avg_distance from
(SELECT 
        a.order_id, 
        a.customer_id, 
        a.roll_id, 
        a.not_include_items, 
        a.extra_items_included, 
        a.order_date, 
        b.pickup_time, 
        TIMESTAMPDIFF(MINUTE, a.order_date, b.pickup_time) AS difference,
        b.distance
    FROM 
        customer_orders AS a
    INNER JOIN 
        driver_order AS b ON a.order_id = b.order_id
    WHERE 
        b.pickup_time IS NOT NULL)c
        group by customer_id;

## 14. What is the difference between shortest and largest delivery times for all the orders?

select max(duration)-min(duration) as difference from driver_order where duration is not null;
        
## 15. What is the average speed for each driver for each delivery and do you notice any trend for these values?

SELECT 
    b.driver_id,
    COUNT(a.roll_id) AS roll_count,
    a.order_id,
    AVG(b.distance / b.duration) AS avg_speed
FROM 
    driver_order AS b
INNER JOIN
    customer_orders a ON a.order_id = b.order_id
WHERE 
    b.distance IS NOT NULL
    AND b.duration IS NOT NULL
GROUP BY 
    b.driver_id,
    a.order_id;

## 16. What is the successful delivery percentage for each driver?

select * from temp_customers_order;
select * from temp_cte_driver_order;

SELECT 
    driver_id,
    SUM(CASE WHEN new_cancellation != 0 THEN 1 ELSE 0 END) / COUNT(driver_id) * 100.0 AS successful_delivery_percentage
FROM 
    temp_cte_driver_order
GROUP BY 
    driver_id;
