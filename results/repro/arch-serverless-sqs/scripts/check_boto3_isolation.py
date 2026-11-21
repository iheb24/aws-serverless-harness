"""Reject boto3/botocore imports outside backend ``clients/`` packages.

The generated repositories enforce a strict hexagonal boundary: only
``backend/<package>/clients/`` may import AWS SDK modules. Everything else
receives client objects through dependency injection, which keeps domain
logic testable with moto-free fakes and makes the boundary machine-checkable.
"""

import ast
import sys
from pathlib import Path

SDK_MODULES = {"boto3", "botocore", "aioboto3", "aiobotocore"}
ALLOWED_SEGMENT = "clients"
SKIP_SEGMENTS = {"tests", "scripts"}


def find_violations(path: Path) -> list[tuple[int, str]]:
    """Return (line, module) pairs importing SDK modules outside clients/."""
    if ALLOWED_SEGMENT in path.parts or any(
        part in SKIP_SEGMENTS for part in path.parts
    ):
        return []
    tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
    violations: list[tuple[int, str]] = []
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for alias in node.names:
                if alias.name.split(".")[0] in SDK_MODULES:
                    violations.append((node.lineno, alias.name))
        elif isinstance(node, ast.ImportFrom) and node.module:
            if node.module.split(".")[0] in SDK_MODULES:
                violations.append((node.lineno, node.module))
    return violations


def main(argv: list[str]) -> int:
    """Check every file passed by pre-commit; return 1 on any violation."""
    failures = 0
    for arg in argv[1:]:
        for lineno, module in find_violations(Path(arg)):
            print(f"{arg}:{lineno}: forbidden import '{module}' outside clients/")
            failures += 1
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
