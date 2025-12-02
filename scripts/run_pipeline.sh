#!/usr/bin/env bash
set -euo pipefail

# Run the full pipeline: generate STLs, then convert to STEP.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$REPO_ROOT/output"

cd "$REPO_ROOT"

echo "Step 1/2: Generating STLs from CSV..."
python3 "$SCRIPT_DIR/generate_nametag_stls.py"

# Ensure STLs exist before attempting STEP conversion
shopt -s nullglob
stl_files=("$OUTPUT_DIR"/*.stl)
shopt -u nullglob
if [[ ${#stl_files[@]} -eq 0 ]]; then
    echo "Error: No STL files found in $OUTPUT_DIR; generation may have failed." >&2
    exit 1
fi

echo "Step 2/2: Converting STLs to STEP..."
FCAD="${FCAD:-}" "$SCRIPT_DIR/batch_stls_to_step.sh"

echo "Pipeline complete."
