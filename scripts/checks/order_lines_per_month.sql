SELECT d.year_num, d.month_num,
       COUNT(*)                                         AS lines,
       COUNT(DISTINCT f.order_id)                       AS orders,
       ROUND(COUNT(*) / COUNT(DISTINCT f.order_id), 2)  AS lines_per_order,
       ROUND(SUM(f.item_total), 2)                      AS revenue,
       ROUND(SUM(f.item_total) / COUNT(*), 2)           AS revenue_per_line
FROM dw.fact_order_items f
JOIN dw.dim_date d ON d.date_key = f.order_date_key
WHERE d.date_key >= 20170601
GROUP BY d.year_num, d.month_num
ORDER BY d.year_num, d.month_num;

