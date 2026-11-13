import sys
from pathlib import Path

from db import get_engine


def run_checks(engine, path):
    sql = Path(path).read_text(encoding="utf-8-sig")
    with engine.connect() as conn:
        rows = conn.exec_driver_sql(sql).fetchall()

    failed = [(name, count) for name, count in rows if count != 0]
    for name, count in failed:
        print(f"  FAIL  {name}: {count}")

    if failed:
        raise RuntimeError(f"{len(failed)} of {len(rows)} checks failed")

    print(f"OK  {path}  ({len(rows)} checks passed)")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python src/run_checks.py <path to checks .sql file>")
        sys.exit(1)
    try:
        run_checks(get_engine(), sys.argv[1])
    except Exception as error:
        print(error)
        sys.exit(1)