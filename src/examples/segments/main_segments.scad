/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

use <../../polysymmetrica/core/funcs.scad>
use <../../polysymmetrica/core/placement.scad>
use <../../polysymmetrica/core/prisms.scad>
use <../../polysymmetrica/core/segments.scad>

// Segments demo surface.
// Shows the main face-local segment-analysis modules on one star antiprism:
// parity fill, winding fill, segmented cells, geometry cuts, and visible cells.

IR = 30;
FACE_THK = 0.35;
LINE_R = 1.35;
TXT_H = 0.18;
TXT_S = 3.8;
PANEL_X = 125;

P = poly_antiprism(5, 2);
FACES = poly_faces(P);
STAR_FACE_IDX = 1;
SIDE_FACE_IDX = 8;

// Function: cell_color()
// Usage:
//   result = cell_color(i);
// Description:
//   Pick a strongly differentiated named color for cell visualization.
//   .
//   - Returns: a named color string
// Arguments:
//   i = cell index
function cell_color(i) =
    (i % 6 == 0) ? "tomato" :
    (i % 6 == 1) ? "gold" :
    (i % 6 == 2) ? "mediumseagreen" :
    (i % 6 == 3) ? "deepskyblue" :
    (i % 6 == 4) ? "orchid" :
    "darkorange";

// Module: draw_panel_label()
// Usage:
//   draw_panel_label(s);
// Description:
//   Draw a world-space label below one panel.
//   .
//   - Returns: none
// Arguments:
//   s = label string
module draw_panel_label(s) {
    translate([0, -55, -34])
        linear_extrude(height = TXT_H)
            text(s, size = TXT_S, halign = "center", valign = "center");
}

// Module: draw_polygon()
// Usage:
//   draw_polygon(pts2d);
// Description:
//   Draw a thin local face fill from a point loop.
//   .
//   - Returns: none
// Arguments:
//   pts2d = 2D polygon loop
//   color_name = named color
module draw_polygon(pts2d) {
    linear_extrude(height = FACE_THK, center = true)
        polygon(points = pts2d);
}

// Module: draw_local_segment_stroke()
// Usage:
//   draw_local_segment_stroke(seg2d, r);
// Description:
//   Draw a stroked local 2D segment as a thin extruded ribbon.
//   .
//   - Returns: none
// Arguments:
//   seg2d = 2D segment
//   r = stroke radius
module draw_local_segment_stroke(seg2d, r = LINE_R) {
    linear_extrude(height = FACE_THK * 0.8, center = true)
        hull() {
            translate(seg2d[0]) circle(r = r, $fn = 20);
            translate(seg2d[1]) circle(r = r, $fn = 20);
        }
        translate(seg2d[0]) cylinder(r=0.3, h=5);
        translate(seg2d[1]) cylinder(r=0.2, h=6);
}

// Module: draw_wireframe()
// Usage:
//   draw_wireframe(poly, ir);
// Description:
//   Draw a light poly wireframe context for the demo poly.
//   .
//   - Returns: none
// Arguments:
//   poly = poly descriptor
//   ir = placement scale
module draw_wireframe(poly, ir = IR) {
    color("silver")
        place_on_edges(poly, ir)
            cube([$ps_edge_len, 0.8, 0.8], center = true);

    color("gold")
        place_on_vertices(poly, ir)
            sphere(1.2, $fn = 12);
}

// Module: draw_panel_ps_polygon()
// Usage:
//   draw_panel_ps_polygon(label_s);
// Description:
//   Show `ps_polygon(...)` on the star face.
//   .
//   - Returns: none
// Arguments:
//   label_s = panel label
module draw_panel_ps_polygon(label_s) {
    draw_wireframe(P, IR);
    
    place_on_faces(P, IR) {
        if ($ps_face_idx == STAR_FACE_IDX) {
            color("deepskyblue")
                linear_extrude(height = FACE_THK, center = true)
                    ps_polygon($ps_face_pts2d);
        }
    }
    draw_panel_label(label_s);
}

// Module: draw_panel_face_segments()
// Usage:
//   draw_panel_face_segments();
// Description:
//   Show `place_on_face_segments(...)` on the star face.
//   .
//   - Returns: none
// Arguments:
//   none =
module draw_panel_face_segments() {
    draw_wireframe(P, IR);
    
    place_on_faces(P, IR) {
        if ($ps_face_idx == STAR_FACE_IDX) {
            place_on_face_segments() {
                // simply draw the polygon in supplied color
                color(cell_color($ps_seg_idx)) 
                    draw_polygon($ps_seg_pts2d);

                // draw a line along each segment
                color("black") 
                    for (seg2d = ps_cyclic_pairs($ps_seg_pts2d))
                        draw_local_segment_stroke(seg2d, r = LINE_R);

                // draw the segment index at the centroid of the segment
                color("white") {
                    centre = ps_centroid2d($ps_seg_pts2d);
                    translate([centre[0], centre[1], FACE_THK / 2 + 0.02])
                        linear_extrude(height = TXT_H)
                            text(str($ps_seg_idx), size = 2.2, halign = "center", valign = "center");
                }
            }
        }
    }
    draw_panel_label("place_on_face_segments");
}

// Module: draw_panel_geom_cuts()
// Usage:
//   draw_panel_geom_cuts();
// Description:
//   Show `place_on_face_geom_cut_segments(...)` on one side face.
//   .
//   - Returns: none
// Arguments:
//   none =
module draw_panel_geom_cuts() {
    draw_wireframe(P, IR);
    
    place_on_faces(P, IR) {
        if ($ps_face_idx == SIDE_FACE_IDX) {
            color("gainsboro") draw_polygon($ps_face_pts2d);
            
            place_on_face_geom_cut_segments(filter_parent = true) {
                color("crimson") draw_local_segment_stroke($ps_face_cut_segment2d_local, r = LINE_R * 1.1);

                color("black")
                    for (j = [0:1:1])
                        translate([
                            $ps_face_cut_segment2d_local[j][0],
                            $ps_face_cut_segment2d_local[j][1],
                            FACE_THK / 2 + 0.02
                        ])
                            linear_extrude(height = TXT_H * 0.7)
                                text("x", size = 1.4, halign = "center", valign = "center");

                color("black") {
                    mid = ps_segment_midpoint2d($ps_face_cut_segment2d_local);
                    translate([mid[0], mid[1], FACE_THK / 2 + 0.02])
                        linear_extrude(height = TXT_H)
                            text(str($ps_face_cut_idx), size = 1.8, halign = "center", valign = "center");
                }
            }
        }
    }
    draw_panel_label("place_on_face_geom_cut_segments");
}

// Module: draw_panel_visible_segments()
// Usage:
//   draw_panel_visible_segments();
// Description:
//   Show `place_on_face_visible_segments(...)` on one side face.
//   .
//   - Returns: none
// Arguments:
//   none =
module draw_panel_visible_segments() {
    draw_wireframe(P, IR);
    
    place_on_faces(P, IR) {
        if ($ps_face_idx == SIDE_FACE_IDX) {
            color("gainsboro", 0.35)
                linear_extrude(height = FACE_THK * 0.4, center = true)
                    polygon(points = $ps_face_pts2d);

            place_on_face_visible_segments(filter_parent = true) {
                color(cell_color($ps_vis_seg_idx))
                    linear_extrude(height = FACE_THK, center = true)
                        polygon(points = $ps_vis_seg_pts2d);

                color("green")
                    for (seg2d = ps_cyclic_pairs($ps_vis_seg_pts2d))
                        draw_local_segment_stroke(seg2d, r = LINE_R * 0.4);

                color("white")
                    translate([ps_centroid2d($ps_vis_seg_pts2d)[0], ps_centroid2d($ps_vis_seg_pts2d)[1], FACE_THK / 2 + 0.02])
                        linear_extrude(height = TXT_H)
                            text(str($ps_vis_seg_idx), size = 2.0, halign = "center", valign = "center");
            }
        }
    }
    draw_panel_label("place_on_face_visible_segments");
}

translate([-1.5 * PANEL_X, 0, 0]) draw_panel_ps_polygon("ps_polygon");
translate([-0.5 * PANEL_X, 0, 0]) draw_panel_face_segments();
translate([ 0.5 * PANEL_X, 0, 0]) draw_panel_geom_cuts();
translate([ 1.5 * PANEL_X, 0, 0]) draw_panel_visible_segments();
