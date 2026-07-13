/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

// LibFile: polysymmetrica/core/duals.scad
use <funcs.scad>
use <profile.scad>


function _ps_dual_faces(poly, centers) =
    let(
        faces      = poly_faces(poly),
        edges      = _ps_edges_from_faces(faces),
        edge_faces = ps_edge_faces_table(faces, edges),
        verts      = poly_verts(poly)
    )
    [
        for (vi = [0 : len(verts)-1])
            ps_vertex_fan_faces_idx(ps_vertex_fan(poly, vi, edges, edge_faces))
    ];


function _ps_dual_metric_edge_idx(verts, faces, eps=1e-9) =
    let(
        edges    = _ps_edges_from_faces(faces),
        _0       = assert(len(edges) > 0, "_ps_dual_metric_edge_idx: dual has no edges"),
        center   = _ps_poly_mid_center(verts, faces),
        verts0   = [for (v = verts) v - center],
        midrs    = [for (e = edges) norm((verts0[e[0]] + verts0[e[1]]) / 2)],
        ir       = min(midrs),
        _1       = assert(ir > 0, "_ps_dual_metric_edge_idx: dual inter-radius must be positive"),
        tol      = eps * ir,
        nv       = len(verts),
        keys     = [
            for (i = [0:1:len(edges)-1])
                if (abs(midrs[i] - ir) <= tol)
                    edges[i][0] * nv + edges[i][1]
        ],
        key      = min(keys)
    )
    [for (i = [0:1:len(edges)-1]) if (edges[i][0] * nv + edges[i][1] == key) i][0];

function _ps_dual_unit_edge_and_e_over_ir(verts, faces) =
    let(
        edges    = _ps_edges_from_faces(faces),
        e0       = edges[_ps_dual_metric_edge_idx(verts, faces)],
        vA       = verts[e0[0]],
        vB       = verts[e0[1]],
        center   = _ps_poly_mid_center(verts, faces),
        unit_e   = norm(vB - vA),
        mid      = (vA + vB) / 2 - center,
        ir       = norm(mid),
        e_over_ir = unit_e / ir
    )
    [unit_e, e_over_ir];


// Function: ps_face_polar_verts()
// Usage:
//   result = ps_face_polar_verts(verts, faces);
// Description:
//   Build polar-dual vertices from outward face planes.
// Arguments:
//   verts = vertex positions in any consistent coordinate scale
//   faces = outward-oriented face list
function ps_face_polar_verts(verts, faces) =
    [
        for (fi = [0 : len(faces)-1])
            let(
                f = faces[fi],
                n = ps_face_frame_normal(verts, f),  // unit outward normal
                d = v_dot(n, verts[f[0]])         // plane offset along n
            )
            assert(d > 0, str("ps_face_polar_verts: d<=0 at face ", fi))
            (n / d)
    ];


// Function: poly_dual_polar_vf()
// Usage:
//   result = poly_dual_polar_vf(verts, faces);
// Description:
//   Build raw polar-dual vertex and face lists in the same world-space units as
//   the supplied geometry.
// Arguments:
//   verts = scaled vertex positions
//   faces = outward-oriented face list
function poly_dual_polar_vf(verts, faces) =
    let(
        dual_verts  = ps_face_polar_verts(verts, faces),
        faces_raw   = _ps_dual_faces([verts, faces, 1, 1], dual_verts),
        faces_orient = ps_orient_all_faces_outward(dual_verts, faces_raw)
    )
    [dual_verts, faces_orient];



// ---- Edge midradius helpers ----

// Function: ps_edge_midradius_list()
// Usage:
//   result = ps_edge_midradius_list(poly);
// Description:
//   Return edge-midpoint radii for a poly in its own coordinate system.
// Arguments:
//   poly = source poly descriptor
function ps_edge_midradius_list(poly) =
    let(
        verts = poly_verts(poly),
        edges = _ps_edges_from_faces(poly_faces(poly)),
        rs = [
            for (e = edges)
                let(
                    m = (verts[e[0]] + verts[e[1]]) / 2
                )
                norm(m)
        ]
    )
    assert(len(rs) > 0, "ps_edge_midradius_list: poly has no edges")
    rs;

// Function: ps_edge_midradius_stat()
// Usage:
//   result = ps_edge_midradius_stat(poly);
// Description:
//   Return the minimum edge-midpoint radius for a poly.
// Arguments:
//   poly = source poly descriptor
function ps_edge_midradius_stat(poly) =
    let(rs = ps_edge_midradius_list(poly))
        min(rs);

// ---- Face radius helpers ----

// Function: ps_face_radius_list()
// Usage:
//   result = ps_face_radius_list(poly);
// Description:
//   Return the mean vertex distance from each face centroid.
// Arguments:
//   poly = source poly descriptor
function ps_face_radius_list(poly) =
    let(
        verts = poly_verts(poly),
        faces = poly_faces(poly)
    )
    [
        for (f = faces)
            let(
                c = ps_face_centroid(verts, f),
                rs = [ for (vid = f) norm(verts[vid] - c) ]
            )
            ps_sum(rs) / len(rs)
    ];

// Function: ps_face_radius_stat()
// Usage:
//   result = ps_face_radius_stat(poly, face_k=undef);
// Description:
//   Return the minimum face radius overall, or within one face arity.
// Arguments:
//   poly = source poly descriptor
//   face_k = face arity filter
function ps_face_radius_stat(poly, face_k=undef) =
    let(
        faces = poly_faces(poly),
        rs_all = ps_face_radius_list(poly),
        rs = is_undef(face_k)
            ? rs_all
            : [ for (i = [0:len(faces)-1]) if (len(faces[i]) == face_k) rs_all[i] ],
        _0 = assert(len(rs) > 0, "ps_face_radius_stat: no faces of that size")
    )
    min(rs);

// ---- Face-family helpers ----

// Function: ps_face_family_list()
// Usage:
//   result = ps_face_family_list(poly);
// Description:
//   Summarize face families by arity.
// Arguments:
//   poly = source poly descriptor
function ps_face_family_list(poly) =
    let(
        faces = poly_faces(poly),
        sizes = [ for (f = faces) len(f) ],
        uniq = [
            for (i = [0:len(sizes)-1])
                let(k = sizes[i])
                    if (len([for (j = [0:1:i-1]) if (sizes[j] == k) 1]) == 0) k
        ],
        ks = sort(uniq)
    )
    [ for (k = ks) [k, len([for (s = sizes) if (s == k) 1])] ];

// Function: ps_face_family_mode()
// Usage:
//   result = ps_face_family_mode(poly);
// Description:
//   Return the most common face arity. Ties are resolved by choosing the
//   smallest `k`.
// Arguments:
//   poly = source poly descriptor
function ps_face_family_mode(poly) =
    let(
        faces = poly_faces(poly),
        sizes = [ for (f = faces) len(f) ],
        uniq = [
            for (i = [0:len(sizes)-1])
                let(k = sizes[i])
                    if (len([for (j = [0:1:i-1]) if (sizes[j] == k) 1]) == 0) k
        ],
        counts = [ for (k = uniq) len([for (s = sizes) if (s == k) 1]) ],
        max_count = max(counts),
        best = [
            for (i = [0:len(uniq)-1])
                if (counts[i] == max_count) uniq[i]
        ],
        k = min(best)
    )
    [k, max_count];

// Function: ps_face_family_max()
// Usage:
//   result = ps_face_family_max(poly);
// Description:
//   Return the largest face arity present on a poly.
// Arguments:
//   poly = source poly descriptor
function ps_face_family_max(poly) =
    let(
        faces = poly_faces(poly),
        sizes = [ for (f = faces) len(f) ],
        k = max(sizes),
        count = len([for (s = sizes) if (s == k) 1])
    )
    [k, count];

// ---- Edge-crossing scale helpers ----

function _ps_vertex_valence_list(verts, edges) =
    [
        for (vi = [0:len(verts)-1])
            len([for (e = edges) if (e[0] == vi || e[1] == vi) 1])
    ];

function _ps_edge_signature_full(edges, faces, edge_faces, valences, ei) =
    let(
        fpair = edge_faces[ei],
        k0 = len(faces[fpair[0]]),
        k1 = len(faces[fpair[1]]),
        ks = (k0 < k1) ? [k0, k1] : [k1, k0],
        e = edges[ei],
        v0 = valences[e[0]],
        v1 = valences[e[1]],
        vs = (v0 < v1) ? [v0, v1] : [v1, v0]
    )
    [ks[0], ks[1], vs[0], vs[1]];

// Function: ps_edge_from_face()
// Usage:
//   result = ps_edge_from_face(poly, face_idx, edge_pos);
// Description:
//   Return the global edge index for a face-local edge position.
// Arguments:
//   poly = source poly descriptor
//   face_idx = face index
//   edge_pos = edge position within that face
function ps_edge_from_face(poly, face_idx, edge_pos) =
    let(
        faces = poly_faces(poly),
        f = faces[face_idx],
        n = len(f),
        a = f[edge_pos % n],
        b = f[(edge_pos + 1) % n],
        edges = _ps_edges_from_faces(faces)
    )
    ps_find_edge_index(edges, a, b);

// Function: ps_dual_scale_edge_cross()
// Usage:
//   result = ps_dual_scale_edge_cross(poly, dual, face_idx, edge_pos=0,
//       eps=1e-12, len_eps=1e-6);
// Description:
//   Compute a dual scale factor that aligns dual edges with the selected edge
//   family of the source poly.
// Arguments:
//   poly = source poly descriptor
//   dual = dual poly descriptor
//   face_idx = reference face index on `poly`
//   edge_pos = reference edge position within that face
//   eps = solver tolerance
//   len_eps = edge-length matching tolerance
function ps_dual_scale_edge_cross(poly, dual, face_idx, edge_pos=0, eps=1e-12, len_eps=1e-6) =
    let(
        verts = poly_verts(poly),
        faces = poly_faces(poly),
        edges = _ps_edges_from_faces(faces),
        edge_faces = ps_edge_faces_table(faces, edges),
        valences = _ps_vertex_valence_list(verts, edges),

        ref_ei = ps_edge_from_face(poly, face_idx, edge_pos),
        ref_sig = _ps_edge_signature_full(edges, faces, edge_faces, valences, ref_ei),
        ref_len = norm(verts[edges[ref_ei][1]] - verts[edges[ref_ei][0]]),

        // gather edges matching the signature
        edge_ids = [
            for (ei = [0:len(edges)-1])
                let(
                    sig = _ps_edge_signature_full(edges, faces, edge_faces, valences, ei),
                    len_e = norm(verts[edges[ei][1]] - verts[edges[ei][0]])
                )
                if (sig == ref_sig && abs(len_e - ref_len) <= len_eps) ei
        ],

        dverts = poly_verts(dual),
        sp = poly_e_over_ir(poly),
        sd = poly_e_over_ir(dual),

        scales = [
            for (ei = edge_ids)
                let(
                    e = edges[ei],
                    A = verts[e[0]],
                    B = verts[e[1]],
                    d_f = edge_faces[ei],
                    D0 = dverts[d_f[0]],
                    D1 = dverts[d_f[1]],
                    E = D1 - D0,
                    M = [
                        [ (B-A)[0], -D0[0], -E[0] ],
                        [ (B-A)[1], -D0[1], -E[1] ],
                        [ (B-A)[2], -D0[2], -E[2] ]
                    ],
                    sol = _ps_solve3(M, -A, eps)
                )
                is_undef(sol) ? undef
              : let(
                    v = sol[0],
                    s = sol[1],
                    y = sol[2],
                    u = (abs(s) < eps) ? undef : y / s,
                    ok = (s > 0) && (v >= 0) && (v <= 1) && (!is_undef(u)) && (u >= 0) && (u <= 1)
                )
                ok ? (s * sp / sd) : undef
        ],

        s_vals = [ for (s = scales) if (!is_undef(s)) s ],
        _0 = assert(len(s_vals) > 0, "ps_dual_scale_edge_cross: no valid edges found"),
        sorted = _ps_sort(s_vals),
        n = len(sorted)
    )
    (n % 2 == 1)
        ? sorted[(n-1)/2]
        : (sorted[n/2 - 1] + sorted[n/2]) / 2;


// Function: ps_dual_scale()
// Usage:
//   result = ps_dual_scale(poly, dual);
// Description:
//   Return an inter-radius multiplier that tends to align dual edges with the
//   source poly's edges.
// Arguments:
//   poly = source poly descriptor
//   dual = dual poly descriptor
function ps_dual_scale(poly, dual) =
    let(
        // scaling from unit-edge coords to "per-IR world coords":
        // world = IR * (e_over_ir/unit_edge) * verts_unit
        sp = poly_e_over_ir(poly),
        sd = poly_e_over_ir(dual),

        rp = ps_edge_midradius_stat(poly),
        rd = ps_edge_midradius_stat(dual),

        _0 = assert(abs(rd) > 1e-12, "ps_dual_scale: dual edge midradius ~ 0")
    )
    (sp * rp) / (sd * rd);

// Function: ps_dual_scale_face_radius()
// Usage:
//   result = ps_dual_scale_face_radius(poly, dual, face_k=undef, dual_face_k=undef);
// Description:
//   Return a scale multiplier that aligns face radii between a poly and its
//   dual, optionally restricted to selected face arities.
// Arguments:
//   poly = source poly descriptor
//   dual = dual poly descriptor
//   face_k = source face arity filter
//   dual_face_k = dual face arity filter
function ps_dual_scale_face_radius(poly, dual, face_k=undef, dual_face_k=undef) =
    let(
        rp = ps_face_radius_stat(poly, face_k),
        rd = ps_face_radius_stat(dual, dual_face_k),
        _0 = assert(abs(rd) > 1e-12, "ps_dual_scale_face_radius: dual face radius ~ 0")
    )
    rp / rd * ps_dual_scale(poly, dual);



// Function: poly_dual()
// Usage:
//   result = poly_dual(poly, profile=undef);
// Description:
//   Build the polar dual of a poly and return it as a normalized descriptor
//   with unit edge length 1.
// Arguments:
//   poly = source poly descriptor
//   profile = reserved for future extensions; currently unsupported
function poly_dual(poly, profile=undef) =
    let(
        _p_ok = assert(ps_profile_row_count(profile) == 0, "poly_dual: profile not supported")
    )
    let(
        // Ensure input faces are outward for correct polar normals
        verts0 = poly_verts(poly),
        faces0 = ps_orient_all_faces_outward(verts0, poly_faces(poly)),

        // Build raw polar dual in same coordinate system as verts0
        dual_vf_raw = poly_dual_polar_vf(verts0, faces0),
        dv_raw = dual_vf_raw[0],
        df_raw = dual_vf_raw[1],

        // Compute metrics for raw dual
        ue_eir_raw = _ps_dual_unit_edge_and_e_over_ir(dv_raw, df_raw),
        unit_e_raw = ue_eir_raw[0],
        e_over_ir_raw = ue_eir_raw[1],

        // Renormalise so returned descriptor follows convention unit_edge = 1
        k = 1 / unit_e_raw,
        dv = dv_raw * k,

        // Recompute metrics after renormalisation
        ue_eir = _ps_dual_unit_edge_and_e_over_ir(dv, df_raw),
        e_over_ir = ue_eir[1]
    )
    poly_make(dv, df_raw, e_over_ir);
