"""Enforce the infra root contract: main.tf/stack_*.tf wire, custom_*.tf extends.

``infra/main.tf`` and ``infra/stack_*.tf`` may contain only ``locals`` and
``module`` blocks; the terraform/provider blocks live in ``providers.tf``
and are agent-locked. Raw resources and data sources are allowed only inside
``custom_*.tf`` files (the Tier-2 escape hatch), never in main.tf,
stack_*.tf, variables.tf, outputs.tf, outputs_*.tf, or providers.tf.
"""

import re
import sys
from pathlib import Path

FORBIDDEN_IN_MAIN = re.compile(
    r'^\s*(terraform\s*\{|provider\s+"|resource\s+"|data\s+")', re.MULTILINE
)
FORBIDDEN_IN_STABLE = re.compile(r'^\s*(resource\s+"|data\s+")', re.MULTILINE)


def _is_root_tf(path: Path) -> bool:
    """True only for .tf files directly under infra/, never in modules/."""
    return len(path.parts) == 2 and path.parts[0] == "infra" and path.suffix == ".tf"


def find_violations(path: Path) -> list[str]:
    """Return the forbidden block types found in a root .tf file."""
    text = path.read_text(encoding="utf-8")
    if path.name == "main.tf" or path.name.startswith("stack_"):
        return FORBIDDEN_IN_MAIN.findall(text)
    if path.name in {
        "variables.tf",
        "outputs.tf",
        "providers.tf",
    } or path.name.startswith("outputs_"):
        return FORBIDDEN_IN_STABLE.findall(text)
    return []


def main(argv: list[str]) -> int:
    """Check root .tf files; return 1 on any forbidden block."""
    failures = 0
    for arg in argv[1:]:
        path = Path(arg)
        if path.name.startswith("custom_") or not _is_root_tf(path):
            continue
        violations = find_violations(path)
        if violations:
            print(f"{arg}: forbidden blocks {sorted(set(violations))} in root file")
            failures += 1
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
