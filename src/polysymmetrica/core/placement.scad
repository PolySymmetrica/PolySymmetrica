/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

// LibFile: polysymmetrica/core/placement.scad
use <funcs.scad>
include <placement_data.scad>
include <segments.scad>
use <classify.scad>

function _ps_cls_opt(classify_opts, i, def) =
    (is_undef(classify_opts) || !is_list(classify_opts) || i >= len(classify_opts) || is_undef(classify_opts[i]))
        ? def
        : classify_opts[i];

// Function: _ps_place_idx_selected()
// Usage:
//   result = _ps_place_idx_selected(idx, indices);
// Description:
//   Test whether a placement element index is selected.
//   .
//   - Returns: true when the element should be visited
// Arguments:
//   idx = element index
//   indices = `undef`, scalar index, or list of indices
function _ps_place_idx_selected(idx, indices) =
    is_undef(indices)
        ? true
        : is_list(indices)
            ? _ps_list_contains(indices, idx)
            : idx == indices;

function _ps_resolve_classify(poly, classify=undef, classify_opts=undef) =
    is_undef(classify) && is_undef(classify_opts)
        ? undef
        : !is_undef(classify)
        ? classify
        : poly_classify(
            poly,
            _ps_cls_opt(classify_opts, 0, 1),
            _ps_cls_opt(classify_opts, 1, 1e-6),
            _ps_cls_opt(classify_opts, 2, 1),
            _ps_cls_opt(classify_opts, 3, false)
        );

function _ps_vertex_site_incident_edge_idxs(edges, vertex_idx) =
    [
        for (ei = [0:1:len(edges)-1])
            if (edges[ei][0] == vertex_idx || edges[ei][1] == vertex_idx)
                ei
    ];

function _ps_vertex_site_face_incident_edge_count(incident_edge_idxs, edge_faces, face_idx) =
    len([
        for (ei = incident_edge_idxs)
            if (_ps_list_contains(edge_faces[ei], face_idx))
                ei
    ]);

function _ps_vertex_site_adjacent_faces(incident_edge_idxs, edge_faces, face_idx) =
    _ps_unique_values([
        for (ei = incident_edge_idxs)
            if (_ps_list_contains(edge_faces[ei], face_idx))
                for (fi = edge_faces[ei])
                    if (fi != face_idx)
                        fi
    ]);

function _ps_vertex_site_reachable_faces(incident_edge_idxs, edge_faces, frontier, seen=[]) =
    let(
        seen1 = _ps_unique_values(concat(seen, frontier)),
        next = _ps_unique_values([
            for (fi = frontier)
                for (adj = _ps_vertex_site_adjacent_faces(incident_edge_idxs, edge_faces, fi))
                    if (!_ps_list_contains(seen1, adj))
                        adj
        ])
    )
    (len(next) == 0)
        ? seen1
        : _ps_vertex_site_reachable_faces(incident_edge_idxs, edge_faces, next, seen1);

function _ps_vertex_site_has_closed_fan(faces, edges, edge_faces, vertex_idx) =
    let(
        incident_edge_idxs = _ps_vertex_site_incident_edge_idxs(edges, vertex_idx),
        incident_face_idxs = _ps_vertex_incident_face_indices(faces, vertex_idx),
        non_simple_faces = [
            for (fi = incident_face_idxs)
                if (_ps_face_vertex_count(faces[fi], vertex_idx) != 1)
                    fi
        ],
        non_manifold = [
            for (ei = incident_edge_idxs)
                if (len(edge_faces[ei]) != 2)
                    ei
        ],
        foreign_edge_faces = [
            for (ei = incident_edge_idxs)
                if (len(edge_faces[ei]) == 2)
                    for (fi = edge_faces[ei])
                        if (!_ps_list_contains(incident_face_idxs, fi))
                            fi
        ],
        bad_face_degrees = [
            for (fi = incident_face_idxs)
                if (_ps_vertex_site_face_incident_edge_count(incident_edge_idxs, edge_faces, fi) != 2)
                    fi
        ],
        reachable = (len(incident_face_idxs) == 0 || len(non_manifold) > 0)
            ? []
            : _ps_vertex_site_reachable_faces(incident_edge_idxs, edge_faces, [incident_face_idxs[0]])
    )
    len(incident_edge_idxs) > 0
        && len(incident_face_idxs) > 0
        && len(incident_edge_idxs) == len(incident_face_idxs)
        && len(non_simple_faces) == 0
        && len(non_manifold) == 0
        && len(foreign_edge_faces) == 0
        && len(bad_face_degrees) == 0
        && len(reachable) == len(incident_face_idxs);

// Function: _ps_face_site_neighbors_idx()
// Usage:
//   result = _ps_face_site_neighbors_idx(face, fi, faces0, edges, edge_faces);
// Description:
//   Build face-neighbor indices in face-edge order for one face site.
//   .
//   - Returns: list of adjacent face indices, or undef on boundary edges
// Arguments:
//   face = face index cycle
//   fi = face index
//   faces0 = oriented topology tables
//   edges = oriented topology tables
//   edge_faces = oriented topology tables
function _ps_face_site_neighbors_idx(face, fi, faces0, edges, edge_faces) =
    [
        for (k = [0:1:len(face)-1])
            let(
                v0 = face[k],
                v1 = face[(k+1)%len(face)],
                ei = ps_find_edge_index(edges, v0, v1),
                adj = edge_faces[ei]
            )
            (len(adj) < 2) ? undef : ((adj[0] == fi) ? adj[1] : adj[0])
    ];

// Function: _ps_face_site_dihedrals()
// Usage:
//   result = _ps_face_site_dihedrals(face, fi, faces0, edges, edge_faces, face_n);
// Description:
//   Build per-edge face dihedrals in face-edge order for one face site.
//   .
//   - Returns: list of dihedral angles in degrees, aligned with the face edge order
// Arguments:
//   face = face index cycle
//   fi = face index
//   faces0 = oriented topology tables
//   edges = oriented topology tables
//   edge_faces = oriented topology tables
//   face_n = per-face normals
function _ps_face_site_dihedrals(face, fi, faces0, edges, edge_faces, face_n) =
    [
        for (k = [0:1:len(face)-1])
            let(
                v0 = face[k],
                v1 = face[(k+1)%len(face)],
                ei = ps_find_edge_index(edges, v0, v1),
                adj = edge_faces[ei],
                n0 = face_n[fi],
                n1 = (len(adj) < 2) ? n0 : face_n[(adj[0] == fi) ? adj[1] : adj[0]],
                dotn = v_dot(n0, n1),
                c = (dotn > 1) ? 1 : ((dotn < -1) ? -1 : dotn)
            )
            180 - acos(c)
    ];

// Function: _ps_vertex_site_neighbors_idx()
// Usage:
//   result = _ps_vertex_site_neighbors_idx(edges, vi);
// Description:
//   Build full neighbor indices for one vertex site from the edge list.
//   .
//   - Returns: list of neighboring vertex indices in edge scan order
// Arguments:
//   edges = undirected edge list
//   vi = vertex index
function _ps_vertex_site_neighbors_idx(edges, vi) =
    [
        for (e = edges)
            if (e[0] == vi) e[1]
            else if (e[1] == vi) e[0]
    ];

// Function: _ps_any_perp()
// Usage:
//   result = _ps_any_perp(n);
// Description:
//   Pick a stable axis perpendicular to a normal for degenerate local face frames.
//   .
//   - Returns: unit vector perpendicular to `n`
// Arguments:
//   n = unit normal
function _ps_any_perp(n) =
    abs(n[0]) < 0.9
        ? v_norm(v_cross(n, [1, 0, 0]))
        : v_norm(v_cross(n, [0, 1, 0]));

// Function: _ps_local_face_ex()
// Usage:
//   result = _ps_local_face_ex(verts_local, f, center, ez, eps);
// Description:
//   Build a projected local face-frame X axis from target-local poly vertices.
//   .
//   - Returns: unit X axis in target-local coordinates
// Arguments:
//   verts_local = poly vertices in target-local coordinates
//   f = face index loop
//   center = face center
//   ez = face normal
//   eps = degeneracy tolerance
function _ps_local_face_ex(verts_local, f, center, ez, eps=1e-12) =
    let(
        ex_raw = verts_local[f[0]] - center,
        ex_proj = ex_raw - ez * v_dot(ex_raw, ez),
        ex_fallback_raw = verts_local[f[1]] - verts_local[f[0]],
        ex_fallback = ex_fallback_raw - ez * v_dot(ex_fallback_raw, ez)
    )
    norm(ex_proj) > eps
        ? v_norm(ex_proj)
        : norm(ex_fallback) > eps
        ? v_norm(ex_fallback)
        : _ps_any_perp(ez);

// Function: _ps_face_site_from_local_poly()
// Usage:
//   result = _ps_face_site_from_local_poly(face_idx, faces, verts_local, poly_center_local_parent, eps);
// Description:
//   Build a canonical face placement site from vertices already in a local coordinate system.
//   .
//   - Returns: face site record matching `ps_face_sites(...)`
// Arguments:
//   face_idx = face index
//   faces = face list
//   verts_local = poly vertices in parent-local coordinates
//   poly_center_local_parent = optional poly center in parent-local coords
//   eps = degeneracy tolerance
function _ps_face_site_from_local_poly(face_idx, faces, verts_local, poly_center_local_parent=undef, eps=1e-12) =
    let(
        f = faces[face_idx],
        center = ps_face_centroid(verts_local, f),
        ez = ps_face_frame_normal(verts_local, f, eps),
        ex = _ps_local_face_ex(verts_local, f, center, ez, eps),
        ey = v_cross(ez, ex),
        edge_lens = [
            for (k = [0:1:len(f)-1])
                norm(verts_local[f[(k + 1) % len(f)]] - verts_local[f[k]])
        ],
        edge_len = len(edge_lens) == 0 ? 0 : ps_sum(edge_lens) / len(edge_lens),
        face_midradius = norm(center),
        rad_vec = [for (vid = f) norm(verts_local[vid] - center)],
        face_radius = len(rad_vec) == 0 ? 0 : ps_sum(rad_vec) / len(rad_vec),
        poly_center_parent = is_undef(poly_center_local_parent) ? [0, 0, 0] : poly_center_local_parent,
        poly_center_delta = poly_center_parent - center,
        poly_center_local_raw = [
            v_dot(poly_center_delta, ex),
            v_dot(poly_center_delta, ey),
            v_dot(poly_center_delta, ez)
        ],
        face_verts_local_raw = [
            for (vid = f)
                let(p = verts_local[vid] - center)
                    [v_dot(p, ex), v_dot(p, ey), v_dot(p, ez)]
        ],
        poly_verts_local_raw = [
            for (p0 = verts_local)
                let(p = p0 - center)
                    [v_dot(p, ex), v_dot(p, ey), v_dot(p, ez)]
        ],
        zvals = [for (p = face_verts_local_raw) p[2]],
        zmean = len(zvals) == 0 ? 0 : ps_sum(zvals) / len(zvals),
        face_planarity_err = len(zvals) == 0 ? 0 : max([for (z = zvals) abs(z - zmean)]),
        face_pts3d_local = [for (p = face_verts_local_raw) [p[0], p[1], p[2] - zmean]],
        poly_center_local = [poly_center_local_raw[0], poly_center_local_raw[1], poly_center_local_raw[2] - zmean],
        poly_verts_local = [for (p = poly_verts_local_raw) [p[0], p[1], p[2] - zmean]],
        face_pts2d = ps_xy(face_pts3d_local),
        edges = _ps_edges_from_faces(faces),
        edge_faces = ps_edge_faces_table(faces, edges),
        face_n = [for (face = faces) ps_face_frame_normal(verts_local, face, eps)],
        face_neighbors_idx = _ps_face_site_neighbors_idx(f, face_idx, faces, edges, edge_faces),
        face_dihedrals = _ps_face_site_dihedrals(f, face_idx, faces, edges, edge_faces, face_n),
        frame = ps_placement_frame(center, ex, ey, ez),
        face_local_context = ps_face_local_context(
            face_pts3d_local,
            face_pts2d,
            face_idx,
            faces,
            poly_verts_local,
            face_neighbors_idx,
            face_dihedrals,
            poly_center_local
        )
    )
    [
        face_idx,
        edge_len,
        len(face_pts2d),
        face_midradius,
        face_radius,
        face_planarity_err,
        face_planarity_err <= eps,
        undef,
        undef,
        undef,
        undef,
        frame,
        face_local_context
    ];

// Function: _ps_edge_site_from_local_poly()
// Usage:
//   result = _ps_edge_site_from_local_poly(edge_idx, faces, verts_local, poly_center_local_parent, eps);
// Description:
//   Build a canonical edge placement site from vertices already in a local coordinate system.
//   .
//   - Returns: edge site record matching `ps_edge_sites(...)`
// Arguments:
//   edge_idx = global edge index
//   faces = face list
//   verts_local = poly vertices in parent-local coordinates
//   poly_center_local_parent = optional poly center in parent-local coords
//   eps = degeneracy tolerance
function _ps_edge_site_from_local_poly(edge_idx, faces, verts_local, poly_center_local_parent=undef, eps=1e-12) =
    let(
        edges = _ps_edges_from_faces(faces),
        e = edges[edge_idx],
        v0 = verts_local[e[0]],
        v1 = verts_local[e[1]],
        center = (v0 + v1) / 2,
        edge_vec = v1 - v0,
        ex = (norm(edge_vec) <= eps) ? [1, 0, 0] : v_norm(edge_vec),
        edge_faces = ps_edge_faces_table(faces, edges),
        adj_faces_idx = edge_faces[edge_idx],
        face_n = [for (f = faces) ps_face_frame_normal(verts_local, f, eps)],
        poly_center_parent = is_undef(poly_center_local_parent) ? [0, 0, 0] : poly_center_local_parent,
        radial_raw = center - poly_center_parent,
        radial_ref = (norm(radial_raw) <= eps) ? _ps_any_perp(ex) : v_norm(radial_raw),
        bisector_raw =
            (len(adj_faces_idx) < 2)
                ? radial_ref
                : face_n[adj_faces_idx[0]] + face_n[adj_faces_idx[1]],
        bisector_signed =
            (norm(bisector_raw) <= eps)
                ? radial_ref
                : ((v_dot(bisector_raw, radial_ref) < 0) ? -bisector_raw : bisector_raw),
        ez_proj = bisector_signed - ex * v_dot(bisector_signed, ex),
        radial_proj = radial_ref - ex * v_dot(radial_ref, ex),
        ez_dir =
            (norm(ez_proj) <= eps)
                ? radial_proj
                : ez_proj,
        ez = (norm(ez_dir) <= eps) ? _ps_any_perp(ex) : v_norm(ez_dir),
        ey = v_norm(v_cross(ez, ex)),
        edge_midradius = norm(center - poly_center_parent),
        edge_len_actual = norm(edge_vec),
        poly_center_delta = poly_center_parent - center,
        poly_center_local = [
            v_dot(poly_center_delta, ex),
            v_dot(poly_center_delta, ey),
            v_dot(poly_center_delta, ez)
        ],
        edge_pts_local = [[-edge_len_actual / 2, 0, 0], [edge_len_actual / 2, 0, 0]],
        frame = ps_placement_frame(center, ex, ey, ez)
    )
    [
        edge_idx,
        edge_len_actual,
        edge_midradius,
        poly_center_local,
        edge_pts_local,
        e,
        adj_faces_idx,
        undef,
        undef,
        undef,
        undef,
        frame
    ];

// Function: _ps_vertex_site_from_local_poly()
// Usage:
//   result = _ps_vertex_site_from_local_poly(vertex_idx, faces, verts_local, poly_center_local_parent, eps);
// Description:
//   Build a canonical vertex placement site from vertices already in a local coordinate system.
//   .
//   - Returns: vertex site record matching `ps_vertex_sites(...)`
// Arguments:
//   vertex_idx = vertex index
//   faces = face list
//   verts_local = poly vertices in parent-local coordinates
//   poly_center_local_parent = optional poly center in parent-local coords
//   eps = degeneracy tolerance
function _ps_vertex_site_from_local_poly(vertex_idx, faces, verts_local, poly_center_local_parent=undef, eps=1e-12) =
    let(
        edges = _ps_edges_from_faces(faces),
        edge_faces = ps_edge_faces_table(faces, edges),
        local_poly = [verts_local, faces, 1],
        center = verts_local[vertex_idx],
        poly_center_parent = is_undef(poly_center_local_parent) ? [0, 0, 0] : poly_center_local_parent,
        radial_raw = center - poly_center_parent,
        ez = (norm(radial_raw) <= eps) ? [0, 0, 1] : v_norm(radial_raw),
        closed_fan = _ps_vertex_site_has_closed_fan(faces, edges, edge_faces, vertex_idx),
        fan = closed_fan ? ps_vertex_fan(local_poly, vertex_idx, edges, edge_faces) : undef,
        vertex_figure = is_undef(fan) ? undef : _ps_vertex_figure_from_fan(fan),
        neighbors_idx = closed_fan
            ? ps_vertex_fan_neighbors_idx(fan)
            : _ps_vertex_site_neighbors_idx(edges, vertex_idx),
        neighbor0 = len(neighbors_idx) == 0 ? undef : verts_local[neighbors_idx[0]],
        neighbor_dir = is_undef(neighbor0) ? undef : neighbor0 - center,
        proj = is_undef(neighbor_dir) ? undef : neighbor_dir - ez * v_dot(neighbor_dir, ez),
        ex =
            (!is_undef(proj) && norm(proj) > eps)
                ? v_norm(proj)
                : _ps_any_perp(ez),
        ey = v_cross(ez, ex),
        valence = len(neighbors_idx),
        neighbor_pts_local = [
            for (nj = neighbors_idx)
                let(pw = verts_local[nj] - center)
                    [v_dot(pw, ex), v_dot(pw, ey), v_dot(pw, ez)]
        ],
        neighbor_lens = [for (p = neighbor_pts_local) norm(p)],
        edge_len = len(neighbor_lens) == 0 ? 0 : ps_sum(neighbor_lens) / len(neighbor_lens),
        poly_center_delta = poly_center_parent - center,
        poly_center_local = [
            v_dot(poly_center_delta, ex),
            v_dot(poly_center_delta, ey),
            v_dot(poly_center_delta, ez)
        ],
        frame = ps_placement_frame(center, ex, ey, ez)
    )
    [
        vertex_idx,
        edge_len,
        norm(radial_raw),
        poly_center_local,
        valence,
        neighbors_idx,
        neighbor_pts_local,
        undef,
        undef,
        undef,
        undef,
        frame,
        vertex_figure
    ];

// Function: _ps_proxy_edge_ids_from_face_record()
// Usage:
//   result = _ps_proxy_edge_ids_from_face_record(record, faces, verts_local, eps);
// Description:
//   Build edge ids from one foreign face intrusion record.
//   .
//   - Returns: global edge ids for every boundary edge of the exact foreign face intruder
// Arguments:
//   record = foreign face intrusion record
//   faces = face list
//   verts_local = accepted for API symmetry
//   eps = accepted for API symmetry
function _ps_proxy_edge_ids_from_face_record(record, faces, verts_local, eps=1e-8) =
    let(
        face_idx = ps_intrusion_foreign_idx(record),
        f = faces[face_idx],
        edges = _ps_edges_from_faces(faces),
        ids = [
            for (k = [0:1:len(f)-1])
                let(
                    a = f[k],
                    b = f[(k + 1) % len(f)],
                    edge_idx = ps_find_edge_index(edges, a, b)
                )
                edge_idx
        ]
    )
    _ps_unique_values(ids);

// Function: _ps_proxy_vertex_ids_from_face_record()
// Usage:
//   result = _ps_proxy_vertex_ids_from_face_record(record, faces, verts_local, eps);
// Description:
//   Build vertex ids from one foreign face intrusion record.
//   .
//   - Returns: vertex ids for every vertex of the exact foreign face intruder
// Arguments:
//   record = foreign face intrusion record
//   faces = face list
//   verts_local = accepted for API symmetry
//   eps = accepted for API symmetry
function _ps_proxy_vertex_ids_from_face_record(record, faces, verts_local, eps=1e-8) =
    let(
        face_idx = ps_intrusion_foreign_idx(record),
        raw = faces[face_idx]
    )
    _ps_unique_values(raw);

// Function: _ps_proxy_candidate_record_seen()
// Usage:
//   result = _ps_proxy_candidate_record_seen(records, kind, idx, i);
// Description:
//   Test whether a candidate record set already contains a foreign element.
//   .
//   - Returns: boolean
// Arguments:
//   records = candidate records
//   kind = foreign kind
//   idx = foreign index
//   i = recursion state
function _ps_proxy_candidate_record_seen(records, kind, idx, i=0) =
    (i >= len(records)) ? false :
    (ps_intrusion_foreign_kind(records[i]) == kind && ps_intrusion_foreign_idx(records[i]) == idx) ? true :
    _ps_proxy_candidate_record_seen(records, kind, idx, i + 1);

// Function: _ps_proxy_candidate_records_dedupe()
// Usage:
//   result = _ps_proxy_candidate_records_dedupe(records, i, acc);
// Description:
//   Deduplicate proxy candidate records by foreign kind and source index.
//   .
//   - Returns: first record for each `(foreign_kind, foreign_idx)` pair
// Arguments:
//   records = candidate records
//   i = recursion state
//   acc = recursion state
function _ps_proxy_candidate_records_dedupe(records, i=0, acc=[]) =
    (i >= len(records)) ? acc :
    let(
        record = records[i],
        hit = _ps_proxy_candidate_record_seen(
            acc,
            ps_intrusion_foreign_kind(record),
            ps_intrusion_foreign_idx(record)
        )
    )
    _ps_proxy_candidate_records_dedupe(
        records,
        i + 1,
        hit ? acc : concat(acc, [record])
    );

// Function: _ps_face_foreign_face_replay_site()
// Usage:
//   result = _ps_face_foreign_face_replay_site(replay_idx, record, ctx, eps);
// Description:
//   Build one foreign face replay site from an intrusion record.
//   .
//   - Returns: replay site record for `place_on_face_foreign_face_replay_sites(...)`
// Arguments:
//   replay_idx = site index
//   record = foreign intrusion record
//   ctx = target-local poly context
//   eps = degeneracy tolerance
function _ps_face_foreign_face_replay_site(replay_idx, record, ctx, eps=1e-12) =
    let(
        foreign_face_idx = ps_intrusion_foreign_idx(record),
        ctx_faces_idx = ps_target_local_poly_context_faces_idx(ctx),
        ctx_verts_local = ps_target_local_poly_context_verts_local(ctx),
        ctx_center_local = ps_target_local_poly_context_center_local(ctx),
        face_site = _ps_face_site_from_local_poly(foreign_face_idx, ctx_faces_idx, ctx_verts_local, ctx_center_local, eps),
        face_site_faces_idx = ps_face_site_poly_faces_idx(face_site),
        frame = ps_face_site_frame(face_site)
    )
    [
        replay_idx,
        record,
        frame,
        foreign_face_idx,
        ps_face_site_pts2d(face_site),
        ps_face_site_pts3d_local(face_site),
        ps_face_site_poly_verts_local(face_site),
        ps_face_site_poly_center_local(face_site),
        face_site_faces_idx[foreign_face_idx],
        ps_intrusion_foreign_kind(record),
        ps_intrusion_segment2d_local(record),
        ps_intrusion_dihedral(record),
        ps_intrusion_confidence(record),
        face_site,
        undef,
        undef
    ];

// Function: _ps_face_foreign_edge_replay_site()
// Usage:
//   result = _ps_face_foreign_edge_replay_site(replay_idx, record, ctx, eps);
// Description:
//   Build one foreign edge replay site from a candidate intrusion record.
//   .
//   - Returns: replay site record for `place_on_face_foreign_proxy_sites(...)`
// Arguments:
//   replay_idx = site index
//   record = foreign edge candidate record
//   ctx = target-local poly context
//   eps = degeneracy tolerance
function _ps_face_foreign_edge_replay_site(replay_idx, record, ctx, eps=1e-12) =
    let(
        foreign_edge_idx = ps_intrusion_foreign_idx(record),
        ctx_faces_idx = ps_target_local_poly_context_faces_idx(ctx),
        ctx_verts_local = ps_target_local_poly_context_verts_local(ctx),
        ctx_center_local = ps_target_local_poly_context_center_local(ctx),
        edge_site = _ps_edge_site_from_local_poly(foreign_edge_idx, ctx_faces_idx, ctx_verts_local, ctx_center_local, eps),
        frame = ps_edge_site_frame(edge_site)
    )
    [
        replay_idx,
        record,
        frame,
        foreign_edge_idx,
        undef,
        undef,
        undef,
        ps_edge_site_poly_center_local(edge_site),
        undef,
        ps_intrusion_foreign_kind(record),
        ps_intrusion_segment2d_local(record),
        ps_intrusion_dihedral(record),
        ps_intrusion_confidence(record),
        undef,
        edge_site,
        undef
    ];

// Function: _ps_face_foreign_vertex_replay_site()
// Usage:
//   result = _ps_face_foreign_vertex_replay_site(replay_idx, record, ctx, eps);
// Description:
//   Build one foreign vertex replay site from a candidate intrusion record.
//   .
//   - Returns: replay site record for `place_on_face_foreign_proxy_sites(...)`
// Arguments:
//   replay_idx = site index
//   record = foreign vertex candidate record
//   ctx = target-local poly context
//   eps = degeneracy tolerance
function _ps_face_foreign_vertex_replay_site(replay_idx, record, ctx, eps=1e-12) =
    let(
        foreign_vertex_idx = ps_intrusion_foreign_idx(record),
        ctx_faces_idx = ps_target_local_poly_context_faces_idx(ctx),
        ctx_verts_local = ps_target_local_poly_context_verts_local(ctx),
        ctx_center_local = ps_target_local_poly_context_center_local(ctx),
        vertex_site = _ps_vertex_site_from_local_poly(foreign_vertex_idx, ctx_faces_idx, ctx_verts_local, ctx_center_local, eps),
        frame = ps_vertex_site_frame(vertex_site)
    )
    [
        replay_idx,
        record,
        frame,
        foreign_vertex_idx,
        undef,
        undef,
        undef,
        ps_vertex_site_poly_center_local(vertex_site),
        undef,
        ps_intrusion_foreign_kind(record),
        ps_intrusion_segment2d_local(record),
        ps_intrusion_dihedral(record),
        ps_intrusion_confidence(record),
        undef,
        undef,
        vertex_site
    ];

// Function: _ps_face_foreign_face_replay_sites_from_context()
// Usage:
//   result = _ps_face_foreign_face_replay_sites_from_context(face_pts2d, face_idx, ctx, eps, mode, filter_parent);
// Description:
//   Build target-local replay sites for exact foreign face intrusions from a target-local poly context.
//   .
//   - Returns: replay site records for intruding foreign faces, with frames expressed in the target face-local coordinate system
//   .
//   - Limitations/Gotchas: only exact `"face"` intrusion records are converted; use `ps_face_foreign_proxy_replay_sites(...)` for edge/vertex candidates
// Arguments:
//   face_pts2d = current target face loop in face-local 2D coordinates.
//   face_idx = current target face index in the source poly.
//   ctx = target-local poly context containing source faces and vertices in the current face frame.
//   eps = geometric tolerance for intrusion/arrangement calculations.
//   mode = face-arrangement fill rule: `"nonzero"`, `"evenodd"`, or `"all"`.
//   filter_parent = whether to drop cuts caused only by the current face's own boundary adjacency.
function _ps_face_foreign_face_replay_sites_from_context(face_pts2d, face_idx, ctx, eps=1e-8, mode="nonzero", filter_parent=true) =
    let(
        ctx_faces_idx = ps_target_local_poly_context_faces_idx(ctx),
        ctx_verts_local = ps_target_local_poly_context_verts_local(ctx),
        records = [
            for (r = ps_face_foreign_intrusion_records(face_pts2d, face_idx, ctx_faces_idx, ctx_verts_local, eps, mode, filter_parent))
                if (ps_intrusion_foreign_kind(r) == "face")
                    r
        ]
    )
    [
        for (ri = [0:1:len(records)-1])
            _ps_face_foreign_face_replay_site(ri, records[ri], ctx, eps)
    ];

// Function: ps_face_foreign_face_replay_sites()
// Usage:
//   result = ps_face_foreign_face_replay_sites(face_pts2d, face_idx, ctx, eps, mode, filter_parent);
// Description:
//   Build target-local replay sites for exact foreign face intrusions from a target-local poly context.
//   .
//   - Returns: replay site records for intruding foreign faces, with frames expressed in the target face-local coordinate system
//   .
//   - Limitations/Gotchas: context-first public entry point
// Arguments:
//   face_pts2d = current target face loop in face-local 2D coordinates.
//   face_idx = current target face index in the source poly.
//   ctx = target-local poly context containing source faces and vertices in the current face frame.
//   eps = geometric tolerance for intrusion/arrangement calculations.
//   mode = face-arrangement fill rule: `"nonzero"`, `"evenodd"`, or `"all"`.
//   filter_parent = whether to drop cuts caused only by the current face's own boundary adjacency.
function ps_face_foreign_face_replay_sites(face_pts2d, face_idx, ctx, eps=1e-8, mode="nonzero", filter_parent=true) =
    _ps_face_foreign_face_replay_sites_from_context(face_pts2d, face_idx, ctx, eps, mode, filter_parent);

// Function: _ps_face_foreign_proxy_replay_sites_from_records_context()
// Usage:
//   result = _ps_face_foreign_proxy_replay_sites_from_records_context(face_idx, face_records, ctx, eps);
// Description:
//   Build proxy replay sites from already-derived exact foreign face records.
//   .
//   - Returns: replay site records preserving every exact face record, plus deduped edge/vertex boundary candidates
// Arguments:
//   face_idx = target face index
//   face_records = exact foreign face intrusion records
//   ctx = target-local poly context
//   eps = tolerance
function _ps_face_foreign_proxy_replay_sites_from_records_context(face_idx, face_records, ctx, eps=1e-8) =
    let(
        ctx_faces_idx = ps_target_local_poly_context_faces_idx(ctx),
        ctx_verts_local = ps_target_local_poly_context_verts_local(ctx),
        edge_records = [
            for (r = face_records)
                for (edge_idx = _ps_proxy_edge_ids_from_face_record(r, ctx_faces_idx, ctx_verts_local, eps))
                    ["face_plane_cut_candidate", face_idx, "edge", edge_idx, ps_intrusion_segment2d_local(r), ps_intrusion_dihedral(r), "candidate"]
        ],
        vertex_records = [
            for (r = face_records)
                for (vertex_idx = _ps_proxy_vertex_ids_from_face_record(r, ctx_faces_idx, ctx_verts_local, eps))
                    ["face_plane_cut_candidate", face_idx, "vertex", vertex_idx, ps_intrusion_segment2d_local(r), ps_intrusion_dihedral(r), "candidate"]
        ],
        candidate_records = _ps_proxy_candidate_records_dedupe(concat(edge_records, vertex_records)),
        records = concat(face_records, candidate_records)
    )
    [
        for (ri = [0:1:len(records)-1])
            let(kind = ps_intrusion_foreign_kind(records[ri]))
                kind == "face"
                    ? _ps_face_foreign_face_replay_site(ri, records[ri], ctx, eps)
                    : kind == "edge"
                    ? _ps_face_foreign_edge_replay_site(ri, records[ri], ctx, eps)
                    : _ps_face_foreign_vertex_replay_site(ri, records[ri], ctx, eps)
    ];

// Function: _ps_face_foreign_proxy_replay_sites_from_records()
// Usage:
//   result = _ps_face_foreign_proxy_replay_sites_from_records(face_idx, face_records, poly_faces_idx, poly_verts_local, poly_center_local, eps);
// Description:
//   Build proxy replay sites from already-derived exact foreign face records.
//   .
//   - Returns: replay site records preserving every exact face record, plus deduped edge/vertex boundary candidates
// Arguments:
//   face_idx = target face index
//   face_records = exact foreign face intrusion records
//   poly_faces_idx = current `place_on_faces(...)` metadata
//   poly_verts_local = current `place_on_faces(...)` metadata
//   poly_center_local = current `place_on_faces(...)` metadata
//   eps = tolerance
function _ps_face_foreign_proxy_replay_sites_from_records(face_idx, face_records, poly_faces_idx, poly_verts_local, poly_center_local=undef, eps=1e-8) =
    _ps_face_foreign_proxy_replay_sites_from_records_context(
        face_idx,
        face_records,
        ps_target_local_poly_context(poly_faces_idx, poly_verts_local, poly_center_local),
        eps
    );

// Function: _ps_face_foreign_proxy_replay_sites_from_context()
// Usage:
//   result = _ps_face_foreign_proxy_replay_sites_from_context(face_pts2d, face_idx, ctx, eps, mode, filter_parent);
// Description:
//   Build provenance-driven proxy replay sites for foreign face/edge/vertex sources from a target-local poly context.
//   .
//   - Returns: replay site records for exact foreign faces plus every boundary edge/vertex of those exact face intruders
//   .
//   - Limitations/Gotchas: edge and vertex sites are candidate/provenance records, not distance-envelope proximity tests
// Arguments:
//   face_pts2d = current target face loop in face-local 2D coordinates.
//   face_idx = current target face index in the source poly.
//   ctx = target-local poly context containing source faces and vertices in the current face frame.
//   eps = geometric tolerance for intrusion/arrangement calculations.
//   mode = face-arrangement fill rule: `"nonzero"`, `"evenodd"`, or `"all"`.
//   filter_parent = whether to drop cuts caused only by the current face's own boundary adjacency.
function _ps_face_foreign_proxy_replay_sites_from_context(face_pts2d, face_idx, ctx, eps=1e-8, mode="nonzero", filter_parent=true) =
    let(
        ctx_faces_idx = ps_target_local_poly_context_faces_idx(ctx),
        ctx_verts_local = ps_target_local_poly_context_verts_local(ctx),
        face_records = [
            for (r = ps_face_foreign_intrusion_records(face_pts2d, face_idx, ctx_faces_idx, ctx_verts_local, eps, mode, filter_parent))
                if (ps_intrusion_foreign_kind(r) == "face")
                    r
        ]
    )
    _ps_face_foreign_proxy_replay_sites_from_records_context(face_idx, face_records, ctx, eps);

// Function: ps_face_foreign_proxy_replay_sites()
// Usage:
//   result = ps_face_foreign_proxy_replay_sites(face_pts2d, face_idx, ctx, eps, mode, filter_parent);
// Description:
//   Build provenance-driven proxy replay sites for foreign face/edge/vertex sources from a target-local poly context.
//   .
//   - Returns: replay site records for exact foreign faces plus every boundary edge/vertex of those exact face intruders
//   .
//   - Limitations/Gotchas: context-first public entry point
// Arguments:
//   face_pts2d = target face loop
//   face_idx = target face index
//   ctx = target-local poly context
//   eps = tolerance
//   mode = foreign face fill rule
//   filter_parent = drop parent-edge cuts
function ps_face_foreign_proxy_replay_sites(face_pts2d, face_idx, ctx, eps=1e-8, mode="nonzero", filter_parent=true) =
    _ps_face_foreign_proxy_replay_sites_from_context(face_pts2d, face_idx, ctx, eps, mode, filter_parent);

// Function: _ps_faces_share_source_edge()
// Usage:
//   result = _ps_faces_share_source_edge(face_a, face_b);
// Description:
//   Test whether two faces share an undirected source edge.
//   .
//   - Returns: boolean
// Arguments:
//   face_a =
//   face_b = face index loops
function _ps_faces_share_source_edge(face_a, face_b) =
    len([
        for (i = [0:1:len(face_a)-1])
            let(a = face_a[i], b = face_a[(i + 1) % len(face_a)])
            if (ps_face_has_edge(face_b, a, b)) 1
    ]) > 0;

// Function: _ps_face_adjacent_to_group()
// Usage:
//   result = _ps_face_adjacent_to_group(face_idx, group_face_ids, faces, i);
// Description:
//   Test whether a face is edge-adjacent to any face in a group.
//   .
//   - Returns: boolean
// Arguments:
//   face_idx = candidate face
//   group_face_ids = face ids
//   faces = face list
//   i = scan index
function _ps_face_adjacent_to_group(face_idx, group_face_ids, faces, i=0) =
    (i >= len(group_face_ids)) ? false :
    _ps_faces_share_source_edge(faces[face_idx], faces[group_face_ids[i]]) ? true :
    _ps_face_adjacent_to_group(face_idx, group_face_ids, faces, i + 1);

// Function: _ps_proxy_grow_face_group()
// Usage:
//   result = _ps_proxy_grow_face_group(seed_face_ids, faces, group_face_ids);
// Description:
//   Expand a seed-face group through source-edge adjacency.
//   .
//   - Returns: connected component of seed face ids
// Arguments:
//   seed_face_ids = allowed face ids
//   faces = face list
//   group_face_ids = current connected group
function _ps_proxy_grow_face_group(seed_face_ids, faces, group_face_ids) =
    let(
        additions = [
            for (face_idx = seed_face_ids)
                if (!_ps_list_contains(group_face_ids, face_idx) && _ps_face_adjacent_to_group(face_idx, group_face_ids, faces))
                    face_idx
        ],
        next_group = _ps_unique_values(concat(group_face_ids, additions))
    )
    (len(next_group) == len(group_face_ids))
        ? group_face_ids
        : _ps_proxy_grow_face_group(seed_face_ids, faces, next_group);

// Function: _ps_proxy_group_in_seed_order()
// Usage:
//   result = _ps_proxy_group_in_seed_order(group_face_ids, seed_face_ids);
// Description:
//   Reorder a connected face group to match original seed order.
//   .
//   - Returns: group face ids in seed order
// Arguments:
//   group_face_ids = connected face ids
//   seed_face_ids = original ordered seeds
function _ps_proxy_group_in_seed_order(group_face_ids, seed_face_ids) =
    [for (face_idx = seed_face_ids) if (_ps_list_contains(group_face_ids, face_idx)) face_idx];

// Function: _ps_proxy_connected_face_groups()
// Usage:
//   result = _ps_proxy_connected_face_groups(seed_face_ids, faces, acc);
// Description:
//   Group source face ids into edge-connected components.
//   .
//   - Returns: list of connected face-id groups
// Arguments:
//   seed_face_ids = face ids
//   faces = face list
//   acc = group accumulator
function _ps_proxy_connected_face_groups(seed_face_ids, faces, acc=[]) =
    (len(seed_face_ids) == 0) ? acc :
    let(
        group = _ps_proxy_group_in_seed_order(
            _ps_proxy_grow_face_group(seed_face_ids, faces, [seed_face_ids[0]]),
            seed_face_ids
        ),
        remaining = [for (face_idx = seed_face_ids) if (!_ps_list_contains(group, face_idx)) face_idx]
    )
    _ps_proxy_connected_face_groups(remaining, faces, concat(acc, [group]));

// Function: _ps_proxy_group_record_idxs()
// Usage:
//   result = _ps_proxy_group_record_idxs(face_records, group_face_ids);
// Description:
//   Find face-record positions belonging to a connected face group.
//   .
//   - Returns: index positions into `face_records`
// Arguments:
//   face_records = intrusion records
//   group_face_ids = connected source face ids
function _ps_proxy_group_record_idxs(face_records, group_face_ids) =
    [
        for (ri = [0:1:len(face_records)-1])
            if (_ps_list_contains(group_face_ids, ps_intrusion_foreign_idx(face_records[ri])))
                ri
    ];

// Function: _ps_proxy_group_support_face_ids()
// Usage:
//   result = _ps_proxy_group_support_face_ids(group_face_ids, faces, target_face_idx);
// Description:
//   Find adjacent non-seed faces that may later support a proxy volume.
//   .
//   - Returns: source face ids adjacent to the group, excluding the target and seed faces
// Arguments:
//   group_face_ids = connected seed source faces
//   faces = face list
//   target_face_idx = current target face
function _ps_proxy_group_support_face_ids(group_face_ids, faces, target_face_idx) =
    _ps_unique_values([
        for (fi = [0:1:len(faces)-1])
            if (
                fi != target_face_idx
                && !_ps_list_contains(group_face_ids, fi)
                && _ps_face_adjacent_to_group(fi, group_face_ids, faces)
            )
                fi
    ]);

// Function: _ps_proxy_volume_group_record()
// Usage:
//   result = _ps_proxy_volume_group_record(group_idx, target_face_idx, group_face_ids, face_records, ctx, eps);
// Description:
//   Build one foreign proxy volume-group record.
//   .
//   - Returns: volume-group record `["foreign_proxy_volume_group", target_face_idx, group_idx, face_idxs, record_idxs, records, edge_idxs, vertex_idxs, support_face_idxs]`
// Arguments:
//   group_idx = group index
//   target_face_idx = target face
//   group_face_ids = seed source faces
//   face_records = exact intrusion records
//   ctx = target-local poly context
//   eps = tolerance
function _ps_proxy_volume_group_record(group_idx, target_face_idx, group_face_ids, face_records, ctx, eps=1e-8) =
    let(
        ctx_faces_idx = ps_target_local_poly_context_faces_idx(ctx),
        ctx_verts_local = ps_target_local_poly_context_verts_local(ctx),
        record_idxs = _ps_proxy_group_record_idxs(face_records, group_face_ids),
        records = [for (ri = record_idxs) face_records[ri]],
        edge_idxs = _ps_unique_values([
            for (r = records)
                for (edge_idx = _ps_proxy_edge_ids_from_face_record(r, ctx_faces_idx, ctx_verts_local, eps))
                    edge_idx
        ]),
        vertex_idxs = _ps_unique_values([
            for (r = records)
                for (vertex_idx = _ps_proxy_vertex_ids_from_face_record(r, ctx_faces_idx, ctx_verts_local, eps))
                    vertex_idx
        ]),
        support_face_idxs = _ps_proxy_group_support_face_ids(group_face_ids, ctx_faces_idx, target_face_idx)
    )
    [
        "foreign_proxy_volume_group",
        target_face_idx,
        group_idx,
        group_face_ids,
        record_idxs,
        records,
        edge_idxs,
        vertex_idxs,
        support_face_idxs
    ];

// Function: _ps_face_foreign_proxy_volume_groups_from_records_context()
// Usage:
//   result = _ps_face_foreign_proxy_volume_groups_from_records_context(target_face_idx, face_records, ctx, eps);
// Description:
//   Build proxy volume groups from exact foreign face intrusion records.
//   .
//   - Returns: connected source-face volume-group records
//   .
//   - Limitations/Gotchas: data only; does not construct a closed CSG/polyhedron volume
// Arguments:
//   target_face_idx = target face
//   face_records = exact foreign face records
//   ctx = target-local poly context
//   eps = tolerance
function _ps_face_foreign_proxy_volume_groups_from_records_context(target_face_idx, face_records, ctx, eps=1e-8) =
    let(
        ctx_faces_idx = ps_target_local_poly_context_faces_idx(ctx),
        seed_face_ids = _ps_unique_values([for (r = face_records) ps_intrusion_foreign_idx(r)]),
        groups = _ps_proxy_connected_face_groups(seed_face_ids, ctx_faces_idx)
    )
    [
        for (gi = [0:1:len(groups)-1])
            _ps_proxy_volume_group_record(gi, target_face_idx, groups[gi], face_records, ctx, eps)
    ];

// Function: _ps_face_foreign_proxy_volume_groups_from_records()
// Usage:
//   result = _ps_face_foreign_proxy_volume_groups_from_records(target_face_idx, face_records, poly_faces_idx, poly_verts_local, eps);
// Description:
//   Build proxy volume groups from exact foreign face intrusion records.
//   .
//   - Returns: connected source-face volume-group records
//   .
//   - Limitations/Gotchas: internal helper that rebuilds target-local context from raw poly fields
// Arguments:
//   target_face_idx = target face
//   face_records = exact foreign face records
//   poly_faces_idx = target-local poly context
//   poly_verts_local = target-local poly context
//   eps = tolerance
function _ps_face_foreign_proxy_volume_groups_from_records(target_face_idx, face_records, poly_faces_idx, poly_verts_local, eps=1e-8) =
    _ps_face_foreign_proxy_volume_groups_from_records_context(
        target_face_idx,
        face_records,
        ps_target_local_poly_context(poly_faces_idx, poly_verts_local),
        eps
    );

// Function: _ps_face_foreign_proxy_volume_groups_from_context()
// Usage:
//   result = _ps_face_foreign_proxy_volume_groups_from_context(face_pts2d, face_idx, ctx, eps, mode, filter_parent);
// Description:
//   Build connected foreign proxy volume-group records for a target face from a target-local poly context.
//   .
//   - Returns: data-only volume-group records for exact intruding foreign faces
//   .
//   - Limitations/Gotchas: groups describe source-topology provenance for later/user-supplied volume replay; they do not infer arbitrary solid geometry
// Arguments:
//   face_pts2d = target face loop
//   face_idx = target face index
//   ctx = target-local poly context
//   eps = tolerance
//   mode = foreign face fill rule
//   filter_parent = drop parent-edge cuts
function _ps_face_foreign_proxy_volume_groups_from_context(face_pts2d, face_idx, ctx, eps=1e-8, mode="nonzero", filter_parent=true) =
    let(
        ctx_faces_idx = ps_target_local_poly_context_faces_idx(ctx),
        ctx_verts_local = ps_target_local_poly_context_verts_local(ctx),
        face_records = [
            for (r = ps_face_foreign_intrusion_records(face_pts2d, face_idx, ctx_faces_idx, ctx_verts_local, eps, mode, filter_parent))
                if (ps_intrusion_foreign_kind(r) == "face" && ps_intrusion_confidence(r) == "exact")
                    r
        ]
    )
    _ps_face_foreign_proxy_volume_groups_from_records_context(face_idx, face_records, ctx, eps);

// Function: ps_face_foreign_proxy_volume_groups()
// Usage:
//   result = ps_face_foreign_proxy_volume_groups(face_pts2d, face_idx, ctx, eps, mode, filter_parent);
// Description:
//   Build connected foreign proxy volume-group records for a target face from a target-local poly context.
//   .
//   - Returns: data-only volume-group records for exact intruding foreign faces
//   .
//   - Limitations/Gotchas: context-first public entry point
// Arguments:
//   face_pts2d = target face loop
//   face_idx = target face index
//   ctx = target-local poly context
//   eps = tolerance
//   mode = foreign face fill rule
//   filter_parent = drop parent-edge cuts
function ps_face_foreign_proxy_volume_groups(face_pts2d, face_idx, ctx, eps=1e-8, mode="nonzero", filter_parent=true) =
    _ps_face_foreign_proxy_volume_groups_from_context(face_pts2d, face_idx, ctx, eps, mode, filter_parent);

// Function: _ps_proxy_volume_group_face_replay_sites_from_context()
// Usage:
//   result = _ps_proxy_volume_group_face_replay_sites_from_context(group, ctx, eps);
// Description:
//   Build renderable exact face replay sites for one proxy volume group from a target-local poly context.
//   .
//   - Returns: replay site records for exact foreign faces in the group
// Arguments:
//   group = proxy volume-group record returned by `ps_face_foreign_proxy_volume_groups(...)`.
//   ctx = target-local poly context containing source faces and vertices in the current face frame.
//   eps = geometric tolerance for replay-frame construction.
function _ps_proxy_volume_group_face_replay_sites_from_context(group, ctx, eps=1e-8) =
    let(records = ps_proxy_volume_group_records(group))
    [
        for (ri = [0:1:len(records)-1])
            _ps_face_foreign_face_replay_site(ri, records[ri], ctx, eps)
    ];

// Function: ps_proxy_volume_group_face_replay_sites()
// Usage:
//   result = ps_proxy_volume_group_face_replay_sites(group, ctx, eps);
// Description:
//   Build renderable exact face replay sites for one proxy volume group from a target-local poly context.
//   .
//   - Returns: replay site records for exact foreign faces in the group
//   .
//   - Limitations/Gotchas: context-first public entry point
// Arguments:
//   group = proxy volume-group record
//   ctx = target-local poly context
//   eps = tolerance
function ps_proxy_volume_group_face_replay_sites(group, ctx, eps=1e-8) =
    _ps_proxy_volume_group_face_replay_sites_from_context(group, ctx, eps);

// Function: ps_face_sites()
// Usage:
//   result = ps_face_sites(poly, inter_radius, edge_len, classify, classify_opts);
// Description:
//   Build face placement site records for `place_on_faces(...)`.
//   .
//   - Returns: list of face site records `[face_idx, edge_len, vertex_count, face_midradius, face_radius, face_planarity_err, face_is_planar, face_family_id, face_family_count, edge_family_count, vertex_family_count, frame, face_local_context]`
//   .
//   - Limitations/Gotchas: record shape is currently positional; keep the semantics stable even if the internal representation changes later
// Arguments:
//   poly = source poly descriptor.
//   inter_radius = target interradius scale used when `edge_len` is `undef`.
//   edge_len = explicit target edge length; overrides `inter_radius`.
//   classify = optional `poly_classify(...)` result to reuse for family ids.
//   classify_opts = optional `[detail, eps, radius, include_geom]` tuple used to compute classification when `classify` is `undef`.
function ps_face_sites(poly, inter_radius = 1, edge_len = undef, classify = undef, classify_opts = undef) =
    let(
        exp_edge_len = is_undef(edge_len) ? inter_radius * poly_e_over_ir(poly) : edge_len,
        scale = exp_edge_len,
        verts = poly_verts(poly),
        faces = poly_faces(poly),
        faces0 = ps_orient_all_faces_outward(verts, faces),
        edges = _ps_edges_from_faces(faces0),
        edge_faces = ps_edge_faces_table(faces0, edges),
        face_n = [ for (f = faces0) ps_face_frame_normal(verts, f) ],
        cls = _ps_resolve_classify(poly, classify, classify_opts),
        family_counts = is_undef(cls) ? undef : ps_classify_counts(cls),
        face_family_ids = is_undef(cls) ? [] : ps_classify_face_ids(cls, len(faces)),
        edge_family_count = is_undef(family_counts) ? undef : family_counts[1],
        vert_family_count = is_undef(family_counts) ? undef : family_counts[2]
    )
    [
        for (fi = [0:1:len(faces)-1])
            let(
                f = faces[fi],
                center = poly_face_center(poly, fi, scale),
                ex = poly_face_ex(poly, fi, scale),
                ey = poly_face_ey(poly, fi, scale),
                ez = poly_face_ez(poly, fi, scale),
                face_midradius = norm(center),
                rad_vec = [for (vid = f) norm(verts[vid] * scale - center)],
                face_radius = ps_sum(rad_vec) / len(rad_vec),
                poly_center_local_raw = [
                    v_dot(-center, ex),
                    v_dot(-center, ey),
                    v_dot(-center, ez)
                ],
                face_verts_local = [
                    for (vid = f)
                        let(p = verts[vid] * scale - center)
                            [v_dot(p, ex), v_dot(p, ey), v_dot(p, ez)]
                ],
                poly_verts_local_raw = [
                    for (vi = [0:1:len(verts)-1])
                        let(p = verts[vi] * scale - center)
                            [v_dot(p, ex), v_dot(p, ey), v_dot(p, ez)]
                ],
                zvals = [for (p = face_verts_local) p[2]],
                zmean = (len(zvals) == 0) ? 0 : ps_sum(zvals) / len(zvals),
                face_planarity_err = (len(zvals) == 0) ? 0 : max([for (z = zvals) abs(z - zmean)]),
                face_pts3d_local = [for (p = face_verts_local) [p[0], p[1], p[2] - zmean]],
                poly_center_local = [poly_center_local_raw[0], poly_center_local_raw[1], poly_center_local_raw[2] - zmean],
                poly_verts_local = [for (p = poly_verts_local_raw) [p[0], p[1], p[2] - zmean]],
                face_pts2d = ps_xy(face_pts3d_local),
                frame = ps_placement_frame(center, ex, ey, ez),
                face_neighbors_idx = _ps_face_site_neighbors_idx(f, fi, faces0, edges, edge_faces),
                face_dihedrals = _ps_face_site_dihedrals(f, fi, faces0, edges, edge_faces, face_n)
            )
    [
        fi,
        exp_edge_len,
        len(face_pts2d),
        face_midradius,
        face_radius,
        face_planarity_err,
        face_planarity_err <= 1e-8,
        is_undef(cls) ? undef : face_family_ids[fi],
        is_undef(family_counts) ? undef : family_counts[0],
        edge_family_count,
        vert_family_count,
        frame,
        ps_face_local_context(
            face_pts3d_local,
            face_pts2d,
            fi,
                    faces,
                    poly_verts_local,
                    face_neighbors_idx,
                    face_dihedrals,
                    poly_center_local
                )
            ]
    ];

// Module: place_on_faces()
// Usage:
//   place_on_faces(poly, inter_radius, edge_len, classify, classify_opts, indices);
// Description:
//   Place children on selected faces of a polyhedron.
//   .
//   - Returns: none; exposes `$ps_face_*` metadata, `$ps_face_frame`, `$ps_face_local_context`, and `$ps_target_local_poly_context` for each selected face
//   .
//   - Limitations/Gotchas: `indices` filters the placement loop only; `ps_face_sites(...)` still builds the complete site list so element ids and classification metadata remain global
// Arguments:
//   poly = source poly descriptor.
//   inter_radius = target interradius scale used when `edge_len` is `undef`.
//   edge_len = explicit target edge length; overrides `inter_radius`.
//   classify = optional `poly_classify(...)` result to reuse for family ids.
//   classify_opts = optional `[detail, eps, radius, include_geom]` tuple used to compute classification when `classify` is `undef`.
//   indices = `undef` for all faces, one face index, or a list of face indices.
module place_on_faces(poly, inter_radius = 1, edge_len = undef, classify = undef, classify_opts = undef, indices = undef) {
    sites = ps_face_sites(poly, inter_radius, edge_len, classify, classify_opts);

    for (site = sites) {
        fi = ps_face_site_idx(site);
        if (_ps_place_idx_selected(fi, indices)) {
            frame = ps_face_site_frame(site);

            // Per-face metadata (local-space friendly) - mean average values where faces are irregular
            $ps_face_idx           = fi;
            $ps_face_frame         = frame;
            $ps_edge_len           = ps_face_site_edge_len(site);
            $ps_vertex_count       = ps_face_site_vertex_count(site);
            $ps_face_midradius     = ps_face_site_midradius(site);
            $ps_face_radius        = ps_face_site_radius(site);
            $ps_poly_center_local  = ps_face_site_poly_center_local(site);
            $ps_face_pts2d         = ps_face_site_pts2d(site);
            $ps_face_pts3d_local   = ps_face_site_pts3d_local(site);
            $ps_poly_verts_local   = ps_face_site_poly_verts_local(site);
            $ps_poly_faces_idx     = ps_face_site_poly_faces_idx(site);
            $ps_face_planarity_err = ps_face_site_planarity_err(site);
            $ps_face_is_planar     = ps_face_site_is_planar(site);
            $ps_face_family_id     = ps_face_site_family_id(site);
            $ps_face_family_count  = ps_face_site_face_family_count(site);
            $ps_edge_family_count  = ps_face_site_edge_family_count(site);
            $ps_vertex_family_count = ps_face_site_vertex_family_count(site);
            $ps_face_neighbors_idx = ps_face_site_neighbors_idx(site);
            $ps_face_dihedrals     = ps_face_site_dihedrals(site);
            $ps_target_local_poly_context = ps_face_site_target_local_poly_context(site);
            $ps_face_local_context        = ps_face_site_face_local_context(site);

            multmatrix(ps_placement_frame_matrix(frame))
                children();
        }
    }
}

// Module: place_on_face_foreign_face_replay_sites()
// Usage:
//   place_on_face_foreign_face_replay_sites(mode, eps, filter_parent, coords);
// Description:
//   Replay exact foreign face intrusion sites inside the current placed target face.
//   .
//   - Returns: none; exposes `$ps_replay_*` metadata and optionally places children in the foreign face replay frame
//   .
//   - Limitations/Gotchas: requires `place_on_faces(...)`; does not generate or subtract proxy geometry
// Arguments:
//   mode = face-arrangement fill rule: `"nonzero"`, `"evenodd"`, or `"all"`.
//   eps = geometric tolerance for intrusion/arrangement calculations.
//   filter_parent = whether to drop cuts caused only by the current face's own boundary adjacency.
//   coords = `"element"` to enter each foreign face frame before calling children, or `"parent"` to keep children in the current face-local frame.
module place_on_face_foreign_face_replay_sites(mode="nonzero", eps=1e-8, filter_parent=true, coords="element") {
    assert(!is_undef($ps_face_pts2d), "place_on_face_foreign_face_replay_sites: requires place_on_faces context ($ps_face_pts2d)");
    assert(!is_undef($ps_face_idx), "place_on_face_foreign_face_replay_sites: requires place_on_faces context ($ps_face_idx)");
    assert(!is_undef($ps_face_local_context), "place_on_face_foreign_face_replay_sites: requires place_on_faces context ($ps_face_local_context)");
    assert(!is_undef($ps_target_local_poly_context), "place_on_face_foreign_face_replay_sites: requires place_on_faces context ($ps_target_local_poly_context)");
    assert(coords == "element" || coords == "parent", "place_on_face_foreign_face_replay_sites: coords must be \"element\" or \"parent\"");

    target_ctx = $ps_target_local_poly_context;
    face_ctx = $ps_face_local_context;
    sites = ps_face_foreign_face_replay_sites($ps_face_pts2d, $ps_face_idx, target_ctx, eps, mode, filter_parent);
    for (site = sites) {
        face_site = ps_replay_site_face_site(site);
        $ps_replay_idx = ps_replay_site_idx(site);
        $ps_replay_count = len(sites);
        $ps_replay_intrusion_record = ps_replay_site_intrusion_record(site);
        $ps_replay_kind = "foreign_face";
        $ps_replay_foreign_kind = ps_replay_site_foreign_kind(site);
        $ps_replay_foreign_idx = ps_replay_site_foreign_idx(site);
        $ps_replay_center_local = ps_replay_site_center_local(site);
        $ps_replay_ex_local = ps_replay_site_ex_local(site);
        $ps_replay_ey_local = ps_replay_site_ey_local(site);
        $ps_replay_ez_local = ps_replay_site_ez_local(site);
        $ps_replay_face_pts2d = ps_replay_site_face_pts2d(site);
        $ps_replay_face_pts3d_local = ps_replay_site_face_pts3d_local(site);
        $ps_replay_poly_verts_local = ps_replay_site_poly_verts_local(site);
        $ps_replay_poly_center_local = ps_replay_site_poly_center_local(site);
        $ps_replay_face_verts_idx = ps_replay_site_face_verts_idx(site);
        $ps_replay_intrusion_segment2d_local = ps_replay_site_intrusion_segment2d_local(site);
        $ps_replay_intrusion_dihedral = ps_replay_site_intrusion_dihedral(site);
        $ps_replay_intrusion_confidence = ps_replay_site_intrusion_confidence(site);

        if (coords == "element") {
            face_frame = ps_face_site_frame(face_site);
            $ps_face_idx           = ps_face_site_idx(face_site);
            $ps_face_frame         = face_frame;
            $ps_edge_len           = ps_face_site_edge_len(face_site);
            $ps_vertex_count       = ps_face_site_vertex_count(face_site);
            $ps_face_midradius     = ps_face_site_midradius(face_site);
            $ps_face_radius        = ps_face_site_radius(face_site);
            $ps_poly_center_local  = ps_face_site_poly_center_local(face_site);
            $ps_face_pts2d         = ps_face_site_pts2d(face_site);
            $ps_face_pts3d_local   = ps_face_site_pts3d_local(face_site);
            $ps_poly_verts_local   = ps_face_site_poly_verts_local(face_site);
            $ps_poly_faces_idx     = ps_face_site_poly_faces_idx(face_site);
            $ps_face_planarity_err = ps_face_site_planarity_err(face_site);
            $ps_face_is_planar     = ps_face_site_is_planar(face_site);
            $ps_face_family_id     = ps_face_site_family_id(face_site);
            $ps_face_family_count  = ps_face_site_face_family_count(face_site);
            $ps_edge_family_count  = ps_face_site_edge_family_count(face_site);
            $ps_vertex_family_count = ps_face_site_vertex_family_count(face_site);
            $ps_face_neighbors_idx = ps_face_site_neighbors_idx(face_site);
            $ps_face_dihedrals     = ps_face_site_dihedrals(face_site);
            $ps_target_local_poly_context = ps_face_site_target_local_poly_context(face_site);
            $ps_face_local_context        = ps_face_site_face_local_context(face_site);

            multmatrix(ps_placement_frame_matrix(face_frame))
                children();
        } else {
            children();
        }
    }
}

// Module: place_on_face_foreign_proxy_sites()
// Usage:
//   place_on_face_foreign_proxy_sites(mode, eps, filter_parent, coords, face_child, edge_child, vertex_child);
// Description:
//   Replay caller-supplied proxy geometry for foreign sites affecting the current placed face.
//   .
//   - Returns: none; exposes `$ps_proxy_*` metadata and calls the child slot matching the foreign source kind
//   .
//   - Limitations/Gotchas: face sites are exact face-plane intrusions; edge/vertex sites are deduped boundary candidates from those intruding faces, not distance-envelope proximity tests
// Arguments:
//   mode = face-arrangement fill rule: `"nonzero"`, `"evenodd"`, or `"all"`.
//   eps = geometric tolerance for intrusion/arrangement calculations.
//   filter_parent = whether to drop cuts caused only by the current face's own boundary adjacency.
//   coords = `"element"` to enter the replayed face/edge/vertex frame before calling the selected child, or `"parent"` to stay in the current face-local frame.
//   face_child = child slot used for foreign face proxies.
//   edge_child = child slot used for foreign edge proxies.
//   vertex_child = child slot used for foreign vertex proxies.
module place_on_face_foreign_proxy_sites(
    mode="nonzero",
    eps=1e-8,
    filter_parent=true,
    coords="element",
    face_child=0,
    edge_child=1,
    vertex_child=2
) {
    assert(!is_undef($ps_face_pts2d), "place_on_face_foreign_proxy_sites: requires place_on_faces context ($ps_face_pts2d)");
    assert(!is_undef($ps_face_idx), "place_on_face_foreign_proxy_sites: requires place_on_faces context ($ps_face_idx)");
    assert(!is_undef($ps_face_local_context), "place_on_face_foreign_proxy_sites: requires place_on_faces context ($ps_face_local_context)");
    assert(!is_undef($ps_target_local_poly_context), "place_on_face_foreign_proxy_sites: requires place_on_faces context ($ps_target_local_poly_context)");
    assert(coords == "element" || coords == "parent", "place_on_face_foreign_proxy_sites: coords must be \"element\" or \"parent\"");
    assert(face_child >= 0 && edge_child >= 0 && vertex_child >= 0, "place_on_face_foreign_proxy_sites: child slot indices must be non-negative");

    target_ctx = $ps_target_local_poly_context;
    sites = ps_face_foreign_proxy_replay_sites($ps_face_pts2d, $ps_face_idx, target_ctx, eps, mode, filter_parent);
    for (site = sites) {
        source_kind = ps_replay_site_foreign_kind(site);
        face_site = ps_replay_site_face_site(site);
        edge_site = ps_replay_site_edge_site(site);
        vertex_site = ps_replay_site_vertex_site(site);
        child_idx =
            source_kind == "face" ? face_child :
            source_kind == "edge" ? edge_child :
            source_kind == "vertex" ? vertex_child :
            undef;

        $ps_proxy_idx = ps_replay_site_idx(site);
        $ps_proxy_count = len(sites);
        $ps_proxy_kind = str("foreign_", source_kind);
        $ps_proxy_source_kind = source_kind;
        $ps_proxy_source_idx = ps_replay_site_foreign_idx(site);
        $ps_proxy_target_face_idx = $ps_face_idx;
        $ps_proxy_child_idx = child_idx;
        $ps_proxy_intrusion_record = ps_replay_site_intrusion_record(site);
        $ps_proxy_intrusion_segment2d_local = ps_replay_site_intrusion_segment2d_local(site);
        $ps_proxy_intrusion_dihedral = ps_replay_site_intrusion_dihedral(site);
        $ps_proxy_intrusion_confidence = ps_replay_site_intrusion_confidence(site);
        $ps_proxy_center_local = ps_replay_site_center_local(site);
        $ps_proxy_ex_local = ps_replay_site_ex_local(site);
        $ps_proxy_ey_local = ps_replay_site_ey_local(site);
        $ps_proxy_ez_local = ps_replay_site_ez_local(site);
        $ps_proxy_face_pts2d = ps_replay_site_face_pts2d(site);
        $ps_proxy_face_pts3d_local = ps_replay_site_face_pts3d_local(site);
        $ps_proxy_face_verts_idx = ps_replay_site_face_verts_idx(site);
        $ps_proxy_edge_pts_local = is_undef(edge_site) ? undef : ps_edge_site_pts_local(edge_site);
        $ps_proxy_edge_verts_idx = is_undef(edge_site) ? undef : ps_edge_site_verts_idx(edge_site);
        $ps_proxy_edge_adj_faces_idx = is_undef(edge_site) ? undef : ps_edge_site_adj_faces_idx(edge_site);
        $ps_proxy_vertex_valence = is_undef(vertex_site) ? undef : ps_vertex_site_valence(vertex_site);
        $ps_proxy_vertex_neighbors_idx = is_undef(vertex_site) ? undef : ps_vertex_site_neighbors_idx(vertex_site);
        $ps_proxy_vertex_neighbor_pts_local = is_undef(vertex_site) ? undef : ps_vertex_site_neighbor_pts_local(vertex_site);
        $ps_proxy_poly_verts_local = ps_replay_site_poly_verts_local(site);
        $ps_proxy_poly_center_local = ps_replay_site_poly_center_local(site);
        $ps_replay_idx = ps_replay_site_idx(site);
        $ps_replay_count = len(sites);
        $ps_replay_intrusion_record = ps_replay_site_intrusion_record(site);
        $ps_replay_kind = str("foreign_", source_kind);
        $ps_replay_foreign_kind = source_kind;
        $ps_replay_foreign_idx = ps_replay_site_foreign_idx(site);
        $ps_replay_center_local = ps_replay_site_center_local(site);
        $ps_replay_ex_local = ps_replay_site_ex_local(site);
        $ps_replay_ey_local = ps_replay_site_ey_local(site);
        $ps_replay_ez_local = ps_replay_site_ez_local(site);
        $ps_replay_face_pts2d = ps_replay_site_face_pts2d(site);
        $ps_replay_face_pts3d_local = ps_replay_site_face_pts3d_local(site);
        $ps_replay_poly_verts_local = ps_replay_site_poly_verts_local(site);
        $ps_replay_poly_center_local = ps_replay_site_poly_center_local(site);
        $ps_replay_face_verts_idx = ps_replay_site_face_verts_idx(site);
        $ps_replay_edge_pts_local = is_undef(edge_site) ? undef : ps_edge_site_pts_local(edge_site);
        $ps_replay_edge_verts_idx = is_undef(edge_site) ? undef : ps_edge_site_verts_idx(edge_site);
        $ps_replay_edge_adj_faces_idx = is_undef(edge_site) ? undef : ps_edge_site_adj_faces_idx(edge_site);
        $ps_replay_vertex_valence = is_undef(vertex_site) ? undef : ps_vertex_site_valence(vertex_site);
        $ps_replay_vertex_neighbors_idx = is_undef(vertex_site) ? undef : ps_vertex_site_neighbors_idx(vertex_site);
        $ps_replay_vertex_neighbor_pts_local = is_undef(vertex_site) ? undef : ps_vertex_site_neighbor_pts_local(vertex_site);
        $ps_replay_intrusion_segment2d_local = ps_replay_site_intrusion_segment2d_local(site);
        $ps_replay_intrusion_dihedral = ps_replay_site_intrusion_dihedral(site);
        $ps_replay_intrusion_confidence = ps_replay_site_intrusion_confidence(site);

        if (!is_undef(child_idx) && child_idx < $children) {
            if (coords == "element") {
                if (source_kind == "face") {
                    face_frame = ps_face_site_frame(face_site);
                    $ps_face_idx           = ps_face_site_idx(face_site);
                    $ps_face_frame         = face_frame;
                    $ps_edge_len           = ps_face_site_edge_len(face_site);
                    $ps_vertex_count       = ps_face_site_vertex_count(face_site);
                    $ps_face_midradius     = ps_face_site_midradius(face_site);
                    $ps_face_radius        = ps_face_site_radius(face_site);
                    $ps_poly_center_local  = ps_face_site_poly_center_local(face_site);
                    $ps_face_pts2d         = ps_face_site_pts2d(face_site);
                    $ps_face_pts3d_local   = ps_face_site_pts3d_local(face_site);
                    $ps_poly_verts_local   = ps_face_site_poly_verts_local(face_site);
                    $ps_poly_faces_idx     = ps_face_site_poly_faces_idx(face_site);
                    $ps_face_planarity_err = ps_face_site_planarity_err(face_site);
                    $ps_face_is_planar     = ps_face_site_is_planar(face_site);
                    $ps_face_family_id     = ps_face_site_family_id(face_site);
                    $ps_face_family_count  = ps_face_site_face_family_count(face_site);
                    $ps_edge_family_count  = ps_face_site_edge_family_count(face_site);
                    $ps_vertex_family_count = ps_face_site_vertex_family_count(face_site);
                    $ps_face_neighbors_idx = ps_face_site_neighbors_idx(face_site);
                    $ps_face_dihedrals     = ps_face_site_dihedrals(face_site);
                    $ps_target_local_poly_context = ps_face_site_target_local_poly_context(face_site);
                    $ps_face_local_context        = ps_face_site_face_local_context(face_site);

                    multmatrix(ps_placement_frame_matrix(face_frame))
                        children(child_idx);
                } else if (source_kind == "edge") {
                    edge_frame = ps_edge_site_frame(edge_site);
                    $ps_edge_idx            = ps_edge_site_idx(edge_site);
                    $ps_edge_frame          = edge_frame;
                    $ps_edge_len            = ps_edge_site_edge_len(edge_site);
                    $ps_edge_midradius      = ps_edge_site_midradius(edge_site);
                    $ps_poly_center_local   = ps_edge_site_poly_center_local(edge_site);
                    $ps_edge_pts_local      = ps_edge_site_pts_local(edge_site);
                    $ps_edge_verts_idx      = ps_edge_site_verts_idx(edge_site);
                    $ps_edge_adj_faces_idx  = ps_edge_site_adj_faces_idx(edge_site);
                    $ps_edge_family_id      = ps_edge_site_family_id(edge_site);
                    $ps_face_family_count   = ps_edge_site_face_family_count(edge_site);
                    $ps_edge_family_count   = ps_edge_site_edge_family_count(edge_site);
                    $ps_vertex_family_count = ps_edge_site_vertex_family_count(edge_site);

                    multmatrix(ps_placement_frame_matrix(edge_frame))
                        children(child_idx);
                } else if (source_kind == "vertex") {
                    vertex_frame = ps_vertex_site_frame(vertex_site);
                    $ps_vertex_idx                = ps_vertex_site_idx(vertex_site);
                    $ps_vertex_frame              = vertex_frame;
                    $ps_vertex_valence            = ps_vertex_site_valence(vertex_site);
                    $ps_vertex_neighbors_idx      = ps_vertex_site_neighbors_idx(vertex_site);
                    $ps_vertex_neighbor_pts_local = ps_vertex_site_neighbor_pts_local(vertex_site);
                    $ps_edge_len                  = ps_vertex_site_edge_len(vertex_site);
                    $ps_vert_radius               = ps_vertex_site_radius(vertex_site);
                    $ps_poly_center_local         = ps_vertex_site_poly_center_local(vertex_site);
                    $ps_vertex_family_id          = ps_vertex_site_family_id(vertex_site);
                    $ps_face_family_count         = ps_vertex_site_face_family_count(vertex_site);
                    $ps_edge_family_count         = ps_vertex_site_edge_family_count(vertex_site);
                    $ps_vertex_family_count       = ps_vertex_site_vertex_family_count(vertex_site);

                    multmatrix(ps_placement_frame_matrix(vertex_frame))
                        children(child_idx);
                }
            } else {
                children(child_idx);
            }
        }
    }
}

// Module: place_on_face_foreign_proxy_volume_groups()
// Usage:
//   place_on_face_foreign_proxy_volume_groups(mode, eps, filter_parent);
// Description:
//   Iterate data-only connected foreign proxy volume groups affecting the current placed face.
//   .
//   - Returns: none; exposes `$ps_proxy_volume_group_*` metadata and calls children in the current face-local frame
//   .
//   - Limitations/Gotchas: this is a provenance iterator only; it does not construct or transform a solid volume
// Arguments:
//   mode = face-arrangement fill rule: `"nonzero"`, `"evenodd"`, or `"all"`.
//   eps = geometric tolerance for intrusion/arrangement calculations.
//   filter_parent = whether to drop cuts caused only by the current face's own boundary adjacency.
module place_on_face_foreign_proxy_volume_groups(mode="nonzero", eps=1e-8, filter_parent=true) {
    assert(!is_undef($ps_face_pts2d), "place_on_face_foreign_proxy_volume_groups: requires place_on_faces context ($ps_face_pts2d)");
    assert(!is_undef($ps_face_idx), "place_on_face_foreign_proxy_volume_groups: requires place_on_faces context ($ps_face_idx)");
    assert(!is_undef($ps_face_local_context), "place_on_face_foreign_proxy_volume_groups: requires place_on_faces context ($ps_face_local_context)");
    assert(!is_undef($ps_target_local_poly_context), "place_on_face_foreign_proxy_volume_groups: requires place_on_faces context ($ps_target_local_poly_context)");

    target_ctx = $ps_target_local_poly_context;
    groups = ps_face_foreign_proxy_volume_groups($ps_face_pts2d, $ps_face_idx, target_ctx, eps, mode, filter_parent);
    for (group = groups) {
        $ps_proxy_volume_group_record = group;
        $ps_proxy_volume_group_idx = ps_proxy_volume_group_idx(group);
        $ps_proxy_volume_group_count = len(groups);
        $ps_proxy_volume_group_kind = ps_proxy_volume_group_kind(group);
        $ps_proxy_volume_group_target_face_idx = ps_proxy_volume_group_target_face_idx(group);
        $ps_proxy_volume_group_face_idxs = ps_proxy_volume_group_face_idxs(group);
        $ps_proxy_volume_group_record_idxs = ps_proxy_volume_group_record_idxs(group);
        $ps_proxy_volume_group_records = ps_proxy_volume_group_records(group);
        $ps_proxy_volume_group_edge_idxs = ps_proxy_volume_group_edge_idxs(group);
        $ps_proxy_volume_group_vertex_idxs = ps_proxy_volume_group_vertex_idxs(group);
        $ps_proxy_volume_group_support_face_idxs = ps_proxy_volume_group_support_face_idxs(group);

        $ps_proxy_kind = "foreign_volume_group";
        $ps_proxy_source_kind = "volume_group";
        $ps_proxy_source_idx = ps_proxy_volume_group_idx(group);
        $ps_proxy_target_face_idx = ps_proxy_volume_group_target_face_idx(group);

        children();
    }
}

// Module: place_on_face_foreign_proxy_volume_group_faces()
// Usage:
//   place_on_face_foreign_proxy_volume_group_faces(mode, eps, filter_parent, coords);
// Description:
//   Iterate renderable exact foreign face units, grouped by proxy volume group.
//   .
//   - Returns: none; exposes `$ps_proxy_volume_group_*`, `$ps_proxy_volume_unit_*`, and face-compatible `$ps_proxy_*` metadata on child slot 0
//   .
//   - Limitations/Gotchas: emits grouped face replay units only; it does not infer or close the volume enclosed by those faces
// Arguments:
//   mode = face-arrangement fill rule: `"nonzero"`, `"evenodd"`, or `"all"`.
//   eps = geometric tolerance for intrusion/arrangement calculations.
//   filter_parent = whether to drop cuts caused only by the current face's own boundary adjacency.
//   coords = `"element"` to enter each replayed foreign face frame before calling child slot 0, or `"parent"` to stay in the current face-local frame.
module place_on_face_foreign_proxy_volume_group_faces(
    mode="nonzero",
    eps=1e-8,
    filter_parent=true,
    coords="element"
) {
    assert(!is_undef($ps_face_pts2d), "place_on_face_foreign_proxy_volume_group_faces: requires place_on_faces context ($ps_face_pts2d)");
    assert(!is_undef($ps_face_idx), "place_on_face_foreign_proxy_volume_group_faces: requires place_on_faces context ($ps_face_idx)");
    assert(!is_undef($ps_target_local_poly_context), "place_on_face_foreign_proxy_volume_group_faces: requires place_on_faces context ($ps_target_local_poly_context)");
    assert(coords == "element" || coords == "parent", "place_on_face_foreign_proxy_volume_group_faces: coords must be \"element\" or \"parent\"");

    target_ctx = $ps_target_local_poly_context;
    groups = ps_face_foreign_proxy_volume_groups($ps_face_pts2d, $ps_face_idx, target_ctx, eps, mode, filter_parent);
    for (group = groups) {
        sites = ps_proxy_volume_group_face_replay_sites(group, target_ctx, eps);
        for (site = sites) {
            face_site = ps_replay_site_face_site(site);

            $ps_proxy_volume_group_record = group;
            $ps_proxy_volume_group_idx = ps_proxy_volume_group_idx(group);
            $ps_proxy_volume_group_count = len(groups);
            $ps_proxy_volume_group_kind = ps_proxy_volume_group_kind(group);
            $ps_proxy_volume_group_target_face_idx = ps_proxy_volume_group_target_face_idx(group);
            $ps_proxy_volume_group_face_idxs = ps_proxy_volume_group_face_idxs(group);
            $ps_proxy_volume_group_record_idxs = ps_proxy_volume_group_record_idxs(group);
            $ps_proxy_volume_group_records = ps_proxy_volume_group_records(group);
            $ps_proxy_volume_group_edge_idxs = ps_proxy_volume_group_edge_idxs(group);
            $ps_proxy_volume_group_vertex_idxs = ps_proxy_volume_group_vertex_idxs(group);
            $ps_proxy_volume_group_support_face_idxs = ps_proxy_volume_group_support_face_idxs(group);

            $ps_proxy_volume_unit_idx = ps_replay_site_idx(site);
            $ps_proxy_volume_unit_count = len(sites);
            $ps_proxy_volume_unit_kind = "foreign_face";
            $ps_proxy_volume_unit_record = ps_replay_site_intrusion_record(site);
            $ps_proxy_volume_unit_record_idx = ps_proxy_volume_group_record_idxs(group)[ps_replay_site_idx(site)];

            $ps_proxy_idx = ps_replay_site_idx(site);
            $ps_proxy_count = len(sites);
            $ps_proxy_kind = "foreign_face";
            $ps_proxy_source_kind = "face";
            $ps_proxy_source_idx = ps_replay_site_foreign_idx(site);
            $ps_proxy_target_face_idx = $ps_face_idx;
            $ps_proxy_child_idx = 0;
            $ps_proxy_intrusion_record = ps_replay_site_intrusion_record(site);
            $ps_proxy_intrusion_segment2d_local = ps_replay_site_intrusion_segment2d_local(site);
            $ps_proxy_intrusion_dihedral = ps_replay_site_intrusion_dihedral(site);
            $ps_proxy_intrusion_confidence = ps_replay_site_intrusion_confidence(site);
            $ps_proxy_center_local = ps_replay_site_center_local(site);
            $ps_proxy_ex_local = ps_replay_site_ex_local(site);
            $ps_proxy_ey_local = ps_replay_site_ey_local(site);
            $ps_proxy_ez_local = ps_replay_site_ez_local(site);
            $ps_proxy_face_pts2d = ps_replay_site_face_pts2d(site);
            $ps_proxy_face_pts3d_local = ps_replay_site_face_pts3d_local(site);
            $ps_proxy_face_verts_idx = ps_replay_site_face_verts_idx(site);
            $ps_proxy_edge_pts_local = undef;
            $ps_proxy_edge_verts_idx = undef;
            $ps_proxy_edge_adj_faces_idx = undef;
            $ps_proxy_vertex_valence = undef;
            $ps_proxy_vertex_neighbors_idx = undef;
            $ps_proxy_vertex_neighbor_pts_local = undef;
            $ps_proxy_poly_verts_local = ps_replay_site_poly_verts_local(site);
            $ps_proxy_poly_center_local = ps_replay_site_poly_center_local(site);

            if (coords == "element") {
                face_frame = ps_face_site_frame(face_site);
                $ps_face_idx           = ps_face_site_idx(face_site);
                $ps_face_frame         = face_frame;
                $ps_edge_len           = ps_face_site_edge_len(face_site);
                $ps_vertex_count       = ps_face_site_vertex_count(face_site);
                $ps_face_midradius     = ps_face_site_midradius(face_site);
                $ps_face_radius        = ps_face_site_radius(face_site);
                $ps_poly_center_local  = ps_face_site_poly_center_local(face_site);
                $ps_face_pts2d         = ps_face_site_pts2d(face_site);
                $ps_face_pts3d_local   = ps_face_site_pts3d_local(face_site);
                $ps_poly_verts_local   = ps_face_site_poly_verts_local(face_site);
                $ps_poly_faces_idx     = ps_face_site_poly_faces_idx(face_site);
                $ps_face_planarity_err = ps_face_site_planarity_err(face_site);
                $ps_face_is_planar     = ps_face_site_is_planar(face_site);
                $ps_face_family_id     = ps_face_site_family_id(face_site);
                $ps_face_family_count   = ps_face_site_face_family_count(face_site);
                $ps_edge_family_count   = ps_face_site_edge_family_count(face_site);
                $ps_vertex_family_count = ps_face_site_vertex_family_count(face_site);
                $ps_face_neighbors_idx  = ps_face_site_neighbors_idx(face_site);
                $ps_face_dihedrals      = ps_face_site_dihedrals(face_site);
                $ps_target_local_poly_context = ps_face_site_target_local_poly_context(face_site);
                $ps_face_local_context        = ps_face_site_face_local_context(face_site);

                multmatrix(ps_placement_frame_matrix(face_frame))
                    children(0);
            } else {
                children(0);
            }
        }
    }
}

// Module: place_on_face_foreign_proxy_volume_group_hulls()
// Usage:
//   place_on_face_foreign_proxy_volume_group_hulls(mode, eps, filter_parent, point_r, point_fn);
// Description:
//   Render one conservative convex hull per foreign proxy volume group.
//   .
//   - Returns: none; emits a hull around grouped source-face vertices in the current face-local frame
//   .
//   - Limitations/Gotchas: debug/conservative helper only; convexifies each group and can over-subtract concave or disconnected real user geometry
// Arguments:
//   mode = face-arrangement fill rule: `"nonzero"`, `"evenodd"`, or `"all"`.
//   eps = geometric tolerance for intrusion/arrangement calculations.
//   filter_parent = whether to drop cuts caused only by the current face's own boundary adjacency.
//   point_r = radius of default hull marker spheres when no child is supplied.
//   point_fn = `$fn` facet count for default hull marker spheres.
module place_on_face_foreign_proxy_volume_group_hulls(
    mode="nonzero",
    eps=1e-8,
    filter_parent=true,
    point_r=0.04,
    point_fn=8
) {
    place_on_face_foreign_proxy_volume_groups(mode = mode, eps = eps, filter_parent = filter_parent) {
        group = $ps_proxy_volume_group_record;
        group_idx = $ps_proxy_volume_group_idx;
        group_count = $ps_proxy_volume_group_count;
        vertex_idxs = ps_proxy_volume_group_vertex_idxs(group);
        use_children = $children > 0;

        if (len(vertex_idxs) > 0) {
            _ps_place_on_face_foreign_proxy_volume_group_hull(
                group,
                group_idx,
                group_count,
                vertex_idxs,
                point_r,
                point_fn,
                use_children = use_children
            ) {
                children();
            }
        }
    }
}

module _ps_place_on_face_foreign_proxy_volume_group_hull(group, group_idx, group_count, vertex_idxs, point_r, point_fn, use_children=false) {
    $ps_proxy_kind = "foreign_volume_group_hull";
    $ps_proxy_source_kind = "volume_group";
    $ps_proxy_volume_group_record = group;
    $ps_proxy_volume_group_idx = group_idx;
    $ps_proxy_volume_group_count = group_count;
    $ps_proxy_source_idx = group_idx;
    $ps_proxy_volume_hull_vertex_idxs = vertex_idxs;
    $ps_proxy_volume_hull_vertex_count = len(vertex_idxs);

    hull() {
        for (vi = vertex_idxs) {
            $ps_proxy_volume_hull_vertex_idx = vi;
            $ps_proxy_volume_hull_vertex_pos_local = $ps_poly_verts_local[vi];

            translate($ps_poly_verts_local[vi]) {
                if (use_children)
                    children();
                else
                    sphere(r = point_r, $fn = point_fn);
            }
        }
    }
}

// Function: ps_edge_sites()
// Usage:
//   result = ps_edge_sites(poly, inter_radius, edge_len, classify, classify_opts);
// Description:
//   Build edge placement site records for `place_on_edges(...)`.
//   .
//   - Returns: list of edge site records `[edge_idx, edge_len, edge_midradius, poly_center_local, edge_pts_local, edge_verts_idx, edge_adj_faces_idx, edge_family_id, face_family_count, edge_family_count, vertex_family_count, frame]`
//   .
//   - Limitations/Gotchas: uses an adjacent-face normal bisector for `+Z` when a usable face pair exists, with radial fallback on boundary or degenerate edges
// Arguments:
//   poly = source poly descriptor.
//   inter_radius = target interradius scale used when `edge_len` is `undef`.
//   edge_len = explicit target edge length; overrides `inter_radius`.
//   classify = optional `poly_classify(...)` result to reuse for family ids.
//   classify_opts = optional `[detail, eps, radius, include_geom]` tuple used to compute classification when `classify` is `undef`.
function ps_edge_sites(poly, inter_radius = 1, edge_len = undef, classify = undef, classify_opts = undef) =
    let(
        exp_edge_len = is_undef(edge_len) ? inter_radius * poly_e_over_ir(poly) : edge_len,
        scale = exp_edge_len,
        verts = poly_verts(poly),
        faces = poly_faces(poly),
        faces0 = ps_orient_all_faces_outward(verts, faces),
        edges = _ps_edges_from_faces(faces),
        edge_faces = ps_edge_faces_table(faces0, edges),
        face_n = [for (f = faces0) ps_face_frame_normal(verts, f)],
        cls = _ps_resolve_classify(poly, classify, classify_opts),
        family_counts = is_undef(cls) ? undef : ps_classify_counts(cls),
        edge_family_ids = is_undef(cls) ? [] : ps_classify_edge_ids(cls, len(edges)),
        face_family_count = is_undef(family_counts) ? undef : family_counts[0],
        edge_family_count = is_undef(family_counts) ? undef : family_counts[1],
        vert_family_count = is_undef(family_counts) ? undef : family_counts[2]
    )
    [
        for (ei = [0:1:len(edges)-1])
            let(
                e = edges[ei],
                v0 = verts[e[0]] * scale,
                v1 = verts[e[1]] * scale,
                center = (v0 + v1) / 2,
                ex = v_norm(v1 - v0),
                adj_faces_idx = edge_faces[ei],
                radial_ref = v_norm(center),
                bisector_raw =
                    (len(adj_faces_idx) < 2)
                        ? radial_ref
                        : face_n[adj_faces_idx[0]] + face_n[adj_faces_idx[1]],
                bisector_signed =
                    (norm(bisector_raw) <= 1e-12)
                        ? radial_ref
                        : ((v_dot(bisector_raw, radial_ref) < 0) ? -bisector_raw : bisector_raw),
                ez_proj = bisector_signed - ex * v_dot(bisector_signed, ex),
                radial_proj = radial_ref - ex * v_dot(radial_ref, ex),
                ez_dir =
                    (norm(ez_proj) <= 1e-12)
                        ? radial_proj
                        : ez_proj,
                ez = v_norm(ez_dir),
                ey = v_norm(v_cross(ez, ex)),
                edge_midradius = norm(center),
                edge_len_actual = norm(v1 - v0),
                poly_center_local = [
                    v_dot(-center, ex),
                    v_dot(-center, ey),
                    v_dot(-center, ez)
                ],
                frame = ps_placement_frame(center, ex, ey, ez),
                edge_pts_local = [[-edge_len_actual/2, 0, 0], [edge_len_actual/2, 0, 0]]
            )
            [
                ei,
                edge_len_actual,
                edge_midradius,
                poly_center_local,
                edge_pts_local,
                e,
                adj_faces_idx,
                is_undef(cls) ? undef : edge_family_ids[ei],
                face_family_count,
                edge_family_count,
                vert_family_count,
                frame
            ]
    ];

// Function: ps_vertex_sites()
// Usage:
//   result = ps_vertex_sites(poly, inter_radius, edge_len, classify, classify_opts);
// Description:
//   Build vertex placement site records for `place_on_vertices(...)`.
//   .
//   - Returns: list of vertex site records `[vertex_idx, edge_len, vert_radius, poly_center_local, vertex_valence, vertex_neighbors_idx, vertex_neighbor_pts_local, vertex_family_id, face_family_count, edge_family_count, vertex_family_count, frame, vertex_figure]`
//   .
//   - Limitations/Gotchas: simple closed-manifold vertices use cyclic fan order anchored at the lowest neighbour index; boundary and singular vertices keep edge-scan neighbour order so open construction outputs and degenerate construction results remain placeable
// Arguments:
//   poly = source poly descriptor.
//   inter_radius = target interradius scale used when `edge_len` is `undef`.
//   edge_len = explicit target edge length; overrides `inter_radius`.
//   classify = optional `poly_classify(...)` result to reuse for family ids.
//   classify_opts = optional `[detail, eps, radius, include_geom]` tuple used to compute classification when `classify` is `undef`.
function ps_vertex_sites(poly, inter_radius = 1, edge_len = undef, classify = undef, classify_opts = undef) =
    let(
        exp_edge_len = is_undef(edge_len) ? inter_radius * poly_e_over_ir(poly) : edge_len,
        scale = exp_edge_len,
        verts = poly_verts(poly),
        faces = poly_faces(poly),
        edges = _ps_edges_from_faces(faces),
        edge_faces = ps_edge_faces_table(faces, edges),
        cls = _ps_resolve_classify(poly, classify, classify_opts),
        family_counts = is_undef(cls) ? undef : ps_classify_counts(cls),
        vert_family_ids = is_undef(cls) ? [] : ps_classify_vert_ids(cls, len(verts)),
        face_family_count = is_undef(family_counts) ? undef : family_counts[0],
        edge_family_count = is_undef(family_counts) ? undef : family_counts[1],
        vert_family_count = is_undef(family_counts) ? undef : family_counts[2]
    )
    [
        for (vi = [0:1:len(verts)-1])
            let(
                v0 = verts[vi] * scale,
                ez = v_norm(v0),
                closed_fan = _ps_vertex_site_has_closed_fan(faces, edges, edge_faces, vi),
                fan = closed_fan ? ps_vertex_fan(poly, vi, edges, edge_faces) : undef,
                vertex_figure = is_undef(fan) ? undef : _ps_vertex_figure_from_fan(fan),
                neighbors_idx = closed_fan
                    ? ps_vertex_fan_neighbors_idx(fan)
                    : _ps_vertex_site_neighbors_idx(edges, vi),
                ni = neighbors_idx[0],
                v1 = verts[ni] * scale,
                neighbor_dir = v1 - v0,
                proj = neighbor_dir - ez * v_dot(neighbor_dir, ez),
                proj_len = norm(proj),
                ex = (proj_len == 0) ? _ps_any_perp(ez) : proj / proj_len,
                ey = v_cross(ez, ex),
                center = v0,
                vert_radius = norm(center),
                valence = len(neighbors_idx),
                neighbor_pts_local = [
                    for (nj = neighbors_idx)
                        let(pw = verts[nj] * scale - v0)
                            [v_dot(pw, ex), v_dot(pw, ey), v_dot(pw, ez)]
                ],
                frame = ps_placement_frame(center, ex, ey, ez)
            )
            [
                vi,
                exp_edge_len,
                vert_radius,
                [0, 0, -vert_radius],
                valence,
                neighbors_idx,
                neighbor_pts_local,
                is_undef(cls) ? undef : vert_family_ids[vi],
                face_family_count,
                edge_family_count,
                vert_family_count,
                frame,
                vertex_figure
            ]
    ];

// Module: place_on_vertices()
// Usage:
//   place_on_vertices(poly, inter_radius, edge_len, classify, classify_opts, indices);
// Description:
//   Place children on selected vertices of a polyhedron.
//   .
//   - Returns: none; exposes `$ps_vertex_*` metadata and `$ps_vertex_frame` for each selected vertex
//   .
//   - Limitations/Gotchas: `indices` filters the placement loop only; `ps_vertex_sites(...)` still builds the complete site list so element ids and classification metadata remain global
// Arguments:
//   poly = source poly descriptor.
//   inter_radius = target interradius scale used when `edge_len` is `undef`.
//   edge_len = explicit target edge length; overrides `inter_radius`.
//   classify = optional `poly_classify(...)` result to reuse for family ids.
//   classify_opts = optional `[detail, eps, radius, include_geom]` tuple used to compute classification when `classify` is `undef`.
//   indices = `undef` for all vertices, one vertex index, or a list of vertex indices.
module place_on_vertices(poly, inter_radius = 1, edge_len = undef, classify = undef, classify_opts = undef, indices = undef) {
    sites = ps_vertex_sites(poly, inter_radius, edge_len, classify, classify_opts);

    for (site = sites) {
        if (_ps_place_idx_selected(ps_vertex_site_idx(site), indices)) {
            // Metadata for children (local-space friendly)
            $ps_vertex_idx                = ps_vertex_site_idx(site);
            $ps_vertex_valence            = ps_vertex_site_valence(site);
            $ps_vertex_neighbors_idx      = ps_vertex_site_neighbors_idx(site);
            $ps_vertex_neighbor_pts_local = ps_vertex_site_neighbor_pts_local(site);
            $ps_vertex_frame              = ps_vertex_site_frame(site);
            $ps_vertex_figure             = ps_vertex_site_vertex_figure(site);
            $ps_vertex_figure_faces_idx   = is_undef($ps_vertex_figure) ? undef : ps_vertex_figure_faces_idx($ps_vertex_figure);
            $ps_vertex_figure_edges_idx   = is_undef($ps_vertex_figure) ? undef : ps_vertex_figure_edges_idx($ps_vertex_figure);
            $ps_vertex_figure_neighbors_idx = is_undef($ps_vertex_figure) ? undef : ps_vertex_figure_neighbors_idx($ps_vertex_figure);

            $ps_edge_len                  = ps_vertex_site_edge_len(site);      // (target edge length parameter)
            $ps_vert_radius               = ps_vertex_site_radius(site);
            $ps_poly_center_local         = ps_vertex_site_poly_center_local(site);
            $ps_vertex_family_id          = ps_vertex_site_family_id(site);
            $ps_face_family_count         = ps_vertex_site_face_family_count(site);
            $ps_edge_family_count         = ps_vertex_site_edge_family_count(site);
            $ps_vertex_family_count       = ps_vertex_site_vertex_family_count(site);

            multmatrix(ps_placement_frame_matrix($ps_vertex_frame))
                children();
        }
    }
}


// Module: place_on_edges()
// Usage:
//   place_on_edges(poly, inter_radius, edge_len, classify, classify_opts, indices);
// Description:
//   Place children on selected edges of a polyhedron.
//   .
//   - Returns: none; exposes `$ps_edge_*` metadata and `$ps_edge_frame` for each selected edge
//   .
//   - Limitations/Gotchas: `indices` filters the placement loop only; `ps_edge_sites(...)` still builds the complete site list so element ids and classification metadata remain global
// Arguments:
//   poly = source poly descriptor.
//   inter_radius = target interradius scale used when `edge_len` is `undef`.
//   edge_len = explicit target edge length; overrides `inter_radius`.
//   classify = optional `poly_classify(...)` result to reuse for family ids.
//   classify_opts = optional `[detail, eps, radius, include_geom]` tuple used to compute classification when `classify` is `undef`.
//   indices = `undef` for all edges, one edge index, or a list of edge indices.
module place_on_edges(poly, inter_radius = 1, edge_len = undef, classify = undef, classify_opts = undef, indices = undef) {
    sites = ps_edge_sites(poly, inter_radius, edge_len, classify, classify_opts);

    for (site = sites) {
        if (_ps_place_idx_selected(ps_edge_site_idx(site), indices)) {
            // Metadata for children (edge-local)
            $ps_edge_idx            = ps_edge_site_idx(site);
            $ps_edge_len            = ps_edge_site_edge_len(site);      // actual length of this edge (vs supplied edge_len = scaling factor arg)
            $ps_edge_midradius      = ps_edge_site_midradius(site);
            $ps_poly_center_local   = ps_edge_site_poly_center_local(site);

            $ps_edge_pts_local      = ps_edge_site_pts_local(site);
            $ps_edge_verts_idx      = ps_edge_site_verts_idx(site);
            $ps_edge_adj_faces_idx  = ps_edge_site_adj_faces_idx(site);
            $ps_edge_family_id      = ps_edge_site_family_id(site);
            $ps_face_family_count   = ps_edge_site_face_family_count(site);
            $ps_edge_family_count   = ps_edge_site_edge_family_count(site);
            $ps_vertex_family_count = ps_edge_site_vertex_family_count(site);
            $ps_edge_frame          = ps_edge_site_frame(site);

            multmatrix(ps_placement_frame_matrix($ps_edge_frame))
                children();
        }
    }
}


module ps_face_debug() {
    // Face index
    color("white") translate([0,0,2])
        text(str($ps_face_idx), size=5, halign="center", valign="center");

    // Local axes
    color("red")   cube([8,1,1], center=false);
    color("green") rotate([0,0,90]) cube([8,1,1], center=false);
    color("blue")  rotate([0,-90,0]) cube([8,1,1], center=false);

    // Radial line to centre
    color("yellow") cylinder(h = -$ps_poly_center_local[2], r = 0.5, center=false);
}
