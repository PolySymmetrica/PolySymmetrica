/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

use <../../polysymmetrica/core/face_regions.scad>
use <../../polysymmetrica/core/funcs.scad>
use <../../polysymmetrica/core/loop_shells.scad>
use <../../polysymmetrica/core/placement.scad>
use <../../polysymmetrica/core/prisms.scad>
use <../../polysymmetrica/core/segments.scad>
use <../../polysymmetrica/core/truncation.scad>
use <../../polysymmetrica/core/construction.scad>
use <../../polysymmetrica/models/archimedians_all.scad>
use <../../polysymmetrica/models/platonics_all.scad>
use <../../polysymmetrica/models/tetrahedron.scad>

EPS = 1e-8;

module assert_int_eq(a, b, msg="") {
    assert(a == b, str(msg, " expected=", b, " got=", a));
}

module assert_near(a, b, eps=EPS, msg="") {
    assert(abs(a - b) <= eps, str(msg, " expected=", b, " got=", a));
}

function _test_face_site(poly, face_idx) =
    ps_face_sites(poly)[face_idx];

function _test_shell_points_are_finite(points) =
    len([
        for (p = points)
            if (!is_undef(p) && len(p) == 3 && norm(p) < 1e9)
                1
    ]) == len(points);

function _test_seg_intersects(a, b, c, d, eps=EPS) =
    let(
        r = b - a,
        s = d - c,
        den = r[0] * s[1] - r[1] * s[0],
        q = c - a,
        ta = (abs(den) <= eps) ? undef : ((q[0] * s[1] - q[1] * s[0]) / den),
        tb = (abs(den) <= eps) ? undef : ((q[0] * r[1] - q[1] * r[0]) / den)
    )
    !is_undef(ta) && !is_undef(tb) && ta > eps && ta < 1 - eps && tb > eps && tb < 1 - eps;

function _test_loop_self_hits(loop, eps=EPS) =
    let(n = len(loop))
    [
        for (i = [0:1:n-1])
            for (j = [i+1:1:n-1])
                if (abs(i - j) > 1 && !(i == 0 && j == n - 1))
                    if (_test_seg_intersects(loop[i], loop[(i + 1) % n], loop[j], loop[(j + 1) % n], eps))
                        [i, j]
    ];

function _test_shell_caps_are_simple(shell, eps=EPS) =
    len(_test_loop_self_hits(ps_loop_shell_bottom_loop2d(shell), eps)) == 0
        && len(_test_loop_self_hits(ps_loop_shell_top_loop2d(shell), eps)) == 0;

function _test_first_face_idx_by_n(poly, n, i=0) =
    (i >= len(poly_faces(poly))) ? undef :
    (len(poly_faces(poly)[i]) == n) ? i : _test_first_face_idx_by_n(poly, n, i + 1);

function _test_loop_perimeter(loop) =
    ps_sum([
        for (i = [0:1:len(loop)-1])
            norm(loop[(i + 1) % len(loop)] - loop[i])
    ]);

function _test_loop_inradius(loop) =
    abs(_ps_seg_poly_area2(loop)) / _test_loop_perimeter(loop);

module test_ps_face_region_loop_shells__cube_face_single_quad_shell() {
    p = hexahedron();
    site = _test_face_site(p, 0);
    face_ctx = ps_face_site_face_local_context(site);
    shells = ps_face_region_loop_shells(face_ctx, -0.4, 0.6);

    assert_int_eq(len(shells), 1, "cube face should produce one filled boundary shell");
    assert_int_eq(len(ps_loop_shell_points(shells[0])), 8, "cube quad shell should have bottom+top vertices");
    assert_int_eq(len(ps_loop_shell_faces(shells[0])), 8, "quad shell should have two triangulated caps plus four sides");
    assert_int_eq(ps_loop_shell_exposure_sign(shells[0]), 1, "cube shell should be top-exposed");
    assert(_test_shell_points_are_finite(ps_loop_shell_points(shells[0])), "cube shell points should be finite");
    assert(_test_shell_caps_are_simple(shells[0]), "cube shell cap loops should be simple");

    zs = [for (p = ps_loop_shell_points(shells[0])) p[2]];
    assert_near(min(zs), -0.4, EPS, "cube shell min z");
    assert_near(max(zs), 0.6, EPS, "cube shell max z");
}

module test_ps_loop_shell_describe_str__summary() {
    p = hexahedron();
    site = _test_face_site(p, 0);
    face_ctx = ps_face_site_face_local_context(site);
    shell = ps_face_region_loop_shells(face_ctx, -0.4, 0.6)[0];
    s = ps_loop_shell_describe_str(shell);
    assert(s == "LoopShell(source_kind=face_region, source_idx=0, point_count=8, face_count=8)", "loop shell summary string");
}

module test_ps_face_region_loop_shells__boundary_inset_shrinks_shell() {
    p = hexahedron();
    site = _test_face_site(p, 0);
    face_ctx = ps_face_site_face_local_context(site);
    shells0 = ps_face_region_loop_shells(face_ctx, -0.4, 0.6);
    shells1 = ps_face_region_loop_shells(face_ctx, -0.4, 0.6, boundary_inset = 0.1);

    assert_int_eq(len(shells1), len(shells0), "boundary inset should preserve shell count");
    assert(abs(_ps_seg_poly_area2(ps_loop_shell_bottom_loop2d(shells1[0]))) < abs(_ps_seg_poly_area2(ps_loop_shell_bottom_loop2d(shells0[0]))), "boundary inset should shrink z0 cap");
    assert(abs(_ps_seg_poly_area2(ps_loop_shell_top_loop2d(shells1[0]))) < abs(_ps_seg_poly_area2(ps_loop_shell_top_loop2d(shells0[0]))), "boundary inset should shrink z1 cap");
    assert_int_eq(len(ps_loop_shell_top_loop2d(shells1[0])), 4, "top loop accessor should expose inset cap loop");
}

module test_ps_face_region_loop_shells__cubocta_high_valence_vertex_clips_triangle_corners() {
    p = cuboctahedron();
    face_idx = _test_first_face_idx_by_n(p, 3);
    site = _test_face_site(p, face_idx);
    face_ctx = ps_face_site_face_local_context(site);
    shells0 = ps_face_region_loop_shells(face_ctx, -0.05, 0.05, boundary_inset = 0);
    shells1 = ps_face_region_loop_shells(face_ctx, -0.05, 0.05, boundary_inset = 0.05);

    assert_int_eq(len(shells0), 1, "cubocta triangle should produce one base shell");
    assert_int_eq(len(shells1), 1, "cubocta triangle should produce one clipped shell");
    assert_int_eq(len(ps_loop_shell_bottom_loop2d(shells0[0])), 3, "unclipped cubocta triangle should have three cap vertices");
    assert_int_eq(len(ps_loop_shell_bottom_loop2d(shells1[0])), 6, "high-valence vertex clips should add one side at each triangle corner");
    assert(_test_shell_caps_are_simple(shells1[0]), "cubocta clipped triangle caps should be simple");
}

module test_ps_face_region_loop_shells__cubocta_high_valence_vertex_clip_inset_sweep_stays_simple() {
    p = cuboctahedron();
    face_idx = _test_first_face_idx_by_n(p, 3);
    site = _test_face_site(p, face_idx);
    face_ctx = ps_face_site_face_local_context(site);
    pts2d = ps_face_site_pts2d(site);
    inradius = _test_loop_inradius(pts2d);
    inset_factors = [0.1, 0.25, 0.5, 0.75, 0.9];

    for (f = inset_factors) {
        inset = inradius * f;
        shells = ps_face_region_loop_shells(face_ctx, -0.05, 0.05, boundary_inset = inset);

        assert_int_eq(len(shells), 1, str("cubocta inset sweep should preserve shell count f=", f));
        assert_int_eq(len(ps_loop_shell_bottom_loop2d(shells[0])), 6, str("cubocta inset sweep should keep vertex clips f=", f));
        assert(_test_shell_caps_are_simple(shells[0]), str("cubocta inset sweep caps should stay simple f=", f));
    }
}

module test_ps_face_region_span_end_source_vertex_idx__recognizes_reversed_endpoint() {
    face = [10, 11, 12, 13];
    forward_site = [0, undef, 0, undef, 0, 2, 0, 1];
    reversed_site = [0, undef, 0, undef, 0, 2, 1, 0];
    partial_site = [0, undef, 0, undef, 0, 2, 0.25, 0.75];

    assert_int_eq(_ps_fr_span_end_source_vertex_idx(forward_site, face), 13, "forward source edge endpoint should map to face[i+1]");
    assert_int_eq(_ps_fr_span_end_source_vertex_idx(reversed_site, face), 12, "reversed source edge endpoint should map to face[i]");
    assert(is_undef(_ps_fr_span_end_source_vertex_idx(partial_site, face)), "partial source edge endpoint should not map to a source vertex");
}

module test_ps_face_region_loop_shells__open_boundary_vertex_skips_fan_clip() {
    p = poly_delete_faces(hexahedron(), 0, cap=false, cleanup=false);
    site = _test_face_site(p, 0);
    face_ctx = ps_face_site_face_local_context(site);
    shells = ps_face_region_loop_shells(face_ctx, -0.05, 0.05, boundary_inset = 0.05);

    assert_int_eq(len(shells), 1, "open cube face should still produce an inset shell");
    assert_int_eq(len(ps_loop_shell_bottom_loop2d(shells[0])), 4, "open boundary vertices should not add vertex-fan clip sides");
    assert(_test_shell_caps_are_simple(shells[0]), "open cube inset shell caps should be simple");
}

module test_ps_face_region_vertex_clip_line__skips_unrealizable_cap_plane() {
    verts = [
        [0, 0, 0],
        [1, 0, 0],
        [0, 1, 1],
        [-1, 0, 0],
        [0, -1, 1]
    ];
    faces = [[0, 1, 2], [0, 2, 3], [0, 3, 4], [0, 4, 1], [1, 4, 3, 2]];
    edges = _ps_edges_from_faces(faces);
    edge_faces = ps_edge_faces_table(faces, edges);
    clip_line = _ps_fr_vertex_clip_line(
        faces,
        verts,
        edges,
        edge_faces,
        0,
        0,
        [[0, 0], [1, 0]],
        [[0, 0], [0, 1]],
        boundary_inset = 0.1
    );

    assert(is_undef(clip_line), "unrealizable high-valence fan clip should be skipped");
}

module test_ps_face_region_loop_shells__site_context_matches_raw_context_builder() {
    p = hexahedron();
    site = _test_face_site(p, 0);
    face_ctx = ps_face_site_face_local_context(site);
    face_ctx_raw = ps_face_local_context(
        ps_face_site_pts3d_local(site),
        ps_face_site_pts2d(site),
        site[0],
        ps_face_site_poly_faces_idx(site),
        ps_face_site_poly_verts_local(site),
        ps_face_site_neighbors_idx(site),
        ps_face_site_dihedrals(site),
        ps_face_site_poly_center_local(site)
    );
    shells_ctx = ps_face_region_loop_shells(face_ctx, -0.4, 0.6);
    shells_raw_ctx = ps_face_region_loop_shells(face_ctx_raw, -0.4, 0.6);

    assert_int_eq(len(shells_ctx), len(shells_raw_ctx), "context shell count should match raw context shell count");
    for (i = [0:1:len(shells_raw_ctx)-1]) {
        assert(ps_loop_shell_points(shells_ctx[i]) == ps_loop_shell_points(shells_raw_ctx[i]), str("context shell points should match i=", i));
        assert(ps_loop_shell_faces(shells_ctx[i]) == ps_loop_shell_faces(shells_raw_ctx[i]), str("context shell faces should match i=", i));
        assert_int_eq(ps_loop_shell_source_idx(shells_ctx[i]), ps_loop_shell_source_idx(shells_raw_ctx[i]), str("context shell loop idx should match i=", i));
        assert_int_eq(ps_loop_shell_capped_count(shells_ctx[i]), ps_loop_shell_capped_count(shells_raw_ctx[i]), str("context shell capped count should match i=", i));
        assert_int_eq(ps_loop_shell_exposure_sign(shells_ctx[i]), ps_loop_shell_exposure_sign(shells_raw_ctx[i]), str("context shell exposure sign should match i=", i));
    }
}

module test_ps_face_region_loop_shells__side_inset_compensates_face_offset() {
    p = hexahedron();
    site = _test_face_site(p, 0);
    face_pts3d_local = ps_face_site_pts3d_local(site);
    arr = ps_face_arrangement(face_pts3d_local, EPS);
    input_area = _ps_seg_poly_area2(ps_xy(face_pts3d_local));
    input_sign = (input_area >= 0) ? 1 : -1;
    cell_winding_signs = _ps_fr_cell_winding_signs(face_pts3d_local, arr[4], EPS);
    span_sites = _ps_face_boundary_span_sites(
        face_pts3d_local,
        site[0],
        ps_face_site_poly_faces_idx(site),
        ps_face_site_poly_verts_local(site),
        ps_face_site_neighbors_idx(site),
        ps_face_site_dihedrals(site),
        "nonzero",
        EPS
    );
    span_site = span_sites[0];
    dir = _ps_fr_span_bisector_dir_local(span_site, input_sign, cell_winding_signs, EPS);
    face_offset = _ps_fr_boundary_inset_face_offset(span_site, dir, 0.1, "face", EPS);
    side_offset = _ps_fr_boundary_inset_face_offset(span_site, dir, 0.1, "side", EPS);

    assert_near(face_offset, 0.1, EPS, "face inset mode should use raw face-plane offset");
    assert(side_offset > face_offset, str("side inset mode should compensate angled side offset face=", face_offset, " side=", side_offset));
}

module test_ps_face_region_loop_shells__matches_boundary_loop_count() {
    p = poly_antiprism(5, 2);
    site = _test_face_site(p, 1);
    face_pts3d_local = ps_face_site_pts3d_local(site);
    face_ctx = ps_face_site_face_local_context(site);
    bm = ps_face_boundary_model(face_pts3d_local, "nonzero");
    shells = ps_face_region_loop_shells(face_ctx, -0.3, 0.3, "nonzero");

    assert_int_eq(len(shells), len(bm[2]), "one shell per filled boundary loop");
    for (i = [0:1:len(shells)-1])
        assert_int_eq(len(ps_loop_shell_points(shells[i])), 2 * len(bm[2][i][0]), "shell vertices should match loop arity");
}

module test_ps_face_region_loop_shells__pentagram_zmax_expands_outward() {
    p = poly_antiprism(5, 2);
    site = _test_face_site(p, 1);
    face_ctx = ps_face_site_face_local_context(site);
    shells = ps_face_region_loop_shells(face_ctx, -0.5, 0.5, "nonzero");

    assert_int_eq(len(shells), 1, "pentagram cap should produce one shell");
    area_zmin = abs(_ps_seg_poly_area2(ps_loop_shell_bottom_loop2d(shells[0])));
    area_zmax = abs(_ps_seg_poly_area2(ps_loop_shell_top_loop2d(shells[0])));
    assert(
        area_zmax > area_zmin,
        str("pentagram +Z cap should expand outward area_zmin=", area_zmin, " area_zmax=", area_zmax)
    );
    assert(_test_shell_caps_are_simple(shells[0]), "pentagram shell cap loops should be simple");
}

module test_ps_face_region_loop_shells__zero_winding_exposure_uses_same_winding_fallback() {
    zero_cell_site = [0, undef, 0, undef, 0, undef, 0, 1, "source_edge", 0];

    assert_int_eq(
        _ps_fr_span_exposure_sign(zero_cell_site, 1, [0]),
        1,
        "zero-winding cells should use same-winding exposure fallback"
    );
}

module test_ps_face_region_loop_shells__anti_tet_hex_is_finite() {
    p = poly_truncate(tetrahedron(), t = -0.5);
    site = _test_face_site(p, 0);
    face_ctx = ps_face_site_face_local_context(site);
    shells = ps_face_region_loop_shells(face_ctx, -0.25, 0.25, "nonzero", 20);

    assert(len(shells) >= 1, "anti-truncated tetrahedron hex should produce at least one shell");
    for (shell = shells) {
        assert(len(ps_loop_shell_points(shell)) >= 6, "anti-tet shell should have points");
        assert(len(ps_loop_shell_faces(shell)) >= 4, "anti-tet shell should have faces");
        assert(abs(ps_loop_shell_exposure_sign(shell)) == 1, "anti-tet shell should have a signed exposure");
        assert(_test_shell_points_are_finite(ps_loop_shell_points(shell)), "anti-tet shell points should be finite");
        assert(_test_shell_caps_are_simple(shell), "anti-tet shell cap loops should be simple");
    }
}

module test_ps_face_region_loop_shells__anti_tet_winding_splits_exposure() {
    p = poly_truncate(tetrahedron(), t = -0.5);
    site = _test_face_site(p, 0);
    face_ctx = ps_face_site_face_local_context(site);
    shells = ps_face_region_loop_shells(face_ctx, -0.5, 0.5, "nonzero", 20);

    assert_int_eq(len(shells), 4, "anti-tet hex should split into one centre and three corner shells");

    exposure_signs = [
        for (shell = shells)
            ps_loop_shell_exposure_sign(shell)
    ];
    top_count = ps_sum([for (sign = exposure_signs) sign > 0 ? 1 : 0]);
    bottom_count = ps_sum([for (sign = exposure_signs) sign < 0 ? 1 : 0]);

    assert_int_eq(top_count, 1, "anti-tet same-winding centre shell should be top-exposed");
    assert_int_eq(bottom_count, 3, "anti-tet opposite-winding corner shells should be bottom-exposed");
}

module test_ps_face_region_loop_shells__anti_tet_past_zero_area_keeps_atom_regions() {
    p = poly_truncate(tetrahedron(), t = -1);
    site = _test_face_site(p, 0);
    face_ctx = ps_face_site_face_local_context(site);
    bm = ps_face_boundary_model(ps_face_site_pts3d_local(site), "nonzero", 1e-4);
    shells = ps_face_region_loop_shells(face_ctx, -0.5, 0.5, "nonzero", 20, 1e-4);

    assert_int_eq(len(bm[2]), 4, "anti-tet past zero-area threshold should keep four boundary loops");
    assert_int_eq(len(shells), 4, "anti-tet past zero-area threshold should keep four face-region shells");

    for (i = [0:1:len(shells)-1]) {
        assert_int_eq(len(ps_loop_shell_bottom_loop2d(shells[i])), 3, str("anti-tet threshold shell should be triangular i=", i));
        assert(_test_shell_caps_are_simple(shells[i], 1e-4), str("anti-tet threshold shell cap loops should be simple i=", i));
    }

    exposure_signs = [
        for (shell = shells)
            ps_loop_shell_exposure_sign(shell)
    ];
    top_count = ps_sum([for (sign = exposure_signs) sign > 0 ? 1 : 0]);
    bottom_count = ps_sum([for (sign = exposure_signs) sign < 0 ? 1 : 0]);

    assert_int_eq(top_count, 1, "anti-tet threshold centre shell should remain top-exposed");
    assert_int_eq(bottom_count, 3, "anti-tet threshold corner shells should remain bottom-exposed");
}

module test_ps_face_region_projection_cap__limits_offset() {
    assert_near(_ps_fr_project_offset(10, 0.5, 3), 3, EPS, "positive projection cap");
    assert_near(_ps_fr_project_offset(-10, 0.5, 3), -3, EPS, "negative projection cap");
    assert_near(_ps_fr_project_offset(10, 0.5, undef), 20, EPS, "uncapped projection");
    assert_near(_ps_fr_project_offset(10, 0, 3), 3, EPS, "near-flat projection uses cap");
}

module test_ps_face_region_loop_shells__clips_before_projected_loop_convergence() {
    p = poly_rectify(dodecahedron());
    site = ps_face_sites(p, inter_radius = 20)[13];
    face_ctx = ps_face_site_face_local_context(site);
    shells = ps_face_region_loop_shells(face_ctx, -5, 4, boundary_inset = 3);
    shell = shells[0];
    bottom = ps_loop_shell_bottom_loop2d(shell);
    top = ps_loop_shell_top_loop2d(shell);

    assert_int_eq(len(shells), 1, "rectified dodecahedron face should still produce one clipped shell");
    assert(ps_loop_shell_z0(shell) > -5 + EPS, str("z0 should be clipped before convergence got=", ps_loop_shell_z0(shell)));
    assert_near(ps_loop_shell_z1(shell), 4, EPS, "z1 should remain unchanged");
    assert(_ps_seg_poly_area2(bottom) * _ps_seg_poly_area2(top) > 0, "clipped cap loops should keep the same orientation");
    assert(_test_shell_caps_are_simple(shell, 1e-6), "clipped convergence shell caps should be simple");
}

module run_TestFaceRegions() {
    test_ps_face_region_loop_shells__cube_face_single_quad_shell();
    test_ps_loop_shell_describe_str__summary();
    test_ps_face_region_loop_shells__boundary_inset_shrinks_shell();
    test_ps_face_region_loop_shells__cubocta_high_valence_vertex_clips_triangle_corners();
    test_ps_face_region_loop_shells__cubocta_high_valence_vertex_clip_inset_sweep_stays_simple();
    test_ps_face_region_span_end_source_vertex_idx__recognizes_reversed_endpoint();
    test_ps_face_region_loop_shells__open_boundary_vertex_skips_fan_clip();
    test_ps_face_region_vertex_clip_line__skips_unrealizable_cap_plane();
    test_ps_face_region_loop_shells__site_context_matches_raw_context_builder();
    test_ps_face_region_loop_shells__side_inset_compensates_face_offset();
    test_ps_face_region_loop_shells__matches_boundary_loop_count();
    test_ps_face_region_loop_shells__pentagram_zmax_expands_outward();
    test_ps_face_region_loop_shells__zero_winding_exposure_uses_same_winding_fallback();
    test_ps_face_region_loop_shells__anti_tet_hex_is_finite();
    test_ps_face_region_loop_shells__anti_tet_winding_splits_exposure();
    test_ps_face_region_loop_shells__anti_tet_past_zero_area_keeps_atom_regions();
    test_ps_face_region_projection_cap__limits_offset();
    test_ps_face_region_loop_shells__clips_before_projected_loop_convergence();
}

run_TestFaceRegions();

cube([0.01, 0.01, 0.01], center = true);
