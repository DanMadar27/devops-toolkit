import logging
import boto3

logger = logging.getLogger(__name__)

def upload_to_s3(zip_file_path, bucket_name, s3_key, region_name):
    s3 = boto3.client('s3', region_name=region_name)
    s3.upload_file(zip_file_path, bucket_name, s3_key)
    logger.info(f"Uploaded {zip_file_path} to S3 bucket {bucket_name} as {s3_key}")
