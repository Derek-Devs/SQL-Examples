-- Step 1: Predict Future Demand using a simple moving average
WITH product_sales AS (
    SELECT
        s.warehouse_id,
        s.product_id,
        DATE_TRUNC('month', s.sale_date) AS sale_month,
        SUM(s.quantity) AS total_sales
    FROM
        sales s
    GROUP BY
        s.warehouse_id,
        s.product_id,
        DATE_TRUNC('month', s.sale_date)
),
predicted_demand AS (
    SELECT
        ps.warehouse_id,
        ps.product_id,
        AVG(ps.total_sales) OVER (
            PARTITION BY ps.warehouse_id, ps.product_id
            ORDER BY ps.sale_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS avg_monthly_demand
    FROM
        product_sales ps
),

-- Step 2: Calculate Optimal Reorder Points
reorder_points AS (
    SELECT
        sl.warehouse_id,
        sl.product_id,
        sl.stock_level,
        sl.last_restock_date,
        pd.avg_monthly_demand,
        (pd.avg_monthly_demand * 1.5) AS safety_stock,
        (pd.avg_monthly_demand * 2) AS reorder_point
    FROM
        stock_levels sl
        JOIN predicted_demand pd ON sl.warehouse_id = pd.warehouse_id AND sl.product_id = pd.product_id
),

-- Step 3: Generate Replenishment Orders for products that need restocking
replenishment_orders AS (
    SELECT
        rp.warehouse_id,
        rp.product_id,
        rp.stock_level,
        rp.avg_monthly_demand,
        rp.reorder_point,
        rp.safety_stock,
        (rp.reorder_point - rp.stock_level) AS reorder_quantity
    FROM
        reorder_points rp
    WHERE
        rp.stock_level < rp.reorder_point
)

-- Final Step: Insert Replenishment Orders into the replenishments table
INSERT INTO replenishments (warehouse_id, product_id, replenishment_date, quantity)
SELECT
    ro.warehouse_id,
    ro.product_id,
    CURRENT_DATE AS replenishment_date,
    ro.reorder_quantity
FROM
    replenishment_orders ro;

-- The query predicts future demand, calculates reorder points, and generates replenishment orders.
