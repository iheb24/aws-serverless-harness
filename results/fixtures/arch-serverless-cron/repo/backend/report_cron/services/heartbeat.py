"""Logic for generating and formatting heartbeat data."""

from datetime import UTC, datetime

from report_cron.models.heartbeat import HeartbeatRecord


class HeartbeatService:
    """Logic to generate and format heartbeat data."""

    def generate_heartbeat(self) -> HeartbeatRecord:
        """Create a new HeartbeatRecord with current UTC timestamp.

        Returns:
            A populated HeartbeatRecord instance.
        """
        now = datetime.now(UTC)
        timestamp_str = now.isoformat()

        return HeartbeatRecord(
            pk="HEARTBEAT",
            sk=timestamp_str,
            status="HEALTHY",
            timestamp=timestamp_str,
        )
