-- Fact table: one row per order line. Descriptions are replaced by keys

DROP TABLE IF EXISTS dw.fact_order_items;

CREATE TABLE dw.fact_order_items (
    order_item_id     INT           NOT NULL PRIMARY KEY,
    order_id          INT           NOT NULL,
    product_key       INT           NOT NULL,
    customer_key      INT           NOT NULL,
    order_date_key    INT           NOT NULL,
    market_key        INT           NOT NULL,
    order_status_key  INT           NOT NULL,
    quantity          INT           NOT NULL,
    sales             DECIMAL(10,2) NOT NULL,
    discount          DECIMAL(10,2) NOT NULL,
    discount_rate     DECIMAL(4,2)  NOT NULL,
    item_total        DECIMAL(10,2) NOT NULL,
    profit_ratio      DECIMAL(5,2)  NOT NULL,
    profit            DECIMAL(10,2) NOT NULL
);

INSERT INTO dw.fact_order_items (
    order_item_id, order_id, product_key, customer_key, order_date_key, market_key, order_status_key,
    quantity, sales, discount, discount_rate, item_total, profit_ratio, profit
)
SELECT
    co.order_item_id,
    co.order_id,
    p.product_key,
    c.customer_key,
    d.date_key,
    m.market_key,
    s.order_status_key,
    co.quantity,
    co.sales,
    co.discount,
    co.discount_rate,
    co.item_total,
    co.profit_ratio,
    co.profit
FROM clean.orders co
LEFT JOIN dw.dim_product      p ON p.product_id   = co.product_id
LEFT JOIN dw.dim_customer     c ON c.customer_id  = co.customer_id
LEFT JOIN dw.dim_date         d ON d.full_date    = CAST(co.order_date AS DATE)
LEFT JOIN dw.dim_market       m ON  m.market        = co.market
                                AND m.order_region  = co.order_region
                                AND m.order_country = co.order_country
                                AND m.order_state   = co.order_state
                                AND m.order_city    = co.order_city
LEFT JOIN dw.dim_order_status s ON s.order_status = co.order_status;



-- Fact table: one row per order. Shipping data lives here, once per order.

DROP TABLE IF EXISTS dw.fact_orders;

CREATE TABLE dw.fact_orders (
    order_id                 INT          NOT NULL PRIMARY KEY,
    customer_key             INT          NOT NULL,
    order_date_key           INT          NOT NULL,
    shipping_mode_key        INT          NOT NULL,
    market_key               INT          NOT NULL,
    order_status_key         INT          NOT NULL,
    payment_type             NVARCHAR(50) NOT NULL,
    delivery_status          NVARCHAR(50) NOT NULL,
    late_delivery_flag       INT          NOT NULL,
    shipping_date            DATETIME2(0) NOT NULL,
    days_shipping_real       INT          NOT NULL,
    days_shipping_scheduled  INT          NOT NULL,
    delay_days               INT          NOT NULL
);

INSERT INTO dw.fact_orders (
    order_id, customer_key, order_date_key, shipping_mode_key,
    market_key, order_status_key, payment_type, delivery_status,
    late_delivery_flag, shipping_date, days_shipping_real,
    days_shipping_scheduled, delay_days
)
SELECT
    co.order_id,
    c.customer_key,
    d.date_key,
    sm.shipping_mode_key,
    m.market_key,
    s.order_status_key,
    co.payment_type,
    co.delivery_status,
    co.late_delivery_flag,
    co.shipping_date,
    co.days_shipping_real,
    co.days_shipping_scheduled,
    co.delay_days
FROM (
    SELECT DISTINCT
        order_id, customer_id, order_date, shipping_date,
        order_status, payment_type, shipping_mode, delivery_status,
        late_delivery_flag, days_shipping_real, days_shipping_scheduled,
        delay_days, market, order_region, order_country, order_state, order_city
    FROM clean.orders
) co
LEFT JOIN dw.dim_customer      c  ON c.customer_id    = co.customer_id
LEFT JOIN dw.dim_date          d  ON d.full_date      = CAST(co.order_date AS DATE)
LEFT JOIN dw.dim_shipping_mode sm ON sm.shipping_mode = co.shipping_mode
LEFT JOIN dw.dim_market        m  ON  m.market        = co.market
                                  AND m.order_region  = co.order_region
                                  AND m.order_country = co.order_country
                                  AND m.order_state   = co.order_state
                                  AND m.order_city    = co.order_city
LEFT JOIN dw.dim_order_status  s  ON s.order_status   = co.order_status;


