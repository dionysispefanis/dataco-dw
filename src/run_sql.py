import sys
import time
from pathlib import Path

from db import get_engine

def run_sql_file(engine, path):
    sql = Path(path). read_text(encoding="utf-8-sig")
    start = time.time()
    with engine.begin() as conn:
        conn.exec_driver_sql("SET NOCOUNT ON;\n" + sql)
    print(f"OK  {path}  ({time.time() - start:.1f} s)")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python src/run_sql.py <path to .sql file>")
        sys.exit(1)
    run_sql_file(get_engine(), sys.argv[1])