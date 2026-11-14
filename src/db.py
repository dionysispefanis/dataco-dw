import os 

from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.engine import URL

load_dotenv()

SERVER = os.getenv("DB_SERVER")
DATABASE = os.getenv("DB_NAME")
DRIVER = os.getenv("DB_DRIVER")

def get_engine():
    if not SERVER:
        raise RuntimeError("DB_SERVER is missing in .env")
    if not DATABASE:
        raise RuntimeError("DB_NAME is missing in .env")
    if not DRIVER:
        raise RuntimeError("DB_DRIVER is missing in .env")

    conn_str = (
        f"DRIVER={{{DRIVER}}};"
        f"SERVER={SERVER};"
        f"DATABASE={DATABASE};"
        "Trusted_Connection=yes;"
        "TrustServerCertificate=yes;"
    )
    url = URL.create("mssql+pyodbc", query={"odbc_connect": conn_str})
    return create_engine(url, fast_executemany=True)

    url = URL.create("mssql+pyodbc", query={"odbc_connect": conn_str})
    return create_engine(url, fast_executemany=True)