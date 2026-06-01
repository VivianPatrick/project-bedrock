import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    for record in event.get('Records', []):
        bucket = record['s3']['bucket']['name']
        filename = record['s3']['object']['key']
        logger.info(f"Image received: {filename}")
        print(f"Image received: {filename} from bucket: {bucket}")
    
    return {
        "statusCode": 200,
        "body": json.dumps("Processing complete")
    }