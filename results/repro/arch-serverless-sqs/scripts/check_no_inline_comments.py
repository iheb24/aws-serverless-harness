"""Reject inline ``#`` comments inside backend packages.

Code must explain itself through names and Google-style docstrings, never
through trailing comments. Tests and gate scripts are exempt. The check runs
at tokenizer level, so commented-out code is rejected as well (ruff's ERA
ruleset covers the same rule from a different angle).
"""

import io
import sys
import tokenize
from pathlib import Path

SKIP_SEGMENTS = {"tests", "scripts"}


def find_comment_lines(path: Path) -> list[int]:
    """Return 1-based line numbers of COMMENT tokens in the file."""
    if any(part in SKIP_SEGMENTS for part in path.parts):
        return []
    source = path.read_text(encoding="utf-8")
    tokens = tokenize.generate_tokens(io.StringIO(source).readline)
    return [token.start[0] for token in tokens if token.type == tokenize.COMMENT]


def main(argv: list[str]) -> int:
    """Check every file passed by pre-commit; return 1 on any comment."""
    failures = 0
    for arg in argv[1:]:
        lines = find_comment_lines(Path(arg))
        if lines:
            print(f"{arg}: inline comments on lines {', '.join(map(str, lines))}")
            failures += 1
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
