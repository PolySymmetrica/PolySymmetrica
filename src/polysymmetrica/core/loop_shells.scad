/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

// ---------------------------------------------------------------------------
// PolySymmetrica - Generic projected loop shell helpers
// Builds closed polyhedron records from corresponding bottom/top 2D loops.

use <funcs.scad>

function _ps_ls_cross2(a, b) = a[0] * b[1] - a[1] * b[0];

function _ps_ls_orient2(a, b, c) =
    (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0]);

function _ps_ls_poly_area2(pts2d) =
    let(n = len(pts2d))
    (n < 3) ? 0 :
    ps_sum([for (i = [0:1:n-1]) let(j = (i + 1) % n) pts2d[i][0] * pts2d[j][1] - pts2d[j][0] * pts2d[i][1]]) / 2;

function _ps_ls_nonadj(n, i, j) =
    abs(i - j) > 1 && !(i == 0 && j == n - 1);

function _ps_ls_segment_proper_intersects(a, b, c, d, eps=1e-9) =
    let(
        r = b - a,
        s = d - c,
        den = _ps_ls_cross2(r, s),
        q = c - a,
        ta = (abs(den) <= eps) ? undef : _ps_ls_cross2(q, s) / den,
        tb = (abs(den) <= eps) ? undef : _ps_ls_cross2(q, r) / den
    )
    !is_undef(ta) && !is_undef(tb) && ta > eps && ta < 1 - eps && tb > eps && tb < 1 - eps;

function _ps_ls_loop_self_hits(loop2d, eps=1e-8) =
    let(n = len(loop2d))
    [
        for (i = [0:1:n-1])
            for (j = [i+1:1:n-1])
                if (_ps_ls_nonadj(n, i, j)
                        && _ps_ls_segment_proper_intersects(loop2d[i], loop2d[(i + 1) % n], loop2d[j], loop2d[(j + 1) % n], eps))
                    [i, j]
    ];

function _ps_ls_point_in_tri(p, a, b, c, sign, eps=1e-9) =
    let(
        o0 = sign * _ps_ls_orient2(a, b, p),
        o1 = sign * _ps_ls_orient2(b, c, p),
        o2 = sign * _ps_ls_orient2(c, a, p)
    )
    o0 >= -eps && o1 >= -eps && o2 >= -eps;

function _ps_ls_any_point_in_tri(pts, idxs, ia, ib, ic, sign, eps=1e-9) =
    len([
        for (idx = idxs)
            if (idx != ia && idx != ib && idx != ic
                    && _ps_ls_point_in_tri(pts[idx], pts[ia], pts[ib], pts[ic], sign, eps))
                1
    ]) > 0;

function _ps_ls_ear_index(pts, idxs, sign, eps=1e-9, k=0) =
    (k >= len(idxs)) ? undef :
    let(
        n = len(idxs),
        ia = idxs[(k - 1 + n) % n],
        ib = idxs[k],
        ic = idxs[(k + 1) % n],
        convex = (sign * _ps_ls_orient2(pts[ia], pts[ib], pts[ic])) > eps,
        contains = convex ? _ps_ls_any_point_in_tri(pts, idxs, ia, ib, ic, sign, eps) : true
    )
    (convex && !contains) ? k : _ps_ls_ear_index(pts, idxs, sign, eps, k + 1);

function _ps_ls_remove_at(list, idx) =
    [for (i = [0:1:len(list)-1]) if (i != idx) list[i]];

function _ps_ls_triangulate_idx(pts2d, eps=1e-9, idxs=undef, acc=[]) =
    let(
        ids = is_undef(idxs) ? [for (i = [0:1:len(pts2d)-1]) i] : idxs,
        area = _ps_ls_poly_area2(pts2d),
        sign = area >= 0 ? 1 : -1
    )
    (len(ids) < 3) ? acc :
    (len(ids) == 3) ? concat(acc, [ids]) :
    let(
        ear = _ps_ls_ear_index(pts2d, ids, sign, eps),
        n = len(ids),
        tri = is_undef(ear) ? [ids[0], ids[1], ids[2]] : [ids[(ear - 1 + n) % n], ids[ear], ids[(ear + 1) % n]],
        ids2 = is_undef(ear) ? _ps_ls_remove_at(ids, 1) : _ps_ls_remove_at(ids, ear)
    )
    _ps_ls_triangulate_idx(pts2d, eps, ids2, concat(acc, [tri]));

function _ps_ls_line_normal(line) =
    [-line[1][1], line[1][0]];

function _ps_ls_line_intersection(line0, line1, eps=1e-9) =
    let(
        n0 = _ps_ls_line_normal(line0),
        n1 = _ps_ls_line_normal(line1),
        d0 = v_dot(n0, line0[0]),
        d1 = v_dot(n1, line1[0]),
        det = n0[0] * n1[1] - n0[1] * n1[0]
    )
    (abs(det) <= eps) ? undef :
    [
        (d0 * n1[1] - n0[1] * d1) / det,
        (n0[0] * d1 - d0 * n1[0]) / det
    ];

/**
 * Function: Convert a circular list of projected boundary lines into loop vertices.
 * Params: lines (`[[point2d, dir2d, ...], ...]`), eps (parallel tolerance)
 * Returns: 2D loop from intersections of adjacent lines
 */
function ps_loop_shell_projected_loop(lines, eps=1e-8) =
    let(n = len(lines))
    (n < 3) ? [] :
    [
        for (i = [0:1:n-1])
            let(hit = _ps_ls_line_intersection(lines[(i - 1 + n) % n], lines[i], eps))
            is_undef(hit) ? lines[i][0] : hit
    ];

function _ps_ls_cap_faces(loop2d, offset, target_area_sign, eps=1e-8) =
    [
        for (t = _ps_ls_triangulate_idx(loop2d, eps))
            let(
                area = _ps_ls_orient2(loop2d[t[0]], loop2d[t[1]], loop2d[t[2]]),
                oriented = (area * target_area_sign >= 0) ? t : [t[0], t[2], t[1]]
            )
            [for (idx = oriented) idx + offset]
    ];

function _ps_ls_side_faces(n, loop_area_sign) =
    [
        for (i = [0:1:n-1])
            let(j = (i + 1) % n)
            (loop_area_sign >= 0)
                ? [i, n + i, n + j, j]
                : [i, j, n + j, n + i]
    ];

/**
 * Function: Build a generic projected loop shell record from cap loops.
 * Params: bottom_loop2d/top_loop2d (corresponding simple 2D loops), z0/z1 (cap Z planes), source_kind/source_idx/lineage (caller-owned metadata), capped_count/exposure_sign (optional metadata), eps (tolerance)
 * Returns: `ps_loop_shell` record
 */
function ps_loop_shell_from_loops(
    bottom_loop2d,
    top_loop2d,
    z0,
    z1,
    source_kind="loop",
    source_idx=undef,
    lineage=[],
    capped_count=0,
    exposure_sign=undef,
    eps=1e-8
) =
    let(
        n = min(len(bottom_loop2d), len(top_loop2d)),
        _arity = assert(n >= 3, "ps_loop_shell_from_loops: loops need at least three vertices"),
        bottom = [for (i = [0:1:n-1]) bottom_loop2d[i]],
        top = [for (i = [0:1:n-1]) top_loop2d[i]],
        _same = assert(len(bottom_loop2d) == len(top_loop2d), "ps_loop_shell_from_loops: bottom/top loop arity mismatch"),
        _bottom_simple = assert(len(_ps_ls_loop_self_hits(bottom, eps)) == 0, "ps_loop_shell_from_loops: bottom cap loop self-intersects"),
        _top_simple = assert(len(_ps_ls_loop_self_hits(top, eps)) == 0, "ps_loop_shell_from_loops: top cap loop self-intersects"),
        points = concat(
            [for (p = bottom) [p[0], p[1], z0]],
            [for (p = top) [p[0], p[1], z1]]
        ),
        area = _ps_ls_poly_area2(bottom),
        area_sign = area >= 0 ? 1 : -1,
        faces = concat(
            _ps_ls_cap_faces(bottom, 0, 1, eps),
            _ps_ls_cap_faces(top, n, -1, eps),
            _ps_ls_side_faces(n, area_sign)
        )
    )
    [
        "loop_shell",
        points,
        faces,
        bottom,
        top,
        z0,
        z1,
        source_kind,
        source_idx,
        lineage,
        capped_count,
        exposure_sign
    ];

/**
 * Function: Build a generic projected loop shell record from projected line loops.
 * Params: bottom_lines/top_lines (`[[point2d, dir2d, was_capped, ...], ...]`), z0/z1, source_kind/source_idx/lineage, exposure_sign, eps
 * Returns: `ps_loop_shell` record
 */
function ps_loop_shell_from_projected_lines(
    bottom_lines,
    top_lines,
    z0,
    z1,
    source_kind="loop",
    source_idx=undef,
    lineage=[],
    exposure_sign=undef,
    eps=1e-8
) =
    let(
        bottom = ps_loop_shell_projected_loop(bottom_lines, eps),
        top = ps_loop_shell_projected_loop(top_lines, eps),
        capped_count = len([
            for (line = concat(bottom_lines, top_lines))
                if (len(line) > 2 && line[2]) 1
        ])
    )
    ps_loop_shell_from_loops(bottom, top, z0, z1, source_kind, source_idx, lineage, capped_count, exposure_sign, eps);

/**
 * Function: Get loop-shell polyhedron points.
 * Params: shell (`ps_loop_shell` record)
 * Returns: point list
 */
function ps_loop_shell_points(shell) = shell[1];

/**
 * Function: Get loop-shell polyhedron faces.
 * Params: shell (`ps_loop_shell` record)
 * Returns: face index list
 */
function ps_loop_shell_faces(shell) = shell[2];

/**
 * Function: Get bottom cap loop in local XY.
 * Params: shell (`ps_loop_shell` record)
 * Returns: 2D loop at `z0`
 */
function ps_loop_shell_bottom_loop2d(shell) = shell[3];

/**
 * Function: Get top cap loop in local XY.
 * Params: shell (`ps_loop_shell` record)
 * Returns: 2D loop at `z1`
 */
function ps_loop_shell_top_loop2d(shell) = shell[4];

/**
 * Function: Get bottom Z.
 * Params: shell (`ps_loop_shell` record)
 * Returns: `z0`
 */
function ps_loop_shell_z0(shell) = shell[5];

/**
 * Function: Get top Z.
 * Params: shell (`ps_loop_shell` record)
 * Returns: `z1`
 */
function ps_loop_shell_z1(shell) = shell[6];

/**
 * Function: Get caller-owned source kind.
 * Params: shell (`ps_loop_shell` record)
 * Returns: source kind string
 */
function ps_loop_shell_source_kind(shell) = shell[7];

/**
 * Function: Get caller-owned source index.
 * Params: shell (`ps_loop_shell` record)
 * Returns: source index
 */
function ps_loop_shell_source_idx(shell) = shell[8];

/**
 * Function: Get caller-owned lineage metadata.
 * Params: shell (`ps_loop_shell` record)
 * Returns: lineage value
 */
function ps_loop_shell_lineage(shell) = shell[9];

/**
 * Function: Get capped projection count.
 * Params: shell (`ps_loop_shell` record)
 * Returns: capped projection count
 */
function ps_loop_shell_capped_count(shell) = shell[10];

/**
 * Function: Get optional exposure sign.
 * Params: shell (`ps_loop_shell` record)
 * Returns: exposure sign, or `undef`
 */
function ps_loop_shell_exposure_sign(shell) = shell[11];

/**
 * Function: Build a description string for a loop shell record.
 * Params: shell (loop shell record), detail (detail level), kvpair_to_str (optional key/value formatter), field_sep (field separator)
 * Returns: description string
 */
function ps_loop_shell_describe_str(shell, detail=0, kvpair_to_str=undef, field_sep=", ") =
    ps_describe_record_str(
        "LoopShell",
        [
            ps_describe_kvpair_str("source_kind", ps_loop_shell_source_kind(shell), kvpair_to_str),
            ps_describe_kvpair_str("source_idx", ps_loop_shell_source_idx(shell), kvpair_to_str),
            ps_describe_kvpair_str("point_count", len(ps_loop_shell_points(shell)), kvpair_to_str),
            ps_describe_kvpair_str("face_count", len(ps_loop_shell_faces(shell)), kvpair_to_str)
        ],
        detail,
        [
            ps_describe_kvpair_str("bottom_loop2d", ps_loop_shell_bottom_loop2d(shell), kvpair_to_str),
            ps_describe_kvpair_str("top_loop2d", ps_loop_shell_top_loop2d(shell), kvpair_to_str),
            ps_describe_kvpair_str("z0", ps_loop_shell_z0(shell), kvpair_to_str),
            ps_describe_kvpair_str("z1", ps_loop_shell_z1(shell), kvpair_to_str),
            ps_describe_kvpair_str("lineage", ps_loop_shell_lineage(shell), kvpair_to_str),
            ps_describe_kvpair_str("capped_count", ps_loop_shell_capped_count(shell), kvpair_to_str),
            ps_describe_kvpair_str("exposure_sign", ps_loop_shell_exposure_sign(shell), kvpair_to_str)
        ],
        field_sep
    );

/**
 * Module: Echo a loop-shell description.
 * Params: shell (loop shell record), detail (detail level), kvpair_to_str (optional key/value formatter), field_sep (field separator)
 * Returns: none
 */
module ps_loop_shell_describe(shell, detail=0, kvpair_to_str=undef, field_sep=", ") {
    echo(ps_loop_shell_describe_str(shell, detail, kvpair_to_str, field_sep));
}

/**
 * Module: Emit a generic loop-shell polyhedron.
 * Params: shell (`ps_loop_shell` record), convexity (OpenSCAD hint)
 * Returns: none
 */
module ps_loop_shell(shell, convexity=6) {
    assert(shell[0] == "loop_shell", "ps_loop_shell: bad shell kind");
    polyhedron(
        points = ps_loop_shell_points(shell),
        faces = ps_loop_shell_faces(shell),
        convexity = convexity
    );
}
