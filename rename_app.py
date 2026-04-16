#!/usr/bin/env python3
from pathlib import Path
import argparse
import sys

SKIP_DIRS = {
    ".git",
    "__pycache__",
    "build",
    "dist",
}

SKIP_SUFFIXES = {
    ".png", ".jpg", ".jpeg", ".gif", ".bmp", ".webp",
    ".pdf", ".zip", ".gz", ".tgz", ".xz", ".bz2",
    ".o", ".a", ".so", ".dll", ".exe",
    ".pyc",
}

def is_probably_text(path: Path) -> bool:
    if path.suffix.lower() in SKIP_SUFFIXES:
        return False
    try:
        with path.open("rb") as f:
            chunk = f.read(2048)
        return b"\x00" not in chunk
    except Exception:
        return False

def replace_in_file(path: Path, old: str, new: str, dry_run: bool) -> bool:
    try:
        text = path.read_text(encoding="utf-8")
    except:
        return False

    if old not in text:
        return False

    if not dry_run:
        path.write_text(text.replace(old, new), encoding="utf-8")

    return True

def rename_paths(root: Path, old: str, new: str, dry_run: bool):
    # sort paths deepest first so we rename children before parents
    paths = sorted(root.rglob("*"), key=lambda p: len(p.parts), reverse=True)

    renamed = []
    for path in paths:
        if any(part in SKIP_DIRS for part in path.parts):
            continue

        if old in path.name:
            new_name = path.name.replace(old, new)
            new_path = path.with_name(new_name)

            if not dry_run:
                path.rename(new_path)

            renamed.append((path, new_path))

    return renamed

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("old")
    parser.add_argument("new")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    root = Path(".").resolve()

    # Step 1: replace inside files
    changed_files = []
    for path in root.rglob("*"):
        if not path.is_file():
            continue

        if any(part in SKIP_DIRS for part in path.parts):
            continue

        if not is_probably_text(path):
            continue

        if replace_in_file(path, args.old, args.new, args.dry_run):
            changed_files.append(path)

    # Step 2: rename files + directories
    renamed_paths = rename_paths(root, args.old, args.new, args.dry_run)

    # Output
    print("\nContent changes:")
    for f in changed_files:
        print(f"  {'Would update' if args.dry_run else 'Updated'}: {f}")

    print("\nRenamed paths:")
    for old_p, new_p in renamed_paths:
        print(f"  {'Would rename' if args.dry_run else 'Renamed'}: {old_p} -> {new_p}")

    print(f"\nTotal files changed: {len(changed_files)}")
    print(f"Total paths renamed: {len(renamed_paths)}")

if __name__ == "__main__":
    sys.exit(main())