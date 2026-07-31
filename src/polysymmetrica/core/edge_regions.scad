/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

// LibFile: polysymmetrica/core/edge_regions.scad
use <funcs.scad>
use <loop_shells.scad>
use <placement.scad>
include <segments.scad>

function _ps_er_face_source_edge_idx(face, edge_verts, k=0) =
    (k >= len(face)) ? undef :
    let(a = face[k], b = face[(k + 1) % len(face)])
    ((a == edge_verts[0] && b == edge_verts[1]) || (a == edge_verts[1] && b == edge_verts[0]))
        ? k
        : _ps_er_face_source_edge_idx(face, edge_verts, k + 1);

function _ps_er_global_t_range(site, face, edge_verts, eps=1e-8) =
    let(
        k = ps_boundary_span_site_source_edge_idx(site),
        a = face[k],
        b = face[(k + 1) % len(face)],
        same_dir = a == edge_verts[0] && b == edge_verts[1],
        t0_raw = ps_boundary_span_site_source_t0(site),
        t1_raw = ps_boundary_span_site_source_t1(site),
        t0 = same_dir ? t0_raw : 1 - t0_raw,
        t1 = same_dir ? t1_raw : 1 - t1_raw
    )
    [min(t0, t1), max(t0, t1)];

function _ps_er_face_edge_boundary_spans(face_site, edge_verts, mode="nonzero", eps=1e-8) =
    let(
        face_ctx = ps_face_site_face_local_context(face_site),
        face_idx = ps_face_local_context_idx(face_ctx),
        face = ps_face_local_context_poly_faces_idx(face_ctx)[face_idx],
        source_edge_idx = _ps_er_face_source_edge_idx(face, edge_verts),
        _edge = assert(!is_undef(source_edge_idx), "ps_edge_region_shells: adjacent face does not contain edge"),
        sites = _ps_face_boundary_span_sites(
            ps_face_local_context_pts3d_local(face_ctx),
            face_idx,
            ps_face_local_context_poly_faces_idx(face_ctx),
            ps_face_local_context_poly_verts_local(face_ctx),
            ps_face_local_context_neighbors_idx(face_ctx),
            ps_face_local_context_dihedrals(face_ctx),
            mode,
            eps
        )
    )
    [
        for (site = sites)
            if (ps_boundary_span_site_source_edge_idx(site) == source_edge_idx)
                [site, _ps_er_global_t_range(site, face, edge_verts, eps), face_site]
    ];

function _ps_er_span_at_t(spans, t, eps=1e-8) =
    let(
        hits = [
            for (span = spans)
                if (t >= span[1][0] - eps && t <= span[1][1] + eps)
                    span
        ]
    )
    len(hits) == 0 ? undef : hits[0];

function _ps_er_unique_sorted(vals, eps=1e-8) =
    _ps_seg_sort_uniq([for (v = vals) ps_clamp(v, 0, 1)], eps);

function _ps_er_atom_intervals(spans0, spans1, eps=1e-8) =
    let(
        ts = _ps_er_unique_sorted(concat(
            [0, 1],
            [for (s = spans0) each s[1]],
            [for (s = spans1) each s[1]]
        ), eps)
    )
    [
        for (i = [0:1:len(ts)-2])
            let(t0 = ts[i], t1 = ts[i + 1])
            if (t1 - t0 > eps)
                [t0, t1, (t0 + t1) / 2]
    ];

function _ps_er_face_local_vec_to_parent(face_site, v) =
    ps_face_site_ex(face_site) * v[0]
        + ps_face_site_ey(face_site) * v[1]
        + ps_face_site_ez(face_site) * v[2];

function _ps_er_parent_vec_to_edge_local(edge_site, v) =
    [
        v_dot(v, ps_edge_site_ex(edge_site)),
        v_dot(v, ps_edge_site_ey(edge_site)),
        v_dot(v, ps_edge_site_ez(edge_site))
    ];

function _ps_er_span_filled_ray_face_local(site) =
    ps_boundary_span_site_ey_local(site) * ((ps_boundary_span_site_filled_side(site) < 0) ? -1 : 1);

function _ps_er_span_filled_ray_edge_local(span, edge_site, eps=1e-8) =
    let(
        site = span[0],
        face_site = span[2],
        v_parent = _ps_er_face_local_vec_to_parent(face_site, _ps_er_span_filled_ray_face_local(site)),
        v_edge = _ps_er_parent_vec_to_edge_local(edge_site, v_parent),
        yz = [v_edge[1], v_edge[2]],
        _ray = assert(norm(yz) > eps, "ps_edge_region_shells: adjacent face side ray is parallel to edge")
    )
    yz / norm(yz);

function _ps_er_side_constraint(ray_yz, outset, eps=1e-8) =
    let(
        _ry = assert(abs(ray_yz[0]) > eps, "ps_edge_region_shells: side ray cannot constrain edge-local Y"),
        slope = -ray_yz[1] / ray_yz[0],
        intercept = outset / ray_yz[0]
    )
    [slope, intercept];

function _ps_er_side_constraint_y(constraint, z) =
    constraint[0] * z + constraint[1];

function _ps_er_side_constraints_cross_z(c0, c1, eps=1e-8) =
    let(dz = c0[0] - c1[0])
    abs(dz) <= eps ? undef : (c1[1] - c0[1]) / dz;

function _ps_er_z_ordered(z0, z1) =
    z0 <= z1 ? [z0, z1] : [z1, z0];

function _ps_er_stable_z_ranges(c0, c1, z0, z1, eps=1e-8) =
    let(
        zz = _ps_er_z_ordered(z0, z1),
        za = zz[0],
        zb = zz[1],
        z_cross = _ps_er_side_constraints_cross_z(c0, c1, eps)
    )
    is_undef(z_cross) || z_cross <= za + eps || z_cross >= zb - eps
        ? [[z0, z1]]
        : (z0 <= z1)
            ? [[z0, z_cross], [z_cross, z1]]
            : [[z0, z_cross], [z_cross, z1]];

function _ps_er_side_ys_for_z(constraints, z) =
    [
        _ps_er_side_constraint_y(constraints[0], z),
        _ps_er_side_constraint_y(constraints[1], z)
    ];

function _ps_er_atom_shell_from_constraints(edge_site, atom, span0, span1, constraints, z0, z1, eps=1e-8) =
    let(
        edge_len = ps_edge_site_edge_len(edge_site),
        x0 = -edge_len / 2 + atom[0] * edge_len,
        x1 = -edge_len / 2 + atom[1] * edge_len,
        bottom_ys = _ps_er_side_ys_for_z(constraints, z0),
        top_ys = _ps_er_side_ys_for_z(constraints, z1),
        _bw = assert(bottom_ys[1] - bottom_ys[0] > eps, "ps_edge_region_shells: z0 side constraints cross or collapse"),
        _tw = assert(top_ys[1] - top_ys[0] > eps, "ps_edge_region_shells: z1 side constraints cross or collapse"),
        bottom_loop = [
            [x0, bottom_ys[0]],
            [x1, bottom_ys[0]],
            [x1, bottom_ys[1]],
            [x0, bottom_ys[1]]
        ],
        top_loop = [
            [x0, top_ys[0]],
            [x1, top_ys[0]],
            [x1, top_ys[1]],
            [x0, top_ys[1]]
        ],
        lineage = [
            ps_boundary_span_site_idx(span0[0]),
            ps_boundary_span_site_idx(span1[0])
        ]
    )
    ps_loop_shell_from_loops(bottom_loop, top_loop, z0, z1, "edge_region", ps_edge_site_idx(edge_site), lineage, 0, undef, eps);

function _ps_er_atom_wedge_shell(edge_site, atom, span0, span1, constraints, z_wide, z_tip, eps=1e-8) =
    let(
        edge_len = ps_edge_site_edge_len(edge_site),
        x0 = -edge_len / 2 + atom[0] * edge_len,
        x1 = -edge_len / 2 + atom[1] * edge_len,
        wide_ys = _ps_er_side_ys_for_z(constraints, z_wide),
        tip_y = _ps_er_side_constraint_y(constraints[0], z_tip),
        bottom_wide = z_wide < z_tip,
        points = bottom_wide
            ? [
                [x0, wide_ys[0], z_wide],
                [x1, wide_ys[0], z_wide],
                [x1, wide_ys[1], z_wide],
                [x0, wide_ys[1], z_wide],
                [x0, tip_y, z_tip],
                [x1, tip_y, z_tip]
            ]
            : [
                [x0, tip_y, z_tip],
                [x1, tip_y, z_tip],
                [x0, wide_ys[0], z_wide],
                [x1, wide_ys[0], z_wide],
                [x1, wide_ys[1], z_wide],
                [x0, wide_ys[1], z_wide]
            ],
        faces = bottom_wide
            ? [
                [0, 1, 2, 3],
                [0, 4, 5, 1],
                [3, 2, 5, 4],
                [0, 3, 4],
                [1, 5, 2]
            ]
            : [
                [2, 3, 4, 5],
                [0, 1, 3, 2],
                [0, 5, 4, 1],
                [0, 2, 5],
                [1, 4, 3]
            ],
        bottom_loop = bottom_wide
            ? [[x0, wide_ys[0]], [x1, wide_ys[0]], [x1, wide_ys[1]], [x0, wide_ys[1]]]
            : [[x0, tip_y], [x1, tip_y]],
        top_loop = bottom_wide
            ? [[x0, tip_y], [x1, tip_y]]
            : [[x0, wide_ys[0]], [x1, wide_ys[0]], [x1, wide_ys[1]], [x0, wide_ys[1]]],
        lineage = [
            ps_boundary_span_site_idx(span0[0]),
            ps_boundary_span_site_idx(span1[0])
        ]
    )
    [
        "loop_shell",
        points,
        faces,
        bottom_loop,
        top_loop,
        min(z_wide, z_tip),
        max(z_wide, z_tip),
        "edge_region",
        ps_edge_site_idx(edge_site),
        lineage,
        0,
        undef
    ];

function _ps_er_atom_shell_for_stable_z(edge_site, atom, span0, span1, constraints, za, zb, eps=1e-8) =
    let(
        ya = _ps_er_side_ys_for_z(constraints, za),
        yb = _ps_er_side_ys_for_z(constraints, zb),
        wa = ya[1] - ya[0],
        wb = yb[1] - yb[0],
        _valid = assert(wa >= -eps && wb >= -eps, "ps_edge_region_shells: stable side constraints are reversed"),
        wide_z = wa > wb ? za : zb,
        tip_z = wa > wb ? zb : za
    )
    (wa <= eps || wb <= eps)
        ? _ps_er_atom_wedge_shell(edge_site, atom, span0, span1, constraints, wide_z, tip_z, eps)
        : _ps_er_atom_shell_from_constraints(edge_site, atom, span0, span1, constraints, za, zb, eps);

function _ps_er_atom_shells(edge_site, atom, span0, span1, outset, z0, z1, eps=1e-8) =
    let(
        ray0 = _ps_er_span_filled_ray_edge_local(span0, edge_site, eps),
        ray1 = _ps_er_span_filled_ray_edge_local(span1, edge_site, eps),
        c0 = _ps_er_side_constraint(ray0, outset, eps),
        c1 = _ps_er_side_constraint(ray1, outset, eps),
        ranges = _ps_er_stable_z_ranges(c0, c1, z0, z1, eps)
    )
    [
        for (range = ranges)
            let(
                z_mid = (range[0] + range[1]) / 2,
                y0_mid = _ps_er_side_constraint_y(c0, z_mid),
                y1_mid = _ps_er_side_constraint_y(c1, z_mid),
                constraints = y0_mid <= y1_mid ? [c0, c1] : [c1, c0]
            )
            _ps_er_atom_shell_for_stable_z(edge_site, atom, span0, span1, constraints, range[0], range[1], eps)
    ];

// Function: ps_edge_region_shells()
// Usage:
//   shells = ps_edge_region_shells(poly, outset, z0, z1, inter_radius, edge_len, edge_idx, mode, eps);
// Description:
//   Build edge-region atom shells for one source edge.
//   .
//   Adjacent face boundary spans are used as the source of truth. Transition
//   points from both adjacent faces are merged along the edge, and each interval
//   with a stable pair of face-side spans becomes one shell.
//   .
//   - Returns: list of `ps_loop_shell` records
//   .
//   - Limitations/Gotchas: closed two-face edges only; endpoint handoff to
//     vertex-node volumes is not applied here.
// Arguments:
//   poly = source poly descriptor.
//   outset = symmetric side offset from the topological edge.
//   z0 = lower edge-local Z bound.
//   z1 = upper edge-local Z bound.
//   inter_radius = target interradius scale used when `edge_len` is `undef`.
//   edge_len = explicit target edge length; pass the same value used by `place_on_edges(...)`.
//   edge_idx = source edge index; defaults to `$ps_edge_idx` inside `place_on_edges(...)`.
//   mode = face fill mode used when deriving adjacent face boundary spans.
//   eps = geometric tolerance.
function ps_edge_region_shells(poly, outset, z0, z1, inter_radius=1, edge_len=undef, edge_idx=$ps_edge_idx, mode="nonzero", eps=1e-8) =
    let(
        _edge_idx = assert(!is_undef(edge_idx), "ps_edge_region_shells: edge_idx is required; call inside place_on_edges(...) or pass edge_idx"),
        _outset = assert(outset > eps, "ps_edge_region_shells: outset must be positive"),
        _z0 = assert(!is_undef(z0), "ps_edge_region_shells: z0 must be defined"),
        _z1 = assert(!is_undef(z1), "ps_edge_region_shells: z1 must be defined"),
        _height = assert(abs(z1 - z0) > eps, "ps_edge_region_shells: z0 and z1 must differ"),
        edge_site = ps_edge_sites(poly, inter_radius, edge_len)[edge_idx],
        edge_verts = ps_edge_site_verts_idx(edge_site),
        adj_faces = ps_edge_site_adj_faces_idx(edge_site),
        _closed = assert(len(adj_faces) == 2, "ps_edge_region_shells: edge must have exactly two adjacent faces"),
        face_sites = ps_face_sites(poly, inter_radius, edge_len),
        spans0 = _ps_er_face_edge_boundary_spans(face_sites[adj_faces[0]], edge_verts, mode, eps),
        spans1 = _ps_er_face_edge_boundary_spans(face_sites[adj_faces[1]], edge_verts, mode, eps),
        intervals = _ps_er_atom_intervals(spans0, spans1, eps)
    )
    [
        for (atom = intervals)
            let(
                span0 = _ps_er_span_at_t(spans0, atom[2], eps),
                span1 = _ps_er_span_at_t(spans1, atom[2], eps)
            )
            if (!is_undef(span0) && !is_undef(span1))
                each _ps_er_atom_shells(edge_site, atom, span0, span1, outset, z0, z1, eps)
    ];

// Module: ps_edge_region_volume()
// Usage:
//   ps_edge_region_volume(poly, outset, z0, z1, inter_radius, edge_len, edge_idx, mode, eps, convexity);
// Description:
//   Emit edge-region atom shells for the current or supplied source edge.
//   .
//   - Returns: none; intended for use inside `place_on_edges(...)`
// Arguments:
//   poly = source poly descriptor.
//   outset = symmetric side offset from the topological edge.
//   z0 = lower edge-local Z bound.
//   z1 = upper edge-local Z bound.
//   inter_radius = target interradius scale used when `edge_len` is `undef`.
//   edge_len = explicit target edge length.
//   edge_idx = source edge index; defaults to `$ps_edge_idx`.
//   mode = face fill mode used when deriving adjacent face boundary spans.
//   eps = geometric tolerance.
//   convexity = OpenSCAD polyhedron convexity hint.
module ps_edge_region_volume(poly, outset, z0, z1, inter_radius=1, edge_len=undef, edge_idx=$ps_edge_idx, mode="nonzero", eps=1e-8, convexity=6) {
    shells = ps_edge_region_shells(poly, outset, z0, z1, inter_radius, edge_len, edge_idx, mode, eps);

    union() {
        for (shell = shells)
            ps_loop_shell(shell, convexity);
    }
}
