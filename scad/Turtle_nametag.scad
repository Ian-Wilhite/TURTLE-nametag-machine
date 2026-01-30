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

text_depth      = 0.6;
font_name       = "Liberation Sans:style=Bold";

///////////////////////////////
// Logo Position Parameters
///////////////////////////////
logo_center_x   = 43.5;
logo_center_y   = 19.5;
logo_svg_width  = 1136;   // native SVG width
logo_svg_height = 1144;   // native SVG height
logo_scale      = 0.045; // tuned so logo fits the 20 mm logo area

// Back pocket cutout (on backside)
pocket_len   = 45;  // mm (X)
pocket_wid   = 13;  // mm (Y)
pocket_depth = 2;   // mm (Z)
pocket_center = [0, 0]; // x,y center of the pocket (edit as needed)
fillet_r = 1.2; // mm

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
      0 ];

function position_text_pos() =
    [ left_center_x(),
      -6,
      0 ];

function org_text_pos() =
    [ right_center_x() - 3,
     -plate_height/2 + 0.85 * bottom_margin + org_size/2,
      0 ];

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
    mirror([0, 1, 0]) {
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
}

// Logo body from STL slice
module logo_body() {
    union() {
        logo_yellow();
        logo_white();
    }
}


module rounded_prism_xy(len, wid, ht, r=2) {
    // Rounds only the XY corners; Z edges remain sharp (a true extruded rounded-rectangle).
    linear_extrude(height = ht)
        translate([r, r])
            offset(r = r)
                square([len - 2*r, wid - 2*r], center = false);
}

module back_pocket() {
    translate([
        pocket_center[0] - pocket_len/2,
        pocket_center[1] - pocket_wid/2,
        plate_thickness - pocket_depth
    ])
    rounded_prism_xy(pocket_len, pocket_wid, pocket_depth + 0.01, fillet_r);
}
///////////////////////////////
// Backing plate with text and logo cavities
module backing_with_cavities() {
    difference() {
        backing();
        all_text();
        logo_body();
        back_pocket();   // <-- add this
    }
}

///////////////////////////////
module rounded_rect_2d(len, ht, r) {
    minkowski() {
        square([len - 2*r, ht - 2*r], center=true);
        circle(r=r, $fn=64);
    }
}

///////////////////////////////
// Turtle Logo from SVG layers
///////////////////////////////
// Common transform for each SVG layer so the logo stays centered and scaled.
module turtle_logo_layer(svg_path) {
    mirror([0, 1, 0])
        translate([logo_center_x, logo_center_y, 0])
            linear_extrude(height = text_depth)
                scale(logo_scale)
                    translate([-logo_svg_width/2, -logo_svg_height/2])
                        import(svg_path, convexity = 10);
}

module logo_yellow() {
    color("#edcb24") turtle_logo_layer("assets/color_edcb24.svg");
}

module logo_white() {
    color("#f6f6f6") turtle_logo_layer("assets/color_f6f6f6.svg");
}

///////////////////////////////
// Assembly / top-level selection
///////////////////////////////
if (part == "backing") {
    color("black") backing_with_cavities();
}
else if (part == "text") {
    color("lightgray") union() {
        all_text();      // name, position, org
        logo_white();    // white layer of the turtle logo
    }
}
else if (part == "logo") {
    // Only the yellow portion is exported separately; the white rides with text
    color("#edcb24") logo_yellow();
}
else {  // full assembly for preview
    color("white") backing_with_cavities();
    color("lightgray") union() {
        all_text();
        logo_white();
    }
    color("#edcb24") logo_yellow();
}
