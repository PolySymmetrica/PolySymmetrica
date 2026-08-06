/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

include <../../common/regression_common.scad>

use <../../../../polysymmetrica/core/funcs.scad>
use <../../../../polysymmetrica/core/truncation.scad>
use <../../../../polysymmetrica/models/catalans_all.scad>

CAP_MODES = ["planar_edge_fraction", "edge_fraction", "centric", "poly_centroidal"];
REG_RENDER_ARGS_VERTEX_CAP_GRID = "--projection=o --camera=0,0,0,55,0,25,300 --render";

TESTS = [
    ["cantellate_strict_vs_planarized", "compare", "cantellate"],
    ["cantellate_cap_modes", "modes", "cantellate"],
    ["cantitruncate_strict_vs_planarized", "compare", "cantitruncate"],
    ["cantitruncate_cap_modes", "modes", "cantitruncate"]
];

T_MAX = len(TESTS);
T = is_undef(T) ? 0 : T;
REG_LIST = is_undef(REG_LIST) ? false : REG_LIST;

assert(T >= 0 && T < T_MAX, str("T out of range: ", T));

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

function _cap_poly(kind, mode = "planar_edge_fraction", style = "planarized") =
    kind == "cantellate"
        ? poly_cantellate(_irregular_valence4_bipyramid(), df = 0.18, style = style, cap_mode = (style == "planarized") ? mode : undef)
        : poly_cantitruncate(_irregular_valence4_bipyramid(), t = 0.2, c = 0.1, style = style, cap_mode = (style == "planarized") ? mode : undef);

module _render_poly_at(poly, pos, label, ir = 12) {
    translate(pos)
        reg_poly_preview(poly, ir = ir, show_vertex_ids = true);

    translate(pos + [0, -13, -9])
        reg_text_label(label, size = 2.35, h = 0.12);
}

module _render_compare(kind) {
    _render_poly_at(
        _cap_poly(kind, style = "strict"),
        [-18, 0, 0],
        "strict",
        ir = 14
    );

    _render_poly_at(
        _cap_poly(kind, style = "planarized"),
        [18, 0, 0],
        "planarized",
        ir = 14
    );

    translate([0, -34, -20])
        reg_panel_label(str(kind, " source-vertex caps"), y = 0, z = 0, size = 2.7, h = 0.14);
}

module _render_modes(kind) {
    positions = [
        [-29, 22, 0],
        [29, 22, 0],
        [-29, -22, 0],
        [29, -22, 0]
    ];

    for (i = [0:1:len(CAP_MODES) - 1])
        _render_poly_at(
            _cap_poly(kind, mode = CAP_MODES[i]),
            positions[i],
            CAP_MODES[i]
        );

    translate([0, -50, -20])
        reg_panel_label(str(kind, " cap modes"), y = 0, z = 0, size = 2.7, h = 0.14);
}

if (REG_LIST) {
    reg_list_tests(TESTS, render_args = REG_RENDER_ARGS_VERTEX_CAP_GRID);
} else {
    spec = TESTS[T];

    if (spec[1] == "compare")
        _render_compare(spec[2]);
    else
        _render_modes(spec[2]);
}
