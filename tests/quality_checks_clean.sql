-- Quality checks on clean.orders. Run after scripts/01_clean.sql.
-- Each check returns the number of rows that break a rule.
-- Expected: failures = 0 on every line.

SELECT 'row count equals staging' AS check_name,
       ABS((SELECT COUNT(*) FROM clean.orders) - (SELECT COUNT(*) FROM staging.orders_raw)) AS failures

UNION ALL
SELECT 'order_item_id is unique',
       (SELECT COUNT(*) FROM (SELECT order_item_id FROM clean.orders GROUP BY order_item_id HAVING COUNT(*) > 1) t)

UNION ALL
SELECT 'shipping date is not before order date',
       COUNT(*)
FROM clean.orders
WHERE shipping_date < order_date

UNION ALL
SELECT 'zipcode is exactly 5 digits',
       COUNT(*)
FROM clean.orders
WHERE customer_zipcode IS NULL
   OR customer_zipcode NOT LIKE '[0-9][0-9][0-9][0-9][0-9]'

UNION ALL
SELECT 'state is a 2-letter code',
       COUNT(*)
FROM clean.orders
WHERE customer_state IS NULL
   OR LEN(customer_state) <> 2
   OR customer_state LIKE '%[0-9]%'

UNION ALL
SELECT 'customer country is one of the 2 expected values',
       COUNT(*)
FROM clean.orders
WHERE customer_country NOT IN ('Estados Unidos', 'Puerto Rico')
   OR customer_country IS NULL

UNION ALL
SELECT 'quantity, prices and totals are positive',
       COUNT(*)
FROM clean.orders
WHERE quantity < 1 OR product_price <= 0 OR sales <= 0 OR item_total <= 0

UNION ALL
SELECT 'discount rate is between 0 and 1',
       COUNT(*)
FROM clean.orders
WHERE discount_rate < 0 OR discount_rate > 1

UNION ALL
SELECT 'sales minus discount equals total (within 1 cent)',
       COUNT(*)
FROM clean.orders
WHERE ABS(sales - discount - item_total) > 0.01

UNION ALL
SELECT 'delay in days matches delivery status',
       COUNT(*)
FROM clean.orders
WHERE (delivery_status = 'Late delivery'    AND delay_days <= 0)
   OR (delivery_status = 'Shipping on time' AND delay_days <> 0)
   OR (delivery_status = 'Advance shipping' AND delay_days >= 0)

UNION ALL
SELECT 'late flag matches delivery status',
       COUNT(*)
FROM clean.orders
WHERE (delivery_status = 'Late delivery'  AND late_delivery_flag <> 1)
   OR (delivery_status <> 'Late delivery' AND late_delivery_flag <> 0)

UNION ALL
SELECT 'revenue matches staging',
       CASE WHEN ABS((SELECT SUM(item_total) FROM clean.orders)
                   - (SELECT SUM(TRY_CONVERT(float, [Order Item Total])) FROM staging.orders_raw)) > 1
            THEN 1 ELSE 0 END

UNION ALL
SELECT 'text columns are trimmed and not empty',
       COUNT(*)
FROM clean.orders
WHERE DATALENGTH(order_status)     <> DATALENGTH(TRIM(order_status))     OR order_status     = ''
   OR DATALENGTH(payment_type)     <> DATALENGTH(TRIM(payment_type))     OR payment_type     = ''
   OR DATALENGTH(shipping_mode)    <> DATALENGTH(TRIM(shipping_mode))    OR shipping_mode    = ''
   OR DATALENGTH(delivery_status)  <> DATALENGTH(TRIM(delivery_status))  OR delivery_status  = ''
   OR DATALENGTH(market)           <> DATALENGTH(TRIM(market))           OR market           = ''
   OR DATALENGTH(order_region)     <> DATALENGTH(TRIM(order_region))     OR order_region     = ''
   OR DATALENGTH(order_country)    <> DATALENGTH(TRIM(order_country))    OR order_country    = ''
   OR DATALENGTH(order_state)      <> DATALENGTH(TRIM(order_state))      OR order_state      = ''
   OR DATALENGTH(order_city)       <> DATALENGTH(TRIM(order_city))       OR order_city       = ''
   OR DATALENGTH(customer_segment) <> DATALENGTH(TRIM(customer_segment)) OR customer_segment = ''
   OR DATALENGTH(customer_city)    <> DATALENGTH(TRIM(customer_city))    OR customer_city    = ''
   OR DATALENGTH(product_name)     <> DATALENGTH(TRIM(product_name))     OR product_name     = ''
   OR DATALENGTH(product_image)    <> DATALENGTH(TRIM(product_image))    OR product_image    = ''
   OR DATALENGTH(category_name)    <> DATALENGTH(TRIM(category_name))    OR category_name    = ''
   OR DATALENGTH(department_name)  <> DATALENGTH(TRIM(department_name))  OR department_name  = '';