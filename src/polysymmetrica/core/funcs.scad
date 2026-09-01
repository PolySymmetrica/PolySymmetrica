/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

// LibFile: polysymmetrica/core/funcs.scad
///////////////////////////////////////
// ---- Poly descriptor API ----
// Function: poly_verts()
// Usage:
//   result = poly_verts(poly);
// Description:
//   Return the vertex list from a poly descriptor.
//   .
//   - Returns: vertex list
// Arguments:
//   poly = `[verts, faces, e_over_ir, provenance?]`
function poly_verts(poly)      = poly[0];

// Function: poly_faces()
// Usage:
//   result = poly_faces(poly);
// Description:
//   Return the face index loops from a poly descriptor.
//   .
//   - Returns: face list
// Arguments:
//   poly = `[verts, faces, e_over_ir, provenance?]`
function poly_faces(poly)      = poly[1];

// Function: poly_e_over_ir()
// Usage:
//   result = poly_e_over_ir(poly);
// Description:
//   Return descriptor scale ratio `edge / inter-radius`.
//   .
//   - Returns: positive scalar ratio
// Arguments:
//   poly = `[verts, faces, e_over_ir, provenance?]`
function poly_e_over_ir(poly)  = poly[2];

// Function: poly_provenance()
// Usage:
//   result = poly_provenance(poly);
// Description:
//   Return the optional provenance record, or `undef` for a raw descriptor.
//   The record layout is private; use the named query functions below.
function poly_provenance(poly) = (len(poly) > 3) ? poly[3] : undef;

// Function: poly_has_provenance()
// Usage:
//   result = poly_has_provenance(poly);
// Description:
//   Test whether a descriptor carries provenance metadata.
function poly_has_provenance(poly) = !is_undef(poly_provenance(poly));

function _ps_prov_has_item(xs, value, i=0) =
    (i >= len(xs)) ? false
    : (xs[i] == value) ? true : _ps_prov_has_item(xs, value, i + 1);

function _ps_prov_unique(xs, acc=[], i=0) =
    (i >= len(xs)) ? acc
    : _ps_prov_unique(
        xs,
        _ps_prov_has_item(acc, xs[i]) ? acc : concat(acc, [xs[i]]),
        i + 1
    );

function _ps_prov_record(vertex_roots=[], face_roots=[], events=[]) =
    [_ps_prov_unique(vertex_roots), _ps_prov_unique(face_roots), events];

function _ps_prov_source_vertex_record(i) =
    _ps_prov_record([["vertex", i]], [], [["source_vertex", i]]);

function _ps_prov_source_face_record(i) =
    _ps_prov_record([], [["face", i]], [["source_face", i]]);

function _ps_prov_empty_history() = [];

function _ps_prov_init_record(poly) =
    [
        "ps_provenance_v1",
        [for (i = [0:1:len(poly_verts(poly))-1]) _ps_prov_source_vertex_record(i)],
        [for (i = [0:1:len(poly_faces(poly))-1]) _ps_prov_source_face_record(i)],
        _ps_prov_empty_history()
    ];

// Function: poly_with_provenance()
// Usage:
//   result = poly_with_provenance(poly);
// Description:
//   Lazily initialize source lineage on a raw descriptor. Existing metadata is
//   returned unchanged.
function poly_with_provenance(poly) =
    poly_has_provenance(poly)
        ? poly
        : [poly_verts(poly), poly_faces(poly), poly_e_over_ir(poly), _ps_prov_init_record(poly)];

// Compatibility spelling for callers that prefer an explicit initializer.
function poly_provenance_init(poly) = poly_with_provenance(poly);

function _ps_prov_vertices(prov) = prov[1];
function _ps_prov_faces(prov) = prov[2];
function _ps_prov_history(prov) = prov[3];

// Function: poly_vertex_provenance()
// Usage:
//   result = poly_vertex_provenance(poly, vertex_idx);
// Description:
//   Return the private lineage record for one current vertex.
function poly_vertex_provenance(poly, vertex_idx) =
    assert(poly_has_provenance(poly), "poly_vertex_provenance: poly has no provenance")
    poly_provenance(poly)[1][vertex_idx];

// Function: poly_face_provenance()
// Usage:
//   result = poly_face_provenance(poly, face_idx);
// Description:
//   Return the private lineage record for one current face.
function poly_face_provenance(poly, face_idx) =
    assert(poly_has_provenance(poly), "poly_face_provenance: poly has no provenance")
    poly_provenance(poly)[2][face_idx];

// Function: poly_provenance_history()
// Usage:
//   result = poly_provenance_history(poly);
// Description:
//   Return semantic public operations recorded on a provenance-bearing poly.
function poly_provenance_history(poly) =
    assert(poly_has_provenance(poly), "poly_provenance_history: poly has no provenance")
    _ps_prov_history(poly_provenance(poly));

function _ps_prov_record_has_event(record, tag) =
    len([for (e = record[2]) if (is_list(e) && len(e) > 0 && e[0] == tag) 1]) > 0;

// Function: poly_vertex_descends_from()
// Usage:
//   result = poly_vertex_descends_from(poly, vertex_idx, source_vertex_idx);
// Description:
//   Test whether a current vertex has lineage rooted at a source vertex.
function poly_vertex_descends_from(poly, vertex_idx, source_vertex_idx) =
    let(r = poly_vertex_provenance(poly, vertex_idx))
    _ps_prov_has_item(r[0], ["vertex", source_vertex_idx]);

// Function: poly_source_vertex_indices()
// Usage:
//   result = poly_source_vertex_indices(poly);
// Description:
//   Return current vertices that are retained source vertices, optionally
//   restricted to one source vertex identity.
function poly_source_vertex_indices(poly, source_vertex_idx=undef) =
    assert(poly_has_provenance(poly), "poly_source_vertex_indices: poly has no provenance")
    [
        for (i = [0:1:len(poly_verts(poly))-1])
            let(r = poly_vertex_provenance(poly, i))
            if (
                _ps_prov_record_has_event(r, "source_vertex") &&
                (is_undef(source_vertex_idx) || _ps_prov_has_item(r[0], ["vertex", source_vertex_idx]))
            ) i
    ];

function _ps_prov_merge_records(records, event=undef) =
    let(
        vr = [for (r = records) for (x = r[0]) x],
        fr = [for (r = records) for (x = r[1]) x],
        ev = [for (r = records) for (x = r[2]) x]
    )
    _ps_prov_record(vr, fr, is_undef(event) ? ev : concat(ev, [event]));

function _ps_prov_append_history(prov, operation) =
    [prov[0], prov[1], prov[2], concat(prov[3], [[operation]])];

// Function: poly_edge_provenance()
// Usage:
//   result = poly_edge_provenance(poly, edge);
// Description:
//   Derive one edge's lineage from its endpoints and incident face cycles.
//   Edges are intentionally not stored in the descriptor.
function poly_edge_provenance(poly, edge) =
    let(
        edges = _ps_edges_from_faces(poly_faces(poly)),
        ei = is_num(edge) ? edge : _ps_index_of(edges, edge),
        ef = ps_edge_faces_table(poly_faces(poly), edges),
        e = edges[ei],
        vr = concat(poly_vertex_provenance(poly, e[0])[0], poly_vertex_provenance(poly, e[1])[0]),
        fr = [for (fi = ef[ei]) for (x = poly_face_provenance(poly, fi)[1]) x],
        ids = [
            for (a = _ps_prov_unique(vr))
                for (b = _ps_prov_unique(vr))
                    if (a[0] == "vertex" && b[0] == "vertex" && a[1] < b[1])
                    ["edge", a[1], b[1]]
        ]
    )
    [
        _ps_prov_unique(ids),
        _ps_prov_unique(vr),
        _ps_prov_unique(fr),
        [["derived_edge", ei]]
    ];

// Function: poly_edge_source_ids()
// Usage:
//   result = poly_edge_source_ids(poly, edge);
// Description:
//   Return source-edge identities derived from current face topology.
function poly_edge_source_ids(poly, edge) = poly_edge_provenance(poly, edge)[0];

// Function: ps_assert_no_provenance()
// Usage:
//   result = ps_assert_no_provenance(poly, operator_name);
// Description:
//   Guard Stage-B operators while their lineage mappings are not implemented.
function ps_assert_no_provenance(poly, operator_name) =
    assert(!poly_has_provenance(poly), str(operator_name, ": provenance-bearing input is not supported yet"))
    0;

// Function: poly_edges()
// Usage:
//   result = poly_edges(poly);
// Description:
//   Derive unique undirected edges from a poly descriptor.
//   .
//   - Returns: edge list `[[a,b], ...]`; O(face-edge-count)
// Arguments:
//   poly = `[verts, faces, e_over_ir]`
function poly_edges(poly)      = _ps_edges_from_faces(poly_faces(poly));

// Function: ps_clamp()
// Usage:
//   result = ps_clamp(x, lo, hi);
// Description:
//   Clamp a scalar to a closed interval.
//   .
//   - Returns: `min(max(x, lo), hi)`
// Arguments:
//   x = value
//   lo = lower bound
//   hi = upper bound
function ps_clamp(x, lo, hi) = min(max(x, lo), hi);

// Function: poly_make()
// Usage:
//   result = poly_make(verts, faces, e_over_ir);
// Description:
//   Build a normalized poly descriptor from vertices and faces.
//   .
//   - Returns: `[centered_verts, faces, e_over_ir]`
//   .
//   - Limitations/Gotchas: recenters by mean edge-midpoint center and computes default scale from minimum edge-midradius
// Arguments:
//   verts = 3D vertex list
//   faces = face index loops
//   e_over_ir = optional scale ratio
function poly_make(verts, faces, e_over_ir=undef, provenance=undef) =
    let(
        // Validation
        _0 = assert(len(verts) >= 3, "Polyhedron must have at least 3 vertices"),
        _1 = assert(len(faces) >= 1, "Polyhedron must have at least 1 face"),
        _2 = assert(ps_faces_valid(verts, faces), "Invalid face indices"),

        // Auto-compute if not provided
        edges = _ps_edges_from_faces(faces),
        _3 = assert(len(edges) >= 1, "Polyhedron must have at least 1 edge"),
        center = _ps_poly_mid_center(verts, faces),
        verts_centered = [for (v = verts) v - center],

        // compute ir from min edge-midradius, not just the first edge
        mids = [
            for (e = edges)
                norm((verts_centered[e[0]] + verts_centered[e[1]]) / 2)
        ],
        ir = min(mids),
        _ir_ok = assert(ir > 0, "poly_make: inter-radius (min edge-midradius) must be positive"),

        // choose an edge achieving that min (first one that matches)
        ei_ir = [ for (i = [0:len(edges)-1]) if (abs(mids[i] - ir) < 1e-12) i ][0],
        e_ir  = edges[ei_ir],

        computed_e_over_ir = is_undef(e_over_ir)
            ? norm(verts_centered[e_ir[1]] - verts_centered[e_ir[0]]) / ir
            : e_over_ir,
        
        _5 = assert(computed_e_over_ir > 0, "e_over_ir must be positive")
    )
    is_undef(provenance)
        ? [verts_centered, faces, computed_e_over_ir]
        : let(
            _pv = assert(len(provenance[1]) == len(verts), "poly_make: provenance vertex count mismatch"),
            _pf = assert(len(provenance[2]) == len(faces), "poly_make: provenance face count mismatch")
        )
        [verts_centered, faces, computed_e_over_ir, provenance];

// Function: poly_fix_winding()
// Usage:
//   result = poly_fix_winding(poly);
// Description:
//   Make adjacent face windings consistent across shared edges.
//   .
//   - Returns: poly descriptor with original vertices/scale and fixed face order
//   .
//   - Limitations/Gotchas: fixes topological consistency only; it does not prove outward orientation
// Arguments:
//   poly = poly descriptor
function poly_fix_winding(poly) =
    let(
        verts = poly_verts(poly),
        faces = poly_faces(poly),
        fixed = _ps_fix_winding_all(faces)
    )
    is_undef(poly_provenance(poly))
        ? [verts, fixed, poly_e_over_ir(poly)]
        : [verts, fixed, poly_e_over_ir(poly), poly_provenance(poly)];

///////////////////////////////////////
// ---- Basic validation helpers ----
// Function: ps_faces_valid()
// Usage:
//   result = ps_faces_valid(verts, faces);
// Description:
//   Validate all face loops against a vertex list.
//   .
//   - Returns: `true` when every face has at least 3 valid vertex indices
// Arguments:
//   verts = vertex list
//   faces = face index loops
function ps_faces_valid(verts, faces) =
    len([
        for (f = faces)
            if (len(f) >= 3 && ps_indices_in_range(f, len(verts)))
                1
    ]) == len(faces);

// Function: ps_indices_in_range()
// Usage:
//   result = ps_indices_in_range(face, max_idx);
// Description:
//   Check whether every index in a face is within `[0, max_idx)`.
//   .
//   - Returns: boolean
// Arguments:
//   face = index list
//   max_idx = exclusive upper bound
function ps_indices_in_range(face, max_idx) =
    len([for (vi = face) if (vi >= 0 && vi < max_idx) 1]) == len(face);

// Function: ps_join_strs()
// Usage:
//   result = ps_join_strs(parts, sep, i);
// Description:
//   Join a list of strings with a separator.
//   .
//   - Returns: joined string
// Arguments:
//   parts = string list
//   sep = separator
//   i = recursion index
function ps_join_strs(parts, sep="", i=0) =
    (i >= len(parts)) ? "" :
    (i == len(parts)-1) ? parts[i] :
    str(parts[i], sep, ps_join_strs(parts, sep, i + 1));

function _ps_describe_default_kvpair_str(k, v) = str(k, "=", v);

// Function: ps_describe_kvpair_str()
// Usage:
//   result = ps_describe_kvpair_str(k, v, kvpair_to_str);
// Description:
//   Format one key/value pair for a describe helper.
//   .
//   - Returns: formatted key/value string
// Arguments:
//   k = key
//   v = value
//   kvpair_to_str = optional function `(k, v) -> string`
function ps_describe_kvpair_str(k, v, kvpair_to_str=undef) =
    is_undef(kvpair_to_str)
        ? _ps_describe_default_kvpair_str(k, v)
        : kvpair_to_str(k, v);

// Function: ps_describe_record_str()
// Usage:
//   result = ps_describe_record_str(name, base_parts, detail, detail_parts, field_sep);
// Description:
//   Build a standard `Name(k=v, ...)` record description string.
//   .
//   - Returns: description string
// Arguments:
//   name = record type label
//   base_parts = summary field strings
//   detail = detail level
//   detail_parts = optional extra field strings
//   field_sep = field separator
function ps_describe_record_str(name, base_parts, detail=0, detail_parts=undef, field_sep=", ") =
    str(
        name,
        "(",
        ps_join_strs(
            detail > 0 && !is_undef(detail_parts)
                ? concat(base_parts, detail_parts)
                : base_parts,
            field_sep
        ),
        ")"
    );

function _ps_describe_count(xs) = is_undef(xs) ? undef : len(xs);

// Function: ps_cyclic_pairs()
// Usage:
//   result = ps_cyclic_pairs(list);
// Description:
//   Build successive pairs from a circular list.
//   .
//   - Returns: `[[list[i], list[i+1]], ... , [last, first]]`, or `[]` for lists shorter than 2
// Arguments:
//   list = item list
function ps_cyclic_pairs(list) =
    let(n = len(list))
    (n < 2) ? [] :
    [ for (i = [0:1:n-1]) [list[i], list[(i+1)%n]] ];

///////////////////////////////////////
// ---- Winding/orientation helpers (private) ----
// Function: _ps_face_edges_dir()
// Usage:
//   result = _ps_face_edges_dir(f);
// Description:
//   Return directed cyclic edges from a face loop.
//   .
//   - Returns: `[[a,b], ...]`
// Arguments:
//   f = face index loop
function _ps_face_edges_dir(f) =
    ps_cyclic_pairs(f);

// Function: _ps_face_edge_dir()
// Usage:
//   result = _ps_face_edge_dir(f, a, b);
// Description:
//   Determine whether a directed edge appears in a face.
//   .
//   - Returns: `1` for `a->b`, `-1` for `b->a`, `0` when absent
// Arguments:
//   f = face index loop
//   a =
//   b = edge endpoints
function _ps_face_edge_dir(f, a, b) =
    let(
        n = len(f),
        vals = [
            for (i = [0:1:n-1])
                let(u = f[i], v = f[(i+1)%n])
                (u == a && v == b) ? 1 : (u == b && v == a) ? -1 : 0
        ]
    )
    (max(vals) == 1) ? 1 : (min(vals) == -1) ? -1 : 0;

// Function: _ps_adjacent_faces_for_edge()
// Usage:
//   result = _ps_adjacent_faces_for_edge(faces, a, b, fi);
// Description:
//   Find faces adjacent to an edge, excluding one face.
//   .
//   - Returns: face indices containing undirected edge `{a,b}`
// Arguments:
//   faces = face list
//   a =
//   b = edge endpoints
//   fi = face to exclude
function _ps_adjacent_faces_for_edge(faces, a, b, fi) =
    [
        for (fj = [0:1:len(faces)-1])
            if (fj != fi && _ps_face_edge_dir(faces[fj], a, b) != 0) fj
    ];

// Function: _ps_list_set()
// Usage:
//   result = _ps_list_set(list, idx, val);
// Description:
//   Replace one list element.
//   .
//   - Returns: copy of `list` with `list[idx] = val`
// Arguments:
//   list = input list
//   idx = target index
//   val = replacement value
function _ps_list_set(list, idx, val) =
    [ for (i = [0:1:len(list)-1]) (i == idx) ? val : list[i] ];

// Function: _ps_index_of_undef()
// Usage:
//   result = _ps_index_of_undef(list);
// Description:
//   Find the first undefined element in a list.
//   .
//   - Returns: first index with `is_undef(...)`, or `-1`
// Arguments:
//   list = input list
function _ps_index_of_undef(list) =
    let(idx = [for (i = [0:1:len(list)-1]) if (is_undef(list[i])) i])
    (len(idx) == 0) ? -1 : idx[0];

// Function: _ps_reverse()
// Usage:
//   result = _ps_reverse(list);
// Description:
//   Reverse a list.
//   .
//   - Returns: reversed list
// Arguments:
//   list = input list
function _ps_reverse(list) =
    [ for (i = [len(list)-1 : -1 : 0]) list[i] ];

// Function: _ps_identity_map()
// Usage:
//   result = _ps_identity_map(n);
// Description:
//   Build identity index map.
//   .
//   - Returns: `[0, 1, ..., n-1]`
// Arguments:
//   n = size
function _ps_identity_map(n) =
    [for (i = [0:1:n-1]) i];

// Function: _ps_distinct_count()
// Usage:
//   result = _ps_distinct_count(list);
// Description:
//   Count distinct values in a list.
//   .
//   - Returns: number of first occurrences
// Arguments:
//   list = input list
function _ps_distinct_count(list) =
    len([for (i = [0:1:len(list)-1]) if (_ps_index_of(list, list[i]) == i) 1]);

// Function: _ps_face_strip_adjacent_dups()
// Usage:
//   result = _ps_face_strip_adjacent_dups(f);
// Description:
//   Remove adjacent duplicate vertex ids from a cyclic face.
//   .
//   - Returns: face loop without adjacent repeats
// Arguments:
//   f = face index loop
function _ps_face_strip_adjacent_dups(f) =
    let(n = len(f))
    (n == 0) ? [] :
    [for (i = [0:1:n-1]) if (f[i] != f[(i-1+n)%n]) f[i]];

// Function: _ps_face_trim_closing_dup()
// Usage:
//   result = _ps_face_trim_closing_dup(f);
// Description:
//   Remove duplicated closing vertex from a face loop.
//   .
//   - Returns: `f` without final element when `last == first`
// Arguments:
//   f = face index loop
function _ps_face_trim_closing_dup(f) =
    (len(f) >= 2 && f[0] == f[len(f)-1]) ? [for (i = [0:1:len(f)-2]) f[i]] : f;

// Function: _ps_face_clean_cycle()
// Usage:
//   result = _ps_face_clean_cycle(f);
// Description:
//   Normalize one face loop by removing trivial duplicate vertices.
//   .
//   - Returns: cleaned face loop
// Arguments:
//   f = face index loop
function _ps_face_clean_cycle(f) =
    _ps_face_trim_closing_dup(_ps_face_strip_adjacent_dups(f));

// Function: _ps_faces_clean_cycles()
// Usage:
//   result = _ps_faces_clean_cycles(faces);
// Description:
//   Clean every face loop in a face list.
//   .
//   - Returns: cleaned face list
// Arguments:
//   faces = face list
function _ps_faces_clean_cycles(faces) =
    [for (f = faces) _ps_face_clean_cycle(f)];

// Function: _ps_faces_remap()
// Usage:
//   result = _ps_faces_remap(faces, old_to_new);
// Description:
//   Remap all vertex ids in face loops.
//   .
//   - Returns: remapped face list
// Arguments:
//   faces = face list
//   old_to_new = index map
function _ps_faces_remap(faces, old_to_new) =
    [for (f = faces) [for (vi = f) old_to_new[vi]]];

// Function: _ps_neighbor_face()
// Usage:
//   result = _ps_neighbor_face(neighbors, idx);
// Description:
//   Look up a pending neighbor face assignment.
//   .
//   - Returns: assigned value or `undef`
// Arguments:
//   neighbors = `[[idx, value], ...]`
//   idx = face index
function _ps_neighbor_face(neighbors, idx) =
    let(hit = [for (p = neighbors) if (p[0] == idx) p[1]])
    (len(hit) == 0) ? undef : hit[0];

// Function: _ps_apply_neighbors()
// Usage:
//   result = _ps_apply_neighbors(fixed, neighbors);
// Description:
//   Apply pending neighbor face assignments into a fixed-face list.
//   .
//   - Returns: updated fixed list
// Arguments:
//   fixed = possibly-undef face list
//   neighbors = `[[idx, face], ...]`
function _ps_apply_neighbors(fixed, neighbors) =
    [
        for (i = [0:1:len(fixed)-1])
            is_undef(fixed[i]) ? _ps_neighbor_face(neighbors, i) : fixed[i]
    ];

// Function: _ps_new_neighbor_indices()
// Usage:
//   result = _ps_new_neighbor_indices(fixed, neighbors);
// Description:
//   Extract newly assigned face indices.
//   .
//   - Returns: indices whose previous value was `undef`
// Arguments:
//   fixed = previous fixed list
//   neighbors = `[[idx, face], ...]`
function _ps_new_neighbor_indices(fixed, neighbors) =
    [ for (p = neighbors) if (is_undef(fixed[p[0]])) p[0] ];

// Function: _ps_fix_winding_queue()
// Usage:
//   result = _ps_fix_winding_queue(faces, fixed, queue);
// Description:
//   Breadth-first face-winding propagation over connected faces.
//   .
//   - Returns: fixed face list for the connected component reachable from queue
// Arguments:
//   faces = source face list
//   fixed = assigned oriented faces
//   queue = face indices
function _ps_fix_winding_queue(faces, fixed, queue) =
    (len(queue) == 0) ? fixed :
    let(
        fi = queue[0],
        fcur = fixed[fi],
        edges = _ps_face_edges_dir(fcur),
        neighbors = [
            for (e = edges)
                let(
                    a = e[0],
                    b = e[1],
                    nbrs = _ps_adjacent_faces_for_edge(faces, a, b, fi)
                )
                for (nj = nbrs)
                    let(
                        dir_cur = _ps_face_edge_dir(fcur, a, b),
                        dir_n = _ps_face_edge_dir(faces[nj], a, b),
                        desired = (dir_n == dir_cur) ? _ps_reverse(faces[nj]) : faces[nj]
                    )
                    [nj, desired]
        ],
        updated = _ps_apply_neighbors(fixed, neighbors),
        new_queue = concat([for (i = [1:1:len(queue)-1]) queue[i]], _ps_new_neighbor_indices(fixed, neighbors))
    )
    _ps_fix_winding_queue(faces, updated, new_queue);

// Function: _ps_fix_winding_all()
// Usage:
//   result = _ps_fix_winding_all(faces, fixed);
// Description:
//   Fix winding across all connected face components.
//   .
//   - Returns: oriented face list with each shared edge opposite-directed
// Arguments:
//   faces = face list
//   fixed = optional in-progress oriented faces
function _ps_fix_winding_all(faces, fixed=undef) =
    let(
        init = is_undef(fixed) ? [for (i = [0:1:len(faces)-1]) undef] : fixed,
        seed = _ps_index_of_undef(init)
    )
    (seed < 0) ? init :
    _ps_fix_winding_all(
        faces,
        _ps_fix_winding_queue(faces, _ps_list_set(init, seed, faces[seed]), [seed])
    );

// Function: _ps_unique_values()
// Usage:
//   result = _ps_unique_values(list);
// Description:
//   Keep first occurrences from a scalar list.
//   .
//   - Returns: list with duplicate values removed
// Arguments:
//   list = input list
function _ps_unique_values(list) =
    [for (i = [0:1:len(list)-1]) if (_ps_index_of(list, list[i]) == i) list[i]];

// Function: _ps_unique_face_indices()
// Usage:
//   result = _ps_unique_face_indices(list);
// Description:
//   Keep first occurrences from a face-index list.
//   .
//   - Returns: list with duplicate values removed
// Arguments:
//   list = input list
function _ps_unique_face_indices(list) =
    _ps_unique_values(list);

// Function: _ps_face_neighbor_indices()
// Usage:
//   result = _ps_face_neighbor_indices(faces, fi);
// Description:
//   Find face indices that share an edge with one face.
//   .
//   - Returns: adjacent face indices
// Arguments:
//   faces = face list
//   fi = face index
function _ps_face_neighbor_indices(faces, fi) =
    _ps_unique_face_indices([
        for (e = _ps_face_edges_dir(faces[fi]))
            for (fj = _ps_adjacent_faces_for_edge(faces, e[0], e[1], fi))
                fj
    ]);

// Function: _ps_face_component_queue()
// Usage:
//   result = _ps_face_component_queue(faces, component, queue);
// Description:
//   Breadth-first traversal of one connected face component.
//   .
//   - Returns: face indices in one component
// Arguments:
//   faces = face list
//   component = accumulated face indices
//   queue = pending face indices
function _ps_face_component_queue(faces, component, queue) =
    (len(queue) == 0) ? component :
    let(
        fi = queue[0],
        component2 = _ps_list_contains(component, fi) ? component : concat(component, [fi]),
        queue_tail = [for (i = [1:1:len(queue)-1]) if (i < len(queue)) queue[i]],
        nbrs = [
            for (fj = _ps_face_neighbor_indices(faces, fi))
                if (!_ps_list_contains(component2, fj) && !_ps_list_contains(queue_tail, fj))
                    fj
        ]
    )
    _ps_face_component_queue(faces, component2, concat(queue_tail, nbrs));

// Function: _ps_face_components()
// Usage:
//   result = _ps_face_components(faces, seen);
// Description:
//   Partition faces into edge-connected components.
//   .
//   - Returns: `[[face_idx, ...], ...]`
// Arguments:
//   faces = face list
//   seen = optional accumulated face indices
function _ps_face_components(faces, seen=[]) =
    let(
        seeds = [for (i = [0:1:len(faces)-1]) if (!_ps_list_contains(seen, i)) i]
    )
    (len(seeds) == 0) ? [] :
    let(
        comp = _ps_face_component_queue(faces, [], [seeds[0]])
    )
    concat([comp], _ps_face_components(faces, concat(seen, comp)));

// Function: _ps_face_signed_volume6_rhr()
// Usage:
//   result = _ps_face_signed_volume6_rhr(verts, f);
// Description:
//   Compute six times the signed volume contribution of one polygon face,
//   using the conventional right-hand triangle-fan sign.
//   .
//   - Returns: signed scalar; PolySymmetrica/OpenSCAD LHR outward shells have negative total volume
// Arguments:
//   verts = vertex list
//   f = face index loop
function _ps_face_signed_volume6_rhr(verts, f) =
    (len(f) < 3) ? 0 :
    ps_sum([
        for (i = [1:1:len(f)-2])
            v_dot(verts[f[0]], v_cross(verts[f[i]], verts[f[i+1]]))
    ]);

// Function: _ps_faces_signed_volume6_rhr()
// Usage:
//   result = _ps_faces_signed_volume6_rhr(verts, faces);
// Description:
//   Compute six times the signed volume of an oriented face set.
//   .
//   - Returns: signed scalar; negative means LHR outward for closed shells
// Arguments:
//   verts = vertex list
//   faces = face list
function _ps_faces_signed_volume6_rhr(verts, faces) =
    ps_sum([for (f = faces) _ps_face_signed_volume6_rhr(verts, f)]);

// Function: _ps_faces_volume_scale3()
// Usage:
//   result = _ps_faces_volume_scale3(verts, faces);
// Description:
//   Compute a cubic scale for signed-volume orientation tests.
//   .
//   - Returns: smallest positive edge length cubed, or 1 for edgeless input
// Arguments:
//   verts = vertex list
//   faces = face list
function _ps_faces_volume_scale3(verts, faces) =
    let(
        edges = _ps_edges_from_faces(faces),
        edge_lens = [
            for (e = edges)
                let(len = norm(verts[e[1]] - verts[e[0]]))
                if (len > 0) len
        ],
        min_edge = (len(edge_lens) == 0) ? 0 : min(edge_lens)
    )
    (min_edge > 0) ? min_edge * min_edge * min_edge : 1;

// Function: _ps_faces_signed_volume6_normalized_rhr()
// Usage:
//   result = _ps_faces_signed_volume6_normalized_rhr(verts, faces);
// Description:
//   Compute signed `volume6` normalized by local mesh edge scale cubed.
//   .
//   - Returns: dimensionless signed scalar; negative means LHR outward for closed shells
// Arguments:
//   verts = vertex list
//   faces = face list
function _ps_faces_signed_volume6_normalized_rhr(verts, faces) =
    _ps_faces_signed_volume6_rhr(verts, faces) / _ps_faces_volume_scale3(verts, faces);

// Function: _ps_faces_winding_consistent()
// Usage:
//   result = _ps_faces_winding_consistent(faces, strict);
// Description:
//   Check whether all shared edges have opposing directed windings.
//   .
//   - Returns: boolean
// Arguments:
//   faces = face list
//   strict = when true, every undirected edge must appear exactly twice
function _ps_faces_winding_consistent(faces, strict=true) =
    let(
        dir_edges = [
            for (f = faces)
                for (k = [0:1:len(f)-1])
                    let(
                        a = f[k],
                        b = f[(k+1)%len(f)],
                        u = (a < b) ? a : b,
                        v = (a < b) ? b : a,
                        dir = (a < b) ? 1 : -1
                    )
                    [u, v, dir]
        ],
        edges = _ps_edges_from_faces(faces)
    )
    (len(edges) == 0) ? false :
    min([
        for (e = edges)
            let(
                u = e[0],
                v = e[1],
                fwd = len([for (de = dir_edges) if (de[0] == u && de[1] == v && de[2] == 1) 1]),
                back = len([for (de = dir_edges) if (de[0] == u && de[1] == v && de[2] == -1) 1])
            )
            strict ? ((fwd == 1 && back == 1) ? 1 : 0)
                   : ((fwd == back && fwd > 0) ? 1 : 0)
    ]) == 1;

// Function: _ps_faces_semantic_origin_orient()
// Usage:
//   result = _ps_faces_semantic_origin_orient(verts, faces);
// Description:
//   Apply per-face origin orientation only when it already forms a coherent
//   shared-edge winding.
//   .
//   - Returns: oriented face list, or `undef` when the result is inconsistent
// Arguments:
//   verts = vertex list
//   faces = face list
function _ps_faces_semantic_origin_orient(verts, faces) =
    let(oriented = [for (f = faces) ps_orient_face_outward(verts, f)])
    _ps_faces_winding_consistent(oriented, true) ? oriented : undef;

// Function: _ps_faces_for_indices()
// Usage:
//   result = _ps_faces_for_indices(faces, idxs);
// Description:
//   Select faces by index.
//   .
//   - Returns: face sublist
// Arguments:
//   faces = face list
//   idxs = face indices
function _ps_faces_for_indices(faces, idxs) =
    [for (i = idxs) faces[i]];

// Function: _ps_component_oriented_face_pairs()
// Usage:
//   result = _ps_component_oriented_face_pairs(verts, faces, comp, eps);
// Description:
//   Orient one connected face component by normalized signed volume.
//   .
//   - Returns: `[face_idx, oriented_face]` pairs
// Arguments:
//   verts = vertex list
//   faces = topology-consistent face list
//   comp = face-index component
//   eps = normalized signed-volume tolerance
function _ps_component_oriented_face_pairs(verts, faces, comp, eps) =
    let(
        comp_faces = _ps_faces_for_indices(faces, comp),
        vol6 = _ps_faces_signed_volume6_normalized_rhr(verts, comp_faces),
        reverse = vol6 > eps
    )
    [
        for (i = [0:1:len(comp)-1])
            [comp[i], reverse ? _ps_reverse(comp_faces[i]) : comp_faces[i]]
    ];

// Function: _ps_face_pair_value()
// Usage:
//   result = _ps_face_pair_value(pairs, fi);
// Description:
//   Retrieve an oriented face from `[face_idx, face]` pairs.
//   .
//   - Returns: face loop
// Arguments:
//   pairs = `[face_idx, face]` pairs
//   fi = face index
function _ps_face_pair_value(pairs, fi) =
    [for (p = pairs) if (p[0] == fi) p[1]][0];

// Function: _ps_faces_orient_by_signed_volume()
// Usage:
//   result = _ps_faces_orient_by_signed_volume(verts, faces, eps);
// Description:
//   Reverse each connected face component that has right-hand outward signed volume.
//   .
//   - Returns: face list with each component independently oriented
//   .
//   - Limitations/Gotchas: zero-volume/open face sets keep their topology-consistent seed orientation
// Arguments:
//   verts = vertex list
//   faces = topology-consistent face list
//   eps = normalized signed-volume tolerance
function _ps_faces_orient_by_signed_volume(verts, faces, eps=1e-9) =
    let(
        components = _ps_face_components(faces),
        pairs = [
            for (comp = components)
                for (p = _ps_component_oriented_face_pairs(verts, faces, comp, eps))
                    p
        ]
    )
    [for (fi = [0:1:len(faces)-1]) _ps_face_pair_value(pairs, fi)];

///////////////////////////////////////
// ---- List helpers (private) ----
// Function: _ps_list_contains()
// Usage:
//   result = _ps_list_contains(list, v);
// Description:
//   Test whether a list contains a value.
//   .
//   - Returns: boolean
// Arguments:
//   list = input list
//   v = value
function _ps_list_contains(list, v) =
    len(search(v, list)) > 0;

// Function: _ps_index_of()
// Usage:
//   result = _ps_index_of(list, v);
// Description:
//   Find first index of a value.
//   .
//   - Returns: first index, or `-1`
// Arguments:
//   list = input list
//   v = value
function _ps_index_of(list, v) =
    let(idx = search(v, list))
    (len(idx) == 0) ? -1 : idx[0];

// Function: _ps_cycle_rotate()
// Usage:
//   result = _ps_cycle_rotate(list, k);
// Description:
//   Cyclic left rotation helper.
//   .
//   - Returns: rotated sequence
// Arguments:
//   list = sequence
//   k = rotation offset
function _ps_cycle_rotate(list, k) =
    let(n = len(list))
    [for (i = [0:1:n-1]) list[(i + k) % n]];

///////////////////////////////////////
// ---- Vector math ----
// Function: v_add()
// Usage:
//   result = v_add(a, b);
// Description:
//   Add two vectors.
//   .
//   - Returns: `a + b`
// Arguments:
//   a =
//   b = vectors
function v_add(a, b)   = a + b;

// Function: v_sub()
// Usage:
//   result = v_sub(a, b);
// Description:
//   Subtract two vectors.
//   .
//   - Returns: `a - b`
// Arguments:
//   a =
//   b = vectors
function v_sub(a, b)   = a - b;

// Function: v_scale()
// Usage:
//   result = v_scale(a, k);
// Description:
//   Scale a vector.
//   .
//   - Returns: `a * k`
// Arguments:
//   a = vector
//   k = scalar
function v_scale(a, k) = a * k;             // scalar multiplication

// Function: v_dot()
// Usage:
//   result = v_dot(a, b);
// Description:
//   Dot product.
//   .
//   - Returns: scalar dot product
// Arguments:
//   a =
//   b = vectors
function v_dot(a, b)   = a * b;             // dot product

// Function: v_cross()
// Usage:
//   result = v_cross(a, b);
// Description:
//   Cross product.
//   .
//   - Returns: `cross(a,b)`
// Arguments:
//   a =
//   b = 3D vectors
function v_cross(a, b) = cross(a, b);       // OpenSCAD built-in

// Function: v_len()
// Usage:
//   result = v_len(a);
// Description:
//   Vector length.
//   .
//   - Returns: Euclidean norm
// Arguments:
//   a = vector
function v_len(a)      = norm(a);           // built-in length

// Function: v_norm()
// Usage:
//   result = v_norm(a);
// Description:
//   Normalize a vector.
//   .
//   - Returns: unit vector, or zero-like vector when input length is zero
// Arguments:
//   a = vector
function v_norm(a)     = let(L = norm(a)) (L == 0 ? [0,0,0] : a / L);

// Function: _ps_ordered_pair()
// Usage:
//   result = _ps_ordered_pair(a, b);
// Description:
//   Sort two endpoint indices into canonical undirected-edge order.
//   .
//   - Returns: `[min,max]`
// Arguments:
//   a =
//   b = indices
function _ps_ordered_pair(a, b) = (a < b) ? [a,b] : [b,a];


///////////////////////////////////////
// ---- Edge/list primitives ----
// Function: ps_edge_equal()
// Usage:
//   result = ps_edge_equal(e1, e2);
// Description:
//   Test equality of ordered edge records.
//   .
//   - Returns: boolean
// Arguments:
//   e1 =
//   e2 = `[a,b]`
function ps_edge_equal(e1, e2) = (e1[0] == e2[0] && e1[1] == e2[1]);

// Function: ps_sum()
// Usage:
//   result = ps_sum(a, i);
// Description:
//   Sum scalar list entries recursively.
//   .
//   - Returns: scalar sum from `i` to end
// Arguments:
//   a = number list
//   i = start index
function ps_sum(a, i = 0) =
    i >= len(a) ? 0 : a[i] + ps_sum(a, i + 1);

// Function: v_sum()
// Usage:
//   result = v_sum(list);
// Description:
//   Sum a list of equal-dimension vectors.
//   .
//   - Returns: component-wise vector sum; `[]` for empty input
// Arguments:
//   list = vector list
function v_sum(list) =
    (len(list) == 0) ? [] :
    let(n = len(list[0]))
    [ for (i = [0:1:n-1]) ps_sum([for (v = list) v[i]]) ];

// Function: ps_centroid2d()
// Usage:
//   result = ps_centroid2d(points);
// Description:
//   Compute the simple centroid of a 2D point list.
//   .
//   - Returns: centroid `[x, y]`, or `[0, 0]` for an empty list
// Arguments:
//   points = 2D point list
function ps_centroid2d(points) =
    (len(points) == 0) ? [0, 0] :
    v_scale(v_sum(points), 1 / len(points));

// Function: ps_segment_midpoint2d()
// Usage:
//   result = ps_segment_midpoint2d(seg2d);
// Description:
//   Compute the midpoint of a 2D segment.
//   .
//   - Returns: midpoint `[x, y]`
// Arguments:
//   seg2d = `[[x0,y0],[x1,y1]]`
function ps_segment_midpoint2d(seg2d) =
    [(seg2d[0][0] + seg2d[1][0]) / 2, (seg2d[0][1] + seg2d[1][1]) / 2];

// Function: ps_xy()
// Usage:
//   result = ps_xy(points);
// Description:
//   Project points to the XY plane.
//   .
//   - Returns: `[[x, y], ...]`
// Arguments:
//   points = 2D/3D/ND point list
function ps_xy(points) =
    [for (p = points) [p[0], p[1]]];

// Rotate vector v around axis by ang (degrees).
// Function: ps_rot_axis()
// Usage:
//   result = ps_rot_axis(v, axis, ang);
// Description:
//   Rotate a vector around an axis.
//   .
//   - Returns: rotated vector
// Arguments:
//   v = 3D vector
//   axis = 3D axis vector
//   ang = degrees
function ps_rot_axis(v, axis, ang) =
    let(
        a = v_norm(axis),
        c = cos(ang),
        s = sin(ang),
        term1 = v_scale(v, c),
        term2 = v_scale(v_cross(a, v), s),
        term3 = v_scale(a, v_dot(a, v) * (1 - c))
    )
    v_add(v_add(term1, term2), term3);


// Function: ps_find_edge_index()
// Usage:
//   result = ps_find_edge_index(edges, a, b);
// Description:
//   Find an undirected edge in an edge list.
//   .
//   - Returns: edge index
//   .
//   - Limitations/Gotchas: assumes the edge exists
// Arguments:
//   edges = canonical edge list
//   a =
//   b = edge endpoints
function ps_find_edge_index(edges, a, b) =
    let(
        e = _ps_ordered_pair(a, b),
        idxs = [for (i = [0 : len(edges)-1]) if (ps_edge_equal(edges[i], e)) i]
    )
    idxs[0];   // assume the edge exists

// Function: ps_point_eq()
// Usage:
//   result = ps_point_eq(p, q, eps);
// Description:
//   Compare points with tolerance.
//   .
//   - Returns: boolean
// Arguments:
//   p =
//   q = points
//   eps = distance tolerance
function ps_point_eq(p,q,eps) = norm(p-q) <= eps;

// Function: _ps_list_min()
// Usage:
//   result = _ps_list_min(list, i, cur);
// Description:
//   Minimum scalar in a list.
//   .
//   - Returns: minimum value, or `undef` for empty input
// Arguments:
//   list = number list
//   i = scan index
//   cur = current minimum
function _ps_list_min(list, i=0, cur=undef) =
    (i >= len(list)) ? cur :
    let(v = list[i])
    _ps_list_min(list, i+1, is_undef(cur) ? v : (v < cur ? v : cur));

// Function: _ps_remove_first()
// Usage:
//   result = _ps_remove_first(list, v, i);
// Description:
//   Remove the first matching value from a list.
//   .
//   - Returns: list with first occurrence removed
// Arguments:
//   list = input list
//   v = value
//   i = scan index
function _ps_remove_first(list, v, i=0) =
    (i >= len(list)) ? [] :
    (list[i] == v) ? [for (j = [i+1:1:len(list)-1]) list[j]]
                  : concat([list[i]], _ps_remove_first(list, v, i+1));

// Function: _ps_sort()
// Usage:
//   result = _ps_sort(list, acc);
// Description:
//   Sort a scalar list by selection recursion.
//   .
//   - Returns: ascending sorted list
// Arguments:
//   list = input list
//   acc = accumulator
function _ps_sort(list, acc=[]) =
    (len(list) == 0) ? acc :
    let(mn = _ps_list_min(list))
    _ps_sort(_ps_remove_first(list, mn), concat(acc, [mn]));

///////////////////////////////////////
// ---- Polygon/polygram helpers ----
// Function: _ps_gcd()
// Usage:
//   result = _ps_gcd(a, b);
// Description:
//   Compute Euclidean gcd for integer-like values.
//   .
//   - Returns: non-negative integer gcd after rounding
// Arguments:
//   a =
//   b = numbers
function _ps_gcd(a, b) =
    let(ai = abs(round(a)), bi = abs(round(b)))
    (bi == 0) ? ai : _ps_gcd(bi, ai % bi);

// Function: _ps_validate_np()
// Usage:
//   result = _ps_validate_np(n, p, who, allow_compound);
// Description:
//   Validate Schläfli-like polygon/polygram parameters.
//   .
//   - Returns: rounded `[n, p]`
//   .
//   - Limitations/Gotchas: non-coprime `n,p` describes a compound with multiple cycles,
//     and must be explicitly allowed by the caller
// Arguments:
//   n = vertex count
//   p = step
//   who = caller label
//   allow_compound = bool
function _ps_validate_np(n, p, who, allow_compound=false) =
    let(
        n_i = round(n),
        p_i = round(p),
        _n_int = assert(abs(n - n_i) < 1e-9, str(who, ": n must be an integer")),
        _p_int = assert(abs(p - p_i) < 1e-9, str(who, ": p must be an integer")),
        _n_ok = assert(n_i >= 3, str(who, ": n must be >= 3")),
        _p_ok = assert(p_i >= 1 && p_i < n_i, str(who, ": p must satisfy 1 <= p < n")),
        _hemi = assert(2 * p_i != n_i, str(who, ": p=n/2 gives diameter cycles, not polygonal faces")),
        _cop = assert(allow_compound || _ps_gcd(n_i, p_i) == 1, str(who, ": n and p must be coprime unless compounds are supported"))
    )
    [n_i, p_i];

// Function: _ps_polygram_radius()
// Usage:
//   result = _ps_polygram_radius(n, p, edge);
// Description:
//   Circumradius for regular/star polygon `{n,p}`.
//   .
//   - Returns: radius scalar
// Arguments:
//   n = vertex count
//   p = step
//   edge = chord length
function _ps_polygram_radius(n, p, edge) =
    edge / (2 * sin(180 * p / n));

// Function: _ps_polygram_signed_step()
// Usage:
//   result = _ps_polygram_signed_step(n, p);
// Description:
//   Signed representative of a polygram step.
//   .
//   - Returns: `p` for forward steps, or `p-n` for retrograde steps
// Arguments:
//   n = vertex count
//   p = step
function _ps_polygram_signed_step(n, p) =
    (2 * p > n) ? (p - n) : p;

// Function: _ps_ngon_radius()
// Usage:
//   result = _ps_ngon_radius(n, edge);
// Description:
//   Circumradius for regular polygon `{n,1}`.
//   .
//   - Returns: radius scalar
// Arguments:
//   n = vertex count
//   edge = edge length
function _ps_ngon_radius(n, edge) =
    _ps_polygram_radius(n, 1, edge);

// Function: _ps_polygram_cycle()
// Usage:
//   result = _ps_polygram_cycle(n, p);
// Description:
//   Vertex order for the first cycle of polygram `{n,p}`.
//   .
//   - Returns: index cycle `[(k*p)%n, ...]`; length is `n/gcd(n,p)`
// Arguments:
//   n = vertex count
//   p = step
function _ps_polygram_cycle(n, p) =
    let(cycle_len = n / _ps_gcd(n, p))
    [for (k = [0:1:cycle_len-1]) (k * p) % n];

// Function: _ps_polygram_cycles()
// Usage:
//   result = _ps_polygram_cycles(n, p);
// Description:
//   Vertex orders for all cycles of polygram `{n,p}`.
//   .
//   - Returns: list of index cycles; non-coprime `n,p` returns a compound
// Arguments:
//   n = vertex count
//   p = step
function _ps_polygram_cycles(n, p) =
    let(
        g = _ps_gcd(n, p),
        cycle_len = n / g
    )
    [
        for (start = [0:1:g-1])
            [for (k = [0:1:cycle_len-1]) (start + k * p) % n]
    ];

// Function: _ps_ngon_ring()
// Usage:
//   result = _ps_ngon_ring(n, radius, z, phase);
// Description:
//   Generate a regular support ring at fixed Z.
//   .
//   - Returns: 3D point ring
// Arguments:
//   n = vertex count
//   radius = ring radius
//   z = Z coordinate
//   phase = degrees
function _ps_ngon_ring(n, radius, z, phase=0) =
    [for (k = [0:1:n-1]) [radius * cos(360 * k / n + phase), radius * sin(360 * k / n + phase), z]];

// Function: _ps_poly_mid_center()
// Usage:
//   result = _ps_poly_mid_center(verts, faces);
// Description:
//   Compute mean edge-midpoint center for a mesh.
//   .
//   - Returns: center point
// Arguments:
//   verts = 3D vertices
//   faces = face loops
function _ps_poly_mid_center(verts, faces) =
    let(
        edges = _ps_edges_from_faces(faces),
        mids = [for (e = edges) (verts[e[0]] + verts[e[1]]) / 2],
        _ok = assert(len(mids) > 0, "poly: edge-midpoint center requires at least one edge")
    )
    v_scale(v_sum(mids), 1 / len(mids));

// Function: _ps_poly_ir()
// Usage:
//   result = _ps_poly_ir(verts, faces);
// Description:
//   Compute inter-radius from minimum centered edge-midpoint radius.
//   .
//   - Returns: positive inter-radius
// Arguments:
//   verts = 3D vertices
//   faces = face loops
function _ps_poly_ir(verts, faces) =
    let(
        edges = _ps_edges_from_faces(faces),
        center = _ps_poly_mid_center(verts, faces),
        verts_centered = [for (v = verts) v - center],
        mids = [for (e = edges) norm((verts_centered[e[0]] + verts_centered[e[1]]) / 2)],
        ir = min(mids),
        _ok = assert(ir > 0, "poly: inter-radius must be > 0")
    ) ir;

///////////////////////////////////////
// ---- Linear algebra helpers ----
// Function: _ps_det3()
// Usage:
//   result = _ps_det3(m);
// Description:
//   Determinant of a 3x3 matrix.
//   .
//   - Returns: determinant scalar
// Arguments:
//   m = 3x3 matrix
function _ps_det3(m) =
    m[0][0]*(m[1][1]*m[2][2] - m[1][2]*m[2][1]) -
    m[0][1]*(m[1][0]*m[2][2] - m[1][2]*m[2][0]) +
    m[0][2]*(m[1][0]*m[2][1] - m[1][1]*m[2][0]);

// Function: _ps_replace_col()
// Usage:
//   result = _ps_replace_col(m, col, b);
// Description:
//   Replace one column in a 3x3 matrix.
//   .
//   - Returns: updated 3x3 matrix
// Arguments:
//   m = 3x3 matrix
//   col = column index 0..2
//   b = replacement column
function _ps_replace_col(m, col, b) =
    [
        [ col == 0 ? b[0] : m[0][0], col == 1 ? b[0] : m[0][1], col == 2 ? b[0] : m[0][2] ],
        [ col == 0 ? b[1] : m[1][0], col == 1 ? b[1] : m[1][1], col == 2 ? b[1] : m[1][2] ],
        [ col == 0 ? b[2] : m[2][0], col == 1 ? b[2] : m[2][1], col == 2 ? b[2] : m[2][2] ]
    ];

// Function: _ps_solve3()
// Usage:
//   result = _ps_solve3(m, b, eps);
// Description:
//   Solve a 3x3 linear system with Cramer's rule.
//   .
//   - Returns: solution `[x0,x1,x2]`, or `undef` for near-singular systems
// Arguments:
//   m = 3x3 matrix
//   b = right-hand vector
//   eps = singularity tolerance
function _ps_solve3(m, b, eps=1e-12) =
    let(det = _ps_det3(m))
    (abs(det) < eps) ? undef
  : [
        _ps_det3(_ps_replace_col(m, 0, b)) / det,
        _ps_det3(_ps_replace_col(m, 1, b)) / det,
        _ps_det3(_ps_replace_col(m, 2, b)) / det
    ];

///////////////////////////////////////
// ---- Prefix offsets / face offsets ----
// Function: _ps_prefix_offsets()
// Usage:
//   result = _ps_prefix_offsets(counts, acc);
// Description:
//   Build prefix offsets from a count list.
//   .
//   - Returns: offsets such as `[0, c0, c0+c1, ...]` when seeded with `[0]`
// Arguments:
//   counts = non-negative counts
//   acc = offset accumulator
function _ps_prefix_offsets(counts, acc=[]) =
    (len(counts) == 0) ? acc :
    let(last = (len(acc) == 0) ? 0 : acc[len(acc)-1])
    _ps_prefix_offsets(
        [for (i = [1:1:len(counts)-1]) counts[i]],
        concat(acc, [last + counts[0]])
    );

// Function: _ps_face_offsets()
// Usage:
//   result = _ps_face_offsets(faces);
// Description:
//   Prefix offsets for concatenated face vertices.
//   .
//   - Returns: offsets by face
// Arguments:
//   faces = face list
function _ps_face_offsets(faces) =
    let(counts = [for (f = faces) len(f)])
    _ps_prefix_offsets(counts, [0]);

// Function: _ps_face_edge_offsets()
// Usage:
//   result = _ps_face_edge_offsets(faces);
// Description:
//   Prefix offsets for concatenated directed face edges.
//   .
//   - Returns: offsets by face, counting two directed half-edges per edge
// Arguments:
//   faces = face list
function _ps_face_edge_offsets(faces) =
    let(counts = [for (f = faces) 2 * len(f)])
    _ps_prefix_offsets(counts, [0]);


///////////////////////////////////////
// ---- Polygon helpers ----
// Function: ps_calc_edge()
// Usage:
//   result = ps_calc_edge(n_vertex, rad);
// Description:
//   Compute regular polygon edge length from radius.
//   .
//   - Returns: edge length
// Arguments:
//   n_vertex = vertex count
//   rad = circumradius
function ps_calc_edge(n_vertex, rad) = 2 * rad * sin(180 / n_vertex);

// Function: ps_calc_radius()
// Usage:
//   result = ps_calc_radius(n_vertex, edge_len);
// Description:
//   Compute regular polygon circumradius from edge length.
//   .
//   - Returns: radius scalar
// Arguments:
//   n_vertex = vertex count
//   edge_len = edge length
function ps_calc_radius(n_vertex, edge_len) = edge_len / (2 * sin(180 / n_vertex));


///////////////////////////////////////
// ---- Geometry helpers ----
// Function: ps_face_centroid()
// Usage:
//   result = ps_face_centroid(verts, f);
// Description:
//   Compute mean vertex centroid for one face.
//   .
//   - Returns: 3D centroid, or `[0,0,0]` for empty face
// Arguments:
//   verts = 3D vertex list
//   f = face index loop
function ps_face_centroid(verts, f) =
    len(f) == 0
        ? [0,0,0]
        : v_scale(v_sum([for (vid = f) verts[vid]]), 1 / len(f));

// Function: ps_face_normal()
// Usage:
//   result = ps_face_normal(verts, f);
// Description:
//   Compute topological face normal using OpenSCAD LHR winding.
//   .
//   - Returns: unit normal direction
//   .
//   - Limitations/Gotchas: uses first three vertices; use `ps_face_frame_normal(...)` for non-planar placement frames
// Arguments:
//   verts = 3D vertex list
//   f = face index loop
function ps_face_normal(verts, f) =
    // OpenSCAD expects LHR (clockwise from outside), so flip cross product.
    v_norm(v_cross(
        verts[f[2]] - verts[f[0]],
        verts[f[1]] - verts[f[0]]
    ));

// Function: ps_face_frame_normal()
// Usage:
//   result = ps_face_frame_normal(verts, f, eps);
// Description:
//   Compute placement frame normal for a face.
//   .
//   - Returns: unit normal direction aligned with `ps_face_normal(...)`
//   .
//   - Limitations/Gotchas: uses Newell-style best-fit normal for non-planar faces
//     and follows the project/OpenSCAD LHR winding convention even when the
//     first three vertices are collinear.
// Arguments:
//   verts = 3D vertex list
//   f = face index loop
//   eps = degeneracy tolerance
function ps_face_frame_normal(verts, f, eps=1e-12) =
    let(
        n = len(f),
        nx = (n < 3) ? 0 : ps_sum([
            for (i = [0:1:n-1])
                let(
                    j = (i + 1) % n,
                    pi = verts[f[i]],
                    pj = verts[f[j]]
                )
                (pi[1] - pj[1]) * (pi[2] + pj[2])
        ]),
        ny = (n < 3) ? 0 : ps_sum([
            for (i = [0:1:n-1])
                let(
                    j = (i + 1) % n,
                    pi = verts[f[i]],
                    pj = verts[f[j]]
                )
                (pi[2] - pj[2]) * (pi[0] + pj[0])
        ]),
        nz = (n < 3) ? 0 : ps_sum([
            for (i = [0:1:n-1])
                let(
                    j = (i + 1) % n,
                    pi = verts[f[i]],
                    pj = verts[f[j]]
                )
                (pi[0] - pj[0]) * (pi[1] + pj[1])
        ]),
        // Newell's formula gives the conventional right-hand normal. The rest
        // of PolySymmetrica follows OpenSCAD's left-hand face winding.
        n_newell = [-nx, -ny, -nz],
        n_topo = ps_face_normal(verts, f),
        n_raw = (norm(n_newell) > eps) ? n_newell : n_topo,
        n_aligned = (v_dot(n_raw, n_topo) < 0) ? [-n_raw[0], -n_raw[1], -n_raw[2]] : n_raw
    )
    v_norm(n_aligned);

function _ps_face_area_projected_term(a, b, axis) =
    (axis == 0) ? (a[1] * b[2] - b[1] * a[2]) :
    (axis == 1) ? (a[2] * b[0] - b[2] * a[0]) :
                  (a[0] * b[1] - b[0] * a[1]);

function _ps_face_area2_vector(verts, f) =
    let(o = verts[f[0]])
    [
        for (axis = [0:1:2])
            ps_sum([
                for (i = [0:1:len(f)-1])
                    _ps_face_area_projected_term(
                        verts[f[i]] - o,
                        verts[f[(i+1)%len(f)]] - o,
                        axis
                    )
            ])
    ];

// Function: _ps_face_area_mag()
// Usage:
//   result = _ps_face_area_mag(verts, f);
// Description:
//   Compute face area magnitude from the projected boundary area vector.
//   .
//   - Returns: non-negative area
//   .
//   - Limitations/Gotchas: intended for planar simple faces; self-crossing
//     boundary area follows signed polygon-area cancellation
// Arguments:
//   verts = 3D vertex list
//   f = face index loop
function _ps_face_area_mag(verts, f) =
    (len(f) < 3) ? 0 :
    norm(_ps_face_area2_vector(verts, f)) / 2;

// Function: _ps_face_planarity_err()
// Usage:
//   result = _ps_face_planarity_err(verts, f, eps);
// Description:
//   Compute maximum vertex deviation from a face plane.
//   .
//   - Returns: maximum absolute signed-distance error
// Arguments:
//   verts = 3D vertex list
//   f = face index loop
//   eps = normal tolerance
function _ps_face_planarity_err(verts, f, eps=1e-12) =
    (len(f) < 3) ? 0 :
    let(
        n_raw = ps_face_frame_normal(verts, f, eps),
        n_len = norm(n_raw),
        n = (n_len <= eps) ? [0,0,1] : (n_raw / n_len),
        d = v_dot(n, verts[f[0]]),
        errs = [for (vi = f) abs(v_dot(n, verts[vi]) - d)]
    )
    (len(errs) == 0) ? 0 : max(errs);

// Function: _ps_faces_max_planarity_err()
// Usage:
//   result = _ps_faces_max_planarity_err(verts, faces, eps);
// Description:
//   Compute maximum planarity error over a face list.
//   .
//   - Returns: maximum face planarity error
// Arguments:
//   verts = 3D vertex list
//   faces = face list
//   eps = normal tolerance
function _ps_faces_max_planarity_err(verts, faces, eps=1e-12) =
    (len(faces) == 0) ? 0 : max([for (f = faces) _ps_face_planarity_err(verts, f, eps)]);

///////////////////////////////////////
// ---- Topology helpers ----
// Function: _ps_edges_from_faces()
// Usage:
//   result = _ps_edges_from_faces(faces);
// Description:
//   Build unique undirected edges from a face list.
//   .
//   - Returns: canonical edge list `[[min,max], ...]`
// Arguments:
//   faces = face index loops
function _ps_edges_from_faces(faces) =
    let(
        raw_edges = [
            for (fi = [0 : len(faces)-1])
                let(f = faces[fi])
                    for (k = [0 : len(f)-1])
                        let(
                            a = f[k],
                            b = f[(k+1) % len(f)],
                            e = (a < b) ? [a,b] : [b,a]
                        ) e
        ],
        uniq_edges = [
            for (i = [0 : len(raw_edges)-1])
                let(ei = raw_edges[i])
                    if (len([
                            for (j = [0 : 1 : i-1])
                                if (ps_edge_equal(raw_edges[j], ei)) 1
                        ]) == 0) ei
        ]
    )
    uniq_edges;


// Function: ps_edge_faces_table()
// Usage:
//   result = ps_edge_faces_table(faces, edges);
// Description:
//   Map each edge to incident faces.
//   .
//   - Returns: `[[face_idx, ...], ...]` matching `edges`
// Arguments:
//   faces = face list
//   edges = canonical edge list
function ps_edge_faces_table(faces, edges) =
    [
        for (ei = [0 : len(edges)-1])
            let(e = edges[ei])
            [
                for (fi = [0 : len(faces)-1])
                    if (ps_face_has_edge(faces[fi], e[0], e[1])) fi
            ]
    ];

// Function: ps_face_has_edge()
// Usage:
//   result = ps_face_has_edge(f, a, b);
// Description:
//   Test whether a face contains an undirected edge.
//   .
//   - Returns: boolean
// Arguments:
//   f = face index loop
//   a =
//   b = edge endpoints
function ps_face_has_edge(f, a, b) =
    len([
        for (k = [0 : len(f)-1])
            let(
                x = f[k],
                y = f[(k+1) % len(f)]
            )
            if ((x==a && y==b) || (x==b && y==a)) 1
    ]) > 0;

///////////////////////////////////////
// ---- Frame/placement helpers ----
// Function: poly_face_center()
// Usage:
//   result = poly_face_center(poly, fi, scale);
// Description:
//   Compute scaled face center for placement.
//   .
//   - Returns: 3D center point
// Arguments:
//   poly = poly descriptor
//   fi = face index
//   scale = scale factor
function poly_face_center(poly, fi, scale) =
    let(
        f   = poly_faces(poly)[fi],
        vs  = poly_verts(poly),
        xs  = [ for (vid = f) vs[vid][0] * scale ],
        ys  = [ for (vid = f) vs[vid][1] * scale ],
        zs  = [ for (vid = f) vs[vid][2] * scale ]
    )
    [
        ps_sum(xs) / len(f),
        ps_sum(ys) / len(f),
        ps_sum(zs) / len(f)
    ];


// Function: poly_face_ex()
// Usage:
//   result = poly_face_ex(poly, fi, scale);
// Description:
//   Compute local face-frame X axis for placement.
//   .
//   - Returns: unit 3D X-axis vector in world/poly coordinates
//   .
//   - Limitations/Gotchas: candidate axis is projected into the face plane to remain orthonormal for non-planar faces
// Arguments:
//   poly = poly descriptor
//   fi = face index
//   scale = scale factor
function poly_face_ex(poly, fi, scale) =
    let(f      = poly_faces(poly)[fi],
        vs     = poly_verts(poly),
        center = poly_face_center(poly, fi, scale),
        v0     = vs[f[0]] * scale,
        ez     = poly_face_ez(poly, fi, scale),
        ex_raw = v0 - center,
        // Keep face frame orthonormal even for non-planar faces:
        // project candidate x-axis into the local face plane.
        ex_proj = ex_raw - ez * v_dot(ex_raw, ez),
        ex_fallback_raw = (vs[f[1]] * scale) - (vs[f[0]] * scale),
        ex_fallback = ex_fallback_raw - ez * v_dot(ex_fallback_raw, ez))
    (norm(ex_proj) > 1e-12)
        ? v_norm(ex_proj)
        : v_norm(ex_fallback);   // local +X points towards face vertex order


// Function: poly_face_ey()
// Usage:
//   result = poly_face_ey(poly, fi, scale);
// Description:
//   Compute local face-frame Y axis for placement.
//   .
//   - Returns: unit 3D Y-axis vector
// Arguments:
//   poly = poly descriptor
//   fi = face index
//   scale = scale factor
function poly_face_ey(poly, fi, scale) =
    v_cross(
        poly_face_ez(poly, fi, scale),
        poly_face_ex(poly, fi, scale)
    );


// Function: poly_face_ez()
// Usage:
//   result = poly_face_ez(poly, fi, scale);
// Description:
//   Compute local face-frame Z axis for placement.
//   .
//   - Returns: unit 3D Z-axis vector
// Arguments:
//   poly = poly descriptor
//   fi = face index
//   scale = scale factor
function poly_face_ez(poly, fi, scale) =
    let(f  = poly_faces(poly)[fi],
        vs = poly_verts(poly),
        vs_scaled = [for (v = vs) v * scale])
    // Frame +Z for placement; best-fit for non-planar faces, aligned to LHR.
    ps_face_frame_normal(vs_scaled, f);


// Function: ps_frame_matrix()
// Usage:
//   result = ps_frame_matrix(center, ex, ey, ez);
// Description:
//   Build a 4x4 transform matrix from frame axes and center.
//   .
//   - Returns: OpenSCAD `multmatrix`-compatible matrix
// Arguments:
//   center = translation
//   ex = basis vectors
//   ey = basis vectors
//   ez = basis vectors
function ps_frame_matrix(center, ex, ey, ez) = [
    [ex[0], ey[0], ez[0], center[0]],
    [ex[1], ey[1], ez[1], center[1]],
    [ex[2], ey[2], ez[2], center[2]],
    [0,      0,     0,     1]
];

// Function: ps_placement_frame()
// Usage:
//   result = ps_placement_frame(center, ex, ey, ez);
// Description:
//   Build a semantic placement-frame record.
//   .
//   - Returns: placement frame `[center, ex, ey, ez]`
//   .
//   - Limitations/Gotchas: stores axes as supplied; callers remain responsible for orthonormal frame construction
// Arguments:
//   center = origin in parent coordinates
//   ex = orthonormal axes in parent coordinates
//   ey = orthonormal axes in parent coordinates
//   ez = orthonormal axes in parent coordinates
function ps_placement_frame(center, ex, ey, ez) = [center, ex, ey, ez];

// Function: ps_placement_frame_center()
// Usage:
//   result = ps_placement_frame_center(frame);
// Description:
//   Get center from a placement-frame record.
//   .
//   - Returns: origin in parent coordinates
// Arguments:
//   frame = placement frame
function ps_placement_frame_center(frame) = frame[0];

// Function: ps_placement_frame_ex()
// Usage:
//   result = ps_placement_frame_ex(frame);
// Description:
//   Get local X axis from a placement-frame record.
//   .
//   - Returns: unit X axis in parent coordinates
// Arguments:
//   frame = placement frame
function ps_placement_frame_ex(frame) = frame[1];

// Function: ps_placement_frame_ey()
// Usage:
//   result = ps_placement_frame_ey(frame);
// Description:
//   Get local Y axis from a placement-frame record.
//   .
//   - Returns: unit Y axis in parent coordinates
// Arguments:
//   frame = placement frame
function ps_placement_frame_ey(frame) = frame[2];

// Function: ps_placement_frame_ez()
// Usage:
//   result = ps_placement_frame_ez(frame);
// Description:
//   Get local Z axis from a placement-frame record.
//   .
//   - Returns: unit Z axis in parent coordinates
// Arguments:
//   frame = placement frame
function ps_placement_frame_ez(frame) = frame[3];

// Function: ps_placement_frame_matrix()
// Usage:
//   result = ps_placement_frame_matrix(frame);
// Description:
//   Convert a placement-frame record to an OpenSCAD transform matrix.
//   .
//   - Returns: matrix compatible with `multmatrix(...)`
// Arguments:
//   frame = placement frame
function ps_placement_frame_matrix(frame) =
    ps_frame_matrix(
        ps_placement_frame_center(frame),
        ps_placement_frame_ex(frame),
        ps_placement_frame_ey(frame),
        ps_placement_frame_ez(frame)
    );

// Function: ps_placement_frame_describe_str()
// Usage:
//   result = ps_placement_frame_describe_str(frame, detail, kvpair_to_str, field_sep);
// Description:
//   Build a description string for a placement frame.
//   .
//   - Returns: description string
// Arguments:
//   frame = placement frame
//   detail = detail level
//   kvpair_to_str = optional key/value formatter
//   field_sep = field separator
function ps_placement_frame_describe_str(frame, detail=0, kvpair_to_str=undef, field_sep=", ") =
    ps_describe_record_str(
        "PlacementFrame",
        [
            ps_describe_kvpair_str("center", ps_placement_frame_center(frame), kvpair_to_str),
            ps_describe_kvpair_str("ex", ps_placement_frame_ex(frame), kvpair_to_str),
            ps_describe_kvpair_str("ey", ps_placement_frame_ey(frame), kvpair_to_str),
            ps_describe_kvpair_str("ez", ps_placement_frame_ez(frame), kvpair_to_str)
        ],
        detail,
        undef,
        field_sep
    );

// Module: ps_placement_frame_describe()
// Usage:
//   ps_placement_frame_describe(frame, detail, kvpair_to_str, field_sep);
// Description:
//   Echo a placement frame description.
//   .
//   - Returns: none
// Arguments:
//   frame = placement frame
//   detail = detail level
//   kvpair_to_str = optional key/value formatter
//   field_sep = field separator
module ps_placement_frame_describe(frame, detail=0, kvpair_to_str=undef, field_sep=", ") {
    echo(ps_placement_frame_describe_str(frame, detail, kvpair_to_str, field_sep));
}

// Function: ps_target_local_poly_context()
// Usage:
//   result = ps_target_local_poly_context(poly_faces_idx, poly_verts_local, poly_center_local);
// Description:
//   Build a target-local poly context record.
//   .
//   - Returns: target-local poly context `[poly_faces_idx, poly_verts_local, poly_center_local]`
// Arguments:
//   poly_faces_idx = poly face index loops
//   poly_verts_local = poly vertices in target-local coordinates
//   poly_center_local = optional poly center in target-local coordinates
function ps_target_local_poly_context(poly_faces_idx, poly_verts_local, poly_center_local=undef) =
    [
        poly_faces_idx,
        poly_verts_local,
        is_undef(poly_center_local) ? [0, 0, 0] : poly_center_local
    ];

// Function: ps_target_local_poly_context_faces_idx()
// Usage:
//   result = ps_target_local_poly_context_faces_idx(ctx);
// Description:
//   Get face index loops from a target-local poly context.
//   .
//   - Returns: poly face index loops
// Arguments:
//   ctx = target-local poly context
function ps_target_local_poly_context_faces_idx(ctx) = ctx[0];

// Function: ps_target_local_poly_context_verts_local()
// Usage:
//   result = ps_target_local_poly_context_verts_local(ctx);
// Description:
//   Get local vertices from a target-local poly context.
//   .
//   - Returns: poly vertices in target-local coordinates
// Arguments:
//   ctx = target-local poly context
function ps_target_local_poly_context_verts_local(ctx) = ctx[1];

// Function: ps_target_local_poly_context_center_local()
// Usage:
//   result = ps_target_local_poly_context_center_local(ctx);
// Description:
//   Get local poly center from a target-local poly context.
//   .
//   - Returns: poly center in target-local coordinates
// Arguments:
//   ctx = target-local poly context
function ps_target_local_poly_context_center_local(ctx) = ctx[2];

// Function: ps_target_local_poly_context_describe_str()
// Usage:
//   result = ps_target_local_poly_context_describe_str(ctx, detail, kvpair_to_str, field_sep);
// Description:
//   Build a description string for a target-local poly context.
//   .
//   - Returns: description string
// Arguments:
//   ctx = target-local poly context
//   detail = detail level
//   kvpair_to_str = optional key/value formatter
//   field_sep = field separator
function ps_target_local_poly_context_describe_str(ctx, detail=0, kvpair_to_str=undef, field_sep=", ") =
    ps_describe_record_str(
        "TargetLocalPolyContext",
        [
            ps_describe_kvpair_str("face_count", len(ps_target_local_poly_context_faces_idx(ctx)), kvpair_to_str),
            ps_describe_kvpair_str("vert_count", len(ps_target_local_poly_context_verts_local(ctx)), kvpair_to_str),
            ps_describe_kvpair_str("center_local", ps_target_local_poly_context_center_local(ctx), kvpair_to_str)
        ],
        detail,
        [
            ps_describe_kvpair_str("faces_idx", ps_target_local_poly_context_faces_idx(ctx), kvpair_to_str),
            ps_describe_kvpair_str("verts_local", ps_target_local_poly_context_verts_local(ctx), kvpair_to_str)
        ],
        field_sep
    );

// Module: ps_target_local_poly_context_describe()
// Usage:
//   ps_target_local_poly_context_describe(ctx, detail, kvpair_to_str, field_sep);
// Description:
//   Echo a target-local poly context description.
//   .
//   - Returns: none
// Arguments:
//   ctx = target-local poly context
//   detail = detail level
//   kvpair_to_str = optional key/value formatter
//   field_sep = field separator
module ps_target_local_poly_context_describe(ctx, detail=0, kvpair_to_str=undef, field_sep=", ") {
    echo(ps_target_local_poly_context_describe_str(ctx, detail, kvpair_to_str, field_sep));
}

// Function: ps_face_local_context()
// Usage:
//   result = ps_face_local_context(face_pts3d_local, face_pts2d, face_idx, poly_faces_idx, poly_verts_local, face_neighbors_idx, face_dihedrals, poly_center_local);
// Description:
//   Build a face-local context record for nested face operations.
//   .
//   - Returns: face-local context `[face_pts3d_local, face_pts2d, face_idx, target_ctx, face_neighbors_idx, face_dihedrals]`
// Arguments:
//   face_pts3d_local = face vertices in target face-local 3D
//   face_pts2d = face vertices in target face-local XY
//   face_idx = source face index
//   poly_faces_idx = target-local poly topology/vertices
//   poly_verts_local = target-local poly topology/vertices
//   face_neighbors_idx = optional adjacent face ids
//   face_dihedrals = optional edge dihedrals
//   poly_center_local = optional poly center in target-local coordinates
function ps_face_local_context(
    face_pts3d_local,
    face_pts2d,
    face_idx,
    poly_faces_idx,
    poly_verts_local,
    face_neighbors_idx=undef,
    face_dihedrals=undef,
    poly_center_local=undef
) =
    [
        face_pts3d_local,
        face_pts2d,
        face_idx,
        ps_target_local_poly_context(poly_faces_idx, poly_verts_local, poly_center_local),
        face_neighbors_idx,
        face_dihedrals
    ];

// Function: ps_face_local_context_pts3d_local()
// Usage:
//   result = ps_face_local_context_pts3d_local(ctx);
// Description:
//   Get face-local 3D vertices from a face-local context.
//   .
//   - Returns: face vertices in target face-local 3D
// Arguments:
//   ctx = face-local context
function ps_face_local_context_pts3d_local(ctx) = ctx[0];

// Function: ps_face_local_context_pts2d()
// Usage:
//   result = ps_face_local_context_pts2d(ctx);
// Description:
//   Get face-local 2D vertices from a face-local context.
//   .
//   - Returns: face vertices in target face-local XY
// Arguments:
//   ctx = face-local context
function ps_face_local_context_pts2d(ctx) = ctx[1];

// Function: ps_face_local_context_idx()
// Usage:
//   result = ps_face_local_context_idx(ctx);
// Description:
//   Get source face index from a face-local context.
//   .
//   - Returns: source face index
// Arguments:
//   ctx = face-local context
function ps_face_local_context_idx(ctx) = ctx[2];

// Function: ps_face_local_context_target_local_poly_context()
// Usage:
//   result = ps_face_local_context_target_local_poly_context(ctx);
// Description:
//   Get target-local poly context from a face-local context.
//   .
//   - Returns: nested target-local poly context
// Arguments:
//   ctx = face-local context
function ps_face_local_context_target_local_poly_context(ctx) = ctx[3];

// Function: ps_face_local_context_poly_faces_idx()
// Usage:
//   result = ps_face_local_context_poly_faces_idx(ctx);
// Description:
//   Get target-local face index loops from a face-local context.
//   .
//   - Returns: poly face index loops
// Arguments:
//   ctx = face-local context
function ps_face_local_context_poly_faces_idx(ctx) =
    ps_target_local_poly_context_faces_idx(ps_face_local_context_target_local_poly_context(ctx));

// Function: ps_face_local_context_poly_verts_local()
// Usage:
//   result = ps_face_local_context_poly_verts_local(ctx);
// Description:
//   Get target-local vertices from a face-local context.
//   .
//   - Returns: poly vertices in target-local coordinates
// Arguments:
//   ctx = face-local context
function ps_face_local_context_poly_verts_local(ctx) =
    ps_target_local_poly_context_verts_local(ps_face_local_context_target_local_poly_context(ctx));

// Function: ps_face_local_context_poly_center_local()
// Usage:
//   result = ps_face_local_context_poly_center_local(ctx);
// Description:
//   Get target-local poly center from a face-local context.
//   .
//   - Returns: poly center in target-local coordinates
// Arguments:
//   ctx = face-local context
function ps_face_local_context_poly_center_local(ctx) =
    ps_target_local_poly_context_center_local(ps_face_local_context_target_local_poly_context(ctx));

// Function: ps_face_local_context_neighbors_idx()
// Usage:
//   result = ps_face_local_context_neighbors_idx(ctx);
// Description:
//   Get neighboring face indices from a face-local context.
//   .
//   - Returns: adjacent face index per source face edge, or `undef`
// Arguments:
//   ctx = face-local context
function ps_face_local_context_neighbors_idx(ctx) = ctx[4];

// Function: ps_face_local_context_dihedrals()
// Usage:
//   result = ps_face_local_context_dihedrals(ctx);
// Description:
//   Get edge dihedrals from a face-local context.
//   .
//   - Returns: dihedral metadata per source face edge, or `undef`
// Arguments:
//   ctx = face-local context
function ps_face_local_context_dihedrals(ctx) = ctx[5];

// Function: ps_face_local_context_describe_str()
// Usage:
//   result = ps_face_local_context_describe_str(ctx, detail, kvpair_to_str, field_sep);
// Description:
//   Build a description string for a face-local context.
//   .
//   - Returns: description string
// Arguments:
//   ctx = face-local context
//   detail = detail level
//   kvpair_to_str = optional key/value formatter
//   field_sep = field separator
function ps_face_local_context_describe_str(ctx, detail=0, kvpair_to_str=undef, field_sep=", ") =
    ps_describe_record_str(
        "FaceLocalContext",
        [
            ps_describe_kvpair_str("face_idx", ps_face_local_context_idx(ctx), kvpair_to_str),
            ps_describe_kvpair_str("vertex_count", len(ps_face_local_context_pts2d(ctx)), kvpair_to_str),
            ps_describe_kvpair_str("neighbor_count", _ps_describe_count(ps_face_local_context_neighbors_idx(ctx)), kvpair_to_str),
            ps_describe_kvpair_str("dihedral_count", _ps_describe_count(ps_face_local_context_dihedrals(ctx)), kvpair_to_str)
        ],
        detail,
        [
            ps_describe_kvpair_str("pts3d_local", ps_face_local_context_pts3d_local(ctx), kvpair_to_str),
            ps_describe_kvpair_str("pts2d", ps_face_local_context_pts2d(ctx), kvpair_to_str),
            ps_describe_kvpair_str("target_local_poly_context", ps_target_local_poly_context_describe_str(ps_face_local_context_target_local_poly_context(ctx), max(0, detail - 1), kvpair_to_str, field_sep), kvpair_to_str),
            ps_describe_kvpair_str("neighbors_idx", ps_face_local_context_neighbors_idx(ctx), kvpair_to_str),
            ps_describe_kvpair_str("dihedrals", ps_face_local_context_dihedrals(ctx), kvpair_to_str)
        ],
        field_sep
    );

// Module: ps_face_local_context_describe()
// Usage:
//   ps_face_local_context_describe(ctx, detail, kvpair_to_str, field_sep);
// Description:
//   Echo a face-local context description.
//   .
//   - Returns: none
// Arguments:
//   ctx = face-local context
//   detail = detail level
//   kvpair_to_str = optional key/value formatter
//   field_sep = field separator
module ps_face_local_context_describe(ctx, detail=0, kvpair_to_str=undef, field_sep=", ") {
    echo(ps_face_local_context_describe_str(ctx, detail, kvpair_to_str, field_sep));
}


// Function: ps_orient_face_outward()
// Usage:
//   result = ps_orient_face_outward(verts, f);
// Description:
//   Orient one face so its normal points away from origin.
//   .
//   - Returns: original or reversed face loop
//   .
//   - Limitations/Gotchas: origin-relative heuristic; appropriate for centered radial polyhedra
// Arguments:
//   verts = 3D vertex list
//   f = face index loop
function ps_orient_face_outward(verts, f) =
    let(
        c = ps_face_centroid(verts, f),
        n = ps_face_normal(verts, f)
    )
    (v_dot(c, n) >= 0)
        ? f
        : _ps_reverse(f);  // reversed

// Function: ps_orient_all_faces_outward()
// Usage:
//   result = ps_orient_all_faces_outward(verts, faces, eps);
// Description:
//   Orient all faces as an OpenSCAD LHR outward shell where a global volume
//   direction is available.
//   .
//   - Returns: topology-consistent face list, possibly reversed as a whole
//   .
//   - Limitations/Gotchas: keeps per-face semantic orientation when that already
//     forms a coherent shell; otherwise repairs shared-edge winding before the
//     global outside decision. Zero-volume/open face sets keep the repaired seed
//     orientation.
// Arguments:
//   verts = 3D vertex list
//   faces = face list
//   eps = normalized signed-volume tolerance
function ps_orient_all_faces_outward(verts, faces, eps=1e-9) =
    let(semantic = _ps_faces_semantic_origin_orient(verts, faces))
    !is_undef(semantic)
        ? semantic
        : _ps_faces_orient_by_signed_volume(verts, _ps_fix_winding_all(faces), eps);
