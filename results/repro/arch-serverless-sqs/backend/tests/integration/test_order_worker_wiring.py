"""Integration tests for the order_worker wiring.

Verifies that provisioned resources exist and the environment is correct.
"""

import os
from typing import Any

from order_worker.clients.storage import StorageClient


def test_storage_wiring(aws_client: Any) -> None:
    """Verify the DynamoDB table exists and has the correct keys.

    The infra context specifies the table name as 'order-worker-store-table'.
    """
    table_name = "order-worker-store-table"
    ddb = aws_client("dynamodb")

    response = ddb.describe_table(TableName=table_name)
    table = response["Table"]

    assert table["TableStatus"] == "ACTIVE"

    # Verify schema
    key_schema = {ks["AttributeName"]: ks["KeyType"] for ks in table["KeySchema"]}
    assert key_schema["pk"] == "HASH"
    assert key_schema["sk"] == "RANGE"


def test_queue_wiring(aws_client: Any) -> None:
    """Verify the SQS queue exists.

    The infra context specifies the queue name as 'order-worker-queue'.
    """
    queue_name = "order-worker-queue"
    sqs = aws_client("sqs")

    # get_queue_url raises QueueDoesNotExist if not found
    response = sqs.get_queue_url(QueueName=queue_name)
    assert "QueueUrl" in response


def test_client_resolution_with_env(aws_client: Any) -> None:
    """Verify StorageClient works with the configured environment."""
    table_name = "order-worker-store-table"
    os.environ["ORDERS_TABLE_NAME"] = table_name

    client = StorageClient()
    assert client.table_exists(table_name) is True
