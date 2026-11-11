-- Date dimension: one row per day, from the first to the last order date

DROP TABLE IF EXISTS dw.dim_date;

CREATE TABLE dw.dim_date(
    date_key        INT             NOT NULL PRIMARY KEY,
    full_date       DATE            NOT NULL,
    year_num        INT             NOT NULL,
    quarter_num     INT             NOT NULL,
    month_num       INT             NOT NULL,
    month_name      NVARCHAR(20)    NOT NULL,
    day_of_month    INT             NOT NULL,
    weekday_name    NVARCHAR(20)    NOT NULL
);

DECLARE @start DATE = (SELECT MIN(CAST(order_date AS DATE)) FROM clean.orders);
DECLARE @end DATE = (SELECT MAX(CAST(order_date AS DATE)) FROM clean.orders);

INSERT INTO dw.dim_date(
    date_key, full_date, year_num, quarter_num, month_num, 
    month_name, day_of_month, weekday_name
)
SELECT 
    YEAR(d) * 10000 + MONTH(d) * 100 + DAY(d),
    d,
    YEAR(d),
    DATEPART(quarter, d),
    MONTH(d),
    FORMAT(d, 'MMMM', 'en-US'),
    DAY(d),
    FORMAT(d, 'dddd', 'en-US')
FROM (
    SELECT DATEADD(day, value, @start) AS d
    FROM GENERATE_SERIES(0, DATEDIFF(day, @start, @end))
) days;


-- Shipping mode dimension: oner row per shipping mode

DROP TABLE IF EXISTS dw.dim_shipping_mode;

CREATE TABLE dw.dim_shipping_mode (
    shipping_mode_key   INT IDENTITY(1,1) PRIMARY KEY,
    shipping_mode       NVARCHAR(50) NOT NULL
);

INSERT INTO dw.dim_shipping_mode (shipping_mode)
SELECT DISTINCT shipping_mode
FROM clean.orders
ORDER BY shipping_mode;

-- Order Status dimension: one row per order status, with the KPI rule
-- Decision 9: CANCELED and SUSPECTED_FRAUD are not valid orders

DROP TABLE IF EXISTS dw.dim_order_status;

CREATE TABLE dw.dim_order_status (
    order_status_key  INT IDENTITY(1,1) PRIMARY KEY,
    order_status      NVARCHAR(50) NOT NULL,
    is_kpi_order      INT          NOT NULL
);

INSERT INTO dw.dim_order_status (order_status, is_kpi_order)
SELECT DISTINCT
    order_status,
    CASE WHEN order_status IN ('CANCELED', 'SUSPECTED_FRAUD') 
        THEN 0 
        ELSE 1 
    END
FROM clean.orders
ORDER BY order_status;



-- Market dimension: one row per distinct delivery location.

DROP TABLE IF EXISTS dw.dim_market;

CREATE TABLE dw.dim_market (
    market_key     INT IDENTITY(1,1) PRIMARY KEY,
    market         NVARCHAR(50)  NOT NULL,
    order_region   NVARCHAR(50)  NOT NULL,
    order_country NVARCHAR(100) NOT NULL,
    order_state    NVARCHAR(100) NOT NULL,
    order_city     NVARCHAR(100) NOT NULL
);

INSERT INTO dw.dim_market (market, order_region, order_country, order_state, order_city)
SELECT DISTINCT market, order_region, order_country, order_state, order_city
FROM clean.orders
ORDER BY market, order_region, order_country, order_state, order_city;


-- Product dimension: one row per product, with category and department

DROP TABLE IF EXISTS dw.dim_product;

CREATE TABLE dw.dim_product (
    product_key      INT IDENTITY(1,1) PRIMARY KEY,
    product_id       INT            NOT NULL,
    product_name     NVARCHAR(100)  NOT NULL,
    product_price    DECIMAL(10,2)  NOT NULL,
    product_image    NVARCHAR(200)  NOT NULL,
    category_id      INT            NOT NULL,
    category_name    NVARCHAR(50)   NOT NULL,
    department_id    INT            NOT NULL,
    department_name  NVARCHAR(50)   NOT NULL
);

INSERT INTO dw.dim_product (
    product_id, product_name, product_price, product_image,
    category_id, category_name, department_id, department_name
)
SELECT DISTINCT
    product_id, product_name, product_price, product_image,
    category_id, category_name, department_id, department_name
FROM clean.orders
ORDER BY product_id;


