"""Unit tests for the ReportHandler entrypoint."""

import os
from unittest.mock import MagicMock, patch

import pytest
from aws_lambda_powertools.utilities.typing import LambdaContext

from report_cron.entrypoint import handler
from report_cron.exceptions import AwsClientError


@patch.dict(os.environ, {"TABLE_NAME": "report-cron-table"})
@patch("report_cron.entrypoint.StorageClient")
@patch("report_cron.entrypoint.HeartbeatService")
def test_handler_success(
    mock_service_class: MagicMock,
    mock_client_class: MagicMock,
) -> None:
    """Handler orchestrates service and client correctly."""
    mock_service = mock_service_class.return_value
    mock_client = mock_client_class.return_value

    mock_record = MagicMock()
    mock_record.pk = "HB"
    mock_record.sk = "TS"
    mock_service.generate_heartbeat.return_value = mock_record

    context = MagicMock(spec=LambdaContext)
    event = {"detail-type": "Scheduled Event"}

    response = handler(event, context)

    assert response["status"] == "success"
    assert response["pk"] == "HB"
    mock_client.put_heartbeat.assert_called_once_with(
        table_name="report-cron-table", record=mock_record
    )


@patch.dict(os.environ, {"TABLE_NAME": "report-cron-table"})
@patch("report_cron.entrypoint.StorageClient")
@patch("report_cron.entrypoint.HeartbeatService")
def test_handler_throttle_failure(
    mock_service_class: MagicMock,
    mock_client_class: MagicMock,
) -> None:
    """Handler propagates AwsClientError when DynamoDB is throttled."""
    mock_client = mock_client_class.return_value
    mock_client.put_heartbeat.side_effect = AwsClientError(
        service="dynamodb",
        operation="put_item",
        code="ProvisionedThroughputExceededException",
        msg="Throttled",
    )

    context = MagicMock(spec=LambdaContext)
    with pytest.raises(AwsClientError) as excinfo:
        handler({}, context)

    assert "ProvisionedThroughputExceededException" in str(excinfo.value)
