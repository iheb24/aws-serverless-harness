"""Smoke test: the local AWS endpoint is reachable and usable."""

from collections.abc import Callable
from typing import Any


def test_ssm_parameter_round_trip(aws_client: Callable[[str], Any]) -> None:
    """A parameter written to the local stack reads back identically."""
    client = aws_client("ssm")
    client.put_parameter(
        Name="/harness/smoke", Value="ok", Type="String", Overwrite=True
    )
    response = client.get_parameter(Name="/harness/smoke")
    assert response["Parameter"]["Value"] == "ok"
