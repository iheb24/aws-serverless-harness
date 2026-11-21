"""Entrypoint for the order_worker lambda_sqs workload.

Wires the storage client and processor service to handle SQS events.
"""

import os
from typing import Any

from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.typing import LambdaContext

from order_worker.clients.storage import StorageClient
from order_worker.services.processor import OrderProcessor

logger = Logger(service="order_worker")


def handler(event: dict[str, Any], context: LambdaContext) -> dict[str, Any]:
    """Lambda entrypoint for SQS events.

    Args:
        event: SQS event containing one or more records.
        context: Lambda execution context.

    Returns:
        A summary of the batch processing result.
    """
    table_name = os.environ["ORDERS_TABLE_NAME"]
    storage_client = StorageClient()
    processor = OrderProcessor(storage_client, table_name)

    records = event.get("Records", [])
    success_count = 0

    for record in records:
        body = record.get("body", "")
        if processor.process_sqs_record(body):
            success_count += 1

    logger.info(
        "Batch processing complete",
        extra={"total": len(records), "success": success_count},
    )

    return {
        "batch_size": len(records),
        "success_count": success_count,
    }
