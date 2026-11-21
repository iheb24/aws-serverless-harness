"""Build deployment zips for every backend workload package into dist/.

Each package directory under backend/ (excluding tests) is archived as
``dist/<package>.zip`` with the package at the archive root, matching the
layout Lambda expects. The harness runs this after scaffolding workloads;
CI runs it before ``terraform apply``.
"""

import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BACKEND = ROOT / "backend"
DIST = ROOT / "dist"


def main() -> None:
    """Zip each workload package as dist/<package>.zip and print its path."""
    DIST.mkdir(exist_ok=True)
    packages = [
        path
        for path in BACKEND.iterdir()
        if path.is_dir() and path.name != "tests" and (path / "__init__.py").is_file()
    ]
    for package in sorted(packages):
        archive = shutil.make_archive(
            str(DIST / package.name), "zip", root_dir=BACKEND, base_dir=package.name
        )
        print(Path(archive).relative_to(ROOT))


if __name__ == "__main__":
    main()
