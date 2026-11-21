"""Handler-level integration tests for report_cron against the emulator."""

from collections.abc import Callable
from typing import Any
from unittest.mock import MagicMock

import pytest
from aws_lambda_powertools.utilities.typing import LambdaContext

from report_cron.entrypoint import handler


def test_handler_writes_heartbeat_to_dynamodb(
    aws_client: Callable[[str], Any],
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Invoke the scheduled handler in-process and verify DynamoDB persistence."""
    table_name = "report-cron-table"
    monkeypatch.setenv("TABLE_NAME", table_name)

    result = handler({"detail-type": "Scheduled Event"}, MagicMock(spec=LambdaContext))
    assert result["status"] == "success"

    ddb = aws_client("dynamodb")
    response = ddb.get_item(
        TableName=table_name,
        Key={"pk": {"S": result["pk"]}, "sk": {"S": result["sk"]}},
    )
    item = response.get("Item")
    assert item is not None
    assert item["status"] == {"S": "HEALTHY"}
