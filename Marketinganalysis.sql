-- 1. Calculate campaign performance and ROI metrics
WITH campaign_performance AS (
    SELECT
        c.campaign_id,
        c.campaign_name,
        COUNT(DISTINCT cl.click_id) AS total_clicks,
        COUNT(DISTINCT p.purchase_id) AS total_purchases,
        SUM(p.amount) AS total_revenue,
        c.budget,
        (SUM(p.amount) - c.budget) AS roi
    FROM
        campaigns c
        LEFT JOIN clicks cl ON c.campaign_id = cl.campaign_id
        LEFT JOIN purchases p ON c.campaign_id = p.campaign_id
    GROUP BY
        c.campaign_id, c.campaign_name, c.budget
),
customer_engagement AS (
    SELECT
        c.customer_id,
        c.name AS customer_name,
        COUNT(DISTINCT cl.click_id) AS total_clicks,
        COUNT(DISTINCT p.purchase_id) AS total_purchases,
        CASE
            WHEN COUNT(DISTINCT cl.click_id) = 0 THEN 0
            ELSE COUNT(DISTINCT p.purchase_id) * 1.0 / COUNT(DISTINCT cl.click_id)
        END AS conversion_rate
    FROM
        customers c
        LEFT JOIN clicks cl ON c.customer_id = cl.customer_id
        LEFT JOIN purchases p ON c.customer_id = p.customer_id
    GROUP BY
        c.customer_id, c.name
),
campaign_top_products AS (
    SELECT
        p.product_id,
        pr.product_name,
        pr.category,
        COUNT(DISTINCT p.purchase_id) AS total_sales,
        SUM(p.amount) AS total_revenue,
        c.campaign_name
    FROM
        purchases p
        JOIN products pr ON p.product_id = pr.product_id
        JOIN campaigns c ON p.campaign_id = c.campaign_id
    GROUP BY
        p.product_id, pr.product_name, pr.category, c.campaign_name
    ORDER BY
        total_revenue DESC
    LIMIT 10
),
campaign_performance_over_time AS (
    SELECT
        c.campaign_id,
        c.campaign_name,
        DATE_TRUNC('month', p.purchase_date) AS month,
        COUNT(DISTINCT p.purchase_id) AS total_purchases,
        SUM(p.amount) AS total_revenue
    FROM
        campaigns c
        JOIN purchases p ON c.campaign_id = p.campaign_id
    GROUP BY
        c.campaign_id, c.campaign_name, DATE_TRUNC('month', p.purchase_date)
)
SELECT
    cp.campaign_name,
    cp.total_clicks,
    cp.total_purchases,
    cp.total_revenue,
    cp.budget,
    cp.roi,
    ce.customer_name,
    ce.total_clicks AS customer_clicks,
    ce.total_purchases AS customer_purchases,
    ce.conversion_rate,
    ctp.product_name,
    ctp.category,
    ctp.total_sales AS product_sales,
    ctp.total_revenue AS product_revenue,
    cpot.month,
    cpot.total_purchases AS monthly_purchases,
    cpot.total_revenue AS monthly_revenue
FROM
    campaign_performance cp
    LEFT JOIN customer_engagement ce ON ce.total_clicks > 0
    LEFT JOIN campaign_top_products ctp ON cp.campaign_name = ctp.campaign_name
    LEFT JOIN campaign_performance_over_time cpot ON cp.campaign_id = cpot.campaign_id
ORDER BY
    cp.campaign_name, ctp.total_revenue DESC, cpot.month;

-- The query combines campaign performance, customer engagement, top products, and campaign performance over time.
