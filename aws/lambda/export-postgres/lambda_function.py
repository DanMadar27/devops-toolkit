import logging
from main import main

logger = logging.getLogger()
logger.setLevel("INFO")

def handler(event, context):
    try:
        main()
        return {
            'statusCode': 200,
            'body': 'OK'
        }
    except Exception as e:
        logger.error(f"An error occurred in handler: {e}")
        
        return {
            'statusCode': 500,
            'body': 'Internal Server Error'
        }