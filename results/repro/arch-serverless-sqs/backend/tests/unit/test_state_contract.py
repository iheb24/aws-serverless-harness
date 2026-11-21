"""Guard: .harness/state.yaml stays parseable and coherent."""

from pathlib import Path

import yaml

STATE_PATH = Path(__file__).parents[3] / ".harness" / "state.yaml"


def test_state_file_is_valid_mapping() -> None:
    """The contract file exists and carries schema and repository keys."""
    assert STATE_PATH.exists(), "run harness init before the test suite"
    data = yaml.safe_load(STATE_PATH.read_text(encoding="utf-8"))
    assert isinstance(data, dict)
    assert data["schema_version"] >= 1
    assert data["repository"]["name"]
