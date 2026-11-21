"""DynamoDB client wrapper for storing heartbeat records."""

from typing import Any, cast

from report_cron.clients.base import BaseAwsClient
from report_cron.models.heartbeat import HeartbeatRecord


class StorageClient(BaseAwsClient):
    """Wrapper for writing heartbeat items to DynamoDB."""

    service_name = "dynamodb"

    def put_heartbeat(self, table_name: str, record: HeartbeatRecord) -> None:
        """Persist a heartbeat record to the specified DynamoDB table.

        Args:
            table_name: The target DynamoDB table name.
            record: The heartbeat record model instance.
        """
        self.call(
            "put_item",
            TableName=table_name,
            Item=record.to_item(),
        )

    def get_heartbeat(
        self, table_name: str, pk: str, sk: str
    ) -> HeartbeatRecord | None:
        """Retrieve a heartbeat record for verification in tests.

        Args:
            table_name: The target DynamoDB table name.
            pk: Partition key.
            sk: Sort key.

        Returns:
            The HeartbeatRecord if found, otherwise None.
        """
        response = cast(
            dict[str, Any],
            self.call(
                "get_item",
                TableName=table_name,
                Key={"pk": {"S": pk}, "sk": {"S": sk}},
            ),
        )

        item = response.get("Item")
        if not item:
            return None

        return HeartbeatRecord(
            pk=item["pk"]["S"],
            sk=item["sk"]["S"],
            status=item["status"]["S"],
            timestamp=item["timestamp"]["S"],
        )
