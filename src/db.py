from sqlalchemy import create_engine
from sqlalchemy.engine import URL

SERVER = "localhost\SQLEXPRESS"
DATABASE = "DataCoDW"
DRIVER = "ODBC Driver 18 for SQL Server"

def get_engine():
    conn_str = (
        f"DRIVER={{{DRIVER}}};"
        f"SERVER={SERVER};"
        f"DATABASE={DATABASE};"
        "Trusted_Connection=yes;"
        "TrustServerCertificate=yes;"
    )

    url = URL.create("mssql+pyodbc", query={"odbc_connect": conn_str})
    return create_engine(url, fast_executemany=True)