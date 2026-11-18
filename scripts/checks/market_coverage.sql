SELECT m.market,
       COUNT(DISTINCT d.year_num * 100 + d.month_num)         AS months_with_orders,
       DATEDIFF(month, MIN(d.full_date), MAX(d.full_date)) + 1 AS months_in_range
FROM dw.fact_orders f
JOIN dw.dim_market m ON m.market_key = f.market_key
JOIN dw.dim_date   d ON d.date_key   = f.order_date_key
GROUP BY m.market
ORDER BY m.market;

