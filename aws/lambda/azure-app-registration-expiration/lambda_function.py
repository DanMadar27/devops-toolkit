import logging
from main import lambda_handler

logger = logging.getLogger()
logger.setLevel("INFO")

def handler(event, context):
    try:
        lambda_handler(event, context)
        return {
            'statusCode': 200,
            'body': 'Azure app registration check completed successfully'
        }
    except Exception as e:
        logger.error(f"An error occurred in handler: {e}")
        
        return {
            'statusCode': 500,
            'body': f'Internal Server Error: {str(e)}'
        }
