/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

use <../../polysymmetrica/core/placement.scad>
use <../../polysymmetrica/core/classify.scad>
use <../../polysymmetrica/core/construction.scad>
use <../../polysymmetrica/core/funcs.scad>
use <../../polysymmetrica/core/vertex.scad>
use <../../polysymmetrica/core/prisms.scad>
use <../../polysymmetrica/core/truncation.scad>
use <../../polysymmetrica/models/platonics_all.scad>
use <../../polysymmetrica/models/archimedians_all.scad>
use <../../polysymmetrica/models/tetrahedron.scad>

module assert_int_eq(a, b, msg="") {
    assert(a == b, str(msg, " expected=", b, " got=", a));
}

module assert_vec3_near(v, w, eps=1e-9, msg="") {
    assert(norm(v - w) <= eps, str(msg, " expected=", w, " got=", v));
}

module test_place_on_faces__family_ids_and_counts_from_classify() {
    p = rhombicuboctahedron();
    faces = poly_faces(p);
    cls = poly_classify(p, 1, 1e-6, 1, false);
    ids = ps_classify_face_ids(cls, len(faces));
    counts = ps_classify_counts(cls);

    place_on_faces(p, classify = cls) {
        assert_int_eq($ps_face_family_id, ids[$ps_face_idx], "face family id");
        assert_int_eq($ps_face_family_count, counts[0], "face family count");
        assert_int_eq($ps_edge_family_count, counts[1], "edge family count from face placement");
        assert_int_eq($ps_vertex_family_count, counts[2], "vertex family count from face placement");
    }
}

module test_place_on_edges__family_ids_and_counts_from_classify() {
    p = rhombicuboctahedron();
    faces = poly_faces(p);
    edges = _ps_edges_from_faces(faces);
    cls = poly_classify(p, 1, 1e-6, 1, false);
    ids = ps_classify_edge_ids(cls, len(edges));
    counts = ps_classify_counts(cls);

    place_on_edges(p, classify = cls) {
        assert_int_eq($ps_edge_family_id, ids[$ps_edge_idx], "edge family id");
        assert_int_eq($ps_face_family_count, counts[0], "face family count from edge placement");
        assert_int_eq($ps_edge_family_count, counts[1], "edge family count");
        assert_int_eq($ps_vertex_family_count, counts[2], "vertex family count from edge placement");
    }
}

module test_place_on_vertices__family_ids_and_counts_from_classify() {
    p = rhombicuboctahedron();
    verts = poly_verts(p);
    cls = poly_classify(p, 1, 1e-6, 1, false);
    ids = ps_classify_vert_ids(cls, len(verts));
    counts = ps_classify_counts(cls);

    place_on_vertices(p, classify = cls) {
        assert_int_eq($ps_vertex_family_id, ids[$ps_vertex_idx], "vertex family id");
        assert_int_eq($ps_face_family_count, counts[0], "face family count from vertex placement");
        assert_int_eq($ps_edge_family_count, counts[1], "edge family count from vertex placement");
        assert_int_eq($ps_vertex_family_count, counts[2], "vertex family count");
    }
}

module test_place_on_faces__auto_classify_matches_precomputed() {
    p = rhombicuboctahedron();
    faces = poly_faces(p);
    opts = [1, 1e-6, 1, false];
    cls = poly_classify(p, opts[0], opts[1], opts[2], opts[3]);
    ids = ps_classify_face_ids(cls, len(faces));

    place_on_faces(p, classify_opts = opts) {
        assert_int_eq($ps_face_family_id, ids[$ps_face_idx], "auto classify face family id");
    }
}

module test_ps_placement_frame__accessors_and_matrix_match_raw_frame() {
    center = [1, 2, 3];
    ex = [1, 0, 0];
    ey = [0, 1, 0];
    ez = [0, 0, 1];
    frame = ps_placement_frame(center, ex, ey, ez);

    assert(frame == [center, ex, ey, ez], "placement frame record layout");
    assert(ps_placement_frame_center(frame) == center, "placement frame center accessor");
    assert(ps_placement_frame_ex(frame) == ex, "placement frame ex accessor");
    assert(ps_placement_frame_ey(frame) == ey, "placement frame ey accessor");
    assert(ps_placement_frame_ez(frame) == ez, "placement frame ez accessor");
    assert(ps_placement_frame_matrix(frame) == ps_frame_matrix(center, ex, ey, ez), "placement frame matrix");
}

module test_ps_placement_frame_describe_str__summary_and_formatter() {
    frame = ps_placement_frame([1, 2, 3], [1, 0, 0], [0, 1, 0], [0, 0, 1]);
    s0 = ps_placement_frame_describe_str(frame);
    s1 = ps_placement_frame_describe_str(frame, 0, function(k, v) str("\"", k, "\":", v), " | ");

    assert(s0 == "PlacementFrame(center=[1, 2, 3], ex=[1, 0, 0], ey=[0, 1, 0], ez=[0, 0, 1])", "placement frame summary string");
    assert(s1 == "PlacementFrame(\"center\":[1, 2, 3] | \"ex\":[1, 0, 0] | \"ey\":[0, 1, 0] | \"ez\":[0, 0, 1])", "placement frame formatter override");
}

module test_ps_target_local_poly_context__accessors_and_default_center() {
    faces = [[0, 1, 2]];
    verts_local = [[0, 0, 0], [1, 0, 0], [0, 1, 0]];
    center_local = [0.2, 0.3, -1];
    ctx = ps_target_local_poly_context(faces, verts_local, center_local);
    ctx_default = ps_target_local_poly_context(faces, verts_local);

    assert(ps_target_local_poly_context_faces_idx(ctx) == faces, "target-local context faces");
    assert(ps_target_local_poly_context_verts_local(ctx) == verts_local, "target-local context vertices");
    assert(ps_target_local_poly_context_center_local(ctx) == center_local, "target-local context center");
    assert(ps_target_local_poly_context_center_local(ctx_default) == [0, 0, 0], "target-local context default center");
}

module test_ps_target_local_poly_context_describe_str__summary() {
    ctx = ps_target_local_poly_context([[0, 1, 2]], [[0, 0, 0], [1, 0, 0], [0, 1, 0]]);
    s = ps_target_local_poly_context_describe_str(ctx);
    assert(s == "TargetLocalPolyContext(face_count=1, vert_count=3, center_local=[0, 0, 0])", "target-local context summary string");
}

module test_ps_face_local_context_describe_str__summary() {
    ctx = ps_face_local_context(
        [[0, 0, 0], [1, 0, 0], [0, 1, 0]],
        [[0, 0], [1, 0], [0, 1]],
        4,
        [[0, 1, 2]],
        [[0, 0, 0], [1, 0, 0], [0, 1, 0]],
        [5, 6, 7],
        [90, 90, 90]
    );
    s = ps_face_local_context_describe_str(ctx);
    assert(s == "FaceLocalContext(face_idx=4, vertex_count=3, neighbor_count=3, dihedral_count=3)", "face-local context summary string");
}

module test_ps_face_sites__cube_records_match_face_structure() {
    p = hexahedron();
    faces = poly_faces(p);
    cls = poly_classify(p, 1, 1e-6, 1, false);
    ids = ps_classify_face_ids(cls, len(faces));
    counts = ps_classify_counts(cls);
    sites = ps_face_sites(p, classify = cls);

    assert_int_eq(len(sites), len(faces), "face site count should match face count");

    for (site = sites) {
        fi = site[0];
        face = faces[fi];

        assert_int_eq(len(site), 13, str("face site should store the compact frame/context tail fi=", fi));
        assert_int_eq(site[2], len(face), "site vertex count should match face arity");
        assert(site[11] == ps_face_site_frame(site), str("face site stored frame mismatch fi=", fi));
        assert(site[12] == ps_face_site_face_local_context(site), str("face site stored face-local context mismatch fi=", fi));
        assert(site[6], str("cube face site should be planar fi=", fi));
        assert(abs(site[5]) < 1e-9, str("cube face planarity err should be ~0 fi=", fi, " err=", site[5]));
        assert_int_eq(site[7], ids[fi], "site face family id");
        assert_int_eq(site[8], counts[0], "site face family count");
        assert_int_eq(site[9], counts[1], "site edge family count");
        assert_int_eq(site[10], counts[2], "site vertex family count");
    }
}

module test_ps_face_site_accessors__match_record_layout() {
    p = rhombicuboctahedron();
    cls = poly_classify(p, 1, 1e-6, 1, false);
    sites = ps_face_sites(p, classify = cls);

    for (site = sites) {
        face_ctx = ps_face_site_face_local_context(site);
        fields = [
            ["idx", ps_face_site_idx(site), site[0]],
            ["edge_len", ps_face_site_edge_len(site), site[1]],
            ["vertex_count", ps_face_site_vertex_count(site), site[2]],
            ["midradius", ps_face_site_midradius(site), site[3]],
            ["radius", ps_face_site_radius(site), site[4]],
            ["planarity_err", ps_face_site_planarity_err(site), site[5]],
            ["is_planar", ps_face_site_is_planar(site), site[6]],
            ["family_id", ps_face_site_family_id(site), site[7]],
            ["face_family_count", ps_face_site_face_family_count(site), site[8]],
            ["edge_family_count", ps_face_site_edge_family_count(site), site[9]],
            ["vertex_family_count", ps_face_site_vertex_family_count(site), site[10]],
            ["frame", ps_face_site_frame(site), site[11]],
            ["face_local_context", ps_face_site_face_local_context(site), site[12]],
            ["poly_center_local", ps_face_site_poly_center_local(site), ps_face_local_context_poly_center_local(face_ctx)],
            ["pts2d", ps_face_site_pts2d(site), ps_face_local_context_pts2d(face_ctx)],
            ["pts3d_local", ps_face_site_pts3d_local(site), ps_face_local_context_pts3d_local(face_ctx)],
            ["poly_verts_local", ps_face_site_poly_verts_local(site), ps_face_local_context_poly_verts_local(face_ctx)],
            ["poly_faces_idx", ps_face_site_poly_faces_idx(site), ps_face_local_context_poly_faces_idx(face_ctx)],
            ["neighbors_idx", ps_face_site_neighbors_idx(site), ps_face_local_context_neighbors_idx(face_ctx)],
            ["dihedrals", ps_face_site_dihedrals(site), ps_face_local_context_dihedrals(face_ctx)]
        ];

        for (field = fields)
            assert(field[1] == field[2], str("face site accessor mismatch field=", field[0], " site=", site[0]));
    }
}

module test_ps_face_site_frame_and_context__match_site_accessors() {
    p = hexahedron();
    site = ps_face_sites(p)[0];
    frame = ps_face_site_frame(site);
    ctx = ps_face_site_target_local_poly_context(site);
    face_ctx = ps_face_site_face_local_context(site);

    assert(frame == site[11], "face site should store its frame object");
    assert(ps_placement_frame_center(frame) == ps_face_site_center(site), "face site frame center");
    assert(ps_placement_frame_ex(frame) == ps_face_site_ex(site), "face site frame ex");
    assert(ps_placement_frame_ey(frame) == ps_face_site_ey(site), "face site frame ey");
    assert(ps_placement_frame_ez(frame) == ps_face_site_ez(site), "face site frame ez");
    assert(ps_placement_frame_matrix(frame) == ps_placement_frame_matrix(site[11]), "face site frame matrix");
    assert(ps_target_local_poly_context_faces_idx(ctx) == ps_face_site_poly_faces_idx(site), "face site context faces");
    assert(ps_target_local_poly_context_verts_local(ctx) == ps_face_site_poly_verts_local(site), "face site context vertices");
    assert(ps_target_local_poly_context_center_local(ctx) == ps_face_site_poly_center_local(site), "face site context center");
    assert(face_ctx == site[12], "face site should store the face-local context object");
    assert(ps_face_local_context_pts3d_local(face_ctx) == ps_face_site_pts3d_local(site), "face site face-local context pts3d");
    assert(ps_face_local_context_pts2d(face_ctx) == ps_face_site_pts2d(site), "face site face-local context pts2d");
    assert(ps_face_local_context_idx(face_ctx) == ps_face_site_idx(site), "face site face-local context idx");
    assert(ps_face_local_context_poly_faces_idx(face_ctx) == ps_face_site_poly_faces_idx(site), "face site face-local context faces");
    assert(ps_face_local_context_poly_verts_local(face_ctx) == ps_face_site_poly_verts_local(site), "face site face-local context vertices");
    assert(ps_face_local_context_poly_center_local(face_ctx) == ps_face_site_poly_center_local(site), "face site face-local context center");
    assert(ps_face_local_context_neighbors_idx(face_ctx) == ps_face_site_neighbors_idx(site), "face site face-local context neighbors");
    assert(ps_face_local_context_dihedrals(face_ctx) == ps_face_site_dihedrals(site), "face site face-local context dihedrals");
}

module test_ps_placement_site_describe_str__detail_includes_nested_context() {
    p = hexahedron();
    face_site = ps_face_sites(p)[0];
    edge_site = ps_edge_sites(p)[0];
    vertex_site = ps_vertex_sites(p)[0];
    face_s = ps_face_site_describe_str(face_site, 1);
    edge_s = ps_edge_site_describe_str(edge_site, 1);
    vertex_s = ps_vertex_site_describe_str(vertex_site, 1);

    assert(len(search("FaceSite(", face_s)) > 0, "face site describe prefix");
    assert(len(search("face_local_context=FaceLocalContext(", face_s)) > 0, "face site detail should include nested face-local context");
    assert(len(search("EdgeSite(", edge_s)) > 0, "edge site describe prefix");
    assert(len(search("adj_faces_idx=", edge_s)) > 0, "edge site detail should include adjacent faces");
    assert(len(search("VertexSite(", vertex_s)) > 0, "vertex site describe prefix");
    assert(len(search("neighbor_pts_local=", vertex_s)) > 0, "vertex site detail should include neighbor points");
    assert(len(search("vertex_figure=", vertex_s)) > 0, "vertex site detail should include vertex figure");
}

module test_place_on_faces__exposes_stored_context_objects() {
    p = hexahedron();
    site = ps_face_sites(p)[0];

    place_on_faces(p) {
        if ($ps_face_idx == site[0]) {
            assert($ps_face_frame == ps_face_site_frame(site), "place_on_faces face frame");
            assert($ps_face_local_context == ps_face_site_face_local_context(site), "place_on_faces face-local context");
            assert($ps_target_local_poly_context == ps_face_site_target_local_poly_context(site), "place_on_faces target-local context");
        }
    }
}

module test_ps_edge_sites__cube_records_match_edge_structure() {
    p = hexahedron();
    faces = poly_faces(p);
    edges = _ps_edges_from_faces(faces);
    cls = poly_classify(p, 1, 1e-6, 1, false);
    ids = ps_classify_edge_ids(cls, len(edges));
    counts = ps_classify_counts(cls);
    sites = ps_edge_sites(p, classify = cls);

    assert_int_eq(len(sites), len(edges), "edge site count should match edge count");

    for (site = sites) {
        ei = site[0];

        assert_int_eq(len(site), 12, str("edge site should store only the compact frame tail ei=", ei));
        assert_vec3_near(site[4][0], [-site[1] / 2, 0, 0], 1e-9, "edge local start point");
        assert_vec3_near(site[4][1], [site[1] / 2, 0, 0], 1e-9, "edge local end point");
        assert_int_eq(len(site[5]), 2, "edge vertex pair should have arity 2");
        assert_int_eq(len(site[6]), 2, "cube edges should have two adjacent faces");
        assert(abs(norm(ps_edge_site_center(site)) - site[2]) < 1e-9, str("edge center/midradius mismatch ei=", ei));
        assert_int_eq(site[7], ids[ei], "site edge family id");
        assert_int_eq(site[8], counts[0], "site face family count");
        assert_int_eq(site[9], counts[1], "site edge family count");
        assert_int_eq(site[10], counts[2], "site vertex family count");
        assert(site[11] == ps_edge_site_frame(site), str("edge site stored frame mismatch ei=", ei));
    }
}

module test_ps_edge_site_accessors__match_record_layout() {
    p = rhombicuboctahedron();
    cls = poly_classify(p, 1, 1e-6, 1, false);
    sites = ps_edge_sites(p, classify = cls);

    for (site = sites) {
        fields = [
            ["idx", ps_edge_site_idx(site), site[0]],
            ["edge_len", ps_edge_site_edge_len(site), site[1]],
            ["midradius", ps_edge_site_midradius(site), site[2]],
            ["poly_center_local", ps_edge_site_poly_center_local(site), site[3]],
            ["pts_local", ps_edge_site_pts_local(site), site[4]],
            ["verts_idx", ps_edge_site_verts_idx(site), site[5]],
            ["adj_faces_idx", ps_edge_site_adj_faces_idx(site), site[6]],
            ["family_id", ps_edge_site_family_id(site), site[7]],
            ["face_family_count", ps_edge_site_face_family_count(site), site[8]],
            ["edge_family_count", ps_edge_site_edge_family_count(site), site[9]],
            ["vertex_family_count", ps_edge_site_vertex_family_count(site), site[10]],
            ["frame", ps_edge_site_frame(site), site[11]]
        ];

        for (field = fields)
            assert(field[1] == field[2], str("edge site accessor mismatch field=", field[0], " site=", site[0]));
    }
}

module test_ps_edge_site_frame__matches_site_accessors() {
    p = hexahedron();
    site = ps_edge_sites(p)[0];
    frame = ps_edge_site_frame(site);

    assert(frame == site[11], "edge site should store its frame object");
    assert(ps_placement_frame_center(frame) == ps_edge_site_center(site), "edge site frame center");
    assert(ps_placement_frame_ex(frame) == ps_edge_site_ex(site), "edge site frame ex");
    assert(ps_placement_frame_ey(frame) == ps_edge_site_ey(site), "edge site frame ey");
    assert(ps_placement_frame_ez(frame) == ps_edge_site_ez(site), "edge site frame ez");
    assert(ps_placement_frame_matrix(frame) == ps_placement_frame_matrix(site[11]), "edge site frame matrix");
}

module test_ps_edge_sites__cube_uses_adjacent_face_normal_bisector() {
    p = hexahedron();
    verts = poly_verts(p);
    faces = poly_faces(p);
    faces0 = ps_orient_all_faces_outward(verts, faces);
    edges = _ps_edges_from_faces(faces0);
    edge_faces = ps_edge_faces_table(faces0, edges);
    face_n = [for (f = faces0) ps_face_normal(verts, f)];
    sites = ps_edge_sites(p);

    for (site = sites) {
        ei = site[0];
        adj = edge_faces[ei];
        nsum = face_n[adj[0]] + face_n[adj[1]];
        expected = v_norm(nsum);
        assert(
            v_dot(ps_edge_site_ez(site), expected) > 1 - 1e-9,
            str("edge site ez should follow adjacent-face bisector ei=", ei, " got=", ps_edge_site_ez(site), " expected=", expected)
        );
    }
}

module test_ps_edge_sites__preserves_raw_edge_order_for_classify_ids() {
    p = hexahedron();
    verts = poly_verts(p);
    faces_rev = [for (f = poly_faces(p)) [for (i = [len(f)-1:-1:0]) f[i]]];
    p_rev = [verts, faces_rev, poly_e_over_ir(p)];
    raw_edges = _ps_edges_from_faces(faces_rev);
    oriented_edges = _ps_edges_from_faces(ps_orient_all_faces_outward(verts, faces_rev));
    cls = poly_classify(p_rev, 1, 1e-6, 1, false);
    ids = ps_classify_edge_ids(cls, len(raw_edges));
    sites = ps_edge_sites(p_rev, classify = cls);

    assert(raw_edges != oriented_edges, "reversed input should change raw edge ordering for this regression test");
    assert_int_eq(len(sites), len(raw_edges), "reversed poly edge site count");

    for (site = sites) {
        ei = site[0];
        assert(site[5] == raw_edges[ei], str("edge site should preserve raw edge order ei=", ei, " got=", site[5], " expected=", raw_edges[ei]));
        assert_int_eq(site[7], ids[ei], "edge family id should match raw-order classify ids");
    }
}

module test_ps_vertex_sites__cube_records_match_vertex_structure() {
    p = hexahedron();
    verts = poly_verts(p);
    cls = poly_classify(p, 1, 1e-6, 1, false);
    ids = ps_classify_vert_ids(cls, len(verts));
    counts = ps_classify_counts(cls);
    sites = ps_vertex_sites(p, classify = cls);

    assert_int_eq(len(sites), len(verts), "vertex site count should match vertex count");

    for (site = sites) {
        vi = site[0];

        assert_int_eq(len(site), 13, str("vertex site should store the compact frame and vertex-figure tail vi=", vi));
        assert_int_eq(site[4], 3, "cube vertex valence should be 3");
        assert_int_eq(len(site[5]), site[4], "neighbor index count should match valence");
        assert_int_eq(len(site[6]), site[4], "neighbor point count should match valence");
        assert(abs(norm(ps_vertex_site_center(site)) - site[2]) < 1e-9, str("vertex center/radius mismatch vi=", vi));
        assert_vec3_near(site[3], [0, 0, -site[2]], 1e-9, "vertex poly-center local");
        for (p_local = site[6])
            assert(abs(norm(p_local) - site[1]) < 1e-9, str("vertex neighbor edge length mismatch vi=", vi, " p=", p_local));
        assert_int_eq(site[7], ids[vi], "site vertex family id");
        assert_int_eq(site[8], counts[0], "site face family count");
        assert_int_eq(site[9], counts[1], "site edge family count");
        assert_int_eq(site[10], counts[2], "site vertex family count");
        assert(site[11] == ps_vertex_site_frame(site), str("vertex site stored frame mismatch vi=", vi));
        assert(site[12] == ps_vertex_site_vertex_figure(site), str("vertex site stored vertex figure mismatch vi=", vi));
        assert(!is_undef(ps_vertex_site_vertex_figure(site)), str("closed cube vertex should expose a vertex figure vi=", vi));
    }
}

module test_ps_vertex_fan__rhombicuboctahedron_neighbors_are_cyclic_and_anchored() {
    p = rhombicuboctahedron();
    faces = poly_faces(p);
    edges = _ps_edges_from_faces(faces);
    edge_faces = ps_edge_faces_table(faces, edges);

    for (vi = [0:1:len(poly_verts(p))-1]) {
        fan = ps_vertex_fan(p, vi, edges, edge_faces);
        faces_idx = ps_vertex_fan_faces_idx(fan);
        neighbors_idx = ps_vertex_fan_neighbors_idx(fan);
        edges_idx = ps_vertex_fan_edges_idx(fan);

        assert_int_eq(ps_vertex_fan_idx(fan), vi, "vertex fan source id");
        assert_int_eq(len(neighbors_idx), len(faces_idx), str("fan neighbor/face count vi=", vi));
        assert_int_eq(len(edges_idx), len(neighbors_idx), str("fan edge/neighbor count vi=", vi));
        assert_int_eq(neighbors_idx[0], min(neighbors_idx), str("fan should start at lowest neighbor id vi=", vi));

        for (i = [0:1:len(faces_idx)-1]) {
            f = faces[faces_idx[i]];
            pos = _ps_index_of(f, vi);
            expected_neighbor = f[(pos + 1) % len(f)];
            expected_edge = ps_find_edge_index(edges, vi, neighbors_idx[i]);
            assert_int_eq(neighbors_idx[i], expected_neighbor, str("fan neighbor should match cyclic face successor vi=", vi, " i=", i));
            assert_int_eq(edges_idx[i], expected_edge, str("fan edge should match fan neighbor vi=", vi, " i=", i));
        }
    }
}

module test_ps_vertex_figure__matches_fan_order() {
    p = rhombicuboctahedron();
    faces = poly_faces(p);
    edges = _ps_edges_from_faces(faces);
    edge_faces = ps_edge_faces_table(faces, edges);

    for (vi = [0:1:len(poly_verts(p))-1]) {
        fan = ps_vertex_fan(p, vi, edges, edge_faces);
        fig = ps_vertex_figure(p, vi, edges, edge_faces);

        assert_int_eq(ps_vertex_figure_idx(fig), ps_vertex_fan_idx(fan), str("vertex figure source id vi=", vi));
        assert(ps_vertex_figure_faces_idx(fig) == ps_vertex_fan_faces_idx(fan), str("vertex figure faces should match fan vi=", vi));
        assert(ps_vertex_figure_edges_idx(fig) == ps_vertex_fan_edges_idx(fan), str("vertex figure edges should match fan vi=", vi));
        assert(ps_vertex_figure_neighbors_idx(fig) == ps_vertex_fan_neighbors_idx(fan), str("vertex figure neighbors should match fan vi=", vi));
    }
}

module test_ps_vertex_sites__neighbors_match_vertex_fan_order() {
    p = rhombicuboctahedron();
    faces = poly_faces(p);
    edges = _ps_edges_from_faces(faces);
    edge_faces = ps_edge_faces_table(faces, edges);
    sites = ps_vertex_sites(p);

    for (site = sites) {
        vi = ps_vertex_site_idx(site);
        fan = ps_vertex_fan(p, vi, edges, edge_faces);
        assert(
            ps_vertex_site_neighbors_idx(site) == ps_vertex_fan_neighbors_idx(fan),
            str("vertex site should expose fan neighbor order vi=", vi, " site=", ps_vertex_site_neighbors_idx(site), " fan=", ps_vertex_fan_neighbors_idx(fan))
        );
    }
}

function _test_vertex_has_boundary_edge(edges, edge_faces, vi) =
    len([
        for (ei = [0:1:len(edges)-1])
            if ((edges[ei][0] == vi || edges[ei][1] == vi) && len(edge_faces[ei]) != 2)
                ei
    ]) > 0;

module test_ps_vertex_sites__open_construction_outputs_remain_placeable() {
    cases = [
        poly_delete_faces(hexahedron(), 0, cap=false, cleanup=false),
        poly_slice(hexahedron(), [0,0,0], [0,0,1], keep="above", cap=false)
    ];

    for (p = cases) {
        faces = poly_faces(p);
        edges = _ps_edges_from_faces(faces);
        edge_faces = ps_edge_faces_table(faces, edges);
        sites = ps_vertex_sites(p);

        assert_int_eq(len(sites), len(poly_verts(p)), "open construction output should produce one vertex site per vertex");

        for (site = sites) {
            vi = ps_vertex_site_idx(site);
            expected = !_ps_vertex_site_has_closed_fan(faces, edges, edge_faces, vi)
                ? _ps_vertex_site_neighbors_idx(edges, vi)
                : ps_vertex_fan_neighbors_idx(ps_vertex_fan(p, vi, edges, edge_faces));
            assert(
                ps_vertex_site_neighbors_idx(site) == expected,
                str("open vertex site neighbor order mismatch vi=", vi, " got=", ps_vertex_site_neighbors_idx(site), " expected=", expected)
            );
            if (!_ps_vertex_site_has_closed_fan(faces, edges, edge_faces, vi))
                assert(is_undef(ps_vertex_site_vertex_figure(site)), str("open boundary vertex should not expose a vertex figure vi=", vi));
        }
    }
}

module test_ps_vertex_sites__hypertruncated_dodecahedron_t1_singular_vertices_remain_placeable() {
    p = poly_truncate(dodecahedron(), 1);
    faces = poly_faces(p);
    verts = poly_verts(p);
    edges = _ps_edges_from_faces(faces);
    edge_faces = ps_edge_faces_table(faces, edges);
    sites = ps_vertex_sites(p);
    singular_vertices = [
        for (vi = [0:1:len(verts)-1])
            if (!_ps_vertex_site_has_closed_fan(faces, edges, edge_faces, vi))
                vi
    ];

    assert_int_eq(len(sites), len(verts), "hypertruncated dodecahedron t=1 should produce one vertex site per vertex");
    assert(len(singular_vertices) > 0, "hypertruncated dodecahedron t=1 should exercise singular vertex-site fallback");

    for (vi = singular_vertices) {
        expected = _ps_vertex_site_neighbors_idx(edges, vi);
        assert(
            ps_vertex_site_neighbors_idx(sites[vi]) == expected,
            str("singular hypertruncated vertex should use edge-scan order vi=", vi, " got=", ps_vertex_site_neighbors_idx(sites[vi]), " expected=", expected)
        );
        assert(is_undef(ps_vertex_site_vertex_figure(sites[vi])), str("singular hypertruncated vertex should not expose a vertex figure vi=", vi));
    }

    place_on_vertices(p, indices = singular_vertices[0])
        assert_int_eq($ps_vertex_valence, len(_ps_vertex_site_neighbors_idx(edges, $ps_vertex_idx)), "singular hypertruncated vertex placement valence");
}

module test_ps_vertex_site_from_local_poly__pinched_vertex_uses_edge_scan_order() {
    verts = [[1,0,0], [2,0,0], [1,1,0], [1,0,1], [0,0,0], [1,-1,0], [1,0,-1]];
    faces = [
        [0,1,2], [0,3,1], [0,2,3], [1,3,2],
        [0,5,4], [0,4,6], [0,6,5], [4,5,6]
    ];
    edges = _ps_edges_from_faces(faces);
    edge_faces = ps_edge_faces_table(faces, edges);
    site = _ps_vertex_site_from_local_poly(0, faces, verts);
    expected = _ps_vertex_site_neighbors_idx(edges, 0);

    assert(!_ps_vertex_site_has_closed_fan(faces, edges, edge_faces, 0), "pinched vertex should not be classified as a simple closed fan");
    assert(
        ps_vertex_site_neighbors_idx(site) == expected,
        str("pinched local vertex site should use edge-scan order got=", ps_vertex_site_neighbors_idx(site), " expected=", expected)
    );
    assert(is_undef(ps_vertex_site_vertex_figure(site)), "pinched local vertex site should not expose a vertex figure");
}

module test_ps_vertex_site_from_local_poly__closed_ring_uses_fan_order() {
    p = hexahedron();
    faces = poly_faces(p);
    verts = poly_verts(p);
    edges = _ps_edges_from_faces(faces);
    edge_faces = ps_edge_faces_table(faces, edges);

    for (vi = [0:1:len(verts)-1]) {
        site = _ps_vertex_site_from_local_poly(vi, faces, verts);
        expected = ps_vertex_fan_neighbors_idx(ps_vertex_fan(p, vi, edges, edge_faces));
        assert(
            ps_vertex_site_neighbors_idx(site) == expected,
            str("closed local vertex site should expose fan order vi=", vi, " got=", ps_vertex_site_neighbors_idx(site), " expected=", expected)
        );
        assert(
            ps_vertex_figure_neighbors_idx(ps_vertex_site_vertex_figure(site)) == expected,
            str("closed local vertex site should expose vertex figure vi=", vi)
        );
    }
}

module test_ps_vertex_site_from_local_poly__does_not_rebuild_local_poly() {
    // Edge [0, 1] has midpoint at the edge-midpoint center, so poly_make(...)
    // would reject these replay-local coordinates before fan traversal.
    verts = [[1,0,0], [-1,0,0], [0,1,0], [0,-1,0]];
    faces = [[0,1,2], [0,3,1], [0,2,3], [1,3,2]];
    raw_poly = [verts, faces, 1];
    edges = _ps_edges_from_faces(faces);
    edge_faces = ps_edge_faces_table(faces, edges);
    site = _ps_vertex_site_from_local_poly(0, faces, verts);
    expected = ps_vertex_fan_neighbors_idx(ps_vertex_fan(raw_poly, 0, edges, edge_faces));

    assert(
        ps_vertex_site_neighbors_idx(site) == expected,
        str("local vertex site should not rebuild/recenter replay-local poly got=", ps_vertex_site_neighbors_idx(site), " expected=", expected)
    );
    assert(ps_vertex_figure_neighbors_idx(ps_vertex_site_vertex_figure(site)) == expected, "local vertex figure should use raw descriptor fan order");
}

module test_ps_vertex_site_from_local_poly__open_ring_uses_edge_scan_order() {
    p = poly_delete_faces(hexahedron(), 0, cap=false, cleanup=false);
    faces = poly_faces(p);
    verts = poly_verts(p);
    edges = _ps_edges_from_faces(faces);
    edge_faces = ps_edge_faces_table(faces, edges);

    for (vi = [0:1:len(verts)-1]) {
        if (_test_vertex_has_boundary_edge(edges, edge_faces, vi)) {
            site = _ps_vertex_site_from_local_poly(vi, faces, verts);
            expected = _ps_vertex_site_neighbors_idx(edges, vi);
            assert(
                ps_vertex_site_neighbors_idx(site) == expected,
                str("open local vertex site should expose edge-scan order vi=", vi, " got=", ps_vertex_site_neighbors_idx(site), " expected=", expected)
            );
            assert(is_undef(ps_vertex_site_vertex_figure(site)), str("open local vertex site should not expose a vertex figure vi=", vi));
        }
    }
}

module test_ps_vertex_site_accessors__match_record_layout() {
    p = rhombicuboctahedron();
    cls = poly_classify(p, 1, 1e-6, 1, false);
    sites = ps_vertex_sites(p, classify = cls);

    for (site = sites) {
        fields = [
            ["idx", ps_vertex_site_idx(site), site[0]],
            ["edge_len", ps_vertex_site_edge_len(site), site[1]],
            ["radius", ps_vertex_site_radius(site), site[2]],
            ["poly_center_local", ps_vertex_site_poly_center_local(site), site[3]],
            ["valence", ps_vertex_site_valence(site), site[4]],
            ["neighbors_idx", ps_vertex_site_neighbors_idx(site), site[5]],
            ["neighbor_pts_local", ps_vertex_site_neighbor_pts_local(site), site[6]],
            ["family_id", ps_vertex_site_family_id(site), site[7]],
            ["face_family_count", ps_vertex_site_face_family_count(site), site[8]],
            ["edge_family_count", ps_vertex_site_edge_family_count(site), site[9]],
            ["vertex_family_count", ps_vertex_site_vertex_family_count(site), site[10]],
            ["frame", ps_vertex_site_frame(site), site[11]],
            ["vertex_figure", ps_vertex_site_vertex_figure(site), site[12]]
        ];

        for (field = fields)
            assert(field[1] == field[2], str("vertex site accessor mismatch field=", field[0], " site=", site[0]));
    }
}

module test_ps_vertex_site_frame__matches_site_accessors() {
    p = hexahedron();
    site = ps_vertex_sites(p)[0];
    frame = ps_vertex_site_frame(site);

    assert(frame == site[11], "vertex site should store its frame object");
    assert(ps_placement_frame_center(frame) == ps_vertex_site_center(site), "vertex site frame center");
    assert(ps_placement_frame_ex(frame) == ps_vertex_site_ex(site), "vertex site frame ex");
    assert(ps_placement_frame_ey(frame) == ps_vertex_site_ey(site), "vertex site frame ey");
    assert(ps_placement_frame_ez(frame) == ps_vertex_site_ez(site), "vertex site frame ez");
    assert(ps_placement_frame_matrix(frame) == ps_placement_frame_matrix(site[11]), "vertex site frame matrix");
}

module test_ps_vertex_sites__truncated_tetrahedron_frames_are_orthonormal() {
    sites = ps_vertex_sites(truncated_tetrahedron());

    for (site = sites) {
        vi = ps_vertex_site_idx(site);
        ex = ps_vertex_site_ex(site);
        ey = ps_vertex_site_ey(site);
        ez = ps_vertex_site_ez(site);

        assert(abs(norm(ex) - 1) < 1e-9, str("truncated tetra vertex frame ex unit vi=", vi, " ex=", ex));
        assert(abs(norm(ey) - 1) < 1e-9, str("truncated tetra vertex frame ey unit vi=", vi, " ey=", ey));
        assert(abs(norm(ez) - 1) < 1e-9, str("truncated tetra vertex frame ez unit vi=", vi, " ez=", ez));
        assert(abs(v_dot(ex, ey)) < 1e-9, str("truncated tetra vertex frame ex/ey orthogonal vi=", vi, " ex=", ex, " ey=", ey));
        assert(abs(v_dot(ex, ez)) < 1e-9, str("truncated tetra vertex frame ex/ez orthogonal vi=", vi, " ex=", ex, " ez=", ez));
        assert(abs(v_dot(ey, ez)) < 1e-9, str("truncated tetra vertex frame ey/ez orthogonal vi=", vi, " ey=", ey, " ez=", ez));
    }
}

module test_place_on_all__cube_single_family() {
    p = hexahedron();
    cls = poly_classify(p, 1, 1e-6, 1, false);
    counts = ps_classify_counts(cls);
    assert_int_eq(counts[0], 1, "cube face families");
    assert_int_eq(counts[1], 1, "cube edge families");
    assert_int_eq(counts[2], 1, "cube vertex families");

    place_on_faces(p, classify = cls) {
        assert_int_eq($ps_face_family_id, 0, "cube face family id");
        assert_int_eq($ps_face_family_count, 1, "cube face family count");
    }
    place_on_edges(p, classify = cls) {
        assert_int_eq($ps_edge_family_id, 0, "cube edge family id");
        assert_int_eq($ps_edge_family_count, 1, "cube edge family count");
    }
    place_on_vertices(p, classify = cls) {
        assert_int_eq($ps_vertex_family_id, 0, "cube vertex family id");
        assert_int_eq($ps_vertex_family_count, 1, "cube vertex family count");
    }
}

module test_place_on_faces_edges_vertices__expose_stored_frame_objects() {
    p = hexahedron();
    face_site = ps_face_sites(p)[0];
    edge_site = ps_edge_sites(p)[0];
    vertex_site = ps_vertex_sites(p)[0];

    place_on_faces(p, indices = 0) {
        assert($ps_face_frame == ps_face_site_frame(face_site), "face placement should expose stored frame object");
    }

    place_on_edges(p, indices = 0) {
        assert($ps_edge_frame == ps_edge_site_frame(edge_site), "edge placement should expose stored frame object");
    }

    place_on_vertices(p, indices = 0) {
        assert($ps_vertex_frame == ps_vertex_site_frame(vertex_site), "vertex placement should expose stored frame object");
        assert($ps_vertex_figure == ps_vertex_site_vertex_figure(vertex_site), "vertex placement should expose stored vertex figure object");
        assert($ps_vertex_figure_faces_idx == ps_vertex_figure_faces_idx($ps_vertex_figure), "vertex placement should expose figure face ids");
        assert($ps_vertex_figure_edges_idx == ps_vertex_figure_edges_idx($ps_vertex_figure), "vertex placement should expose figure edge ids");
        assert($ps_vertex_figure_neighbors_idx == ps_vertex_figure_neighbors_idx($ps_vertex_figure), "vertex placement should expose figure neighbor ids");
    }
}

module test_place_on_edges__no_auto_classify_by_default() {
    p = hexahedron();
    place_on_edges(p) {
        assert(is_undef($ps_edge_family_id), "default placement: edge family id should be undef without classify");
        assert(is_undef($ps_face_family_count), "default placement: face family count should be undef without classify");
        assert(is_undef($ps_edge_family_count), "default placement: edge family count should be undef without classify");
        assert(is_undef($ps_vertex_family_count), "default placement: vertex family count should be undef without classify");
    }
}

module test_place_on_all__indices_filter_selected_ids() {
    p = hexahedron();
    face_ids = [1, 3];
    edge_ids = [0, 5, 11];
    vertex_ids = [2, 7];

    place_on_faces(p, indices = face_ids)
        assert(_ps_list_contains(face_ids, $ps_face_idx), str("face index should be selected: ", $ps_face_idx));

    place_on_edges(p, indices = edge_ids)
        assert(_ps_list_contains(edge_ids, $ps_edge_idx), str("edge index should be selected: ", $ps_edge_idx));

    place_on_vertices(p, indices = vertex_ids)
        assert(_ps_list_contains(vertex_ids, $ps_vertex_idx), str("vertex index should be selected: ", $ps_vertex_idx));
}

module test_place_on_all__indices_accept_scalar() {
    p = hexahedron();

    place_on_faces(p, indices = 2)
        assert_int_eq($ps_face_idx, 2, "scalar face index");

    place_on_edges(p, indices = 4)
        assert_int_eq($ps_edge_idx, 4, "scalar edge index");

    place_on_vertices(p, indices = 6)
        assert_int_eq($ps_vertex_idx, 6, "scalar vertex index");
}

module test_place_on_all__empty_indices_skip_children() {
    p = hexahedron();

    place_on_faces(p, indices = [])
        assert(false, "empty face indices should skip children");

    place_on_edges(p, indices = [])
        assert(false, "empty edge indices should skip children");

    place_on_vertices(p, indices = [])
        assert(false, "empty vertex indices should skip children");
}

module test_place_on_face_segments__star_face_split() {
    p = poly_antiprism(5, 2);
    place_on_faces(p) {
        if ($ps_face_idx == 0) {
            place_on_face_segments(mode="evenodd") {
                assert(!is_undef($ps_seg_idx), "segment idx should be defined");
                assert(!is_undef($ps_seg_count), "segment count should be defined");
                assert($ps_seg_count > 1, "star face should split into multiple segments");
                assert($ps_seg_vertex_count >= 3, "segment should have at least 3 vertices");
                assert(len($ps_seg_pts2d) == $ps_seg_vertex_count, "segment pts2d count");
                assert(len($ps_seg_pts3d_local) == $ps_seg_vertex_count, "segment pts3d count");
                assert(len($ps_seg_parent_face_edge_idx) == $ps_seg_vertex_count, "segment parent-edge mapping");
                assert($ps_face_has_segments == ($ps_seg_count > 1), "segment split flag consistency");
            }
        }
    }
}

module test_place_on_faces__local_z_origin_consistent_for_face_and_poly_verts() {
    // Build a slightly warped cube so at least some faces are non-planar.
    base = hexahedron();
    verts0 = poly_verts(base);
    faces0 = poly_faces(base);
    verts = [
        for (i = [0:1:len(verts0)-1])
            (i == 0) ? (verts0[i] + [0.35, -0.2, 0.45]) : verts0[i]
    ];
    p = poly_make(verts, faces0);

    place_on_faces(p)
        let(
            face = faces0[$ps_face_idx],
            zmean = ps_sum([for (q = $ps_face_pts3d_local) q[2]]) / len($ps_face_pts3d_local)
        ) {
            assert(abs(zmean) < 1e-9, str("face local z should be mean-centered, fi=", $ps_face_idx, " zmean=", zmean));
            for (k = [0:1:len(face)-1])
                let(vi = face[k])
                    assert_vec3_near(
                        $ps_poly_verts_local[vi],
                        $ps_face_pts3d_local[k],
                        1e-8,
                        str("poly/local vertex mismatch at face=", $ps_face_idx, " k=", k, " vi=", vi)
                    );
        }
}

module test_seg_cycle_probe_point__concave_inside() {
    concave = [[0,0], [4,0], [4,1], [1,1], [1,4], [0,4]];
    probe = _ps_seg_cycle_probe_point(concave, 1e-9);
    assert(_ps_seg_point_in_poly_evenodd(probe, concave, 1e-9), str("probe should be inside concave polygon, probe=", probe));
    assert(!_ps_seg_point_on_poly_boundary(probe, concave, 1e-8), str("probe should not lie on boundary, probe=", probe));
}

function _tri2_area(a, b, c) =
    abs((b[0] - a[0]) * (c[1] - a[1]) - (c[0] - a[0]) * (b[1] - a[1])) / 2;

function _list_sum(xs, i=0, acc=0) =
    (i >= len(xs)) ? acc : _list_sum(xs, i + 1, acc + xs[i]);

module test_seg_face_tris3__concave_area_preserved() {
    // Concave simple polygon: fan triangulation would over-cover; ear clipping should preserve area.
    pts3 = [[0,0,0], [4,0,0], [4,1,0], [1,1,0], [1,4,0], [0,4,0]];
    tris = _ps_seg_face_tris3([0,1,2,3,4,5], pts3, 1e-9);
    area_poly = abs(_ps_seg_poly_area2([for (p = pts3) [p[0], p[1]]]));
    area_tris = ps_sum([
        for (t = tris)
            _tri2_area(
                [t[0][0], t[0][1]],
                [t[1][0], t[1][1]],
                [t[2][0], t[2][1]]
            )
    ]);
    assert_int_eq(len(tris), 4, "concave hex should triangulate to 4 triangles");
    assert(abs(area_tris - area_poly) < 1e-6, str("concave triangulation area mismatch poly=", area_poly, " tris=", area_tris));
}

module test_seg_face_tris3__star_area_matches_segments() {
    // Pentagram-style self-intersecting face loop.
    pts3 = [[0,9,0], [-5,-5,0], [8,3,0], [-8,3,0], [5,-5,0]];
    tris = _ps_seg_face_tris3([0,1,2,3,4], pts3, 1e-9);
    segs = ps_face_segments(pts3, "evenodd", 1e-9);
    area_tris = _list_sum([
        for (t = tris)
            _tri2_area(
                [t[0][0], t[0][1]],
                [t[1][0], t[1][1]],
                [t[2][0], t[2][1]]
            )
    ]);
    area_segs = _list_sum([for (s = segs) abs(_ps_seg_poly_area2(s[0]))]);
    assert(len(segs) > 1, "star face should split into multiple even-odd regions");
    assert(len(tris) >= 3, "triangulation should produce at least a few triangles");
    assert(abs(area_tris - area_segs) < 1e-6, str("star triangulation area mismatch tris=", area_tris, " segs=", area_segs));
}

module test_ps_face_segments__default_matches_nonzero() {
    pts3 = [[0,9,0], [-5,-5,0], [8,3,0], [-8,3,0], [5,-5,0]];
    segs_default = ps_face_segments(pts3, eps=1e-9);
    segs_nonzero = ps_face_segments(pts3, "nonzero", 1e-9);
    assert(segs_default == segs_nonzero, "ps_face_segments default should match nonzero fill");
}

module test_ps_face_arrangement__pentagram_counts() {
    p = poly_antiprism(5, 2);
    pts3 = [for (i = poly_faces(p)[1]) poly_verts(p)[i]];
    arr = ps_face_arrangement(pts3, 1e-9);
    crossings = arr[1];
    nodes = arr[2];
    spans = arr[3];
    cells = arr[4];

    assert_int_eq(len(crossings), 5, "pentagram crossings");
    assert_int_eq(len(nodes), 10, "pentagram arrangement nodes");
    assert_int_eq(len(spans), 15, "pentagram arrangement spans");
    assert_int_eq(len(cells), 7, "pentagram arrangement cells");

    assert_int_eq(len([for (n = nodes) if (n[1] == "source_vertex") 1]), 5, "pentagram source-vertex count");
    assert_int_eq(len([for (n = nodes) if (n[1] == "crossing") 1]), 5, "pentagram crossing-node count");
    assert_int_eq(len([for (s = spans) if (s[6] == "source") 1]), len(spans), "pentagram span kinds");
}

module test_ps_face_boundary_model__pentagram_counts() {
    p = poly_antiprism(5, 2);
    pts3 = [for (i = poly_faces(p)[1]) poly_verts(p)[i]];
    pts2 = [for (pt = pts3) [pt[0], pt[1]]];
    nz = ps_face_boundary_model(pts3, "nonzero", 1e-9);
    eo = ps_face_boundary_model(pts3, "evenodd", 1e-9);

    assert_int_eq(len(nz[1]), 1, "pentagram nonzero filled cell count");
    assert_int_eq(len(nz[2]), 1, "pentagram nonzero boundary loop count");
    assert_int_eq(len(nz[3]), 10, "pentagram nonzero boundary span count");

    assert_int_eq(len(eo[1]), 5, "pentagram evenodd filled cell count");
    assert_int_eq(len(eo[2]), 2, "pentagram evenodd boundary loop count");
    assert_int_eq(len(eo[3]), 15, "pentagram evenodd boundary span count");

    for (bm = [nz, eo])
        for (span = bm[3]) {
            edge_idx = span[2];
            t0 = span[3];
            t1 = span[4];
            a = pts2[edge_idx];
            b = pts2[(edge_idx + 1) % len(pts2)];
            p0 = [a[0] + (b[0] - a[0]) * t0, a[1] + (b[1] - a[1]) * t0];
            p1 = [a[0] + (b[0] - a[0]) * t1, a[1] + (b[1] - a[1]) * t1];
            assert(norm(p0 - span[0][0]) < 1e-6, str("boundary span start should match source params edge=", edge_idx, " t0=", t0));
            assert(norm(p1 - span[0][1]) < 1e-6, str("boundary span end should match source params edge=", edge_idx, " t1=", t1));
        }
}

module test_ps_face_boundary_span_sites__pentagram_attach_adjacent_face_context() {
    p = poly_antiprism(5, 2);
    place_on_faces(p) {
        if ($ps_face_idx == 1) {
            sites = _ps_face_boundary_span_sites(
                $ps_face_pts3d_local,
                $ps_face_idx,
                $ps_poly_faces_idx,
                $ps_poly_verts_local,
                $ps_face_neighbors_idx,
                $ps_face_dihedrals,
                "nonzero",
                1e-9
            );

            assert_int_eq(len(sites), 10, "pentagram nonzero boundary span site count");

            for (site = sites) {
                ei = ps_boundary_span_site_source_edge_idx(site);
                dir = ps_boundary_span_site_adj_face_dir_span_local(site);
                assert_int_eq(ps_boundary_span_site_adj_face_idx(site), $ps_face_neighbors_idx[ei], "boundary span adjacent face id");
                assert(abs(ps_boundary_span_site_dihedral(site) - $ps_face_dihedrals[ei]) < 1e-6, str("boundary span dihedral mismatch edge=", ei));
                assert(!is_undef(ps_boundary_span_site_adj_face_normal_local(site)), str("boundary span adjacent-face normal should be defined edge=", ei));
                assert(ps_boundary_span_site_filled_side(site) != 0, str("boundary span filled side should be nonzero edge=", ei));
                assert(!is_undef(dir), str("boundary span adjacent-face direction should be defined edge=", ei));
                assert(abs(dir[0]) < 1e-6, str("boundary span adjacent-face direction should stay in local yz plane edge=", ei));
                assert(dir[2] > 0, str("boundary span adjacent-face direction should point to current-face +Z edge=", ei));
            }
        }
    }
}

module test_ps_boundary_span_site_accessors__match_record_layout_and_frame() {
    p = poly_antiprism(5, 2);
    place_on_faces(p) {
        if ($ps_face_idx == 1) {
            sites = _ps_face_boundary_span_sites(
                $ps_face_pts3d_local,
                $ps_face_idx,
                $ps_poly_faces_idx,
                $ps_poly_verts_local,
                $ps_face_neighbors_idx,
                $ps_face_dihedrals,
                "nonzero",
                1e-9
            );

            for (site = sites) {
                fields = [
                    ["idx", ps_boundary_span_site_idx(site), site[0]],
                    ["frame", ps_boundary_span_site_frame(site), site[1]],
                    ["center", ps_boundary_span_site_center_local(site), ps_placement_frame_center(site[1])],
                    ["ex", ps_boundary_span_site_ex_local(site), ps_placement_frame_ex(site[1])],
                    ["ey", ps_boundary_span_site_ey_local(site), ps_placement_frame_ey(site[1])],
                    ["ez", ps_boundary_span_site_ez_local(site), ps_placement_frame_ez(site[1])],
                    ["len", ps_boundary_span_site_len(site), site[2]],
                    ["segment2d", ps_boundary_span_site_segment2d_local(site), site[3]],
                    ["loop_idx", ps_boundary_span_site_loop_idx(site), site[4]],
                    ["source_edge_idx", ps_boundary_span_site_source_edge_idx(site), site[5]],
                    ["source_t0", ps_boundary_span_site_source_t0(site), site[6]],
                    ["source_t1", ps_boundary_span_site_source_t1(site), site[7]],
                    ["raw_kind", ps_boundary_span_site_raw_kind(site), site[8]],
                    ["filled_cell_idx", ps_boundary_span_site_filled_cell_idx(site), site[9]],
                    ["other_cell_idx", ps_boundary_span_site_other_cell_idx(site), site[10]],
                    ["adj_face_idx", ps_boundary_span_site_adj_face_idx(site), site[11]],
                    ["dihedral", ps_boundary_span_site_dihedral(site), site[12]],
                    ["adj_face_normal", ps_boundary_span_site_adj_face_normal_local(site), site[13]],
                    ["filled_side", ps_boundary_span_site_filled_side(site), site[14]],
                    ["adj_face_dir", ps_boundary_span_site_adj_face_dir_span_local(site), site[15]],
                    ["kind", ps_boundary_span_site_kind(site), site[16]]
                ];

                for (field = fields)
                    assert(field[1] == field[2], str("boundary span site accessor mismatch field=", field[0], " site=", site[0]));

                assert(
                    ps_placement_frame_matrix(ps_boundary_span_site_frame(site)) == ps_placement_frame_matrix(site[1]),
                    str("boundary span site frame matrix site=", site[0])
                );
                assert(
                    ps_boundary_span_site_is_generated(site) == (site[16] != "source_edge"),
                    str("boundary span generated flag site=", site[0])
                );
            }
        }
    }
}

module test_ps_face_boundary_span_direction__projects_source_edge_into_face_plane() {
    ex = [1, 0, 0];
    ey = [0, 1, 0];
    ez = [0, 0, 1];
    source_ex_raw = v_norm([1, 0, 1]);
    source_ex_proj = v_norm(_ps_seg_project_to_plane(source_ex_raw, ez));
    adj_face_normal_local = v_norm([0, 1, 1]);
    dir_span_local = _ps_seg_boundary_span_adj_face_dir_span_local(source_ex_proj, ex, ey, ez, adj_face_normal_local);

    assert(abs(source_ex_proj[2]) < 1e-9, "projected source edge should lie in the current face plane");
    assert(abs(dir_span_local[0]) < 1e-9, "adjacent-face direction should stay in local yz plane after source-edge projection");
    assert(dir_span_local[2] > 0, "adjacent-face direction should keep the +Z branch");
}

module test_ps_face_boundary_span_sites__anti_tet_hex_is_span_directional() {
    p = poly_truncate(tetrahedron(), t = -0.5);
    place_on_faces(p) {
        if ($ps_face_idx == 0) {
            sites = _ps_face_boundary_span_sites(
                $ps_face_pts3d_local,
                $ps_face_idx,
                $ps_poly_faces_idx,
                $ps_poly_verts_local,
                $ps_face_neighbors_idx,
                $ps_face_dihedrals,
                "nonzero",
                1e-9
            );
            source_edges = len($ps_face_pts2d);
            repeated_edges = [
                for (ei = [0:1:source_edges-1])
                    if (len([for (s = sites) if (ps_boundary_span_site_source_edge_idx(s) == ei) 1]) > 1)
                        ei
            ];
            mixed_dir_edges = [
                for (ei = repeated_edges)
                    let(
                        has_inc = len([for (s = sites) if (ps_boundary_span_site_source_edge_idx(s) == ei && ps_boundary_span_site_source_t1(s) > ps_boundary_span_site_source_t0(s)) 1]) > 0,
                        has_dec = len([for (s = sites) if (ps_boundary_span_site_source_edge_idx(s) == ei && ps_boundary_span_site_source_t1(s) < ps_boundary_span_site_source_t0(s)) 1]) > 0
                    )
                    if (has_inc && has_dec)
                        ei
            ];

            assert_int_eq(len(sites), 12, "anti-tet hex nonzero boundary span site count");
            assert(len(repeated_edges) > 0, "anti-tet hex should reuse source edges across multiple boundary spans");
            assert(len(mixed_dir_edges) > 0, "anti-tet hex should need per-span source-edge directionality");

            for (site = sites) {
                ei = ps_boundary_span_site_source_edge_idx(site);
                dir = ps_boundary_span_site_adj_face_dir_span_local(site);
                assert_int_eq(ps_boundary_span_site_adj_face_idx(site), $ps_face_neighbors_idx[ei], "anti-tet boundary span adjacent face id");
                assert(abs(ps_boundary_span_site_dihedral(site) - $ps_face_dihedrals[ei]) < 1e-6, str("anti-tet boundary span dihedral mismatch edge=", ei));
                assert(ps_boundary_span_site_filled_side(site) != 0, str("anti-tet boundary span filled side should be nonzero edge=", ei));
                assert(!is_undef(dir), str("anti-tet boundary span adjacent-face direction should be defined edge=", ei));
                assert(abs(dir[0]) < 1e-6, str("anti-tet boundary span adjacent-face direction should stay in local yz plane edge=", ei));
                assert(dir[2] > 0, str("anti-tet boundary span adjacent-face direction should point to current-face +Z edge=", ei));
            }

            se1_span_dirs = [
                for (site = sites)
                    if (ps_boundary_span_site_source_edge_idx(site) == 1)
                        ps_boundary_span_site_adj_face_dir_span_local(site)
            ];
            se1_has_pos_y = len([for (dir = se1_span_dirs) if (dir[1] > 0) 1]) > 0;
            se1_has_neg_y = len([for (dir = se1_span_dirs) if (dir[1] < 0) 1]) > 0;
            assert(se1_has_pos_y && se1_has_neg_y, "anti-tet spans from one long source edge should distinguish central vs end branches");
        }
    }
}

module test_ps_face_visible_segments__cube_face_unchanged() {
    p = hexahedron();
    place_on_faces(p) {
        if ($ps_face_idx == 0) {
            vis = ps_face_visible_segments($ps_face_pts2d, $ps_face_idx, $ps_poly_faces_idx, $ps_poly_verts_local, 1e-8, "nonzero", true);
            area_face = abs(_ps_seg_poly_area2($ps_face_pts2d));
            area_vis = _list_sum([for (s = vis) abs(_ps_seg_poly_area2(s[0]))]);
            assert_int_eq(len(vis), 1, "cube face should keep one visible cell");
            assert(abs(area_vis - area_face) < 1e-6, str("cube visible area mismatch face=", area_face, " vis=", area_vis));
            assert_int_eq(len(vis[0][2]), len(vis[0][0]), "cube visible edge-id count");
            assert_int_eq(len(vis[0][3]), len(vis[0][0]), "cube visible edge-kind count");
            assert(ps_sum([for (k = vis[0][3]) (k == "parent") ? 1 : 0]) == len(vis[0][0]), "cube visible cell edges should all be parent");
        }
    }
}

module test_ps_face_visible_segments__star_antiprism_side_reduced() {
    p = poly_antiprism(5, 2);
    faces = poly_faces(p);
    tri_faces = [for (i = [0:1:len(faces)-1]) if (len(faces[i]) == 3) i];
    target = tri_faces[0];
    place_on_faces(p) {
        if ($ps_face_idx == target) {
            vis = ps_face_visible_segments($ps_face_pts2d, $ps_face_idx, $ps_poly_faces_idx, $ps_poly_verts_local, 1e-8, "nonzero", true);
            area_face = abs(_ps_seg_poly_area2($ps_face_pts2d));
            area_vis = _list_sum([for (s = vis) abs(_ps_seg_poly_area2(s[0]))]);
            assert(len(vis) >= 1, "star antiprism side should keep at least one visible cell");
            assert(area_vis > 1e-6, "star antiprism visible area should stay positive");
            assert(area_vis < area_face - 1e-6, str("star antiprism side should lose hidden area face=", area_face, " vis=", area_vis));
            assert(
                ps_sum([
                    for (s = vis)
                        ps_sum([for (k = s[3]) (k == "cut") ? 1 : 0])
                ]) > 0,
                "star antiprism visible cells should include cut edges"
            );
        }
    }
}

module test_ps_face_visible_segments__cells_preserve_parent_winding() {
    p = poly_antiprism(5, 2);
    faces = poly_faces(p);
    tri_faces = [for (i = [0:1:len(faces)-1]) if (len(faces[i]) == 3) i];
    target = tri_faces[0];
    place_on_faces(p) {
        if ($ps_face_idx == target) {
            vis = ps_face_visible_segments($ps_face_pts2d, $ps_face_idx, $ps_poly_faces_idx, $ps_poly_verts_local, 1e-8, "nonzero", true);
            parent_sign = (_ps_seg_poly_area2($ps_face_pts2d) >= 0) ? 1 : -1;
            for (s = vis)
                assert(
                    _ps_seg_poly_area2(s[0]) * parent_sign > 1e-9,
                    str("visible cell winding mismatch parent=", $ps_face_idx, " area=", _ps_seg_poly_area2(s[0]))
                );
        }
    }
}

module test_ps_face_geom_cut_segments__respects_fill_mode() {
    // Target square in z=0 plane plus a star-shaped cutter face tilted through the plane.
    target = [[-6,-6], [6,-6], [6,6], [-6,6]];
    faces = [
        [0,1,2,3],
        [4,5,6,7,8]
    ];
    star_xy = [for (i = [0:1:4]) [10*cos(-144*i), 10*sin(-144*i)]];
    verts_local = concat(
        [for (p = target) [p[0], p[1], 0]],
        [for (p = star_xy) [p[0], p[1], p[1] / 6]]
    );
    segs_evenodd = ps_face_geom_cut_segments(target, 0, faces, verts_local, 1e-8, "evenodd", true);
    segs_nonzero = ps_face_geom_cut_segments(target, 0, faces, verts_local, 1e-8, "nonzero", true);
    assert(len(segs_evenodd) > 0, "synthetic star cutter should generate some cut geometry");
    assert(len(segs_nonzero) > len(segs_evenodd), str("nonzero star cutter should yield more cut segments than evenodd evenodd=", len(segs_evenodd), " nonzero=", len(segs_nonzero)));
}

module run_TestPlacement() {
    test_place_on_faces__family_ids_and_counts_from_classify();
    test_place_on_edges__family_ids_and_counts_from_classify();
    test_place_on_vertices__family_ids_and_counts_from_classify();
    test_place_on_faces__auto_classify_matches_precomputed();
    test_ps_placement_frame__accessors_and_matrix_match_raw_frame();
    test_ps_placement_frame_describe_str__summary_and_formatter();
    test_ps_target_local_poly_context__accessors_and_default_center();
    test_ps_target_local_poly_context_describe_str__summary();
    test_ps_face_local_context_describe_str__summary();
    test_ps_face_sites__cube_records_match_face_structure();
    test_ps_face_site_accessors__match_record_layout();
    test_ps_face_site_frame_and_context__match_site_accessors();
    test_ps_placement_site_describe_str__detail_includes_nested_context();
    test_ps_edge_sites__cube_records_match_edge_structure();
    test_ps_edge_site_accessors__match_record_layout();
    test_ps_edge_site_frame__matches_site_accessors();
    test_ps_edge_sites__cube_uses_adjacent_face_normal_bisector();
    test_ps_edge_sites__preserves_raw_edge_order_for_classify_ids();
    test_ps_vertex_sites__cube_records_match_vertex_structure();
    test_ps_vertex_fan__rhombicuboctahedron_neighbors_are_cyclic_and_anchored();
    test_ps_vertex_figure__matches_fan_order();
    test_ps_vertex_sites__neighbors_match_vertex_fan_order();
    test_ps_vertex_sites__open_construction_outputs_remain_placeable();
    test_ps_vertex_sites__hypertruncated_dodecahedron_t1_singular_vertices_remain_placeable();
    test_ps_vertex_site_from_local_poly__closed_ring_uses_fan_order();
    test_ps_vertex_site_from_local_poly__does_not_rebuild_local_poly();
    test_ps_vertex_site_from_local_poly__open_ring_uses_edge_scan_order();
    test_ps_vertex_site_from_local_poly__pinched_vertex_uses_edge_scan_order();
    test_ps_vertex_site_accessors__match_record_layout();
    test_ps_vertex_site_frame__matches_site_accessors();
    test_ps_vertex_sites__truncated_tetrahedron_frames_are_orthonormal();
    test_place_on_all__cube_single_family();
    test_place_on_edges__no_auto_classify_by_default();
    test_place_on_all__indices_filter_selected_ids();
    test_place_on_all__indices_accept_scalar();
    test_place_on_all__empty_indices_skip_children();
    test_place_on_face_segments__star_face_split();
    test_place_on_faces__local_z_origin_consistent_for_face_and_poly_verts();
    test_seg_cycle_probe_point__concave_inside();
    test_seg_face_tris3__concave_area_preserved();
    test_seg_face_tris3__star_area_matches_segments();
    test_ps_face_segments__default_matches_nonzero();
    test_ps_face_arrangement__pentagram_counts();
    test_ps_face_boundary_model__pentagram_counts();
    test_ps_face_boundary_span_sites__pentagram_attach_adjacent_face_context();
    test_ps_boundary_span_site_accessors__match_record_layout_and_frame();
    test_ps_face_boundary_span_direction__projects_source_edge_into_face_plane();
    test_ps_face_boundary_span_sites__anti_tet_hex_is_span_directional();
    test_ps_face_visible_segments__cube_face_unchanged();
    test_ps_face_visible_segments__star_antiprism_side_reduced();
    test_ps_face_visible_segments__cells_preserve_parent_winding();
    test_ps_face_geom_cut_segments__respects_fill_mode();
}

run_TestPlacement();
