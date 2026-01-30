#!/usr/bin/env bash
set -euo pipefail

# Run the full pipeline: generate STLs, convert to STEP, and create 3MF files.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$REPO_ROOT/output"
VENV_DIR="$REPO_ROOT/occ-venv"

cd "$REPO_ROOT"

# Activate virtual environment
source "$VENV_DIR/bin/activate"

echo "Step 1/3: Generating STLs from CSV..."
python "$SCRIPT_DIR/generate_nametag_stls.py"

# Ensure STLs exist before attempting STEP conversion
shopt -s nullglob
stl_files=("$OUTPUT_DIR"/*.stl)
shopt -u nullglob
if [[ ${#stl_files[@]} -eq 0 ]]; then
    echo "Error: No STL files found in $OUTPUT_DIR; generation may have failed." >&2
    exit 1
fi

echo "Step 2/3: Converting STLs to STEP..."
# Only run STEP conversion if cadquery-ocp is available
if "$VENV_DIR/bin/python" -c "import OCP" 2>/dev/null; then
    "$SCRIPT_DIR/batch_stls_to_step.sh"
else
    echo "Warning: cadquery-ocp not available; skipping STEP conversion."
    echo "To enable STEP conversion, install cadquery-ocp: pip install cadquery-ocp"
fi

echo "Step 3/3: Converting STLs to 3MF..."
# Only run 3MF conversion if PrusaSlicer CLI is available
if command -v prusa-slicer &>/dev/null || command -v prusaslicer &>/dev/null || command -v PrusaSlicer &>/dev/null; then
    "$SCRIPT_DIR/batch_stls_to_3mf.sh"
else
    echo "Warning: PrusaSlicer CLI not available; skipping 3MF conversion."
    echo "To enable 3MF conversion, install PrusaSlicer and ensure it's in your PATH."
fi

echo "Pipeline complete."
