"""Inspect an existing DuckDB without creating or modifying the source file."""

import argparse
import hashlib
import json
from pathlib import Path

import duckdb


def inspect_database(path: Path) -> dict:
    path = path.resolve(strict=True)
    with path.open("rb") as source:
        digest = hashlib.file_digest(source, "sha256").hexdigest()
    with duckdb.connect(str(path), read_only=True) as connection:
        tables = connection.execute(
            "SELECT table_schema, table_name, table_type "
            "FROM information_schema.tables ORDER BY table_schema, table_name"
        ).fetchdf().to_dict(orient="records")
    return {
        "path": str(path),
        "size_bytes": path.stat().st_size,
        "sha256": digest,
        "tables": tables,
        "table_count": len(tables),
        "status": "empty" if not tables else "requires_schema_and_coverage_review",
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("database", nargs="?", type=Path, default=Path("Data/nba.duckdb"))
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    report = inspect_database(args.database)
    rendered = json.dumps(report, indent=2) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered)
    print(rendered, end="")
