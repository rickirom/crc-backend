# tests/test_app.py
import os
import boto3
import pytest
from moto import mock_aws

aws_region = 'eu-central-1'

os.environ['TABLE_NAME'] = 'VisitorCount'
os.environ['AWS_DEFAULT_REGION'] = aws_region

@pytest.fixture
def dynamodb_table():
    with mock_aws():
        client = boto3.client('dynamodb', region_name=aws_region)
        client.create_table(
            TableName='VisitorCount',
            KeySchema=[{'AttributeName': 'id', 'KeyType': 'HASH'}],
            AttributeDefinitions=[{'AttributeName': 'id', 'AttributeType': 'S'}],
            BillingMode='PAY_PER_REQUEST'
        )
        client.put_item(
            TableName='VisitorCount',
            Item={'id': {'S': 'visitor-count'}, 'views': {'N': '42'}}
        )
        yield

# Get views function/endpoint

def test_get_view_count_returns_value(dynamodb_table):
    from src.get_views import get_view_count
    assert get_view_count() == 42

def test_get_view_count_missing_item(dynamodb_table):
    import boto3
    client = boto3.client('dynamodb', region_name=aws_region)
    client.delete_item(TableName='VisitorCount', Key={'id': {'S': 'visitor-count'}})
    from src.get_views import get_view_count
    assert get_view_count() is None

def test_get_view_handler_shape(dynamodb_table):
    from src.get_views import handler
    import json
    result = handler({}, None)
    assert result['statusCode'] == 200
    assert json.loads(result['body'])['views'] == 42

# Increment views function/endpoint
def test_increment_returns_value(dynamodb_table):
    from src.increment import increment
    assert increment() == 43

def test_increment_missing_item(dynamodb_table):
    import boto3
    client = boto3.client('dynamodb', region_name=aws_region)
    client.delete_item(TableName='VisitorCount', Key={'id': {'S': 'visitor-count'}})
    from src.increment import increment
    assert increment() is None

def test_increment_handler_shape(dynamodb_table):
    from src.increment import handler
    import json
    result = handler({}, None)
    assert result['statusCode'] == 200
    assert json.loads(result['body'])['views'] == 43