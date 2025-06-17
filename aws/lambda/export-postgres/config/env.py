import os
import logging
import boto3
from botocore.exceptions import ClientError
import json

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(message)s')

# Initialize the Secrets Manager client
secrets_manager = boto3.client('secretsmanager', region_name='eu-central-1')

def get_secret_values():
    """
    Retrieve secret values from AWS Secrets Manager
    """
    db_secret_id = os.environ['DATABASE_SECRET_ID']
    
    try:        
        # Get database secrets
        response = secrets_manager.get_secret_value(SecretId=db_secret_id)
        secret_json = json.loads(response['SecretString'])
        db_name = secret_json['DB_NAME']
        db_user = secret_json['DB_USER']
        db_password = secret_json['DB_PASSWORD']
        db_host = secret_json['DB_HOST']
        db_port = secret_json['DB_PORT']
        db_sslmode = secret_json.get('DB_SSLMODE', 'require')

        return {
            'db_name': db_name,
            'db_user': db_user,
            'db_password': db_password,
            'db_host': db_host,
            'db_port': db_port,
            'db_sslmode': db_sslmode,
        }
    except ClientError as e:
        print(f"Error retrieving secret: {e}")
        raise e
    
def get_config():
    secret_values = get_secret_values()
    dbname = secret_values['db_name']
    user = secret_values['db_user']
    password = secret_values['db_password']
    host = secret_values['db_host']
    port = secret_values['db_port']
    sslmode = secret_values['db_sslmode']
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