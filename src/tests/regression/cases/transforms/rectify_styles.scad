/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

include <../../common/regression_common.scad>

use <../../../../polysymmetrica/core/truncation.scad>
use <../../../../polysymmetrica/models/catalans_all.scad>

TESTS = [
    ["tetrakis_strict", "strict"],
    ["tetrakis_planarized", "planarized"]
];

T_MAX = len(TESTS);
T = is_undef(T) ? 0 : T;
REG_LIST = is_undef(REG_LIST) ? false : REG_LIST;

assert(T >= 0 && T < T_MAX, str("T out of range: ", T));

if (REG_LIST) {
    reg_list_tests(TESTS);
} else {
    spec = TESTS[T];
    p = poly_rectify(tetrakis_hexahedron(), style = spec[1]);

    reg_poly_preview(p, ir = 28, show_face_ids = true);
    reg_panel_label(str("rectify ", spec[1]));
}
