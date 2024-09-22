import os
from datetime import datetime
from pymongo import MongoClient
from bson.json_util import dumps

# Configuration
SOURCE_DB = "db_name"
SOURCE_URI = "mongodb+srv://<user>:<password>@<host>/" + SOURCE_DB
BACKUP_ROOT = "./backup/" + SOURCE_DB

# Create timestamped directory for backup
timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
export_dir = os.path.join(BACKUP_ROOT, timestamp)

# Create export directory
os.makedirs(export_dir, exist_ok=True)

# Connect to the MongoDB client
client = MongoClient(SOURCE_URI)
db = client[SOURCE_DB]

# Get list of collections in the source database
collections = db.list_collection_names()

# Loop through each collection and export it
for collection in collections:
    print(f"Exporting collection: {collection}")
    output_file = os.path.join(export_dir, f"{collection}.json")
    with open(output_file, 'w') as f:
        cursor = db[collection].find({})
        for document in cursor:
            f.write(dumps(document) + '\n')

print(f"All collections have been exported from {SOURCE_DB} to {export_dir}")