/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

// ---------------------------------------------------------------------------
// PolySymmetrica - Segment data records
// Shared record accessors for boundary spans, intrusions, seam-clearance loops,
// and seam placement sites.

use <funcs.scad>

function _ps_boundary_span_site(
    idx,
    frame,
    len_d,
    seg2d,
    loop_idx,
    source_edge_idx,
    source_t0,
    source_t1,
    raw_kind,
    filled_cell_idx,
    other_cell_idx,
    adj_face_idx,
    dihedral,
    adj_face_normal_local,
    filled_side,
    adj_face_dir_span_local,
    kind
) =
    [
        idx,
        frame,
        len_d,
        seg2d,
        loop_idx,
        source_edge_idx,
        source_t0,
        source_t1,
        raw_kind,
        filled_cell_idx,
        other_cell_idx,
        adj_face_idx,
        dihedral,
        adj_face_normal_local,
        filled_side,
        adj_face_dir_span_local,
        kind
    ];

/**
 * Function: Return the boundary span site index.
 * Params: site (boundary span site record)
 * Returns: source boundary span site index
 */
function ps_boundary_span_site_idx(site) = site[0];

/**
 * Function: Return the boundary span site center.
 * Params: site (boundary span site record)
 * Returns: span center in current face-local coordinates
 */
function ps_boundary_span_site_center_local(site) =
    ps_placement_frame_center(ps_boundary_span_site_frame(site));

/**
 * Function: Return the boundary span site local X axis.
 * Params: site (boundary span site record)
 * Returns: span-local X axis in current face-local coordinates
 */
function ps_boundary_span_site_ex_local(site) =
    ps_placement_frame_ex(ps_boundary_span_site_frame(site));

/**
 * Function: Return the boundary span site local Y axis.
 * Params: site (boundary span site record)
 * Returns: span-local Y axis in current face-local coordinates
 */
function ps_boundary_span_site_ey_local(site) =
    ps_placement_frame_ey(ps_boundary_span_site_frame(site));

/**
 * Function: Return the boundary span site local Z axis.
 * Params: site (boundary span site record)
 * Returns: span-local Z axis in current face-local coordinates
 */
function ps_boundary_span_site_ez_local(site) =
    ps_placement_frame_ez(ps_boundary_span_site_frame(site));

/**
 * Function: Return the boundary span placement frame.
 * Params: site (boundary span site record)
 * Returns: placement frame `[center, ex, ey, ez]` in current face-local coordinates
 */
function ps_boundary_span_site_frame(site) = site[1];

/**
 * Function: Return the boundary span length.
 * Params: site (boundary span site record)
 * Returns: span length in current face-local units
 */
function ps_boundary_span_site_len(site) = site[2];

/**
 * Function: Return the boundary span 2D segment.
 * Params: site (boundary span site record)
 * Returns: oriented `[[x0,y0],[x1,y1]]` segment in current face-local XY coordinates
 */
function ps_boundary_span_site_segment2d_local(site) = site[3];

/**
 * Function: Return the boundary loop index containing this span.
 * Params: site (boundary span site record)
 * Returns: boundary loop index
 */
function ps_boundary_span_site_loop_idx(site) = site[4];

/**
 * Function: Return the source edge index for this span.
 * Params: site (boundary span site record)
 * Returns: original current-face edge index, or `undef`
 */
function ps_boundary_span_site_source_edge_idx(site) = site[5];

/**
 * Function: Return the oriented source-edge start parameter.
 * Params: site (boundary span site record)
 * Returns: source-edge parameter at the span start
 */
function ps_boundary_span_site_source_t0(site) = site[6];

/**
 * Function: Return the oriented source-edge end parameter.
 * Params: site (boundary span site record)
 * Returns: source-edge parameter at the span end
 */
function ps_boundary_span_site_source_t1(site) = site[7];

/**
 * Function: Return the raw arrangement span kind.
 * Params: site (boundary span site record)
 * Returns: raw lineage kind such as `"source"`
 */
function ps_boundary_span_site_raw_kind(site) = site[8];

/**
 * Function: Return the filled cell index beside this boundary span.
 * Params: site (boundary span site record)
 * Returns: filled cell index, or `undef`
 */
function ps_boundary_span_site_filled_cell_idx(site) = site[9];

/**
 * Function: Return the non-filled/opposite cell index beside this boundary span.
 * Params: site (boundary span site record)
 * Returns: opposite cell index, or `undef`
 */
function ps_boundary_span_site_other_cell_idx(site) = site[10];

/**
 * Function: Return the adjacent source face index.
 * Params: site (boundary span site record)
 * Returns: adjacent face index inherited from the source edge, or `undef`
 */
function ps_boundary_span_site_adj_face_idx(site) = site[11];

/**
 * Function: Return the source-edge dihedral metadata.
 * Params: site (boundary span site record)
 * Returns: dihedral inherited from the source edge, or `undef`
 */
function ps_boundary_span_site_dihedral(site) = site[12];

/**
 * Function: Return the adjacent face normal in current face-local coordinates.
 * Params: site (boundary span site record)
 * Returns: adjacent-face normal, or `undef`
 */
function ps_boundary_span_site_adj_face_normal_local(site) = site[13];

/**
 * Function: Return which side of the oriented span is filled.
 * Params: site (boundary span site record)
 * Returns: `+1` for left, `-1` for right, or `0` for degenerate/ambiguous spans
 */
function ps_boundary_span_site_filled_side(site) = site[14];

/**
 * Function: Return adjacent-face direction in span-local coordinates.
 * Params: site (boundary span site record)
 * Returns: adjacent face plane direction in `[x,y,z]` span-local coordinates, or `undef`
 */
function ps_boundary_span_site_adj_face_dir_span_local(site) = site[15];

/**
 * Function: Return the public boundary span lineage kind.
 * Params: site (boundary span site record)
 * Returns: `"source_edge"`, `"source_partial"`, or `"generated_cut"`
 */
function ps_boundary_span_site_kind(site) = site[16];

/**
 * Function: Test whether a boundary span site is generated/split rather than a full source edge.
 * Params: site (boundary span site record)
 * Returns: true when the public kind is not `"source_edge"`
 */
function ps_boundary_span_site_is_generated(site) =
    ps_boundary_span_site_kind(site) != "source_edge";

/**
 * Function: Build a description string for a boundary span site.
 * Params: site (boundary span site record), detail (detail level), kvpair_to_str (optional key/value formatter), field_sep (field separator)
 * Returns: description string
 */
function ps_boundary_span_site_describe_str(site, detail=0, kvpair_to_str=undef, field_sep=", ") =
    ps_describe_record_str(
        "BoundarySpanSite",
        [
            ps_describe_kvpair_str("idx", ps_boundary_span_site_idx(site), kvpair_to_str),
            ps_describe_kvpair_str("kind", ps_boundary_span_site_kind(site), kvpair_to_str),
            ps_describe_kvpair_str("source_edge_idx", ps_boundary_span_site_source_edge_idx(site), kvpair_to_str),
            ps_describe_kvpair_str("len", ps_boundary_span_site_len(site), kvpair_to_str)
        ],
        detail,
        [
            ps_describe_kvpair_str("frame", ps_placement_frame_describe_str(ps_boundary_span_site_frame(site), max(0, detail - 1), kvpair_to_str, field_sep), kvpair_to_str),
            ps_describe_kvpair_str("segment2d_local", ps_boundary_span_site_segment2d_local(site), kvpair_to_str),
            ps_describe_kvpair_str("loop_idx", ps_boundary_span_site_loop_idx(site), kvpair_to_str),
            ps_describe_kvpair_str("source_t0", ps_boundary_span_site_source_t0(site), kvpair_to_str),
            ps_describe_kvpair_str("source_t1", ps_boundary_span_site_source_t1(site), kvpair_to_str),
            ps_describe_kvpair_str("raw_kind", ps_boundary_span_site_raw_kind(site), kvpair_to_str),
            ps_describe_kvpair_str("filled_cell_idx", ps_boundary_span_site_filled_cell_idx(site), kvpair_to_str),
            ps_describe_kvpair_str("other_cell_idx", ps_boundary_span_site_other_cell_idx(site), kvpair_to_str),
            ps_describe_kvpair_str("adj_face_idx", ps_boundary_span_site_adj_face_idx(site), kvpair_to_str),
            ps_describe_kvpair_str("dihedral", ps_boundary_span_site_dihedral(site), kvpair_to_str),
            ps_describe_kvpair_str("adj_face_normal_local", ps_boundary_span_site_adj_face_normal_local(site), kvpair_to_str),
            ps_describe_kvpair_str("filled_side", ps_boundary_span_site_filled_side(site), kvpair_to_str),
            ps_describe_kvpair_str("adj_face_dir_span_local", ps_boundary_span_site_adj_face_dir_span_local(site), kvpair_to_str)
        ],
        field_sep
    );

/**
 * Module: Echo a boundary span site description.
 * Params: site (boundary span site record), detail (detail level), kvpair_to_str (optional key/value formatter), field_sep (field separator)
 * Returns: none
 */
module ps_boundary_span_site_describe(site, detail=0, kvpair_to_str=undef, field_sep=", ") {
    echo(ps_boundary_span_site_describe_str(site, detail, kvpair_to_str, field_sep));
}

function _ps_intrusion_record(kind, target_face_idx, foreign_kind, foreign_idx, seg2d_local, dihedral, confidence) =
    [kind, target_face_idx, foreign_kind, foreign_idx, seg2d_local, dihedral, confidence];

/**
 * Function: Get the record kind from a foreign intrusion record.
 * Params: record (from `ps_face_foreign_intrusion_records(...)`)
 * Returns: record kind string, currently `"face_plane_cut"`
 */
function ps_intrusion_kind(record) = record[0];

/**
 * Function: Get the target face index from a foreign intrusion record.
 * Params: record (from `ps_face_foreign_intrusion_records(...)`)
 * Returns: target face index
 */
function ps_intrusion_target_face_idx(record) = record[1];

/**
 * Function: Get the foreign element kind from a foreign intrusion record.
 * Params: record (from `ps_face_foreign_intrusion_records(...)`)
 * Returns: foreign element kind string, currently `"face"`
 */
function ps_intrusion_foreign_kind(record) = record[2];

/**
 * Function: Get the foreign element index from a foreign intrusion record.
 * Params: record (from `ps_face_foreign_intrusion_records(...)`)
 * Returns: foreign element index
 */
function ps_intrusion_foreign_idx(record) = record[3];

/**
 * Function: Get the target-local 2D intrusion segment from a foreign intrusion record.
 * Params: record (from `ps_face_foreign_intrusion_records(...)`)
 * Returns: `seg2d` in target face-local coordinates
 */
function ps_intrusion_segment2d_local(record) = record[4];

/**
 * Function: Get the face-plane cut dihedral from a foreign intrusion record.
 * Params: record (from `ps_face_foreign_intrusion_records(...)`)
 * Returns: cut dihedral angle
 */
function ps_intrusion_dihedral(record) = record[5];

/**
 * Function: Get the confidence/classification from a foreign intrusion record.
 * Params: record (from `ps_face_foreign_intrusion_records(...)`)
 * Returns: confidence string, currently `"exact"`
 */
function ps_intrusion_confidence(record) = record[6];

/**
 * Function: Build a description string for a foreign intrusion record.
 * Params: record (foreign intrusion record), detail (detail level), kvpair_to_str (optional key/value formatter), field_sep (field separator)
 * Returns: description string
 */
function ps_intrusion_describe_str(record, detail=0, kvpair_to_str=undef, field_sep=", ") =
    ps_describe_record_str(
        "Intrusion",
        [
            ps_describe_kvpair_str("kind", ps_intrusion_kind(record), kvpair_to_str),
            ps_describe_kvpair_str("target_face_idx", ps_intrusion_target_face_idx(record), kvpair_to_str),
            ps_describe_kvpair_str("foreign_kind", ps_intrusion_foreign_kind(record), kvpair_to_str),
            ps_describe_kvpair_str("foreign_idx", ps_intrusion_foreign_idx(record), kvpair_to_str)
        ],
        detail,
        [
            ps_describe_kvpair_str("segment2d_local", ps_intrusion_segment2d_local(record), kvpair_to_str),
            ps_describe_kvpair_str("dihedral", ps_intrusion_dihedral(record), kvpair_to_str),
            ps_describe_kvpair_str("confidence", ps_intrusion_confidence(record), kvpair_to_str)
        ],
        field_sep
    );

/**
 * Module: Echo a foreign intrusion description.
 * Params: record (foreign intrusion record), detail (detail level), kvpair_to_str (optional key/value formatter), field_sep (field separator)
 * Returns: none
 */
module ps_intrusion_describe(record, detail=0, kvpair_to_str=undef, field_sep=", ") {
    echo(ps_intrusion_describe_str(record, detail, kvpair_to_str, field_sep));
}

function _ps_scl_record(idx, source_cell_idx, cell, cut_entries) =
    [
        "seam_clearance_loop",
        idx,
        cell[0],
        cell[2],
        cell[3],
        source_cell_idx,
        _ps_seg_poly_area2(cell[0]),
        [
            for (ei = [0:1:len(cell[3])-1])
                cell[3][ei] == "cut" ? cut_entries[cell[2][ei]][2] : undef
        ]
    ];

/**
 * Function: Get seam-clearance loop kind.
 * Params: loop (from `ps_face_seam_clearance_loops(...)`)
 * Returns: record kind string
 */
function ps_seam_clearance_loop_kind(loop) = loop[0];

/**
 * Function: Get seam-clearance loop index.
 * Params: loop (from `ps_face_seam_clearance_loops(...)`)
 * Returns: zero-based loop index
 */
function ps_seam_clearance_loop_idx(loop) = loop[1];

/**
 * Function: Get seam-clearance loop points.
 * Params: loop (from `ps_face_seam_clearance_loops(...)`)
 * Returns: ordered 2D loop points in current face-local coordinates
 */
function ps_seam_clearance_loop_pts2d(loop) = loop[2];

/**
 * Function: Get source edge ids for seam-clearance loop edges.
 * Params: loop (from `ps_face_seam_clearance_loops(...)`)
 * Returns: edge/source ids from the split-cell loop
 */
function ps_seam_clearance_loop_edge_ids(loop) = loop[3];

/**
 * Function: Get edge kind labels for seam-clearance loop edges.
 * Params: loop (from `ps_face_seam_clearance_loops(...)`)
 * Returns: edge kind labels such as `"parent"` and `"cut"`
 */
function ps_seam_clearance_loop_edge_kinds(loop) = loop[4];

/**
 * Function: Get source split-cell index for a seam-clearance loop.
 * Params: loop (from `ps_face_seam_clearance_loops(...)`)
 * Returns: source cell index before seam-clearance filtering
 */
function ps_seam_clearance_loop_source_cell_idx(loop) = loop[5];

/**
 * Function: Get signed area for a seam-clearance loop.
 * Params: loop (from `ps_face_seam_clearance_loops(...)`)
 * Returns: signed 2D area
 */
function ps_seam_clearance_loop_area(loop) = loop[6];

/**
 * Function: Get cut dihedral metadata for seam-clearance loop edges.
 * Params: loop (from `ps_face_seam_clearance_loops(...)`)
 * Returns: per-edge dihedral angle for cut-derived edges, otherwise `undef`
 */
function ps_seam_clearance_loop_edge_dihedrals(loop) = loop[7];

function _ps_face_seam_segment_site(
    site_idx,
    seg2d,
    seam_source,
    source_kind,
    foreign_kind,
    foreign_idx,
    foreign_n,
    dihedral,
    confidence,
    record,
    support_kind="none",
    support_reason="unclassified",
    poly_center_local=undef,
    eps=1e-8
) =
    let(
        d2 = seg2d[1] - seg2d[0],
        len_d = norm(d2),
        ex0 = (len_d <= eps) ? [1, 0, 0] : [d2[0] / len_d, d2[1] / len_d, 0],
        center = [(seg2d[0][0] + seg2d[1][0]) / 2, (seg2d[0][1] + seg2d[1][1]) / 2, 0],
        n0 = [0, 0, 1],
        n1 = (is_undef(foreign_n) || norm(foreign_n) <= eps) ? undef : v_norm(foreign_n),
        poly_center = is_undef(poly_center_local) ? [0, 0, 0] : poly_center_local,
        radial_raw = center - poly_center,
        radial_ref = (norm(radial_raw) <= eps) ? _ps_any_perp(ex0) : v_norm(radial_raw),
        bisector_raw = is_undef(n1) ? radial_ref : n0 + n1,
        bisector_signed =
            (norm(bisector_raw) <= eps)
                ? radial_ref
                : ((v_dot(bisector_raw, radial_ref) < 0) ? -bisector_raw : bisector_raw),
        ez_proj = bisector_signed - ex0 * v_dot(bisector_signed, ex0),
        radial_proj = radial_ref - ex0 * v_dot(radial_ref, ex0),
        ez_dir = (norm(ez_proj) <= eps) ? radial_proj : ez_proj,
        ez = (norm(ez_dir) <= eps) ? _ps_any_perp(ex0) : v_norm(ez_dir),
        ey0 = v_norm(v_cross(ez, ex0)),
        ex = (v_dot(n0, ey0) < -eps) ? -ex0 : ex0,
        ey = v_norm(v_cross(ez, ex)),
        frame = ps_placement_frame(center, ex, ey, ez),
        edge_pts_local = [[-len_d / 2, 0, 0], [len_d / 2, 0, 0]],
        current_normal_seam_local = [v_dot(n0, ex), v_dot(n0, ey), v_dot(n0, ez)]
    )
    [site_idx, frame, len_d, edge_pts_local, seg2d, seam_source, source_kind, foreign_kind, foreign_idx, dihedral, confidence, record, n1, support_kind, support_reason, current_normal_seam_local];

/**
 * Function: Get seam site index.
 * Params: site (seam segment site record)
 * Returns: zero-based seam site index
 */
function ps_seam_site_idx(site) = site[0];

/**
 * Function: Get seam center in target face-local coordinates.
 * Params: site (seam segment site record)
 * Returns: seam midpoint in target face-local coordinates
 */
function ps_seam_site_center_local(site) = ps_placement_frame_center(ps_seam_site_frame(site));

/**
 * Function: Get seam-local X axis in target face-local coordinates.
 * Params: site (seam segment site record)
 * Returns: unit X axis along the seam segment
 */
function ps_seam_site_ex_local(site) = ps_placement_frame_ex(ps_seam_site_frame(site));

/**
 * Function: Get seam-local Y axis in target face-local coordinates.
 * Params: site (seam segment site record)
 * Returns: unit Y axis completing the seam frame
 */
function ps_seam_site_ey_local(site) = ps_placement_frame_ey(ps_seam_site_frame(site));

/**
 * Function: Get seam-local Z axis in target face-local coordinates.
 * Params: site (seam segment site record)
 * Returns: unit Z axis following the face-normal bisector/radial fallback
 */
function ps_seam_site_ez_local(site) = ps_placement_frame_ez(ps_seam_site_frame(site));

/**
 * Function: Get seam segment length.
 * Params: site (seam segment site record)
 * Returns: seam length in target face-local units
 */
function ps_seam_site_len(site) = site[2];

/**
 * Function: Get seam endpoints in seam-local coordinates.
 * Params: site (seam segment site record)
 * Returns: edge-like endpoint pair `[[ -len/2, 0, 0 ], [ len/2, 0, 0 ]]`
 */
function ps_seam_site_edge_pts_local(site) = site[3];

/**
 * Function: Get source seam segment in target face-local 2D.
 * Params: site (seam segment site record)
 * Returns: `seg2d` endpoints in target face-local XY
 */
function ps_seam_site_segment2d_local(site) = site[4];

/**
 * Function: Get seam source family.
 * Params: site (seam segment site record)
 * Returns: `"boundary"` or `"foreign"`
 */
function ps_seam_site_source(site) = site[5];

/**
 * Function: Get source kind within the seam source family.
 * Params: site (seam segment site record)
 * Returns: boundary span kind or intrusion kind string
 */
function ps_seam_site_source_kind(site) = site[6];

/**
 * Function: Get foreign source kind for foreign-linked seams.
 * Params: site (seam segment site record)
 * Returns: `"face"` for current exact cuts, or `undef`
 */
function ps_seam_site_foreign_kind(site) = site[7];

/**
 * Function: Get foreign source index for foreign-linked seams.
 * Params: site (seam segment site record)
 * Returns: foreign face index, or `undef`
 */
function ps_seam_site_foreign_idx(site) = site[8];

/**
 * Function: Get seam dihedral metadata.
 * Params: site (seam segment site record)
 * Returns: dihedral angle when known, otherwise `undef`
 */
function ps_seam_site_dihedral(site) = site[9];

/**
 * Function: Get seam confidence metadata.
 * Params: site (seam segment site record)
 * Returns: confidence string such as `"exact"`
 */
function ps_seam_site_confidence(site) = site[10];

/**
 * Function: Get source record used to build the seam site.
 * Params: site (seam segment site record)
 * Returns: boundary span site or intrusion record
 */
function ps_seam_site_record(site) = site[11];

/**
 * Function: Get foreign normal in target face-local coordinates.
 * Params: site (seam segment site record)
 * Returns: unit foreign normal, or `undef`
 */
function ps_seam_site_foreign_normal_local(site) = site[12];

/**
 * Function: Get printable support classification.
 * Params: site (seam segment site record)
 * Returns: support kind string, or `"none"`
 */
function ps_seam_site_support_kind(site) = site[13];

/**
 * Function: Get printable support classification reason.
 * Params: site (seam segment site record)
 * Returns: reason string explaining support classification
 */
function ps_seam_site_support_reason(site) = site[14];

/**
 * Function: Get current face normal in seam-local coordinates.
 * Params: site (seam segment site record)
 * Returns: current target face normal expressed in the seam frame
 */
function ps_seam_site_current_normal_seam_local(site) = site[15];

/**
 * Function: Get placement frame from a seam segment site.
 * Params: site (seam segment site record)
 * Returns: placement frame `[center, ex, ey, ez]` in target face-local coordinates
 */
function ps_seam_site_frame(site) =
    site[1];

/**
 * Function: Test whether a seam site is a printable support candidate.
 * Params: site (seam segment site record)
 * Returns: true when support kind is not `"none"`
 */
function ps_seam_site_is_support_candidate(site) = ps_seam_site_support_kind(site) != "none";

/**
 * Function: Build a description string for a seam segment site.
 * Params: site (seam segment site record), detail (detail level), kvpair_to_str (optional key/value formatter), field_sep (field separator)
 * Returns: description string
 */
function ps_seam_site_describe_str(site, detail=0, kvpair_to_str=undef, field_sep=", ") =
    ps_describe_record_str(
        "SeamSite",
        [
            ps_describe_kvpair_str("idx", ps_seam_site_idx(site), kvpair_to_str),
            ps_describe_kvpair_str("source", ps_seam_site_source(site), kvpair_to_str),
            ps_describe_kvpair_str("source_kind", ps_seam_site_source_kind(site), kvpair_to_str),
            ps_describe_kvpair_str("len", ps_seam_site_len(site), kvpair_to_str)
        ],
        detail,
        [
            ps_describe_kvpair_str("frame", ps_placement_frame_describe_str(ps_seam_site_frame(site), max(0, detail - 1), kvpair_to_str, field_sep), kvpair_to_str),
            ps_describe_kvpair_str("segment2d_local", ps_seam_site_segment2d_local(site), kvpair_to_str),
            ps_describe_kvpair_str("foreign_kind", ps_seam_site_foreign_kind(site), kvpair_to_str),
            ps_describe_kvpair_str("foreign_idx", ps_seam_site_foreign_idx(site), kvpair_to_str),
            ps_describe_kvpair_str("dihedral", ps_seam_site_dihedral(site), kvpair_to_str),
            ps_describe_kvpair_str("confidence", ps_seam_site_confidence(site), kvpair_to_str),
            ps_describe_kvpair_str(
                "record",
                ps_seam_site_source(site) == "boundary"
                    ? ps_boundary_span_site_describe_str(ps_seam_site_record(site), max(0, detail - 1), kvpair_to_str, field_sep)
                    : ps_intrusion_describe_str(ps_seam_site_record(site), max(0, detail - 1), kvpair_to_str, field_sep),
                kvpair_to_str
            ),
            ps_describe_kvpair_str("foreign_normal_local", ps_seam_site_foreign_normal_local(site), kvpair_to_str),
            ps_describe_kvpair_str("support_kind", ps_seam_site_support_kind(site), kvpair_to_str),
            ps_describe_kvpair_str("support_reason", ps_seam_site_support_reason(site), kvpair_to_str),
            ps_describe_kvpair_str("current_normal_seam_local", ps_seam_site_current_normal_seam_local(site), kvpair_to_str)
        ],
        field_sep
    );

/**
 * Module: Echo a seam-site description.
 * Params: site (seam segment site record), detail (detail level), kvpair_to_str (optional key/value formatter), field_sep (field separator)
 * Returns: none
 */
module ps_seam_site_describe(site, detail=0, kvpair_to_str=undef, field_sep=", ") {
    echo(ps_seam_site_describe_str(site, detail, kvpair_to_str, field_sep));
}
