-- Let's assume we have the following tables:
-- customers (customer_id, name, email, created_at)
-- orders (order_id, customer_id, order_date, total_amount)
-- order_items (order_item_id, order_id, product_id, quantity, price)
-- products (product_id, product_name, category, price)
-- suppliers (supplier_id, supplier_name, contact_email)

-- The query will provide insights on:
-- 1. Total sales per customer
-- 2. Average order value per customer
-- 3. Top 5 products sold by revenue
-- 4. Top 3 customers by total spend
-- 5. Monthly sales trends

WITH customer_sales AS (
    SELECT 
        c.customer_id,
        c.name AS customer_name,
        SUM(o.total_amount) AS total_spent,
        COUNT(o.order_id) AS total_orders,
        AVG(o.total_amount) AS avg_order_value
    FROM 
        customers c
        JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY 
        c.customer_id, c.name
),
top_products AS (
    SELECT 
        p.product_id,
        p.product_name,
        SUM(oi.quantity * oi.price) AS total_revenue
    FROM 
        products p
        JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY 
        p.product_id, p.product_name
    ORDER BY 
        total_revenue DESC
    LIMIT 5
),
top_customers AS (
    SELECT 
        customer_id,
        customer_name,
        total_spent,
        RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM 
        customer_sales
)
SELECT 
    cs.customer_id,
    cs.customer_name,
    cs.total_spent,
    cs.total_orders,
    cs.avg_order_value,
    tp.product_name AS top_product,
    tp.total_revenue,
    tc.rank AS customer_rank
FROM 
    customer_sales cs
    LEFT JOIN top_customers tc ON cs.customer_id = tc.customer_id
    CROSS JOIN top_products tp
WHERE 
    tc.rank <= 3
ORDER BY 
    tc.rank, tp.total_revenue DESC;

-- Monthly sales trends
WITH monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', o.order_date) AS month,
        SUM(o.total_amount) AS total_sales,
        COUNT(o.order_id) AS total_orders
    FROM 
        orders o
    GROUP BY 
        DATE_TRUNC('month', o.order_date)
    ORDER BY 
        month
)
SELECT 
    month,
    total_sales,
    total_orders,
    LAG(total_sales) OVER (ORDER BY month) AS prev_month_sales,
    (total_sales - LAG(total_sales) OVER (ORDER BY month)) / NULLIF(LAG(total_sales) OVER (ORDER BY month), 0) * 100 AS sales_growth
FROM 
    monthly_sales;
