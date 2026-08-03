/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

// LibFile: polysymmetrica/core/face_regions.scad

// ---------------------------------------------------------------------------
// PolySymmetrica - Face-region volume helpers
// Builds positive face-local volumes from filled face boundary spans.

use <funcs.scad>
use <loop_shells.scad>
use <segments.scad>
use <vertex.scad>

// Function: _ps_fr_orient2()
// Usage:
//   result = _ps_fr_orient2(a, b, c);
// Description:
//   Signed 2D triangle orientation.
//   .
//   - Returns: positive for left turn, negative for right turn, zero for colinear
// Arguments:
//   a = 2D points
//   b = 2D points
//   c = 2D points
function _ps_fr_orient2(a, b, c) =
    (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0]);

// Function: _ps_fr_line2_intersect()
// Usage:
//   result = _ps_fr_line2_intersect(n0, d0, n1, d1, eps);
// Description:
//   Intersect 2D lines represented as `n dot p = d`.
//   .
//   - Returns: 2D intersection point, or `undef` for near-parallel lines
// Arguments:
//   n0 =
//   d0 =
//   n1 = line equations
//   d1 = line equations
//   eps = parallel tolerance
function _ps_fr_line2_intersect(n0, d0, n1, d1, eps=1e-12) =
    let(det = n0[0]*n1[1] - n0[1]*n1[0])
    (abs(det) < eps) ? undef
  : [
        (d0*n1[1] - n0[1]*d1) / det,
        (n0[0]*d1 - d0*n1[0]) / det
    ];

// Function: _ps_fr_line_normal()
// Usage:
//   result = _ps_fr_line_normal(line);
// Description:
//   Build a left-hand normal for a 2D point+direction line.
//   .
//   - Returns: 2D normal vector
// Arguments:
//   line = `[point2d, dir2d, ...]`
function _ps_fr_line_normal(line) =
    [-line[1][1], line[1][0]];

// Function: _ps_fr_line_intersection()
// Usage:
//   result = _ps_fr_line_intersection(line0, line1, eps);
// Description:
//   Intersect two 2D point+direction lines.
//   .
//   - Returns: 2D intersection point, or `undef` for near-parallel lines
// Arguments:
//   line0 = `[point2d, dir2d, ...]`
//   line1 = `[point2d, dir2d, ...]`
//   eps = parallel tolerance
function _ps_fr_line_intersection(line0, line1, eps=1e-9) =
    let(
        n0 = _ps_fr_line_normal(line0),
        n1 = _ps_fr_line_normal(line1),
        d0 = v_dot(n0, line0[0]),
        d1 = v_dot(n1, line1[0])
    )
    _ps_fr_line2_intersect(n0, d0, n1, d1, eps);

// Function: _ps_fr_span_source_point()
// Usage:
//   result = _ps_fr_span_source_point(face_pts3d_local, site, t);
// Description:
//   Reconstruct a boundary-span point on its source edge.
//   .
//   - Returns: face-local 3D point, or `undef` when source edge metadata is missing
// Arguments:
//   face_pts3d_local = source face loop
//   site = boundary-span site
//   t = source-edge parameter
function _ps_fr_span_source_point(face_pts3d_local, site, t) =
    let(
        source_edge_idx = ps_boundary_span_site_source_edge_idx(site),
        n = len(face_pts3d_local),
        a = is_undef(source_edge_idx) ? undef : face_pts3d_local[source_edge_idx],
        b = is_undef(source_edge_idx) ? undef : face_pts3d_local[(source_edge_idx + 1) % n]
    )
    (is_undef(a) || is_undef(b)) ? undef : a + (b - a) * t;

// Function: _ps_fr_span_seg3d()
// Usage:
//   result = _ps_fr_span_seg3d(face_pts3d_local, site);
// Description:
//   Reconstruct the source-edge 3D segment for one boundary-span site.
//   .
//   - Returns: `[p0, p1]` in face-local 3D, falling back to the planar span when source data is absent
// Arguments:
//   face_pts3d_local = source face loop
//   site = boundary-span site
function _ps_fr_span_seg3d(face_pts3d_local, site) =
    let(
        p0 = _ps_fr_span_source_point(face_pts3d_local, site, ps_boundary_span_site_source_t0(site)),
        p1 = _ps_fr_span_source_point(face_pts3d_local, site, ps_boundary_span_site_source_t1(site)),
        seg2d = ps_boundary_span_site_segment2d_local(site)
    )
    (is_undef(p0) || is_undef(p1))
        ? [[seg2d[0][0], seg2d[0][1], 0], [seg2d[1][0], seg2d[1][1], 0]]
        : [p0, p1];

// Function: _ps_fr_span_exterior_ray()
// Usage:
//   result = _ps_fr_span_exterior_ray(site);
// Description:
//   Return the current-face in-plane ray out of the filled side of a span.
//   .
//   - Returns: span-local unit ray `[0,+/-1,0]` pointing outside the filled region
// Arguments:
//   site = boundary-span site
function _ps_fr_span_exterior_ray(site) =
    [0, (ps_boundary_span_site_filled_side(site) < 0) ? 1 : -1, 0];

// Function: _ps_fr_span_filled_ray()
// Usage:
//   result = _ps_fr_span_filled_ray(site);
// Description:
//   Return the current-face in-plane ray into the filled side of a span.
//   .
//   - Returns: span-local unit ray `[0,+/-1,0]` pointing inside the filled region
// Arguments:
//   site = boundary-span site
function _ps_fr_span_filled_ray(site) =
    [0, (ps_boundary_span_site_filled_side(site) < 0) ? -1 : 1, 0];

// Function: _ps_fr_winding_number()
// Usage:
//   result = _ps_fr_winding_number(pt, poly, eps);
// Description:
//   Compute integer winding number of a 2D loop around a point.
//   .
//   - Returns: integer winding number
// Arguments:
//   pt = 2D point
//   poly = 2D loop
//   eps = orientation tolerance
function _ps_fr_winding_number(pt, poly, eps=1e-9) =
    let(
        x = pt[0],
        y = pt[1],
        n = len(poly)
    )
    ps_sum([
        for (i = [0:1:n-1])
            let(
                j = (i + 1) % n,
                a = poly[i],
                b = poly[j],
                is_left = _ps_fr_orient2(a, b, pt)
            )
            (a[1] <= y && b[1] > y && is_left > eps) ? 1 :
            (a[1] > y && b[1] <= y && is_left < -eps) ? -1 :
            0
    ]);

// Function: _ps_fr_cell_winding_signs()
// Usage:
//   result = _ps_fr_cell_winding_signs(face_pts3d_local, cells, eps);
// Description:
//   Build winding signs for arrangement cells under the source face loop.
//   .
//   - Returns: list of cell winding signs (`+1`, `-1`, or `0`)
// Arguments:
//   face_pts3d_local = source face loop
//   cells = face arrangement cells
//   eps = tolerance
function _ps_fr_cell_winding_signs(face_pts3d_local, cells, eps=1e-8) =
    let(face_pts2d = ps_xy(face_pts3d_local))
    [
        for (cell = cells)
            let(
                probe = _ps_seg_cycle_probe_point(cell[0], eps),
                wn = _ps_fr_winding_number(probe, face_pts2d, eps)
            )
            (wn > 0) ? 1 : (wn < 0) ? -1 : 0
    ];

// Function: _ps_fr_span_face_plane_ray()
// Usage:
//   result = _ps_fr_span_face_plane_ray(site, input_sign, cell_winding_signs);
// Description:
//   Select the face-plane ray used by anti-interference projection.
//   .
//   - Returns: exterior ray for same-winding cells, filled ray for opposite-winding cells
// Arguments:
//   site = boundary-span site
//   input_sign = source face signed-area sign
//   cell_winding_signs = per-arrangement-cell winding signs
function _ps_fr_span_face_plane_ray(site, input_sign, cell_winding_signs) =
    let(
        cell_idx = ps_boundary_span_site_filled_cell_idx(site),
        cell_sign =
            (is_undef(cell_idx) || cell_idx < 0 || cell_idx >= len(cell_winding_signs))
                ? 0
                : cell_winding_signs[cell_idx],
        same_winding = (cell_sign == 0) || (cell_sign == input_sign)
    )
    same_winding ? _ps_fr_span_exterior_ray(site) : _ps_fr_span_filled_ray(site);

// Function: _ps_fr_span_exposure_sign()
// Usage:
//   result = _ps_fr_span_exposure_sign(site, input_sign, cell_winding_signs);
// Description:
//   Classify one boundary span's filled cell relative to the source face winding.
//   .
//   - Returns: `+1` for same- or zero-winding/top-exposed cells, `-1` for opposite-winding/bottom-exposed cells
// Arguments:
//   site = boundary-span site
//   input_sign = source face signed-area sign
//   cell_winding_signs = per-arrangement-cell winding signs
function _ps_fr_span_exposure_sign(site, input_sign, cell_winding_signs) =
    let(
        cell_idx = ps_boundary_span_site_filled_cell_idx(site),
        cell_sign =
            (is_undef(cell_idx) || cell_idx < 0 || cell_idx >= len(cell_winding_signs))
                ? 0
                : cell_winding_signs[cell_idx]
    )
    (cell_sign == 0 || cell_sign == input_sign) ? 1 : -1;

// Function: _ps_fr_loop_exposure_sign()
// Usage:
//   result = _ps_fr_loop_exposure_sign(loop_sites, input_sign, cell_winding_signs);
// Description:
//   Classify a boundary loop's filled region exposure relative to the source face winding.
//   .
//   - Returns: `+1` for same- or zero-winding/top-exposed loops, `-1` for opposite-winding/bottom-exposed loops
// Arguments:
//   loop_sites = sites for one boundary loop
//   input_sign = source face signed-area sign
//   cell_winding_signs = per-arrangement-cell winding signs
function _ps_fr_loop_exposure_sign(loop_sites, input_sign, cell_winding_signs) =
    let(
        signs = [for (site = loop_sites) _ps_fr_span_exposure_sign(site, input_sign, cell_winding_signs)],
        first = len(signs) == 0 ? 0 : signs[0],
        mixed_count = len([for (sign = signs) if (sign != first) 1]),
        _has_sites = assert(len(signs) > 0, "ps_face_region_loop_shells: boundary loop has no sites"),
        _consistent = assert(mixed_count == 0, "ps_face_region_loop_shells: boundary loop mixes exposure signs")
    )
    first;

// Function: _ps_fr_span_bisector_dir_span_local()
// Usage:
//   result = _ps_fr_span_bisector_dir_span_local(site, input_sign, cell_winding_signs, eps);
// Description:
//   Build the anti-interference bisector direction in span-local coords.
//   .
//   - Returns: span-local unit direction between the selected face-plane ray and adjacent-face +Z branch
// Arguments:
//   site = boundary-span site
//   input_sign = source face signed-area sign
//   cell_winding_signs = per-arrangement-cell winding signs
//   eps = zero-length tolerance
function _ps_fr_span_bisector_dir_span_local(site, input_sign, cell_winding_signs, eps=1e-8) =
    let(
        face_ray = _ps_fr_span_face_plane_ray(site, input_sign, cell_winding_signs),
        adj0 = ps_boundary_span_site_adj_face_dir_span_local(site),
        adj_unit = (is_undef(adj0) || norm(adj0) <= eps) ? undef : v_norm(adj0),
        raw = is_undef(adj_unit) ? [0, 0, 1] : face_ray + adj_unit
    )
    (norm(raw) <= eps) ? [0, 0, 1] : v_norm(raw);

// Function: _ps_fr_span_to_face_local()
// Usage:
//   result = _ps_fr_span_to_face_local(site, v_span);
// Description:
//   Transform a span-local vector into current face-local coordinates.
//   .
//   - Returns: face-local vector
// Arguments:
//   site = boundary-span site
//   v_span = span-local vector
function _ps_fr_span_to_face_local(site, v_span) =
    ps_boundary_span_site_ex_local(site) * v_span[0]
        + ps_boundary_span_site_ey_local(site) * v_span[1]
        + ps_boundary_span_site_ez_local(site) * v_span[2];

// Function: _ps_fr_span_bisector_dir_local()
// Usage:
//   result = _ps_fr_span_bisector_dir_local(site, input_sign, cell_winding_signs, eps);
// Description:
//   Build the anti-interference bisector direction in face-local coords.
//   .
//   - Returns: face-local unit direction
// Arguments:
//   site = boundary-span site
//   input_sign = source face signed-area sign
//   cell_winding_signs = per-arrangement-cell winding signs
//   eps = zero-length tolerance
function _ps_fr_span_bisector_dir_local(site, input_sign, cell_winding_signs, eps=1e-8) =
    v_norm(_ps_fr_span_to_face_local(site, _ps_fr_span_bisector_dir_span_local(site, input_sign, cell_winding_signs, eps)));

// Function: _ps_fr_project_offset()
// Usage:
//   result = _ps_fr_project_offset(dz, dir_z, max_project, eps);
// Description:
//   Compute scalar projection distance needed to reach a target Z plane.
//   .
//   - Returns: scalar offset along the projection direction
// Arguments:
//   dz = target minus source Z
//   dir_z = projection direction Z
//   max_project = optional cap
//   eps = near-flat tolerance
function _ps_fr_project_offset(dz, dir_z, max_project=undef, eps=1e-8) =
    let(
        _ok = assert(
            abs(dz) <= eps || abs(dir_z) > eps || !is_undef(max_project),
            "ps_face_region_loop_shells: projection direction is too close to parallel to target Z plane; set max_project"
        )
    )
    (abs(dz) <= eps) ? 0 :
    (abs(dir_z) <= eps)
        ? (dz >= 0 ? 1 : -1) * abs(max_project)
        : let(
            raw = dz / dir_z,
            cap = is_undef(max_project) ? undef : abs(max_project)
        )
        is_undef(cap) ? raw : ps_clamp(raw, -cap, cap);

// Function: _ps_fr_project_was_capped()
// Usage:
//   result = _ps_fr_project_was_capped(dz, dir_z, max_project, eps);
// Description:
//   Report whether a projection offset would be capped.
//   .
//   - Returns: boolean
// Arguments:
//   dz = target minus source Z
//   dir_z = projection direction Z
//   max_project = optional cap
//   eps = near-flat tolerance
function _ps_fr_project_was_capped(dz, dir_z, max_project=undef, eps=1e-8) =
    is_undef(max_project) ? false :
    (abs(dz) <= eps) ? false :
    (abs(dir_z) <= eps) ? true :
    abs(dz / dir_z) > abs(max_project) + eps;

// Function: _ps_fr_boundary_inset_face_offset()
// Usage:
//   result = _ps_fr_boundary_inset_face_offset(site, dir, boundary_inset, boundary_inset_mode, eps);
// Description:
//   Convert requested boundary clearance to a face-plane line shift.
//   .
//   - Returns: face-plane offset to apply toward the filled side
// Arguments:
//   site = boundary-span site
//   dir = anti-interference projection direction
//   boundary_inset = requested clearance
//   boundary_inset_mode = `"side"` or `"face"`
//   eps = tolerance
function _ps_fr_boundary_inset_face_offset(site, dir, boundary_inset=0, boundary_inset_mode="side", eps=1e-8) =
    let(
        _mode = assert(
            boundary_inset_mode == "side" || boundary_inset_mode == "face",
            "ps_face_region_loop_shells: boundary_inset_mode must be \"side\" or \"face\""
        )
    )
    (boundary_inset <= eps) ? 0 :
    (boundary_inset_mode == "face") ? boundary_inset :
    let(
        edge_dir = ps_boundary_span_site_ex_local(site),
        filled_dir = _ps_fr_span_to_face_local(site, _ps_fr_span_filled_ray(site)),
        side_n_raw = v_cross(edge_dir, dir),
        side_n = (norm(side_n_raw) <= eps) ? undef : v_norm(side_n_raw),
        denom = is_undef(side_n) ? 0 : abs(v_dot(side_n, filled_dir))
    )
    (denom <= eps) ? boundary_inset : boundary_inset / denom;

// Function: _ps_fr_project_span_line()
// Usage:
//   result = _ps_fr_project_span_line(face_pts3d_local, site, z, input_sign, cell_winding_signs, max_project, boundary_inset, boundary_inset_mode, eps);
// Description:
//   Project one boundary span to a target Z plane as a 2D line.
//   .
//   - Returns: `[point2d, dir2d, was_capped, span_idx, source_edge_idx]`
// Arguments:
//   face_pts3d_local = source face loop
//   site = boundary-span site
//   z = target face-local Z
//   input_sign = anti-interference direction context
//   cell_winding_signs = anti-interference direction context
//   max_project = optional cap
//   boundary_inset = positive shift toward filled side
//   boundary_inset_mode = `"side"` or `"face"`
//   eps = tolerance
function _ps_fr_project_span_line(face_pts3d_local, site, z, input_sign, cell_winding_signs, max_project=undef, boundary_inset=0, boundary_inset_mode="side", eps=1e-8) =
    let(
        seg3d = _ps_fr_span_seg3d(face_pts3d_local, site),
        mid = (seg3d[0] + seg3d[1]) / 2,
        dir = _ps_fr_span_bisector_dir_local(site, input_sign, cell_winding_signs, eps),
        offset = _ps_fr_project_offset(z - mid[2], dir[2], max_project, eps),
        p = mid + dir * offset,
        inset_dir3 = _ps_fr_span_to_face_local(site, _ps_fr_span_filled_ray(site)),
        inset_dir2_raw = [inset_dir3[0], inset_dir3[1]],
        inset_dir2 = (norm(inset_dir2_raw) <= eps) ? [0, 0] : v_norm(inset_dir2_raw),
        inset_offset = _ps_fr_boundary_inset_face_offset(site, dir, boundary_inset, boundary_inset_mode, eps),
        p_inset = [p[0], p[1]] + inset_dir2 * inset_offset,
        ex = ps_boundary_span_site_ex_local(site),
        ex2d = [ex[0], ex[1]],
        line_dir = (norm(ex2d) <= eps) ? [1, 0] : v_norm(ex2d)
    )
    [
        p_inset,
        line_dir,
        _ps_fr_project_was_capped(z - mid[2], dir[2], max_project, eps),
        ps_boundary_span_site_idx(site),
        ps_boundary_span_site_source_edge_idx(site)
    ];

function _ps_fr_span_end_source_vertex_idx(site, face, eps=1e-8) =
    let(
        source_edge_idx = ps_boundary_span_site_source_edge_idx(site),
        source_t1 = ps_boundary_span_site_source_t1(site)
    )
    (is_undef(source_edge_idx) || source_edge_idx < 0 || source_edge_idx >= len(face))
        ? undef
        : (abs(source_t1 - 1) <= eps)
            ? face[(source_edge_idx + 1) % len(face)]
            : (abs(source_t1) <= eps)
                ? face[source_edge_idx]
                : undef;

function _ps_fr_vertex_raw_cap_points(poly_verts_local, vertex_idx, neighbors_idx, inset, eps=1e-8) =
    let(vertex_pt = poly_verts_local[vertex_idx])
    [
        for (ni = neighbors_idx)
            let(
                dir = poly_verts_local[ni] - vertex_pt,
                len_dir = norm(dir),
                _len = assert(len_dir > eps, str("ps_face_region_loop_shells: zero-length vertex fan edge at vertex ", vertex_idx))
            )
            vertex_pt + dir / len_dir * inset
    ];

function _ps_fr_vertex_clip_line(poly_faces_idx, poly_verts_local, edges, edge_faces, face_idx, vertex_idx, prev_span_line, next_span_line, boundary_inset=0, eps=1e-8) =
    (is_undef(vertex_idx) || boundary_inset <= eps) ? undef :
    let(
        poly_local = [poly_verts_local, poly_faces_idx, 1],
        closed_fan = _ps_vertex_has_closed_fan(poly_faces_idx, edges, edge_faces, vertex_idx),
        fig = closed_fan ? ps_vertex_figure(poly_local, vertex_idx, edges, edge_faces) : undef,
        faces_idx = closed_fan ? ps_vertex_figure_faces_idx(fig) : [],
        neighbors_idx = closed_fan ? ps_vertex_figure_neighbors_idx(fig) : [],
        valence = len(neighbors_idx),
        face_pos = _ps_index_of(faces_idx, face_idx)
    )
    (!closed_fan || valence <= 3 || face_pos < 0) ? undef :
    let(
        vertex_pt = poly_verts_local[vertex_idx],
        raw_pts = _ps_fr_vertex_raw_cap_points(poly_verts_local, vertex_idx, neighbors_idx, boundary_inset, eps),
        can_clip = _ps_vertex_figure_points_from_raw_on_rays_realizable(
            vertex_pt,
            raw_pts,
            raw_pts,
            "planar_edge_fraction",
            undef,
            eps
        )
    )
    (!can_clip) ? undef :
    let(
        cap_pts = ps_vertex_figure_points_from_raw(
            vertex_pt,
            raw_pts,
            "planar_edge_fraction",
            undef,
            eps
        ),
        prev_i = (face_pos - 1 + valence) % valence,
        next_i = face_pos,
        p0 = ps_xy([cap_pts[prev_i]])[0],
        p1 = ps_xy([cap_pts[next_i]])[0],
        dir = p1 - p0,
        len_dir = norm(dir),
        miter = _ps_fr_line_intersection(prev_span_line, next_span_line, eps),
        line_point = is_undef(miter) ? p0 : miter
    )
    (len_dir <= eps) ? undef :
    [
        line_point,
        dir / len_dir,
        false,
        str("vertex:", vertex_idx)
    ];

function _ps_fr_projected_lines_with_vertex_clips(face_pts3d_local, poly_faces_idx, poly_verts_local, face_idx, edges, edge_faces, loop_sites, z, input_sign, cell_winding_signs, max_project=undef, boundary_inset=0, boundary_inset_mode="side", eps=1e-8) =
    let(
        face = poly_faces_idx[face_idx],
        span_lines = [
            for (site = loop_sites)
                _ps_fr_project_span_line(face_pts3d_local, site, z, input_sign, cell_winding_signs, max_project, boundary_inset, boundary_inset_mode, eps)
        ],
        n = len(loop_sites)
    )
    [
        for (i = [0:1:n-1])
            let(
                site = loop_sites[i],
                span_line = span_lines[i],
                vertex_idx = _ps_fr_span_end_source_vertex_idx(site, face, eps),
                next_span_line = span_lines[(i + 1) % n],
                vertex_line = _ps_fr_vertex_clip_line(poly_faces_idx, poly_verts_local, edges, edge_faces, face_idx, vertex_idx, span_line, next_span_line, boundary_inset, eps)
            )
            each (is_undef(vertex_line) ? [span_line] : [span_line, vertex_line])
    ];

// Function: _ps_fr_projected_loop()
// Usage:
//   result = _ps_fr_projected_loop(lines, eps);
// Description:
//   Convert a circular list of projected boundary lines into loop vertices.
//   .
//   - Returns: 2D loop from intersections of adjacent lines
// Arguments:
//   lines = projected line records
//   eps = parallel tolerance
function _ps_fr_projected_loop(lines, eps=1e-8) =
    let(n = len(lines))
    (n < 3) ? [] :
    [
        for (i = [0:1:n-1])
            let(hit = _ps_fr_line_intersection(lines[(i - 1 + n) % n], lines[i], eps))
            is_undef(hit) ? lines[i][0] : hit
    ];

// Function: _ps_fr_unique_loop_ids()
// Usage:
//   result = _ps_fr_unique_loop_ids(sites, i, acc);
// Description:
//   Collect distinct loop ids from boundary-span sites preserving first-seen order.
//   .
//   - Returns: list of loop ids
// Arguments:
//   sites = boundary-span site records
//   i = recursion state
//   acc = recursion state
function _ps_fr_unique_loop_ids(sites, i=0, acc=[]) =
    (i >= len(sites)) ? acc :
    let(loop_idx = ps_boundary_span_site_loop_idx(sites[i]))
    _ps_fr_unique_loop_ids(
        sites,
        i + 1,
        _ps_list_contains(acc, loop_idx) ? acc : concat(acc, [loop_idx])
    );

// Function: _ps_fr_sites_for_loop()
// Usage:
//   result = _ps_fr_sites_for_loop(sites, loop_idx);
// Description:
//   Filter boundary-span sites to one boundary loop.
//   .
//   - Returns: site records for that loop, in source boundary order
// Arguments:
//   sites = boundary-span site records
//   loop_idx = target loop id
function _ps_fr_sites_for_loop(sites, loop_idx) =
    [for (site = sites) if (ps_boundary_span_site_loop_idx(site) == loop_idx) site];

// Function: _ps_fr_cap_faces()
// Usage:
//   result = _ps_fr_cap_faces(loop2d, offset, target_area_sign, eps);
// Description:
//   Triangulate one projected cap loop into indexed polyhedron faces.
//   .
//   - Returns: list of triangle index faces
// Arguments:
//   loop2d = cap loop
//   offset = point-index offset
//   target_area_sign = desired triangle orientation
//   eps = tolerance
function _ps_fr_cap_faces(loop2d, offset, target_area_sign, eps=1e-8) =
    [
        for (t = _ps_seg_triangulate_simple_poly_idx(loop2d, eps))
            let(
                area = _ps_fr_orient2(loop2d[t[0]], loop2d[t[1]], loop2d[t[2]]),
                oriented = (area * target_area_sign >= 0) ? t : [t[0], t[2], t[1]]
            )
            [for (idx = oriented) idx + offset]
    ];

// Function: _ps_fr_side_faces()
// Usage:
//   result = _ps_fr_side_faces(n, loop_area_sign);
// Description:
//   Build side quad faces joining bottom and top loops.
//   .
//   - Returns: list of quad index faces
// Arguments:
//   n = loop arity
//   loop_area_sign = bottom-loop signed area sign
function _ps_fr_side_faces(n, loop_area_sign) =
    [
        for (i = [0:1:n-1])
            let(j = (i + 1) % n)
            (loop_area_sign >= 0)
                ? [i, n + i, n + j, j]
                : [i, j, n + j, n + i]
    ];

function _ps_fr_cross2(a, b) =
    a[0] * b[1] - a[1] * b[0];

function _ps_fr_segment_proper_intersects(a, b, c, d, eps=1e-9) =
    let(
        r = b - a,
        s = d - c,
        den = _ps_fr_cross2(r, s),
        q = c - a,
        ta = (abs(den) <= eps) ? undef : _ps_fr_cross2(q, s) / den,
        tb = (abs(den) <= eps) ? undef : _ps_fr_cross2(q, r) / den
    )
    !is_undef(ta) && !is_undef(tb) && ta > eps && ta < 1 - eps && tb > eps && tb < 1 - eps;

function _ps_fr_nonadjacent_edges(n, i, j) =
    abs(i - j) > 1 && !(i == 0 && j == n - 1);

function _ps_fr_loop_self_hits(loop2d, eps=1e-8) =
    let(n = len(loop2d))
    [
        for (i = [0:1:n-1])
            for (j = [i+1:1:n-1])
                if (_ps_fr_nonadjacent_edges(n, i, j)
                        && _ps_fr_segment_proper_intersects(loop2d[i], loop2d[(i + 1) % n], loop2d[j], loop2d[(j + 1) % n], eps))
                    [i, j]
    ];

function _ps_fr_loop_without_adjacent_duplicates(loop2d, eps=1e-8) =
    [
        for (i = [0:1:len(loop2d)-1])
            if (norm(loop2d[(i + 1) % len(loop2d)] - loop2d[i]) > eps)
                loop2d[i]
    ];

function _ps_fr_loop_edges_match_reference(loop2d, ref_loop2d, eps=1e-8) =
    len(loop2d) == len(ref_loop2d)
        && len([
            for (i = [0:1:len(loop2d)-1])
                let(
                    edge = loop2d[(i + 1) % len(loop2d)] - loop2d[i],
                    ref_edge = ref_loop2d[(i + 1) % len(ref_loop2d)] - ref_loop2d[i]
                )
                if (norm(edge) <= eps || norm(ref_edge) <= eps || v_dot(edge, ref_edge) <= eps)
                    i
        ]) == 0;

function _ps_fr_projected_lines_for_z(face_pts3d_local, poly_faces_idx, poly_verts_local, face_idx, edges, edge_faces, loop_sites, z, input_sign, cell_winding_signs, max_project=undef, boundary_inset=0, boundary_inset_mode="side", eps=1e-8) =
    _ps_fr_projected_lines_with_vertex_clips(face_pts3d_local, poly_faces_idx, poly_verts_local, face_idx, edges, edge_faces, loop_sites, z, input_sign, cell_winding_signs, max_project, boundary_inset, boundary_inset_mode, eps);

function _ps_fr_projected_loop_for_z(face_pts3d_local, poly_faces_idx, poly_verts_local, face_idx, edges, edge_faces, loop_sites, z, input_sign, cell_winding_signs, max_project=undef, boundary_inset=0, boundary_inset_mode="side", eps=1e-8) =
    _ps_fr_projected_loop(
        _ps_fr_projected_lines_for_z(face_pts3d_local, poly_faces_idx, poly_verts_local, face_idx, edges, edge_faces, loop_sites, z, input_sign, cell_winding_signs, max_project, boundary_inset, boundary_inset_mode, eps),
        eps
    );

function _ps_fr_loop_valid_against_ref(loop2d, ref_loop2d, ref_area_sign, eps=1e-8) =
    let(loop = _ps_fr_loop_without_adjacent_duplicates(loop2d, eps))
    len(loop) >= 3
        && _ps_fr_loop_edges_match_reference(loop, ref_loop2d, eps)
        && len(_ps_fr_loop_self_hits(loop, eps)) == 0
        && _ps_seg_poly_area2(loop) * ref_area_sign > eps;

function _ps_fr_projected_loop_valid_for_z(face_pts3d_local, poly_faces_idx, poly_verts_local, face_idx, edges, edge_faces, loop_sites, z, input_sign, cell_winding_signs, ref_loop2d, ref_area_sign, max_project=undef, boundary_inset=0, boundary_inset_mode="side", eps=1e-8) =
    _ps_fr_loop_valid_against_ref(
        _ps_fr_projected_loop_for_z(face_pts3d_local, poly_faces_idx, poly_verts_local, face_idx, edges, edge_faces, loop_sites, z, input_sign, cell_winding_signs, max_project, boundary_inset, boundary_inset_mode, eps),
        ref_loop2d,
        ref_area_sign,
        eps
    );

function _ps_fr_clipped_z_search(face_pts3d_local, poly_faces_idx, poly_verts_local, face_idx, edges, edge_faces, loop_sites, z_good, z_bad, input_sign, cell_winding_signs, ref_loop2d, ref_area_sign, max_project=undef, boundary_inset=0, boundary_inset_mode="side", eps=1e-8, iter=36) =
    (iter <= 0 || abs(z_bad - z_good) <= eps)
        ? z_good
        : let(
            z_mid = (z_good + z_bad) / 2,
            ok = _ps_fr_projected_loop_valid_for_z(face_pts3d_local, poly_faces_idx, poly_verts_local, face_idx, edges, edge_faces, loop_sites, z_mid, input_sign, cell_winding_signs, ref_loop2d, ref_area_sign, max_project, boundary_inset, boundary_inset_mode, eps)
        )
        ok
            ? _ps_fr_clipped_z_search(face_pts3d_local, poly_faces_idx, poly_verts_local, face_idx, edges, edge_faces, loop_sites, z_mid, z_bad, input_sign, cell_winding_signs, ref_loop2d, ref_area_sign, max_project, boundary_inset, boundary_inset_mode, eps, iter - 1)
            : _ps_fr_clipped_z_search(face_pts3d_local, poly_faces_idx, poly_verts_local, face_idx, edges, edge_faces, loop_sites, z_good, z_mid, input_sign, cell_winding_signs, ref_loop2d, ref_area_sign, max_project, boundary_inset, boundary_inset_mode, eps, iter - 1);

function _ps_fr_clipped_z_for_bound(face_pts3d_local, poly_faces_idx, poly_verts_local, face_idx, edges, edge_faces, loop_sites, z, input_sign, cell_winding_signs, ref_loop2d, ref_area_sign, max_project=undef, boundary_inset=0, boundary_inset_mode="side", eps=1e-8) =
    _ps_fr_projected_loop_valid_for_z(face_pts3d_local, poly_faces_idx, poly_verts_local, face_idx, edges, edge_faces, loop_sites, z, input_sign, cell_winding_signs, ref_loop2d, ref_area_sign, max_project, boundary_inset, boundary_inset_mode, eps)
        ? z
        : _ps_fr_clipped_z_search(face_pts3d_local, poly_faces_idx, poly_verts_local, face_idx, edges, edge_faces, loop_sites, 0, z, input_sign, cell_winding_signs, ref_loop2d, ref_area_sign, max_project, boundary_inset, boundary_inset_mode, eps);

// Function: _ps_fr_loop_shell()
// Usage:
//   result = _ps_fr_loop_shell(face_pts3d_local, loop_sites, loop_idx, z0, z1, input_sign, cell_winding_signs, max_project, boundary_inset, boundary_inset_mode, eps);
// Description:
//   Build one face-region loop shell record for one boundary loop.
//   .
//   - Returns: `ps_loop_shell` record
// Arguments:
//   face_pts3d_local = source face loop
//   loop_sites = sites for one boundary loop
//   loop_idx = loop id
//   z0 = target Z planes
//   z1 = target Z planes
//   input_sign = source loop winding sign
//   cell_winding_signs = per-cell winding signs
//   max_project = optional cap
//   boundary_inset = positive shift toward filled side
//   boundary_inset_mode = `"side"` or `"face"`
//   eps = tolerance
function _ps_fr_loop_shell(face_pts3d_local, poly_faces_idx, poly_verts_local, face_idx, edges, edge_faces, loop_sites, loop_idx, z0, z1, input_sign, cell_winding_signs, max_project=undef, boundary_inset=0, boundary_inset_mode="side", eps=1e-8) =
    let(
        ref_loop = _ps_fr_loop_without_adjacent_duplicates(
            _ps_fr_projected_loop_for_z(face_pts3d_local, poly_faces_idx, poly_verts_local, face_idx, edges, edge_faces, loop_sites, 0, input_sign, cell_winding_signs, max_project, boundary_inset, boundary_inset_mode, eps),
            eps
        ),
        ref_area = _ps_seg_poly_area2(ref_loop),
        _ref = assert(abs(ref_area) > eps, "ps_face_region_loop_shells: projected loop at z=0 is degenerate"),
        ref_area_sign = ref_area >= 0 ? 1 : -1,
        z0c = _ps_fr_clipped_z_for_bound(face_pts3d_local, poly_faces_idx, poly_verts_local, face_idx, edges, edge_faces, loop_sites, z0, input_sign, cell_winding_signs, ref_loop, ref_area_sign, max_project, boundary_inset, boundary_inset_mode, eps),
        z1c = _ps_fr_clipped_z_for_bound(face_pts3d_local, poly_faces_idx, poly_verts_local, face_idx, edges, edge_faces, loop_sites, z1, input_sign, cell_winding_signs, ref_loop, ref_area_sign, max_project, boundary_inset, boundary_inset_mode, eps),
        lines0 = _ps_fr_projected_lines_for_z(face_pts3d_local, poly_faces_idx, poly_verts_local, face_idx, edges, edge_faces, loop_sites, z0c, input_sign, cell_winding_signs, max_project, boundary_inset, boundary_inset_mode, eps),
        lines1 = _ps_fr_projected_lines_for_z(face_pts3d_local, poly_faces_idx, poly_verts_local, face_idx, edges, edge_faces, loop_sites, z1c, input_sign, cell_winding_signs, max_project, boundary_inset, boundary_inset_mode, eps),
        exposure_sign = _ps_fr_loop_exposure_sign(loop_sites, input_sign, cell_winding_signs),
        lineage = [for (site = loop_sites) ps_boundary_span_site_idx(site)]
    )
    ps_loop_shell_from_projected_lines(lines0, lines1, z0c, z1c, "face_region", loop_idx, lineage, exposure_sign, eps);

// Function: _ps_face_region_loop_shells_from_context()
// Usage:
//   result = _ps_face_region_loop_shells_from_context(face_ctx, z0, z1, mode, max_project, eps, boundary_inset, boundary_inset_mode);
// Description:
//   Build positive face-region loop shells from a face-local context.
//   .
//   - Returns: list of `ps_loop_shell` records
//   .
//   - Limitations/Gotchas: emits one shell per filled boundary loop; holes/proxy punch-through volumes are intentionally outside this first primitive
// Arguments:
//   face_ctx = face-local context
//   z0 = target local Z planes
//   z1 = target local Z planes
//   mode = `"nonzero"`, `"evenodd"`, or `"all"`
//   max_project = optional projection-distance cap
//   eps = geometric tolerance
//   boundary_inset = positive shift toward filled side
//   boundary_inset_mode = `"side"` or `"face"`
function _ps_face_region_loop_shells_from_context(
    face_ctx,
    z0,
    z1,
    mode="nonzero",
    max_project=undef,
    eps=1e-8,
    boundary_inset=0,
    boundary_inset_mode="side"
) =
    let(
        face_pts3d_local = ps_face_local_context_pts3d_local(face_ctx),
        face_idx = ps_face_local_context_idx(face_ctx),
        poly_faces_idx = ps_face_local_context_poly_faces_idx(face_ctx),
        poly_verts_local = ps_face_local_context_poly_verts_local(face_ctx),
        face_neighbors_idx = ps_face_local_context_neighbors_idx(face_ctx),
        face_dihedrals = ps_face_local_context_dihedrals(face_ctx)
    )
    _ps_face_region_loop_shells_from_fields(
        face_pts3d_local,
        face_idx,
        poly_faces_idx,
        poly_verts_local,
        face_neighbors_idx,
        face_dihedrals,
        z0,
        z1,
        mode,
        max_project,
        eps,
        boundary_inset,
        boundary_inset_mode
    );

// Function: _ps_face_region_loop_shells_from_fields()
// Usage:
//   result = _ps_face_region_loop_shells_from_fields(face_pts3d_local, face_idx, poly_faces_idx, poly_verts_local, face_neighbors_idx, face_dihedrals, z0, z1, mode, max_project, eps, boundary_inset, boundary_inset_mode);
// Description:
//   Build positive face-region loop shells for one face.
//   .
//   - Returns: list of `ps_loop_shell` records
//   .
//   - Limitations/Gotchas: emits one shell per filled boundary loop; holes/proxy punch-through volumes are intentionally outside this first primitive
// Arguments:
//   face_pts3d_local = current face loop in face-local 3D
//   face_idx = current face index
//   poly_faces_idx = full poly in current face-local coordinates
//   poly_verts_local = full poly in current face-local coordinates
//   face_neighbors_idx = current face-edge metadata
//   face_dihedrals = current face-edge metadata
//   z0 = target local Z planes
//   z1 = target local Z planes
//   mode = `"nonzero"`, `"evenodd"`, or `"all"`
//   max_project = optional projection-distance cap
//   eps = geometric tolerance
//   boundary_inset = positive shift toward filled side
//   boundary_inset_mode = `"side"` or `"face"`
function _ps_face_region_loop_shells_from_fields(
    face_pts3d_local,
    face_idx,
    poly_faces_idx,
    poly_verts_local,
    face_neighbors_idx,
    face_dihedrals,
    z0,
    z1,
    mode="nonzero",
    max_project=undef,
    eps=1e-8,
    boundary_inset=0,
    boundary_inset_mode="side"
) =
    let(
        _z0 = assert(!is_undef(z0), "ps_face_region_loop_shells: z0 must be defined"),
        _z1 = assert(!is_undef(z1), "ps_face_region_loop_shells: z1 must be defined"),
        _inset = assert(boundary_inset >= 0, "ps_face_region_loop_shells: boundary_inset must be >= 0"),
        arr = ps_face_arrangement(face_pts3d_local, eps),
        input_sign = _ps_seg_fill_target_sign(arr, mode, eps),
        cell_winding_signs = _ps_fr_cell_winding_signs(face_pts3d_local, arr[4], eps),
        sites = _ps_face_boundary_span_sites(
            face_pts3d_local,
            face_idx,
            poly_faces_idx,
            poly_verts_local,
            face_neighbors_idx,
            face_dihedrals,
            mode,
            eps
        ),
        edges = _ps_edges_from_faces(poly_faces_idx),
        edge_faces = ps_edge_faces_table(poly_faces_idx, edges),
        loop_ids = _ps_fr_unique_loop_ids(sites)
    )
    [
        for (loop_idx = loop_ids)
            let(
                loop_sites = _ps_fr_sites_for_loop(sites, loop_idx),
                shell = _ps_fr_loop_shell(face_pts3d_local, poly_faces_idx, poly_verts_local, face_idx, edges, edge_faces, loop_sites, loop_idx, z0, z1, input_sign, cell_winding_signs, max_project, boundary_inset, boundary_inset_mode, eps)
            )
            if (len(ps_loop_shell_points(shell)) >= 6 && len(ps_loop_shell_faces(shell)) >= 4)
                shell
    ];

// Function: ps_face_region_loop_shells()
// Usage:
//   result = ps_face_region_loop_shells(face_ctx, z0, z1, mode, max_project, eps, boundary_inset, boundary_inset_mode);
// Description:
//   Build positive face-region loop shells from a face-local context.
//   .
//   - Returns: list of `ps_loop_shell` records
//   .
//   - Limitations/Gotchas: context-first public entry point
// Arguments:
//   face_ctx = face-local context
//   z0 = target local Z planes
//   z1 = target local Z planes
//   mode = `"nonzero"`, `"evenodd"`, or `"all"`
//   max_project = optional projection-distance cap
//   eps = geometric tolerance
//   boundary_inset = positive shift toward filled side
//   boundary_inset_mode = `"side"` or `"face"`
function ps_face_region_loop_shells(
    face_ctx,
    z0,
    z1,
    mode="nonzero",
    max_project=undef,
    eps=1e-8,
    boundary_inset=0,
    boundary_inset_mode="side"
    ) =
    _ps_face_region_loop_shells_from_context(
        face_ctx,
        z0,
        z1,
        mode,
        max_project,
        eps,
        boundary_inset,
        boundary_inset_mode
    );

// Module: ps_face_region_loop_volume()
// Usage:
//   ps_face_region_loop_volume(z0, z1, mode, max_project, eps, convexity, boundary_inset, boundary_inset_mode);
// Description:
//   Emit the current face's positive face-region loop volume.
//   .
//   - Returns: none; intended for use inside `place_on_faces(...)`, usually inside `intersection()`
//   .
//   - Limitations/Gotchas: this is only the boundary-span volume primitive; it does not yet subtract or union proxy punch-through voids
// Arguments:
//   z0 = target local Z planes
//   z1 = target local Z planes
//   mode = `"nonzero"`, `"evenodd"`, or `"all"`
//   max_project = optional projection-distance cap
//   eps = geometric tolerance
//   convexity = OpenSCAD polyhedron convexity hint
//   boundary_inset = positive shift toward filled side
//   boundary_inset_mode = `"side"` or `"face"`
module ps_face_region_loop_volume(z0, z1, mode="nonzero", max_project=undef, eps=1e-8, convexity=6, boundary_inset=0, boundary_inset_mode="side") {
    assert(!is_undef($ps_face_pts3d_local), "ps_face_region_loop_volume: requires place_on_faces context ($ps_face_pts3d_local)");
    assert(!is_undef($ps_face_idx), "ps_face_region_loop_volume: requires place_on_faces context ($ps_face_idx)");
    assert(!is_undef($ps_face_local_context), "ps_face_region_loop_volume: requires place_on_faces context ($ps_face_local_context)");

    face_ctx = $ps_face_local_context;
    shells = ps_face_region_loop_shells(
        face_ctx,
        z0,
        z1,
        mode,
        max_project,
        eps,
        boundary_inset,
        boundary_inset_mode
    );

    union() {
        for (shell = shells) {
            if (ps_loop_shell_capped_count(shell) > 0)
                echo(str(
                    "ps_face_region_loop_volume: capped ",
                    ps_loop_shell_capped_count(shell),
                    " projection(s) on face ",
                    $ps_face_idx,
                    " loop ",
                    ps_loop_shell_source_idx(shell)
                ));

            ps_loop_shell(shell, convexity);
        }
    }
}
