"""Domain logic for processing order messages.

Validates SQS message payloads and coordinates storage operations.
"""

import json

from aws_lambda_powertools import Logger
from pydantic import ValidationError

from order_worker.clients.storage import StorageClient
from order_worker.exceptions import AwsClientError
from order_worker.models.order import OrderRecord

logger = Logger(service="order_worker")


class OrderProcessor:
    """Service for processing and validating order data."""

    def __init__(self, storage_client: StorageClient, table_name: str) -> None:
        """Initialize the processor with its dependencies.

        Args:
            storage_client: Client for DynamoDB persistence.
            table_name: Target table for order records.
        """
        self._storage = storage_client
        self._table_name = table_name

    def process_sqs_record(self, body: str) -> bool:
        """Process a single SQS message body.

        Args:
            body: The JSON string from the SQS message body.

        Returns:
            True if processed successfully, False otherwise.
        """
        try:
            data = json.loads(body)
            order = OrderRecord(**data)
            self._storage.put_order(self._table_name, order)
            logger.info(
                "Successfully processed order", extra={"order_id": order.order_id}
            )
            return True
        except (json.JSONDecodeError, ValidationError) as exc:
            logger.error("Malformed order message received", extra={"error": str(exc)})
            return False
        except AwsClientError as exc:
            if exc.code in (
                "ProvisionedThroughputExceededException",
                "ThrottlingException",
            ):
                logger.warning("Storage throttling detected", extra={"code": exc.code})
                raise
            logger.error("Permanent storage error", extra={"error": str(exc)})
            return False
