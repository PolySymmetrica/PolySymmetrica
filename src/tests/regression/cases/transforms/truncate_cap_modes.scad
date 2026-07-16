/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

include <../../common/regression_common.scad>

use <../../../../polysymmetrica/core/funcs.scad>
use <../../../../polysymmetrica/core/truncation.scad>

T_VALUES = [-0.3, 0.12, 0.22, 0.34];

TESTS = [
    ["planar_edge_fraction_t_sweep", "mode", "planar_edge_fraction"],
    ["edge_fraction_t_sweep", "mode", "edge_fraction"],
    ["centric_t_sweep", "mode", "centric"],
    ["poly_centroidal_t_sweep", "mode", "poly_centroidal"],
    ["mixed_cap_mode_profile", "profile", undef]
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

function _profile_cap_poly() =
    let(
        p = _irregular_valence4_bipyramid(),
        profile = [
            ["vert", "id", 0, ["cap_mode", "edge_fraction"]],
            ["vert", "id", 5, ["cap_mode", "poly_centroidal"]]
        ]
    )
    poly_truncate(p, t = 0.22, cap_mode = "planar_edge_fraction", profile = profile);

module _render_poly_at(poly, x, label, ir = 10) {
    translate([x, 0, 0])
        reg_poly_preview(poly, ir = ir);

    translate([x, -26, -16])
        reg_text_label(label, size = 2.3, h = 0.12);
}

module _render_mode_sweep(cap_mode) {
    base = _irregular_valence4_bipyramid();
    spacing = 36;

    for (i = [0:1:len(T_VALUES) - 1]) {
        t = T_VALUES[i];
        x = (i - (len(T_VALUES) - 1) / 2) * spacing;
        _render_poly_at(
            poly_truncate(base, t = t, cap_mode = cap_mode),
            x,
            str("t=", t)
        );
    }

    translate([0, -31, -22])
        reg_panel_label(TESTS[T][0], y = 0, z = 0, size = 2.7, h = 0.14);
}

module _render_profile() {
    _render_poly_at(
        poly_truncate(_irregular_valence4_bipyramid(), t = 0.22, cap_mode = "planar_edge_fraction"),
        -22,
        "default",
        ir = 13
    );

    _render_poly_at(
        _profile_cap_poly(),
        22,
        "v0=edge v5=poly",
        ir = 13
    );

    translate([0, -31, -22])
        reg_panel_label("profile overrides", y = 0, z = 0, size = 2.7, h = 0.14);
}

if (REG_LIST) {
    reg_list_tests(TESTS);
} else {
    spec = TESTS[T];

    if (spec[1] == "mode")
        _render_mode_sweep(spec[2]);
    else
        _render_profile();
}
