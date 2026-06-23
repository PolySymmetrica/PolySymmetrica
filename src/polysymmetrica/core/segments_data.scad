/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

// LibFile: polysymmetrica/core/segments_data.scad
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

// Function: ps_boundary_span_site_idx()
// Usage:
//   result = ps_boundary_span_site_idx(site);
// Description:
//   Return the boundary span site index.
//   .
//   - Returns: source boundary span site index
// Arguments:
//   site = boundary span site record
function ps_boundary_span_site_idx(site) = site[0];

// Function: ps_boundary_span_site_center_local()
// Usage:
//   result = ps_boundary_span_site_center_local(site);
// Description:
//   Return the boundary span site center.
//   .
//   - Returns: span center in current face-local coordinates
// Arguments:
//   site = boundary span site record
function ps_boundary_span_site_center_local(site) =
    ps_placement_frame_center(ps_boundary_span_site_frame(site));

// Function: ps_boundary_span_site_ex_local()
// Usage:
//   result = ps_boundary_span_site_ex_local(site);
// Description:
//   Return the boundary span site local X axis.
//   .
//   - Returns: span-local X axis in current face-local coordinates
// Arguments:
//   site = boundary span site record
function ps_boundary_span_site_ex_local(site) =
    ps_placement_frame_ex(ps_boundary_span_site_frame(site));

// Function: ps_boundary_span_site_ey_local()
// Usage:
//   result = ps_boundary_span_site_ey_local(site);
// Description:
//   Return the boundary span site local Y axis.
//   .
//   - Returns: span-local Y axis in current face-local coordinates
// Arguments:
//   site = boundary span site record
function ps_boundary_span_site_ey_local(site) =
    ps_placement_frame_ey(ps_boundary_span_site_frame(site));

// Function: ps_boundary_span_site_ez_local()
// Usage:
//   result = ps_boundary_span_site_ez_local(site);
// Description:
//   Return the boundary span site local Z axis.
//   .
//   - Returns: span-local Z axis in current face-local coordinates
// Arguments:
//   site = boundary span site record
function ps_boundary_span_site_ez_local(site) =
    ps_placement_frame_ez(ps_boundary_span_site_frame(site));

// Function: ps_boundary_span_site_frame()
// Usage:
//   result = ps_boundary_span_site_frame(site);
// Description:
//   Return the boundary span placement frame.
//   .
//   - Returns: placement frame `[center, ex, ey, ez]` in current face-local coordinates
// Arguments:
//   site = boundary span site record
function ps_boundary_span_site_frame(site) = site[1];

// Function: ps_boundary_span_site_len()
// Usage:
//   result = ps_boundary_span_site_len(site);
// Description:
//   Return the boundary span length.
//   .
//   - Returns: span length in current face-local units
// Arguments:
//   site = boundary span site record
function ps_boundary_span_site_len(site) = site[2];

// Function: ps_boundary_span_site_segment2d_local()
// Usage:
//   result = ps_boundary_span_site_segment2d_local(site);
// Description:
//   Return the boundary span 2D segment.
//   .
//   - Returns: oriented `[[x0,y0],[x1,y1]]` segment in current face-local XY coordinates
// Arguments:
//   site = boundary span site record
function ps_boundary_span_site_segment2d_local(site) = site[3];

// Function: ps_boundary_span_site_loop_idx()
// Usage:
//   result = ps_boundary_span_site_loop_idx(site);
// Description:
//   Return the boundary loop index containing this span.
//   .
//   - Returns: boundary loop index
// Arguments:
//   site = boundary span site record
function ps_boundary_span_site_loop_idx(site) = site[4];

// Function: ps_boundary_span_site_source_edge_idx()
// Usage:
//   result = ps_boundary_span_site_source_edge_idx(site);
// Description:
//   Return the source edge index for this span.
//   .
//   - Returns: original current-face edge index, or `undef`
// Arguments:
//   site = boundary span site record
function ps_boundary_span_site_source_edge_idx(site) = site[5];

// Function: ps_boundary_span_site_source_t0()
// Usage:
//   result = ps_boundary_span_site_source_t0(site);
// Description:
//   Return the oriented source-edge start parameter.
//   .
//   - Returns: source-edge parameter at the span start
// Arguments:
//   site = boundary span site record
function ps_boundary_span_site_source_t0(site) = site[6];

// Function: ps_boundary_span_site_source_t1()
// Usage:
//   result = ps_boundary_span_site_source_t1(site);
// Description:
//   Return the oriented source-edge end parameter.
//   .
//   - Returns: source-edge parameter at the span end
// Arguments:
//   site = boundary span site record
function ps_boundary_span_site_source_t1(site) = site[7];

// Function: ps_boundary_span_site_raw_kind()
// Usage:
//   result = ps_boundary_span_site_raw_kind(site);
// Description:
//   Return the raw arrangement span kind.
//   .
//   - Returns: raw lineage kind such as `"source"`
// Arguments:
//   site = boundary span site record
function ps_boundary_span_site_raw_kind(site) = site[8];

// Function: ps_boundary_span_site_filled_cell_idx()
// Usage:
//   result = ps_boundary_span_site_filled_cell_idx(site);
// Description:
//   Return the filled cell index beside this boundary span.
//   .
//   - Returns: filled cell index, or `undef`
// Arguments:
//   site = boundary span site record
function ps_boundary_span_site_filled_cell_idx(site) = site[9];

// Function: ps_boundary_span_site_other_cell_idx()
// Usage:
//   result = ps_boundary_span_site_other_cell_idx(site);
// Description:
//   Return the non-filled/opposite cell index beside this boundary span.
//   .
//   - Returns: opposite cell index, or `undef`
// Arguments:
//   site = boundary span site record
function ps_boundary_span_site_other_cell_idx(site) = site[10];

// Function: ps_boundary_span_site_adj_face_idx()
// Usage:
//   result = ps_boundary_span_site_adj_face_idx(site);
// Description:
//   Return the adjacent source face index.
//   .
//   - Returns: adjacent face index inherited from the source edge, or `undef`
// Arguments:
//   site = boundary span site record
function ps_boundary_span_site_adj_face_idx(site) = site[11];

// Function: ps_boundary_span_site_dihedral()
// Usage:
//   result = ps_boundary_span_site_dihedral(site);
// Description:
//   Return the source-edge dihedral metadata.
//   .
//   - Returns: dihedral inherited from the source edge, or `undef`
// Arguments:
//   site = boundary span site record
function ps_boundary_span_site_dihedral(site) = site[12];

// Function: ps_boundary_span_site_adj_face_normal_local()
// Usage:
//   result = ps_boundary_span_site_adj_face_normal_local(site);
// Description:
//   Return the adjacent face normal in current face-local coordinates.
//   .
//   - Returns: adjacent-face normal, or `undef`
// Arguments:
//   site = boundary span site record
function ps_boundary_span_site_adj_face_normal_local(site) = site[13];

// Function: ps_boundary_span_site_filled_side()
// Usage:
//   result = ps_boundary_span_site_filled_side(site);
// Description:
//   Return which side of the oriented span is filled.
//   .
//   - Returns: `+1` for left, `-1` for right, or `0` for degenerate/ambiguous spans
// Arguments:
//   site = boundary span site record
function ps_boundary_span_site_filled_side(site) = site[14];

// Function: ps_boundary_span_site_adj_face_dir_span_local()
// Usage:
//   result = ps_boundary_span_site_adj_face_dir_span_local(site);
// Description:
//   Return adjacent-face direction in span-local coordinates.
//   .
//   - Returns: adjacent face plane direction in `[x,y,z]` span-local coordinates, or `undef`
// Arguments:
//   site = boundary span site record
function ps_boundary_span_site_adj_face_dir_span_local(site) = site[15];

// Function: ps_boundary_span_site_kind()
// Usage:
//   result = ps_boundary_span_site_kind(site);
// Description:
//   Return the public boundary span lineage kind.
//   .
//   - Returns: `"source_edge"`, `"source_partial"`, or `"generated_cut"`
// Arguments:
//   site = boundary span site record
function ps_boundary_span_site_kind(site) = site[16];

// Function: ps_boundary_span_site_is_generated()
// Usage:
//   result = ps_boundary_span_site_is_generated(site);
// Description:
//   Test whether a boundary span site is generated/split rather than a full source edge.
//   .
//   - Returns: true when the public kind is not `"source_edge"`
// Arguments:
//   site = boundary span site record
function ps_boundary_span_site_is_generated(site) =
    ps_boundary_span_site_kind(site) != "source_edge";

// Function: ps_boundary_span_site_describe_str()
// Usage:
//   result = ps_boundary_span_site_describe_str(site, detail, kvpair_to_str, field_sep);
// Description:
//   Build a description string for a boundary span site.
//   .
//   - Returns: description string
// Arguments:
//   site = boundary span site record
//   detail = detail level
//   kvpair_to_str = optional key/value formatter
//   field_sep = field separator
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

// Module: ps_boundary_span_site_describe()
// Usage:
//   ps_boundary_span_site_describe(site, detail, kvpair_to_str, field_sep);
// Description:
//   Echo a boundary span site description.
//   .
//   - Returns: none
// Arguments:
//   site = boundary span site record
//   detail = detail level
//   kvpair_to_str = optional key/value formatter
//   field_sep = field separator
module ps_boundary_span_site_describe(site, detail=0, kvpair_to_str=undef, field_sep=", ") {
    echo(ps_boundary_span_site_describe_str(site, detail, kvpair_to_str, field_sep));
}

function _ps_intrusion_record(kind, target_face_idx, foreign_kind, foreign_idx, seg2d_local, dihedral, confidence) =
    [kind, target_face_idx, foreign_kind, foreign_idx, seg2d_local, dihedral, confidence];

// Function: ps_intrusion_kind()
// Usage:
//   result = ps_intrusion_kind(record);
// Description:
//   Get the record kind from a foreign intrusion record.
//   .
//   - Returns: record kind string, currently `"face_plane_cut"`
// Arguments:
//   record = from `ps_face_foreign_intrusion_records(...)`
function ps_intrusion_kind(record) = record[0];

// Function: ps_intrusion_target_face_idx()
// Usage:
//   result = ps_intrusion_target_face_idx(record);
// Description:
//   Get the target face index from a foreign intrusion record.
//   .
//   - Returns: target face index
// Arguments:
//   record = from `ps_face_foreign_intrusion_records(...)`
function ps_intrusion_target_face_idx(record) = record[1];

// Function: ps_intrusion_foreign_kind()
// Usage:
//   result = ps_intrusion_foreign_kind(record);
// Description:
//   Get the foreign element kind from a foreign intrusion record.
//   .
//   - Returns: foreign element kind string, currently `"face"`
// Arguments:
//   record = from `ps_face_foreign_intrusion_records(...)`
function ps_intrusion_foreign_kind(record) = record[2];

// Function: ps_intrusion_foreign_idx()
// Usage:
//   result = ps_intrusion_foreign_idx(record);
// Description:
//   Get the foreign element index from a foreign intrusion record.
//   .
//   - Returns: foreign element index
// Arguments:
//   record = from `ps_face_foreign_intrusion_records(...)`
function ps_intrusion_foreign_idx(record) = record[3];

// Function: ps_intrusion_segment2d_local()
// Usage:
//   result = ps_intrusion_segment2d_local(record);
// Description:
//   Get the target-local 2D intrusion segment from a foreign intrusion record.
//   .
//   - Returns: `seg2d` in target face-local coordinates
// Arguments:
//   record = from `ps_face_foreign_intrusion_records(...)`
function ps_intrusion_segment2d_local(record) = record[4];

// Function: ps_intrusion_dihedral()
// Usage:
//   result = ps_intrusion_dihedral(record);
// Description:
//   Get the face-plane cut dihedral from a foreign intrusion record.
//   .
//   - Returns: cut dihedral angle
// Arguments:
//   record = from `ps_face_foreign_intrusion_records(...)`
function ps_intrusion_dihedral(record) = record[5];

// Function: ps_intrusion_confidence()
// Usage:
//   result = ps_intrusion_confidence(record);
// Description:
//   Get the confidence/classification from a foreign intrusion record.
//   .
//   - Returns: confidence string, currently `"exact"`
// Arguments:
//   record = from `ps_face_foreign_intrusion_records(...)`
function ps_intrusion_confidence(record) = record[6];

// Function: ps_intrusion_describe_str()
// Usage:
//   result = ps_intrusion_describe_str(record, detail, kvpair_to_str, field_sep);
// Description:
//   Build a description string for a foreign intrusion record.
//   .
//   - Returns: description string
// Arguments:
//   record = foreign intrusion record
//   detail = detail level
//   kvpair_to_str = optional key/value formatter
//   field_sep = field separator
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

// Module: ps_intrusion_describe()
// Usage:
//   ps_intrusion_describe(record, detail, kvpair_to_str, field_sep);
// Description:
//   Echo a foreign intrusion description.
//   .
//   - Returns: none
// Arguments:
//   record = foreign intrusion record
//   detail = detail level
//   kvpair_to_str = optional key/value formatter
//   field_sep = field separator
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

// Function: ps_seam_clearance_loop_kind()
// Usage:
//   result = ps_seam_clearance_loop_kind(loop);
// Description:
//   Get seam-clearance loop kind.
//   .
//   - Returns: record kind string
// Arguments:
//   loop = from `ps_face_seam_clearance_loops(...)`
function ps_seam_clearance_loop_kind(loop) = loop[0];

// Function: ps_seam_clearance_loop_idx()
// Usage:
//   result = ps_seam_clearance_loop_idx(loop);
// Description:
//   Get seam-clearance loop index.
//   .
//   - Returns: zero-based loop index
// Arguments:
//   loop = from `ps_face_seam_clearance_loops(...)`
function ps_seam_clearance_loop_idx(loop) = loop[1];

// Function: ps_seam_clearance_loop_pts2d()
// Usage:
//   result = ps_seam_clearance_loop_pts2d(loop);
// Description:
//   Get seam-clearance loop points.
//   .
//   - Returns: ordered 2D loop points in current face-local coordinates
// Arguments:
//   loop = from `ps_face_seam_clearance_loops(...)`
function ps_seam_clearance_loop_pts2d(loop) = loop[2];

// Function: ps_seam_clearance_loop_edge_ids()
// Usage:
//   result = ps_seam_clearance_loop_edge_ids(loop);
// Description:
//   Get source edge ids for seam-clearance loop edges.
//   .
//   - Returns: edge/source ids from the split-cell loop
// Arguments:
//   loop = from `ps_face_seam_clearance_loops(...)`
function ps_seam_clearance_loop_edge_ids(loop) = loop[3];

// Function: ps_seam_clearance_loop_edge_kinds()
// Usage:
//   result = ps_seam_clearance_loop_edge_kinds(loop);
// Description:
//   Get edge kind labels for seam-clearance loop edges.
//   .
//   - Returns: edge kind labels such as `"parent"` and `"cut"`
// Arguments:
//   loop = from `ps_face_seam_clearance_loops(...)`
function ps_seam_clearance_loop_edge_kinds(loop) = loop[4];

// Function: ps_seam_clearance_loop_source_cell_idx()
// Usage:
//   result = ps_seam_clearance_loop_source_cell_idx(loop);
// Description:
//   Get source split-cell index for a seam-clearance loop.
//   .
//   - Returns: source cell index before seam-clearance filtering
// Arguments:
//   loop = from `ps_face_seam_clearance_loops(...)`
function ps_seam_clearance_loop_source_cell_idx(loop) = loop[5];

// Function: ps_seam_clearance_loop_area()
// Usage:
//   result = ps_seam_clearance_loop_area(loop);
// Description:
//   Get signed area for a seam-clearance loop.
//   .
//   - Returns: signed 2D area
// Arguments:
//   loop = from `ps_face_seam_clearance_loops(...)`
function ps_seam_clearance_loop_area(loop) = loop[6];

// Function: ps_seam_clearance_loop_edge_dihedrals()
// Usage:
//   result = ps_seam_clearance_loop_edge_dihedrals(loop);
// Description:
//   Get cut dihedral metadata for seam-clearance loop edges.
//   .
//   - Returns: per-edge dihedral angle for cut-derived edges, otherwise `undef`
// Arguments:
//   loop = from `ps_face_seam_clearance_loops(...)`
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

// Function: ps_seam_site_idx()
// Usage:
//   result = ps_seam_site_idx(site);
// Description:
//   Get seam site index.
//   .
//   - Returns: zero-based seam site index
// Arguments:
//   site = seam segment site record
function ps_seam_site_idx(site) = site[0];

// Function: ps_seam_site_center_local()
// Usage:
//   result = ps_seam_site_center_local(site);
// Description:
//   Get seam center in target face-local coordinates.
//   .
//   - Returns: seam midpoint in target face-local coordinates
// Arguments:
//   site = seam segment site record
function ps_seam_site_center_local(site) = ps_placement_frame_center(ps_seam_site_frame(site));

// Function: ps_seam_site_ex_local()
// Usage:
//   result = ps_seam_site_ex_local(site);
// Description:
//   Get seam-local X axis in target face-local coordinates.
//   .
//   - Returns: unit X axis along the seam segment
// Arguments:
//   site = seam segment site record
function ps_seam_site_ex_local(site) = ps_placement_frame_ex(ps_seam_site_frame(site));

// Function: ps_seam_site_ey_local()
// Usage:
//   result = ps_seam_site_ey_local(site);
// Description:
//   Get seam-local Y axis in target face-local coordinates.
//   .
//   - Returns: unit Y axis completing the seam frame
// Arguments:
//   site = seam segment site record
function ps_seam_site_ey_local(site) = ps_placement_frame_ey(ps_seam_site_frame(site));

// Function: ps_seam_site_ez_local()
// Usage:
//   result = ps_seam_site_ez_local(site);
// Description:
//   Get seam-local Z axis in target face-local coordinates.
//   .
//   - Returns: unit Z axis following the face-normal bisector/radial fallback
// Arguments:
//   site = seam segment site record
function ps_seam_site_ez_local(site) = ps_placement_frame_ez(ps_seam_site_frame(site));

// Function: ps_seam_site_len()
// Usage:
//   result = ps_seam_site_len(site);
// Description:
//   Get seam segment length.
//   .
//   - Returns: seam length in target face-local units
// Arguments:
//   site = seam segment site record
function ps_seam_site_len(site) = site[2];

// Function: ps_seam_site_edge_pts_local()
// Usage:
//   result = ps_seam_site_edge_pts_local(site);
// Description:
//   Get seam endpoints in seam-local coordinates.
//   .
//   - Returns: edge-like endpoint pair `[[ -len/2, 0, 0 ], [ len/2, 0, 0 ]]`
// Arguments:
//   site = seam segment site record
function ps_seam_site_edge_pts_local(site) = site[3];

// Function: ps_seam_site_segment2d_local()
// Usage:
//   result = ps_seam_site_segment2d_local(site);
// Description:
//   Get source seam segment in target face-local 2D.
//   .
//   - Returns: `seg2d` endpoints in target face-local XY
// Arguments:
//   site = seam segment site record
function ps_seam_site_segment2d_local(site) = site[4];

// Function: ps_seam_site_source()
// Usage:
//   result = ps_seam_site_source(site);
// Description:
//   Get seam source family.
//   .
//   - Returns: `"boundary"` or `"foreign"`
// Arguments:
//   site = seam segment site record
function ps_seam_site_source(site) = site[5];

// Function: ps_seam_site_source_kind()
// Usage:
//   result = ps_seam_site_source_kind(site);
// Description:
//   Get source kind within the seam source family.
//   .
//   - Returns: boundary span kind or intrusion kind string
// Arguments:
//   site = seam segment site record
function ps_seam_site_source_kind(site) = site[6];

// Function: ps_seam_site_foreign_kind()
// Usage:
//   result = ps_seam_site_foreign_kind(site);
// Description:
//   Get foreign source kind for foreign-linked seams.
//   .
//   - Returns: `"face"` for current exact cuts, or `undef`
// Arguments:
//   site = seam segment site record
function ps_seam_site_foreign_kind(site) = site[7];

// Function: ps_seam_site_foreign_idx()
// Usage:
//   result = ps_seam_site_foreign_idx(site);
// Description:
//   Get foreign source index for foreign-linked seams.
//   .
//   - Returns: foreign face index, or `undef`
// Arguments:
//   site = seam segment site record
function ps_seam_site_foreign_idx(site) = site[8];

// Function: ps_seam_site_dihedral()
// Usage:
//   result = ps_seam_site_dihedral(site);
// Description:
//   Get seam dihedral metadata.
//   .
//   - Returns: dihedral angle when known, otherwise `undef`
// Arguments:
//   site = seam segment site record
function ps_seam_site_dihedral(site) = site[9];

// Function: ps_seam_site_confidence()
// Usage:
//   result = ps_seam_site_confidence(site);
// Description:
//   Get seam confidence metadata.
//   .
//   - Returns: confidence string such as `"exact"`
// Arguments:
//   site = seam segment site record
function ps_seam_site_confidence(site) = site[10];

// Function: ps_seam_site_record()
// Usage:
//   result = ps_seam_site_record(site);
// Description:
//   Get source record used to build the seam site.
//   .
//   - Returns: boundary span site or intrusion record
// Arguments:
//   site = seam segment site record
function ps_seam_site_record(site) = site[11];

// Function: ps_seam_site_foreign_normal_local()
// Usage:
//   result = ps_seam_site_foreign_normal_local(site);
// Description:
//   Get foreign normal in target face-local coordinates.
//   .
//   - Returns: unit foreign normal, or `undef`
// Arguments:
//   site = seam segment site record
function ps_seam_site_foreign_normal_local(site) = site[12];

// Function: ps_seam_site_support_kind()
// Usage:
//   result = ps_seam_site_support_kind(site);
// Description:
//   Get printable support classification.
//   .
//   - Returns: support kind string, or `"none"`
// Arguments:
//   site = seam segment site record
function ps_seam_site_support_kind(site) = site[13];

// Function: ps_seam_site_support_reason()
// Usage:
//   result = ps_seam_site_support_reason(site);
// Description:
//   Get printable support classification reason.
//   .
//   - Returns: reason string explaining support classification
// Arguments:
//   site = seam segment site record
function ps_seam_site_support_reason(site) = site[14];

// Function: ps_seam_site_current_normal_seam_local()
// Usage:
//   result = ps_seam_site_current_normal_seam_local(site);
// Description:
//   Get current face normal in seam-local coordinates.
//   .
//   - Returns: current target face normal expressed in the seam frame
// Arguments:
//   site = seam segment site record
function ps_seam_site_current_normal_seam_local(site) = site[15];

// Function: ps_seam_site_frame()
// Usage:
//   result = ps_seam_site_frame(site);
// Description:
//   Get placement frame from a seam segment site.
//   .
//   - Returns: placement frame `[center, ex, ey, ez]` in target face-local coordinates
// Arguments:
//   site = seam segment site record
function ps_seam_site_frame(site) =
    site[1];

// Function: ps_seam_site_is_support_candidate()
// Usage:
//   result = ps_seam_site_is_support_candidate(site);
// Description:
//   Test whether a seam site is a printable support candidate.
//   .
//   - Returns: true when support kind is not `"none"`
// Arguments:
//   site = seam segment site record
function ps_seam_site_is_support_candidate(site) = ps_seam_site_support_kind(site) != "none";

// Function: ps_seam_site_describe_str()
// Usage:
//   result = ps_seam_site_describe_str(site, detail, kvpair_to_str, field_sep);
// Description:
//   Build a description string for a seam segment site.
//   .
//   - Returns: description string
// Arguments:
//   site = seam segment site record
//   detail = detail level
//   kvpair_to_str = optional key/value formatter
//   field_sep = field separator
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

// Module: ps_seam_site_describe()
// Usage:
//   ps_seam_site_describe(site, detail, kvpair_to_str, field_sep);
// Description:
//   Echo a seam-site description.
//   .
//   - Returns: none
// Arguments:
//   site = seam segment site record
//   detail = detail level
//   kvpair_to_str = optional key/value formatter
//   field_sep = field separator
module ps_seam_site_describe(site, detail=0, kvpair_to_str=undef, field_sep=", ") {
    echo(ps_seam_site_describe_str(site, detail, kvpair_to_str, field_sep));
}
