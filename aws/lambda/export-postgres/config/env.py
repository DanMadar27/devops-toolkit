import os
import logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(message)s')

def get_config():
    dbname = os.getenv('DB_NAME')
    user = os.getenv('DB_USER')
    password = os.getenv('DB_PASSWORD')
    host = os.getenv('DB_HOST')
    port = os.getenv('DB_PORT')
    sslmode = 'require'
    output_dir = os.getenv('OUTPUT_DIR', './output')
    bucket_name = os.getenv('S3_BUCKET_NAME')
    region_name = os.getenv('AWS_REGION', 'eu-central-1')
    bucket_path = os.getenv('S3_BUCKET_PATH', 'database/backup/')

    if (dbname is None or user is None or password is None or host is None or port is None or bucket_name is None):
        logging.error("Missing environment variables")
        raise Exception("Missing environment variables")
    
    return {
        'dbname': dbname,
        'user': user,
        'password': password,
        'host': host,
        'port': port,
        'sslmode': sslmode,
        'output_dir': output_dir,
        'bucket_name': bucket_name,
        'region_name': region_name,
        'bucket_path': bucket_path
    }