/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

// LibFile: polysymmetrica/core/transform.scad
use <funcs.scad>

// Generic site/cycle poly transform kernel.
// Keep this file minimal and reusable across future operators.

// index of point p in list (or -1)
function _ps_find_point(list, p, eps, i=0) =
    (i >= len(list)) ? -1 :
    (ps_point_eq(list[i], p, eps) ? i : _ps_find_point(list, p, eps, i+1));

// Build unique vertex list from a flat list of points
function _ps_unique_points(points, eps, acc=[], i=0) =
    (i >= len(points)) ? acc :
    let(p = points[i])
    (_ps_find_point(acc, p, eps) >= 0)
        ? _ps_unique_points(points, eps, acc, i+1)
        : _ps_unique_points(points, eps, concat(acc, [p]), i+1);

// Remap a face described by points -> indices in uniq[]
function _ps_face_points_to_indices(uniq, face_pts, eps) =
    [ for (p = face_pts) _ps_find_point(uniq, p, eps) ];

// Build a poly descriptor from face point lists (dedup + orient + unit-edge scale).
function _ps_face_keep_after_simplify(f) =
    (len(f) >= 3) && (_ps_distinct_count(f) >= 3);

function _ps_poly_from_face_points(faces_pts_all, eps, len_eps=undef) =
    let(
        len_eps_eff = is_undef(len_eps) ? eps : len_eps,
        bad_pts = [
            for (fi = [0:1:len(faces_pts_all)-1])
                for (pi = [0:1:len(faces_pts_all[fi])-1])
                    let(p = faces_pts_all[fi][pi])
                    if (
                        is_undef(p) ||
                        (len(p) < 3) ||
                        (len([for (c = p) if (is_undef(c)) 1]) > 0)
                    )
                    [fi, pi, p]
        ],
        _ = assert(
            len(bad_pts) == 0,
            str("transform: undef point at face ", bad_pts[0][0], " idx ", bad_pts[0][1], " p=", bad_pts[0][2])
        ),
        all_pts = [ for (fp = faces_pts_all) for (p = fp) p ],
        uniq_verts = _ps_unique_points(all_pts, len_eps_eff),
        faces_idx = [ for (fp = faces_pts_all) _ps_face_points_to_indices(uniq_verts, fp, len_eps_eff) ],
        faces_idx_simpl = [ for (f = faces_idx) _ps_face_clean_cycle(f) ],
        faces_idx_keep = [ for (f = faces_idx_simpl) if (_ps_face_keep_after_simplify(f)) f ],
        _simp_ok = assert(len(faces_idx_keep) > 0, "transform: no non-degenerate faces after simplification"),
        faces_out = ps_orient_all_faces_outward(uniq_verts, faces_idx_keep),
        edges_new = _ps_edges_from_faces(faces_out),
        _edge_ok = assert(len(edges_new) > 0, "transform: no edges after simplification"),
        e0 = edges_new[0],
        vA = uniq_verts[e0[0]],
        vB = uniq_verts[e0[1]],
        unit_e = norm(vB - vA),
        mid = (vA + vB) / 2,
        ir  = norm(mid),
        e_over_ir = unit_e / ir
    )
    poly_make(uniq_verts / unit_e, faces_out, e_over_ir);

// Function: ps_poly_transform_from_sites()
// Usage:
//   result = ps_poly_transform_from_sites(verts0, sites, site_points,
//       face_cycles, eps=1e-8, len_eps=1e-6);
// Description:
//   Build a poly descriptor from site-based face cycles.
// Arguments:
//   verts0 = original vertex list, before generated transform points are added.
//   sites = metadata records for generated sites; used for duplicate-site detection and provenance checks.
//   site_points = generated 3D points corresponding one-to-one with `sites`.
//   face_cycles = output face cycles using `[0, v_idx]` for original vertices and `[1, site_idx]` for generated site points.
//   eps = geometric tolerance for face simplification and validation.
//   len_eps = point-merging tolerance for coincident generated/original points.
function ps_poly_transform_from_sites(verts0, sites, site_points, face_cycles, eps=1e-8, len_eps=1e-6) =
    let(
        faces_pts_all = [
            for (cy = face_cycles)
                [ for (c = cy) (c[0] == 0) ? verts0[c[1]] : site_points[c[1]] ]
        ],
        bad_cycles = [
            for (cyi = [0:1:len(face_cycles)-1])
                for (ci = [0:1:len(face_cycles[cyi])-1])
                    let(
                        c = face_cycles[cyi][ci],
                        p = (c[0] == 0) ? verts0[c[1]] : site_points[c[1]]
                    )
                    if (
                        is_undef(p) ||
                        (len(p) < 3) ||
                        (len([for (v = p) if (is_undef(v)) 1]) > 0)
                    )
                    [cyi, ci, c, p]
        ],
        _ = assert(
            len(bad_cycles) == 0,
            str("transform: bad cycle point at face_cycle ", bad_cycles[0][0],
                " idx ", bad_cycles[0][1], " c=", bad_cycles[0][2], " p=", bad_cycles[0][3])
        )
    )
    _ps_poly_from_face_points(faces_pts_all, eps, len_eps);
