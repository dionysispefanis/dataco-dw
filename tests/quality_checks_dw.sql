-- Quality checks on the dw layer. Run after scripts/02_dw_dimensions.sql
-- and scripts/03_dw_facts.sql.
-- Each check returns the number of rows that break a rule.
-- Expected: failures = 0 on every line.

-- Dimensions: one row per distinct value in clean.orders
SELECT 'dim_date has one row per day' AS check_name,
       ABS((SELECT COUNT(*) FROM dw.dim_date)
         - (DATEDIFF(day, (SELECT MIN(order_date) FROM clean.orders),
                          (SELECT MAX(order_date) FROM clean.orders)) + 1)) AS failures

UNION ALL
SELECT 'dim_shipping_mode has one row per shipping mode',
       ABS((SELECT COUNT(*) FROM dw.dim_shipping_mode)
         - (SELECT COUNT(DISTINCT shipping_mode) FROM clean.orders))

UNION ALL
SELECT 'dim_order_status has one row per order status',
       ABS((SELECT COUNT(*) FROM dw.dim_order_status)
         - (SELECT COUNT(DISTINCT order_status) FROM clean.orders))

UNION ALL
SELECT 'dim_product has one row per product',
       ABS((SELECT COUNT(*) FROM dw.dim_product)
         - (SELECT COUNT(DISTINCT product_id) FROM clean.orders))

UNION ALL
SELECT 'dim_customer has one row per customer',
       ABS((SELECT COUNT(*) FROM dw.dim_customer)
         - (SELECT COUNT(DISTINCT customer_id) FROM clean.orders))

UNION ALL
SELECT 'dim_market has one row per delivery location',
       ABS((SELECT COUNT(*) FROM dw.dim_market)
         - (SELECT COUNT(*) FROM (
                SELECT DISTINCT market, order_region, order_country, order_state, order_city
                FROM clean.orders) t))

-- Facts: same number of rows as the clean layer
UNION ALL
SELECT 'fact_order_items has one row per order line',
       ABS((SELECT COUNT(*) FROM dw.fact_order_items)
         - (SELECT COUNT(*) FROM clean.orders))

UNION ALL
SELECT 'fact_orders has one row per order',
       ABS((SELECT COUNT(*) FROM dw.fact_orders)
         - (SELECT COUNT(DISTINCT order_id) FROM clean.orders))

UNION ALL
SELECT 'revenue in fact_order_items matches clean',
       CASE WHEN (SELECT SUM(item_total) FROM dw.fact_order_items)
               <> (SELECT SUM(item_total) FROM clean.orders)
            THEN 1 ELSE 0 END

-- Keys: every key in a fact exists in its dimension
UNION ALL
SELECT 'fact_order_items has no orphan keys',
       COUNT(*)
FROM dw.fact_order_items f
LEFT JOIN dw.dim_product      p ON p.product_key      = f.product_key
LEFT JOIN dw.dim_customer     c ON c.customer_key     = f.customer_key
LEFT JOIN dw.dim_date         d ON d.date_key         = f.order_date_key
LEFT JOIN dw.dim_market       m ON m.market_key       = f.market_key
LEFT JOIN dw.dim_order_status s ON s.order_status_key = f.order_status_key
WHERE p.product_key IS NULL OR c.customer_key IS NULL OR d.date_key IS NULL
   OR m.market_key IS NULL OR s.order_status_key IS NULL

UNION ALL
SELECT 'fact_orders has no orphan keys',
       COUNT(*)
FROM dw.fact_orders f
LEFT JOIN dw.dim_customer      c  ON c.customer_key      = f.customer_key
LEFT JOIN dw.dim_date          d  ON d.date_key          = f.order_date_key
LEFT JOIN dw.dim_shipping_mode sm ON sm.shipping_mode_key = f.shipping_mode_key
LEFT JOIN dw.dim_market        m  ON m.market_key        = f.market_key
LEFT JOIN dw.dim_order_status  s  ON s.order_status_key  = f.order_status_key
WHERE c.customer_key IS NULL OR d.date_key IS NULL OR sm.shipping_mode_key IS NULL
   OR m.market_key IS NULL OR s.order_status_key IS NULL

-- Both facts agree with each other
UNION ALL
SELECT 'every order line belongs to an order',
       COUNT(*)
FROM dw.fact_order_items i
LEFT JOIN dw.fact_orders o ON o.order_id = i.order_id
WHERE o.order_id IS NULL

UNION ALL
SELECT 'every order has at least one order line',
       COUNT(*)
FROM dw.fact_orders o
WHERE NOT EXISTS (SELECT 1 FROM dw.fact_order_items i WHERE i.order_id = o.order_id)

UNION ALL
SELECT 'shared keys are the same in both facts',
       COUNT(*)
FROM dw.fact_order_items i
JOIN dw.fact_orders o ON o.order_id = i.order_id
WHERE i.customer_key     <> o.customer_key
   OR i.order_date_key   <> o.order_date_key
   OR i.market_key       <> o.market_key
   OR i.order_status_key <> o.order_status_key

-- Business rule
UNION ALL
SELECT 'late flag matches delivery status in fact_orders',
       COUNT(*)
FROM dw.fact_orders
WHERE (delivery_status = 'Late delivery'  AND late_delivery_flag <> 1)
   OR (delivery_status <> 'Late delivery' AND late_delivery_flag <> 0);

   