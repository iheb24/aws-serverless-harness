"""Handler-level integration tests for order_worker against the emulator."""

import json
from collections.abc import Callable
from typing import Any
from unittest.mock import MagicMock

import pytest
from aws_lambda_powertools.utilities.typing import LambdaContext

from order_worker.entrypoint import handler


def test_handler_persists_valid_order_and_rejects_invalid_body(
    aws_client: Callable[[str], Any],
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Invoke the SQS handler in-process and verify DynamoDB side effects."""
    table_name = "order-worker-store-table"
    monkeypatch.setenv("ORDERS_TABLE_NAME", table_name)

    event = {
        "Records": [
            {
                "body": json.dumps(
                    {
                        "order_id": "ord-1",
                        "user_id": "usr-1",
                        "status": "pending",
                        "total": 42.5,
                    }
                )
            },
            {"body": "not-json"},
        ]
    }
    result = handler(event, MagicMock(spec=LambdaContext))
    assert result == {"batch_size": 2, "success_count": 1}

    ddb = aws_client("dynamodb")
    response = ddb.get_item(
        TableName=table_name,
        Key={"pk": {"S": "ORDER#ord-1"}, "sk": {"S": "USER#usr-1"}},
    )
    item = response.get("Item")
    assert item is not None
    assert item["status"] == {"S": "pending"}
    assert item["total"] == {"N": "42.5"}
