import pandas as pd
from sqlalchemy.types import NVARCHAR

from db import get_engine

CSV_PATH = "data/DataCoSupplyChainDataset.csv"

df = pd.read_csv(
        CSV_PATH,
        encoding="latin-1",
        dtype=str,
        keep_default_na=False,
        na_values=[""]
)

engine = get_engine()

df.to_sql(
    "orders_raw",
    engine,
    schema="staging",
    if_exists="replace",
    index=False,
    dtype={col: NVARCHAR(255) for col in df.columns},
    chunksize=10000
)

with engine.connect() as conn:
    n = conn.exec_driver_sql("SELECT COUNT(*) FROM staging.orders_raw").scalar()

print("Rows in CSV:", len(df))
print("Rows in staging.orders_raw:", n)
