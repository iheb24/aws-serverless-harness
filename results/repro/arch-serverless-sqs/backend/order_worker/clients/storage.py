"""AWS DynamoDB client for the order_worker workload.

Handles low-level SDK interactions for persisting order records.
"""

from typing import Any

from order_worker.clients.base import BaseAwsClient
from order_worker.models.order import OrderRecord


class StorageClient(BaseAwsClient):
    """Client for DynamoDB storage operations."""

    service_name = "dynamodb"

    def put_order(self, table_name: str, order: OrderRecord) -> None:
        """Persist an order record to DynamoDB using the low-level client.

        Args:
            table_name: The target DynamoDB table name.
            order: The validated OrderRecord model.

        Raises:
            AwsClientError: If the DynamoDB operation fails.
        """
        item: dict[str, Any] = {
            "pk": {"S": f"ORDER#{order.order_id}"},
            "sk": {"S": f"USER#{order.user_id}"},
            "status": {"S": order.status},
            "total": {"N": str(order.total)},
        }
        self.call(
            "put_item",
            TableName=table_name,
            Item=item,
        )

    def table_exists(self, table_name: str) -> bool:
        """Check if the table exists for wiring validation.

        Args:
            table_name: The table name to check.

        Returns:
            True if the table exists.
        """
        try:
            self.call("describe_table", TableName=table_name)
            return True
        except Exception:
            return False
