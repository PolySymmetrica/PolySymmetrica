/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

use <../testing_util.scad>
use <../../polysymmetrica/core/classify.scad>
use <../../polysymmetrica/core/funcs.scad>
use <../../polysymmetrica/core/truncation.scad>
use <../../polysymmetrica/core/duals.scad>
use <../../polysymmetrica/models/platonics_all.scad>
use <../../polysymmetrica/models/archimedians_all.scad>
use <../../polysymmetrica/models/catalans_all.scad>

module assert_int_eq(a, b, msg="") {
    assert(a == b, msg);
}

function _classify_counts(poly, detail=0) =
    let(cls = poly_classify(poly, detail))
    [len(cls[0]), len(cls[1]), len(cls[2])];

function _poly_with_rotated_face_starts(poly) =
    let(faces = poly_faces(poly))
    [
        poly_verts(poly),
        [
            for (i = [0:1:len(faces)-1])
                rotl(faces[i], i % len(faces[i]))
        ],
        poly_e_over_ir(poly)
    ];

function _classify_edge_ids_for_edges(poly, cls, target_edges) =
    let(
        edges = _ps_edges_from_faces(poly_faces(poly)),
        nv = len(poly_verts(poly)),
        edge_keys = _ps_edge_keys_list(edges, nv),
        ids = ps_classify_edge_ids(cls, len(edges))
    )
    [
        for (e = target_edges)
            ids[_ps_edge_index(edge_keys, e[0], e[1], nv)]
    ];

module test_classify__platonics_single_family() {
    plats = [
        tetrahedron(),
        hexahedron(),
        octahedron(),
        dodecahedron(),
        icosahedron()
    ];

    for (p = plats) {
        counts = _classify_counts(p, 0);
        assert_int_eq(counts[0], 1, "platonics: face families = 1");
        assert_int_eq(counts[1], 1, "platonics: edge families = 1");
        assert_int_eq(counts[2], 1, "platonics: vertex families = 1");
    }
}

module test_classify__truncated_octa_families() {
    p = poly_truncate(octahedron());
    counts = _classify_counts(p, 0);
    assert_int_eq(counts[0], 2, "trunc octa: face families = 2");
    assert_int_eq(counts[1], 2, "trunc octa: edge families = 2");
    assert_int_eq(counts[2], 1, "trunc octa: vertex families = 1");
}

module test_classify__rhombi_families() {
    r = rhombicuboctahedron();
    g = great_rhombicuboctahedron();
    counts_r = _classify_counts(r, 0);
    counts_g = _classify_counts(g, 0);

    assert_int_eq(counts_r[0], 2, "rhombicubocta: face families = 2");
    assert_int_eq(counts_r[1], 2, "rhombicubocta: edge families = 2");
    assert_int_eq(counts_r[2], 1, "rhombicubocta: vertex families = 1");

    assert_int_eq(counts_g[0], 3, "great rhombicubocta: face families = 3");
    assert_int_eq(counts_g[2], 2, "great rhombicubocta: vertex families = 2");
}

module test_classify__rhombi_duals_face_family() {
    d1 = deltoidal_icositetrahedron();
    d2 = disdyakis_dodecahedron();
    counts1 = _classify_counts(d1, 0);
    counts2 = _classify_counts(d2, 0);

    assert_int_eq(counts1[0], 1, "deltoidal icositetra: face families = 1");
    assert_int_eq(counts2[0], 1, "disdyakis dodeca: face families = 1");
}

module test_classify__dual_trunc_rhomb_triaconta_faces_split() {
    p = poly_truncate(rhombic_triacontahedron());
    d = poly_dual(p);
    counts = _classify_counts(d, 1);
    assert_int_eq(counts[0], 2, "dual trunc rhomb triacont: face families = 2");
}

module test_classify__detail_refines_faces() {
    p = poly_truncate(rhombic_triacontahedron());
    d = poly_dual(p);
    counts0 = _classify_counts(d, 0);
    counts1 = _classify_counts(d, 1);
    counts2 = _classify_counts(d, 2);
    assert_int_eq(counts0[0], 1, "detail=0: dual trunc rhomb triacont faces = 1");
    assert_int_eq(counts1[0], 2, "detail=1: dual trunc rhomb triacont faces = 2");
    assert_int_eq(counts2[0], 2, "detail=2: dual trunc rhomb triacont faces = 2");
}

module test_classify__cyclic_face_starts_do_not_change_families() {
    p = great_rhombicuboctahedron();
    p_rot = _poly_with_rotated_face_starts(p);
    cls = poly_classify(p, 1, 1e-6, 1, false);
    cls_rot = poly_classify(p_rot, 1, 1e-6, 1, false);
    faces = poly_faces(p);
    faces_rot = poly_faces(p_rot);
    edges = _ps_edges_from_faces(faces);

    assert(ps_classify_counts(cls) == ps_classify_counts(cls_rot), "cyclic face starts: classification counts should match");
    assert(
        ps_classify_face_ids(cls, len(faces)) == ps_classify_face_ids(cls_rot, len(faces_rot)),
        "cyclic face starts: face ids should match"
    );
    assert(
        _classify_edge_ids_for_edges(p, cls, edges) == _classify_edge_ids_for_edges(p_rot, cls_rot, edges),
        "cyclic face starts: edge ids should match by edge"
    );
    assert(
        ps_classify_vert_ids(cls, len(poly_verts(p))) == ps_classify_vert_ids(cls_rot, len(poly_verts(p_rot))),
        "cyclic face starts: vertex ids should match"
    );
}

module test_classify__group_by_key_composite() {
    keys = [
        [3, [1, 2]],
        [3, [1, 2]],
        [4, [0]],
        [3, [1, 2]],
        [4, [0]]
    ];
    fams = _ps_group_by_key(keys);
    assert_int_eq(len(fams), 2, "group_by_key: two families");
    assert_int_eq(len(fams[0][1]) + len(fams[1][1]), 5, "group_by_key: total count");
}

module test_ps_classification_describe_str__summary() {
    cls = poly_classify(hexahedron(), 0);
    s = ps_classification_describe_str(cls, 0);
    assert(s == "Classification(face_families=1, edge_families=1, vert_families=1)", "classification summary string");
}

module test_ps_classification_describe_str__formatter_override() {
    cls = poly_classify(hexahedron(), 0);
    s = ps_classification_describe_str(
        cls,
        0,
        function(k, v) str("\"", k, "\":", v),
        " | ",
        "\n"
    );
    assert(s == "Classification(\"face_families\":1 | \"edge_families\":1 | \"vert_families\":1)", "classification formatter override");
}


module run_TestClassify() {
    test_classify__platonics_single_family();
    test_classify__truncated_octa_families();
    test_classify__rhombi_families();
    test_classify__rhombi_duals_face_family();
    test_classify__dual_trunc_rhomb_triaconta_faces_split();
    test_classify__detail_refines_faces();
    test_classify__cyclic_face_starts_do_not_change_families();
    test_classify__group_by_key_composite();
    test_ps_classification_describe_str__summary();
    test_ps_classification_describe_str__formatter_override();
}

run_TestClassify();
