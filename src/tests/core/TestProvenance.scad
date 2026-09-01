/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

use <../../polysymmetrica/core/funcs.scad>
use <../../polysymmetrica/core/cleanup.scad>
use <../../polysymmetrica/core/truncation.scad>
use <../../polysymmetrica/core/transform.scad>
use <../../polysymmetrica/models/platonics_all.scad>

module test_provenance__raw_descriptors_are_lazy() {
    p = hexahedron();
    assert(!poly_has_provenance(p), "raw descriptor should not carry provenance");
    q = poly_with_provenance(p);
    assert(poly_has_provenance(q), "initializer should add provenance");
    assert(len(poly_provenance(q)[1]) == len(poly_verts(p)), "source vertex record count");
    assert(len(poly_provenance(q)[2]) == len(poly_faces(p)), "source face record count");
}

module test_provenance__chamfer_keeps_source_vertices_and_history() {
    p = hexahedron();
    q = poly_chamfer(p, t=0.1);
    source = poly_source_vertex_indices(q);
    assert(poly_has_provenance(q), "chamfer provenance");
    assert(len(source) == len(poly_verts(p)), "chamfer retains source vertices");
    assert(len(poly_provenance_history(q)) == 1, "one semantic operation");
    assert(poly_provenance_history(q)[0] == ["chamfer"], "semantic operation is chamfer");
    assert(len(poly_source_vertex_indices(q)) < len(poly_verts(q)), "generated site events");
}

module test_provenance__chamfer_edges_are_derived_from_lineage() {
    q = poly_chamfer(hexahedron(), t=0.1);
    ids = [for (ei = [0:1:len(poly_edges(q))-1]) poly_edge_source_ids(q, ei)];
    assert(len([for (xs = ids) if (len(xs) > 0) xs]) > 0, "derived chamfer edge lineage");
    assert(len(poly_edges(q)) == 48, "edges remain derived from faces");
}

module test_provenance__selective_truncation_targets_only_source_vertices() {
    p = hexahedron();
    q = poly_chamfer(p, t=0.1);
    selected = concat(
        poly_source_vertex_indices(q, 0),
        poly_source_vertex_indices(q, 1),
        poly_source_vertex_indices(q, 2),
        poly_source_vertex_indices(q, 3)
    );
    r = poly_truncate(q, t=0.08, selected_vertices=selected);
    all_cut = poly_truncate(q, t=0.08);
    assert(poly_has_provenance(r), "selective truncation provenance");
    assert(poly_provenance_history(r) == [["chamfer"], ["truncate"]], "compound history");
    assert(len(poly_source_vertex_indices(r, 0)) == 0, "selected source vertex is cut");
    assert(len(poly_source_vertex_indices(r, 4)) == 1, "unselected source vertex remains identifiable");
    assert(len(poly_source_vertex_indices(r, 7)) == 1, "unselected source vertex remains selectable");
    assert(len(poly_verts(r)) < len(poly_verts(all_cut)), "selective cut does not cut generated sites");
}

module test_provenance__cantitruncate_records_one_semantic_operation() {
    p = poly_with_provenance(hexahedron());
    q = poly_cantitruncate(p, t=0.08, c=0.08);
    assert(poly_has_provenance(q), "cantitruncate provenance");
    assert(poly_provenance_history(q) == [["cantitruncate"]], "compound operation history");
    assert(len(poly_faces(q)) > len(poly_faces(p)), "cantitruncate topology");
}

module test_provenance__strict_rectify_preserves_site_lineage() {
    p = poly_with_provenance(hexahedron());
    q = poly_rectify(p, style="strict");
    edge_ids = [for (ei = [0:1:len(poly_edges(q))-1]) poly_edge_source_ids(q, ei)];
    face_roots = [for (fi = [0:1:len(poly_faces(q))-1]) poly_face_provenance(q, fi)[1]];
    assert(poly_has_provenance(q), "strict rectify provenance");
    assert(len(poly_source_vertex_indices(q)) == 0, "rectify creates edge-midpoint vertices");
    assert(len([for (i = [0:1:len(poly_verts(q))-1]) if (poly_vertex_descends_from(q, i, 0)) i]) > 0, "rectify vertex descendants");
    assert(len([for (xs = edge_ids) if (len(xs) > 0) xs]) > 0, "rectify edge lineage");
    assert(len([for (xs = face_roots) if (len(xs) > 0) xs]) > 0, "rectify face lineage");
}

module test_provenance__planarized_rectify_has_rectify_history() {
    p = poly_with_provenance(hexahedron());
    q = poly_rectify(p, style="planarized");
    assert(poly_provenance_history(q) == [["rectify"]], "planarized rectify semantic history");
    assert(poly_has_provenance(q), "planarized rectify provenance");
}

module test_provenance__transform_merges_coincident_point_lineage() {
    p = poly_with_provenance(tetrahedron());
    pts = [
        [poly_verts(p)[0], poly_verts(p)[1], poly_verts(p)[2]],
        [poly_verts(p)[0], poly_verts(p)[2], poly_verts(p)[3]]
    ];
    point_provenance = [
        poly_vertex_provenance(p, 0),
        poly_vertex_provenance(p, 1),
        poly_vertex_provenance(p, 2),
        poly_vertex_provenance(p, 3),
        poly_vertex_provenance(p, 2),
        poly_vertex_provenance(p, 3)
    ];
    face_provenance = [poly_face_provenance(p, 0), poly_face_provenance(p, 1)];
    q = _ps_poly_from_face_points(pts, 1e-8, 1e-8, "global", point_provenance, face_provenance, []);
    assert(
        len([
            for (i = [0:1:len(poly_verts(q))-1])
                if (poly_vertex_descends_from(q, i, 0) && poly_vertex_descends_from(q, i, 3)) i
        ]) > 0,
        "coincident point lineage is merged"
    );
}

module test_provenance__cleanup_remaps_lineage() {
    q = poly_chamfer(hexahedron(), t=0.1);
    r = poly_cleanup(q, merge_vertices=true, remove_unreferenced=true);
    assert(poly_has_provenance(r), "cleanup preserves provenance");
    assert(len(poly_provenance(r)[1]) == len(poly_verts(r)), "cleanup vertex remap");
    assert(len(poly_provenance(r)[2]) == len(poly_faces(r)), "cleanup face remap");
}

module run_TestProvenance() {
    test_provenance__raw_descriptors_are_lazy();
    test_provenance__chamfer_keeps_source_vertices_and_history();
    test_provenance__chamfer_edges_are_derived_from_lineage();
    test_provenance__selective_truncation_targets_only_source_vertices();
    test_provenance__cantitruncate_records_one_semantic_operation();
    test_provenance__strict_rectify_preserves_site_lineage();
    test_provenance__planarized_rectify_has_rectify_history();
    test_provenance__transform_merges_coincident_point_lineage();
    test_provenance__cleanup_remaps_lineage();
}

run_TestProvenance();
