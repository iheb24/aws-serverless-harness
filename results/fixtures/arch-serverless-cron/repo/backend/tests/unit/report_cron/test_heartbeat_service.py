"""Unit tests for the HeartbeatService."""

from datetime import UTC, datetime

from report_cron.services.heartbeat import HeartbeatService


def test_generate_heartbeat() -> None:
    """HeartbeatService generates a valid record with current timestamp."""
    service = HeartbeatService()
    before = datetime.now(UTC)
    record = service.generate_heartbeat()
    after = datetime.now(UTC)

    assert record.pk == "HEARTBEAT"
    assert record.status == "HEALTHY"

    # Verify timestamp is between before and after
    record_time = datetime.fromisoformat(record.timestamp)
    assert before <= record_time <= after
    assert record.sk == record.timestamp
