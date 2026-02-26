# CREATE A NEW DATABASE

CREATE DATABASE ecommerce_analysis;
USE ecommerce_analysis;

# CREATE TABLES

CREATE TABLE customers (
customer_id INT,
signup_date DATE,
city VARCHAR(50),
gender VARCHAR(20)
);

CREATE TABLE website_sessions (
    session_id INT,
    customer_id INT,
    visit_date DATE,
    page_viewed VARCHAR(100),
    source_ VARCHAR(50)
);

CREATE TABLE orders (
    order_id INT,
    customer_id INT,
    order_date DATE,
    payment_type VARCHAR(50),
    status_ VARCHAR(50)
);

CREATE TABLE order_items (
    order_id INT,
    product_id INT,
    quantity INT,
    price DECIMAL(10,2),
    discount DECIMAL(5,2),
    revenue DECIMAL(12,4),
    discount_percent DECIMAL(5,2),
    product_cost DECIMAL(10,2),
    profit DECIMAL(12,4),
    margin_percent DECIMAL(5,2),
    profit_type VARCHAR(50)
);

CREATE TABLE products (
    product_id INT,
    category VARCHAR(100),
    cost DECIMAL(10,2)
);

SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM website_sessions;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM order_items;
SELECT COUNT(*) FROM products;

# CUSTOMER FUNNEL & CONVERSION ANALYSIS:

# Total Visitors Count:
SELECT COUNT(DISTINCT customer_id) AS total_visitors
FROM website_sessions;

# Total Buyers Count:
SELECT COUNT(DISTINCT customer_id) AS total_buyers
FROM orders;

# Overall Conversion Rate:
SELECT 
    COUNT(DISTINCT o.customer_id) * 100.0 / 
    COUNT(DISTINCT w.customer_id) AS conversion_rate
FROM website_sessions w
LEFT JOIN orders o 
ON w.customer_id = o.customer_id;

# Conversion by Traffic Source:
SELECT 
    w.source_,
    COUNT(DISTINCT w.customer_id) AS visitors,
    COUNT(DISTINCT o.customer_id) AS buyers,
    COUNT(DISTINCT o.customer_id) * 100.0 /
    COUNT(DISTINCT w.customer_id) AS conversion_rate
FROM website_sessions w
LEFT JOIN orders o 
ON w.customer_id = o.customer_id
GROUP BY w.source_;

# CUSTOMER BEHAVIOUR ANALYSIS:

# Count Orders per Customer:
SELECT 
    customer_id,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY customer_id;

# Create Customer Segments (New vs Repeat):
SELECT 
    customer_id,
    COUNT(order_id) AS total_orders,
    CASE 
        WHEN COUNT(order_id) = 1 THEN 'New'
        ELSE 'Repeat'
    END AS customer_type
FROM orders
GROUP BY customer_id;

# Count New vs Repeat Customers:
WITH customer_orders AS (
    SELECT 
        customer_id,
        COUNT(order_id) AS total_orders
    FROM orders
    GROUP BY customer_id
)
SELECT 
    CASE 
        WHEN total_orders = 1 THEN 'New'
        ELSE 'Repeat'
    END AS customer_type,
    COUNT(*) AS customer_count
FROM customer_orders
GROUP BY customer_type;

# Revenue Contribution:
WITH customer_summary AS (
    SELECT 
        o.customer_id,
        SUM(oi.revenue) AS total_revenue,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM orders o
    JOIN order_items oi 
    ON o.order_id = oi.order_id
    GROUP BY o.customer_id
)
SELECT 
    CASE 
        WHEN total_orders = 1 THEN 'New'
        ELSE 'Repeat'
    END AS customer_type,
    COUNT(*) AS customers,
    SUM(total_revenue) AS total_revenue
FROM customer_summary
GROUP BY customer_type;

# Profit Contribution:
WITH customer_summary AS (
    SELECT 
        o.customer_id,
        SUM(oi.revenue) AS total_revenue,
        SUM(oi.profit) AS total_profit,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM orders o
    JOIN order_items oi 
    ON o.order_id = oi.order_id
    GROUP BY o.customer_id
)

SELECT 
    CASE 
        WHEN total_orders = 1 THEN 'New'
        ELSE 'Repeat'
    END AS customer_type,
    SUM(total_profit) AS total_profit
FROM customer_summary
GROUP BY customer_type;

# DISCOUNT & PRICING STRATEGY ANALYSIS:

# Create Discount Buckets:
SELECT 
    CASE 
        WHEN discount_percent < 10 THEN '0-10%'
        WHEN discount_percent < 20 THEN '10-20%'
        WHEN discount_percent < 30 THEN '20-30%'
        ELSE '30%+'
    END AS discount_bucket,
    COUNT(*) AS orders,
    SUM(revenue) AS total_revenue,
    SUM(profit) AS total_profit,
    AVG(margin_percent) AS avg_margin
FROM order_items
GROUP BY discount_bucket
ORDER BY discount_bucket;

# Identify Loss-Making Discount Range:
SELECT 
    discount_percent,
    SUM(profit) AS total_loss
FROM order_items
WHERE profit < 0
GROUP BY discount_percent
ORDER BY total_loss;

# CATEGORY & PRODUCT STRATEGY ANALYSIS:

# Join Product Category with Order Data:
SELECT 
    p.category,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.revenue) AS total_revenue,
    SUM(oi.profit) AS total_profit,
    AVG(oi.margin_percent) AS avg_margin
FROM order_items oi
JOIN products p 
ON oi.product_id = p.product_id
JOIN orders o
ON oi.order_id = o.order_id
GROUP BY p.category
ORDER BY total_revenue DESC;

# Discount Sensitivity by Category:
SELECT 
    p.category,
    AVG(oi.discount_percent) AS avg_discount,
    AVG(oi.margin_percent) AS avg_margin
FROM order_items oi
JOIN products p
ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY avg_discount DESC;

# Identify Loss-Making Categories:
SELECT 
    p.category,
    SUM(oi.profit) AS total_profit
FROM order_items oi
JOIN products p
ON oi.product_id = p.product_id
GROUP BY p.category
HAVING total_profit < 0;