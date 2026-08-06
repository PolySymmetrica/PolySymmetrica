/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

use <../../polysymmetrica/core/funcs.scad>
use <../../polysymmetrica/core/truncation.scad>
use <../../polysymmetrica/core/validate.scad>
use <../../polysymmetrica/models/catalans_all.scad>
use <../../polysymmetrica/models/platonics_all.scad>
use <../testing_util.scad>

EPS = 1e-7;

module assert_int_eq(a, b, msg="") {
    assert(a == b, str(msg, " expected=", b, " got=", a));
}

function _count_faces_of_size(poly, k) =
    ps_sum([ for (f = poly_faces(poly)) (len(f)==k) ? 1 : 0 ]);

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

function _max_vertex_diff(p1, p2) =
    let(
        v1 = poly_verts(p1),
        v2 = poly_verts(p2),
        n = min(len(v1), len(v2))
    )
    (n == 0) ? 0 : max([for (i = [0:1:n-1]) norm(v1[i] - v2[i])]);

function _cantellate_source_vertex_faces(poly, q) =
    let(
        faces = poly_faces(q)
    )
    [for (i = [len(faces) - len(poly_verts(poly)):1:len(faces)-1]) faces[i]];

module test_poly_cantellate__tetra_counts() {
    p = tetrahedron();
    q = poly_cantellate(p, 0.2);
    expected_faces = len(poly_faces(p)) + len(_ps_edges_from_faces(poly_faces(p))) + len(poly_verts(p));
    assert_int_eq(len(poly_faces(q)), expected_faces, "cantellate faces count");
    assert_int_eq(_count_faces_of_size(q, 3), 8, "cantellate tetra: 8 triangles");
    assert_int_eq(_count_faces_of_size(q, 4), 6, "cantellate tetra: 6 quads");
}

module test_poly_cantellate__cube_counts() {
    p = hexahedron();
    q = poly_cantellate(p, 0.2);
    expected_faces = len(poly_faces(p)) + len(_ps_edges_from_faces(poly_faces(p))) + len(poly_verts(p));
    assert_int_eq(len(poly_faces(q)), expected_faces, "cantellate cube faces count");
    assert_int_eq(_count_faces_of_size(q, 3), 8, "cantellate cube: 8 triangles");
    assert_int_eq(_count_faces_of_size(q, 4), 18, "cantellate cube: 18 quads");
}

module test_poly_cantellate__strict_exposes_irregular_vertex_cap_nonplanarity() {
    p = _irregular_valence4_bipyramid();
    q = poly_cantellate(p, df = 0.1);
    verts = poly_verts(q);
    vert_faces = _cantellate_source_vertex_faces(p, q);
    err = _ps_faces_max_planarity_err(verts, vert_faces);

    assert(err > 1e-4, str("strict cantellate should expose irregular source-vertex cap non-planarity err=", err));
}

module test_poly_cantellate__planarized_keeps_irregular_faces_planar() {
    p = _irregular_valence4_bipyramid();
    q = poly_cantellate(p, df = 0.1, style = "planarized");
    err = _ps_faces_max_planarity_err(poly_verts(q), poly_faces(q));

    assert(err <= 1e-7, str("planarized cantellate should keep all faces planar err=", err));
    assert(poly_valid(q, "closed", 1e-7), "planarized cantellate irregular output should remain closed-valid");
}

module test_poly_cantellate__planarized_keeps_tetrakis_faces_planar() {
    p = tetrakis_hexahedron();
    q = poly_cantellate(p, df = 0.1, style = "planarized");
    err = _ps_faces_max_planarity_err(poly_verts(q), poly_faces(q));

    assert(err <= 1e-7, str("planarized cantellate tetrakis output should remain planar err=", err));
    assert(poly_valid(q, "closed", 1e-7), "planarized cantellate tetrakis output should remain closed-valid");
}

module test_poly_cantellate__planarized_edge_fraction_matches_strict() {
    p = _irregular_valence4_bipyramid();
    q_strict = poly_cantellate(p, df = 0.1);
    q_edge = poly_cantellate(p, df = 0.1, style = "planarized", cap_mode = "edge_fraction");

    assert(_max_vertex_diff(q_strict, q_edge) < 1e-7, "planarized edge_fraction should collapse to strict cantellation points");
    assert_int_eq(len(poly_verts(q_strict)), len(poly_verts(q_edge)), "planarized edge_fraction should collapse duplicate cap vertices");
    assert_int_eq(len(poly_faces(q_strict)), len(poly_faces(q_edge)), "planarized edge_fraction should collapse degenerate connector faces");
}

module test_poly_cantellate__profile_vertex_cap_mode() {
    p = _irregular_valence4_bipyramid();
    q_profile = poly_cantellate(
        p,
        df = 0.1,
        style = "planarized",
        profile = [["vert", "id", 0, ["cap_mode", "edge_fraction"]]]
    );
    vert_faces = _cantellate_source_vertex_faces(p, q_profile);
    apex_cap = vert_faces[0];
    err = _ps_face_planarity_err(poly_verts(q_profile), apex_cap);

    assert(err > 1e-4, "vertex profile cap_mode=edge_fraction should preserve the raw skew cap at that vertex");
}

module run_TestCantellation() {
    test_poly_cantellate__tetra_counts();
    test_poly_cantellate__cube_counts();
    test_poly_cantellate__strict_exposes_irregular_vertex_cap_nonplanarity();
    test_poly_cantellate__planarized_keeps_irregular_faces_planar();
    test_poly_cantellate__planarized_keeps_tetrakis_faces_planar();
    test_poly_cantellate__planarized_edge_fraction_matches_strict();
    test_poly_cantellate__profile_vertex_cap_mode();
}

run_TestCantellation();
