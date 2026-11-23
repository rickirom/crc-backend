import json
import os

import boto3

table_name = os.environ.get('TABLE_NAME', 'VisitorCount')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(table_name)

def increment() -> int:
    '''Pure functionality. No lambda specifics'''
    response = table.update_item(
        Key={'id': 'visitor-count'},
        UpdateExpression='ADD #v :incr',
        ExpressionAttributeNames={'#v': 'views'},
        ExpressionAttributeValues={':incr': 1},
        ReturnValues='UPDATED_NEW',
    )
    attributes = response.get('Attributes')

    if attributes is None:
        return None

    return int(attributes['views'])

def handler(event, context) -> dict:
    '''Adapted to Lambda event'''
    incremented = increment()
    if incremented is None:
        return {
            'statusCode': 404,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'error': 'Not found'})
        }

    return {
        'statusCode': 200,
        'headers': {'Content-Type': 'application/json'},
        'body': json.dumps({'views': incremented})
    }

