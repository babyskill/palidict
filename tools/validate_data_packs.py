#!/usr/bin/env python3
"""Validate every data pack (*.db) under data/.

Checks, per pack:
  1. The file opens as SQLite and `PRAGMA integrity_check` passes.
  2. The required tables and columns from data/DATA_SPEC.md are present.
  3. `headwords` and `lookup` are non-empty and `lookup.headwords` holds
     a JSON list of entry ids in every row.

The required contract is the same for every pack, so packs stay
interchangeable. Packs may add extra tables/columns (Core does; see
DATA_SPEC.md) — only the required set is enforced.

Usage: python3 tools/validate_data_packs.py [pack ...]
With no arguments every *.db / *.sqlite* file under data/ is validated.
Exits non-zero and prints a report when any pack fails.
"""

from __future__ import annotations

import json
import sqlite3
import sys
from pathlib import Path
from urllib.parse import quote

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
PACK_SUFFIXES = {".db", ".sqlite", ".sqlite3"}

# Required tables and columns (Lite baseline from data/DATA_SPEC.md).
REQUIRED_SCHEMA = {
    "headwords": {
        "id", "lemma_1", "lemma_2", "pos", "grammar", "meaning_1",
        "meaning_lit", "meaning_2", "root_key", "root_sign", "construction",
        "phonetic", "source_1", "sutta_1", "example_1", "antonym",
        "synonym", "ebt_count",
    },
    "lookup": {"lookup_key", "headwords", "deconstructor", "grammar"},
    "roots": {"root"},
    "meaning_vi": {
        "lemma_key", "lemma", "pos", "gloss_main", "gloss_full", "source",
    },
    "meaning_vi_senses": {"entry_id", "vi_gloss", "source"},
}

NON_EMPTY_TABLES = ("headwords", "lookup")


def find_packs(paths: list[str]) -> list[Path]:
    if paths:
        return [Path(p) for p in paths]
    if not DATA_DIR.is_dir():
        return []
    return sorted(
        p for p in DATA_DIR.rglob("*")
        if p.is_file() and p.suffix in PACK_SUFFIXES
    )


def table_columns(db: sqlite3.Connection, table: str) -> set[str]:
    return {row[1] for row in db.execute(f'PRAGMA table_info("{table}")')}


def validate_pack(path: Path) -> list[str]:
    errors: list[str] = []
    try:
        db = sqlite3.connect(f"file:{quote(str(path))}?mode=ro", uri=True)
    except sqlite3.Error as e:
        return [f"cannot open as SQLite: {e}"]

    try:
        integrity = db.execute("PRAGMA integrity_check").fetchone()
        if integrity is None or integrity[0] != "ok":
            errors.append(f"integrity_check failed: {integrity[0] if integrity else 'no result'}")

        tables = {
            row[0]
            for row in db.execute(
                "SELECT name FROM sqlite_master WHERE type = 'table'"
            )
        }
        for table, required_cols in REQUIRED_SCHEMA.items():
            if table not in tables:
                errors.append(f"missing required table: {table}")
                continue
            missing = required_cols - table_columns(db, table)
            if missing:
                errors.append(
                    f"table {table} missing columns: {', '.join(sorted(missing))}"
                )

        for table in NON_EMPTY_TABLES:
            if table in tables:
                count = db.execute(f'SELECT COUNT(*) FROM "{table}"').fetchone()[0]
                if count == 0:
                    errors.append(f"table {table} is empty")

        if "lookup" in tables:
            headword_ids = (
                {row[0] for row in db.execute("SELECT id FROM headwords")}
                if "id" in table_columns(db, "headwords")
                else set()
            )
            bad = 0
            empty = 0
            dangling = 0
            for (raw,) in db.execute("SELECT headwords FROM lookup"):
                if not isinstance(raw, str):
                    bad += 1
                    continue
                try:
                    ids = json.loads(raw)
                except json.JSONDecodeError:
                    bad += 1
                    continue
                if not isinstance(ids, list) or not all(
                    isinstance(i, int) for i in ids
                ):
                    bad += 1
                elif not ids:
                    empty += 1
                elif headword_ids and all(i not in headword_ids for i in ids):
                    # A lookup row with zero resolvable ids yields an empty
                    # results page in the app. Partial misses are normal:
                    # Lite shares the full lookup index while shipping only
                    # a subset of headwords.
                    dangling += 1
            if bad:
                errors.append(
                    f"lookup.headwords is not a JSON list of ids in {bad} row(s)"
                )
            if empty:
                errors.append(
                    f"lookup.headwords is an empty list in {empty} row(s)"
                )
            if dangling:
                errors.append(
                    f"lookup.headwords has no id present in headwords "
                    f"in {dangling} row(s)"
                )
    finally:
        db.close()
    return errors


def main() -> int:
    packs = find_packs(sys.argv[1:])
    if not packs:
        print("No data packs found under data/.")
        return 1

    failed = 0
    for pack in packs:
        try:
            rel = pack.resolve().relative_to(DATA_DIR.parent)
        except ValueError:
            rel = pack
        errors = validate_pack(pack)
        if errors:
            failed += 1
            print(f"FAIL {rel}")
            for e in errors:
                print(f"  - {e}")
        else:
            print(f"OK   {rel}")

    print(f"\n{len(packs) - failed}/{len(packs)} pack(s) valid.")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
