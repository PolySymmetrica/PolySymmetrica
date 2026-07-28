/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

include <../../common/regression_common.scad>

use <../../../../polysymmetrica/core/funcs.scad>
use <../../../../polysymmetrica/core/placement.scad>
use <../../../../polysymmetrica/core/vertex.scad>

function _irregular_valence4_bipyramid() =
    poly_make(
        [
            [0, 0, 1.7],
            [1.4, 0, 0],
            [0.2, 1.1, 0.35],
            [-1.0, 0.1, -0.15],
            [-0.1, -1.4, 0.25],
            [0.1, 0, -1.2]
        ],
        [
            [0, 2, 1],
            [0, 3, 2],
            [0, 4, 3],
            [0, 1, 4],
            [5, 1, 2],
            [5, 2, 3],
            [5, 3, 4],
            [5, 4, 1]
        ],
        1
    );

TESTS = [
    ["irregular_valence4_vertex_polygons", _irregular_valence4_bipyramid()]
];

T_MAX = len(TESTS);
T = is_undef(T) ? 0 : T;
REG_LIST = is_undef(REG_LIST) ? false : REG_LIST;

assert(T >= 0 && T < T_MAX, str("T out of range: ", T));

P = TESTS[T][1];
IR = 28;

module _vertex_polygon(mode, z, color_name) {
    color(color_name)
        translate([0, 0, z])
            linear_extrude(height = 0.24, center = true)
                polygon(points = ps_current_vertex_figure_points2d(t = 0.34, cap_mode = mode));
}

module render_scene(poly) {
    color("silver")
        place_on_edges(poly, IR)
            cube([$ps_edge_len, 0.35, 0.35], center = true);

    place_on_vertices(poly, IR) {
        _vertex_polygon("edge_fraction", 0.00, "tomato");
        _vertex_polygon("planar_edge_fraction", 0.34, "gold");

        translate([0, 0, 0.78])
            reg_text_label($ps_vertex_idx, size = 2.1, h = 0.08);
    }

    reg_panel_label(TESTS[T][0], y = -34, z = -22);
}

if (REG_LIST) {
    reg_list_tests(TESTS, render_args = REG_RENDER_ARGS_POLY_SINGLE);
} else {
    render_scene(P);
}
