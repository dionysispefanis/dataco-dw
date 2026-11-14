import pandas as pd
from sqlalchemy.types import NVARCHAR

from db import get_engine

CSV_PATH = "data/DataCoSupplyChainDataset.csv"

def load_staging(engine, csv_path=CSV_PATH):
    df = pd.read_csv(
            csv_path,
            encoding="cp1252",
            dtype=str,
            keep_default_na=False,
            na_values=[""]
    )
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

    if n != len(df):
        raise RuntimeError(f"Loaded {n} rows, but the CSV has {len(df)}")

    print(f"OK  {csv_path}  ({n} rows)")


if __name__ == "__main__":
    load_staging(get_engine())
