# dataco-dw

## How to run

### Requirements
- Windows with Python 3.11
- SQL Server (Express or Developer edition) and the ODBC Driver 18 for SQL Server
- A Windows account with access to the SQL Server (the connection uses Windows Authentication)
- The DataCo Smart Supply Chain dataset (`DataCoSupplyChainDataset.csv`)

### Steps

1. Install the Python packages:
   ```
   pip install -r requirements.txt
   ```
2. Download `DataCoSupplyChainDataset.csv` and put it in the `data/` folder (the data is not stored in this repository).
3. Create a file named `.env` in the project root. Copy `.env.example` and change the values to match your SQL Server:
   ```
   DB_SERVER=localhost\SQLEXPRESS
   DB_NAME=DataCoDW
   DB_DRIVER=ODBC Driver 18 for SQL Server
   ```
4. Create the database and its schemas once, by running `scripts/00_create_database.sql` in SQL Server Management Studio or VS Code.
5. Run the pipeline:
   ```
   python src/run_pipeline.py
   ```

The pipeline loads the CSV into `staging`, builds the `clean` and `dw` layers with SQL, and runs the quality checks after each layer. It stops with a message if any check fails.