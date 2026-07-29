/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

use <../../polysymmetrica/core/funcs.scad>
use <../../polysymmetrica/core/vertex.scad>
use <../../polysymmetrica/models/platonics_all.scad>

EPS = 1e-7;

module assert_int_eq(a, b, msg="") {
    assert(a == b, str(msg, " expected=", b, " got=", a));
}

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

function _idx_loop(n) =
    [for (i = [0:1:n-1]) i];

function _points_max_diff(a, b) =
    max([for (i = [0:1:len(a)-1]) norm(a[i] - b[i])]);

function _ray_lambda(vertex_pt, neighbor_pt, p) =
    let(dir = neighbor_pt - vertex_pt)
    v_dot(p - vertex_pt, dir) / v_dot(dir, dir);

module test_ps_vertex_figure_cap_modes__recognizes_supported_modes() {
    modes = ps_vertex_figure_cap_modes();

    assert_int_eq(len(modes), 4, "cap mode count");
    assert(ps_vertex_figure_cap_mode_is_valid("planar_edge_fraction"), "planar_edge_fraction should be valid");
    assert(ps_vertex_figure_cap_mode_is_valid("edge_fraction"), "edge_fraction should be valid");
    assert(ps_vertex_figure_cap_mode_is_valid("centric"), "centric should be valid");
    assert(ps_vertex_figure_cap_mode_is_valid("poly_centroidal"), "poly_centroidal should be valid");
    assert(!ps_vertex_figure_cap_mode_is_valid("bogus"), "bogus cap mode should be rejected");
}

module test_ps_vertex_figure_points__edge_fraction_matches_raw_edge_points() {
    p = tetrahedron();
    verts = poly_verts(p);
    vi = 0;
    t = 0.25;
    fig = ps_vertex_figure(p, vi);
    neighbors = ps_vertex_figure_neighbors_idx(fig);
    expected = [for (ni = neighbors) verts[vi] + t * (verts[ni] - verts[vi])];
    pts = ps_vertex_figure_points(p, vi, t = t, cap_mode = "edge_fraction");

    assert(_points_max_diff(pts, expected) <= EPS, str("edge_fraction points should match raw edge points pts=", pts, " expected=", expected));
}

module test_ps_vertex_figure_points__planar_modes_planarize_irregular_valence4() {
    p = _irregular_valence4_bipyramid();
    modes = ["planar_edge_fraction", "centric", "poly_centroidal"];

    for (mode = modes) {
        pts = ps_vertex_figure_points(p, 0, t = 0.22, cap_mode = mode);
        err = _ps_face_planarity_err(pts, _idx_loop(len(pts)));
        assert(err <= EPS, str(mode, " should produce planar cap points err=", err, " pts=", pts));
    }
}

module test_ps_vertex_figure_points__edge_fraction_preserves_skew_irregular_valence4() {
    p = _irregular_valence4_bipyramid();
    pts = ps_vertex_figure_points(p, 0, t = 0.22, cap_mode = "edge_fraction");
    err = _ps_face_planarity_err(pts, _idx_loop(len(pts)));

    assert(err > 1e-3, str("edge_fraction should preserve non-planar raw cap err=", err, " pts=", pts));
}

module test_ps_vertex_figure_points__anti_trunc_points_are_on_opposite_rays() {
    p = _irregular_valence4_bipyramid();
    verts = poly_verts(p);
    vi = 0;
    fig = ps_vertex_figure(p, vi);
    neighbors = ps_vertex_figure_neighbors_idx(fig);
    pts = ps_vertex_figure_points(p, vi, t = -0.3, cap_mode = "planar_edge_fraction");
    lambdas = [
        for (i = [0:1:len(pts)-1])
            _ray_lambda(verts[vi], verts[neighbors[i]], pts[i])
    ];

    assert(max(lambdas) < 0, str("anti-trunc points should lie opposite incident neighbor rays lambdas=", lambdas));
}

module test_ps_vertex_figure_points__local_matches_neighbor_helper() {
    neighbor_pts = [[1, 0, 0], [0.1, 1, 0.3], [-1, 0.2, -0.1], [0, -1, 0.2]];
    poly_center_local = [0.2, 0.1, -1.4];
    pts1 = ps_vertex_figure_points_local(
        neighbor_pts,
        t = 0.22,
        cap_mode = "centric",
        poly_center_local = poly_center_local
    );
    pts2 = ps_vertex_figure_points_from_neighbors(
        [0, 0, 0],
        neighbor_pts,
        t = 0.22,
        cap_mode = "centric",
        poly_center = poly_center_local
    );

    assert(_points_max_diff(pts1, pts2) <= EPS, str("local helper should match neighbor helper pts1=", pts1, " pts2=", pts2));
}

module test_ps_vertex_figure_points_from_raw__matches_neighbor_helper_raw_loop() {
    vertex_pt = [0.2, -0.1, 0.3];
    neighbor_pts = [[1.2, 0.0, 0.1], [0.4, 1.1, 0.7], [-0.8, 0.2, -0.2], [0.0, -1.0, 0.6]];
    raw_pts = [for (p = neighbor_pts) vertex_pt + 0.31 * (p - vertex_pt)];
    poly_center = [-0.4, 0.2, -1.1];
    pts1 = ps_vertex_figure_points_from_raw(vertex_pt, raw_pts, "planar_edge_fraction", poly_center);
    pts2 = ps_vertex_figure_points_from_neighbors(vertex_pt, neighbor_pts, 0.31, "planar_edge_fraction", poly_center);

    assert(_points_max_diff(pts1, pts2) <= EPS, str("raw helper should match neighbor helper for raw edge-fraction loop pts1=", pts1, " pts2=", pts2));
}

module test_ps_vertex_figure_points_from_neighbors__small_t_parallel_check_uses_ray_angle() {
    vertex_pt = [1, 0, 0];
    neighbor_pts = [[2, 0.1, 0], [2, -0.1, 0], [2, 0, 0.1]];
    t = 1e-9;
    pts = ps_vertex_figure_points_from_neighbors(
        vertex_pt,
        neighbor_pts,
        t,
        cap_mode = "poly_centroidal",
        poly_center = [0, 0, 0]
    );
    lambdas = [
        for (i = [0:1:len(pts)-1])
            _ray_lambda(vertex_pt, neighbor_pts[i], pts[i])
    ];

    assert_int_eq(len(pts), len(neighbor_pts), "small-t vertex figure point count");
    assert(min(lambdas) > 0, str("small-t realized points should remain on incident rays lambdas=", lambdas, " pts=", pts));
    assert(max(lambdas) < 2e-9, str("small-t realized points should stay near the requested cut lambdas=", lambdas, " pts=", pts));
}

module run_TestVertex() {
    test_ps_vertex_figure_cap_modes__recognizes_supported_modes();
    test_ps_vertex_figure_points__edge_fraction_matches_raw_edge_points();
    test_ps_vertex_figure_points__planar_modes_planarize_irregular_valence4();
    test_ps_vertex_figure_points__edge_fraction_preserves_skew_irregular_valence4();
    test_ps_vertex_figure_points__anti_trunc_points_are_on_opposite_rays();
    test_ps_vertex_figure_points__local_matches_neighbor_helper();
    test_ps_vertex_figure_points_from_raw__matches_neighbor_helper_raw_loop();
    test_ps_vertex_figure_points_from_neighbors__small_t_parallel_check_uses_ray_angle();
}

run_TestVertex();

cube([0.01, 0.01, 0.01], center = true);
