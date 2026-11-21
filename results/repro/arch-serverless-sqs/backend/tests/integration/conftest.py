"""Fixtures for integration tests against the local AWS emulator endpoint."""

import os
from collections.abc import Callable
from typing import Any

import boto3
import pytest

ENDPOINT = os.environ.get("AWS_ENDPOINT_URL", "http://localhost:4566")
REGION = os.environ.get("AWS_DEFAULT_REGION", "eu-west-3")


def _credentials() -> dict[str, str]:
    """Explicit test credentials, unless the environment provides identity.

    Backends with per-run generated credentials (AWS Emulator) publish them
    through ``AWS_SHARED_CREDENTIALS_FILE`` or ``AWS_PROFILE``; in that case
    boto3's default chain must resolve them and explicit keys would be wrong.
    Otherwise fall back to the static ``test`` credentials floci accepts.
    """
    if os.environ.get("AWS_SHARED_CREDENTIALS_FILE") or os.environ.get("AWS_PROFILE"):
        return {}
    return {
        "aws_access_key_id": os.environ.get("AWS_ACCESS_KEY_ID", "test"),
        "aws_secret_access_key": os.environ.get("AWS_SECRET_ACCESS_KEY", "test"),
    }


@pytest.fixture
def aws_client() -> Callable[[str], Any]:
    """Return a factory creating boto3 clients pinned to the local endpoint."""

    def make(service: str) -> Any:
        """Create a client for one service against the local endpoint."""
        return boto3.client(
            service,
            endpoint_url=ENDPOINT,
            region_name=REGION,
            **_credentials(),
        )

    return make
