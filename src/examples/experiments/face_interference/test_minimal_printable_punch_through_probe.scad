/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

use <../../../polysymmetrica/core/face_regions.scad>
use <../../../polysymmetrica/core/funcs.scad>
use <../../../polysymmetrica/core/placement.scad>
use <../../../polysymmetrica/core/prisms.scad>
use <../../../polysymmetrica/core/segments.scad>
use <../../../polysymmetrica/core/render.scad>
use <../../printing/frame-and-faces/face_plate.scad>

// Minimal printable punch-through integration probe for poly_antiprism(7,3,15).
// This deliberately stays narrow: it combines the stable face-local data APIs
// into one positive keep-body and demonstrates the opt-in face-plate proxy
// replay path.
//
// The keep-body panel in each row computes:
//   raw face slab ∩ visible-cell mask ∩ positive anti-interference volume
//
// The proxy face-plate panel then subtracts:
//   caller-supplied closed foreign face proxy bodies replayed via
//   place_on_face_foreign_proxy_sites(...)
//
// Orange intrusion strips are drawn as inspection aids. The proxy panel is the
// production-shaped API demonstration; it still requires the caller/library to
// supply the proxy body deliberately.

IR = 32;
FILTER_PARENT_CUTS = true;

STAR_FACE_IDX = 1;
TRI_FACE_IDX = 12;
STAR_SOURCE_EDGE_IDX = 0;

FACE_THK = 0.62;
VOL_Z_MIN = -1;
VOL_Z_MAX = 2;
MAX_PROJECT = 45;
LINE_R = 0.45;
TXT_H = 0.30;
TXT_S = 2.25;
PANEL_X = 92;
PANEL_Y = 112;
PANEL_LABEL_Y = -50;
CUT_KERF = 1.0;
PROXY_FACE_THK = 3.6;
PROXY_EDGE_INSET = 0.55;

P = poly_antiprism(7, 3, angle = 15);

// Function: example_color()
// Usage:
//   result = example_color(i);
// Description:
//   Pick a stable, readable named color.
//   .
//   - Returns: named color string
// Arguments:
//   i = index
function example_color(i) =
    (i % 8 == 0) ? "tomato" :
    (i % 8 == 1) ? "deepskyblue" :
    (i % 8 == 2) ? "gold" :
    (i % 8 == 3) ? "mediumseagreen" :
    (i % 8 == 4) ? "orchid" :
    (i % 8 == 5) ? "darkorange" :
    (i % 8 == 6) ? "turquoise" :
    "sienna";

// Function: unit2d()
// Usage:
//   result = unit2d(a, b);
// Description:
//   Compute a unit 2D direction from one point to another.
//   .
//   - Returns: unit direction, or `[1,0]` for a degenerate segment
// Arguments:
//   a = 2D points
//   b = 2D points
function unit2d(a, b) =
    let(d = [b[0] - a[0], b[1] - a[1]])
    (norm(d) <= 1e-9) ? [1, 0] : d / norm(d);

// Module: draw_text2d()
// Usage:
//   draw_text2d(s, size, z);
// Description:
//   Draw text in the current local XY plane.
//   .
//   - Returns: none
// Arguments:
//   s = text
//   size = font size
//   z = local Z
module draw_text2d(s, size = TXT_S, z = 0) {
    translate([0, 0, z])
        linear_extrude(height = TXT_H)
            text(s, size = size, halign = "center", valign = "center");
}

// Module: draw_panel_label()
// Usage:
//   draw_panel_label(s);
// Description:
//   Draw a world-space panel label.
//   .
//   - Returns: none
// Arguments:
//   s = label text
module draw_panel_label(s) {
    translate([0, PANEL_LABEL_Y, -18])
        draw_text2d(s, size = TXT_S + 0.35);
}

// Module: draw_segment_stroke()
// Usage:
//   draw_segment_stroke(seg2d, r, z);
// Description:
//   Draw a local 2D segment as an extruded rounded ribbon.
//   .
//   - Returns: none
// Arguments:
//   seg2d = 2D segment
//   r = ribbon radius
//   z = local Z offset
module draw_segment_stroke(seg2d, r = LINE_R, z = 0) {
    translate([0, 0, z])
        linear_extrude(height = FACE_THK * 5, center = true)
            hull() {
                translate(seg2d[0]) circle(r = r, $fn = 18);
                translate(seg2d[1]) circle(r = r, $fn = 18);
            }
}

// Module: draw_polygon_fill()
// Usage:
//   draw_polygon_fill(pts2d, z);
// Description:
//   Draw a local 2D polygon loop as a thin face fill.
//   .
//   - Returns: none
// Arguments:
//   pts2d = 2D polygon loop
//   z = local Z offset
module draw_polygon_fill(pts2d, z = 0) {
    translate([0, 0, z])
        linear_extrude(height = FACE_THK * 0.25, center = true)
            polygon(points = pts2d);
}

// Module: draw_source_edge_labels()
// Usage:
//   draw_source_edge_labels(pts2d, highlight_source_edge_idx);
// Description:
//   Draw labels for source edges on a selected face.
//   .
//   - Returns: none
// Arguments:
//   pts2d = source face loop
//   highlight_source_edge_idx = optional source edge
module draw_source_edge_labels(pts2d, highlight_source_edge_idx = undef) {
    centre = ps_centroid2d(pts2d);
    for (ei = [0:1:len(pts2d)-1]) {
        seg2d = [pts2d[ei], pts2d[(ei + 1) % len(pts2d)]];
        mid = ps_segment_midpoint2d(seg2d);
        offset_dir = unit2d(mid, centre);
        highlighted = !is_undef(highlight_source_edge_idx) && ei == highlight_source_edge_idx;

        color(highlighted ? "red" : "dimgray")
            translate([mid[0] + 3.0 * offset_dir[0], mid[1] + 3.0 * offset_dir[1], FACE_THK * 0.65])
                draw_text2d(str(highlighted ? "*se" : "se", ei), size = 1.25);
    }
}

// Module: face_material_slab()
// Usage:
//   face_material_slab();
// Description:
//   Emit a raw face-local material slab from the filled face polygon.
//   .
//   - Returns: none
// Arguments:
//   none =
module face_material_slab() {
    translate([0, 0, -FACE_THK / 2])
        linear_extrude(height = FACE_THK)
            ps_polygon($ps_face_pts2d);
}

// Module: anti_interference_volume()
// Usage:
//   anti_interference_volume();
// Description:
//   Emit the positive anti-interference volume for the current face.
//   .
//   - Returns: none
// Arguments:
//   none =
module anti_interference_volume() {
    ps_face_region_loop_volume(
        VOL_Z_MIN,
        VOL_Z_MAX,
        max_project = MAX_PROJECT
    );
}

// Module: printable_keep_body()
// Usage:
//   printable_keep_body();
// Description:
//   Emit the minimal printable keep-body under test.
//   .
//   - Returns: none
// Arguments:
//   none =
module printable_keep_body() {
    intersection() {
        face_material_slab();
        ps_face_visible_mask(FACE_THK, z_pad = 0.04, filter_parent = FILTER_PARENT_CUTS);
        anti_interference_volume();
    }
}

// Module: foreign_face_proxy_body()
// Usage:
//   foreign_face_proxy_body();
// Description:
//   Emit one closed foreign face proxy body in the replayed source-face frame.
//   .
//   - Returns: none
// Arguments:
//   none; uses `$ps_proxy_*` from `place_on_face_foreign_proxy_sites(...)` =
module foreign_face_proxy_body() {
    linear_extrude(height = PROXY_FACE_THK, center = true)
        ps_polygon($ps_proxy_face_pts2d);
}

// Module: face_plate_with_proxy_cutouts()
// Usage:
//   face_plate_with_proxy_cutouts();
// Description:
//   Emit the face plate after subtracting conservative volume-group hull cutters.
//   .
//   - Returns: none
// Arguments:
//   none =
module face_plate_with_proxy_cutouts() {
    difference() {
        face_plate(
            face_thk = FACE_THK,
            clear_space = false,
            pillow_min_rad = 1000000,
            base_z = -FACE_THK / 2,
            max_project = 10
        );

        place_on_face_foreign_proxy_volume_group_hulls(
            filter_parent = FILTER_PARENT_CUTS
        );
    }
}

// Module: draw_cut_strips()
// Usage:
//   draw_cut_strips();
// Description:
//   Draw orange exact intrusion strips as inspection aids.
//   .
//   - Returns: none
// Arguments:
//   none =
module draw_cut_strips() {
    intrusions = ps_face_foreign_intrusion_records(
        $ps_face_pts2d,
        $ps_face_idx,
        $ps_poly_faces_idx,
        $ps_poly_verts_local,
        filter_parent = FILTER_PARENT_CUTS
    );

    for (ii = [0:1:len(intrusions)-1]) {
        intrusion = intrusions[ii];
        seg2d = ps_intrusion_segment2d_local(intrusion);
        mid = ps_segment_midpoint2d(seg2d);

        color("darkorange", 0.70)
            draw_segment_stroke(seg2d, r = CUT_KERF, z = FACE_THK * 0.55);

        color("black")
            translate([mid[0], mid[1], FACE_THK * 0.95])
                draw_text2d(str("i", ii, "/f", ps_intrusion_foreign_idx(intrusion)), size = 1.05);
    }
}

// Module: draw_proxy_volume_group_strips()
// Usage:
//   draw_proxy_volume_group_strips();
// Description:
//   Draw grouped exact intrusion strips from proxy volume-group records.
//   .
//   - Returns: none
// Arguments:
//   none; uses current `place_on_faces(...)` metadata =
module draw_proxy_volume_group_strips() {
    place_on_face_foreign_proxy_volume_groups(filter_parent = FILTER_PARENT_CUTS) {
        records = $ps_proxy_volume_group_records;
        mids = [for (r = records) ps_segment_midpoint2d(ps_intrusion_segment2d_local(r))];
        label_pos = ps_centroid2d(mids);

        color(example_color($ps_proxy_volume_group_idx), 0.84)
            for (r = records)
                draw_segment_stroke(ps_intrusion_segment2d_local(r), r = CUT_KERF * 0.58, z = FACE_THK * 1.2);

        color("black")
            translate([label_pos[0], label_pos[1], FACE_THK * 1.62])
                draw_text2d(
                    str(
                        "vg", $ps_proxy_volume_group_idx,
                        " f", $ps_proxy_volume_group_face_idxs
                    ),
                    size = 0.95
                );
    }
}

// Module: draw_context_panel()
// Usage:
//   draw_context_panel(face_idx, label_s);
// Description:
//   Draw the surrounding poly and label the selected face.
//   .
//   - Returns: none
// Arguments:
//   face_idx = selected face
//   label_s = panel label
module draw_context_panel(face_idx, label_s) {
    poly_render(P, IR);

    color("silver")
        place_on_edges(P, IR)
            cube([$ps_edge_len, 0.35, 0.85], center = true);

    color("gold")
        place_on_vertices(P, IR)
            sphere(0.95, $fn = 12);

    place_on_faces(P, IR) {
        if ($ps_face_idx == face_idx)
            color("tomato", 0.48)
                face_material_slab();

        color(($ps_face_idx == face_idx) ? "black" : "gray")
            translate([0, 0, 1.3])
                draw_text2d(str("f", $ps_face_idx), size = 1.45);
    }

    draw_panel_label(label_s);
}

// Module: draw_visible_data_panel()
// Usage:
//   draw_visible_data_panel(face_idx, source_edge_idx, label_s);
// Description:
//   Draw visible cells and geometry-cut provenance for one face.
//   .
//   - Returns: none
// Arguments:
//   face_idx = selected face
//   source_edge_idx = optional highlighted edge
//   label_s = panel label
module draw_visible_data_panel(face_idx, source_edge_idx, label_s) {
    place_on_faces(P, IR) {
        if ($ps_face_idx == face_idx) {
            color("gainsboro", 0.18)
                face_material_slab();

            place_on_face_visible_segments(filter_parent = FILTER_PARENT_CUTS) {
                color(example_color($ps_vis_seg_idx), 0.40)
                    draw_polygon_fill($ps_vis_seg_pts2d, z = -FACE_THK * 0.35);

                centre = ps_centroid2d($ps_vis_seg_pts2d);
                color("white")
                    translate([centre[0], centre[1], FACE_THK * 0.72])
                        draw_text2d(str("v", $ps_vis_seg_idx), size = 1.25);
            }

            draw_cut_strips();
            draw_proxy_volume_group_strips();
            draw_source_edge_labels($ps_face_pts2d, source_edge_idx);
        }
    }

    draw_panel_label(label_s);
}

// Module: draw_volume_data_panel()
// Usage:
//   draw_volume_data_panel(face_idx, source_edge_idx, label_s);
// Description:
//   Draw anti-interference volume and its boundary span skeleton.
//   .
//   - Returns: none
// Arguments:
//   face_idx = selected face
//   source_edge_idx = optional highlighted source edge
//   label_s = panel label
module draw_volume_data_panel(face_idx, source_edge_idx, label_s) {
    place_on_faces(P, IR) {
        if ($ps_face_idx == face_idx) {
            color("gainsboro", 0.14)
                face_material_slab();

            color("deepskyblue", 0.35)
                anti_interference_volume();

            place_on_face_boundary_spans() {
                highlighted = !is_undef(source_edge_idx) && $ps_boundary_span_source_edge_idx == source_edge_idx;
                color(highlighted ? "red" : "black")
                    cube([$ps_boundary_span_len, highlighted ? 0.9 : 0.55, 0.55], center = true);
            }
        }
    }

    draw_panel_label(label_s);
}

// Module: draw_printable_result_panel()
// Usage:
//   draw_printable_result_panel(face_idx, source_edge_idx, label_s);
// Description:
//   Draw the minimal printable keep-body plus cut provenance overlay.
//   .
//   - Returns: none
// Arguments:
//   face_idx = selected face
//   source_edge_idx = optional highlighted source edge
//   label_s = panel label
module draw_printable_result_panel(face_idx, source_edge_idx, label_s) {
    place_on_faces(P, IR) {
        if ($ps_face_idx == face_idx) {
            color("white")
                printable_keep_body();

            color("deepskyblue", 0.18)
                anti_interference_volume();

            draw_cut_strips();
            draw_source_edge_labels($ps_face_pts2d, source_edge_idx);
        }
    }

    draw_panel_label(label_s);
}

// Module: draw_proxy_face_plate_panel()
// Usage:
//   draw_proxy_face_plate_panel(face_idx, source_edge_idx, label_s);
// Description:
//   Draw the face plate after subtracting replayed foreign proxy bodies.
//   .
//   - Returns: none
// Arguments:
//   face_idx = selected face
//   source_edge_idx = optional highlighted source edge
//   label_s = panel label
module draw_proxy_face_plate_panel(face_idx, source_edge_idx, label_s) {
    place_on_faces(P, IR) {
        if ($ps_face_idx == face_idx) {
            color("white")
                face_plate_with_proxy_cutouts();

            place_on_face_foreign_proxy_volume_group_faces(filter_parent = FILTER_PARENT_CUTS) {
                color(example_color($ps_proxy_volume_group_idx), 0.24)
                    foreign_face_proxy_body();
            }

            color("mediumseagreen", 0.16)
                place_on_face_foreign_proxy_volume_group_hulls(filter_parent = FILTER_PARENT_CUTS);

            draw_cut_strips();
            draw_source_edge_labels($ps_face_pts2d, source_edge_idx);
        }
    }

    draw_panel_label(label_s);
}

// Module: echo_row_summary()
// Usage:
//   echo_row_summary(label_s, face_idx);
// Description:
//   Echo summary counts for one row.
//   .
//   - Returns: none
// Arguments:
//   label_s = row label
//   face_idx = selected face
module echo_row_summary(label_s, face_idx) {
    place_on_faces(P, IR) {
        if ($ps_face_idx == face_idx) {
            bm = ps_face_boundary_model($ps_face_pts3d_local);
            intrusions = ps_face_foreign_intrusion_records(
                $ps_face_pts2d,
                $ps_face_idx,
                $ps_poly_faces_idx,
                $ps_poly_verts_local,
                filter_parent = FILTER_PARENT_CUTS
            );
            visible = ps_face_visible_segments(
                $ps_face_pts2d,
                $ps_face_idx,
                $ps_poly_faces_idx,
                $ps_poly_verts_local,
                filter_parent = FILTER_PARENT_CUTS
            );
            volume_groups = ps_face_foreign_proxy_volume_groups(
                $ps_face_pts2d,
                $ps_face_idx,
                $ps_target_local_poly_context,
                filter_parent = FILTER_PARENT_CUTS
            );

            echo(str(
                "minimal printable punch-through ", label_s, " f", face_idx,
                ": boundary_loops=", len(bm[2]),
                " boundary_spans=", len(bm[3]),
                " intrusions=", len(intrusions),
                " visible_segments=", len(visible),
                " proxy_volume_groups=", len(volume_groups)
            ));
        }
    }
}

// Module: draw_probe_row()
// Usage:
//   draw_probe_row(face_idx, source_edge_idx, label_s, y);
// Description:
//   Draw one target face row.
//   .
//   - Returns: none
// Arguments:
//   face_idx = selected face
//   source_edge_idx = optional highlighted source edge
//   label_s = row label
//   y = row offset
module draw_probe_row(face_idx, source_edge_idx, label_s, y) {
    translate([-2 * PANEL_X, y, 0])
        draw_context_panel(face_idx, str(label_s, " context"));

    translate([-1 * PANEL_X, y, 0])
        draw_visible_data_panel(face_idx, source_edge_idx, str(label_s, " visible/intrusions"));

    translate([0, y, 0])
        draw_volume_data_panel(face_idx, source_edge_idx, str(label_s, " anti-volume"));

    translate([1 * PANEL_X, y, 0])
        draw_printable_result_panel(face_idx, source_edge_idx, str(label_s, " keep-body"));

    translate([2 * PANEL_X, y, 0])
        draw_proxy_face_plate_panel(face_idx, source_edge_idx, str(label_s, " proxy face-plate"));

    echo_row_summary(label_s, face_idx);
}

draw_probe_row(STAR_FACE_IDX, STAR_SOURCE_EDGE_IDX, "star", 0.5 * PANEL_Y);
draw_probe_row(TRI_FACE_IDX, undef, "tri", -0.5 * PANEL_Y);
