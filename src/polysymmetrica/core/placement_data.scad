// ---------------------------------------------------------------------------
// PolySymmetrica - Placement data records
// Shared record accessors for placement sites and proxy replay/group metadata.

use <funcs.scad>

/**
 * Function: Get volume-group record kind.
 * Params: group (proxy volume-group record)
 * Returns: `"foreign_proxy_volume_group"`
 */
function ps_proxy_volume_group_kind(group) = group[0];

/**
 * Function: Get target face index from a volume group.
 * Params: group (proxy volume-group record)
 * Returns: target face index
 */
function ps_proxy_volume_group_target_face_idx(group) = group[1];

/**
 * Function: Get zero-based volume-group index.
 * Params: group (proxy volume-group record)
 * Returns: group index
 */
function ps_proxy_volume_group_idx(group) = group[2];

/**
 * Function: Get exact intruding source face ids in a volume group.
 * Params: group (proxy volume-group record)
 * Returns: source face ids
 */
function ps_proxy_volume_group_face_idxs(group) = group[3];

/**
 * Function: Get exact intrusion-record positions in a volume group.
 * Params: group (proxy volume-group record)
 * Returns: indices into the exact face-record list used to build the group
 */
function ps_proxy_volume_group_record_idxs(group) = group[4];

/**
 * Function: Get exact intrusion records in a volume group.
 * Params: group (proxy volume-group record)
 * Returns: intrusion records
 */
function ps_proxy_volume_group_records(group) = group[5];

/**
 * Function: Get source edge ids implicated by a volume group.
 * Params: group (proxy volume-group record)
 * Returns: source edge ids from grouped exact foreign faces
 */
function ps_proxy_volume_group_edge_idxs(group) = group[6];

/**
 * Function: Get source vertex ids implicated by a volume group.
 * Params: group (proxy volume-group record)
 * Returns: source vertex ids from grouped exact foreign faces
 */
function ps_proxy_volume_group_vertex_idxs(group) = group[7];

/**
 * Function: Get adjacent non-seed support face ids for a volume group.
 * Params: group (proxy volume-group record)
 * Returns: adjacent source face ids, excluding seed faces and the target face
 */
function ps_proxy_volume_group_support_face_idxs(group) = group[8];

/**
 * Function: Get replay site index.
 * Params: site (foreign replay site)
 * Returns: zero-based replay site index
 */
function ps_replay_site_idx(site) = site[0];

/**
 * Function: Get source intrusion record from a replay site.
 * Params: site (foreign replay site)
 * Returns: foreign intrusion record
 */
function ps_replay_site_intrusion_record(site) = site[1];

/**
 * Function: Get target-local replay frame.
 * Params: site (foreign replay site)
 * Returns: placement frame in current target face-local coordinates
 */
function ps_replay_site_frame(site) = site[2];

/**
 * Function: Get target-local replay frame center.
 * Params: site (foreign replay site)
 * Returns: center in current target face-local coordinates
 */
function ps_replay_site_center_local(site) = ps_placement_frame_center(ps_replay_site_frame(site));

/**
 * Function: Get target-local replay frame X axis.
 * Params: site (foreign replay site)
 * Returns: unit X axis in current target face-local coordinates
 */
function ps_replay_site_ex_local(site) = ps_placement_frame_ex(ps_replay_site_frame(site));

/**
 * Function: Get target-local replay frame Y axis.
 * Params: site (foreign replay site)
 * Returns: unit Y axis in current target face-local coordinates
 */
function ps_replay_site_ey_local(site) = ps_placement_frame_ey(ps_replay_site_frame(site));

/**
 * Function: Get target-local replay frame Z axis.
 * Params: site (foreign replay site)
 * Returns: unit Z axis in current target face-local coordinates
 */
function ps_replay_site_ez_local(site) = ps_placement_frame_ez(ps_replay_site_frame(site));

/**
 * Function: Get foreign element index from a replay site.
 * Params: site (foreign replay site)
 * Returns: foreign face/edge/vertex index, depending on `ps_replay_site_foreign_kind(site)`
 */
function ps_replay_site_foreign_idx(site) = site[3];

/**
 * Function: Get foreign face 2D points in replay local coordinates.
 * Params: site (foreign replay site)
 * Returns: `pts2d` for face sites in replay local coordinates, or `undef`
 */
function ps_replay_site_face_pts2d(site) = site[4];

/**
 * Function: Get foreign face 3D points in replay local coordinates.
 * Params: site (foreign replay site)
 * Returns: `pts3d` for face sites in replay local coordinates, or `undef`
 */
function ps_replay_site_face_pts3d_local(site) = site[5];

/**
 * Function: Get all poly vertices in replay local coordinates.
 * Params: site (foreign replay site)
 * Returns: vertex list transformed into the replay frame
 */
function ps_replay_site_poly_verts_local(site) = site[6];

/**
 * Function: Get poly center vector in replay local coordinates.
 * Params: site (foreign replay site)
 * Returns: vector from replay origin to poly center in replay local coordinates
 */
function ps_replay_site_poly_center_local(site) = site[7];

/**
 * Function: Get foreign face vertex indices from a replay site.
 * Params: site (foreign replay site)
 * Returns: face vertex index loop for face sites, or `undef`
 */
function ps_replay_site_face_verts_idx(site) = site[8];

/**
 * Function: Get foreign element kind from a replay site.
 * Params: site (foreign replay site)
 * Returns: foreign element kind (`"face"`, `"edge"`, or `"vertex"`)
 */
function ps_replay_site_foreign_kind(site) = site[9];

/**
 * Function: Get target-local intrusion segment from a replay site.
 * Params: site (foreign replay site)
 * Returns: `seg2d` in target face-local coordinates
 */
function ps_replay_site_intrusion_segment2d_local(site) = site[10];

/**
 * Function: Get cut dihedral from a replay site.
 * Params: site (foreign replay site)
 * Returns: face-plane cut dihedral
 */
function ps_replay_site_intrusion_dihedral(site) = site[11];

/**
 * Function: Get confidence/classification from a replay site.
 * Params: site (foreign replay site)
 * Returns: confidence string
 */
function ps_replay_site_intrusion_confidence(site) = site[12];

/**
 * Function: Get canonical face placement site from a replay site.
 * Params: site (foreign replay site)
 * Returns: face site record matching `ps_face_sites(...)`, or `undef`
 */
function ps_replay_site_face_site(site) = site[13];

/**
 * Function: Get canonical edge placement site from a replay site.
 * Params: site (foreign replay site)
 * Returns: edge site record matching `ps_edge_sites(...)`, or `undef`
 */
function ps_replay_site_edge_site(site) = site[14];

/**
 * Function: Get canonical vertex placement site from a replay site.
 * Params: site (foreign replay site)
 * Returns: vertex site record matching `ps_vertex_sites(...)`, or `undef`
 */
function ps_replay_site_vertex_site(site) = site[15];

/**
 * Function: Get face index from a face placement site.
 * Params: site (face placement site record)
 * Returns: source face index
 */
function ps_face_site_idx(site) = site[0];

/**
 * Function: Get center from a face placement site.
 * Params: site (face placement site record)
 * Returns: face center in parent coordinates
 */
function ps_face_site_center(site) = ps_placement_frame_center(ps_face_site_frame(site));

/**
 * Function: Get local X axis from a face placement site.
 * Params: site (face placement site record)
 * Returns: unit X axis in parent coordinates
 */
function ps_face_site_ex(site) = ps_placement_frame_ex(ps_face_site_frame(site));

/**
 * Function: Get local Y axis from a face placement site.
 * Params: site (face placement site record)
 * Returns: unit Y axis in parent coordinates
 */
function ps_face_site_ey(site) = ps_placement_frame_ey(ps_face_site_frame(site));

/**
 * Function: Get local Z axis from a face placement site.
 * Params: site (face placement site record)
 * Returns: unit Z axis in parent coordinates
 */
function ps_face_site_ez(site) = ps_placement_frame_ez(ps_face_site_frame(site));

/**
 * Function: Get target edge length from a face placement site.
 * Params: site (face placement site record)
 * Returns: edge length scale used to build the site
 */
function ps_face_site_edge_len(site) = site[1];

/**
 * Function: Get vertex count from a face placement site.
 * Params: site (face placement site record)
 * Returns: number of vertices in the source face loop
 */
function ps_face_site_vertex_count(site) = site[2];

/**
 * Function: Get face midradius from a face placement site.
 * Params: site (face placement site record)
 * Returns: distance from parent origin to face center
 */
function ps_face_site_midradius(site) = site[3];

/**
 * Function: Get face radius from a face placement site.
 * Params: site (face placement site record)
 * Returns: mean distance from face center to face vertices
 */
function ps_face_site_radius(site) = site[4];

/**
 * Function: Get poly center from a face placement site.
 * Params: site (face placement site record)
 * Returns: poly center in face-local coordinates
 */
function ps_face_site_poly_center_local(site) = ps_face_local_context_poly_center_local(ps_face_site_face_local_context(site));

/**
 * Function: Get 2D face points from a face placement site.
 * Params: site (face placement site record)
 * Returns: source face loop in face-local XY coordinates
 */
function ps_face_site_pts2d(site) = ps_face_local_context_pts2d(ps_face_site_face_local_context(site));

/**
 * Function: Get 3D local face points from a face placement site.
 * Params: site (face placement site record)
 * Returns: source face loop in face-local XYZ coordinates
 */
function ps_face_site_pts3d_local(site) = ps_face_local_context_pts3d_local(ps_face_site_face_local_context(site));

/**
 * Function: Get local poly vertices from a face placement site.
 * Params: site (face placement site record)
 * Returns: all poly vertices in face-local coordinates
 */
function ps_face_site_poly_verts_local(site) = ps_face_local_context_poly_verts_local(ps_face_site_face_local_context(site));

/**
 * Function: Get poly face indices from a face placement site.
 * Params: site (face placement site record)
 * Returns: poly face index loops used to build the site
 */
function ps_face_site_poly_faces_idx(site) = ps_face_local_context_poly_faces_idx(ps_face_site_face_local_context(site));

/**
 * Function: Get planarity error from a face placement site.
 * Params: site (face placement site record)
 * Returns: maximum local Z deviation from the face plane
 */
function ps_face_site_planarity_err(site) = site[5];

/**
 * Function: Get planarity flag from a face placement site.
 * Params: site (face placement site record)
 * Returns: true when the face is planar within placement tolerance
 */
function ps_face_site_is_planar(site) = site[6];

/**
 * Function: Get face family id from a face placement site.
 * Params: site (face placement site record)
 * Returns: classification family id, or `undef`
 */
function ps_face_site_family_id(site) = site[7];

/**
 * Function: Get face family count from a face placement site.
 * Params: site (face placement site record)
 * Returns: number of face families in the classification context, or `undef`
 */
function ps_face_site_face_family_count(site) = site[8];

/**
 * Function: Get edge family count from a face placement site.
 * Params: site (face placement site record)
 * Returns: number of edge families in the classification context, or `undef`
 */
function ps_face_site_edge_family_count(site) = site[9];

/**
 * Function: Get vertex family count from a face placement site.
 * Params: site (face placement site record)
 * Returns: number of vertex families in the classification context, or `undef`
 */
function ps_face_site_vertex_family_count(site) = site[10];

/**
 * Function: Get neighboring face indices from a face placement site.
 * Params: site (face placement site record)
 * Returns: adjacent face index per source face edge
 */
function ps_face_site_neighbors_idx(site) = ps_face_local_context_neighbors_idx(ps_face_site_face_local_context(site));

/**
 * Function: Get edge dihedrals from a face placement site.
 * Params: site (face placement site record)
 * Returns: dihedral metadata per source face edge
 */
function ps_face_site_dihedrals(site) = ps_face_local_context_dihedrals(ps_face_site_face_local_context(site));

/**
 * Function: Get placement frame from a face placement site.
 * Params: site (face placement site record)
 * Returns: stored placement frame `[center, ex, ey, ez]`
 */
function ps_face_site_frame(site) = site[11];

/**
 * Function: Get face-local context from a face placement site.
 * Params: site (face placement site record)
 * Returns: stored face-local context record
 */
function ps_face_site_face_local_context(site) = site[12];

/**
 * Function: Get target-local poly context from a face placement site.
 * Params: site (face placement site record)
 * Returns: target-local poly context for the placed face
 */
function ps_face_site_target_local_poly_context(site) =
    ps_face_local_context_target_local_poly_context(ps_face_site_face_local_context(site));

/**
 * Function: Get edge index from an edge placement site.
 * Params: site (edge placement site record)
 * Returns: source edge index
 */
function ps_edge_site_idx(site) = site[0];

/**
 * Function: Get center from an edge placement site.
 * Params: site (edge placement site record)
 * Returns: edge midpoint in parent coordinates
 */
function ps_edge_site_center(site) = ps_placement_frame_center(ps_edge_site_frame(site));

/**
 * Function: Get local X axis from an edge placement site.
 * Params: site (edge placement site record)
 * Returns: unit X axis in parent coordinates
 */
function ps_edge_site_ex(site) = ps_placement_frame_ex(ps_edge_site_frame(site));

/**
 * Function: Get local Y axis from an edge placement site.
 * Params: site (edge placement site record)
 * Returns: unit Y axis in parent coordinates
 */
function ps_edge_site_ey(site) = ps_placement_frame_ey(ps_edge_site_frame(site));

/**
 * Function: Get local Z axis from an edge placement site.
 * Params: site (edge placement site record)
 * Returns: unit Z axis in parent coordinates
 */
function ps_edge_site_ez(site) = ps_placement_frame_ez(ps_edge_site_frame(site));

/**
 * Function: Get actual edge length from an edge placement site.
 * Params: site (edge placement site record)
 * Returns: placed edge length
 */
function ps_edge_site_edge_len(site) = site[1];

/**
 * Function: Get edge midradius from an edge placement site.
 * Params: site (edge placement site record)
 * Returns: distance from parent origin to edge midpoint
 */
function ps_edge_site_midradius(site) = site[2];

/**
 * Function: Get poly center from an edge placement site.
 * Params: site (edge placement site record)
 * Returns: poly center in edge-local coordinates
 */
function ps_edge_site_poly_center_local(site) = site[3];

/**
 * Function: Get local edge endpoints from an edge placement site.
 * Params: site (edge placement site record)
 * Returns: two edge endpoints in edge-local coordinates
 */
function ps_edge_site_pts_local(site) = site[4];

/**
 * Function: Get source vertex indices from an edge placement site.
 * Params: site (edge placement site record)
 * Returns: source edge vertex pair
 */
function ps_edge_site_verts_idx(site) = site[5];

/**
 * Function: Get adjacent face indices from an edge placement site.
 * Params: site (edge placement site record)
 * Returns: face indices adjacent to the source edge
 */
function ps_edge_site_adj_faces_idx(site) = site[6];

/**
 * Function: Get edge family id from an edge placement site.
 * Params: site (edge placement site record)
 * Returns: classification family id, or `undef`
 */
function ps_edge_site_family_id(site) = site[7];

/**
 * Function: Get face family count from an edge placement site.
 * Params: site (edge placement site record)
 * Returns: number of face families in the classification context, or `undef`
 */
function ps_edge_site_face_family_count(site) = site[8];

/**
 * Function: Get edge family count from an edge placement site.
 * Params: site (edge placement site record)
 * Returns: number of edge families in the classification context, or `undef`
 */
function ps_edge_site_edge_family_count(site) = site[9];

/**
 * Function: Get vertex family count from an edge placement site.
 * Params: site (edge placement site record)
 * Returns: number of vertex families in the classification context, or `undef`
 */
function ps_edge_site_vertex_family_count(site) = site[10];

/**
 * Function: Get placement frame from an edge placement site.
 * Params: site (edge placement site record)
 * Returns: stored placement frame `[center, ex, ey, ez]`
 */
function ps_edge_site_frame(site) = site[11];

/**
 * Function: Get vertex index from a vertex placement site.
 * Params: site (vertex placement site record)
 * Returns: source vertex index
 */
function ps_vertex_site_idx(site) = site[0];

/**
 * Function: Get center from a vertex placement site.
 * Params: site (vertex placement site record)
 * Returns: vertex position in parent coordinates
 */
function ps_vertex_site_center(site) = ps_placement_frame_center(ps_vertex_site_frame(site));

/**
 * Function: Get local X axis from a vertex placement site.
 * Params: site (vertex placement site record)
 * Returns: unit X axis in parent coordinates
 */
function ps_vertex_site_ex(site) = ps_placement_frame_ex(ps_vertex_site_frame(site));

/**
 * Function: Get local Y axis from a vertex placement site.
 * Params: site (vertex placement site record)
 * Returns: unit Y axis in parent coordinates
 */
function ps_vertex_site_ey(site) = ps_placement_frame_ey(ps_vertex_site_frame(site));

/**
 * Function: Get local Z axis from a vertex placement site.
 * Params: site (vertex placement site record)
 * Returns: unit Z axis in parent coordinates
 */
function ps_vertex_site_ez(site) = ps_placement_frame_ez(ps_vertex_site_frame(site));

/**
 * Function: Get target edge length from a vertex placement site.
 * Params: site (vertex placement site record)
 * Returns: edge length scale used to build the site
 */
function ps_vertex_site_edge_len(site) = site[1];

/**
 * Function: Get vertex radius from a vertex placement site.
 * Params: site (vertex placement site record)
 * Returns: distance from parent origin to vertex
 */
function ps_vertex_site_radius(site) = site[2];

/**
 * Function: Get poly center from a vertex placement site.
 * Params: site (vertex placement site record)
 * Returns: poly center in vertex-local coordinates
 */
function ps_vertex_site_poly_center_local(site) = site[3];

/**
 * Function: Get vertex valence from a vertex placement site.
 * Params: site (vertex placement site record)
 * Returns: number of incident source edges
 */
function ps_vertex_site_valence(site) = site[4];

/**
 * Function: Get neighbor vertex indices from a vertex placement site.
 * Params: site (vertex placement site record)
 * Returns: adjacent vertex indices
 */
function ps_vertex_site_neighbors_idx(site) = site[5];

/**
 * Function: Get local neighbor points from a vertex placement site.
 * Params: site (vertex placement site record)
 * Returns: adjacent vertex positions in vertex-local coordinates
 */
function ps_vertex_site_neighbor_pts_local(site) = site[6];

/**
 * Function: Get vertex family id from a vertex placement site.
 * Params: site (vertex placement site record)
 * Returns: classification family id, or `undef`
 */
function ps_vertex_site_family_id(site) = site[7];

/**
 * Function: Get face family count from a vertex placement site.
 * Params: site (vertex placement site record)
 * Returns: number of face families in the classification context, or `undef`
 */
function ps_vertex_site_face_family_count(site) = site[8];

/**
 * Function: Get edge family count from a vertex placement site.
 * Params: site (vertex placement site record)
 * Returns: number of edge families in the classification context, or `undef`
 */
function ps_vertex_site_edge_family_count(site) = site[9];

/**
 * Function: Get vertex family count from a vertex placement site.
 * Params: site (vertex placement site record)
 * Returns: number of vertex families in the classification context, or `undef`
 */
function ps_vertex_site_vertex_family_count(site) = site[10];

/**
 * Function: Get placement frame from a vertex placement site.
 * Params: site (vertex placement site record)
 * Returns: stored placement frame `[center, ex, ey, ez]`
 */
function ps_vertex_site_frame(site) = site[11];

/**
 * Function: Build a description string for a proxy volume group.
 * Params: group (proxy volume-group record), detail (detail level), kvpair_to_str (optional key/value formatter), field_sep (field separator)
 * Returns: description string
 */
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

/**
 * Module: Echo a proxy volume-group description.
 * Params: group (proxy volume-group record), detail (detail level), kvpair_to_str (optional key/value formatter), field_sep (field separator)
 * Returns: none
 */
module ps_proxy_volume_group_describe(group, detail=0, kvpair_to_str=undef, field_sep=", ") {
    echo(ps_proxy_volume_group_describe_str(group, detail, kvpair_to_str, field_sep));
}

/**
 * Function: Build a description string for a replay site.
 * Params: site (foreign replay site), detail (detail level), kvpair_to_str (optional key/value formatter), field_sep (field separator)
 * Returns: description string
 */
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

/**
 * Module: Echo a replay-site description.
 * Params: site (foreign replay site), detail (detail level), kvpair_to_str (optional key/value formatter), field_sep (field separator)
 * Returns: none
 */
module ps_replay_site_describe(site, detail=0, kvpair_to_str=undef, field_sep=", ") {
    echo(ps_replay_site_describe_str(site, detail, kvpair_to_str, field_sep));
}

/**
 * Function: Build a description string for a face placement site.
 * Params: site (face placement site record), detail (detail level), kvpair_to_str (optional key/value formatter), field_sep (field separator)
 * Returns: description string
 */
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

/**
 * Module: Echo a face-site description.
 * Params: site (face placement site record), detail (detail level), kvpair_to_str (optional key/value formatter), field_sep (field separator)
 * Returns: none
 */
module ps_face_site_describe(site, detail=0, kvpair_to_str=undef, field_sep=", ") {
    echo(ps_face_site_describe_str(site, detail, kvpair_to_str, field_sep));
}

/**
 * Function: Build a description string for an edge placement site.
 * Params: site (edge placement site record), detail (detail level), kvpair_to_str (optional key/value formatter), field_sep (field separator)
 * Returns: description string
 */
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

/**
 * Module: Echo an edge-site description.
 * Params: site (edge placement site record), detail (detail level), kvpair_to_str (optional key/value formatter), field_sep (field separator)
 * Returns: none
 */
module ps_edge_site_describe(site, detail=0, kvpair_to_str=undef, field_sep=", ") {
    echo(ps_edge_site_describe_str(site, detail, kvpair_to_str, field_sep));
}

/**
 * Function: Build a description string for a vertex placement site.
 * Params: site (vertex placement site record), detail (detail level), kvpair_to_str (optional key/value formatter), field_sep (field separator)
 * Returns: description string
 */
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

/**
 * Module: Echo a vertex-site description.
 * Params: site (vertex placement site record), detail (detail level), kvpair_to_str (optional key/value formatter), field_sep (field separator)
 * Returns: none
 */
module ps_vertex_site_describe(site, detail=0, kvpair_to_str=undef, field_sep=", ") {
    echo(ps_vertex_site_describe_str(site, detail, kvpair_to_str, field_sep));
}
