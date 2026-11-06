"""First look at the DataCo main file: size, types, missing values, distinct counts."""
import pandas as pd

df = pd.read_csv("data/DataCoSupplyChainDataset.csv", encoding="cp1252")

# Size, column types and columns with missing values
print(df.shape)
df.info()
print(df.isna().sum()[lambda s: s > 0])

# Distinct values per column, and a transposed preview of the first rows
print(df.nunique())
print(df.head(3).T)

# Group columns by their number of distinct values.
# Columns in the same group are candidates for duplicates (see explore_checks.py)
nun = df.nunique()
for count, cols in nun.groupby(nun):
    if len(cols) > 1:
        print(count, list(cols.index))