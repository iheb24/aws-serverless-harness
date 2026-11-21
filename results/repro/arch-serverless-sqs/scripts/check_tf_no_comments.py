"""Reject comment syntax inside Terraform files.

Terraform documents itself through ``description`` arguments on variables
and outputs plus terraform-docs injected tables, not through ``#`` or ``//``
comments. The check targets line-leading markers; URLs inside strings are
unaffected because they never start a line.
"""

import re
import sys
from pathlib import Path

COMMENT_LINE = re.compile(r"^\s*(#|//)")


def find_comment_lines(path: Path) -> list[int]:
    """Return 1-based line numbers starting with a comment marker."""
    lines = path.read_text(encoding="utf-8").splitlines()
    return [
        number for number, line in enumerate(lines, start=1) if COMMENT_LINE.match(line)
    ]


def main(argv: list[str]) -> int:
    """Check every .tf file passed by pre-commit; return 1 on any comment."""
    failures = 0
    for arg in argv[1:]:
        lines = find_comment_lines(Path(arg))
        if lines:
            print(f"{arg}: comment syntax on lines {', '.join(map(str, lines))}")
            failures += 1
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
