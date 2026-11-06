-- Checks on staging.orders_raw, run before writing the clean layer.

-- 1. Dates
-- Question: do all dates convert to real dates?
-- Expected: 0 bad dates.
-- Found: 0 bad dates. Orders go from 2015-01-01 to 2018-01-31.
SELECT
    MIN(TRY_CONVERT(datetime, [order date (DateOrders)], 101)) AS first_order,
    MAX(TRY_CONVERT(datetime, [order date (DateOrders)], 101)) AS last_order,
    SUM(CASE WHEN TRY_CONVERT(datetime, [order date (DateOrders)], 101)    IS NULL THEN 1 ELSE 0 END) AS bad_order_dates,
    SUM(CASE WHEN TRY_CONVERT(datetime, [shipping date (DateOrders)], 101) IS NULL THEN 1 ELSE 0 END) AS bad_shipping_dates
FROM staging.orders_raw;
 
 
-- 2. Numbers
-- Question: does every non-empty value convert to a number?
-- Expected: 0 in every column.
-- Found: 0 in all 20 columns.
SELECT
    SUM(CASE WHEN [Days for shipping (real)]      IS NOT NULL AND TRY_CONVERT(float, [Days for shipping (real)])      IS NULL THEN 1 ELSE 0 END) AS days_real,
    SUM(CASE WHEN [Days for shipment (scheduled)] IS NOT NULL AND TRY_CONVERT(float, [Days for shipment (scheduled)]) IS NULL THEN 1 ELSE 0 END) AS days_sched,
    SUM(CASE WHEN [Benefit per order]             IS NOT NULL AND TRY_CONVERT(float, [Benefit per order])             IS NULL THEN 1 ELSE 0 END) AS benefit,
    SUM(CASE WHEN [Late_delivery_risk]            IS NOT NULL AND TRY_CONVERT(float, [Late_delivery_risk])            IS NULL THEN 1 ELSE 0 END) AS late_flag,
    SUM(CASE WHEN [Category Id]                   IS NOT NULL AND TRY_CONVERT(float, [Category Id])                   IS NULL THEN 1 ELSE 0 END) AS category_id,
    SUM(CASE WHEN [Customer Id]                   IS NOT NULL AND TRY_CONVERT(float, [Customer Id])                   IS NULL THEN 1 ELSE 0 END) AS customer_id,
    SUM(CASE WHEN [Customer Zipcode]              IS NOT NULL AND TRY_CONVERT(float, [Customer Zipcode])              IS NULL THEN 1 ELSE 0 END) AS cust_zip,
    SUM(CASE WHEN [Department Id]                 IS NOT NULL AND TRY_CONVERT(float, [Department Id])                 IS NULL THEN 1 ELSE 0 END) AS dept_id,
    SUM(CASE WHEN [Latitude]                      IS NOT NULL AND TRY_CONVERT(float, [Latitude])                      IS NULL THEN 1 ELSE 0 END) AS lat,
    SUM(CASE WHEN [Longitude]                     IS NOT NULL AND TRY_CONVERT(float, [Longitude])                     IS NULL THEN 1 ELSE 0 END) AS lon,
    SUM(CASE WHEN [Order Id]                      IS NOT NULL AND TRY_CONVERT(float, [Order Id])                      IS NULL THEN 1 ELSE 0 END) AS order_id,
    SUM(CASE WHEN [Order Item Discount]           IS NOT NULL AND TRY_CONVERT(float, [Order Item Discount])           IS NULL THEN 1 ELSE 0 END) AS discount,
    SUM(CASE WHEN [Order Item Discount Rate]      IS NOT NULL AND TRY_CONVERT(float, [Order Item Discount Rate])      IS NULL THEN 1 ELSE 0 END) AS discount_rate,
    SUM(CASE WHEN [Order Item Id]                 IS NOT NULL AND TRY_CONVERT(float, [Order Item Id])                 IS NULL THEN 1 ELSE 0 END) AS item_id,
    SUM(CASE WHEN [Order Item Profit Ratio]       IS NOT NULL AND TRY_CONVERT(float, [Order Item Profit Ratio])       IS NULL THEN 1 ELSE 0 END) AS profit_ratio,
    SUM(CASE WHEN [Order Item Quantity]           IS NOT NULL AND TRY_CONVERT(float, [Order Item Quantity])           IS NULL THEN 1 ELSE 0 END) AS quantity,
    SUM(CASE WHEN [Sales]                         IS NOT NULL AND TRY_CONVERT(float, [Sales])                         IS NULL THEN 1 ELSE 0 END) AS sales,
    SUM(CASE WHEN [Order Item Total]              IS NOT NULL AND TRY_CONVERT(float, [Order Item Total])              IS NULL THEN 1 ELSE 0 END) AS item_total,
    SUM(CASE WHEN [Product Card Id]               IS NOT NULL AND TRY_CONVERT(float, [Product Card Id])               IS NULL THEN 1 ELSE 0 END) AS product_id,
    SUM(CASE WHEN [Product Price]                 IS NOT NULL AND TRY_CONVERT(float, [Product Price])                 IS NULL THEN 1 ELSE 0 END) AS price
FROM staging.orders_raw;
 
 
-- 3. Ids
-- Question: are the ids whole numbers, and is Order Item Id unique?
-- Expected: total_rows = distinct_item_ids, and every *_bad = 0.
-- Found: 180519 = 180519, and every *_bad = 0.
SELECT
    COUNT(*)                                                           AS total_rows,
    COUNT(DISTINCT [Order Item Id])                                    AS distinct_item_ids,
    SUM(CASE WHEN [Order Id]        LIKE '%[^0-9]%' THEN 1 ELSE 0 END) AS order_id_bad,
    SUM(CASE WHEN [Order Item Id]   LIKE '%[^0-9]%' THEN 1 ELSE 0 END) AS item_id_bad,
    SUM(CASE WHEN [Customer Id]     LIKE '%[^0-9]%' THEN 1 ELSE 0 END) AS customer_id_bad,
    SUM(CASE WHEN [Product Card Id] LIKE '%[^0-9]%' THEN 1 ELSE 0 END) AS product_id_bad,
    SUM(CASE WHEN [Category Id]     LIKE '%[^0-9]%' THEN 1 ELSE 0 END) AS category_id_bad,
    SUM(CASE WHEN [Department Id]   LIKE '%[^0-9]%' THEN 1 ELSE 0 END) AS department_id_bad
FROM staging.orders_raw;
 

 
-- 4. Unusual characters in Order State
-- Question: which states contain characters outside the normal keyboard range?
-- Found: mostly valid accented names. Two problems showed up (see 6a and 6b).
SELECT DISTINCT [Order State]
FROM staging.orders_raw
WHERE [Order State] COLLATE Latin1_General_BIN2 LIKE '%[^ -~]%'
ORDER BY [Order State];
 
-- 4a. Hidden first character in "Šiauliai" and "Žilina"
-- Found with latin-1: codes 138 and 142 (invisible characters).
-- Found with cp1252: codes 352 and 381 (S and Z with a caron). The CSV is
-- therefore read as cp1252.
SELECT DISTINCT
    [Order State],
    LEN([Order State])              AS text_length,
    UNICODE(LEFT([Order State], 1)) AS first_char_code
FROM staging.orders_raw
WHERE [Order State] LIKE N'%iauliai' OR [Order State] LIKE N'%ilina';
 
-- 4b. "?" in text columns
-- The source file replaced characters that do not exist in cp1252 with "?".
-- They cannot be recovered.
-- Found: 6 values in Order State, 6 in Order City, none in the other columns.
SELECT 'Order City'       AS column_name, COUNT(DISTINCT [Order City])       AS values_with_question_mark FROM staging.orders_raw WHERE [Order City]       LIKE '%?%'
UNION ALL
SELECT 'Customer City',                   COUNT(DISTINCT [Customer City])                              FROM staging.orders_raw WHERE [Customer City]    LIKE '%?%'
UNION ALL
SELECT 'Customer State',                  COUNT(DISTINCT [Customer State])                             FROM staging.orders_raw WHERE [Customer State]   LIKE '%?%'
UNION ALL
SELECT 'Order Country',                   COUNT(DISTINCT [Order Country])                              FROM staging.orders_raw WHERE [Order Country]    LIKE '%?%'
UNION ALL
SELECT 'Customer Country',                COUNT(DISTINCT [Customer Country])                           FROM staging.orders_raw WHERE [Customer Country] LIKE '%?%'
UNION ALL
SELECT 'Order Region',                    COUNT(DISTINCT [Order Region])                               FROM staging.orders_raw WHERE [Order Region]     LIKE '%?%'
UNION ALL
SELECT 'Product Name',                    COUNT(DISTINCT [Product Name])                               FROM staging.orders_raw WHERE [Product Name]     LIKE '%?%'
UNION ALL
SELECT 'Category Name',                   COUNT(DISTINCT [Category Name])                              FROM staging.orders_raw WHERE [Category Name]    LIKE '%?%';
 
-- 4c. How many rows have a "?" in city or state
-- Found: 309 rows .
SELECT COUNT(*) AS rows_affected
FROM staging.orders_raw
WHERE [Order City] LIKE '%?%' OR [Order State] LIKE '%?%';
 
 
-- 5. Country names
-- Question: is the same country written in two different ways?
-- Found: customer country has 2 values (EE. UU. and Puerto Rico).
-- Delivery country has 164 values, and no country appears under two names.
-- The US is "EE. UU." in customer country but "Estados Unidos" in delivery country.
SELECT [Customer Country], COUNT(*) AS rows_count
FROM staging.orders_raw
GROUP BY [Customer Country]
ORDER BY rows_count DESC;
 
SELECT [Order Country], COUNT(*) AS rows_count
FROM staging.orders_raw
GROUP BY [Order Country]
ORDER BY [Order Country];
 
 
-- 6. Customer zipcode
-- Question: were leading zeros lost?
-- Found: Puerto Rico zipcodes always have 3 characters (69,373 rows).
-- US zipcodes have 4 characters in 6,135 rows and 5 in 105,008 rows.
-- 3 rows are empty. Zipcodes should have 5 digits, so zeros were lost.
SELECT
    [Customer Country],
    LEN([Customer Zipcode]) AS zip_length,
    COUNT(*)                AS rows_count
FROM staging.orders_raw
GROUP BY [Customer Country], LEN([Customer Zipcode])
ORDER BY [Customer Country], zip_length;
 
 
-- 7. Value ranges
-- Question: do the numbers make sense (no negative quantities, prices, days)?
-- Found: quantity 1-5, discount rate 0-0.25, discount 0-500, sales, total and
-- price all positive, days real 0-6, days scheduled 0-4.
-- Profit goes down to -4274.98. That is how the source is, it is not corrected.
SELECT 'quantity' AS column_name, MIN(TRY_CONVERT(float, [Order Item Quantity])) AS min_value, MAX(TRY_CONVERT(float, [Order Item Quantity])) AS max_value FROM staging.orders_raw
UNION ALL
SELECT 'discount_rate', MIN(TRY_CONVERT(float, [Order Item Discount Rate])), MAX(TRY_CONVERT(float, [Order Item Discount Rate])) FROM staging.orders_raw
UNION ALL
SELECT 'discount', MIN(TRY_CONVERT(float, [Order Item Discount])), MAX(TRY_CONVERT(float, [Order Item Discount])) FROM staging.orders_raw
UNION ALL
SELECT 'sales', MIN(TRY_CONVERT(float, [Sales])), MAX(TRY_CONVERT(float, [Sales])) FROM staging.orders_raw
UNION ALL
SELECT 'item_total', MIN(TRY_CONVERT(float, [Order Item Total])), MAX(TRY_CONVERT(float, [Order Item Total])) FROM staging.orders_raw
UNION ALL
SELECT 'product_price', MIN(TRY_CONVERT(float, [Product Price])), MAX(TRY_CONVERT(float, [Product Price])) FROM staging.orders_raw
UNION ALL
SELECT 'profit', MIN(TRY_CONVERT(float, [Benefit per order])), MAX(TRY_CONVERT(float, [Benefit per order])) FROM staging.orders_raw
UNION ALL
SELECT 'profit_ratio', MIN(TRY_CONVERT(float, [Order Item Profit Ratio])), MAX(TRY_CONVERT(float, [Order Item Profit Ratio])) FROM staging.orders_raw
UNION ALL
SELECT 'days_real', MIN(TRY_CONVERT(float, [Days for shipping (real)])), MAX(TRY_CONVERT(float, [Days for shipping (real)])) FROM staging.orders_raw
UNION ALL
SELECT 'days_scheduled', MIN(TRY_CONVERT(float, [Days for shipment (scheduled)])), MAX(TRY_CONVERT(float, [Days for shipment (scheduled)])) FROM staging.orders_raw
UNION ALL
SELECT 'latitude', MIN(TRY_CONVERT(float, [Latitude])), MAX(TRY_CONVERT(float, [Latitude])) FROM staging.orders_raw
UNION ALL
SELECT 'longitude', MIN(TRY_CONVERT(float, [Longitude])), MAX(TRY_CONVERT(float, [Longitude])) FROM staging.orders_raw;
 


 
 
-- 8. Amounts
-- Question: does Sales minus Discount equal Order Item Total?
-- Found: the biggest difference in the whole file is one cent (the source
-- rounds half cents). No row differs by more than 0.015. No correction needed.
SELECT
    SUM(CASE WHEN d > 0.01  THEN 1 ELSE 0 END) AS rows_over_001,
    SUM(CASE WHEN d > 0.015 THEN 1 ELSE 0 END) AS rows_over_0015,
    MAX(d)                                     AS max_diff
FROM (
    SELECT ABS(TRY_CONVERT(float, [Sales])
             - TRY_CONVERT(float, [Order Item Discount])
             - TRY_CONVERT(float, [Order Item Total])) AS d
    FROM staging.orders_raw
) t;
 
 
-- 9. Shipping and order dates
-- Question: is shipping ever before the order, and do the real days match the dates?
-- Expected: 0 and 0.
-- Found: 0 and 0.
SELECT
    SUM(CASE WHEN ship < ord THEN 1 ELSE 0 END)                            AS ship_before_order,
    SUM(CASE WHEN DATEDIFF(day, ord, ship) <> days_real THEN 1 ELSE 0 END) AS days_mismatch
FROM (
    SELECT
        TRY_CONVERT(datetime, [order date (DateOrders)], 101)    AS ord,
        TRY_CONVERT(datetime, [shipping date (DateOrders)], 101) AS ship,
        TRY_CONVERT(int, [Days for shipping (real)])             AS days_real
    FROM staging.orders_raw
) t;
 
 
-- 10. Order status and delivery status
-- Question: which orders have no real shipment?
-- Found: 9 order statuses. "Shipping canceled" appears only with CANCELED
-- (1,367 orders) and SUSPECTED_FRAUD (1,488 orders): 2,855 orders in total
-- All other statuses have a delivery result.
SELECT
    [Order Status],
    [Delivery Status],
    COUNT(*)                   AS rows_count,
    COUNT(DISTINCT [Order Id]) AS orders
FROM staging.orders_raw
GROUP BY [Order Status], [Delivery Status]
ORDER BY [Order Status], [Delivery Status];
 
 
-- 13. Repeated rows
-- Question: are there rows with the same order, product, quantity and amounts?
-- Expected: 0.
-- Found: 0.
SELECT
    COUNT(*)        AS repeated_groups,
    SUM(line_count) AS rows_in_those_groups
FROM (
    SELECT
        [Order Id], [Product Card Id], [Order Item Quantity],
        [Sales], [Order Item Discount], [Benefit per order],
        COUNT(*) AS line_count
    FROM staging.orders_raw
    GROUP BY
        [Order Id], [Product Card Id], [Order Item Quantity],
        [Sales], [Order Item Discount], [Benefit per order]
    HAVING COUNT(*) > 1
) t;
 
