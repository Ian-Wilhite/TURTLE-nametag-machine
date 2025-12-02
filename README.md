# TURTLE Nametag Generator
Generate multi-material nametags from a CSV roster using OpenSCAD (STL).

## How it works
- Read `data/names_roster.csv`.
- For each row, `scripts/generate_nametag_stls.py` calls OpenSCAD to export three aligned STLs: backing, text, and logo.

## Repo layout
- `scad/Turtle_nametag.scad`: Parametric nametag model and logo projection.
- `data/names_roster.csv`: Input roster (`role,name,email,username[,org]`).
- `scripts/generate_nametag_stls.py`: CSV → `<id>_backing.stl`, `<id>_text.stl`, `<id>_logo.stl` in `output/`.

## Requirements
- OpenSCAD 2021+ (CLI available as `openscad`)
- Python 3.9+ (standard library only for STL generation)
- Bash (for the batch helper)

## Input CSV
 - `data/names_roster.csv` needs headers and one person per line:
```
role,name,email,username[,org]
Internal VP,Ian Wilhite,ian.wilhite0@tamu.edu,en._.ig
Finance Officer,Eddy Silva,esilva@tamu.edu,.halfnote
```
- `username` becomes the file id; if blank, a slugified name is used.
- Optional `org` overrides the default `TURTLE` text on the tag.

## Generate STLs (primary output)
From the repo root:
```bash
python3 scripts/generate_nametag_stls.py
```
- Outputs to `output/<id>_backing.stl`, `_text.stl`, `_logo.stl`.
- Existing files are skipped to avoid re-rendering.


## Slicer usage
- **3-STL method:** Import the three STLs as a multipart object; they share an origin and remain aligned.

## Future work
- Built-in STL→STEP toggle on the main script (no separate helper needed).
- Config switches for geometry tweaks (e.g., enable/disable plate fillets, emboss vs. engrave logo).
- Smarter autosizing for long names/roles with optional manual overrides.
