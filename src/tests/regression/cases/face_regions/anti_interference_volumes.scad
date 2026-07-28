/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

include <../../common/regression_common.scad>

use <../../../../polysymmetrica/core/face_regions.scad>
use <../../../../polysymmetrica/core/loop_shells.scad>
use <../../../../polysymmetrica/core/placement.scad>
use <../../../../polysymmetrica/core/prisms.scad>
use <../../../../polysymmetrica/core/segments.scad>
use <../../../../polysymmetrica/core/truncation.scad>
use <../../../../polysymmetrica/models/dodecahedron.scad>
use <../../../../polysymmetrica/models/tetrahedron.scad>

IR = 30;
Z0 = -2.0;
Z1 = 2.0;
MAX_PROJECT = 40;

TESTS = [
    ["dodeca_volume_control", function() dodecahedron(), 0, 0],
    ["star_ap_volume", function() poly_antiprism(5, 2), 0, 0],
    ["atut_hex_volume", function() poly_truncate(tetrahedron(), t = -0.5), 0, 0],
    ["atut_hex_volume_inset", function() poly_truncate(tetrahedron(), t = -0.5), 0, 1.2]
];

T_MAX = len(TESTS);
T = is_undef(T) ? 0 : T;
REG_LIST = is_undef(REG_LIST) ? false : REG_LIST;

assert(T >= 0 && T < T_MAX, str("T out of range: ", T));

module _wire_context(poly, face_idx) {
    color("silver")
        place_on_edges(poly, IR)
            cube([$ps_edge_len, 0.6, 0.6], center = true);

    color("gold")
        place_on_vertices(poly, IR)
            sphere(r = 1.0, $fn = 12);

    place_on_faces(poly, IR)
        if ($ps_face_idx == face_idx)
            translate([0, 0, 0.58])
                reg_text_label(str("f", $ps_face_idx), size = 2.0, h = 0.08);
}

module _volume_panel(poly, face_idx, label_s, boundary_inset = 0) {
    _wire_context(poly, face_idx);

    place_on_faces(poly, IR)
        if ($ps_face_idx == face_idx) {
            color("gainsboro", 0.28)
                translate([0, 0, -0.18])
                    reg_face_fill(0.24);

            color("deepskyblue", 0.36)
                ps_face_region_loop_volume(
                    Z0,
                    Z1,
                    mode = "nonzero",
                    max_project = MAX_PROJECT,
                    boundary_inset = boundary_inset
                );

            color("black")
                place_on_face_boundary_spans(mode = "nonzero")
                    cube([$ps_boundary_span_len, 0.54, 0.54], center = true);

            shells = ps_face_region_loop_shells(
                $ps_face_local_context,
                Z0,
                Z1,
                "nonzero",
                MAX_PROJECT,
                boundary_inset = boundary_inset
            );

            for (shell = shells) {
                color(ps_loop_shell_exposure_sign(shell) > 0 ? "navy" : "crimson")
                    for (pt = ps_loop_shell_points(shell))
                        translate(pt)
                            sphere(r = 0.62, $fn = 10);

                top = ps_loop_shell_top_loop2d(shell);
                if (len(top) > 0)
                    translate([ps_centroid2d(top)[0], ps_centroid2d(top)[1], Z1 + 0.35])
                        reg_text_label(
                            str("L", ps_loop_shell_source_idx(shell)),
                            size = 1.5,
                            h = 0.06
                        );
            }
        }

    reg_panel_label(label_s);
}

if (REG_LIST) {
    reg_list_tests(TESTS, render_args = REG_RENDER_ARGS_POLY_SINGLE);
} else {
    spec = TESTS[T];
    _volume_panel(spec[1](), spec[2], spec[0], boundary_inset = spec[3]);
}
