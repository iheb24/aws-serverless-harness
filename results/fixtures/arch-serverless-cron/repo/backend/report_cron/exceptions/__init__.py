"""Domain exceptions for the report_cron workload.

``clients/`` translates every botocore ``ClientError`` into ``AwsClientError``
so the rest of the package never depends on AWS SDK error shapes.
"""


class ReportCronError(Exception):
    """Base class for all report_cron domain errors."""


class AwsClientError(ReportCronError):
    """An AWS SDK call failed; carries service, operation, and AWS error code."""

    def __init__(self, *, service: str, operation: str, code: str, msg: str) -> None:
        """Store the AWS error context and build a readable message."""
        self.service = service
        self.operation = operation
        self.code = code
        super().__init__(f"{service}.{operation} failed with {code}: {msg}")
