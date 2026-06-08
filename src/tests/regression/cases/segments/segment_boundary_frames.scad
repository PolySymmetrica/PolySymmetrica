include <../../common/regression_common.scad>

use <../../../../polysymmetrica/core/face_regions.scad>
use <../../../../polysymmetrica/core/funcs.scad>
use <../../../../polysymmetrica/core/placement.scad>
use <../../../../polysymmetrica/core/prisms.scad>
use <../../../../polysymmetrica/core/segments.scad>
use <../../../../polysymmetrica/core/truncation.scad>
use <../../../../polysymmetrica/models/dodecahedron.scad>
use <../../../../polysymmetrica/models/tetrahedron.scad>

IR = 30;
FACE_THK = 0.26;

TESTS = [
    ["star_evenodd_cells", "cells", function() poly_antiprism(5, 2), 1, "evenodd"],
    ["star_nonzero_cells", "cells", function() poly_antiprism(5, 2), 1, "nonzero"],
    ["atut_nonzero_cells", "cells", function() poly_truncate(tetrahedron(), t = -0.5), 0, "nonzero"],
    ["atut_boundary_spans", "boundary_spans", function() poly_truncate(tetrahedron(), t = -0.5), 0, "all"],
    ["atut_boundary_sources", "boundary_sources", function() poly_truncate(tetrahedron(), t = -0.5), 0],
    ["atut_generated_spans", "boundary_spans", function() poly_truncate(tetrahedron(), t = -0.5), 0, "generated"],
    ["atut_seam_segments", "seams", function() poly_truncate(tetrahedron(), t = -0.5), 0],
    ["atut_visible_cells", "visible", function() poly_truncate(tetrahedron(), t = -0.5), 0],
    ["dodeca_boundary_control", "boundary_spans", function() dodecahedron(), 0, "all"]
];

T_MAX = len(TESTS);
T = is_undef(T) ? 0 : T;
REG_LIST = is_undef(REG_LIST) ? false : REG_LIST;

assert(T >= 0 && T < T_MAX, str("T out of range: ", T));

function _span_kind_color(kind) =
    (kind == "source_edge") ? "gainsboro" :
    (kind == "source_partial") ? "darkorange" :
    (kind == "generated_cut") ? "magenta" :
    "white";

module _wire_context(poly, face_idx, show_fill = true) {
    color("silver")
        place_on_edges(poly, IR)
            cube([$ps_edge_len, 0.6, 0.6], center = true);

    color("gold")
        place_on_vertices(poly, IR)
            sphere(r = 1.0, $fn = 12);

    place_on_faces(poly, IR)
        if ($ps_face_idx == face_idx) {
            if (show_fill)
                color("gainsboro", 0.28)
                    translate([0, 0, -0.18])
                        reg_face_fill(FACE_THK);

            translate([0, 0, 0.7])
                reg_text_label(str("f", $ps_face_idx), size = 2.2, h = 0.08);
        }
}

module _local_vector(dir, len = 7, r = 0.22) {
    d = (is_undef(dir) || norm(dir) <= 1e-8) ? [0, 0, 1] : v_norm(dir);
    axis = [-d[1], d[0], 0];
    ang = acos(max(-1, min(1, d[2])));

    rotate(a = ang, v = (norm(axis) <= 1e-8) ? [1, 0, 0] : axis)
        union() {
            translate([0, 0, len / 2])
                cylinder(h = len, r = r, center = true, $fn = 12);
            translate([0, 0, len])
                sphere(r = r * 2.2, $fn = 12);
        }
}

module _source_edge_labels(pts2d) {
    for (ei = [0:1:len(pts2d) - 1]) {
        seg2d = [pts2d[ei], pts2d[(ei + 1) % len(pts2d)]];
        mid = ps_segment_midpoint2d(seg2d);
        inward = ps_centroid2d(pts2d) - mid;
        off = (norm(inward) <= 1e-9) ? [0, 0] : inward / norm(inward);

        color("dimgray")
            translate([mid[0] + 2.8 * off[0], mid[1] + 2.8 * off[1], FACE_THK / 2 + 0.05])
                reg_text_label(str("e", ei), size = 1.25, h = 0.05);
    }
}

module _two_sided_face_label(pt2d, s, size = 2.4, h = 0.08, z = 1.0) {
    translate([pt2d[0], pt2d[1], z])
        reg_text_label(s, size = size, h = h);

    translate([pt2d[0], pt2d[1], -z])
        rotate([180, 0, 0])
            reg_text_label(s, size = size, h = h);
}

module _cells_panel(poly, face_idx, mode, label_s) {
    _wire_context(poly, face_idx, show_fill = false);

    place_on_faces(poly, IR)
        if ($ps_face_idx == face_idx)
            place_on_face_segments(mode = mode) {
                color(reg_cycle_color($ps_seg_idx))
                    translate([0, 0, 0.18])
                        linear_extrude(height = FACE_THK, center = true)
                            polygon(points = $ps_seg_pts2d);

                color("black")
                    for (seg2d = ps_cyclic_pairs($ps_seg_pts2d))
                        translate([0, 0, 0.36])
                            reg_local_segment(seg2d, r = 0.38, h = 0.30);

                _two_sided_face_label(ps_centroid2d($ps_seg_pts2d), $ps_seg_idx, size = 2.9, h = 0.09, z = 1.1);
            }

    reg_panel_label(label_s);
}

module _boundary_spans_panel(poly, face_idx, label_s, kind = "all") {
    _wire_context(poly, face_idx);

    place_on_faces(poly, IR)
        if ($ps_face_idx == face_idx) {
            _source_edge_labels($ps_face_pts2d);

            place_on_face_boundary_spans(mode = "nonzero", kind = kind) {
                color(_span_kind_color($ps_boundary_span_kind))
                    cube([$ps_boundary_span_len, 0.8, 0.35], center = true);

                reg_element_axis(min(8, max(3, $ps_boundary_span_len * 0.28)), r = 0.24);

                color("deepskyblue")
                    translate([0, 0, 0.7])
                        _local_vector($ps_boundary_span_adj_face_dir_span_local, len = 4.8, r = 0.18);

                translate([0, 0, 6.2])
                    reg_text_label(
                        str($ps_boundary_span_idx, ":e", $ps_boundary_span_source_edge_idx, "/f", $ps_boundary_span_adj_face_idx),
                        size = 1.1,
                        h = 0.05
                    );
            }
        }

    reg_panel_label(label_s);
}

module _boundary_sources_panel(poly, face_idx, label_s) {
    _wire_context(poly, face_idx);

    place_on_faces(poly, IR)
        if ($ps_face_idx == face_idx) {
            _source_edge_labels($ps_face_pts2d);

            place_on_face_filled_boundary_source_edges(mode = "nonzero") {
                color($ps_boundary_source_edge_frame_reversed ? "crimson" : "mediumseagreen")
                    cube([$ps_boundary_source_edge_len, 0.82, 0.36], center = true);

                for (si = [0:1:len($ps_boundary_source_edge_span_t_ranges_local) - 1]) {
                    tr = $ps_boundary_source_edge_span_t_ranges_local[si];
                    x0 = (tr[0] - 0.5) * $ps_boundary_source_edge_len;
                    x1 = (tr[1] - 0.5) * $ps_boundary_source_edge_len;
                    mid = (x0 + x1) / 2;
                    lenx = abs(x1 - x0);

                    color(reg_cycle_color(si))
                        translate([mid, 1.3, 0.34])
                            cube([max(0.4, lenx), 0.56, 0.56], center = true);
                }

                translate([0, 0, 2.1])
                    reg_text_label(
                        str("se", $ps_boundary_source_edge_idx, " n", $ps_boundary_source_edge_span_count),
                        size = 1.25,
                        h = 0.05
                    );
            }
        }

    reg_panel_label(label_s);
}

module _seam_panel(poly, face_idx, label_s) {
    _wire_context(poly, face_idx);

    place_on_faces(poly, IR)
        if ($ps_face_idx == face_idx)
            place_on_face_seam_segments(
                mode = "nonzero",
                boundary_kind = "all",
                include_boundary = true,
                include_foreign = true,
                filter_parent = true
            ) {
                color($ps_seam_is_support_candidate ? "limegreen" : "magenta")
                    cube([$ps_seam_len, 1.0, 0.52], center = true);

                color("deepskyblue")
                    translate([0, 0, 0.7])
                        _local_vector($ps_seam_foreign_normal_local, len = 4.0, r = 0.16);

                translate([0, 0, 5.0])
                    reg_text_label(str($ps_seam_idx, ":", $ps_seam_source_kind), size = 1.0, h = 0.05);
            }

    reg_panel_label(label_s);
}

module _visible_panel(poly, face_idx, label_s) {
    _wire_context(poly, face_idx);

    place_on_faces(poly, IR)
        if ($ps_face_idx == face_idx)
            place_on_face_visible_segments(mode = "nonzero", filter_parent = true) {
                color(reg_cycle_color($ps_vis_seg_idx))
                    linear_extrude(height = FACE_THK, center = true)
                        polygon(points = $ps_vis_seg_pts2d);

                color("black")
                    for (seg2d = ps_cyclic_pairs($ps_vis_seg_pts2d))
                        reg_local_segment(seg2d, r = 0.28, h = 0.30);

                _two_sided_face_label(ps_centroid2d($ps_vis_seg_pts2d), $ps_vis_seg_idx, size = 2.7, h = 0.09, z = 1.1);
            }

    reg_panel_label(label_s);
}

module _render_test(spec) {
    name = spec[0];
    kind = spec[1];
    poly = spec[2]();
    face_idx = spec[3];

    if (kind == "cells") {
        _cells_panel(poly, face_idx, spec[4], name);
    } else if (kind == "boundary_spans") {
        _boundary_spans_panel(poly, face_idx, name, kind = spec[4]);
    } else if (kind == "boundary_sources") {
        _boundary_sources_panel(poly, face_idx, name);
    } else if (kind == "seams") {
        _seam_panel(poly, face_idx, name);
    } else if (kind == "visible") {
        _visible_panel(poly, face_idx, name);
    } else {
        assert(false, str("Unknown segment regression kind: ", kind));
    }
}

if (REG_LIST) {
    reg_list_tests(TESTS);
} else {
    _render_test(TESTS[T]);
}
