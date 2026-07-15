/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

include <../../common/regression_common.scad>

use <../../../../polysymmetrica/core/duals.scad>
use <../../../../polysymmetrica/core/funcs.scad>
use <../../../../polysymmetrica/core/prisms.scad>
use <../../../../polysymmetrica/core/solvers.scad>
use <../../../../polysymmetrica/core/truncation.scad>
use <../../../../polysymmetrica/models/platonics_all.scad>
use <../../../../polysymmetrica/models/archimedians_all.scad>

TESTS = [
    ["tet_truncate", function() poly_truncate(tetrahedron())],
    ["cube_rectify", function() poly_rectify(hexahedron())],
    ["dod_chamfer", function() poly_chamfer(dodecahedron())],
    ["ico_cantellate", function() poly_cantellate(icosahedron())],
    ["tet_cantitruncate", function() poly_cantitruncate(tetrahedron())],
    ["cube_snub", function() poly_snub(hexahedron(), c = 0.06, df = 0.03, angle = 12)],
    ["prism6_dual", function() poly_dual(poly_prism(6))],
    ["prism6_cantellate", function() poly_cantellate(poly_prism(6))],
    ["ap5_2_truncate", function() poly_truncate(poly_antiprism(5, 2), t = 0.18)],
    ["ap7_twist_cantellate", function() poly_cantellate(poly_antiprism(7, 3, angle = 12), profile = _tm_ap7_rows())],
    ["trunc_dod_dual", function() poly_dual(truncated_dodecahedron())],
    [
        "cuboct_dominant_ct",
        function() poly_cantitruncate(
            cuboctahedron(),
            t = 0,
            c = 0,
            profile = solve_cantitruncate_dominant_edges_profile_rows(cuboctahedron(), 4)
        )
    ],
    ["star_fan_truncate", function() poly_truncate(_tm_star_fan_pyramid(), t = 0.2)]
];

T_MAX = len(TESTS);
T = is_undef(T) ? 0 : T;
REG_LIST = is_undef(REG_LIST) ? false : REG_LIST;

assert(T >= 0 && T < T_MAX, str("T out of range: ", T));

function _tm_ap7_rows() = [
    ["face", "family", 0, ["df", 0.30]],
    ["face", "family", 1, ["df", 0.30]]
];

function _tm_star_fan_pyramid() =
    let(
        s = [1, 3, 5, 2, 4],
        base = [for (i = [0:1:4]) [cos(90 + i * 72), sin(90 + i * 72), 0]],
        verts = concat([[0, 0, 1]], base),
        side_faces = [
            for (i = [0:1:len(s)-1])
                [0, s[i], s[(i + 1) % len(s)]]
        ],
        base_face = [for (i = [len(s)-1:-1:0]) s[i]]
    )
    poly_make(verts, concat(side_faces, [base_face]), 1);

if (REG_LIST) {
    reg_list_tests(TESTS);
} else {
    spec = TESTS[T];
    reg_poly_preview(spec[1](), ir = 28, show_face_ids = true);
    reg_panel_label(spec[0]);
}
