import os
from datetime import datetime
import psycopg2
import pandas as pd
import warnings

def export_tables_to_csv(dbname, user, password, host, port, output_dir, sslmode):
    try:
        # Connect to PostgreSQL
        conn = psycopg2.connect(
            dbname=dbname,
            user=user,
            password=password,
            host=host,
            port=port,
            sslmode=sslmode
        )

        cursor = conn.cursor()

        # Get all table names
        cursor.execute(
            """
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema='public'
            """
        )
        tables = cursor.fetchall()

        # Export each table to CSV
        for table_name in tables:
            table_name = table_name[0]
            query = f'SELECT * FROM "{table_name}"'
            df = pd.read_sql_query(query, conn)
            csv_file_path = f"{output_dir}/{table_name}.csv"
            df.to_csv(csv_file_path, index=False)
            print(f"Exported {table_name} to {csv_file_path}")

        # Close the connection
        cursor.close()
        conn.close()

    except Exception as e:
        print(f"Error: {e}")

# Suppress SQLAlchemy warning
warnings.filterwarnings("ignore", category=UserWarning, message="pandas only supports SQLAlchemy")

# Configuration
DB_NAME = "your_db_name"
USER = "your_username"
PASSWORD = "your_password"
HOST = "localhost"
PORT = "5432"
OUTPUT_DIR = "./backup/" + DB_NAME
OUTPUT_DIR = "./" + DB_NAME
SSL_MODE = "require" # or allow

# Create timestamped directory for backup
timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
export_dir = os.path.join(OUTPUT_DIR, timestamp)

# Create export directory
os.makedirs(export_dir, exist_ok=True)

# Export tables to CSV
export_tables_to_csv(
    dbname=DB_NAME,
    user=USER,
    password=PASSWORD,
    host=HOST,
    port=PORT,
    output_dir=export_dir,
    sslmode=SSL_MODE
)
