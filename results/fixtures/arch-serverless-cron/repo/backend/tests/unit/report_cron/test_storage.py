"""Unit tests for the StorageClient."""

import pytest
from moto import mock_aws

from report_cron.clients.storage import StorageClient
from report_cron.exceptions import AwsClientError
from report_cron.models.heartbeat import HeartbeatRecord


@mock_aws
def test_put_heartbeat_success() -> None:
    """StorageClient successfully writes an item to DynamoDB."""
    table_name = "test-table"
    client = StorageClient()
    client.client.create_table(
        TableName=table_name,
        KeySchema=[
            {"AttributeName": "pk", "KeyType": "HASH"},
            {"AttributeName": "sk", "KeyType": "RANGE"},
        ],
        AttributeDefinitions=[
            {"AttributeName": "pk", "AttributeType": "S"},
            {"AttributeName": "sk", "AttributeType": "S"},
        ],
        ProvisionedThroughput={"ReadCapacityUnits": 1, "WriteCapacityUnits": 1},
    )

    record = HeartbeatRecord(
        pk="HB",
        sk="2023-01-01T00:00:00Z",
        status="OK",
        timestamp="2023-01-01T00:00:00Z",
    )
    client.put_heartbeat(table_name, record)

    fetched = client.get_heartbeat(table_name, "HB", "2023-01-01T00:00:00Z")
    assert fetched is not None
    assert fetched.status == "OK"


@mock_aws
def test_put_heartbeat_error_translation() -> None:
    """StorageClient translates botocore errors into AwsClientError."""
    client = StorageClient()
    record = HeartbeatRecord(pk="HB", sk="TS", status="OK", timestamp="TS")

    with pytest.raises(AwsClientError) as excinfo:
        client.put_heartbeat("non-existent-table", record)

    assert excinfo.value.service == "dynamodb"
    assert excinfo.value.operation == "put_item"
    assert "ResourceNotFoundException" in str(excinfo.value)


@mock_aws
def test_get_heartbeat_not_found() -> None:
    """get_heartbeat returns None when the item does not exist."""
    table_name = "test-table"
    client = StorageClient()
    client.client.create_table(
        TableName=table_name,
        KeySchema=[
            {"AttributeName": "pk", "KeyType": "HASH"},
            {"AttributeName": "sk", "KeyType": "RANGE"},
        ],
        AttributeDefinitions=[
            {"AttributeName": "pk", "AttributeType": "S"},
            {"AttributeName": "sk", "AttributeType": "S"},
        ],
        ProvisionedThroughput={"ReadCapacityUnits": 1, "WriteCapacityUnits": 1},
    )

    result = client.get_heartbeat(table_name, "missing", "missing")
    assert result is None
