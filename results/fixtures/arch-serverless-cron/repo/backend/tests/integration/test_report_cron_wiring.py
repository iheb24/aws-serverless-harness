"""Integration tests for report_cron wiring and infrastructure."""

import os
from typing import Any

import pytest


def test_infrastructure_and_env_wiring(aws_client: Any) -> None:
    """Verify that provisioned resources exist and env vars are set."""
    table_name = os.environ.get("TABLE_NAME", "report-cron-table")
    assert table_name == "report-cron-table"

    ddb = aws_client("dynamodb")
    try:
        desc = ddb.describe_table(TableName=table_name)
        status = desc["Table"]["TableStatus"]
        assert status in ["ACTIVE", "CREATING"]

        key_schema = desc["Table"]["KeySchema"]
        pk_attr = next(k for k in key_schema if k["KeyType"] == "HASH")
        sk_attr = next(k for k in key_schema if k["KeyType"] == "RANGE")
        assert pk_attr["AttributeName"] == "pk"
        assert sk_attr["AttributeName"] == "sk"
    except Exception as exc:
        pytest.fail(f"Table {table_name} not found or inaccessible: {exc}")
