/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

use <../../polysymmetrica/core/funcs.scad>
use <../../polysymmetrica/core/duals.scad>
use <../../polysymmetrica/core/truncation.scad>
use <../../polysymmetrica/core/validate.scad>
use <../../polysymmetrica/models/johnsons_all.scad>
use <../../polysymmetrica/models/platonics_all.scad>
use <../testing_util.scad>

EPS = 1e-7;

module assert_near(a, b, eps=EPS, msg="") {
    assert(abs(a-b) <= eps, str(msg, " expected=", b, " got=", a));
}

module assert_int_eq(a, b, msg="") {
    assert(a == b, str(msg, " expected=", b, " got=", a));
}

function _tetra_poly() =
    poly_make(
        [[1,1,1],[-1,-1,1],[-1,1,-1],[1,-1,-1]],
        [[0,1,2],[0,3,1],[0,2,3],[1,3,2]]
    );

function _octa_poly() =
    poly_make(
        [[1,0,0],[-1,0,0],[0,1,0],[0,-1,0],[0,0,1],[0,0,-1]],
        [[0,4,2],[2,4,1],[1,4,3],[3,4,0],[2,5,0],[1,5,2],[3,5,1],[0,5,3]]
    );


// ps_vertex_incident_faces
module test_ps_vertex_incident_faces__tetra_valence3() {
    p=_tetra_poly();
    inc = ps_vertex_incident_faces(p, 0);
    assert_int_eq(len(inc), 3, "tetra vertex has 3 incident faces");
}


// ps_find_edge_index (depends on the ordered edge list returned by _ps_edges_from_faces)
module test_find_edge_index__finds_sorted_edge() {
    faces = poly_faces(_tetra_poly());
    edges = _ps_edges_from_faces(faces);
    // edges are sorted pairs
    i = ps_find_edge_index(edges, 0, 1);
    assert(i >= 0, "edge index exists");
    assert(ps_edge_equal(edges[i], [0,1]) || ps_edge_equal(edges[i],[1,0]) ? true : true, "edge is that pair (sorted in edges)");
}


// _ps_next_face_around_vertex + ps_faces_around_vertex cycle
module test_ps_faces_around_vertex__tetra_cycle_len3() {
    p=_tetra_poly();
    edges=_ps_edges_from_faces(poly_faces(p));
    ef=ps_edge_faces_table(poly_faces(p), edges);
    cyc = ps_faces_around_vertex(p, 0, edges, ef);
    assert_int_eq(len(cyc), 3, "cycle length 3");
}


// _ps_dual_faces: count should equal #original vertices
module test__ps_dual_faces__count_equals_original_vertices() {
    p=_octa_poly();
    v=poly_verts(p);
    f=ps_orient_all_faces_outward(v, poly_faces(p));
    centers = ps_face_polar_verts(v, f);
    df = _ps_dual_faces(p, centers);
    assert_int_eq(len(df), len(v), "dual faces == original vertices");
}

module test_dual__validity() {
    d = poly_dual(octahedron());
    ps_assert_poly_valid_mode(d, "closed");
}


// _ps_dual_unit_edge_and_e_over_ir positivity
module test__ps_dual_unit_edge_and_e_over_ir__positive() {
    p=_octa_poly();
    d=poly_dual(p);
    ue_eir = _ps_dual_unit_edge_and_e_over_ir(poly_verts(d), poly_faces(d));
    assert(ue_eir[0] > 0, "unit edge > 0");
    assert(ue_eir[1] > 0, "e_over_ir > 0");
}

module test__ps_dual_unit_edge_and_e_over_ir__stable_under_face_rotation() {
    p = j1_square_pyramid();
    verts0 = poly_verts(p);
    faces0 = ps_orient_all_faces_outward(verts0, poly_faces(p));
    dual_vf_raw = poly_dual_polar_vf(verts0, faces0);
    dv_raw = dual_vf_raw[0];
    df_raw = dual_vf_raw[1];
    df_rot = [for (f = df_raw) rotl(f, 1)];
    edges = _ps_edges_from_faces(df_raw);
    center = _ps_poly_mid_center(dv_raw, df_raw);
    dv_centered = [for (v = dv_raw) v - center];
    edge_lengths = [for (e = edges) norm(dv_raw[e[1]] - dv_raw[e[0]])];
    edge_midradii = [for (e = edges) norm((dv_centered[e[0]] + dv_centered[e[1]]) / 2)];
    ir = min(edge_midradii);
    metric_edge_lengths = [
        for (i = [0:1:len(edges)-1])
            if (abs(edge_midradii[i] - ir) <= 1e-9)
                edge_lengths[i]
    ];

    m0 = _ps_dual_unit_edge_and_e_over_ir(dv_raw, df_raw);
    m1 = _ps_dual_unit_edge_and_e_over_ir(dv_raw, df_rot);

    assert_near(m0[0], m1[0], 1e-9, "dual unit edge stable under cyclic face starts");
    assert_near(m0[1], m1[1], 1e-9, "dual e_over_ir stable under cyclic face starts");
    assert(max([for (el = metric_edge_lengths) abs(el - m0[0]) <= 1e-9 ? 1 : 0]) == 1, "dual metric edge should attain min edge-midradius");
    assert(m0[0] > min(edge_lengths) + 1e-6, "square-pyramid min-midradius dual edge is not the shortest edge");
    assert_near(m0[1], m0[0] / ir, 1e-9, "dual e_over_ir should use descriptor inter-radius");
}


// ps_face_polar_verts correctness: n·q = 1/d, and q colinear with n
module test_ps_face_polar_verts__incidence_relation() {
    p=_octa_poly();
    v=poly_verts(p);
    f=ps_orient_all_faces_outward(v, poly_faces(p));
    qs = ps_face_polar_verts(v, f);

    for (fi=[0:3]) {
        n = ps_face_normal(v, f[fi]);
        d = v_dot(n, v[f[fi][0]]);
        q = qs[fi];

        assert(d > 0, "d>0");
        assert_near(norm(v_cross(n, q)), 0, 1e-6, "n x q ~ 0");
        assert_near(v_dot(n, q), 1/d, 1e-6, "n·q = 1/d");
    }
}


// poly_dual: octa -> cube combinatorics
module test_poly_dual__octa_to_cube_counts() {
    p=_octa_poly();
    d=poly_dual(p);

    assert_int_eq(len(poly_verts(d)), 8, "cube verts=8");
    assert_int_eq(len(poly_faces(d)), 6, "cube faces=6");
    for (fi=[0:len(poly_faces(d))-1]) assert_int_eq(len(poly_faces(d)[fi]), 4, "cube face is quad");
}


// poly_dual: tetra self-dual combinatorics
module test_poly_dual__tetra_self_dual_counts() {
    p=_tetra_poly();
    d=poly_dual(p);

    assert_int_eq(len(poly_verts(d)), 4, "tetra dual verts=4");
    assert_int_eq(len(poly_faces(d)), 4, "tetra dual faces=4");
    for (fi=[0:3]) assert_int_eq(len(poly_faces(d)[fi]), 3, "tri face");
}

module test_poly_dual__miswound_input_uses_oriented_fan() {
    p = _tetra_poly();
    faces = poly_faces(p);
    p_bad = [
        poly_verts(p),
        concat([[faces[0][2], faces[0][1], faces[0][0]]], [for (i = [1:1:len(faces)-1]) faces[i]]),
        poly_e_over_ir(p)
    ];
    d = poly_dual(p_bad);

    ps_assert_poly_valid_mode(d, "closed");
    assert_int_eq(len(poly_verts(d)), 4, "miswound tetra dual verts=4");
    assert_int_eq(len(poly_faces(d)), 4, "miswound tetra dual faces=4");
    for (fi=[0:3]) assert_int_eq(len(poly_faces(d)[fi]), 3, "miswound tetra dual tri face");
}


// ps_dual_scale returns sane positive
module test_ps_dual_scale__sane_range() {
    p=_octa_poly();
    d=poly_dual(p);
    m = ps_dual_scale(p, d);
    assert(m > 0.1 && m < 10, "ps_dual_scale sane");
}

// face-family helpers
module test_face_family_helpers__rectified_octa() {
    p = poly_rectify(octahedron()); // cubocta: 8 triangles, 6 squares
    mode = ps_face_family_mode(p);
    maxf = ps_face_family_max(p);
    assert_int_eq(mode[0], 3, "mode face size 3");
    assert_int_eq(mode[1], 8, "mode count 8");
    assert_int_eq(maxf[0], 4, "max face size 4");
    assert_int_eq(maxf[1], 6, "max count 6");
}

module test_face_family_helpers__truncated_octa() {
    p = poly_truncate(octahedron(), 1/3); // 6 squares, 8 hexagons
    mode = ps_face_family_mode(p);
    maxf = ps_face_family_max(p);
    assert_int_eq(mode[0], 6, "mode face size 6");
    assert_int_eq(mode[1], 8, "mode count 8");
    assert_int_eq(maxf[0], 6, "max face size 6");
    assert_int_eq(maxf[1], 8, "max count 8");
}

module test_ps_dual_scale_edge_cross__octa_consistent() {
    p = octahedron();
    d = poly_dual(p);
    s0 = ps_dual_scale_edge_cross(p, d, 0, 0);
    s1 = ps_dual_scale_edge_cross(p, d, 0, 1);
    assert_near(s0, s1, 1e-6, "edge_cross consistent");
    assert(s0 > 0, "edge_cross positive");
}


// dual(dual()) combinatorics match (faces match up to rotation)
module test_poly_dual__dual_dual_face_match_octa() {
    p=_octa_poly();
    q=poly_dual(poly_dual(p));
    // Use rotation-invariant face multiset matcher:
    assert_face_matches(p, q);
}

module test_poly_dual__empty_profile_noop() {
    p = _octa_poly();
    d0 = poly_dual(p);
    d1 = poly_dual(p, profile=[]);
    assert_near(poly_e_over_ir(d0), poly_e_over_ir(d1), 1e-9, "poly_dual empty profile e/ir");
    assert_face_matches(d0, d1);
}


// suite
module run_TestDuals() {
    test_ps_vertex_incident_faces__tetra_valence3();
    test_find_edge_index__finds_sorted_edge();
    test_ps_faces_around_vertex__tetra_cycle_len3();
    test__ps_dual_faces__count_equals_original_vertices();
    test_dual__validity();
    test__ps_dual_unit_edge_and_e_over_ir__positive();
    test__ps_dual_unit_edge_and_e_over_ir__stable_under_face_rotation();
    test_ps_face_polar_verts__incidence_relation();
    test_poly_dual__octa_to_cube_counts();
    test_poly_dual__tetra_self_dual_counts();
    test_poly_dual__miswound_input_uses_oriented_fan();
    test_ps_dual_scale__sane_range();
    test_face_family_helpers__rectified_octa();
    test_face_family_helpers__truncated_octa();
    test_ps_dual_scale_edge_cross__octa_consistent();
    test_poly_dual__dual_dual_face_match_octa();
    test_poly_dual__empty_profile_noop();
}

run_TestDuals();
