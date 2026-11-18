SELECT m.market,
       COUNT(DISTINCT d.year_num * 100 + d.month_num)         AS months_with_orders,
       DATEDIFF(month, MIN(d.full_date), MAX(d.full_date)) + 1 AS months_in_range
FROM dw.fact_orders f
JOIN dw.dim_market m ON m.market_key = f.market_key
JOIN dw.dim_date   d ON d.date_key   = f.order_date_key
GROUP BY m.market
ORDER BY m.market;



SELECT sm.shipping_mode,
       COUNT(*)                         AS orders,
       SUM(f.late_delivery_flag)        AS late_orders,
       MIN(f.days_shipping_scheduled)   AS min_scheduled,
       MAX(f.days_shipping_scheduled)   AS max_scheduled,
       MIN(f.days_shipping_real)        AS min_real,
       MAX(f.days_shipping_real)        AS max_real,
       MIN(f.delay_days)                AS min_delay,
       MAX(f.delay_days)                AS max_delay
FROM dw.fact_orders f
JOIN dw.dim_shipping_mode sm ON sm.shipping_mode_key = f.shipping_mode_key
JOIN dw.dim_order_status  s  ON s.order_status_key   = f.order_status_key
WHERE s.is_kpi_order = 1
GROUP BY sm.shipping_mode
ORDER BY sm.shipping_mode;