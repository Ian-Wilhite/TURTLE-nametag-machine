#!/usr/bin/env bash
set -euo pipefail

# Convert STL triplets (backing, text, logo) to 3MF files using PrusaSlicer CLI.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CSV="$REPO_ROOT/data/names_roster.csv"
OUTDIR="$REPO_ROOT/output"

# Find PrusaSlicer CLI
PRUSA_CLI=""
for cmd in prusa-slicer prusaslicer PrusaSlicer prusa-slicer-console; do
    if command -v "$cmd" &>/dev/null; then
        PRUSA_CLI="$cmd"
        break
    fi
done

if [[ -z "$PRUSA_CLI" ]]; then
    echo "Error: PrusaSlicer CLI not found in PATH" >&2
    exit 1
fi

# Collect tag IDs using the same rules as generate_nametag_stls.py
export REPO_ROOT
mapfile -t TAG_IDS < <(python3 - <<'PY'
import csv
import os
import pathlib
import re

root = pathlib.Path(os.environ["REPO_ROOT"])
csv_path = root / "data" / "names_roster.csv"

def slugify(name: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "_", name.lower())
    return slug.strip("_") or "nametag"

with csv_path.open(newline="", encoding="utf-8") as f:
    reader = csv.DictReader(f, skipinitialspace=True)
    if reader.fieldnames:
        reader.fieldnames = [fn.strip().lower() for fn in reader.fieldnames]
    for row in reader:
        name = (row.get("name") or "").strip()
        role = (row.get("role") or "").strip()
        username = (row.get("username") or "").strip()
        if not name or not role:
            continue
        tag_id = username or slugify(name)
        print(tag_id)
PY
)

for id in "${TAG_IDS[@]}"; do
    backing="$OUTDIR/${id}_backing.stl"
    text="$OUTDIR/${id}_text.stl"
    logo="$OUTDIR/${id}_logo.stl"
    output_3mf="$OUTDIR/${id}.3mf"

    if [[ ! -f "$backing" || ! -f "$text" || ! -f "$logo" ]]; then
        echo "Skipping $id (missing STL files)"
        continue
    fi

    echo "Converting $id to 3MF..."
    "$PRUSA_CLI" --merge --dont-arrange --export-3mf -o "$output_3mf" "$backing" "$text" "$logo"
done

echo "All 3MF files generated in $OUTDIR"
