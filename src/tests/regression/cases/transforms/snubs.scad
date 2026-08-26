/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

include <../../common/regression_common.scad>

use <../../../../polysymmetrica/core/truncation.scad>
use <../../../../polysymmetrica/models/platonics_all.scad>

TESTS = [
    ["cube_auto", function() poly_snub(hexahedron(), verbose = 0)],
    ["cube_left_handed", function() poly_snub(hexahedron(), c = 0.06, df = 0.03, angle = 12, handedness = -1, verbose = 0)],
    ["dodeca_explicit", function() poly_snub(dodecahedron(), c = 0.07, angle = 15, verbose = 0)]
];

T_MAX = len(TESTS);
T = is_undef(T) ? 0 : T;
REG_LIST = is_undef(REG_LIST) ? false : REG_LIST;

assert(T >= 0 && T < T_MAX, str("T out of range: ", T));

if (REG_LIST) {
    reg_list_tests(TESTS, render_args = REG_RENDER_ARGS_POLY_SINGLE);
} else {
    spec = TESTS[T];
    reg_poly_preview(spec[1](), ir = 28, show_face_ids = true);
    reg_panel_label(str("snub ", spec[0]));
}
