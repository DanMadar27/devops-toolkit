import logging
from datetime import datetime
import shutil
import warnings

from config.env import get_config
from utils.postgres import export_tables_to_csv
from utils.files import compress_to_zip
from utils.s3 import upload_to_s3

logger = logging.getLogger(__name__)

def main():
    logging.basicConfig(level=logging.INFO)

    # Suppress SQLAlchemy warning
    warnings.filterwarnings("ignore", category=UserWarning, message="pandas only supports SQLAlchemy")

    config = get_config()

    dbname = config['dbname']
    user = config['user']
    password = config['password']
    host = config['host']
    port = config['port']
    sslmode = config['sslmode']
    output_dir = config['output_dir']
    bucket_name = config['bucket_name']
    region_name = config['region_name']
    bucket_path = config['bucket_path']
    
    logger.info(f"Exporting tables from {dbname} to {output_dir}")
    export_tables_to_csv(dbname, user, password, host, port, output_dir, sslmode)

    logger.info("Compressing CSV files to ZIP")
    zip_filename = f"exported_tables_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    zip_file_path = compress_to_zip(output_dir, zip_filename)
 
    s3_key = f"{bucket_path}{zip_filename}.zip"
    logger.info(f"Uploading {zip_file_path} to S3 bucket {bucket_name} as {s3_key}")
    upload_to_s3(zip_file_path, bucket_name, s3_key, region_name)

    logger.info("Cleaning up")
    shutil.rmtree(output_dir)
