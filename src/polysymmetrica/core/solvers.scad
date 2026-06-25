/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

// LibFile: polysymmetrica/core/solvers.scad

// ---------------------------------------------------------------------------
// PolySymmetrica - Solver helpers
// Parameter solvers for mixed-face transforms.

use <funcs.scad>
use <duals.scad>

function _ps_unique_ints(a) =
    let(
        s = _ps_sort([for (x = a) x])
    )
    [for (i = [0:1:len(s)-1]) if (i == 0 || s[i] != s[i-1]) s[i]];

// Build sorted unique [a,b] pairs from a list of sizes.
function _ps_pairs_from_sizes(sizes) =
    let(
        s = _ps_sort([for (x = sizes) x]),
        uniq = [for (i = [0:1:len(s)-1]) if (i == 0 || s[i] != s[i-1]) s[i]]
    )
    [for (i = [0:1:len(uniq)-1]) for (j = [i:1:len(uniq)-1]) [uniq[i], uniq[j]]];

function _ps_map_face_c(face_len, c_by_size, default_c=0) =
    let(
        idxs = [for (i = [0:1:len(c_by_size)-1]) if (c_by_size[i][0] == face_len) i]
    )
    (len(idxs) == 0) ? default_c : c_by_size[idxs[0]][1];

function _ps_map_edge_c(face_len, adj_len, c_by_pair, default_c=0) =
    let(
        a = min(face_len, adj_len),
        b = max(face_len, adj_len),
        idxs = [for (i = [0:1:len(c_by_pair)-1]) if (c_by_pair[i][0] == a && c_by_pair[i][1] == b) i]
    )
    (len(idxs) == 0) ? default_c : c_by_pair[idxs[0]][2];

// Function: solve_truncate_corner_t()
// Usage:
//   result = solve_truncate_corner_t(verts, face, k);
// Description:
//   Estimate a truncation fraction for one face corner from local edge
//   geometry.
// Arguments:
//   verts = vertex list
//   face = face index loop
//   k = corner position within `face`
// Compute per-corner truncation estimate t = 1/(2+r),
// where r = |B-C| / mean(|V-B|,|V-C|) for face corner (...B,V,C...).
function solve_truncate_corner_t(verts, face, k) =
    let(
        n  = len(face),
        vm = face[(k-1+n) % n],
        v  = face[k],
        vp = face[(k+1) % n],
        V  = verts[v],
        B  = verts[vm],
        C  = verts[vp],

        LB = norm(V - B),
        LC = norm(V - C),
        L  = (LB + LC) / 2,

        chord = norm(B - C),
        r = (L == 0) ? 0 : chord / L,

        t = (2 + r == 0) ? 0 : 1 / (2 + r)
    )
    t;

// Function: solve_truncate_default_t()
// Usage:
//   result = solve_truncate_default_t(poly, tol=1e-3, fallback=0.2);
// Description:
//   Return a best-guess truncation fraction when the caller leaves `t=undef`.
//   If the poly is locally uniform, this returns the mean corner estimate;
//   otherwise it returns `fallback`.
// Arguments:
//   poly = source poly descriptor
//   tol = absolute tolerance on `(t_max - t_min)`
//   fallback = fallback value for non-uniform inputs
function solve_truncate_default_t(poly, tol = 1e-3, fallback = 0.2) =
    let(
        verts = poly_verts(poly),
        faces = poly_faces(poly),

        ts = [
            for (f = faces)
                for (k = [0 : len(f)-1])
                    solve_truncate_corner_t(verts, f, k)
        ],

        _ = assert(len(ts) > 0, "solve_truncate_default_t: no face corners found"),

        tmin = min(ts),
        tmax = max(ts),
        tavg = ps_sum(ts) / len(ts),
        ok = (tmax - tmin) <= tol
    )
    ok ? tavg : fallback;

function _ps_cantitruncate_face_ids_of_size(faces0, n) =
    [for (fi = [0:1:len(faces0)-1]) if (len(faces0[fi]) == n) fi];

function _ps_cantitruncate_edge_ids_of_pair(faces0, edges, edge_faces, n0, n1) =
    let(
        lo = min(n0, n1),
        hi = max(n0, n1)
    )
    [
        for (ei = [0:1:len(edges)-1])
            let(
                fpair = edge_faces[ei],
                ok = len(fpair) == 2,
                a = ok ? len(faces0[fpair[0]]) : -1,
                b = ok ? len(faces0[fpair[1]]) : -1,
                alo = min(a, b),
                ahi = max(a, b)
            )
            if (ok && alo == lo && ahi == hi) ei
    ];

// Function: ps_cantitruncate_profile_rows()
// Usage:
//   result = ps_cantitruncate_profile_rows(poly, c_by_size, default_c=0,
//       c_edge_by_pair=undef);
// Description:
//   Convert cantitruncate family maps into profile rows for
//   `poly_cantitruncate()`.
// Arguments:
//   poly = source poly descriptor
//   c_by_size = face-family cantellation map
//   default_c = fallback cantellation value
//   c_edge_by_pair = optional edge-family cantellation map
function ps_cantitruncate_profile_rows(poly, c_by_size, default_c=0, c_edge_by_pair=undef) =
    let(
        verts = poly_verts(poly),
        faces0 = ps_orient_all_faces_outward(verts, poly_faces(poly)),
        edges = _ps_edges_from_faces(faces0),
        edge_faces = ps_edge_faces_table(faces0, edges),
        face_sizes = _ps_unique_ints([for (f = faces0) len(f)]),
        face_rows = [
            for (n = face_sizes)
                let(
                    cv = _ps_map_face_c(n, c_by_size, default_c),
                    ids = _ps_cantitruncate_face_ids_of_size(faces0, n)
                )
                if (len(ids) > 0) ["face", "id", ids, ["c", cv]]
        ],
        edge_rows = is_undef(c_edge_by_pair)
            ? []
            : [
                for (p = c_edge_by_pair)
                    let(
                        n0 = p[0],
                        n1 = p[1],
                        cv = p[2],
                        ids = _ps_cantitruncate_edge_ids_of_pair(faces0, edges, edge_faces, n0, n1)
                    )
                    if (len(ids) > 0) ["edge", "id", ids, ["c", cv]]
            ]
    )
    concat(face_rows, edge_rows);

// Function: solve_cantitruncate_dominant()
// Usage:
//   result = solve_cantitruncate_dominant(poly, dominant_size, edge_idx=undef);
// Description:
//   Solve cantitruncate parameters by matching the dominant face family to the
//   trig-based solution.
// Arguments:
//   poly = source poly descriptor
//   dominant_size = dominant face arity
//   edge_idx = optional reference edge index
function solve_cantitruncate_dominant(poly, dominant_size, edge_idx=undef) =
    let(
        verts = poly_verts(poly),
        faces0 = ps_orient_all_faces_outward(verts, poly_faces(poly)),
        poly0 = poly_make(verts, faces0, poly_e_over_ir(poly)),
        edges = _ps_edges_from_faces(faces0),
        face_sizes = [for (f = faces0) len(f)],
        size_set = _ps_unique_ints(face_sizes),
        f_idx = [for (i = [0:1:len(face_sizes)-1]) if (face_sizes[i] == dominant_size) i][0],
        sol = solve_cantitruncate_trig(poly0, f_idx, edge_idx),
        t = sol[0],
        c_dom = sol[1],
        c_by_size = [
            for (sz = size_set)
                let(f_i = [for (i = [0:1:len(face_sizes)-1]) if (face_sizes[i] == sz) i][0])
                (sz == dominant_size)
                    ? [sz, c_dom]
                    : let(sol_i = solve_cantitruncate_trig(poly0, f_i, edge_idx)) [sz, sol_i[1]]
        ]
    )
    [t, c_by_size];

// Function: solve_cantitruncate_dominant_edges()
// Usage:
//   result = solve_cantitruncate_dominant_edges(poly, dominant_size, edge_idx=undef);
// Description:
//   Solve dominant-family cantitruncate parameters and derive per-edge-family
//   overrides.
// Arguments:
//   poly = source poly descriptor
//   dominant_size = dominant face arity
//   edge_idx = optional reference edge index
function solve_cantitruncate_dominant_edges(poly, dominant_size, edge_idx=undef) =
    let(
        sol = solve_cantitruncate_dominant(poly, dominant_size, edge_idx),
        t = sol[0],
        c_by_size = sol[1],
        c_edge_by_pair = [
            for (p = _ps_pairs_from_sizes([for (c = c_by_size) c[0]]))
                let(
                    c0 = _ps_map_face_c(p[0], c_by_size, 0),
                    c1 = _ps_map_face_c(p[1], c_by_size, 0),
                    c_edge = (c0 + c1) / 2
                )
                [p[0], p[1], c_edge]
        ]
    )
    [t, c_by_size, c_edge_by_pair];

// Function: solve_cantitruncate_dominant_edges_profile_rows()
// Usage:
//   result = solve_cantitruncate_dominant_edges_profile_rows(poly,
//       dominant_size, edge_idx=undef, default_c=0);
// Description:
//   Solve dominant-edge cantitruncate parameters and return ready-to-use
//   profile rows, including a global vertex `t` row.
// Arguments:
//   poly = source poly descriptor
//   dominant_size = dominant face arity
//   edge_idx = optional reference edge index
//   default_c = fallback cantellation value
function solve_cantitruncate_dominant_edges_profile_rows(poly, dominant_size, edge_idx=undef, default_c=0) =
    let(
        sol = solve_cantitruncate_dominant_edges(poly, dominant_size, edge_idx),
        rows = ps_cantitruncate_profile_rows(poly, sol[1], default_c, sol[2])
    )
    concat(
        [["vert", "all", ["t", sol[0]]]],
        rows
    );

// Function: solve_cantitruncate_trig()
// Usage:
//   result = solve_cantitruncate_trig(poly, face_idx=0, edge_idx=undef);
// Description:
//   Solve cantitruncate parameters trigonometrically for regular-base cases.
// Arguments:
//   poly = source poly descriptor
//   face_idx = reference face index
//   edge_idx = optional reference edge index
function solve_cantitruncate_trig(poly, face_idx=0, edge_idx=undef) =
    let(
        verts = poly_verts(poly),
        faces = ps_orient_all_faces_outward(verts, poly_faces(poly)),
        f = faces[face_idx],
        n = len(f),
        v0 = f[0],
        v_prev = f[(n-1)%n],
        v_next = f[1],
        a0 = v_norm(verts[v_prev] - verts[v0]),
        a1 = v_norm(verts[v_next] - verts[v0]),
        phi = acos(ps_clamp(v_dot(a0, a1), -1, 1)),
        t = 1 / (2 * (1 + sin(phi/2))),
        edges = _ps_edges_from_faces(faces),
        ei = is_undef(edge_idx) ? ps_find_edge_index(edges, v0, v_next) : edge_idx,
        fpair = ps_edge_faces_table(faces, edges)[ei],
        f0 = fpair[0],
        f1 = fpair[1],
        n0 = ps_face_normal(verts, faces[f0]),
        n1 = ps_face_normal(verts, faces[f1]),
        // alpha is angle between outward normals
        alpha = acos(ps_clamp(v_dot(n0, n1), -1, 1)),
        a = norm(verts[v_next] - verts[v0]),
        ir = min([for (e = edges) norm((verts[e[0]] + verts[e[1]]) / 2)]),
        // across-face distance uses sin(alpha/2); for cube alpha=90 so sin=cos
        d_f = (1 - 2*t) * a / (2 * sin(alpha/2)),
        c = abs(d_f) / ir
    )
    [t, c];
