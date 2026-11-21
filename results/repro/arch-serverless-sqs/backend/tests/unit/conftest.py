"""Fixtures giving every unit test fake AWS credentials and a region."""

import os

import pytest


@pytest.fixture(autouse=True)
def aws_credentials(monkeypatch: pytest.MonkeyPatch) -> None:
    """Set fake credentials and pin the region for moto-based clients."""
    monkeypatch.setenv("AWS_ACCESS_KEY_ID", "test")
    monkeypatch.setenv("AWS_SECRET_ACCESS_KEY", "test")
    monkeypatch.setenv("AWS_DEFAULT_REGION", "eu-west-3")
    monkeypatch.delenv("AWS_ENDPOINT_URL", raising=False)


os.environ.setdefault("AWS_EC2_METADATA_DISABLED", "true")
