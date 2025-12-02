#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CSV="$REPO_ROOT/data/names_roster.csv"
STL_SCRIPT="$SCRIPT_DIR/stls_to_step.py"
OUTDIR="$REPO_ROOT/output"
STEPDIR="$REPO_ROOT/steps"

mkdir -p "$STEPDIR"

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
    step="$STEPDIR/${id}.step"

    if [[ ! -f "$backing" || ! -f "$text" || ! -f "$logo" ]]; then
        echo "Skipping $id (missing STL files)"
        continue
    fi

    echo "Converting $id to STEP..."
    python3 "$STL_SCRIPT" "$id" "$backing" "$text" "$logo" "$step"
done

echo "All STEP files generated in $STEPDIR"
