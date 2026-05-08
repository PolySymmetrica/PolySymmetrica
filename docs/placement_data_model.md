# Placement Data Model

`src/polysymmetrica/core/placement.scad` uses small list-backed records for
placement and proxy replay data. The public contract is the accessor functions,
not the numeric list positions. Treat raw indexing into these records as an
implementation detail.

This document describes the semantic model: what the records mean, which
coordinate space each field belongs to, and how they relate to the `$ps_*`
metadata exposed by placement modules.

## Definitions

- `placement frame`
  A semantic frame record `[center, ex, ey, ez]`.
  `center` is the child origin in the parent coordinate system. `ex`, `ey`, and
  `ez` are the local unit axes expressed in the parent coordinate system.
  Use `ps_placement_frame_matrix(frame)` to turn it into a `multmatrix(...)`
  transform.

- `site`
  A canonical placement target record for one face, edge, or vertex. Site
  records are built by `ps_face_sites(...)`, `ps_edge_sites(...)`, and
  `ps_vertex_sites(...)`. Each site record stores a compact semantic payload
  plus a trailing `ps_placement_frame(...)` subrecord. The `center`/`ex`/`ey`/
  `ez` accessors are derived from that frame and are not separate stored site
  fields.

- `target-local poly context`
  A compact record for "the whole source poly, but expressed in the current
  target frame": `[poly_faces_idx, poly_verts_local, poly_center_local]`.
  This is used by nested replay/proxy code when it needs to reconstruct a
  foreign face/edge/vertex frame inside an already placed target face.

- `face-local context`
  A compact record for "the current face plus the whole source poly, expressed
  in the current face frame": `[face_pts3d_local, face_pts2d, face_idx,
  target_ctx, face_neighbors_idx, face_dihedrals]`. This is the preferred
  argument shape for nested face iterators.

- `replay site`
  A proxy/interference record that points at a foreign face, edge, or vertex and
  provides the foreign element's frame in the current target face-local
  coordinate system.

- `volume group`
  A provenance record grouping exact foreign face intrusions by source topology
  connectivity. It describes implicated source faces/edges/vertices; it is not
  itself a closed solid.

## Coordinate Spaces

The placement layer uses three recurring spaces:

- `parent coordinates`
  The coordinate system in which a site is placed. For top-level
  `place_on_faces(poly)`, this is the caller's current OpenSCAD coordinate
  system.

- `element-local coordinates`
  The child coordinate system after applying a site's placement frame. For a
  face site, this is face-local; for an edge site, edge-local; for a vertex
  site, vertex-local.

- `target face-local coordinates`
  The parent space for nested face-replay/proxy work. When
  `place_on_face_foreign_proxy_sites(...)` is called inside `place_on_faces(...)`,
  all replay frames are rebuilt inside the current target face's local frame.

Variables and accessors ending in `_local` should be read with their immediate
context in mind. For example, `ps_replay_site_center_local(site)` is the replay
origin in the current target face-local frame, while
`ps_face_site_poly_center_local(site)` is the poly center in that face site's
own element-local frame.

## Placement Frames

Use these helpers for generic frame handling:

```scad
frame = ps_placement_frame(center, ex, ey, ez);
matrix = ps_placement_frame_matrix(frame);
```

Accessors:

- `ps_placement_frame_center(frame)`
- `ps_placement_frame_ex(frame)`
- `ps_placement_frame_ey(frame)`
- `ps_placement_frame_ez(frame)`
- `ps_placement_frame_matrix(frame)`

`ps_placement_frame(...)` stores axes as supplied. The caller that constructs a
frame is responsible for making it orthonormal.

## Target-Local Poly Context

Use this when passing the whole source poly through nested geometry code:

```scad
ctx = ps_target_local_poly_context(
    $ps_poly_faces_idx,
    $ps_poly_verts_local,
    $ps_poly_center_local
);
```

Accessors:

- `ps_target_local_poly_context_faces_idx(ctx)`
- `ps_target_local_poly_context_verts_local(ctx)`
- `ps_target_local_poly_context_center_local(ctx)`

If the center is omitted, `ps_target_local_poly_context(...)` stores `[0, 0, 0]`.

## Face-Local Context

Use this when a nested face operation needs the current face geometry plus the
source poly in that face's local coordinate system:

```scad
face_ctx = ps_face_local_context(
    $ps_face_pts3d_local,
    $ps_face_pts2d,
    $ps_face_idx,
    $ps_poly_faces_idx,
    $ps_poly_verts_local,
    $ps_face_neighbors_idx,
    $ps_face_dihedrals,
    $ps_poly_center_local
);
```

Accessors:

- `ps_face_local_context_pts3d_local(ctx)`
- `ps_face_local_context_pts2d(ctx)`
- `ps_face_local_context_idx(ctx)`
- `ps_face_local_context_target_local_poly_context(ctx)`
- `ps_face_local_context_poly_faces_idx(ctx)`
- `ps_face_local_context_poly_verts_local(ctx)`
- `ps_face_local_context_poly_center_local(ctx)`
- `ps_face_local_context_neighbors_idx(ctx)`
- `ps_face_local_context_dihedrals(ctx)`

This record is the preferred argument shape for helpers that operate inside an
existing `place_on_faces(...)` child context. It avoids long argument lists and
keeps the current face, adjacent-face metadata, and target-local poly data
together.

## Face Site Records

Built by:

```scad
sites = ps_face_sites(poly, inter_radius, edge_len, classify, classify_opts);
```

Face site accessors:

| Accessor | Meaning |
| --- | --- |
| `ps_face_site_idx(site)` | Source face index. |
| `ps_face_site_center(site)` | Face center in parent coordinates. |
| `ps_face_site_ex(site)` | Face-local X axis in parent coordinates. |
| `ps_face_site_ey(site)` | Face-local Y axis in parent coordinates. |
| `ps_face_site_ez(site)` | Face-local Z axis in parent coordinates. |
| `ps_face_site_frame(site)` | Stored placement frame for the face. |
| `ps_face_site_edge_len(site)` | Scale edge length used to build the site. |
| `ps_face_site_vertex_count(site)` | Number of vertices in the source face loop. |
| `ps_face_site_midradius(site)` | Distance from parent origin to face center. |
| `ps_face_site_radius(site)` | Mean distance from face center to face vertices. |
| `ps_face_site_poly_center_local(site)` | Poly center in face-local coordinates. |
| `ps_face_site_pts2d(site)` | Face loop in face-local XY coordinates. |
| `ps_face_site_pts3d_local(site)` | Face loop in face-local XYZ coordinates. |
| `ps_face_site_poly_verts_local(site)` | All poly vertices in face-local coordinates. |
| `ps_face_site_poly_faces_idx(site)` | Source poly face index loops. |
| `ps_face_site_target_local_poly_context(site)` | Target-local context derived from this face site. |
| `ps_face_site_face_local_context(site)` | Stored face-local context for this face site. |
| `ps_face_site_planarity_err(site)` | Maximum local-Z deviation from the face plane. |
| `ps_face_site_is_planar(site)` | Planarity flag from the placement tolerance. |
| `ps_face_site_family_id(site)` | Classification family id, or `undef`. |
| `ps_face_site_face_family_count(site)` | Number of face families, or `undef`. |
| `ps_face_site_edge_family_count(site)` | Number of edge families, or `undef`. |
| `ps_face_site_vertex_family_count(site)` | Number of vertex families, or `undef`. |
| `ps_face_site_neighbors_idx(site)` | Adjacent face index per source face edge. |
| `ps_face_site_dihedrals(site)` | Dihedral metadata per source face edge. |

`place_on_faces(...)` exposes the same semantic data as `$ps_face_*`,
`$ps_face_frame`, `$ps_face_local_context`, `$ps_target_local_poly_context`,
`$ps_poly_*`, and family-count variables. The accessor layer is the function
form of that public metadata contract. `ps_face_sites(...)` appends a
`ps_placement_frame(...)` tail element to each site record; the stored frame
is the primary placement contract, and the center/axis accessors derive from
it. The stored face-local context is the next-level shared object for nested
face helpers.

## Edge Site Records

Built by:

```scad
sites = ps_edge_sites(poly, inter_radius, edge_len, classify, classify_opts);
```

Edge site accessors:

| Accessor | Meaning |
| --- | --- |
| `ps_edge_site_idx(site)` | Source edge index. |
| `ps_edge_site_center(site)` | Edge midpoint in parent coordinates. |
| `ps_edge_site_ex(site)` | Edge-local X axis in parent coordinates. |
| `ps_edge_site_ey(site)` | Edge-local Y axis in parent coordinates. |
| `ps_edge_site_ez(site)` | Edge-local Z axis in parent coordinates. |
| `ps_edge_site_frame(site)` | Stored placement frame for the edge. |
| `ps_edge_site_edge_len(site)` | Actual placed edge length. |
| `ps_edge_site_midradius(site)` | Distance from parent origin to edge midpoint. |
| `ps_edge_site_poly_center_local(site)` | Poly center in edge-local coordinates. |
| `ps_edge_site_pts_local(site)` | Edge endpoints in edge-local coordinates. |
| `ps_edge_site_verts_idx(site)` | Source vertex pair for the edge. |
| `ps_edge_site_adj_faces_idx(site)` | Adjacent source face indices. |
| `ps_edge_site_family_id(site)` | Classification family id, or `undef`. |
| `ps_edge_site_face_family_count(site)` | Number of face families, or `undef`. |
| `ps_edge_site_edge_family_count(site)` | Number of edge families, or `undef`. |
| `ps_edge_site_vertex_family_count(site)` | Number of vertex families, or `undef`. |

For closed manifold edges, the edge frame uses the adjacent-face normal bisector
when it can. Boundary or degenerate edges fall back to a radial frame.
`place_on_edges(...)` exposes the same semantic data as `$ps_edge_*` and
`$ps_edge_frame`. `ps_edge_sites(...)` appends a stored
`ps_placement_frame(...)` tail element to each site record; the frame is the
stored source of truth for edge center/axis accessors.

## Vertex Site Records

Built by:

```scad
sites = ps_vertex_sites(poly, inter_radius, edge_len, classify, classify_opts);
```

Vertex site accessors:

| Accessor | Meaning |
| --- | --- |
| `ps_vertex_site_idx(site)` | Source vertex index. |
| `ps_vertex_site_center(site)` | Vertex position in parent coordinates. |
| `ps_vertex_site_ex(site)` | Vertex-local X axis in parent coordinates. |
| `ps_vertex_site_ey(site)` | Vertex-local Y axis in parent coordinates. |
| `ps_vertex_site_ez(site)` | Vertex-local Z axis in parent coordinates. |
| `ps_vertex_site_frame(site)` | Stored placement frame for the vertex. |
| `ps_vertex_site_edge_len(site)` | Scale edge length used to build the site. |
| `ps_vertex_site_radius(site)` | Distance from parent origin to vertex. |
| `ps_vertex_site_poly_center_local(site)` | Poly center in vertex-local coordinates. |
| `ps_vertex_site_valence(site)` | Number of incident source edges. |
| `ps_vertex_site_neighbors_idx(site)` | Adjacent vertex indices. |
| `ps_vertex_site_neighbor_pts_local(site)` | Adjacent vertex positions in vertex-local coordinates. |
| `ps_vertex_site_family_id(site)` | Classification family id, or `undef`. |
| `ps_vertex_site_face_family_count(site)` | Number of face families, or `undef`. |
| `ps_vertex_site_edge_family_count(site)` | Number of edge families, or `undef`. |
| `ps_vertex_site_vertex_family_count(site)` | Number of vertex families, or `undef`. |

`ps_vertex_sites(...)` appends a stored `ps_placement_frame(...)` tail element
to each site record. `place_on_vertices(...)` exposes the same semantic data as
`$ps_vertex_*` and `$ps_vertex_frame`; center/axis accessors derive from the
stored frame.

## Replay Site Records

Replay sites are built by:

```scad
ps_face_foreign_face_replay_sites(...)
ps_face_foreign_proxy_replay_sites(...)
ps_proxy_volume_group_face_replay_sites(...)
```

Internally, replay builders should pass a `ps_target_local_poly_context(...)`
through the call graph once the current target face frame is established. The
public builders still accept the raw `$ps_poly_faces_idx`,
`$ps_poly_verts_local`, and `$ps_poly_center_local` pieces for compatibility,
but nested helpers should avoid unpacking and repacking those three fields.

They are used by:

```scad
place_on_face_foreign_face_replay_sites(...)
place_on_face_foreign_proxy_sites(...)
place_on_face_foreign_proxy_volume_group_faces(...)
```

Replay site accessors:

| Accessor | Meaning |
| --- | --- |
| `ps_replay_site_idx(site)` | Zero-based replay site index. |
| `ps_replay_site_intrusion_record(site)` | Source foreign intrusion record. |
| `ps_replay_site_center_local(site)` | Replay origin in target face-local coordinates. |
| `ps_replay_site_ex_local(site)` | Replay X axis in target face-local coordinates. |
| `ps_replay_site_ey_local(site)` | Replay Y axis in target face-local coordinates. |
| `ps_replay_site_ez_local(site)` | Replay Z axis in target face-local coordinates. |
| `ps_replay_site_foreign_idx(site)` | Foreign element index. |
| `ps_replay_site_foreign_kind(site)` | `"face"`, `"edge"`, or `"vertex"`. |
| `ps_replay_site_face_pts2d(site)` | Foreign face loop in replay-local XY, or `undef`. |
| `ps_replay_site_face_pts3d_local(site)` | Foreign face loop in replay-local XYZ, or `undef`. |
| `ps_replay_site_poly_verts_local(site)` | All poly vertices in replay-local coordinates. |
| `ps_replay_site_poly_center_local(site)` | Poly center in replay-local coordinates. |
| `ps_replay_site_face_verts_idx(site)` | Foreign face vertex index loop, or `undef`. |
| `ps_replay_site_intrusion_segment2d_local(site)` | Target-local cut segment. |
| `ps_replay_site_intrusion_dihedral(site)` | Face-plane cut dihedral. |
| `ps_replay_site_intrusion_confidence(site)` | Confidence/classification string. |
| `ps_replay_site_face_site(site)` | Canonical face site, or `undef`. |
| `ps_replay_site_edge_site(site)` | Canonical edge site, or `undef`. |
| `ps_replay_site_vertex_site(site)` | Canonical vertex site, or `undef`. |

The embedded canonical site is present only for the matching foreign kind. For
example, a replay site with `ps_replay_site_foreign_kind(site) == "edge"` has an
edge site at `ps_replay_site_edge_site(site)` and `undef` for face/vertex sites.

With `coords="element"`, replay modules transform children by the embedded
site's frame and expose the usual face/edge/vertex `$ps_*` metadata for that
foreign source kind. With `coords="parent"`, children remain in the current
target face-local frame and should use the `$ps_replay_*` or `$ps_proxy_*`
metadata directly.

## Proxy Volume Group Records

Built by:

```scad
groups = ps_face_foreign_proxy_volume_groups(...);
```

Accessors:

| Accessor | Meaning |
| --- | --- |
| `ps_proxy_volume_group_kind(group)` | `"foreign_proxy_volume_group"`. |
| `ps_proxy_volume_group_target_face_idx(group)` | Target face affected by the group. |
| `ps_proxy_volume_group_idx(group)` | Zero-based group index. |
| `ps_proxy_volume_group_face_idxs(group)` | Connected exact foreign face ids. |
| `ps_proxy_volume_group_record_idxs(group)` | Positions of exact intrusion records used by the group. |
| `ps_proxy_volume_group_records(group)` | Exact intrusion records in the group. |
| `ps_proxy_volume_group_edge_idxs(group)` | Source edge ids from grouped exact foreign faces. |
| `ps_proxy_volume_group_vertex_idxs(group)` | Source vertex ids from grouped exact foreign faces. |
| `ps_proxy_volume_group_support_face_idxs(group)` | Adjacent non-seed source faces that may help later volume construction. |

Volume groups intentionally do not define arbitrary user geometry. They are a
provenance and grouping layer that later render/replay code can use to decide
which foreign faces, edges, vertices, or conservative hulls to emit.
As with replay sites, internal volume-group builders should receive the
target-local poly context directly and use its accessors when they need source
topology or target-local vertex positions. When a face site is already in
hand, prefer the stored face-local context and its nested target-local context
rather than rebuilding them from sibling fields.

## Boundary Span Site Records

Boundary span sites are built internally by:

```scad
sites = _ps_face_boundary_span_sites(...);
```

They are consumed by:

```scad
place_on_face_boundary_spans(...);
ps_face_seam_segment_sites(...);
```

Boundary span sites describe one oriented span of the current face's filled
boundary in current face-local coordinates. They carry both the planar boundary
span and the adjacent-face/dihedral metadata inherited from the original source
edge.

Accessors:

| Accessor | Meaning |
| --- | --- |
| `ps_boundary_span_site_idx(site)` | Zero-based boundary span site index. |
| `ps_boundary_span_site_center_local(site)` | Span midpoint in current face-local coordinates. |
| `ps_boundary_span_site_ex_local(site)` | Span-local X axis in current face-local coordinates. |
| `ps_boundary_span_site_ey_local(site)` | Span-local Y axis in current face-local coordinates. |
| `ps_boundary_span_site_ez_local(site)` | Span-local Z axis in current face-local coordinates. |
| `ps_boundary_span_site_frame(site)` | Placement frame for the span, expressed in current face-local coordinates. |
| `ps_boundary_span_site_len(site)` | Span length. |
| `ps_boundary_span_site_segment2d_local(site)` | Oriented 2D span in current face-local XY coordinates. |
| `ps_boundary_span_site_loop_idx(site)` | Filled-boundary loop index containing the span. |
| `ps_boundary_span_site_source_edge_idx(site)` | Current-face source edge index, or `undef`. |
| `ps_boundary_span_site_source_t0(site)` | Source-edge parameter at the oriented span start. |
| `ps_boundary_span_site_source_t1(site)` | Source-edge parameter at the oriented span end. |
| `ps_boundary_span_site_raw_kind(site)` | Lower-level arrangement lineage such as `"source"`. |
| `ps_boundary_span_site_filled_cell_idx(site)` | Filled arrangement cell beside the span, or `undef`. |
| `ps_boundary_span_site_other_cell_idx(site)` | Opposite/non-filled arrangement cell beside the span, or `undef`. |
| `ps_boundary_span_site_adj_face_idx(site)` | Adjacent source face inherited from the source edge, or `undef`. |
| `ps_boundary_span_site_dihedral(site)` | Source-edge dihedral metadata, or `undef`. |
| `ps_boundary_span_site_adj_face_normal_local(site)` | Adjacent face normal in current face-local coordinates, or `undef`. |
| `ps_boundary_span_site_filled_side(site)` | `+1` when filled area is on the span's left, `-1` on its right, `0` for ambiguous/degenerate spans. |
| `ps_boundary_span_site_adj_face_dir_span_local(site)` | Adjacent face plane direction in span-local coordinates, oriented toward current face-local `+Z`. |
| `ps_boundary_span_site_kind(site)` | Public lineage: `"source_edge"`, `"source_partial"`, or `"generated_cut"`. |
| `ps_boundary_span_site_is_generated(site)` | True when kind is not `"source_edge"`. |

The span frame convention is:

- `+X` follows `ps_boundary_span_site_segment2d_local(site)`.
- `+Y` is the in-face left normal of that span.
- `+Z` is current face-local `+Z`.

Use `ps_placement_frame_matrix(ps_boundary_span_site_frame(site))` when placing
children manually.

## Seam Segment Site Records

Seam segment sites are built by:

```scad
sites = ps_face_seam_segment_sites(...);
```

They are consumed by:

```scad
place_on_face_seam_segments(...);
```

Seam sites are edge-like records expressed in the current target face-local
coordinate system. They can come from filled-boundary spans or from exact
foreign face-plane cuts.

Accessors:

| Accessor | Meaning |
| --- | --- |
| `ps_seam_site_idx(site)` | Zero-based seam site index. |
| `ps_seam_site_center_local(site)` | Seam midpoint in target face-local coordinates. |
| `ps_seam_site_ex_local(site)` | Seam-local X axis in target face-local coordinates. |
| `ps_seam_site_ey_local(site)` | Seam-local Y axis in target face-local coordinates. |
| `ps_seam_site_ez_local(site)` | Seam-local Z axis in target face-local coordinates. |
| `ps_seam_site_frame(site)` | Placement frame for the seam, expressed in target face-local coordinates. |
| `ps_seam_site_len(site)` | Seam length. |
| `ps_seam_site_edge_pts_local(site)` | Edge-like seam endpoints in seam-local coordinates. |
| `ps_seam_site_segment2d_local(site)` | Source seam segment in target face-local XY. |
| `ps_seam_site_source(site)` | `"boundary"` or `"foreign"`. |
| `ps_seam_site_source_kind(site)` | Boundary span kind or intrusion kind. |
| `ps_seam_site_foreign_kind(site)` | Foreign source kind, or `undef`. |
| `ps_seam_site_foreign_idx(site)` | Foreign source index, or `undef`. |
| `ps_seam_site_dihedral(site)` | Dihedral metadata when known. |
| `ps_seam_site_confidence(site)` | Confidence metadata such as `"exact"`. |
| `ps_seam_site_record(site)` | Boundary span site or intrusion record used as source data. |
| `ps_seam_site_foreign_normal_local(site)` | Foreign normal in target face-local coordinates, or `undef`. |
| `ps_seam_site_support_kind(site)` | Printable support classification. |
| `ps_seam_site_support_reason(site)` | Reason for the support classification. |
| `ps_seam_site_current_normal_seam_local(site)` | Current target face normal expressed in the seam frame. |
| `ps_seam_site_is_support_candidate(site)` | True when support kind is not `"none"`. |

`place_on_face_seam_segments(coords="element")` uses
`ps_placement_frame_matrix(ps_seam_site_frame(site))` to place children in the
seam frame. It also exposes edge-compatible aliases such as `$ps_edge_len`,
`$ps_edge_pts_local`, and `$ps_edge_adj_faces_idx` so simple edge child modules
can be reused on generated seams.

## Accessor Rule

When adding code that consumes any of these records:

- use the named accessor functions;
- pass `ps_placement_frame_matrix(ps_*_site_frame(site))` to `multmatrix(...)`
  instead of rebuilding a matrix from raw list positions;
- pass `ps_target_local_poly_context(...)` when a nested builder needs the whole
  source poly in the current target-local frame;
- pass `ps_face_local_context(...)` when a nested builder needs current-face
  points, face id, neighboring faces, dihedrals, and the target-local poly;
- do not compare or persist family ids across independently computed
  classifications.

Raw list positions may change as the data model evolves. Accessors are the
stable compatibility surface.
