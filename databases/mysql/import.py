import mysql.connector

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

script_path = '~/Desktop/import.sql'

with open(script_path, "r") as sql_file:
    sql_script = sql_file.read()

cursor = connection.cursor()

try:
    for statement in sql_script.split(';'):
        if statement.strip():  # Ignore empty statements
            cursor.execute(statement)
    connection.commit()  # Commit the transaction
    print("SQL script executed successfully.")
except mysql.connector.Error as err:
    print(f"Error: {err}")
finally:
    cursor.close()
    connection.close()
