/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

// LibFile: polysymmetrica/core/vertex.scad
use <funcs.scad>

_PS_VERTEX_FIGURE_CAP_MODES = ["planar_edge_fraction", "edge_fraction", "centric", "poly_centroidal"];

// Function: _ps_face_vertex_count()
// Usage:
//   result = _ps_face_vertex_count(face, vi);
// Description:
//   Count occurrences of a vertex in one face loop.
//   .
//   - Returns: occurrence count
// Arguments:
//   face = face index loop
//   vi = vertex index
function _ps_face_vertex_count(face, vi) =
    len([for (k = [0 : len(face)-1]) if (face[k] == vi) 1]);

// Function: _ps_vertex_incident_face_indices()
// Usage:
//   result = _ps_vertex_incident_face_indices(faces, vi);
// Description:
//   Find face indices incident to a vertex from a face list.
//   .
//   - Returns: unordered face-index list
// Arguments:
//   faces = face list
//   vi = vertex index
function _ps_vertex_incident_face_indices(faces, vi) =
    [
        for (fi = [0 : len(faces)-1])
            if (_ps_face_vertex_count(faces[fi], vi) > 0) fi
    ];

// Function: ps_vertex_incident_faces()
// Usage:
//   result = ps_vertex_incident_faces(poly, vi);
// Description:
//   Find faces incident to a vertex.
//   .
//   - Returns: unordered face-index list
// Arguments:
//   poly = poly descriptor
//   vi = vertex index
function ps_vertex_incident_faces(poly, vi) =
    _ps_vertex_incident_face_indices(poly_faces(poly), vi);

// Function: _ps_next_face_around_vertex()
// Usage:
//   result = _ps_next_face_around_vertex(v, f_cur, f_prev, faces, edges, edge_faces);
// Description:
//   Pick next incident face around a vertex.
//   .
//   - Returns: next face index in the local fan
//   .
//   - Limitations/Gotchas: assumes manifold local topology
// Arguments:
//   v = vertex index
//   f_cur = current face
//   f_prev = previous face
//   faces = topology tables
//   edges = topology tables
//   edge_faces = topology tables
function _ps_next_face_around_vertex(v, f_cur, f_prev, faces, edges, edge_faces) =
    let(
        f = faces[f_cur],
        n = len(f),
        pos = [for (k = [0 : n-1]) if (f[k] == v) k],
        _has_v = assert(len(pos) == 1, str("_ps_next_face_around_vertex: face ", f_cur, " must contain vertex ", v, " exactly once")),
        k0 = pos[0],
        k_prev = (k0 - 1 + n) % n,
        k_next = (k0 + 1) % n,
        v_prev = f[k_prev],
        v_next = f[k_next],
        ei1 = ps_find_edge_index(edges, v, v_next),
        ei2 = ps_find_edge_index(edges, v_prev, v),
        _edge1 = assert(ei1 >= 0, str("_ps_next_face_around_vertex: missing edge [", v, ",", v_next, "]")),
        _edge2 = assert(ei2 >= 0, str("_ps_next_face_around_vertex: missing edge [", v_prev, ",", v, "]")),
        ef1 = edge_faces[ei1],
        ef2 = edge_faces[ei2],
        _manifold1 = assert(len(ef1) == 2, str("_ps_next_face_around_vertex: edge [", v, ",", v_next, "] must have exactly two incident faces")),
        _manifold2 = assert(len(ef2) == 2, str("_ps_next_face_around_vertex: edge [", v_prev, ",", v, "] must have exactly two incident faces")),
        cand1 = (ef1[0] == f_cur ? ef1[1] : ef1[0]),
        cand2 = (ef2[0] == f_cur ? ef2[1] : ef2[0]),
        candidates = [cand1, cand2],
        filtered = [for (cf = candidates) if (cf != f_prev) cf]
    )
    filtered[0];

// Function: _ps_faces_around_vertex_rec()
// Usage:
//   result = _ps_faces_around_vertex_rec(v, f_cur, f_prev, f_start, faces, edges, edge_faces, acc);
// Description:
//   Recursively traverse incident faces around a vertex.
//   .
//   - Returns: cyclically ordered face-index list
// Arguments:
//   v = vertex index
//   f_cur = face indices
//   f_prev = face indices
//   f_start = face indices
//   faces = topology tables
//   edges = topology tables
//   edge_faces = topology tables
//   acc = accumulator
function _ps_faces_around_vertex_rec(v, f_cur, f_prev, f_start, faces, edges, edge_faces, acc = []) =
    let(next = _ps_next_face_around_vertex(v, f_cur, f_prev, faces, edges, edge_faces))
    (next == f_start)
        ? concat(acc, [f_cur])
        : _ps_faces_around_vertex_rec(v, next, f_cur, f_start, faces, edges, edge_faces, concat(acc, [f_cur]));

// Function: ps_faces_around_vertex()
// Usage:
//   result = ps_faces_around_vertex(poly, v, edges, edge_faces);
// Description:
//   Return incident faces around a vertex in cyclic order.
//   .
//   - Returns: ordered face-index list
//   .
//   - Limitations/Gotchas: assumes manifold vertex neighborhood
// Arguments:
//   poly = poly descriptor
//   v = vertex index
//   edges = edge list
//   edge_faces = edge-face table
function ps_faces_around_vertex(poly, v, edges, edge_faces) =
    let(
        faces = poly_faces(poly),
        inc = ps_vertex_incident_faces(poly, v),
        _has_inc = assert(len(inc) > 0, str("ps_faces_around_vertex: vertex ", v, " has no incident faces")),
        start = inc[0]
    )
    _ps_faces_around_vertex_rec(v, start, -1, start, faces, edges, edge_faces);

// Function: _ps_vertex_fan_neighbor_for_face()
// Usage:
//   result = _ps_vertex_fan_neighbor_for_face(faces, face_idx, vertex_idx);
// Description:
//   Get the next vertex around one incident face for vertex-fan ordering.
//   .
//   - Returns: neighbour vertex index
// Arguments:
//   faces = face list
//   face_idx = incident face index
//   vertex_idx = source vertex index
function _ps_vertex_fan_neighbor_for_face(faces, face_idx, vertex_idx) =
    let(
        f = faces[face_idx],
        n = len(f),
        pos = _ps_index_of(f, vertex_idx),
        _has_v = assert(pos >= 0, str("_ps_vertex_fan_neighbor_for_face: face ", face_idx, " does not contain vertex ", vertex_idx))
    )
    f[(pos + 1) % n];

// Function: ps_vertex_fan()
// Usage:
//   result = ps_vertex_fan(poly, vertex_idx, edges, edge_faces);
// Description:
//   Build the abstract vertex fan for one source vertex.
//   .
//   The fan is the topological ordering of faces, neighbour vertices, and
//   incident edges around a vertex. Neighbours are cyclic and anchored at the
//   lowest neighbour index; cyclic direction follows the source face winding.
//   .
//   - Returns: vertex fan record `[vertex_idx, faces_idx, neighbors_idx, edges_idx]`
//   .
//   - Limitations/Gotchas: assumes a closed manifold local vertex neighbourhood
// Arguments:
//   poly = poly descriptor
//   vertex_idx = source vertex index
//   edges = optional edge list for reuse
//   edge_faces = optional edge-face table for reuse
function ps_vertex_fan(poly, vertex_idx, edges=undef, edge_faces=undef) =
    let(
        faces = poly_faces(poly),
        e = is_undef(edges) ? _ps_edges_from_faces(faces) : edges,
        ef = is_undef(edge_faces) ? ps_edge_faces_table(faces, e) : edge_faces,
        incident_faces = ps_vertex_incident_faces(poly, vertex_idx),
        faces_idx0 = ps_faces_around_vertex(poly, vertex_idx, e, ef),
        _complete = assert(
            len(faces_idx0) == len(incident_faces),
            str(
                "ps_vertex_fan: vertex ",
                vertex_idx,
                " has disconnected or pinched fan; traversed ",
                len(faces_idx0),
                " of ",
                len(incident_faces),
                " incident faces"
            )
        ),
        neighbors_idx0 = [
            for (fi = faces_idx0)
                _ps_vertex_fan_neighbor_for_face(faces, fi, vertex_idx)
        ],
        anchor_neighbor = min(neighbors_idx0),
        anchor = _ps_index_of(neighbors_idx0, anchor_neighbor),
        faces_idx = _ps_cycle_rotate(faces_idx0, anchor),
        neighbors_idx = _ps_cycle_rotate(neighbors_idx0, anchor),
        edges_idx = [
            for (nj = neighbors_idx)
                let(ei = ps_find_edge_index(e, vertex_idx, nj))
                assert(ei >= 0, str("ps_vertex_fan: missing edge [", vertex_idx, ",", nj, "]"))
                ei
        ]
    )
    [vertex_idx, faces_idx, neighbors_idx, edges_idx];

// Function: ps_vertex_fan_idx()
// Usage:
//   result = ps_vertex_fan_idx(fan);
// Description:
//   Get the source vertex index from a vertex fan.
//   .
//   - Returns: vertex index
// Arguments:
//   fan = vertex fan record
function ps_vertex_fan_idx(fan) = fan[0];

// Function: ps_vertex_fan_faces_idx()
// Usage:
//   result = ps_vertex_fan_faces_idx(fan);
// Description:
//   Get cyclic incident face indices from a vertex fan.
//   .
//   - Returns: face indices
// Arguments:
//   fan = vertex fan record
function ps_vertex_fan_faces_idx(fan) = fan[1];

// Function: ps_vertex_fan_neighbors_idx()
// Usage:
//   result = ps_vertex_fan_neighbors_idx(fan);
// Description:
//   Get cyclic adjacent vertex indices from a vertex fan.
//   .
//   - Returns: neighbour vertex indices
// Arguments:
//   fan = vertex fan record
function ps_vertex_fan_neighbors_idx(fan) = fan[2];

// Function: ps_vertex_fan_edges_idx()
// Usage:
//   result = ps_vertex_fan_edges_idx(fan);
// Description:
//   Get cyclic incident edge indices from a vertex fan.
//   .
//   - Returns: edge indices
// Arguments:
//   fan = vertex fan record
function ps_vertex_fan_edges_idx(fan) = fan[3];

function _ps_vertex_figure_from_fan(fan) =
    [
        ps_vertex_fan_idx(fan),
        ps_vertex_fan_faces_idx(fan),
        ps_vertex_fan_edges_idx(fan),
        ps_vertex_fan_neighbors_idx(fan)
    ];

// Function: ps_vertex_figure()
// Usage:
//   result = ps_vertex_figure(poly, vertex_idx, edges, edge_faces);
// Description:
//   Build the abstract vertex figure for one source vertex.
//   .
//   The vertex figure is topological, not metric: its vertices are the source
//   edges incident to `vertex_idx`, its sides are the source faces incident to
//   `vertex_idx`, and its neighbour list records the opposite endpoint of each
//   figure vertex. Ordering is the same cyclic order as `ps_vertex_fan(...)`,
//   anchored at the lowest neighbour index.
//   .
//   - Returns: vertex figure record `[vertex_idx, faces_idx, edges_idx, neighbors_idx]`
//   .
//   - Limitations/Gotchas: assumes a closed manifold local vertex neighbourhood
// Arguments:
//   poly = poly descriptor
//   vertex_idx = source vertex index
//   edges = optional edge list for reuse
//   edge_faces = optional edge-face table for reuse
function ps_vertex_figure(poly, vertex_idx, edges=undef, edge_faces=undef) =
    _ps_vertex_figure_from_fan(ps_vertex_fan(poly, vertex_idx, edges, edge_faces));

// Function: ps_vertex_figure_idx()
// Usage:
//   result = ps_vertex_figure_idx(fig);
// Description:
//   Get the source vertex index from a vertex figure.
//   .
//   - Returns: vertex index
// Arguments:
//   fig = vertex figure record
function ps_vertex_figure_idx(fig) = fig[0];

// Function: ps_vertex_figure_faces_idx()
// Usage:
//   result = ps_vertex_figure_faces_idx(fig);
// Description:
//   Get cyclic incident face indices from a vertex figure.
//   .
//   - Returns: face indices
// Arguments:
//   fig = vertex figure record
function ps_vertex_figure_faces_idx(fig) = fig[1];

// Function: ps_vertex_figure_edges_idx()
// Usage:
//   result = ps_vertex_figure_edges_idx(fig);
// Description:
//   Get cyclic incident edge indices from a vertex figure.
//   .
//   - Returns: edge indices
// Arguments:
//   fig = vertex figure record
function ps_vertex_figure_edges_idx(fig) = fig[2];

// Function: ps_vertex_figure_neighbors_idx()
// Usage:
//   result = ps_vertex_figure_neighbors_idx(fig);
// Description:
//   Get cyclic adjacent vertex indices from a vertex figure.
//   .
//   - Returns: neighbour vertex indices
// Arguments:
//   fig = vertex figure record
function ps_vertex_figure_neighbors_idx(fig) = fig[3];

// Function: ps_vertex_figure_cap_modes()
// Usage:
//   result = ps_vertex_figure_cap_modes();
// Description:
//   Return supported vertex-figure cap realization modes.
//   .
//   - Returns: list of cap-mode strings
function ps_vertex_figure_cap_modes() = _PS_VERTEX_FIGURE_CAP_MODES;

// Function: ps_vertex_figure_cap_mode_is_valid()
// Usage:
//   result = ps_vertex_figure_cap_mode_is_valid(cap_mode);
// Description:
//   Test whether a vertex-figure cap realization mode is supported.
//   .
//   - Returns: boolean
// Arguments:
//   cap_mode = cap-mode string
function ps_vertex_figure_cap_mode_is_valid(cap_mode) =
    is_string(cap_mode)
        ? let(found = search([cap_mode], _PS_VERTEX_FIGURE_CAP_MODES))
            len(found) > 0 && found[0] != []
        : false;

function _ps_vertex_figure_cap_mode_ok(cap_mode) =
    assert(ps_vertex_figure_cap_mode_is_valid(cap_mode))
    0;

function _ps_vertex_figure_points_centroid(pts) =
    v_sum(pts) / len(pts);

function _ps_vertex_figure_raw_points(vertex_pt, neighbor_pts, t) =
    [
        for (p = neighbor_pts)
            vertex_pt + t * (p - vertex_pt)
    ];

function _ps_vertex_figure_cut_plane(vertex_pt, raw_pts, cap_mode, poly_center, eps) =
    let(
        n_raw = (cap_mode == "planar_edge_fraction")
            ? let(idx = [for (i = [0:1:len(raw_pts)-1]) i])
                ps_face_frame_normal(raw_pts, idx, eps)
            : (cap_mode == "centric")
                ? (_ps_vertex_figure_points_centroid(raw_pts) - vertex_pt)
                : (vertex_pt - poly_center),
        n_len = norm(n_raw),
        _n_ok = assert(n_len > eps, str("ps_vertex_figure_points: cannot derive ", cap_mode, " cap plane")),
        n = n_raw / n_len,
        d = ps_sum([for (p = raw_pts) v_dot(n, p)]) / len(raw_pts)
    )
    [n, d];

function _ps_vertex_figure_plane_point_on_ray(vertex_pt, neighbor_pt, plane, eps) =
    let(
        dir = neighbor_pt - vertex_pt,
        n = plane[0],
        d = plane[1],
        denom = v_dot(n, dir),
        _denom_ok = assert(abs(denom) > eps, "ps_vertex_figure_points: cap plane is parallel to incident edge"),
        lambda = (d - v_dot(n, vertex_pt)) / denom
    )
    vertex_pt + lambda * dir;

// Function: ps_vertex_figure_points_from_neighbors()
// Usage:
//   result = ps_vertex_figure_points_from_neighbors(vertex_pt, neighbor_pts, t,
//       cap_mode, poly_center, eps);
// Description:
//   Realize a vertex figure as metric points from an ordered neighbor-point
//   loop.
//   .
//   `edge_fraction` returns the same fraction along every incident edge.
//   `planar_edge_fraction` first builds that raw loop and then intersects its
//   implicit plane with the incident edges. `centric` slices normal to the line
//   from the source vertex to the raw loop centroid. `poly_centroidal` slices
//   normal to the line from `poly_center` to the source vertex.
//   .
//   - Returns: ordered 3D cap points
// Arguments:
//   vertex_pt = source vertex point
//   neighbor_pts = cyclic adjacent vertex points
//   t = edge fraction measured from `vertex_pt` towards each neighbor
//   cap_mode = cap realization mode
//   poly_center = source poly centroid for `poly_centroidal`; defaults to `[0,0,0]`
//   eps = geometric tolerance
function ps_vertex_figure_points_from_neighbors(
    vertex_pt,
    neighbor_pts,
    t=undef,
    cap_mode="planar_edge_fraction",
    poly_center=undef,
    eps=1e-8
) =
    let(
        _t_ok = assert(!is_undef(t), "ps_vertex_figure_points_from_neighbors: t is required"),
        _mode_ok = _ps_vertex_figure_cap_mode_ok(cap_mode),
        raw_pts = _ps_vertex_figure_raw_points(vertex_pt, neighbor_pts, t),
        center = is_undef(poly_center) ? [0, 0, 0] : poly_center
    )
    (abs(t) <= eps || cap_mode == "edge_fraction")
        ? raw_pts
        : let(plane = _ps_vertex_figure_cut_plane(vertex_pt, raw_pts, cap_mode, center, eps))
            [
                for (p = neighbor_pts)
                    _ps_vertex_figure_plane_point_on_ray(vertex_pt, p, plane, eps)
            ];

// Function: ps_vertex_figure_points_local()
// Usage:
//   result = ps_vertex_figure_points_local(neighbor_pts_local, t, cap_mode,
//       poly_center_local, eps);
// Description:
//   Realize a vertex figure in vertex-local coordinates. This is the local-space
//   counterpart to `ps_vertex_figure_points_from_neighbors(...)`; the source
//   vertex is `[0,0,0]`.
//   .
//   - Returns: ordered local 3D cap points
// Arguments:
//   neighbor_pts_local = cyclic adjacent vertex points in vertex-local space
//   t = edge fraction measured from the local origin towards each neighbor
//   cap_mode = cap realization mode
//   poly_center_local = source poly center in vertex-local space
//   eps = geometric tolerance
function ps_vertex_figure_points_local(
    neighbor_pts_local,
    t=undef,
    cap_mode="planar_edge_fraction",
    poly_center_local=undef,
    eps=1e-8
) =
    ps_vertex_figure_points_from_neighbors(
        [0, 0, 0],
        neighbor_pts_local,
        t,
        cap_mode,
        is_undef(poly_center_local) ? [0, 0, 0] : poly_center_local,
        eps
    );

// Function: ps_vertex_figure_points()
// Usage:
//   result = ps_vertex_figure_points(poly, vertex_idx, t, cap_mode, edges,
//       edge_faces, eps);
// Description:
//   Realize one source vertex figure as metric points in source-poly
//   coordinates.
//   .
//   - Returns: ordered 3D cap points
// Arguments:
//   poly = source poly descriptor
//   vertex_idx = source vertex index
//   t = edge fraction measured from the vertex towards each neighbor
//   cap_mode = cap realization mode
//   edges = optional edge list for reuse
//   edge_faces = optional edge-face table for reuse
//   eps = geometric tolerance
function ps_vertex_figure_points(
    poly,
    vertex_idx,
    t=undef,
    cap_mode="planar_edge_fraction",
    edges=undef,
    edge_faces=undef,
    eps=1e-8
) =
    let(
        verts = poly_verts(poly),
        fig = ps_vertex_figure(poly, vertex_idx, edges, edge_faces),
        neighbors_idx = ps_vertex_figure_neighbors_idx(fig),
        vertex_pt = verts[vertex_idx],
        neighbor_pts = [for (ni = neighbors_idx) verts[ni]],
        poly_center = _ps_vertex_figure_points_centroid(verts)
    )
    ps_vertex_figure_points_from_neighbors(vertex_pt, neighbor_pts, t, cap_mode, poly_center, eps);
