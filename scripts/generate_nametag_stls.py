#!/usr/bin/env python3
import csv
import re
import shlex
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
CSV_FILE = REPO_ROOT / "data" / "names_roster.csv"
SCAD_FILE = REPO_ROOT / "scad" / "Turtle_nametag.scad"
OUTPUT_DIR = REPO_ROOT / "output"
DEFAULT_ORG = "TURTLE"

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


def slugify(name: str) -> str:
    """
    Create a filesystem-friendly slug from a name.
    """
    slug = re.sub(r"[^a-z0-9]+", "_", name.lower())
    return slug.strip("_") or "nametag"


def run_openscad(output_path, name_text, position_text, org_text, part):
    """
    Calls OpenSCAD to generate an STL for a specific part and text combo.
    """
    cmd = [
        "openscad",
        "-o",
        str(output_path),
        "-D",
        f'name_text="{name_text}"',
        "-D",
        f'position_text="{position_text}"',
        "-D",
        f'org_text="{org_text}"',
        "-D",
        f'part="{part}"',
        str(SCAD_FILE),
    ]
    print("Running:", " ".join(shlex.quote(c) for c in cmd))
    subprocess.run(cmd, check=True)


def main():
    with CSV_FILE.open(newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f, skipinitialspace=True)
        if reader.fieldnames:
            reader.fieldnames = [fn.strip().lower() for fn in reader.fieldnames]

        for row in reader:
            name = (row.get("name") or "").strip()
            role = (row.get("role") or "").strip()
            username = (row.get("username") or "").strip()

            if not name or not role:
                print("Skipping row with missing name/role:", row)
                continue

            tag_id = username or slugify(name)
            org = (row.get("org") or DEFAULT_ORG).strip()

            backing_stl = OUTPUT_DIR / f"{tag_id}_backing.stl"
            text_stl = OUTPUT_DIR / f"{tag_id}_text.stl"
            logo_stl = OUTPUT_DIR / f"{tag_id}_logo.stl"

            stls = [backing_stl, text_stl, logo_stl]
            if all(p.exists() for p in stls):
                for p in stls:
                    print(f"Already exists, skipping: {p}")
                continue

            run_openscad(backing_stl, name, role, org, "backing")
            run_openscad(text_stl, name, role, org, "text")
            run_openscad(logo_stl, name, role, org, "logo")

    print(f"Done generating STLs to {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
