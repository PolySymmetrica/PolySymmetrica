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

function _ps_transform_site_provenance(prov, site, operation) =
    let(
        vertices = _ps_prov_vertices(prov),
        faces = _ps_prov_faces(prov),
        is_chamfer = operation == "chamfer",
        is_truncate = operation == "truncate",
        is_cantitruncate = operation == "cantitruncate",
        fi = is_chamfer ? site[0] : undef,
        vi = is_chamfer ? site[1] : undef,
        prev_vi = is_chamfer && len(site) > 2 ? site[2] : undef,
        next_vi = is_chamfer && len(site) > 3 ? site[3] : undef,
        a = is_truncate && len(site) > 3 ? site[2] : undef,
        b = is_truncate && len(site) > 3 ? site[3] : undef,
        near_v = is_truncate && len(site) > 4 ? site[4] : (is_truncate ? site[1] : undef),
        tag = is_cantitruncate && len(site) > 0 ? site[0] : undef,
        cant_fi = is_cantitruncate && len(site) > 1 ? site[1] : undef,
        cant_a = is_cantitruncate && len(site) > 2 ? site[2] : undef,
        cant_b = is_cantitruncate && len(site) > 3 ? site[3] : undef,
        cant_v = is_cantitruncate && tag == "cantitruncate_face" && len(site) > 2 ? site[2] : undef,
        records = is_chamfer
            ? concat(
                [vertices[vi], faces[fi]],
                is_undef(prev_vi) ? [] : [vertices[prev_vi]],
                is_undef(next_vi) ? [] : [vertices[next_vi]]
            )
            : is_truncate
                ? concat(
                    is_undef(a) ? [] : [vertices[a]],
                    is_undef(b) ? [] : [vertices[b]],
                    is_undef(near_v) ? [] : [vertices[near_v]]
                )
                : is_cantitruncate
                    ? concat(
                        is_undef(cant_a) || tag == "cantitruncate_face" ? [] : [vertices[cant_a]],
                        is_undef(cant_b) || tag == "cantitruncate_face" ? [] : [vertices[cant_b]],
                        is_undef(cant_v) ? [] : [vertices[cant_v]],
                        is_undef(cant_fi) ? [] : [faces[cant_fi]]
                    )
                : []
    )
    _ps_prov_merge_records(
        [for (r = records) _ps_prov_record(r[0], r[1])],
        is_chamfer ? ["chamfer_site", fi, vi]
            : is_truncate ? ["truncation_site", near_v]
            : is_cantitruncate ? ["cantitruncate_site", tag, cant_fi]
            : ["generated_site"]
    );

function _ps_transform_cycle_provenance(records, operation) =
    _ps_prov_merge_records(
        [for (r = records) _ps_prov_record(r[0], r[1])],
        is_undef(operation) ? ["transform_face"] : [str(operation, "_face")]
    );

function _ps_poly_from_face_points(
    faces_pts_all,
    eps,
    len_eps=undef,
    orientation="global",
    point_provenance=undef,
    face_provenance=undef,
    provenance_history=undef
) =
    let(
        _orient_ok = assert(orientation == "global" || orientation == "semantic", "transform: orientation must be global or semantic"),
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
        point_lineages = is_undef(point_provenance)
            ? undef
            : [for (p = uniq_verts) point_provenance[_ps_find_point(all_pts, p, len_eps_eff)]],
        face_lineages = is_undef(face_provenance)
            ? undef
            : [
                for (i = [0:1:len(faces_idx_simpl)-1])
                    if (_ps_face_keep_after_simplify(faces_idx_simpl[i])) face_provenance[i]
            ],
        _simp_ok = assert(len(faces_idx_keep) > 0, "transform: no non-degenerate faces after simplification"),
        faces_out = (orientation == "semantic")
            ? [for (f = faces_idx_keep) ps_orient_face_outward(uniq_verts, f)]
            : ps_orient_all_faces_outward(uniq_verts, faces_idx_keep),
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
    is_undef(point_provenance)
        ? poly_make(uniq_verts / unit_e, faces_out, e_over_ir)
        : poly_make(
            uniq_verts / unit_e,
            faces_out,
            e_over_ir,
            ["ps_provenance_v1", point_lineages, face_lineages, is_undef(provenance_history) ? [] : provenance_history]
        );

// Function: ps_poly_transform_from_sites()
// Usage:
//   result = ps_poly_transform_from_sites(verts0, sites, site_points,
//       face_cycles, eps=1e-8, len_eps=1e-6, orientation="global");
// Description:
//   Build a poly descriptor from site-based face cycles.
// Arguments:
//   verts0 = original vertex list, before generated transform points are added.
//   sites = metadata records for generated sites; used for duplicate-site detection and provenance checks.
//   site_points = generated 3D points corresponding one-to-one with `sites`.
//   face_cycles = output face cycles using `[0, v_idx]` for original vertices and `[1, site_idx]` for generated site points.
//   eps = geometric tolerance for face simplification and validation.
//   len_eps = point-merging tolerance for coincident generated/original points.
//   orientation = `"global"` for topology/global-volume orientation, or `"semantic"` for per-face origin orientation.
function ps_poly_transform_from_sites(
    verts0,
    sites,
    site_points,
    face_cycles,
    eps=1e-8,
    len_eps=1e-6,
    orientation="global",
    provenance=undef,
    operation=undef
) =
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
        ),
        point_provenance = is_undef(provenance)
            ? undef
            : [
                for (cy = face_cycles)
                    for (c = cy)
                        (c[0] == 0)
                            ? _ps_prov_vertices(provenance)[c[1]]
                            : _ps_transform_site_provenance(provenance, sites[c[1]], operation)
            ],
        face_provenance = is_undef(provenance)
            ? undef
            : [
                for (cy = face_cycles)
                    _ps_transform_cycle_provenance(
                        [
                            for (c = cy)
                                (c[0] == 0)
                                    ? _ps_prov_vertices(provenance)[c[1]]
                                    : _ps_transform_site_provenance(provenance, sites[c[1]], operation)
                        ],
                        operation
                    )
            ],
        provenance_history = is_undef(provenance)
            ? undef
            : (is_undef(operation) ? provenance[3] : concat(provenance[3], [[operation]]))
    )
    _ps_poly_from_face_points(
        faces_pts_all,
        eps,
        len_eps,
        orientation,
        point_provenance,
        face_provenance,
        provenance_history
    );
