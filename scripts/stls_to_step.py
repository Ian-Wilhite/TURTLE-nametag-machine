#!/usr/bin/env python3
"""
Convert three aligned STL meshes (backing, text, logo) into a single multi-body STEP file.
Uses pythonocc-core (OCC) instead of FreeCAD CLI.
"""
import sys
import os

try:
    from OCC.Core.BRep import BRep_Builder
    from OCC.Core.STEPControl import STEPControl_Writer, STEPControl_AsIs
    from OCC.Core.StlAPI import StlAPI_Reader
    from OCC.Core.TopoDS import TopoDS_Compound, TopoDS_Shape
    from OCC.Core.IFSelect import IFSelect_RetDone
except Exception as exc:  # pragma: no cover - import guard
    sys.stderr.write(
        "Error: pythonocc-core is required for STL→STEP conversion. "
        "Install with `pip install pythonocc-core`.\n"
    )
    sys.exit(1)


def load_stl(path: str) -> TopoDS_Shape:
    """Read an STL file into a TopoDS_Shape."""
    reader = StlAPI_Reader()
    shape = TopoDS_Shape()
    ok = reader.Read(shape, path)
    if not ok or shape.IsNull():
        raise RuntimeError(f"Failed to read STL: {path}")
    return shape


def make_compound(shapes):
    """Combine shapes into one compound."""
    builder = BRep_Builder()
    comp = TopoDS_Compound()
    builder.MakeCompound(comp)
    for s in shapes:
        builder.Add(comp, s)
    return comp


def export_step(shape, out_path: str):
    """Write a STEP file from the given shape."""
    writer = STEPControl_Writer()
    writer.Transfer(shape, STEPControl_AsIs)
    status = writer.Write(out_path)
    if status != IFSelect_RetDone:
        raise RuntimeError(f"STEP export failed with status {status}")


def main():
    if len(sys.argv) != 6:
        print("Usage: stls_to_step.py <id> <backing.stl> <text.stl> <logo.stl> <output.step>")
        sys.exit(1)

    tag_id = sys.argv[1]
    backing_stl = sys.argv[2]
    text_stl = sys.argv[3]
    logo_stl = sys.argv[4]
    out_step = sys.argv[5]

    for path in (backing_stl, text_stl, logo_stl):
        if not os.path.isfile(path):
            print(f"Error: missing input STL: {path}", file=sys.stderr)
            sys.exit(1)

    try:
        backing_shape = load_stl(backing_stl)
        text_shape = load_stl(text_stl)
        logo_shape = load_stl(logo_stl)

        compound = make_compound([backing_shape, text_shape, logo_shape])

        if os.path.exists(out_step):
            os.remove(out_step)
        export_step(compound, out_step)
        print(f"Exported STEP: {out_step}")
    except Exception as exc:
        print(f"Failed to export STEP for {tag_id}: {exc}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
