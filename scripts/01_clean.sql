-- Clean layer: typed and trimmed copy of staging.orders_raw
-- Rebuilt on every run

DROP TABLE IF EXISTS clean.orders;

CREATE TABLE clean.orders(
    order_id                 INT           NOT NULL,
    order_item_id            INT           NOT NULL PRIMARY KEY,
    order_date               DATETIME2(0)  NOT NULL,
    shipping_date            DATETIME2(0)  NOT NULL,
    order_status             NVARCHAR(50),
    payment_type             NVARCHAR(50),
    shipping_mode            NVARCHAR(50),
    days_shipping_real       INT,
    days_shipping_scheduled  INT,
    delivery_status          NVARCHAR(50),
    late_delivery_flag       INT,
    market                   NVARCHAR(50),
    order_region             NVARCHAR(50),
    order_country            NVARCHAR(100),
    order_state              NVARCHAR(100),
    order_city               NVARCHAR(100),
    customer_id              INT           NOT NULL,
    customer_segment         NVARCHAR(50),
    customer_city            NVARCHAR(50),
    customer_state           NVARCHAR(50),
    customer_country         NVARCHAR(50),
    customer_zipcode         NVARCHAR(5),
    product_id               INT           NOT NULL,
    product_name             NVARCHAR(100),
    product_price            DECIMAL(10,2),
    product_image            NVARCHAR(200),
    category_id              INT,
    category_name            NVARCHAR(50),
    department_id            INT,
    department_name          NVARCHAR(50),
    quantity                 INT,
    sales                    DECIMAL(10,2),
    discount                 DECIMAL(10,2),
    discount_rate            DECIMAL(4,2),
    item_total               DECIMAL(10,2),
    profit_ratio             DECIMAL(5,2),
    profit                   DECIMAL(10,2),
    delay_days               INT,
    dwh_create_date          DATETIME2     DEFAULT GETDATE()
);

INSERT INTO clean.orders (
    order_id,
    order_item_id,
    order_date,
    shipping_date,
    customer_id,
    product_id,
    days_shipping_real,
    days_shipping_scheduled,
    late_delivery_flag,
    category_id,
    department_id,
    quantity,
    product_price,
    sales,
    discount,
    discount_rate,
    item_total,
    profit_ratio,
    profit,
    order_status,
    payment_type,
    shipping_mode,
    delivery_status,
    market,
    order_region,
    order_country,
    order_state,
    order_city,
    customer_segment,
    product_name,
    product_image,
    category_name,
    department_name,
    customer_city,
    customer_state,
    customer_country,
    customer_zipcode,
    delay_days
)
SELECT
    CAST([Order Id] AS INT),
    CAST([Order Item Id] AS INT),
    CONVERT(DATETIME2(0), [order date (DateOrders)], 101),
    CONVERT(DATETIME2(0), [shipping date (DateOrders)], 101),
    CAST([Customer Id] AS INT),
    CAST([Product Card Id] AS INT),
    CAST([Days for shipping (real)] AS INT),
    CAST([Days for shipment (scheduled)] AS INT),
    CAST([Late_delivery_risk] AS INT),
    CAST([Category Id] AS INT),
    CAST([Department Id] AS INT),
    CAST([Order Item Quantity] AS INT),
    CAST([Product Price] AS DECIMAL(10,2)),
    CAST([Sales] AS DECIMAL(10,2)),
    CAST([Order Item Discount] AS DECIMAL(10,2)),
    CAST([Order Item Discount Rate] AS DECIMAL(4,2)),
    CAST([Order Item Total] AS DECIMAL(10,2)),
    CAST([Order Item Profit Ratio] AS DECIMAL(5,2)),
    CAST([Benefit per order] AS DECIMAL(10,2)),
    NULLIF(TRIM([Order Status]), ''),
    NULLIF(TRIM([Type]), ''),
    NULLIF(TRIM([Shipping Mode]), ''),
    NULLIF(TRIM([Delivery Status]), ''),
    NULLIF(TRIM([Market]), ''),
    NULLIF(TRIM([Order Region]), ''),
    NULLIF(TRIM([Order Country]), ''),
    NULLIF(TRIM([Order State]), ''),
    NULLIF(TRIM([Order City]), ''),
    NULLIF(TRIM([Customer Segment]), ''),
    NULLIF(TRIM([Product Name]), ''),
    NULLIF(TRIM([Product Image]), ''),
    NULLIF(TRIM([Category Name]), ''),
    NULLIF(TRIM([Department Name]), ''),

    -- customer_city: empty in the 3 shifted rows (the city is missing)
    CASE WHEN TRIM([Customer State]) LIKE '[0-9][0-9][0-9][0-9][0-9]'
         THEN NULL
         ELSE NULLIF(TRIM([Customer City]), '')
    END,

    -- customer_state: in the 3 shifted rows the state is in the city column
    CASE WHEN TRIM([Customer State]) LIKE '[0-9][0-9][0-9][0-9][0-9]'
         THEN NULLIF(TRIM([Customer City]), '')
         ELSE NULLIF(TRIM([Customer State]), '')
    END,

    -- customer_country: same spelling of the US as in order_country
    CASE WHEN TRIM([Customer Country]) = 'EE. UU.'
         THEN 'Estados Unidos'
         ELSE NULLIF(TRIM([Customer Country]), '')
    END,

    -- customer_zipcode: in the 3 shifted rows the zipcode is in the state column;
    -- otherwise pad with zeros on the left to 5 characters
    CASE WHEN TRIM([Customer State]) LIKE '[0-9][0-9][0-9][0-9][0-9]'
         THEN TRIM([Customer State])
         ELSE RIGHT('00000' + NULLIF(TRIM([Customer Zipcode]), ''), 5)
    END,

    -- delay in days: real minus scheduled (negative = early)
    CAST([Days for shipping (real)] AS INT) - CAST([Days for shipment (scheduled)] AS INT)
FROM staging.orders_raw;



