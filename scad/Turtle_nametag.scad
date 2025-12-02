///////////////////////////////
// Export selector
// "all" | "backing" | "text" | "logo"
///////////////////////////////
part = "all";

///////////////////////////////
// Parameters
///////////////////////////////
plate_length    = 80;    // mm (8 cm)
plate_height    = 30;    // mm (3 cm)
plate_thickness = 3;     // mm
corner_radius   = 5;     // mm (0.5 cm fillet)

left_width      = 60;    // mm (text area)
right_width     = 20;    // mm (logo area)

name_text       = "Kalen Jarosasdgqy";
position_text   = "Development Vice President";
org_text        = "TURTLE";

// These are *maximum* sizes now
name_size_max      = 4;     // mm
position_size_max  = 2.75;      // mm
org_size_max       = 3.5;     // mm

text_depth      = 0.7;
font_name       = "Liberation Sans:style=Bold";

///////////////////////////////
// Logo Position Parameters
///////////////////////////////
logo_center_x   = 16;
logo_center_y   = 11.5;

///////////////////////////////
// Auto text sizing helpers
///////////////////////////////
function autosize_text_legacy(str, target_width, size_max) =
    let(char_factor = 0.55)       // approx width ≈ 0.55 * size * chars
    let(approx_width = len(str) * size_max * char_factor)
    approx_width > target_width ?
        size_max * target_width / approx_width :
        size_max;

// Actual sizes used (depend on the strings)
name_size     = autosize_text_legacy(name_text,     left_width*0.9,  name_size_max);
position_size = autosize_text_legacy(position_text, left_width*0.9,  position_size_max);
org_size      = autosize_text_legacy(org_text,      plate_length*0.9, org_size_max);

///////////////////////////////
// Text Position Helpers
///////////////////////////////
top_margin      = 7;
bottom_margin   = 4;

function left_center_x() = -(plate_length/2 - left_width/2);
function right_center_x() = (plate_length/2 - right_width/2);


function name_text_pos() =
    [ left_center_x(),
      plate_height/2 - top_margin*5/4 - name_size,
      plate_thickness ];

function position_text_pos() =
    [ left_center_x(),
      -6,
      plate_thickness ];

function org_text_pos() =
    [ right_center_x() - 3,
     -plate_height/2 + bottom_margin + org_size/2,
      plate_thickness ];

///////////////////////////////
// Geometry modules
///////////////////////////////

// Backing plate
module backing() {
    linear_extrude(height = plate_thickness)
        rounded_rect_2d(plate_length, plate_height, corner_radius);
}

// All text bodies (name + position + org), as one solid
module all_text() {
    // Name
    translate(name_text_pos())
        linear_extrude(height = text_depth)
            text(name_text, size=name_size,
                 halign="center", valign="center", font=font_name);

    // Position
    translate(position_text_pos())
        linear_extrude(height = text_depth)
            text(position_text, size=position_size,
                 halign="center", valign="center", font=font_name);

    // Org line
    translate(org_text_pos())
        linear_extrude(height = text_depth)
            text(org_text, size=org_size,
                 halign="center", valign="center", font=font_name);
}

// Logo body from STL slice
module logo_body() {
    translate([logo_center_x, logo_center_y, plate_thickness])
        turtle_logo(text_depth);
}

///////////////////////////////
// Rounded Rectangle
///////////////////////////////
module rounded_rect_2d(len, ht, r) {
    minkowski() {
        square([len - 2*r, ht - 2*r], center=true);
        circle(r=r, $fn=64);
    }
}

///////////////////////////////
// Turtle Logo from STL
///////////////////////////////
// slice_z lets you choose which Z-height to slice through
module turtle_logo(height, slice_z = -1) {
    // tweak scale until logo fits in right_width x plate_height nicely
    logo_scale = 0.0105;  

    linear_extrude(height = height)
        scale(logo_scale)
            projection(cut = false)
                translate([0, 0, -slice_z])   // slice at z = slice_z
                    rotate([90, 0, 0])        // your previous orientation
                        import("Turtle_logo.STL", convexity = 10);
}

///////////////////////////////
// Assembly / top-level selection
///////////////////////////////
if (part == "backing") {
    color("black") backing();
}
else if (part == "text") {
    color("lightgray") all_text();
}
else if (part == "logo") {
    color("green") logo_body();
}
else {  // full assembly for preview
    color("black") backing();
    color("lightgray")     all_text();
    color("green")     logo_body();
}
