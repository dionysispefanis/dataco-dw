import sys
import time


from db import get_engine
from run_sql import run_sql_file
from run_checks import run_checks

STEPS = [
    ("sql",     "scripts/01_clean.sql"),
    ("checks",  "tests/quality_checks_clean.sql"),
    ("sql",     "scripts/02_dw_dimensions.sql"),
    ("sql",     "scripts/03_dw_facts.sql"),
    ("checks",  "tests/quality_checks_dw.sql")
]


def main():
    engine  = get_engine()
    start = time.time()

    for kind, path in STEPS:
        try:
            if kind == "sql":
                run_sql_file(engine, path)
            else:
                run_checks(engine, path)
        except Exception as error:
            print(f"FAILED  {path}")
            print(error)
            sys.exit(1)

    print(f"Pipeline finished in {time.time() - start:.1f} s")

if __name__ == "__main__":
    main()