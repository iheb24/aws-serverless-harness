"""Enforce the honest-README contract on every README.md.

Every README must state intent and non-goals, show the architecture as a
mermaid diagram, and carry a known-caveats section. This keeps documentation
structurally honest and prevents free-written promotional drift.
"""

import sys
from pathlib import Path

REQUIRED_SECTIONS = (
    "## Intent & Non-Goals",
    "## Architecture",
    "## Known Caveats & Next Steps",
)
MERMAID_FENCE = "```mermaid"


def find_missing(path: Path) -> list[str]:
    """Return the required pieces missing from the README at ``path``."""
    text = path.read_text(encoding="utf-8")
    missing = [section for section in REQUIRED_SECTIONS if section not in text]
    if MERMAID_FENCE not in text:
        missing.append("a ```mermaid fenced block")
    return missing


def main(argv: list[str]) -> int:
    """Check every README passed by pre-commit; return 1 on any gap."""
    failures = 0
    for arg in argv[1:]:
        missing = find_missing(Path(arg))
        if missing:
            print(f"{arg}: missing {', '.join(missing)}")
            failures += 1
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
