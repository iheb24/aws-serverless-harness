"""Unit tests for the Lambda entrypoint."""

import os
from collections.abc import Generator
from unittest.mock import MagicMock, patch

import pytest

from order_worker.entrypoint import handler


@pytest.fixture
def mock_env() -> Generator[None]:
    """Mock environment variables."""
    with patch.dict(os.environ, {"ORDERS_TABLE_NAME": "test-table"}):
        yield


@patch("order_worker.entrypoint.OrderProcessor")
@patch("order_worker.entrypoint.StorageClient")
def test_handler_batch_processing(
    mock_storage_cls: MagicMock, mock_processor_cls: MagicMock, mock_env: None
) -> None:
    """Should process all records in the SQS event."""
    mock_processor = mock_processor_cls.return_value
    mock_processor.process_sqs_record.side_effect = [True, False]

    event = {
        "Records": [{"body": '{"valid": "data"}'}, {"body": '{"invalid": "data"}'}]
    }

    result = handler(event, MagicMock())

    assert result["batch_size"] == 2
    assert result["success_count"] == 1
    assert mock_processor.process_sqs_record.call_count == 2
