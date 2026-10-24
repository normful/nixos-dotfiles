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
COPY_LIST = TEMP_DIR / ".to-copy.txt"


def check_rsync() -> bool:
    """Check if rsync is available."""
    return shutil.which("rsync") is not None


def list_volumes() -> list[Path]:
    """List mounted volumes, excluding system volumes."""
    if not SRC_DIR.exists():
        return []

    volumes = [
        p
        for p in SRC_DIR.iterdir()
        if p.is_dir()
        and p.name not in ("Macintosh HD", "N")
        and not p.name.startswith("NSC")
        and not p.name.startswith(".")
    ]
    return sorted(volumes)


def pick_volume(volumes: list[Path]) -> Path | None:
    """Prompt user to select a volume."""
    if not volumes:
        print("No /Volumes found. Try plugging in and out the SD card again.")
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


def date_of(path: Path) -> str:
    """Date bucket for a file, from its modification time."""
    return datetime.fromtimestamp(path.stat().st_mtime).strftime("%Y-%m-%d")


def index_destination(base: Path) -> set[tuple[str, str]]:
    """Key every already-imported photo as (date dir name, file name)."""
    keys: set[tuple[str, str]] = set()

    if not base.exists():
        return keys

    for date_dir in base.iterdir():
        if not date_dir.is_dir() or not date_dir.name[:2].isdigit():
            continue
        for f in date_dir.rglob("*.RAF"):
            keys.add((date_dir.name, f.name))

    return keys


def plan_copy(src: Path, dst_keys: set[tuple[str, str]]) -> list[tuple[str, int]]:
    """Return (path relative to src, size) for card files not yet in the destination."""
    pending: list[tuple[str, int]] = []

    for f in sorted(src.rglob("*.RAF")):
        if not f.is_file():
            continue
        if (date_of(f), f.name) in dst_keys:
            continue
        st = f.stat()
        pending.append((str(f.relative_to(src)), st.st_size))

    return pending


def rsync_copy(src: Path, pending: list[tuple[str, int]]) -> None:
    """Rsync only the pending RAF files from src to TEMP_DIR."""
    COPY_LIST.parent.mkdir(parents=True, exist_ok=True)
    COPY_LIST.write_text("".join(rel + "\n" for rel, _ in pending))

    cmd = [
        "rsync",
        "-rt",
        "--size-only",
        f"--files-from={COPY_LIST}",
        "--info=progress2",
        "--stats",
        str(src) + "/",
        str(TEMP_DIR) + "/",
    ]

    print(f"Running: {' '.join(cmd)}\n")

    subprocess.run(cmd, check=True)


def verify_copies(pending: list[tuple[str, int]]) -> list[str]:
    """Return pending paths whose temp copy is missing or the wrong size."""
    bad: list[str] = []

    for rel, size in pending:
        copied = TEMP_DIR / rel
        if not copied.is_file() or copied.stat().st_size != size:
            bad.append(rel)

    return bad


def group_by_date(files: list[Path]) -> dict[str, list[Path]]:
    """Group files by modification date (YYYY-MM-DD)."""
    by_date: dict[str, list[Path]] = defaultdict(list)

    for f in files:
        by_date[date_of(f)].append(f)

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


def purge_temp_duplicates(base: Path) -> int:
    """Delete temp files whose identical copy already sits in the destination."""
    removed = 0

    for f in TEMP_DIR.rglob("*.RAF"):
        date_dir = base / date_of(f)
        destinations = (date_dir / f.name, date_dir / "culled" / f.name)
        for dst_file in destinations:
            if dst_file.is_file() and dst_file.stat().st_size == f.stat().st_size:
                f.unlink()
                removed += 1
                break

    return removed


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

    # Step 2: Rsync only what the destination is missing
    print("=== Step 1: Copying from SD card to local temp dir ===\n")

    dst_keys = index_destination(DST_BASE)
    pending = plan_copy(src_dir, dst_keys)
    pending_bytes = sum(size for _, size in pending)

    print(f"Destination already holds {len(dst_keys)} photo(s)")
    print(
        f"{len(pending)} RAF file(s) need copying "
        f"({pending_bytes / 1e9:.2f} GB)\n"
    )

    if not pending:
        print("Nothing to copy — this card is fully imported.")
        return 0

    TEMP_DIR.mkdir(parents=True, exist_ok=True)
    rsync_copy(src_dir, pending)
    print()

    bad = verify_copies(pending)
    if bad:
        print(f"{len(bad)} file(s) did not copy cleanly:")
        for rel in bad[:10]:
            print(f"  [BAD] {rel}")
        print("Leaving temp dir untouched. Re-run to retry.")
        return 1

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

    purged = purge_temp_duplicates(DST_BASE)
    if purged:
        print(f"Cleaned {purged} leftover file(s) from temp dir\n")

    # Summary
    elapsed = int(time.time() - start_time)

    print("=== Done ===")
    print(f"Total time: {elapsed}s")

    return 0


if __name__ == "__main__":
    sys.exit(main())
