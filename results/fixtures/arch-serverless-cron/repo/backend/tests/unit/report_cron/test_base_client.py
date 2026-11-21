"""Unit tests for the BaseAwsClient scaffolding of report_cron."""

import boto3
import pytest
from moto import mock_aws

from report_cron.clients.base import BaseAwsClient, resolve_parameter
from report_cron.exceptions import AwsClientError


class SsmTestClient(BaseAwsClient):
    """Concrete subclass exercising the shared base wiring."""

    service_name = "ssm"


@mock_aws
def test_call_returns_response_on_success() -> None:
    """A successful SDK call returns the raw boto3 response payload."""
    client = SsmTestClient()
    client.call(
        "put_parameter",
        Name="/dev/report_cron/table",
        Value="orders",
        Type="String",
    )
    response = client.call("get_parameter", Name="/dev/report_cron/table")
    assert response["Parameter"]["Value"] == "orders"


@mock_aws
def test_call_translates_client_error_with_code() -> None:
    """A missing parameter surfaces as AwsClientError carrying the AWS code."""
    client = SsmTestClient()
    with pytest.raises(AwsClientError) as excinfo:
        client.call("get_parameter", Name="/definitely/missing")
    assert excinfo.value.code == "ParameterNotFound"
    assert excinfo.value.service == "ssm"


@mock_aws
def test_resolve_parameter_reads_value() -> None:
    """The cached resolver reads values written to the mocked SSM store."""
    ssm = boto3.client("ssm", region_name="eu-west-3")
    ssm.put_parameter(
        Name="/dev/report_cron/endpoint",
        Value="https://internal.example",
        Type="String",
    )
    assert resolve_parameter("/dev/report_cron/endpoint") == "https://internal.example"
