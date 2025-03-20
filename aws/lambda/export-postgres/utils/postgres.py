import os
import logging
import psycopg2
import pandas as pd

logger = logging.getLogger(__name__)

def export_tables_to_csv(dbname, user, password, host, port, output_dir, sslmode):
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

    # Create output directory if it doesn't exist
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    # Export each table to CSV
    for table_name in tables:
        table_name = table_name[0]
        query = f'SELECT * FROM "{table_name}"'
        df = pd.read_sql_query(query, conn)
        csv_file_path = f"{output_dir}/{table_name}.csv"
        df.to_csv(csv_file_path, index=False)
        logger.info(f"Exported {table_name} to {csv_file_path}")

    cursor.close()
    conn.close()

