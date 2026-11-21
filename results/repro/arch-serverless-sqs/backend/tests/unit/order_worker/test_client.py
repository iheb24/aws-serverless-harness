"""Unit tests for the StorageClient."""

from collections.abc import Generator

import boto3
import pytest
from moto import mock_aws

from order_worker.clients.storage import StorageClient
from order_worker.exceptions import AwsClientError
from order_worker.models.order import OrderRecord


@pytest.fixture
def dynamodb_setup() -> Generator[str]:
    """Create a mock DynamoDB table."""
    table_name = "order-worker-store-table"
    with mock_aws():
        client = boto3.client("dynamodb", region_name="eu-west-3")
        client.create_table(
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
        yield table_name


@mock_aws
def test_put_order_success(dynamodb_setup: str) -> None:
    """Should successfully put an item into DynamoDB."""
    client = StorageClient()
    order = OrderRecord(order_id="1", user_id="A", total=10.0)

    client.put_order(dynamodb_setup, order)

    db = boto3.client("dynamodb", region_name="eu-west-3")
    response = db.get_item(
        TableName=dynamodb_setup, Key={"pk": {"S": "ORDER#1"}, "sk": {"S": "USER#A"}}
    )
    assert "Item" in response
    assert response["Item"]["total"]["N"] == "10.0"


@mock_aws
def test_put_order_failure_no_table() -> None:
    """Should raise AwsClientError if the table does not exist."""
    client = StorageClient()
    order = OrderRecord(order_id="1", user_id="A", total=10.0)

    with pytest.raises(AwsClientError) as exc:
        client.put_order("non-existent", order)
    assert exc.value.code == "ResourceNotFoundException"


@mock_aws
def test_table_exists_logic(dynamodb_setup: str) -> None:
    """Should correctly identify existing and missing tables."""
    client = StorageClient()
    assert client.table_exists(dynamodb_setup) is True
    assert client.table_exists("missing-table") is False
