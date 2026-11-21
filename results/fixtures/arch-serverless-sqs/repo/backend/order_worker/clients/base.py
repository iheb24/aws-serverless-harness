"""Shared AWS client scaffolding for the order_worker workload.

Subclass ``BaseAwsClient`` once per AWS service to inherit adaptive retries,
emulator endpoint injection (moto and AWS Emulator via
``AWS_ENDPOINT_URL``), and
translation of botocore errors into domain exceptions.
"""

from __future__ import annotations

import os
from functools import lru_cache
from typing import Any, ClassVar

import boto3
from botocore.client import Config
from botocore.exceptions import BotoCoreError, ClientError

from order_worker.exceptions import AwsClientError


def _aws_config() -> Config:
    """Build the shared botocore configuration with adaptive retries."""
    return Config(
        retries={"max_attempts": 3, "mode": "adaptive"},
        connect_timeout=5,
        read_timeout=10,
    )


def _endpoint_url() -> str | None:
    """Return the local emulator endpoint override, when set."""
    return os.environ.get("AWS_ENDPOINT_URL")


def _region() -> str:
    """Return the configured AWS region with a dev fallback."""
    return (
        os.environ.get("AWS_REGION")
        or os.environ.get("AWS_DEFAULT_REGION")
        or "eu-west-3"
    )


class BaseAwsClient:
    """Base class wiring a boto3 client with retries and error translation."""

    service_name: ClassVar[str]

    def __init__(self, *, endpoint_url: str | None = None) -> None:
        """Create the boto3 client for the subclass-declared service."""
        factory: Any = boto3.client
        self._client = factory(
            self.service_name,
            endpoint_url=endpoint_url or _endpoint_url(),
            region_name=_region(),
            config=_aws_config(),
        )

    @property
    def client(self) -> Any:
        """Return the underlying boto3 client for one-off operations."""
        return self._client

    def call(self, operation: str, **kwargs: Any) -> Any:
        """Invoke an SDK operation, translating AWS errors to domain errors.

        Args:
            operation: boto3 method name, e.g. ``get_parameter``.
            **kwargs: Arguments forwarded verbatim to the boto3 method.

        Returns:
            The boto3 response payload.

        Raises:
            AwsClientError: When AWS returns an error after retries.
        """
        try:
            return getattr(self._client, operation)(**kwargs)
        except ClientError as exc:
            error = exc.response["Error"]
            raise AwsClientError(
                service=self.service_name,
                operation=operation,
                code=str(error.get("Code", "Unknown")),
                msg=str(error.get("Message", "")),
            ) from exc
        except BotoCoreError as exc:
            raise AwsClientError(
                service=self.service_name,
                operation=operation,
                code=type(exc).__name__,
                msg=str(exc),
            ) from exc


@lru_cache(maxsize=256)
def resolve_parameter(path: str) -> str:
    """Resolve and cache an SSM parameter value at runtime.

    Terraform passes parameter paths as environment variables; this helper
    fetches values lazily so secret payloads never enter the Terraform state.

    Args:
        path: Absolute SSM parameter path, e.g. ``/dev/stack/table_name``.

    Returns:
        The decrypted parameter value.

    Raises:
        AwsClientError: When the parameter cannot be read.
    """
    client = boto3.client(
        "ssm",
        endpoint_url=_endpoint_url(),
        region_name=_region(),
        config=_aws_config(),
    )
    try:
        response = client.get_parameter(Name=path, WithDecryption=True)
    except ClientError as exc:
        error = exc.response["Error"]
        raise AwsClientError(
            service="ssm",
            operation="get_parameter",
            code=str(error.get("Code", "Unknown")),
            msg=str(error.get("Message", "")),
        ) from exc
    return str(response["Parameter"]["Value"])
