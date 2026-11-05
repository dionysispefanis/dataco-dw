# Design decisions

## 1. Grain: two fact tables

**Decision:** two facts with different grain.

- `fact_order_items`: one row is one order line (a product within an order). Key: `Order Item Id`. Measures: sales, quantity, discount, profit.
- `fact_orders`: one row is one order. Key: `Order Id`. Measures: shipping days (real, scheduled), delay.

**Why:** the source file has one row per order line. Amounts vary between
lines of the same order, while shipping data has a single value per order.
Keeping both in one table would repeat the delay once per line and distort
delay KPIs (e.g. an order with 3 lines counted 3 times).

**Evidence** (`src/explore_checks.py`):
- `Order Item Id` is unique (180,519 rows); `Order Id` has 65,752 distinct values.
- All shipping, date and location columns have one value per order.
- Amount columns differ between lines of the same order (45,902 orders with more than one line checked).

## 2. Columns excluded from the warehouse

**Decision:** 14 of the 53 source columns are not carried into the dw layer
(39 are kept). The staging table keeps all 53 columns as received.

**Duplicates** (identical to a column we keep):
- `Order Customer Id` = `Customer Id`
- `Order Item Cardprod Id` = `Product Card Id`
- `Product Category Id` = `Category Id`
- `Order Item Product Price` = `Product Price`
- `Sales per customer` = `Order Item Total`
- `Order Profit Per Order` = `Benefit per order`

**No information** (single value in all rows, or entirely empty):
- `Customer Email`
- `Customer Password`
- `Product Status`
- `Product Description`

**Mostly empty** (too sparse to analyse):
- `Order Zipcode` (86% empty; city, state, country and region are complete)

**Personal data** (not needed for any KPI; excluded to limit personal data in the warehouse):
- `Customer Fname`
- `Customer Lname`
- `Customer Street`

**Evidence** (`src/explore_checks.py`):
- Each duplicate pair: `!=` comparison returns 0 differing rows.
- Email, password, status: 1 distinct value. Description: 100% empty.
- `Order Zipcode`: 155,679 of 180,519 rows are empty.

## 3. KPIs

**Decision:** six KPIs, split by fact table.

Sales (from `fact_order_items`):
1. Total revenue: sum of `Order Item Total`.
2. Total profit and profit margin: sum of `Benefit per order`, divided by revenue.
3. Average order value: revenue divided by number of orders.

Shipping (from `fact_orders`):
4. Late delivery rate: late orders divided by orders that were not canceled.
5. Average delay in days: real minus scheduled shipping days, late orders only.
6. Number of orders.

**Why:** they cover both fact tables and the original goals of the project
(revenue and delivery delays). Each one can be sliced by the dimensions
defined in decision 4.

**Rules:**
- Canceled shipments are excluded from the delay KPIs, because no shipment took place and their day counts are meaningless.
- Delay is measured per order (in `fact_orders`), never per order line.

**Evidence** (`src/explore_checks.py`):
- `Late_delivery_risk` is 1 only when `Delivery Status` is "Late delivery", so it carries the same information.
- Real minus scheduled days is +1 to +4 for late orders, 0 for on time, and negative for early.
- For canceled shipments the difference ranges from -2 to +4, so it has no meaning.

**To verify in the cleaning phase:** 1,224 rows where `Sales` minus discount differs from `Order Item Total`.