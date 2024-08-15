-- CREATE TABLE AND IMPORT CSV FILE 

CREATE TABLE IF NOT EXISTS sales (
    invoice_id VARCHAR(30) PRIMARY KEY,
    branch VARCHAR(5) NOT NULL,
    city VARCHAR(30) NOT NULL,
    customer_type VARCHAR(30) NOT NULL,
    gender VARCHAR(30) NOT NULL,
    product_line VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    vat NUMERIC(6,4) NOT NULL,
    total NUMERIC(12,4) NOT NULL,
    date TIMESTAMP NOT NULL,
    time TIME NOT NULL,  -- Changed from TIMESTAMP to TIME since it only contains time values
    payment VARCHAR(20) NOT NULL,  -- Increased the length to accommodate "Credit card"
    cogs NUMERIC(10,2) NOT NULL,
    gross_margin_pct NUMERIC(5,2) NOT NULL,  -- Adjusted precision to reflect realistic percentage values
    gross_income NUMERIC(12,4) NOT NULL,
    rating NUMERIC(3,1) -- Increased precision to handle values up to 99.9
);


 --  ------------------------------------------------------------------------------------------
--  ---------------------Feature Engineering --------------------------------------------------

-- 1. time_of_date

SELECT
    time,
    (CASE
        WHEN time BETWEEN '00:00:00' AND '12:00:00' THEN 'Morning'
        WHEN time BETWEEN '12:01:00' AND '16:00:00' THEN 'Afternoon'
        ELSE 'Evening'
    END) AS time_of_day
FROM sales;

ALTER TABLE sales 
ADD COLUMN time_of_date VARCHAR(20)

UPDATE sales 
SET time_of_date = (CASE
        WHEN time BETWEEN '00:00:00' AND '12:00:00' THEN 'Morning'
        WHEN time BETWEEN '12:01:00' AND '16:00:00' THEN 'Afternoon'
        ELSE 'Evening'
    END) 

-- 2.day_name 
SELECT 
	date,
	TO_CHAR(date, 'Day') AS day_name
FROM sales 

ALTER TABLE sales
ADD COLUMN day_name VARCHAR(100) 

UPDATE sales
SET day_name = TO_CHAR(date, 'Day')

--  3. month_name 
SELECT 
date, 
TO_CHAR(date, 'Month') AS month_name 
FROM sales

ALTER TABLE sales 
ADD COLUMN month_name VARCHAR(20)

UPDATE sales
SET month_name = TO_CHAR(date, 'Month')

-- -------------------------------------------------------------------------------------------
--  -------------- Generic -------------------------------------------------------------------

-- 1. How many unique cities does the data have? 
SELECT 
	DISTINCT(city)
FROM sales
-- 2. In which city in each branch? 
SELECT 
	DISTINCT(city),
	branch
FROM sales

-- -------------------------------------------------------------------------------------------
--  -------------- Product -------------------------------------------------------------------

-- 1.How many unique product lines does the data have? 
SELECT COUNT(
	DISTINCT product_line )
FROM sales

-- 2. What is the most common payment method?
SELECT 
	payment,
	COUNT(payment) AS no_of_pm_method
FROM sales 
GROUP BY payment 
ORDER BY 2 DESC
LIMIT 1 

-- 3. What is the most selling product line?
SELECT 
	product_line,
	COUNT(product_line) as no_of_product_line
FROM sales 
GROUP BY product_line 
ORDER BY 2 DESC
LIMIT 1 

--4. What is the total revenue by month?
SELECT 
	month_name,
	SUM(total) AS total_revenue
FROM SALES
GROUP BY month_name
ORDER BY 2 DESC
LIMIT 1
-- 5. What month had the largest COGS?
-- $ COGS(Cost of goods sold) = unitsPrice * quantity $
SELECT 
	month_name AS month ,
	SUM(cogs) AS cogs
FROM sales
GROUP BY month_name
ORDER BY 2 DESC
LIMIT 1
--6. What product line had the largest revenue?
SELECT 
	product_line,
	SUM(total) AS total_revenue 
FROM sales
GROUP BY product_line 
ORDER BY total_revenue DESC 

-- 7. What is the city with the largest revenue?
SELECT 
	city,
	SUM(total) AS total_revenue 
FROM sales
GROUP BY city
ORDER BY total_revenue DESC 
-- 8. What product line had the largest VAT?
SELECT 
	product_line,
	ROUND(AVG(vat),2) AS avg_tax
FROM sales
GROUP BY product_line
ORDER BY 2 DESC 
-- 9.Fetch each product line and add a column to those product line showing "Good", "Bad". 
-- Good if its greater than average sales

ALTER TABLE sales 
ADD COLUMN evaluate_product_sale VARCHAR(10)

-- Step 1: Calculate the average total
WITH avg_total AS (
    SELECT AVG(total) AS avg_total_value
    FROM sales
)

-- Step 2: Update the evaluate_product_sale column based on the average total
UPDATE sales
SET evaluate_product_sale = 
    CASE
        WHEN total > (SELECT avg_total_value FROM avg_total) THEN 'Good'
        ELSE 'Bad'
    END;

-- 10. Which branch sold more products than average product sold?
SELECT 
	branch,
	SUM(quantity) AS qty
FROM sales
GROUP BY branch
HAVING SUM(quantity) > AVG(quantity)
-- 11. What is the most common product line by gender?
SELECT 
	gender,
	product_line,
	COUNT(gender) AS total_count
FROM sales
GROUP BY gender, product_line
ORDER BY total_count DESC
-- 12. What is the average rating of each product line?
SELECT 
	product_line,
	ROUND(AVG(rating),2) AS avg_rating
FROM sales 
GROUP BY product_line
ORDER BY 2 DESC

-- -------------------------------------------------------------------------------------------
--  -------------- SALE ----------------------------------------------------------------------

-- 1. Number of sales made in each time of the day per weekday
SELECT 
	time_of_date,
	COUNT(*) AS total_sales
FROM sales 
GROUP BY time_of_date
ORDER BY 2

-- 2. Which of the customer types brings the most revenue?
SELECT 
	customer_type, 
	SUM(total) as total_rev
FROM sales
GROUP BY customer_type 
ORDER BY 2 DESC
LIMIT 1

-- 3.Which city has the largest tax percent/ VAT (Value Added Tax)?
SELECT
	city, 
	ROUND(AVG(vat),2) AS total_vat
FROM sales
GROUP BY city 
ORDER BY 2 DESC
LIMIT 1

-- 4. Which customer type pays the most in VAT?
SELECT
	customer_type, 
	ROUND(AVG(vat),2) AS total_vat
FROM sales
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1

-- -------------------------------------------------------------------------------------------
--  -------------- CUSTOMER ------------------------------------------------------------------

-- 1. How many unique customer types does the data have?
SELECT
	DISTINCT(customer_type)
FROM sales

-- 2.How many unique payment methods does the data have?
SELECT 
	DISTINCT(payment) AS method_of_payment
FROM sales

-- 3.Which customer type buys the most?
SELECT 	
	customer_type,
	COUNT(*) AS count_payment
FROM sales
GROUP BY customer_type
ORDER BY 2 DESC
LIMIT 1

-- 4. What is the gender of most of the customers? 
SELECT 
	gender,
	COUNT(*) AS gender_count
FROM sales
GROUP BY gender
ORDER BY 2 DESC
LIMIT 1

-- 5. What is the gender distribution per branch?
SELECT 
	branch, 
	gender,
	COUNT(gender) AS count_gender
FROM sales
GROUP BY branch, gender
ORDER BY 3 DESC

-- 6. Which time of the day do customers give most ratings?
SELECT
	time_of_date,
	ROUND(AVG(rating),2) AS avg_rating
FROM sales
GROUP BY time_of_date
ORDER BY 2 DESC 
LIMIT 1 

-- 7. which time of the day do customers give most ratings per branch?
SELECT
	time_of_date,
	branch,
	ROUND(AVG(rating),2) AS avg_rating
FROM sales
GROUP BY time_of_date, branch
ORDER BY 3 DESC 
-- LIMIT 1 

-- 8. Which day fo the week has the best avg ratings?
SELECT 
	day_name,
	ROUND(AVG(rating),2) AS avg_rating
FROM sales
GROUP BY day_name
ORDER BY 2 DESC 
-- 9. Which day of the week has the best average ratings per branch?
SELECT 
	day_name,
	branch,
	ROUND(AVG(rating),2) AS avg_rating
FROM sales
GROUP BY day_name,branch
ORDER BY 3 DESC 