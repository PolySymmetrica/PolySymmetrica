use <../../polysymmetrica/core/funcs.scad>
use <../../polysymmetrica/core/placement.scad>
use <../../polysymmetrica/core/prisms.scad>
use <../../polysymmetrica/core/segments.scad>
use <../../polysymmetrica/core/truncation.scad>
use <../../polysymmetrica/models/tetrahedron.scad>

EPS = 1e-8;
MODE = "nonzero";
STAR_FACE_IDX = 1;
TRI_FACE_IDX = 12;
ANTI_FACE_IDX = 0;

module assert_int_eq(a, b, msg="") {
    assert(a == b, str(msg, " expected=", b, " got=", a));
}

module assert_list_eq(a, b, msg="") {
    assert(a == b, str(msg, " expected=", b, " got=", a));
}

module assert_near(a, b, eps=EPS, msg="") {
    assert(abs(a - b) <= eps, str(msg, " expected=", b, " got=", a));
}

function _test_punch_poly() =
    poly_antiprism(7, 3, angle = 15);

function _test_punch_poly_angle0() =
    poly_antiprism(7, 3, angle = 0);

function _test_penta_punch_poly() =
    poly_antiprism(5, 2, angle = 15);

function _test_antitet_poly() =
    poly_truncate(tetrahedron(), t = -0.5);

function _test_face_site(poly, face_idx) =
    ps_face_sites(poly)[face_idx];

function _test_source_counts(records, source_idx_pos, n) =
    [
        for (ei = [0:1:n-1])
            len([for (r = records) if (r[source_idx_pos] == ei) 1])
    ];

function _test_replay_kind_count(sites, kind) =
    len([for (s = sites) if (ps_replay_site_foreign_kind(s) == kind) 1]);

function _test_span_kind_count(sites, kind) =
    len([for (s = sites) if (s[19] == kind) 1]);

function _test_coincident_intrusion_verts_local() =
    [
        [-2, -2, 0], [2, -2, 0], [2, 2, 0], [-2, 2, 0],
        [0, -2, -1], [0, 0, 1], [0, 2, -1],
        [0, -2, -1], [0, 0, 1], [0, 2, -1]
    ];

function _test_coincident_intrusion_faces_idx() =
    [
        [0, 1, 2, 3],
        [4, 5, 6],
        [7, 8, 9]
    ];

function _test_duplicate_face_cut_verts_local() =
    [
        [-2, -2, 0], [2, -2, 0], [2, 2, 0], [-2, 2, 0],
        [-1, -1, -1], [1, -1, 1], [1, 1, 1], [-1, 1, -1]
    ];

function _test_duplicate_face_cut_faces_idx() =
    [
        [0, 1, 2, 3],
        [4, 5, 6, 7]
    ];

module test_ps_face_arrangement__7_3_15_star_has_stable_structure() {
    site = _test_face_site(_test_punch_poly(), STAR_FACE_IDX);
    arr = ps_face_arrangement(site[11]);

    assert_int_eq(len(arr[1]), 14, "star face crossing count");
    assert_int_eq(len(arr[2]), 21, "star face arrangement node count");
    assert_int_eq(len(arr[3]), 35, "star face arrangement span count");
    assert_int_eq(len(arr[4]), 16, "star face arrangement cell count");
    assert_list_eq(
        _test_source_counts(arr[3], 3, len(site[10])),
        [5, 5, 5, 5, 5, 5, 5],
        "star face split spans should distribute evenly across source edges"
    );
    assert_list_eq(
        [for (c = arr[1]) [c[0], c[2]]],
        [[0, 2], [0, 3], [0, 4], [0, 5], [1, 3], [1, 4], [1, 5], [1, 6], [2, 4], [2, 5], [2, 6], [3, 5], [3, 6], [4, 6]],
        "star face crossing source-edge pairs"
    );
}

module test_ps_face_boundary_model__7_3_15_star_has_true_nonzero_boundary() {
    site = _test_face_site(_test_punch_poly(), STAR_FACE_IDX);
    bm = ps_face_boundary_model(site[11], MODE);
    segments = ps_face_segments(site[11], MODE);

    assert_int_eq(len(bm[1]), 1, "star face nonzero filled cell count");
    assert_int_eq(len(bm[2]), 1, "star face nonzero boundary loop count");
    assert_int_eq(len(bm[3]), 14, "star face nonzero boundary span count");
    assert_list_eq(
        _test_source_counts(bm[3], 2, len(site[10])),
        [2, 2, 2, 2, 2, 2, 2],
        "star face boundary spans should distribute evenly across source edges"
    );
    assert_int_eq(len(segments), 1, "star face nonzero should produce one visible filled segment");
    assert_list_eq(
        segments[0][2],
        [0, 4, 5, 2, 3, 0, 1, 5, 6, 3, 4, 1, 2, 6],
        "star face filled segment source-edge lineage"
    );
}

module test_ps_face_boundary_span_sites__classifies_full_and_partial_source_spans() {
    place_on_faces(_test_punch_poly_angle0()) {
        if ($ps_face_idx == TRI_FACE_IDX) {
            sites = _ps_face_boundary_span_sites(
                $ps_face_pts3d_local,
                $ps_face_idx,
                $ps_poly_faces_idx,
                $ps_poly_verts_local,
                $ps_face_neighbors_idx,
                $ps_face_dihedrals,
                MODE,
                EPS
            );

            assert_int_eq(len(sites), 3, "simple triangle should expose three boundary spans");
            assert_int_eq(_test_span_kind_count(sites, "source_edge"), 3, "simple triangle spans should be full source edges");
            assert_int_eq(_test_span_kind_count(sites, "source_partial"), 0, "simple triangle should not expose partial source spans");
        }
    }

    place_on_faces(_test_punch_poly()) {
        if ($ps_face_idx == STAR_FACE_IDX) {
            sites = _ps_face_boundary_span_sites(
                $ps_face_pts3d_local,
                $ps_face_idx,
                $ps_poly_faces_idx,
                $ps_poly_verts_local,
                $ps_face_neighbors_idx,
                $ps_face_dihedrals,
                MODE,
                EPS
            );

            assert_int_eq(len(sites), 14, "star face should expose split boundary spans");
            assert_int_eq(_test_span_kind_count(sites, "source_edge"), 0, "star face should not treat split spans as full source edges");
            assert_int_eq(_test_span_kind_count(sites, "source_partial"), 14, "star face split spans should be source_partial");
        }
    }

    assert(
        _ps_seg_boundary_span_public_kind("cut", undef, undef, EPS) == "generated_cut",
        "future non-source raw spans should map to generated_cut"
    );
}

module test_ps_face_filled_boundary_source_edges__7_3_15_star_groups_surviving_spans() {
    site = _test_face_site(_test_punch_poly(), STAR_FACE_IDX);
    source_edges = ps_face_filled_boundary_source_edges(site[11], MODE);

    assert_int_eq(len(source_edges), 7, "star face should expose one filled-boundary record per source edge");
    assert_list_eq([for (e = source_edges) e[0]], [0, 1, 2, 3, 4, 5, 6], "star face source-edge ids");
    assert_list_eq([for (e = source_edges) len(e[2])], [2, 2, 2, 2, 2, 2, 2], "star face surviving span count per source edge");
    assert_list_eq(
        [for (e = source_edges) [for (span = e[2]) span[8]]],
        [[-1, -1], [-1, -1], [-1, -1], [-1, -1], [-1, -1], [-1, -1], [-1, -1]],
        "star face filled side per surviving span"
    );
    assert_near(source_edges[0][2][0][3], 0, EPS, "star face source edge 0 first span t0");
    assert_near(source_edges[0][2][0][4], 0.356896, 1e-6, "star face source edge 0 first span t1");
    assert_near(source_edges[0][2][1][3], 0.643104, 1e-6, "star face source edge 0 second span t0");
    assert_near(source_edges[0][2][1][4], 1, EPS, "star face source edge 0 second span t1");
}

module test_ps_face_geom_cut_entries__7_3_15_triangle_records_foreign_cutters() {
    site = _test_face_site(_test_punch_poly(), TRI_FACE_IDX);
    cuts = ps_face_geom_cut_entries(site[10], site[0], site[13], site[12], mode = MODE, filter_parent = true);

    assert_int_eq(len(cuts), 6, "triangle punch-through cut count");
    assert_list_eq(
        [for (c = cuts) c[1]],
        [3, 8, 9, 10, 14, 15],
        "triangle punch-through cutter face ids"
    );
    assert(
        min([for (c = cuts) c[2]]) > 90 && max([for (c = cuts) c[2]]) < 140,
        str("triangle punch-through cut dihedrals should stay in expected range: ", [for (c = cuts) c[2]])
    );
}

module test_ps_face_foreign_intrusion_records__7_3_15_triangle_wraps_exact_face_cuts() {
    site = _test_face_site(_test_punch_poly(), TRI_FACE_IDX);
    records = ps_face_foreign_intrusion_records(site[10], site[0], site[13], site[12], mode = MODE, filter_parent = true);

    assert_int_eq(len(records), 6, "triangle punch-through intrusion count");
    assert_list_eq(
        [for (r = records) ps_intrusion_kind(r)],
        ["face_plane_cut", "face_plane_cut", "face_plane_cut", "face_plane_cut", "face_plane_cut", "face_plane_cut"],
        "triangle intrusion kinds"
    );
    assert_list_eq(
        [for (r = records) ps_intrusion_target_face_idx(r)],
        [TRI_FACE_IDX, TRI_FACE_IDX, TRI_FACE_IDX, TRI_FACE_IDX, TRI_FACE_IDX, TRI_FACE_IDX],
        "triangle intrusion target face ids"
    );
    assert_list_eq(
        [for (r = records) ps_intrusion_foreign_kind(r)],
        ["face", "face", "face", "face", "face", "face"],
        "triangle intrusion foreign kinds"
    );
    assert_list_eq(
        [for (r = records) ps_intrusion_foreign_idx(r)],
        [3, 8, 9, 10, 14, 15],
        "triangle intrusion foreign face ids"
    );
    assert_list_eq(
        [for (r = records) ps_intrusion_confidence(r)],
        ["exact", "exact", "exact", "exact", "exact", "exact"],
        "triangle intrusion confidence"
    );
    assert_list_eq([for (r = records) len(ps_intrusion_segment2d_local(r))], [2, 2, 2, 2, 2, 2], "triangle intrusion segment arities");
    assert(
        min([for (r = records) ps_intrusion_dihedral(r)]) > 90 && max([for (r = records) ps_intrusion_dihedral(r)]) < 140,
        str("triangle intrusion dihedrals should stay in expected range: ", [for (r = records) ps_intrusion_dihedral(r)])
    );
}

module test_ps_face_foreign_intrusion_records__preserves_coincident_foreign_face_provenance() {
    face_pts2d = [[-2, -2], [2, -2], [2, 2], [-2, 2]];
    records = ps_face_foreign_intrusion_records(
        face_pts2d,
        0,
        _test_coincident_intrusion_faces_idx(),
        _test_coincident_intrusion_verts_local(),
        mode = MODE,
        filter_parent = true
    );

    assert_int_eq(len(records), 2, "coincident cuts from distinct foreign faces should both survive");
    assert_list_eq([for (r = records) ps_intrusion_foreign_idx(r)], [1, 2], "coincident intrusion foreign face ids");
    assert_list_eq(
        [for (r = records) ps_intrusion_segment2d_local(r)],
        [ps_intrusion_segment2d_local(records[0]), ps_intrusion_segment2d_local(records[0])],
        "coincident intrusion segments remain geometrically identical"
    );
}

module test_ps_face_foreign_face_replay_sites__7_3_15_triangle_builds_target_local_frames() {
    site = _test_face_site(_test_punch_poly(), TRI_FACE_IDX);
    replay = ps_face_foreign_face_replay_sites(site[10], site[0], site[13], site[12], site[9], mode = MODE, filter_parent = true);

    assert_int_eq(len(replay), 6, "triangle foreign face replay site count");
    assert_list_eq(
        [for (s = replay) ps_replay_site_foreign_idx(s)],
        [3, 8, 9, 10, 14, 15],
        "triangle replay foreign face ids"
    );
    assert_list_eq(
        [for (s = replay) ps_replay_site_foreign_kind(s)],
        ["face", "face", "face", "face", "face", "face"],
        "triangle replay foreign kinds"
    );
    assert_list_eq(
        [for (s = replay) len(ps_replay_site_intrusion_segment2d_local(s))],
        [2, 2, 2, 2, 2, 2],
        "triangle replay keeps target-local intrusion segment"
    );
    assert_list_eq(
        [for (s = replay) len(ps_replay_site_face_pts2d(s))],
        [3, 3, 3, 3, 3, 3],
        "triangle replay face point arities"
    );

    for (s = replay) {
        assert_near(norm(ps_replay_site_ex_local(s)), 1, EPS, "replay ex is unit");
        assert_near(norm(ps_replay_site_ey_local(s)), 1, EPS, "replay ey is unit");
        assert_near(norm(ps_replay_site_ez_local(s)), 1, EPS, "replay ez is unit");
        assert_near(v_dot(ps_replay_site_ex_local(s), ps_replay_site_ey_local(s)), 0, EPS, "replay ex/ey orthogonal");
        assert_near(v_dot(ps_replay_site_ex_local(s), ps_replay_site_ez_local(s)), 0, EPS, "replay ex/ez orthogonal");
        assert_near(v_dot(ps_replay_site_ey_local(s), ps_replay_site_ez_local(s)), 0, EPS, "replay ey/ez orthogonal");
        assert(max([for (p = ps_replay_site_face_pts3d_local(s)) abs(p[2])]) <= 1e-6, "planar replay face lies near local z=0");
    }
}

module test_ps_face_foreign_proxy_replay_sites__7_3_15_triangle_includes_edge_and_vertex_candidates() {
    site = _test_face_site(_test_punch_poly(), TRI_FACE_IDX);
    replay = ps_face_foreign_proxy_replay_sites(site[10], site[0], site[13], site[12], site[9], mode = MODE, filter_parent = true);

    assert_int_eq(_test_replay_kind_count(replay, "face"), 6, "triangle proxy replay exact face count");
    assert(_test_replay_kind_count(replay, "edge") > 0, "triangle proxy replay should include edge candidates");
    assert(_test_replay_kind_count(replay, "vertex") > 0, "triangle proxy replay should include vertex candidates");

    for (s = replay) {
        assert_near(norm(ps_replay_site_ex_local(s)), 1, EPS, "proxy replay ex is unit");
        assert_near(norm(ps_replay_site_ey_local(s)), 1, EPS, "proxy replay ey is unit");
        assert_near(norm(ps_replay_site_ez_local(s)), 1, EPS, "proxy replay ez is unit");
        if (ps_replay_site_foreign_kind(s) == "face")
            assert(ps_replay_site_intrusion_confidence(s) == "exact", "face replay confidence");
        if (ps_replay_site_foreign_kind(s) != "face")
            assert(ps_replay_site_intrusion_confidence(s) == "candidate", "edge/vertex replay confidence");
    }
}

module test_ps_face_foreign_proxy_replay_sites__5_2_15_triangle_includes_all_intruding_face_boundary_edges() {
    site = _test_face_site(_test_penta_punch_poly(), 2);
    replay = ps_face_foreign_proxy_replay_sites(site[10], site[0], site[13], site[12], site[9], mode = MODE, filter_parent = true);

    assert_int_eq(_test_replay_kind_count(replay, "face"), 3, "pentagram triangle proxy replay exact face count");
    assert_int_eq(_test_replay_kind_count(replay, "edge"), 7, "pentagram triangle proxy replay boundary edge candidate count");
    assert_int_eq(_test_replay_kind_count(replay, "vertex"), 5, "pentagram triangle proxy replay boundary vertex candidate count");
}

module test_ps_face_foreign_proxy_replay_sites__preserves_duplicate_exact_face_cut_records() {
    records = [
        ["face_plane_cut", 0, "face", 1, [[-1, -0.5], [1, -0.5]], 90, "exact"],
        ["face_plane_cut", 0, "face", 1, [[-1, 0.5], [1, 0.5]], 90, "exact"]
    ];
    replay = _ps_face_foreign_proxy_replay_sites_from_records(
        0,
        records,
        _test_duplicate_face_cut_faces_idx(),
        _test_duplicate_face_cut_verts_local(),
        [0, 0, 0]
    );
    face_sites = [for (s = replay) if (ps_replay_site_foreign_kind(s) == "face") s];

    assert_int_eq(_test_replay_kind_count(replay, "face"), 2, "duplicate exact face records should both replay");
    assert_int_eq(_test_replay_kind_count(replay, "edge"), 4, "duplicate face records should share deduped edge candidates");
    assert_int_eq(_test_replay_kind_count(replay, "vertex"), 4, "duplicate face records should share deduped vertex candidates");
    assert_list_eq(
        [for (s = face_sites) ps_replay_site_intrusion_segment2d_local(s)],
        [records[0][4], records[1][4]],
        "duplicate exact face records should preserve distinct cut segments"
    );
}

module test_ps_face_foreign_proxy_volume_groups__7_3_15_triangle_groups_exact_face_cuts() {
    site = _test_face_site(_test_punch_poly(), TRI_FACE_IDX);
    groups = ps_face_foreign_proxy_volume_groups(site[10], site[0], site[13], site[12], mode = MODE, filter_parent = true);

    assert(len(groups) > 0, "triangle proxy volume groups should be present");
    assert_list_eq(
        [for (g = groups) ps_proxy_volume_group_face_idxs(g)],
        [[3, 9, 10], [8, 14, 15]],
        "triangle proxy volume groups should split into connected foreign face groups"
    );
    assert_list_eq(
        [for (g = groups) ps_proxy_volume_group_record_idxs(g)],
        [[0, 2, 3], [1, 4, 5]],
        "triangle proxy volume groups should preserve exact record ids"
    );

    for (g = groups) {
        assert(ps_proxy_volume_group_kind(g) == "foreign_proxy_volume_group", "volume group kind");
        assert_int_eq(ps_proxy_volume_group_target_face_idx(g), TRI_FACE_IDX, "volume group target face id");
        assert(len(ps_proxy_volume_group_edge_idxs(g)) > 0, "volume group should expose source edge provenance");
        assert(len(ps_proxy_volume_group_vertex_idxs(g)) > 0, "volume group should expose source vertex provenance");
        assert(len(ps_proxy_volume_group_records(g)) == len(ps_proxy_volume_group_record_idxs(g)), "volume group record arity");
    }
}

module test_ps_face_foreign_proxy_volume_groups__preserves_duplicate_exact_face_cut_records() {
    records = [
        ["face_plane_cut", 0, "face", 1, [[-1, -0.5], [1, -0.5]], 90, "exact"],
        ["face_plane_cut", 0, "face", 1, [[-1, 0.5], [1, 0.5]], 90, "exact"]
    ];
    groups = _ps_face_foreign_proxy_volume_groups_from_records(
        0,
        records,
        _test_duplicate_face_cut_faces_idx(),
        _test_duplicate_face_cut_verts_local()
    );

    assert_int_eq(len(groups), 1, "duplicate exact records from one face should form one volume group");
    assert_list_eq(ps_proxy_volume_group_face_idxs(groups[0]), [1], "duplicate volume group face ids");
    assert_list_eq(ps_proxy_volume_group_record_idxs(groups[0]), [0, 1], "duplicate volume group should preserve both record ids");
    assert_int_eq(len(ps_proxy_volume_group_records(groups[0])), 2, "duplicate volume group should preserve both records");
    assert_int_eq(len(ps_proxy_volume_group_edge_idxs(groups[0])), 4, "duplicate volume group edge provenance");
    assert_int_eq(len(ps_proxy_volume_group_vertex_idxs(groups[0])), 4, "duplicate volume group vertex provenance");
}

module test_ps_proxy_volume_group_face_replay_sites__7_3_15_triangle_builds_renderable_units() {
    site = _test_face_site(_test_punch_poly(), TRI_FACE_IDX);
    groups = ps_face_foreign_proxy_volume_groups(site[10], site[0], site[13], site[12], mode = MODE, filter_parent = true);
    group_sites = [
        for (g = groups)
            ps_proxy_volume_group_face_replay_sites(g, site[13], site[12], site[9])
    ];

    assert_list_eq([for (sites = group_sites) len(sites)], [3, 3], "volume groups should build grouped face replay units");
    assert_list_eq(
        [for (sites = group_sites) [for (s = sites) ps_replay_site_foreign_idx(s)]],
        [[3, 9, 10], [8, 14, 15]],
        "volume group face replay units should preserve group face ids"
    );

    for (sites = group_sites)
        for (s = sites) {
            assert(ps_replay_site_foreign_kind(s) == "face", "volume group replay unit kind");
            assert(ps_replay_site_intrusion_confidence(s) == "exact", "volume group replay unit confidence");
            assert_int_eq(len(ps_replay_site_face_pts2d(s)), 3, "volume group replay unit face arity");
        }
}

module test_place_on_face_foreign_proxy_volume_groups__7_3_15_triangle_exposes_context() {
    place_on_faces(_test_punch_poly()) {
        if ($ps_face_idx == TRI_FACE_IDX) {
            place_on_face_foreign_proxy_volume_groups(mode = MODE) {
                assert($ps_proxy_volume_group_count > 0, "volume-group iterator count");
                assert($ps_proxy_volume_group_idx >= 0 && $ps_proxy_volume_group_idx < $ps_proxy_volume_group_count, "volume-group iterator idx bounds");
                assert($ps_proxy_volume_group_kind == "foreign_proxy_volume_group", "volume-group iterator kind");
                assert_int_eq($ps_proxy_volume_group_target_face_idx, TRI_FACE_IDX, "volume-group iterator target face id");
                assert($ps_proxy_kind == "foreign_volume_group", "volume-group proxy kind alias");
                assert($ps_proxy_source_kind == "volume_group", "volume-group proxy source-kind alias");
                assert_int_eq($ps_proxy_source_idx, $ps_proxy_volume_group_idx, "volume-group proxy source index alias");
                assert(len($ps_proxy_volume_group_face_idxs) > 0, "volume-group face ids");
                assert(len($ps_proxy_volume_group_records) == len($ps_proxy_volume_group_record_idxs), "volume-group record ids");
                assert(len($ps_proxy_volume_group_edge_idxs) > 0, "volume-group edge provenance");
                assert(len($ps_proxy_volume_group_vertex_idxs) > 0, "volume-group vertex provenance");
            }
        }
    }
}

module test_place_on_face_foreign_proxy_volume_group_faces__7_3_15_triangle_exposes_render_context() {
    place_on_faces(_test_punch_poly()) {
        if ($ps_face_idx == TRI_FACE_IDX) {
            place_on_face_foreign_proxy_volume_group_faces(mode = MODE) {
                assert_int_eq($ps_proxy_volume_group_count, 2, "volume-group face iterator group count");
                assert_int_eq($ps_proxy_volume_unit_count, 3, "volume-group face iterator unit count");
                assert($ps_proxy_volume_unit_kind == "foreign_face", "volume-group face iterator unit kind");
                assert($ps_proxy_kind == "foreign_face", "volume-group face iterator proxy kind");
                assert($ps_proxy_source_kind == "face", "volume-group face iterator source kind");
                assert($ps_proxy_intrusion_confidence == "exact", "volume-group face iterator confidence");
                assert_int_eq($ps_proxy_volume_unit_record_idx, $ps_proxy_volume_group_record_idxs[$ps_proxy_volume_unit_idx], "volume-group face iterator record id");
                assert_int_eq($ps_face_idx, $ps_proxy_source_idx, "volume-group face iterator should run in source face context");
                assert_list_eq($ps_face_pts2d, $ps_proxy_face_pts2d, "volume-group face iterator face pts alias");
                assert_int_eq(len($ps_proxy_face_pts2d), 3, "volume-group face iterator face arity");
                assert(false, "volume-group face iterator should not dispatch child slot 1");
                assert(false, "volume-group face iterator should not dispatch child slot 2");
            }
        }
    }
}

module test_place_on_face_foreign_proxy_volume_group_hulls__7_3_15_triangle_exposes_hull_context() {
    place_on_faces(_test_punch_poly()) {
        if ($ps_face_idx == TRI_FACE_IDX) {
            place_on_face_foreign_proxy_volume_group_hulls(mode = MODE, point_r = 0.01, point_fn = 4) {
                assert_int_eq($ps_proxy_volume_group_count, 2, "volume-group hull iterator group count");
                assert($ps_proxy_kind == "foreign_volume_group_hull", "volume-group hull proxy kind");
                assert($ps_proxy_source_kind == "volume_group", "volume-group hull source kind");
                assert_int_eq($ps_proxy_source_idx, $ps_proxy_volume_group_idx, "volume-group hull source index alias");
                assert_int_eq($ps_proxy_volume_hull_vertex_count, len($ps_proxy_volume_group_vertex_idxs), "volume-group hull vertex count");
                assert(_ps_list_contains($ps_proxy_volume_group_vertex_idxs, $ps_proxy_volume_hull_vertex_idx), "volume-group hull vertex id belongs to group");
                assert_list_eq(
                    $ps_proxy_volume_hull_vertex_pos_local,
                    $ps_poly_verts_local[$ps_proxy_volume_hull_vertex_idx],
                    "volume-group hull vertex position"
                );
                sphere(r = 0.01, $fn = 4);
            }
        }
    }
}

module test_ps_face_visible_segments__7_3_15_triangle_splits_into_visible_cells() {
    site = _test_face_site(_test_punch_poly(), TRI_FACE_IDX);
    visible = ps_face_visible_segments(site[10], site[0], site[13], site[12], mode = MODE, filter_parent = true);

    assert_int_eq(len(visible), 3, "triangle punch-through visible segment count");
    assert_list_eq([for (seg = visible) len(seg[0])], [8, 3, 3], "triangle visible segment arities");
    assert_list_eq(
        [for (seg = visible) seg[3]],
        [
            ["parent", "parent", "parent", "cut", "cut", "cut", "cut", "cut"],
            ["parent", "cut", "cut"],
            ["parent", "parent", "cut"]
        ],
        "triangle visible segment edge-kind lineage"
    );
}

module test_ps_face_visible_segments__7_3_0_triangle_catches_meeting_cut_edges() {
    site = _test_face_site(_test_punch_poly_angle0(), TRI_FACE_IDX);
    cuts = ps_face_geom_cut_entries(site[10], site[0], site[13], site[12], mode = MODE, filter_parent = true);
    visible = ps_face_visible_segments(site[10], site[0], site[13], site[12], mode = MODE, filter_parent = true);

    assert_int_eq(len(cuts), 6, "angle=0 triangle punch-through cut count");
    assert_list_eq(
        [for (c = cuts) c[1]],
        [3, 8, 9, 10, 14, 15],
        "angle=0 triangle punch-through cutter face ids"
    );
    assert_int_eq(len(visible), 5, "angle=0 triangle should split into five visible cells");
    assert_list_eq([for (seg = visible) len(seg[0])], [4, 3, 3, 3, 3], "angle=0 triangle visible segment arities");
    assert_list_eq(
        [for (seg = visible) seg[3]],
        [
            ["parent", "parent", "cut", "cut"],
            ["cut", "parent", "cut"],
            ["parent", "cut", "cut"],
            ["parent", "parent", "cut"],
            ["cut", "parent", "parent"]
        ],
        "angle=0 triangle visible segment edge-kind lineage"
    );
}

module test_ps_face_filled_boundary_source_edges__7_3_0_triangle_is_simple_boundary() {
    site = _test_face_site(_test_punch_poly_angle0(), TRI_FACE_IDX);
    source_edges = ps_face_filled_boundary_source_edges(site[11], MODE);

    assert_int_eq(len(source_edges), 3, "simple triangle should expose three filled-boundary source edges");
    assert_list_eq([for (e = source_edges) e[0]], [0, 1, 2], "simple triangle source-edge ids");
    assert_list_eq([for (e = source_edges) len(e[2])], [1, 1, 1], "simple triangle surviving span count per source edge");
    assert_list_eq(
        [for (e = source_edges) [for (span = e[2]) span[8]]],
        [[-1], [-1], [-1]],
        "simple triangle filled side per source edge"
    );
    assert_list_eq(
        [for (e = source_edges) [for (span = e[2]) [span[3], span[4]]]],
        [[[0, 1]], [[0, 1]], [[0, 1]]],
        "simple triangle boundary span ranges are oriented to boundary traversal"
    );
}

module test_place_on_face_filled_boundary_source_edges__7_3_15_star_exposes_context() {
    place_on_faces(_test_punch_poly()) {
        if ($ps_face_idx == STAR_FACE_IDX) {
            place_on_face_filled_boundary_source_edges(MODE) {
                assert_int_eq($ps_boundary_source_edge_count, 7, "placed source-edge record count");
                assert_int_eq($ps_boundary_source_edge_span_count, 2, "placed source-edge span count");
                assert(
                    $ps_boundary_source_edge_idx >= 0 && $ps_boundary_source_edge_idx < 7,
                    str("placed source-edge idx in range: ", $ps_boundary_source_edge_idx)
                );
                assert_int_eq(
                    len($ps_boundary_source_edge_boundary_span_idxs),
                    $ps_boundary_source_edge_span_count,
                    "placed source-edge boundary-span id arity"
                );
                assert_int_eq(
                    len($ps_boundary_source_edge_sides),
                    $ps_boundary_source_edge_span_count,
                    "placed source-edge filled-side arity"
                );
                assert_int_eq(
                    $ps_boundary_source_edge_frame_side,
                    -1,
                    "placed source-edge frame normalizes filled side to local right"
                );
                assert_int_eq(
                    len($ps_boundary_source_edge_span_t_ranges_local),
                    $ps_boundary_source_edge_span_count,
                    "placed source-edge frame-local t-range arity"
                );
                assert_int_eq(
                    len($ps_boundary_source_edge_span_sides_local),
                    $ps_boundary_source_edge_span_count,
                    "placed source-edge frame-local filled-side arity"
                );
            }
        }
    }
}

module test_place_on_face_filled_boundary_source_edges__antitet_uses_span_direction() {
    place_on_faces(_test_antitet_poly()) {
        if ($ps_face_idx == ANTI_FACE_IDX) {
            place_on_face_filled_boundary_source_edges(MODE) {
                if ($ps_boundary_source_edge_idx == 1) {
                    assert_list_eq(
                        $ps_boundary_source_edge_span_sides_local,
                        [-1, 1, 1],
                        "antitet long source edge has middle/end spans on opposite frame sides"
                    );
                }
                if ($ps_boundary_source_edge_idx == 0) {
                    assert_list_eq(
                        $ps_boundary_source_edge_span_sides_local,
                        [-1],
                        "antitet short end source edge normalizes from source-param direction"
                    );
                }
            }
        }
    }
}

module test_place_on_face_foreign_intrusions__7_3_15_triangle_exposes_context() {
    place_on_faces(_test_punch_poly()) {
        if ($ps_face_idx == TRI_FACE_IDX) {
            place_on_face_foreign_intrusions(mode = MODE) {
                assert_int_eq($ps_intrusion_count, 6, "triangle intrusion iterator count");
                assert($ps_intrusion_idx >= 0 && $ps_intrusion_idx < $ps_intrusion_count, "triangle intrusion iterator idx bounds");
                assert_int_eq($ps_intrusion_target_face_idx, TRI_FACE_IDX, "triangle intrusion iterator target face id");
                assert($ps_intrusion_kind == "face_plane_cut", "triangle intrusion iterator kind");
                assert($ps_intrusion_foreign_kind == "face", "triangle intrusion iterator foreign kind");
                assert($ps_intrusion_confidence == "exact", "triangle intrusion iterator confidence");
                assert_int_eq(len($ps_intrusion_segment2d_local), 2, "triangle intrusion iterator segment arity");
            }
        }
    }
}

module test_ps_face_seam_segment_sites__triangle_builds_boundary_edge_records() {
    place_on_faces(_test_punch_poly_angle0()) {
        if ($ps_face_idx == TRI_FACE_IDX) {
            sites = ps_face_seam_segment_sites(
                $ps_face_pts3d_local,
                $ps_face_pts2d,
                $ps_face_idx,
                $ps_poly_faces_idx,
                $ps_poly_verts_local,
                $ps_face_neighbors_idx,
                $ps_face_dihedrals,
                $ps_poly_center_local,
                MODE,
                EPS,
                "source_edge",
                true,
                false
            );

            assert_int_eq(len(sites), 3, "triangle source-edge seam site count");
            for (site = sites) {
                assert(ps_seam_site_source(site) == "boundary", "boundary seam site source");
                assert(ps_seam_site_source_kind(site) == "source_edge", "boundary seam site kind");
                assert_int_eq(len(ps_seam_site_edge_pts_local(site)), 2, "boundary seam edge point arity");
                assert_int_eq(len(ps_seam_site_current_normal_seam_local(site)), 3, "boundary seam current normal arity");
                assert_near(norm(ps_seam_site_ex_local(site)), 1, EPS, "boundary seam ex unit");
                assert_near(norm(ps_seam_site_ey_local(site)), 1, EPS, "boundary seam ey unit");
                assert_near(norm(ps_seam_site_ez_local(site)), 1, EPS, "boundary seam ez unit");
                assert_near(norm(ps_seam_site_current_normal_seam_local(site)), 1, EPS, "boundary seam current normal unit");
                assert_near(v_dot(ps_seam_site_ex_local(site), ps_seam_site_ey_local(site)), 0, EPS, "boundary seam ex/ey orthogonal");
                assert_near(v_dot(ps_seam_site_ex_local(site), ps_seam_site_ez_local(site)), 0, EPS, "boundary seam ex/ez orthogonal");
                assert(ps_seam_site_len(site) > EPS, "boundary seam length positive");
            }
        }
    }
}

module test_place_on_face_seam_segments__triangle_exposes_foreign_edge_aliases() {
    place_on_faces(_test_punch_poly()) {
        if ($ps_face_idx == TRI_FACE_IDX) {
            records = ps_face_foreign_intrusion_records($ps_face_pts2d, $ps_face_idx, $ps_poly_faces_idx, $ps_poly_verts_local, EPS, MODE, true);
            first_foreign = ps_intrusion_foreign_idx(records[0]);
            expected_count = len([for (r = records) if (ps_intrusion_foreign_idx(r) == first_foreign) 1]);

            place_on_face_seam_segments(
                mode = MODE,
                eps = EPS,
                coords = "parent",
                include_boundary = false,
                include_foreign = true,
                foreign_indices = first_foreign
            ) {
                assert_int_eq($ps_seam_count, expected_count, "filtered foreign seam count");
                assert_int_eq($ps_seam_foreign_idx, first_foreign, "filtered foreign seam idx");
                assert($ps_seam_source == "foreign", "foreign seam source");
                assert($ps_seam_source_kind == "face_plane_cut", "foreign seam source kind");
                assert($ps_seam_confidence == "exact", "foreign seam confidence");
                assert_int_eq(len($ps_seam_current_normal_seam_local), 3, "foreign seam current normal arity");
                assert_near(norm($ps_seam_current_normal_seam_local), 1, EPS, "foreign seam current normal unit");
                assert_list_eq($ps_edge_pts_local, $ps_seam_edge_pts_local, "foreign seam edge alias points");
                assert_near($ps_edge_len, $ps_seam_len, EPS, "foreign seam edge alias len");
                assert_int_eq(len($ps_edge_adj_faces_idx), 2, "foreign seam edge adjacent-face alias arity");
            }
        }
    }
}

module test_ps_face_seam_segment_sites__source_partial_spans_are_not_support_candidates() {
    place_on_faces(_test_punch_poly()) {
        if ($ps_face_idx == STAR_FACE_IDX) {
            sites = ps_face_seam_segment_sites(
                $ps_face_pts3d_local,
                $ps_face_pts2d,
                $ps_face_idx,
                $ps_poly_faces_idx,
                $ps_poly_verts_local,
                $ps_face_neighbors_idx,
                $ps_face_dihedrals,
                $ps_poly_center_local,
                MODE,
                EPS,
                "generated",
                true,
                false
            );
            support_sites = [for (site = sites) if (ps_seam_site_is_support_candidate(site)) site];

            assert_int_eq(len(sites), 14, "star generated seam site count includes source_partial spans");
            assert_int_eq(len(support_sites), 0, "source_partial star spans are not printable support candidates");
        }
    }
}

module test_ps_face_seam_segment_sites__5_2_triangle_cuts_are_support_candidates() {
    place_on_faces(poly_antiprism(5, 2, angle = 0)) {
        if ($ps_face_idx == 7) {
            sites = ps_face_seam_segment_sites(
                $ps_face_pts3d_local,
                $ps_face_pts2d,
                $ps_face_idx,
                $ps_poly_faces_idx,
                $ps_poly_verts_local,
                $ps_face_neighbors_idx,
                $ps_face_dihedrals,
                $ps_poly_center_local,
                MODE,
                EPS,
                "generated_cut",
                false,
                true
            );
            support_sites = [for (site = sites) if (ps_seam_site_is_support_candidate(site)) site];

            assert_int_eq(len(sites), 3, "5/2 triangle exact foreign seam count");
            assert_int_eq(len(support_sites), 3, "5/2 triangle exact foreign seams classify as printable supports");
            for (site = support_sites) {
                assert(ps_seam_site_support_kind(site) == "foreign_simple_face_cut", "5/2 support kind");
                assert(ps_seam_site_support_reason(site) == "simple_face_cut", "5/2 support reason");
                assert_int_eq(len(ps_seam_site_foreign_normal_local(site)), 3, "5/2 support foreign normal arity");
            }
        }
    }
}

module test_place_on_face_foreign_face_replay_sites__7_3_15_triangle_exposes_context() {
    place_on_faces(_test_punch_poly()) {
        if ($ps_face_idx == TRI_FACE_IDX) {
            place_on_face_foreign_face_replay_sites(mode = MODE, coords = "parent") {
                assert_int_eq($ps_replay_count, 6, "triangle replay iterator count");
                assert($ps_replay_idx >= 0 && $ps_replay_idx < $ps_replay_count, "triangle replay iterator idx bounds");
                assert($ps_replay_kind == "foreign_face", "triangle replay iterator kind");
                assert($ps_replay_foreign_kind == "face", "triangle replay iterator foreign kind");
                assert($ps_replay_intrusion_confidence == "exact", "triangle replay iterator confidence");
                assert_int_eq(len($ps_replay_intrusion_segment2d_local), 2, "triangle replay intrusion segment arity");
                assert_int_eq(len($ps_replay_face_pts2d), 3, "triangle replay face point arity");
                assert_near(norm($ps_replay_ex_local), 1, EPS, "triangle replay ex unit");
                assert_near(norm($ps_replay_ey_local), 1, EPS, "triangle replay ey unit");
                assert_near(norm($ps_replay_ez_local), 1, EPS, "triangle replay ez unit");
            }
        }
    }
}

module _test_assert_triangle_proxy_face_child(expected_child_idx) {
    assert($ps_proxy_count > 6, str("triangle proxy iterator should include face plus candidates, count=", $ps_proxy_count));
    assert($ps_proxy_idx >= 0 && $ps_proxy_idx < $ps_proxy_count, "triangle proxy iterator idx bounds");
    assert($ps_proxy_kind == "foreign_face", "triangle proxy kind");
    assert($ps_proxy_source_kind == "face", "triangle proxy source kind");
    assert_int_eq($ps_proxy_child_idx, expected_child_idx, "triangle face proxy child slot");
    assert_int_eq($ps_proxy_target_face_idx, TRI_FACE_IDX, "triangle proxy target face id");
    assert_int_eq(len($ps_proxy_intrusion_segment2d_local), 2, "triangle proxy intrusion segment arity");
    assert($ps_proxy_intrusion_confidence == "exact", "triangle proxy intrusion confidence");
    assert_int_eq(len($ps_proxy_face_pts2d), 3, "triangle proxy face point arity");
    assert_near(norm($ps_proxy_ex_local), 1, EPS, "triangle proxy ex unit");
    assert_near(norm($ps_proxy_ey_local), 1, EPS, "triangle proxy ey unit");
    assert_near(norm($ps_proxy_ez_local), 1, EPS, "triangle proxy ez unit");
}

module _test_assert_triangle_proxy_edge_child(expected_child_idx) {
    assert($ps_proxy_idx >= 0 && $ps_proxy_idx < $ps_proxy_count, "triangle edge proxy idx bounds");
    assert($ps_proxy_kind == "foreign_edge", "triangle edge proxy kind");
    assert($ps_proxy_source_kind == "edge", "triangle edge proxy source kind");
    assert_int_eq($ps_proxy_child_idx, expected_child_idx, "triangle edge proxy child slot");
    assert_int_eq($ps_proxy_target_face_idx, TRI_FACE_IDX, "triangle edge proxy target face id");
    assert($ps_proxy_intrusion_confidence == "candidate", "triangle edge proxy confidence");
    assert_int_eq($ps_edge_idx, $ps_proxy_source_idx, "triangle edge proxy child edge id");
    assert_list_eq($ps_edge_pts_local, $ps_proxy_edge_pts_local, "triangle edge proxy child edge points");
    assert_list_eq($ps_edge_verts_idx, $ps_proxy_edge_verts_idx, "triangle edge proxy child edge vertices");
    assert_near(norm($ps_proxy_ex_local), 1, EPS, "triangle edge proxy ex unit");
    assert_near(norm($ps_proxy_ey_local), 1, EPS, "triangle edge proxy ey unit");
    assert_near(norm($ps_proxy_ez_local), 1, EPS, "triangle edge proxy ez unit");
}

module _test_assert_triangle_proxy_vertex_child(expected_child_idx) {
    assert($ps_proxy_idx >= 0 && $ps_proxy_idx < $ps_proxy_count, "triangle vertex proxy idx bounds");
    assert($ps_proxy_kind == "foreign_vertex", "triangle vertex proxy kind");
    assert($ps_proxy_source_kind == "vertex", "triangle vertex proxy source kind");
    assert_int_eq($ps_proxy_child_idx, expected_child_idx, "triangle vertex proxy child slot");
    assert_int_eq($ps_proxy_target_face_idx, TRI_FACE_IDX, "triangle vertex proxy target face id");
    assert($ps_proxy_intrusion_confidence == "candidate", "triangle vertex proxy confidence");
    assert_int_eq($ps_vertex_idx, $ps_proxy_source_idx, "triangle vertex proxy child vertex id");
    assert_int_eq($ps_vertex_valence, $ps_proxy_vertex_valence, "triangle vertex proxy child valence");
    assert_list_eq($ps_vertex_neighbors_idx, $ps_proxy_vertex_neighbors_idx, "triangle vertex proxy child neighbors");
    assert_near(norm($ps_proxy_ex_local), 1, EPS, "triangle vertex proxy ex unit");
    assert_near(norm($ps_proxy_ey_local), 1, EPS, "triangle vertex proxy ey unit");
    assert_near(norm($ps_proxy_ez_local), 1, EPS, "triangle vertex proxy ez unit");
}

module _test_assert_triangle_proxy_face_child_element_context(expected_child_idx) {
    _test_assert_triangle_proxy_face_child(expected_child_idx);

    assert_int_eq($ps_face_idx, $ps_proxy_source_idx, "triangle proxy child face id should be foreign face id");
    assert_int_eq(len($ps_face_pts2d), len($ps_proxy_face_pts2d), "triangle proxy child face point arity");
    assert_list_eq($ps_face_pts2d, $ps_proxy_face_pts2d, "triangle proxy child face points should match proxy face points");
    assert_list_eq($ps_face_pts3d_local, $ps_proxy_face_pts3d_local, "triangle proxy child local 3d face points should match proxy face points");
    assert_list_eq($ps_poly_faces_idx[$ps_face_idx], $ps_proxy_face_verts_idx, "triangle proxy child face vertex ids should match proxy source face");
    assert_int_eq(len($ps_face_neighbors_idx), len($ps_face_pts2d), "triangle proxy child neighbor arity");
    assert_int_eq(len($ps_face_dihedrals), len($ps_face_pts2d), "triangle proxy child dihedral arity");
}

module test_place_on_face_foreign_proxy_sites__7_3_15_triangle_dispatches_face_child() {
    place_on_faces(_test_punch_poly()) {
        if ($ps_face_idx == TRI_FACE_IDX) {
            place_on_face_foreign_proxy_sites(mode = MODE, coords = "parent") {
                _test_assert_triangle_proxy_face_child(0);
            }

            place_on_face_foreign_proxy_sites(mode = MODE, coords = "parent", face_child = 1, edge_child = 0, vertex_child = 2) {
                assert($ps_proxy_source_kind == "edge", "remapped child 0 should receive edge proxies");
                _test_assert_triangle_proxy_face_child(1);
                assert($ps_proxy_source_kind == "vertex", "remapped child 2 should receive vertex proxies");
            }
        }
    }
}

module test_place_on_face_foreign_proxy_sites__7_3_15_triangle_element_child_uses_source_face_context() {
    place_on_faces(_test_punch_poly()) {
        if ($ps_face_idx == TRI_FACE_IDX) {
            place_on_face_foreign_proxy_sites(mode = MODE) {
                _test_assert_triangle_proxy_face_child_element_context(0);
            }
        }
    }
}

module test_place_on_face_foreign_proxy_sites__7_3_15_triangle_dispatches_edge_and_vertex_children() {
    place_on_faces(_test_punch_poly()) {
        if ($ps_face_idx == TRI_FACE_IDX) {
            place_on_face_foreign_proxy_sites(mode = MODE) {
                _test_assert_triangle_proxy_face_child_element_context(0);
                _test_assert_triangle_proxy_edge_child(1);
                _test_assert_triangle_proxy_vertex_child(2);
            }
        }
    }
}

module test_face_local_iterators__parent_coords_preserve_metadata() {
    place_on_faces(_test_punch_poly()) {
        if ($ps_face_idx == STAR_FACE_IDX) {
            place_on_face_filled_boundary_source_edges(mode = MODE, coords = "parent") {
                assert_int_eq($ps_boundary_source_edge_count, 7, "parent-coords source-edge record count");
                assert_int_eq(len($ps_boundary_source_edge_segment2d_local), 2, "parent-coords source edge segment arity");
                assert_int_eq(
                    len($ps_boundary_source_edge_span_segments2d_local),
                    $ps_boundary_source_edge_span_count,
                    "parent-coords source-edge span segment arity"
                );
            }

            place_on_face_boundary_spans(mode = MODE, coords = "parent") {
                assert($ps_boundary_span_count > 0, "parent-coords boundary span count");
                assert_int_eq(len($ps_boundary_span_segment2d_local), 2, "parent-coords boundary span segment arity");
            }
        }
    }
}

module test_place_on_face_boundary_spans__kind_filter_exposes_generated_seams() {
    place_on_faces(_test_punch_poly()) {
        if ($ps_face_idx == STAR_FACE_IDX) {
            place_on_face_boundary_spans(mode = MODE, kind = "generated") {
                assert_int_eq($ps_boundary_span_count, 14, "generated filter should keep all split star spans");
                assert_int_eq($ps_boundary_span_total_count, 14, "generated filter total count");
                assert($ps_boundary_span_kind == "source_partial", "generated star seam should be source_partial");
                assert($ps_boundary_span_raw_kind == "source", "source_partial star seam should preserve raw source kind");
                assert($ps_boundary_span_is_generated, "source_partial spans should be generated-seam candidates");
            }
        }
    }

    place_on_faces(_test_punch_poly_angle0()) {
        if ($ps_face_idx == TRI_FACE_IDX) {
            place_on_face_boundary_spans(mode = MODE, kind = "source_edge") {
                assert_int_eq($ps_boundary_span_count, 3, "source_edge filter should keep simple triangle edges");
                assert_int_eq($ps_boundary_span_total_count, 3, "source_edge filter total count");
                assert($ps_boundary_span_kind == "source_edge", "simple triangle spans should be source_edge");
                assert(!$ps_boundary_span_is_generated, "full source edges should not be generated-seam candidates");
            }
        }
    }
}

module run_TestSelfCrossing() {
    test_ps_face_arrangement__7_3_15_star_has_stable_structure();
    test_ps_face_boundary_model__7_3_15_star_has_true_nonzero_boundary();
    test_ps_face_boundary_span_sites__classifies_full_and_partial_source_spans();
    test_ps_face_filled_boundary_source_edges__7_3_15_star_groups_surviving_spans();
    test_ps_face_geom_cut_entries__7_3_15_triangle_records_foreign_cutters();
    test_ps_face_foreign_intrusion_records__7_3_15_triangle_wraps_exact_face_cuts();
    test_ps_face_foreign_intrusion_records__preserves_coincident_foreign_face_provenance();
    test_ps_face_foreign_face_replay_sites__7_3_15_triangle_builds_target_local_frames();
    test_ps_face_foreign_proxy_replay_sites__7_3_15_triangle_includes_edge_and_vertex_candidates();
    test_ps_face_foreign_proxy_replay_sites__5_2_15_triangle_includes_all_intruding_face_boundary_edges();
    test_ps_face_foreign_proxy_replay_sites__preserves_duplicate_exact_face_cut_records();
    test_ps_face_foreign_proxy_volume_groups__7_3_15_triangle_groups_exact_face_cuts();
    test_ps_face_foreign_proxy_volume_groups__preserves_duplicate_exact_face_cut_records();
    test_ps_proxy_volume_group_face_replay_sites__7_3_15_triangle_builds_renderable_units();
    test_ps_face_visible_segments__7_3_15_triangle_splits_into_visible_cells();
    test_ps_face_visible_segments__7_3_0_triangle_catches_meeting_cut_edges();
    test_ps_face_filled_boundary_source_edges__7_3_0_triangle_is_simple_boundary();
    test_place_on_face_filled_boundary_source_edges__7_3_15_star_exposes_context();
    test_place_on_face_filled_boundary_source_edges__antitet_uses_span_direction();
    test_place_on_face_boundary_spans__kind_filter_exposes_generated_seams();
    test_place_on_face_foreign_intrusions__7_3_15_triangle_exposes_context();
    test_ps_face_seam_segment_sites__triangle_builds_boundary_edge_records();
    test_place_on_face_seam_segments__triangle_exposes_foreign_edge_aliases();
    test_ps_face_seam_segment_sites__source_partial_spans_are_not_support_candidates();
    test_ps_face_seam_segment_sites__5_2_triangle_cuts_are_support_candidates();
    test_place_on_face_foreign_face_replay_sites__7_3_15_triangle_exposes_context();
    test_place_on_face_foreign_proxy_sites__7_3_15_triangle_dispatches_face_child();
    test_place_on_face_foreign_proxy_sites__7_3_15_triangle_element_child_uses_source_face_context();
    test_place_on_face_foreign_proxy_sites__7_3_15_triangle_dispatches_edge_and_vertex_children();
    test_place_on_face_foreign_proxy_volume_groups__7_3_15_triangle_exposes_context();
    test_place_on_face_foreign_proxy_volume_group_faces__7_3_15_triangle_exposes_render_context();
    test_place_on_face_foreign_proxy_volume_group_hulls__7_3_15_triangle_exposes_hull_context();
    test_face_local_iterators__parent_coords_preserve_metadata();
}

run_TestSelfCrossing();
