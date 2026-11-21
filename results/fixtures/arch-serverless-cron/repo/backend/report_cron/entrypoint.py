"""Entrypoint for the report_cron workload (lambda_scheduled).

Wiring only: build clients and services, then delegate.
"""

import os
from typing import Any

from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.typing import LambdaContext

from report_cron.clients.storage import StorageClient
from report_cron.services.heartbeat import HeartbeatService

logger = Logger(service="report_cron")


def handler(event: dict[str, Any], context: LambdaContext) -> dict[str, Any]:
    """Handle the 15-minute scheduled event.

    Args:
        event: The EventBridge scheduled event payload.
        context: Lambda execution context.

    Returns:
        A response dictionary containing the execution status.
    """
    logger.info("Starting scheduled heartbeat report", extra={"event": event})

    table_name = os.environ["TABLE_NAME"]

    storage_client = StorageClient()
    heartbeat_service = HeartbeatService()

    record = heartbeat_service.generate_heartbeat()
    storage_client.put_heartbeat(table_name=table_name, record=record)

    logger.info(
        "Successfully recorded heartbeat",
        extra={"pk": record.pk, "sk": record.sk},
    )

    return {
        "status": "success",
        "pk": record.pk,
        "sk": record.sk,
    }
