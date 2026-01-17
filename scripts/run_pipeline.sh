#!/usr/bin/env bash
set -euo pipefail

# Run the full pipeline: generate STLs, then convert to STEP.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$REPO_ROOT/output"
VENV_DIR="$REPO_ROOT/occ-venv"

cd "$REPO_ROOT"

# Activate virtual environment
source "$VENV_DIR/bin/activate"

echo "Step 1/2: Generating STLs from CSV..."
python "$SCRIPT_DIR/generate_nametag_stls.py"

# Ensure STLs exist before attempting STEP conversion
shopt -s nullglob
stl_files=("$OUTPUT_DIR"/*.stl)
shopt -u nullglob
if [[ ${#stl_files[@]} -eq 0 ]]; then
    echo "Error: No STL files found in $OUTPUT_DIR; generation may have failed." >&2
    exit 1
fi

echo "Step 2/2: Converting STLs to STEP..."
# Only run STEP conversion if pythonocc-core is available
if "$VENV_DIR/bin/python" -c "import OCC" 2>/dev/null; then
    FCAD="${FCAD:-}" "$SCRIPT_DIR/batch_stls_to_step.sh"
else
    echo "Warning: pythonocc-core not available; skipping STEP conversion."
    echo "To enable STEP conversion, install pythonocc-core: pip install pythonocc-core"
fi

echo "Pipeline complete."
