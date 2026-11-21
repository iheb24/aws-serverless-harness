"""Pydantic models for the heartbeat reporting data."""

from pydantic import BaseModel, Field


class HeartbeatRecord(BaseModel):
    """Data structure representing a single heartbeat record in DynamoDB."""

    pk: str = Field(..., description="Partition key, usually 'HEARTBEAT'.")
    sk: str = Field(..., description="Sort key, usually the ISO8601 timestamp.")
    status: str = Field(default="HEALTHY", description="Status of the report runner.")
    timestamp: str = Field(..., description="ISO8601 formatted UTC timestamp.")

    def to_item(self) -> dict[str, dict[str, str]]:
        """Convert the model to a low-level DynamoDB item dictionary."""
        return {
            "pk": {"S": self.pk},
            "sk": {"S": self.sk},
            "status": {"S": self.status},
            "timestamp": {"S": self.timestamp},
        }
