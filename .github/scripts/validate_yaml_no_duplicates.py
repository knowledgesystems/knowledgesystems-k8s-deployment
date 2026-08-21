#!/usr/bin/env python3

import sys
from pathlib import Path

from ruamel.yaml import YAML


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print(
            "usage: validate_yaml_no_duplicates.py <yaml-file> [<yaml-file> ...]",
            file=sys.stderr,
        )
        return 2

    yaml = YAML(typ="safe")
    yaml.allow_duplicate_keys = False
    failed = False

    for raw_path in argv[1:]:
        path = Path(raw_path)
        try:
            with path.open("r", encoding="utf-8") as handle:
                for _ in yaml.load_all(handle):
                    pass
        except Exception as exc:  # pragma: no cover - exercised in CI
            print(f"::error file={path}::{exc}")
            failed = True

    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
