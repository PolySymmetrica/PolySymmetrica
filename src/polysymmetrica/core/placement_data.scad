/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

// LibFile: polysymmetrica/core/placement_data.scad

// ---------------------------------------------------------------------------
// PolySymmetrica - Placement data records
// Shared record accessors for placement sites and proxy replay/group metadata.

use <funcs.scad>

// Function: ps_proxy_volume_group_kind()
// Usage:
//   result = ps_proxy_volume_group_kind(group);
// Description:
//   Get volume-group record kind.
//   .
//   - Returns: `"foreign_proxy_volume_group"`
// Arguments:
//   group = proxy volume-group record
function ps_proxy_volume_group_kind(group) = group[0];

// Function: ps_proxy_volume_group_target_face_idx()
// Usage:
//   result = ps_proxy_volume_group_target_face_idx(group);
// Description:
//   Get target face index from a volume group.
//   .
//   - Returns: target face index
// Arguments:
//   group = proxy volume-group record
function ps_proxy_volume_group_target_face_idx(group) = group[1];

// Function: ps_proxy_volume_group_idx()
// Usage:
//   result = ps_proxy_volume_group_idx(group);
// Description:
//   Get zero-based volume-group index.
//   .
//   - Returns: group index
// Arguments:
//   group = proxy volume-group record
function ps_proxy_volume_group_idx(group) = group[2];

// Function: ps_proxy_volume_group_face_idxs()
// Usage:
//   result = ps_proxy_volume_group_face_idxs(group);
// Description:
//   Get exact intruding source face ids in a volume group.
//   .
//   - Returns: source face ids
// Arguments:
//   group = proxy volume-group record
function ps_proxy_volume_group_face_idxs(group) = group[3];

// Function: ps_proxy_volume_group_record_idxs()
// Usage:
//   result = ps_proxy_volume_group_record_idxs(group);
// Description:
//   Get exact intrusion-record positions in a volume group.
//   .
//   - Returns: indices into the exact face-record list used to build the group
// Arguments:
//   group = proxy volume-group record
function ps_proxy_volume_group_record_idxs(group) = group[4];

// Function: ps_proxy_volume_group_records()
// Usage:
//   result = ps_proxy_volume_group_records(group);
// Description:
//   Get exact intrusion records in a volume group.
//   .
//   - Returns: intrusion records
// Arguments:
//   group = proxy volume-group record
function ps_proxy_volume_group_records(group) = group[5];

// Function: ps_proxy_volume_group_edge_idxs()
// Usage:
//   result = ps_proxy_volume_group_edge_idxs(group);
// Description:
//   Get source edge ids implicated by a volume group.
//   .
//   - Returns: source edge ids from grouped exact foreign faces
// Arguments:
//   group = proxy volume-group record
function ps_proxy_volume_group_edge_idxs(group) = group[6];

// Function: ps_proxy_volume_group_vertex_idxs()
// Usage:
//   result = ps_proxy_volume_group_vertex_idxs(group);
// Description:
//   Get source vertex ids implicated by a volume group.
//   .
//   - Returns: source vertex ids from grouped exact foreign faces
// Arguments:
//   group = proxy volume-group record
function ps_proxy_volume_group_vertex_idxs(group) = group[7];

// Function: ps_proxy_volume_group_support_face_idxs()
// Usage:
//   result = ps_proxy_volume_group_support_face_idxs(group);
// Description:
//   Get adjacent non-seed support face ids for a volume group.
//   .
//   - Returns: adjacent source face ids, excluding seed faces and the target face
// Arguments:
//   group = proxy volume-group record
function ps_proxy_volume_group_support_face_idxs(group) = group[8];

// Function: ps_replay_site_idx()
// Usage:
//   result = ps_replay_site_idx(site);
// Description:
//   Get replay site index.
//   .
//   - Returns: zero-based replay site index
// Arguments:
//   site = foreign replay site
function ps_replay_site_idx(site) = site[0];

// Function: ps_replay_site_intrusion_record()
// Usage:
//   result = ps_replay_site_intrusion_record(site);
// Description:
//   Get source intrusion record from a replay site.
//   .
//   - Returns: foreign intrusion record
// Arguments:
//   site = foreign replay site
function ps_replay_site_intrusion_record(site) = site[1];

// Function: ps_replay_site_frame()
// Usage:
//   result = ps_replay_site_frame(site);
// Description:
//   Get target-local replay frame.
//   .
//   - Returns: placement frame in current target face-local coordinates
// Arguments:
//   site = foreign replay site
function ps_replay_site_frame(site) = site[2];

// Function: ps_replay_site_center_local()
// Usage:
//   result = ps_replay_site_center_local(site);
// Description:
//   Get target-local replay frame center.
//   .
//   - Returns: center in current target face-local coordinates
// Arguments:
//   site = foreign replay site
function ps_replay_site_center_local(site) = ps_placement_frame_center(ps_replay_site_frame(site));

// Function: ps_replay_site_ex_local()
// Usage:
//   result = ps_replay_site_ex_local(site);
// Description:
//   Get target-local replay frame X axis.
//   .
//   - Returns: unit X axis in current target face-local coordinates
// Arguments:
//   site = foreign replay site
function ps_replay_site_ex_local(site) = ps_placement_frame_ex(ps_replay_site_frame(site));

// Function: ps_replay_site_ey_local()
// Usage:
//   result = ps_replay_site_ey_local(site);
// Description:
//   Get target-local replay frame Y axis.
//   .
//   - Returns: unit Y axis in current target face-local coordinates
// Arguments:
//   site = foreign replay site
function ps_replay_site_ey_local(site) = ps_placement_frame_ey(ps_replay_site_frame(site));

// Function: ps_replay_site_ez_local()
// Usage:
//   result = ps_replay_site_ez_local(site);
// Description:
//   Get target-local replay frame Z axis.
//   .
//   - Returns: unit Z axis in current target face-local coordinates
// Arguments:
//   site = foreign replay site
function ps_replay_site_ez_local(site) = ps_placement_frame_ez(ps_replay_site_frame(site));

// Function: ps_replay_site_foreign_idx()
// Usage:
//   result = ps_replay_site_foreign_idx(site);
// Description:
//   Get foreign element index from a replay site.
//   .
//   - Returns: foreign face/edge/vertex index, depending on `ps_replay_site_foreign_kind(site)`
// Arguments:
//   site = foreign replay site
function ps_replay_site_foreign_idx(site) = site[3];

// Function: ps_replay_site_face_pts2d()
// Usage:
//   result = ps_replay_site_face_pts2d(site);
// Description:
//   Get foreign face 2D points in replay local coordinates.
//   .
//   - Returns: `pts2d` for face sites in replay local coordinates, or `undef`
// Arguments:
//   site = foreign replay site
function ps_replay_site_face_pts2d(site) = site[4];

// Function: ps_replay_site_face_pts3d_local()
// Usage:
//   result = ps_replay_site_face_pts3d_local(site);
// Description:
//   Get foreign face 3D points in replay local coordinates.
//   .
//   - Returns: `pts3d` for face sites in replay local coordinates, or `undef`
// Arguments:
//   site = foreign replay site
function ps_replay_site_face_pts3d_local(site) = site[5];

// Function: ps_replay_site_poly_verts_local()
// Usage:
//   result = ps_replay_site_poly_verts_local(site);
// Description:
//   Get all poly vertices in replay local coordinates.
//   .
//   - Returns: vertex list transformed into the replay frame
// Arguments:
//   site = foreign replay site
function ps_replay_site_poly_verts_local(site) = site[6];

// Function: ps_replay_site_poly_center_local()
// Usage:
//   result = ps_replay_site_poly_center_local(site);
// Description:
//   Get poly center vector in replay local coordinates.
//   .
//   - Returns: vector from replay origin to poly center in replay local coordinates
// Arguments:
//   site = foreign replay site
function ps_replay_site_poly_center_local(site) = site[7];

// Function: ps_replay_site_face_verts_idx()
// Usage:
//   result = ps_replay_site_face_verts_idx(site);
// Description:
//   Get foreign face vertex indices from a replay site.
//   .
//   - Returns: face vertex index loop for face sites, or `undef`
// Arguments:
//   site = foreign replay site
function ps_replay_site_face_verts_idx(site) = site[8];

// Function: ps_replay_site_foreign_kind()
// Usage:
//   result = ps_replay_site_foreign_kind(site);
// Description:
//   Get foreign element kind from a replay site.
//   .
//   - Returns: foreign element kind (`"face"`, `"edge"`, or `"vertex"`)
// Arguments:
//   site = foreign replay site
function ps_replay_site_foreign_kind(site) = site[9];

// Function: ps_replay_site_intrusion_segment2d_local()
// Usage:
//   result = ps_replay_site_intrusion_segment2d_local(site);
// Description:
//   Get target-local intrusion segment from a replay site.
//   .
//   - Returns: `seg2d` in target face-local coordinates
// Arguments:
//   site = foreign replay site
function ps_replay_site_intrusion_segment2d_local(site) = site[10];

// Function: ps_replay_site_intrusion_dihedral()
// Usage:
//   result = ps_replay_site_intrusion_dihedral(site);
// Description:
//   Get cut dihedral from a replay site.
//   .
//   - Returns: face-plane cut dihedral
// Arguments:
//   site = foreign replay site
function ps_replay_site_intrusion_dihedral(site) = site[11];

// Function: ps_replay_site_intrusion_confidence()
// Usage:
//   result = ps_replay_site_intrusion_confidence(site);
// Description:
//   Get confidence/classification from a replay site.
//   .
//   - Returns: confidence string
// Arguments:
//   site = foreign replay site
function ps_replay_site_intrusion_confidence(site) = site[12];

// Function: ps_replay_site_face_site()
// Usage:
//   result = ps_replay_site_face_site(site);
// Description:
//   Get canonical face placement site from a replay site.
//   .
//   - Returns: face site record matching `ps_face_sites(...)`, or `undef`
// Arguments:
//   site = foreign replay site
function ps_replay_site_face_site(site) = site[13];

// Function: ps_replay_site_edge_site()
// Usage:
//   result = ps_replay_site_edge_site(site);
// Description:
//   Get canonical edge placement site from a replay site.
//   .
//   - Returns: edge site record matching `ps_edge_sites(...)`, or `undef`
// Arguments:
//   site = foreign replay site
function ps_replay_site_edge_site(site) = site[14];

// Function: ps_replay_site_vertex_site()
// Usage:
//   result = ps_replay_site_vertex_site(site);
// Description:
//   Get canonical vertex placement site from a replay site.
//   .
//   - Returns: vertex site record matching `ps_vertex_sites(...)`, or `undef`
// Arguments:
//   site = foreign replay site
function ps_replay_site_vertex_site(site) = site[15];

// Function: ps_face_site_idx()
// Usage:
//   result = ps_face_site_idx(site);
// Description:
//   Get face index from a face placement site.
//   .
//   - Returns: source face index
// Arguments:
//   site = face placement site record
function ps_face_site_idx(site) = site[0];

// Function: ps_face_site_center()
// Usage:
//   result = ps_face_site_center(site);
// Description:
//   Get center from a face placement site.
//   .
//   - Returns: face center in parent coordinates
// Arguments:
//   site = face placement site record
function ps_face_site_center(site) = ps_placement_frame_center(ps_face_site_frame(site));

// Function: ps_face_site_ex()
// Usage:
//   result = ps_face_site_ex(site);
// Description:
//   Get local X axis from a face placement site.
//   .
//   - Returns: unit X axis in parent coordinates
// Arguments:
//   site = face placement site record
function ps_face_site_ex(site) = ps_placement_frame_ex(ps_face_site_frame(site));

// Function: ps_face_site_ey()
// Usage:
//   result = ps_face_site_ey(site);
// Description:
//   Get local Y axis from a face placement site.
//   .
//   - Returns: unit Y axis in parent coordinates
// Arguments:
//   site = face placement site record
function ps_face_site_ey(site) = ps_placement_frame_ey(ps_face_site_frame(site));

// Function: ps_face_site_ez()
// Usage:
//   result = ps_face_site_ez(site);
// Description:
//   Get local Z axis from a face placement site.
//   .
//   - Returns: unit Z axis in parent coordinates
// Arguments:
//   site = face placement site record
function ps_face_site_ez(site) = ps_placement_frame_ez(ps_face_site_frame(site));

// Function: ps_face_site_edge_len()
// Usage:
//   result = ps_face_site_edge_len(site);
// Description:
//   Get target edge length from a face placement site.
//   .
//   - Returns: edge length scale used to build the site
// Arguments:
//   site = face placement site record
function ps_face_site_edge_len(site) = site[1];

// Function: ps_face_site_vertex_count()
// Usage:
//   result = ps_face_site_vertex_count(site);
// Description:
//   Get vertex count from a face placement site.
//   .
//   - Returns: number of vertices in the source face loop
// Arguments:
//   site = face placement site record
function ps_face_site_vertex_count(site) = site[2];

// Function: ps_face_site_midradius()
// Usage:
//   result = ps_face_site_midradius(site);
// Description:
//   Get face midradius from a face placement site.
//   .
//   - Returns: distance from parent origin to face center
// Arguments:
//   site = face placement site record
function ps_face_site_midradius(site) = site[3];

// Function: ps_face_site_radius()
// Usage:
//   result = ps_face_site_radius(site);
// Description:
//   Get face radius from a face placement site.
//   .
//   - Returns: mean distance from face center to face vertices
// Arguments:
//   site = face placement site record
function ps_face_site_radius(site) = site[4];

// Function: ps_face_site_poly_center_local()
// Usage:
//   result = ps_face_site_poly_center_local(site);
// Description:
//   Get poly center from a face placement site.
//   .
//   - Returns: poly center in face-local coordinates
// Arguments:
//   site = face placement site record
function ps_face_site_poly_center_local(site) = ps_face_local_context_poly_center_local(ps_face_site_face_local_context(site));

// Function: ps_face_site_pts2d()
// Usage:
//   result = ps_face_site_pts2d(site);
// Description:
//   Get 2D face points from a face placement site.
//   .
//   - Returns: source face loop in face-local XY coordinates
// Arguments:
//   site = face placement site record
function ps_face_site_pts2d(site) = ps_face_local_context_pts2d(ps_face_site_face_local_context(site));

// Function: ps_face_site_pts3d_local()
// Usage:
//   result = ps_face_site_pts3d_local(site);
// Description:
//   Get 3D local face points from a face placement site.
//   .
//   - Returns: source face loop in face-local XYZ coordinates
// Arguments:
//   site = face placement site record
function ps_face_site_pts3d_local(site) = ps_face_local_context_pts3d_local(ps_face_site_face_local_context(site));

// Function: ps_face_site_poly_verts_local()
// Usage:
//   result = ps_face_site_poly_verts_local(site);
// Description:
//   Get local poly vertices from a face placement site.
//   .
//   - Returns: all poly vertices in face-local coordinates
// Arguments:
//   site = face placement site record
function ps_face_site_poly_verts_local(site) = ps_face_local_context_poly_verts_local(ps_face_site_face_local_context(site));

// Function: ps_face_site_poly_faces_idx()
// Usage:
//   result = ps_face_site_poly_faces_idx(site);
// Description:
//   Get poly face indices from a face placement site.
//   .
//   - Returns: poly face index loops used to build the site
// Arguments:
//   site = face placement site record
function ps_face_site_poly_faces_idx(site) = ps_face_local_context_poly_faces_idx(ps_face_site_face_local_context(site));

// Function: ps_face_site_planarity_err()
// Usage:
//   result = ps_face_site_planarity_err(site);
// Description:
//   Get planarity error from a face placement site.
//   .
//   - Returns: maximum local Z deviation from the face plane
// Arguments:
//   site = face placement site record
function ps_face_site_planarity_err(site) = site[5];

// Function: ps_face_site_is_planar()
// Usage:
//   result = ps_face_site_is_planar(site);
// Description:
//   Get planarity flag from a face placement site.
//   .
//   - Returns: true when the face is planar within placement tolerance
// Arguments:
//   site = face placement site record
function ps_face_site_is_planar(site) = site[6];

// Function: ps_face_site_family_id()
// Usage:
//   result = ps_face_site_family_id(site);
// Description:
//   Get face family id from a face placement site.
//   .
//   - Returns: classification family id, or `undef`
// Arguments:
//   site = face placement site record
function ps_face_site_family_id(site) = site[7];

// Function: ps_face_site_face_family_count()
// Usage:
//   result = ps_face_site_face_family_count(site);
// Description:
//   Get face family count from a face placement site.
//   .
//   - Returns: number of face families in the classification context, or `undef`
// Arguments:
//   site = face placement site record
function ps_face_site_face_family_count(site) = site[8];

// Function: ps_face_site_edge_family_count()
// Usage:
//   result = ps_face_site_edge_family_count(site);
// Description:
//   Get edge family count from a face placement site.
//   .
//   - Returns: number of edge families in the classification context, or `undef`
// Arguments:
//   site = face placement site record
function ps_face_site_edge_family_count(site) = site[9];

// Function: ps_face_site_vertex_family_count()
// Usage:
//   result = ps_face_site_vertex_family_count(site);
// Description:
//   Get vertex family count from a face placement site.
//   .
//   - Returns: number of vertex families in the classification context, or `undef`
// Arguments:
//   site = face placement site record
function ps_face_site_vertex_family_count(site) = site[10];

// Function: ps_face_site_neighbors_idx()
// Usage:
//   result = ps_face_site_neighbors_idx(site);
// Description:
//   Get neighboring face indices from a face placement site.
//   .
//   - Returns: adjacent face index per source face edge
// Arguments:
//   site = face placement site record
function ps_face_site_neighbors_idx(site) = ps_face_local_context_neighbors_idx(ps_face_site_face_local_context(site));

// Function: ps_face_site_dihedrals()
// Usage:
//   result = ps_face_site_dihedrals(site);
// Description:
//   Get edge dihedrals from a face placement site.
//   .
//   - Returns: dihedral metadata per source face edge
// Arguments:
//   site = face placement site record
function ps_face_site_dihedrals(site) = ps_face_local_context_dihedrals(ps_face_site_face_local_context(site));

// Function: ps_face_site_frame()
// Usage:
//   result = ps_face_site_frame(site);
// Description:
//   Get placement frame from a face placement site.
//   .
//   - Returns: stored placement frame `[center, ex, ey, ez]`
// Arguments:
//   site = face placement site record
function ps_face_site_frame(site) = site[11];

// Function: ps_face_site_face_local_context()
// Usage:
//   result = ps_face_site_face_local_context(site);
// Description:
//   Get face-local context from a face placement site.
//   .
//   - Returns: stored face-local context record
// Arguments:
//   site = face placement site record
function ps_face_site_face_local_context(site) = site[12];

// Function: ps_face_site_target_local_poly_context()
// Usage:
//   result = ps_face_site_target_local_poly_context(site);
// Description:
//   Get target-local poly context from a face placement site.
//   .
//   - Returns: target-local poly context for the placed face
// Arguments:
//   site = face placement site record
function ps_face_site_target_local_poly_context(site) =
    ps_face_local_context_target_local_poly_context(ps_face_site_face_local_context(site));

// Function: ps_edge_site_idx()
// Usage:
//   result = ps_edge_site_idx(site);
// Description:
//   Get edge index from an edge placement site.
//   .
//   - Returns: source edge index
// Arguments:
//   site = edge placement site record
function ps_edge_site_idx(site) = site[0];

// Function: ps_edge_site_center()
// Usage:
//   result = ps_edge_site_center(site);
// Description:
//   Get center from an edge placement site.
//   .
//   - Returns: edge midpoint in parent coordinates
// Arguments:
//   site = edge placement site record
function ps_edge_site_center(site) = ps_placement_frame_center(ps_edge_site_frame(site));

// Function: ps_edge_site_ex()
// Usage:
//   result = ps_edge_site_ex(site);
// Description:
//   Get local X axis from an edge placement site.
//   .
//   - Returns: unit X axis in parent coordinates
// Arguments:
//   site = edge placement site record
function ps_edge_site_ex(site) = ps_placement_frame_ex(ps_edge_site_frame(site));

// Function: ps_edge_site_ey()
// Usage:
//   result = ps_edge_site_ey(site);
// Description:
//   Get local Y axis from an edge placement site.
//   .
//   - Returns: unit Y axis in parent coordinates
// Arguments:
//   site = edge placement site record
function ps_edge_site_ey(site) = ps_placement_frame_ey(ps_edge_site_frame(site));

// Function: ps_edge_site_ez()
// Usage:
//   result = ps_edge_site_ez(site);
// Description:
//   Get local Z axis from an edge placement site.
//   .
//   - Returns: unit Z axis in parent coordinates
// Arguments:
//   site = edge placement site record
function ps_edge_site_ez(site) = ps_placement_frame_ez(ps_edge_site_frame(site));

// Function: ps_edge_site_edge_len()
// Usage:
//   result = ps_edge_site_edge_len(site);
// Description:
//   Get actual edge length from an edge placement site.
//   .
//   - Returns: placed edge length
// Arguments:
//   site = edge placement site record
function ps_edge_site_edge_len(site) = site[1];

// Function: ps_edge_site_midradius()
// Usage:
//   result = ps_edge_site_midradius(site);
// Description:
//   Get edge midradius from an edge placement site.
//   .
//   - Returns: distance from parent origin to edge midpoint
// Arguments:
//   site = edge placement site record
function ps_edge_site_midradius(site) = site[2];

// Function: ps_edge_site_poly_center_local()
// Usage:
//   result = ps_edge_site_poly_center_local(site);
// Description:
//   Get poly center from an edge placement site.
//   .
//   - Returns: poly center in edge-local coordinates
// Arguments:
//   site = edge placement site record
function ps_edge_site_poly_center_local(site) = site[3];

// Function: ps_edge_site_pts_local()
// Usage:
//   result = ps_edge_site_pts_local(site);
// Description:
//   Get local edge endpoints from an edge placement site.
//   .
//   - Returns: two edge endpoints in edge-local coordinates
// Arguments:
//   site = edge placement site record
function ps_edge_site_pts_local(site) = site[4];

// Function: ps_edge_site_verts_idx()
// Usage:
//   result = ps_edge_site_verts_idx(site);
// Description:
//   Get source vertex indices from an edge placement site.
//   .
//   - Returns: source edge vertex pair
// Arguments:
//   site = edge placement site record
function ps_edge_site_verts_idx(site) = site[5];

// Function: ps_edge_site_adj_faces_idx()
// Usage:
//   result = ps_edge_site_adj_faces_idx(site);
// Description:
//   Get adjacent face indices from an edge placement site.
//   .
//   - Returns: face indices adjacent to the source edge
// Arguments:
//   site = edge placement site record
function ps_edge_site_adj_faces_idx(site) = site[6];

// Function: ps_edge_site_family_id()
// Usage:
//   result = ps_edge_site_family_id(site);
// Description:
//   Get edge family id from an edge placement site.
//   .
//   - Returns: classification family id, or `undef`
// Arguments:
//   site = edge placement site record
function ps_edge_site_family_id(site) = site[7];

// Function: ps_edge_site_face_family_count()
// Usage:
//   result = ps_edge_site_face_family_count(site);
// Description:
//   Get face family count from an edge placement site.
//   .
//   - Returns: number of face families in the classification context, or `undef`
// Arguments:
//   site = edge placement site record
function ps_edge_site_face_family_count(site) = site[8];

// Function: ps_edge_site_edge_family_count()
// Usage:
//   result = ps_edge_site_edge_family_count(site);
// Description:
//   Get edge family count from an edge placement site.
//   .
//   - Returns: number of edge families in the classification context, or `undef`
// Arguments:
//   site = edge placement site record
function ps_edge_site_edge_family_count(site) = site[9];

// Function: ps_edge_site_vertex_family_count()
// Usage:
//   result = ps_edge_site_vertex_family_count(site);
// Description:
//   Get vertex family count from an edge placement site.
//   .
//   - Returns: number of vertex families in the classification context, or `undef`
// Arguments:
//   site = edge placement site record
function ps_edge_site_vertex_family_count(site) = site[10];

// Function: ps_edge_site_frame()
// Usage:
//   result = ps_edge_site_frame(site);
// Description:
//   Get placement frame from an edge placement site.
//   .
//   - Returns: stored placement frame `[center, ex, ey, ez]`
// Arguments:
//   site = edge placement site record
function ps_edge_site_frame(site) = site[11];

// Function: ps_vertex_site_idx()
// Usage:
//   result = ps_vertex_site_idx(site);
// Description:
//   Get vertex index from a vertex placement site.
//   .
//   - Returns: source vertex index
// Arguments:
//   site = vertex placement site record
function ps_vertex_site_idx(site) = site[0];

// Function: ps_vertex_site_center()
// Usage:
//   result = ps_vertex_site_center(site);
// Description:
//   Get center from a vertex placement site.
//   .
//   - Returns: vertex position in parent coordinates
// Arguments:
//   site = vertex placement site record
function ps_vertex_site_center(site) = ps_placement_frame_center(ps_vertex_site_frame(site));

// Function: ps_vertex_site_ex()
// Usage:
//   result = ps_vertex_site_ex(site);
// Description:
//   Get local X axis from a vertex placement site.
//   .
//   - Returns: unit X axis in parent coordinates
// Arguments:
//   site = vertex placement site record
function ps_vertex_site_ex(site) = ps_placement_frame_ex(ps_vertex_site_frame(site));

// Function: ps_vertex_site_ey()
// Usage:
//   result = ps_vertex_site_ey(site);
// Description:
//   Get local Y axis from a vertex placement site.
//   .
//   - Returns: unit Y axis in parent coordinates
// Arguments:
//   site = vertex placement site record
function ps_vertex_site_ey(site) = ps_placement_frame_ey(ps_vertex_site_frame(site));

// Function: ps_vertex_site_ez()
// Usage:
//   result = ps_vertex_site_ez(site);
// Description:
//   Get local Z axis from a vertex placement site.
//   .
//   - Returns: unit Z axis in parent coordinates
// Arguments:
//   site = vertex placement site record
function ps_vertex_site_ez(site) = ps_placement_frame_ez(ps_vertex_site_frame(site));

// Function: ps_vertex_site_edge_len()
// Usage:
//   result = ps_vertex_site_edge_len(site);
// Description:
//   Get target edge length from a vertex placement site.
//   .
//   - Returns: edge length scale used to build the site
// Arguments:
//   site = vertex placement site record
function ps_vertex_site_edge_len(site) = site[1];

// Function: ps_vertex_site_radius()
// Usage:
//   result = ps_vertex_site_radius(site);
// Description:
//   Get vertex radius from a vertex placement site.
//   .
//   - Returns: distance from parent origin to vertex
// Arguments:
//   site = vertex placement site record
function ps_vertex_site_radius(site) = site[2];

// Function: ps_vertex_site_poly_center_local()
// Usage:
//   result = ps_vertex_site_poly_center_local(site);
// Description:
//   Get poly center from a vertex placement site.
//   .
//   - Returns: poly center in vertex-local coordinates
// Arguments:
//   site = vertex placement site record
function ps_vertex_site_poly_center_local(site) = site[3];

// Function: ps_vertex_site_valence()
// Usage:
//   result = ps_vertex_site_valence(site);
// Description:
//   Get vertex valence from a vertex placement site.
//   .
//   - Returns: number of incident source edges
// Arguments:
//   site = vertex placement site record
function ps_vertex_site_valence(site) = site[4];

// Function: ps_vertex_site_neighbors_idx()
// Usage:
//   result = ps_vertex_site_neighbors_idx(site);
// Description:
//   Get neighbor vertex indices from a vertex placement site.
//   .
//   - Returns: adjacent vertex indices
//   .
//   - Limitations/Gotchas: closed vertex fans use cyclic order anchored at the lowest neighbour index; boundary or partial proxy/replay sites use edge-scan order
// Arguments:
//   site = vertex placement site record
function ps_vertex_site_neighbors_idx(site) = site[5];

// Function: ps_vertex_site_neighbor_pts_local()
// Usage:
//   result = ps_vertex_site_neighbor_pts_local(site);
// Description:
//   Get local neighbor points from a vertex placement site.
//   .
//   - Returns: adjacent vertex positions in vertex-local coordinates
// Arguments:
//   site = vertex placement site record
function ps_vertex_site_neighbor_pts_local(site) = site[6];

// Function: ps_vertex_site_family_id()
// Usage:
//   result = ps_vertex_site_family_id(site);
// Description:
//   Get vertex family id from a vertex placement site.
//   .
//   - Returns: classification family id, or `undef`
// Arguments:
//   site = vertex placement site record
function ps_vertex_site_family_id(site) = site[7];

// Function: ps_vertex_site_face_family_count()
// Usage:
//   result = ps_vertex_site_face_family_count(site);
// Description:
//   Get face family count from a vertex placement site.
//   .
//   - Returns: number of face families in the classification context, or `undef`
// Arguments:
//   site = vertex placement site record
function ps_vertex_site_face_family_count(site) = site[8];

// Function: ps_vertex_site_edge_family_count()
// Usage:
//   result = ps_vertex_site_edge_family_count(site);
// Description:
//   Get edge family count from a vertex placement site.
//   .
//   - Returns: number of edge families in the classification context, or `undef`
// Arguments:
//   site = vertex placement site record
function ps_vertex_site_edge_family_count(site) = site[9];

// Function: ps_vertex_site_vertex_family_count()
// Usage:
//   result = ps_vertex_site_vertex_family_count(site);
// Description:
//   Get vertex family count from a vertex placement site.
//   .
//   - Returns: number of vertex families in the classification context, or `undef`
// Arguments:
//   site = vertex placement site record
function ps_vertex_site_vertex_family_count(site) = site[10];

// Function: ps_vertex_site_frame()
// Usage:
//   result = ps_vertex_site_frame(site);
// Description:
//   Get placement frame from a vertex placement site.
//   .
//   - Returns: stored placement frame `[center, ex, ey, ez]`
// Arguments:
//   site = vertex placement site record
function ps_vertex_site_frame(site) = site[11];

// Function: ps_proxy_volume_group_describe_str()
// Usage:
//   result = ps_proxy_volume_group_describe_str(group, detail, kvpair_to_str, field_sep);
// Description:
//   Build a description string for a proxy volume group.
//   .
//   - Returns: description string
// Arguments:
//   group = proxy volume-group record
//   detail = detail level
//   kvpair_to_str = optional key/value formatter
//   field_sep = field separator
function ps_proxy_volume_group_describe_str(group, detail=0, kvpair_to_str=undef, field_sep=", ") =
    ps_describe_record_str(
        "ProxyVolumeGroup",
        [
            ps_describe_kvpair_str("target_face_idx", ps_proxy_volume_group_target_face_idx(group), kvpair_to_str),
            ps_describe_kvpair_str("idx", ps_proxy_volume_group_idx(group), kvpair_to_str),
            ps_describe_kvpair_str("face_count", len(ps_proxy_volume_group_face_idxs(group)), kvpair_to_str),
            ps_describe_kvpair_str("edge_count", len(ps_proxy_volume_group_edge_idxs(group)), kvpair_to_str),
            ps_describe_kvpair_str("vertex_count", len(ps_proxy_volume_group_vertex_idxs(group)), kvpair_to_str)
        ],
        detail,
        [
            ps_describe_kvpair_str("kind", ps_proxy_volume_group_kind(group), kvpair_to_str),
            ps_describe_kvpair_str("face_idxs", ps_proxy_volume_group_face_idxs(group), kvpair_to_str),
            ps_describe_kvpair_str("record_idxs", ps_proxy_volume_group_record_idxs(group), kvpair_to_str),
            ps_describe_kvpair_str("records", ps_proxy_volume_group_records(group), kvpair_to_str),
            ps_describe_kvpair_str("edge_idxs", ps_proxy_volume_group_edge_idxs(group), kvpair_to_str),
            ps_describe_kvpair_str("vertex_idxs", ps_proxy_volume_group_vertex_idxs(group), kvpair_to_str),
            ps_describe_kvpair_str("support_face_idxs", ps_proxy_volume_group_support_face_idxs(group), kvpair_to_str)
        ],
        field_sep
    );

// Module: ps_proxy_volume_group_describe()
// Usage:
//   ps_proxy_volume_group_describe(group, detail, kvpair_to_str, field_sep);
// Description:
//   Echo a proxy volume-group description.
//   .
//   - Returns: none
// Arguments:
//   group = proxy volume-group record
//   detail = detail level
//   kvpair_to_str = optional key/value formatter
//   field_sep = field separator
module ps_proxy_volume_group_describe(group, detail=0, kvpair_to_str=undef, field_sep=", ") {
    echo(ps_proxy_volume_group_describe_str(group, detail, kvpair_to_str, field_sep));
}

// Function: ps_replay_site_describe_str()
// Usage:
//   result = ps_replay_site_describe_str(site, detail, kvpair_to_str, field_sep);
// Description:
//   Build a description string for a replay site.
//   .
//   - Returns: description string
// Arguments:
//   site = foreign replay site
//   detail = detail level
//   kvpair_to_str = optional key/value formatter
//   field_sep = field separator
function ps_replay_site_describe_str(site, detail=0, kvpair_to_str=undef, field_sep=", ") =
    ps_describe_record_str(
        "ReplaySite",
        [
            ps_describe_kvpair_str("idx", ps_replay_site_idx(site), kvpair_to_str),
            ps_describe_kvpair_str("foreign_kind", ps_replay_site_foreign_kind(site), kvpair_to_str),
            ps_describe_kvpair_str("foreign_idx", ps_replay_site_foreign_idx(site), kvpair_to_str),
            ps_describe_kvpair_str("confidence", ps_replay_site_intrusion_confidence(site), kvpair_to_str)
        ],
        detail,
        [
            ps_describe_kvpair_str("frame", ps_placement_frame_describe_str(ps_replay_site_frame(site), max(0, detail - 1), kvpair_to_str, field_sep), kvpair_to_str),
            ps_describe_kvpair_str("intrusion_record", ps_replay_site_intrusion_record(site), kvpair_to_str),
            ps_describe_kvpair_str("face_pts2d", ps_replay_site_face_pts2d(site), kvpair_to_str),
            ps_describe_kvpair_str("face_pts3d_local", ps_replay_site_face_pts3d_local(site), kvpair_to_str),
            ps_describe_kvpair_str("poly_verts_local", ps_replay_site_poly_verts_local(site), kvpair_to_str),
            ps_describe_kvpair_str("poly_center_local", ps_replay_site_poly_center_local(site), kvpair_to_str),
            ps_describe_kvpair_str("face_verts_idx", ps_replay_site_face_verts_idx(site), kvpair_to_str),
            ps_describe_kvpair_str("intrusion_segment2d_local", ps_replay_site_intrusion_segment2d_local(site), kvpair_to_str),
            ps_describe_kvpair_str("intrusion_dihedral", ps_replay_site_intrusion_dihedral(site), kvpair_to_str),
            ps_describe_kvpair_str("face_site", is_undef(ps_replay_site_face_site(site)) ? undef : ps_face_site_describe_str(ps_replay_site_face_site(site), max(0, detail - 1), kvpair_to_str, field_sep), kvpair_to_str),
            ps_describe_kvpair_str("edge_site", is_undef(ps_replay_site_edge_site(site)) ? undef : ps_edge_site_describe_str(ps_replay_site_edge_site(site), max(0, detail - 1), kvpair_to_str, field_sep), kvpair_to_str),
            ps_describe_kvpair_str("vertex_site", is_undef(ps_replay_site_vertex_site(site)) ? undef : ps_vertex_site_describe_str(ps_replay_site_vertex_site(site), max(0, detail - 1), kvpair_to_str, field_sep), kvpair_to_str)
        ],
        field_sep
    );

// Module: ps_replay_site_describe()
// Usage:
//   ps_replay_site_describe(site, detail, kvpair_to_str, field_sep);
// Description:
//   Echo a replay-site description.
//   .
//   - Returns: none
// Arguments:
//   site = foreign replay site
//   detail = detail level
//   kvpair_to_str = optional key/value formatter
//   field_sep = field separator
module ps_replay_site_describe(site, detail=0, kvpair_to_str=undef, field_sep=", ") {
    echo(ps_replay_site_describe_str(site, detail, kvpair_to_str, field_sep));
}

// Function: ps_face_site_describe_str()
// Usage:
//   result = ps_face_site_describe_str(site, detail, kvpair_to_str, field_sep);
// Description:
//   Build a description string for a face placement site.
//   .
//   - Returns: description string
// Arguments:
//   site = face placement site record
//   detail = detail level
//   kvpair_to_str = optional key/value formatter
//   field_sep = field separator
function ps_face_site_describe_str(site, detail=0, kvpair_to_str=undef, field_sep=", ") =
    ps_describe_record_str(
        "FaceSite",
        [
            ps_describe_kvpair_str("idx", ps_face_site_idx(site), kvpair_to_str),
            ps_describe_kvpair_str("vertex_count", ps_face_site_vertex_count(site), kvpair_to_str),
            ps_describe_kvpair_str("family_id", ps_face_site_family_id(site), kvpair_to_str),
            ps_describe_kvpair_str("frame", ps_placement_frame_describe_str(ps_face_site_frame(site), max(0, detail - 1), kvpair_to_str, field_sep), kvpair_to_str)
        ],
        detail,
        [
            ps_describe_kvpair_str("edge_len", ps_face_site_edge_len(site), kvpair_to_str),
            ps_describe_kvpair_str("midradius", ps_face_site_midradius(site), kvpair_to_str),
            ps_describe_kvpair_str("radius", ps_face_site_radius(site), kvpair_to_str),
            ps_describe_kvpair_str("planarity_err", ps_face_site_planarity_err(site), kvpair_to_str),
            ps_describe_kvpair_str("is_planar", ps_face_site_is_planar(site), kvpair_to_str),
            ps_describe_kvpair_str("face_family_count", ps_face_site_face_family_count(site), kvpair_to_str),
            ps_describe_kvpair_str("edge_family_count", ps_face_site_edge_family_count(site), kvpair_to_str),
            ps_describe_kvpair_str("vertex_family_count", ps_face_site_vertex_family_count(site), kvpair_to_str),
            ps_describe_kvpair_str("face_local_context", ps_face_local_context_describe_str(ps_face_site_face_local_context(site), max(0, detail - 1), kvpair_to_str, field_sep), kvpair_to_str)
        ],
        field_sep
    );

// Module: ps_face_site_describe()
// Usage:
//   ps_face_site_describe(site, detail, kvpair_to_str, field_sep);
// Description:
//   Echo a face-site description.
//   .
//   - Returns: none
// Arguments:
//   site = face placement site record
//   detail = detail level
//   kvpair_to_str = optional key/value formatter
//   field_sep = field separator
module ps_face_site_describe(site, detail=0, kvpair_to_str=undef, field_sep=", ") {
    echo(ps_face_site_describe_str(site, detail, kvpair_to_str, field_sep));
}

// Function: ps_edge_site_describe_str()
// Usage:
//   result = ps_edge_site_describe_str(site, detail, kvpair_to_str, field_sep);
// Description:
//   Build a description string for an edge placement site.
//   .
//   - Returns: description string
// Arguments:
//   site = edge placement site record
//   detail = detail level
//   kvpair_to_str = optional key/value formatter
//   field_sep = field separator
function ps_edge_site_describe_str(site, detail=0, kvpair_to_str=undef, field_sep=", ") =
    ps_describe_record_str(
        "EdgeSite",
        [
            ps_describe_kvpair_str("idx", ps_edge_site_idx(site), kvpair_to_str),
            ps_describe_kvpair_str("edge_len", ps_edge_site_edge_len(site), kvpair_to_str),
            ps_describe_kvpair_str("family_id", ps_edge_site_family_id(site), kvpair_to_str),
            ps_describe_kvpair_str("frame", ps_placement_frame_describe_str(ps_edge_site_frame(site), max(0, detail - 1), kvpair_to_str, field_sep), kvpair_to_str)
        ],
        detail,
        [
            ps_describe_kvpair_str("midradius", ps_edge_site_midradius(site), kvpair_to_str),
            ps_describe_kvpair_str("poly_center_local", ps_edge_site_poly_center_local(site), kvpair_to_str),
            ps_describe_kvpair_str("pts_local", ps_edge_site_pts_local(site), kvpair_to_str),
            ps_describe_kvpair_str("verts_idx", ps_edge_site_verts_idx(site), kvpair_to_str),
            ps_describe_kvpair_str("adj_faces_idx", ps_edge_site_adj_faces_idx(site), kvpair_to_str),
            ps_describe_kvpair_str("face_family_count", ps_edge_site_face_family_count(site), kvpair_to_str),
            ps_describe_kvpair_str("edge_family_count", ps_edge_site_edge_family_count(site), kvpair_to_str),
            ps_describe_kvpair_str("vertex_family_count", ps_edge_site_vertex_family_count(site), kvpair_to_str)
        ],
        field_sep
    );

// Module: ps_edge_site_describe()
// Usage:
//   ps_edge_site_describe(site, detail, kvpair_to_str, field_sep);
// Description:
//   Echo an edge-site description.
//   .
//   - Returns: none
// Arguments:
//   site = edge placement site record
//   detail = detail level
//   kvpair_to_str = optional key/value formatter
//   field_sep = field separator
module ps_edge_site_describe(site, detail=0, kvpair_to_str=undef, field_sep=", ") {
    echo(ps_edge_site_describe_str(site, detail, kvpair_to_str, field_sep));
}

// Function: ps_vertex_site_describe_str()
// Usage:
//   result = ps_vertex_site_describe_str(site, detail, kvpair_to_str, field_sep);
// Description:
//   Build a description string for a vertex placement site.
//   .
//   - Returns: description string
// Arguments:
//   site = vertex placement site record
//   detail = detail level
//   kvpair_to_str = optional key/value formatter
//   field_sep = field separator
function ps_vertex_site_describe_str(site, detail=0, kvpair_to_str=undef, field_sep=", ") =
    ps_describe_record_str(
        "VertexSite",
        [
            ps_describe_kvpair_str("idx", ps_vertex_site_idx(site), kvpair_to_str),
            ps_describe_kvpair_str("valence", ps_vertex_site_valence(site), kvpair_to_str),
            ps_describe_kvpair_str("family_id", ps_vertex_site_family_id(site), kvpair_to_str),
            ps_describe_kvpair_str("frame", ps_placement_frame_describe_str(ps_vertex_site_frame(site), max(0, detail - 1), kvpair_to_str, field_sep), kvpair_to_str)
        ],
        detail,
        [
            ps_describe_kvpair_str("edge_len", ps_vertex_site_edge_len(site), kvpair_to_str),
            ps_describe_kvpair_str("radius", ps_vertex_site_radius(site), kvpair_to_str),
            ps_describe_kvpair_str("poly_center_local", ps_vertex_site_poly_center_local(site), kvpair_to_str),
            ps_describe_kvpair_str("neighbors_idx", ps_vertex_site_neighbors_idx(site), kvpair_to_str),
            ps_describe_kvpair_str("neighbor_pts_local", ps_vertex_site_neighbor_pts_local(site), kvpair_to_str),
            ps_describe_kvpair_str("face_family_count", ps_vertex_site_face_family_count(site), kvpair_to_str),
            ps_describe_kvpair_str("edge_family_count", ps_vertex_site_edge_family_count(site), kvpair_to_str),
            ps_describe_kvpair_str("vertex_family_count", ps_vertex_site_vertex_family_count(site), kvpair_to_str)
        ],
        field_sep
    );

// Module: ps_vertex_site_describe()
// Usage:
//   ps_vertex_site_describe(site, detail, kvpair_to_str, field_sep);
// Description:
//   Echo a vertex-site description.
//   .
//   - Returns: none
// Arguments:
//   site = vertex placement site record
//   detail = detail level
//   kvpair_to_str = optional key/value formatter
//   field_sep = field separator
module ps_vertex_site_describe(site, detail=0, kvpair_to_str=undef, field_sep=", ") {
    echo(ps_vertex_site_describe_str(site, detail, kvpair_to_str, field_sep));
}
