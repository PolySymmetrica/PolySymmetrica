/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

use <../../polysymmetrica/core/edge_regions.scad>
use <../../polysymmetrica/core/loop_shells.scad>
use <../../polysymmetrica/core/placement.scad>
use <../../polysymmetrica/core/truncation.scad>
use <../../polysymmetrica/models/platonics_all.scad>

EPS = 1e-8;

module assert_int_eq(a, b, msg="") {
    assert(a == b, str(msg, " expected=", b, " got=", a));
}

module assert_near(a, b, eps=EPS, msg="") {
    assert(abs(a - b) <= eps, str(msg, " expected=", b, " got=", a));
}

function _test_coord(points, axis) = [for (p = points) p[axis]];

function _test_shell_points_are_finite(points) =
    len([
        for (p = points)
            if (!is_undef(p) && len(p) == 3 && norm(p) < 1e9)
                1
    ]) == len(points);

module test_ps_edge_region_shells__tetra_edge_single_atom() {
    p = tetrahedron();
    shells = ps_edge_region_shells(p, outset = 0.4, z0 = -0.3, z1 = 0.6, inter_radius = 12, edge_idx = 0);
    shell = shells[0];
    pts = ps_loop_shell_points(shell);

    assert_int_eq(len(shells), 1, "tetrahedron edge should have one edge-region atom");
    assert_int_eq(len(pts), 8, "edge shell should have bottom+top rectangle vertices");
    assert_int_eq(len(ps_loop_shell_faces(shell)), 8, "edge shell should have two triangulated caps plus four sides");
    assert(ps_loop_shell_source_kind(shell) == "edge_region", "edge shell source kind");
    assert_int_eq(ps_loop_shell_source_idx(shell), 0, "edge shell source idx");
    assert_near(min(_test_coord(pts, 2)), -0.3, EPS, "edge shell z min");
    assert_near(max(_test_coord(pts, 2)), 0.6, EPS, "edge shell z max");
    assert(_test_shell_points_are_finite(pts), "edge shell points should be finite");
}

module test_ps_edge_region_shells__uses_edge_placement_context() {
    p = hexahedron();
    place_on_edges(p, edge_len = 12, indices = 0) {
        shells = ps_edge_region_shells(p, outset = 0.4, z0 = -0.5, z1 = 1.5, edge_len = 12);
        pts = ps_loop_shell_points(shells[0]);

        assert_int_eq(len(shells), 1, "cube edge should have one edge-region atom");
        assert_int_eq(ps_loop_shell_source_idx(shells[0]), $ps_edge_idx, "edge shell should inherit source edge idx");
        assert_near(min(_test_coord(pts, 0)), -$ps_edge_len / 2, EPS, "context edge shell x min");
        assert_near(max(_test_coord(pts, 0)), $ps_edge_len / 2, EPS, "context edge shell x max");
        assert_near(min(_test_coord(pts, 2)), -0.5, EPS, "context edge shell z min");
        assert_near(max(_test_coord(pts, 2)), 1.5, EPS, "context edge shell z max");
    }
}

module test_ps_edge_region_shells__anti_tet_splits_some_edges() {
    p = poly_truncate(tetrahedron(), t = -0.5);
    edge_count = len(ps_edge_sites(p));
    shell_counts = [
        for (ei = [0:1:edge_count-1])
            len(ps_edge_region_shells(p, outset = 0.2, z0 = -0.2, z1 = 0.2, inter_radius = 10, edge_idx = ei))
    ];

    assert(max(shell_counts) > 1, str("anti-truncated tetrahedron should split at least one edge into multiple atoms counts=", shell_counts));
}

module test_ps_edge_region_shells__crossing_side_constraints_split_z_range() {
    p = poly_truncate(tetrahedron(), t = -1);
    edge_count = len(ps_edge_sites(p));
    shell_counts = [
        for (ei = [0:1:edge_count-1])
            len(ps_edge_region_shells(p, outset = 1.4, z0 = -1.2, z1 = 2, inter_radius = 26, edge_idx = ei))
    ];

    assert(max(shell_counts) > 1, str("crossing side constraints should split edge region shells counts=", shell_counts));
}

module test_ps_edge_region_shells__side_constraints_preserve_identity() {
    constraints = [[0, -0.4], [0, 0.4]];
    bottom_ys = _ps_er_side_ys_for_z(constraints, -1);
    top_ys = _ps_er_side_ys_for_z(constraints, 1);

    assert_near(bottom_ys[0], -0.4, EPS, "bottom left constraint should keep its source identity");
    assert_near(bottom_ys[1], 0.4, EPS, "bottom right constraint should keep its source identity");
    assert_near(top_ys[0], -0.4, EPS, "top left constraint should keep its source identity");
    assert_near(top_ys[1], 0.4, EPS, "top right constraint should keep its source identity");
}

module test_ps_edge_region_shells__crossing_constraints_are_split_at_crossing_z() {
    ranges = _ps_er_stable_z_ranges([1, -0.4], [-1, 0.4], -1, 1, EPS);

    assert_int_eq(len(ranges), 2, "crossing constraints should split into two stable z ranges");
    assert_near(ranges[0][1], 0.4, EPS, "first split should end at crossing z");
    assert_near(ranges[1][0], 0.4, EPS, "second split should start at crossing z");
}

module run_TestEdgeRegions() {
    echo("Running TestEdgeRegions...");
    test_ps_edge_region_shells__tetra_edge_single_atom();
    test_ps_edge_region_shells__uses_edge_placement_context();
    test_ps_edge_region_shells__anti_tet_splits_some_edges();
    test_ps_edge_region_shells__crossing_side_constraints_split_z_range();
    test_ps_edge_region_shells__side_constraints_preserve_identity();
    test_ps_edge_region_shells__crossing_constraints_are_split_at_crossing_z();
    echo("TestEdgeRegions passed");
}

run_TestEdgeRegions();

cube([0.01, 0.01, 0.01], center = true);
