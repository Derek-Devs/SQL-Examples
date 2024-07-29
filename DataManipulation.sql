-- Step 1: Clean and Filter Data
WITH clean_sales AS (
    SELECT
        sale_id,
        customer_id,
        product_id,
        sale_date,
        quantity,
        sale_amount,
        status,
        ROW_NUMBER() OVER (PARTITION BY sale_id ORDER BY sale_date DESC) AS rn
    FROM
        raw_sales
    WHERE
        status = 'completed' AND
        customer_id IS NOT NULL AND
        product_id IS NOT NULL AND
        quantity > 0 AND
        sale_amount > 0
),
filtered_sales AS (
    SELECT
        sale_id,
        customer_id,
        product_id,
        sale_date,
        quantity,
        sale_amount
    FROM
        clean_sales
    WHERE
        rn = 1
),

-- Step 2: Transform Data - Normalize sale
