#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///

"""Copy RAF files from SD card to date-organized folders."""

from pathlib import Path
from datetime import datetime
from collections import defaultdict
import subprocess
import shutil
import sys
import time


HOME = Path.home()
SRC_DIR = Path("/Volumes")
DST_BASE = HOME / "Pictures/PhotosRAWandXMP"
TEMP_DIR = HOME / "Pictures/temp-rsync-area"


def check_rsync() -> bool:
    """Check if rsync is available."""
    return shutil.which("rsync") is not None


def list_volumes() -> list[Path]:
    """List mounted volumes, excluding system volumes."""
    if not SRC_DIR.exists():
        return []

    volumes = [
        p for p in SRC_DIR.iterdir()
        if p.is_dir()
        and p.name not in ("Macintosh HD", "N")
        and not p.name.startswith("NSC")
        and not p.name.startswith(".")
    ]
    return sorted(volumes)


def pick_volume(volumes: list[Path]) -> Path | None:
    """Prompt user to select a volume."""
    if not volumes:
        print("No /Volumes found. Exiting.")
        return None

    print("Available volumes:\n")
    for i, vol in enumerate(volumes, 1):
        print(f"  [{i}] {vol.name}")
    print()
    choice = input("Select a volume number (or 0 to exit): ").strip()

    if choice in ("", "0"):
        print("Exiting.")
        return None

    if not choice.isdigit():
        print("Invalid selection. Exiting.")
        sys.exit(1)

    idx = int(choice) - 1
    if idx < 0 or idx >= len(volumes):
        print("Invalid selection. Exiting.")
        sys.exit(1)

    return volumes[idx]


def rsync_copy(src: Path) -> None:
    """Rsync all RAF files from src to TEMP_DIR."""
    cmd = [
        "rsync", "-av",
        "--ignore-existing",
        "--progress",
        "--stats",
        "--include=*/",
        "--include=*.RAF",
        "--exclude=*",
        str(src) + "/",
        str(TEMP_DIR) + "/",
    ]

    print(f"Running: {' '.join(cmd)}\n")

    subprocess.run(cmd)


def group_by_date(files: list[Path]) -> dict[str, list[Path]]:
    """Group files by modification date (YYYY-MM-DD)."""
    by_date: dict[str, list[Path]] = defaultdict(list)

    for f in files:
        mtime = f.stat().st_mtime
        date_str = datetime.fromtimestamp(mtime).strftime("%Y-%m-%d")
        by_date[date_str].append(f)

    return dict(by_date)


def move_to_dated_dirs(
    files_by_date: dict[str, list[Path]],
    base: Path,
) -> tuple[int, int]:
    """Move files to date-organized directories. Returns (moved, skipped)."""
    moved = 0
    skipped = 0

    for date_str, files in sorted(files_by_date.items()):
        dst_dir = base / date_str
        dst_dir.mkdir(parents=True, exist_ok=True)
        (dst_dir / "culled").mkdir(exist_ok=True)

        print(f"=== {date_str} ===")
        print(f"  Destination: {dst_dir}")

        for src_file in files:
            dst_file = dst_dir / src_file.name
            if dst_file.exists():
                print(f"  [SKIP] {src_file.name} — already exists")
                skipped += 1
            else:
                src_file.rename(dst_file)
                print(f"  [MOVE] {src_file.name}")
                moved += 1

        print(f"  Moved: {moved} | Skipped: {skipped}\n")

    return moved, skipped


def main() -> int:
    start_time = time.time()

    if not check_rsync():
        print("rsync not found. Exiting.")
        return 1

    # Step 1: Pick source volume
    volumes = list_volumes()
    src_dir = pick_volume(volumes)

    if src_dir is None:
        return 0

    print(f"Selected: {src_dir}\n")

    # Step 2: Rsync RAF files to temp dir
    print("=== Step 1: Copying from SD card to local temp dir ===\n")

    raf_count = sum(1 for _ in src_dir.rglob("*.RAF"))
    print(f"Found {raf_count} RAF file(s) on card\n")

    if raf_count == 0:
        print("No RAF files found. Exiting.")
        return 0

    TEMP_DIR.mkdir(parents=True, exist_ok=True)
    rsync_copy(src_dir)
    print()

    # Step 3: Group by date
    print("=== Step 2: Organizing by modification date ===\n")

    raf_files = list(TEMP_DIR.rglob("*.RAF"))
    total = len(raf_files)

    if total == 0:
        print("No RAF files found. Exiting.")
        return 0

    print(f"Found {total} RAF file(s)\n")

    by_date = group_by_date(raf_files)

    # Step 4: Move to destination
    print("=== Step 3: Copying to destination ===\n")

    DST_BASE.mkdir(parents=True, exist_ok=True)
    move_to_dated_dirs(by_date, DST_BASE)

    # Summary
    elapsed = int(time.time() - start_time)

    print("=== Done ===")
    print(f"Total time: {elapsed}s")

    return 0


if __name__ == "__main__":
    sys.exit(main())
