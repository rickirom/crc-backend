import boto3
import json
import os

table_name = os.environ.get('TABLE_NAME', 'VisitorCount')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(table_name)

def get_view_count() -> int:
    '''Pure functionality. No lambda specifics'''
    response = table.get_item(Key={'id': 'visitor-count'})
    item = response.get('Item')

    if item is None:
        return None

    return int(item['views'])

def handler(event, context) -> dict:
    '''Adapted to Lambda event'''
    views = get_view_count()
    if views is None:
        return {
            'statusCode': 404,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'error': 'Not found'})
        }

    return {
        'statusCode': 200,
        'headers': {'Content-Type': 'application/json'},
        'body': json.dumps({'views': views})
    }

