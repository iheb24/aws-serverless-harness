"""Unit tests for the OrderProcessor service."""

import json
from unittest.mock import MagicMock

import pytest

from order_worker.clients.storage import StorageClient
from order_worker.exceptions import AwsClientError
from order_worker.services.processor import OrderProcessor


@pytest.fixture
def mock_storage() -> MagicMock:
    """Return a mocked StorageClient."""
    return MagicMock(spec=StorageClient)


@pytest.fixture
def processor(mock_storage: MagicMock) -> OrderProcessor:
    """Return an OrderProcessor instance with a mocked client."""
    return OrderProcessor(mock_storage, "test-table")


def test_process_valid_order(
    processor: OrderProcessor, mock_storage: MagicMock
) -> None:
    """Should successfully process and save a valid order."""
    body = json.dumps(
        {
            "order_id": "ord-123",
            "user_id": "user-456",
            "status": "pending",
            "total": 99.50,
        }
    )

    result = processor.process_sqs_record(body)

    assert result is True
    mock_storage.put_order.assert_called_once()


def test_process_malformed_json(
    processor: OrderProcessor, mock_storage: MagicMock
) -> None:
    """Should return False and not crash on invalid JSON."""
    result = processor.process_sqs_record("invalid-json")

    assert result is False
    mock_storage.put_order.assert_not_called()


def test_process_invalid_schema(
    processor: OrderProcessor, mock_storage: MagicMock
) -> None:
    """Should return False and not crash on missing required fields."""
    body = json.dumps({"order_id": "only-one-field"})

    result = processor.process_sqs_record(body)

    assert result is False
    mock_storage.put_order.assert_not_called()


def test_process_throttling_retry(
    processor: OrderProcessor, mock_storage: MagicMock
) -> None:
    """Should re-raise AwsClientError when throttling occurs."""
    mock_storage.put_order.side_effect = AwsClientError(
        service="dynamodb",
        operation="put_item",
        code="ProvisionedThroughputExceededException",
        msg="Too many requests",
    )

    body = json.dumps({"order_id": "ord-123", "user_id": "user-456", "total": 50.0})

    with pytest.raises(AwsClientError) as exc:
        processor.process_sqs_record(body)

    assert exc.value.code == "ProvisionedThroughputExceededException"


def test_process_permanent_aws_error(
    processor: OrderProcessor, mock_storage: MagicMock
) -> None:
    """Should return False when a non-retryable AWS error occurs."""
    mock_storage.put_order.side_effect = AwsClientError(
        service="dynamodb",
        operation="put_item",
        code="AccessDeniedException",
        msg="Forbidden",
    )

    body = json.dumps({"order_id": "ord-123", "user_id": "user-456", "total": 50.0})

    result = processor.process_sqs_record(body)
    assert result is False
