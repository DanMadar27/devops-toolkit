import mysql.connector
import csv

HOST = "localhost"
USER = "root"
PASSWORD = "db_password"
DATABASE = "db_name"

connection = mysql.connector.connect(
    host=HOST,
    user=USER,
    password=PASSWORD,
    database=DATABASE
)

cursor = connection.cursor()

# Fetch all table names from the database
cursor.execute("SHOW TABLES")
tables = cursor.fetchall()

# Iterate over each table and export its data to CSV
for table in tables:
    table_name = table[0]  # Table name is the first element of each tuple

    # SQL query to fetch data from the table
    cursor.execute(f"SELECT * FROM {table_name}")

    # Fetch all rows from the result
    rows = cursor.fetchall()

    # Get column names from the cursor description
    columns = [desc[0] for desc in cursor.description]

    # Define the CSV file path for this table
    csv_file = f"{table_name}_data.csv"

    # Write data to CSV
    with open(csv_file, mode="w", newline="") as file:
        writer = csv.writer(file)

        # Write column headers
        writer.writerow(columns)

        # Write rows of data
        for row in rows:
            writer.writerow(row)

    print(f"Data from table '{table_name}' has been exported to {csv_file}.")


cursor.close()
connection.close()

print(f"Data has been exported to {csv_file}.")
