"""Checks behind the decisions in docs/decisions.md.

1. Duplicate and one-to-one column pairs.
2. For each entity (customer, product, order, order line): which columns have a
   single value per key. A count of 0 means the column belongs to that entity.
   Control columns that should NOT belong are included to validate the check.
"""
import pandas as pd

df = pd.read_csv("data/DataCoSupplyChainDataset.csv", encoding="latin-1")

# ---------------------------------------------------------------------------
# A. Identical columns (expected: 0 differing rows)
# ---------------------------------------------------------------------------
print("=== A: identical columns (expect 0 everywhere) ===")
print("Customer Id / Order Customer Id:", (df["Customer Id"] != df["Order Customer Id"]).sum())
print("Product Card Id / Order Item Cardprod Id:", (df["Product Card Id"] != df["Order Item Cardprod Id"]).sum())
print("Category Id / Product Category Id:", (df["Category Id"] != df["Product Category Id"]).sum())
print("Order Item Product Price / Product Price:", (df["Order Item Product Price"] != df["Product Price"]).sum())
print("Sales per customer / Order Item Total:", (df["Sales per customer"] != df["Order Item Total"]).sum())
print("Benefit per order / Order Profit Per Order:", (df["Benefit per order"] != df["Order Profit Per Order"]).sum())

# ---------------------------------------------------------------------------
# B. One-to-one pairs (expected: distinct pairs == distinct keys, shown in brackets)
# ---------------------------------------------------------------------------
print()
print("=== B: one-to-one (expect the number in brackets) ===")
print("Product Card Id - Product Name:", len(df[["Product Card Id", "Product Name"]].drop_duplicates()), "(118)")
print("Product Card Id - Product Image:", len(df[["Product Card Id", "Product Image"]].drop_duplicates()), "(118)")
print("Department Id - Department Name:", len(df[["Department Id", "Department Name"]].drop_duplicates()), "(11)")
print("Shipping Mode - Days scheduled:", len(df[["Shipping Mode", "Days for shipment (scheduled)"]].drop_duplicates()), "(4)")
print("Order Id - order date:", len(df[["Order Id", "order date (DateOrders)"]].drop_duplicates()), "(65752)")
print("Category Id - Category Name:", len(df[["Category Id", "Category Name"]].drop_duplicates()), "(51)")

# ---------------------------------------------------------------------------
# C. Category names shared by more than one id
# ---------------------------------------------------------------------------
print()
print("=== C: category names with more than one id ===")
c = df.groupby("Category Name")["Category Id"].nunique()
dup = c[c > 1]
print(dup)
for name in dup.index:
    print(df[df["Category Name"] == name][["Category Id", "Category Name", "Department Name"]].drop_duplicates())

# ---------------------------------------------------------------------------
# Entity checks
# ---------------------------------------------------------------------------
# All id columns in the file
print([c for c in df.columns if c.endswith("Id")])

# Customer: key = Customer Id
customer_cols = [
    "Customer Fname", "Customer Lname", "Customer Segment",
    "Customer Street", "Customer City", "Customer State",
    "Customer Country", "Customer Zipcode", "Latitude", "Longitude",
]
control_cols = ["Order City", "Order Id"]  # expected to vary per customer
g = df.groupby("Customer Id")[customer_cols + control_cols].nunique(dropna=False)
print("Customers with more than one value (0 = column belongs to the customer):")
print((g > 1).sum())

# Product: key = Product Card Id (category and department included)
product_cols = [
    "Product Name", "Product Price", "Product Image",
    "Category Id", "Category Name", "Department Id", "Department Name",
]
control_cols = ["Customer Id", "Order Id"]  # expected to vary per product
g = df.groupby("Product Card Id")[product_cols + control_cols].nunique(dropna=False)
print("Products with more than one value (0 = column belongs to the product):")
print((g > 1).sum())

# Order: key = Order Id
order_cols = [
    "order date (DateOrders)", "shipping date (DateOrders)",
    "Customer Id", "Order Status", "Type",
    "Shipping Mode", "Days for shipping (real)",
    "Days for shipment (scheduled)", "Delivery Status", "Late_delivery_risk",
    "Market", "Order Region", "Order Country", "Order State",
    "Order City", "Order Zipcode",
]
control_cols = ["Product Card Id", "Order Item Id"]  # expected to vary per order
g = df.groupby("Order Id")[order_cols + control_cols].nunique(dropna=False)
print("Orders with more than one value (0 = column belongs to the order):")
print((g > 1).sum())

# Order line: amounts should vary between lines of the same order.
# Only orders with more than one line can show this.
measure_cols = [
    "Sales", "Order Item Quantity", "Order Item Discount",
    "Order Item Discount Rate", "Order Item Total",
    "Order Item Profit Ratio", "Benefit per order",
]
multi = df[df.groupby("Order Id")["Order Item Id"].transform("count") > 1]
g = multi.groupby("Order Id")[measure_cols].nunique(dropna=False)
print("Orders with more than one value (large = column belongs to the line):")
print((g > 1).sum())
print("Orders checked:", len(g))