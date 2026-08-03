# Placement Data Model

`src/polysymmetrica/core/placement.scad`,
`src/polysymmetrica/core/placement_data.scad`, and sibling core modules use
small list-backed records for placement and proxy replay data.
`placement.scad` owns the site/replay construction logic; `placement_data.scad`
owns the public accessors for the placement-site and proxy record families.
The public contract is the accessor functions, not the numeric list positions.
Treat raw indexing into these records as an implementation detail.

This document describes the semantic model: what the records mean, which
coordinate space each field belongs to, and how they relate to the `$ps_*`
metadata exposed by placement modules.

Each semantic record family also has:

- `ps_*_describe(record, detail=...)` to `echo(...)` a human-readable summary;
- `ps_*_describe_str(record, detail=...)` when a caller needs the string value.

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

- `intrusion record`
  A provenance record for one exact foreign face-plane crossing. It carries the
  target face, foreign source kind/index, 2D cut segment, dihedral metadata,
  and a confidence label.

- `anti-interference shell`
  A mesh record for one filled boundary loop projected between the requested
  `z0`/`z1` planes. It stores the generated polyhedron points/faces plus the
  top/bottom loop projections used to build it.

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
context in mind. For example, `ps_replay_site_frame(site)` is the replay
placement frame in the current target face-local frame, while
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

Describe example:

```scad
place_on_faces(poly, indices = 0)
    ps_placement_frame_describe($ps_face_frame, detail = 1);
```

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

Describe example:

```scad
place_on_faces(poly, indices = 0)
    ps_target_local_poly_context_describe($ps_target_local_poly_context, detail = 1);
```

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

Describe example:

```scad
place_on_faces(poly, indices = 0)
    ps_face_local_context_describe($ps_face_local_context, detail = 1);
```

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
| `ps_face_site_poly_center_local(site)` | Poly center in face-local coordinates, derived from the nested face-local context. |
| `ps_face_site_pts2d(site)` | Face loop in face-local XY coordinates, derived from the nested face-local context. |
| `ps_face_site_pts3d_local(site)` | Face loop in face-local XYZ coordinates, derived from the nested face-local context. |
| `ps_face_site_poly_verts_local(site)` | All poly vertices in face-local coordinates, derived from the nested face-local context. |
| `ps_face_site_poly_faces_idx(site)` | Source poly face index loops, derived from the nested face-local context. |
| `ps_face_site_target_local_poly_context(site)` | Target-local context derived from this face site. |
| `ps_face_site_face_local_context(site)` | Stored face-local context for this face site. |
| `ps_face_site_planarity_err(site)` | Maximum local-Z deviation from the face plane. |
| `ps_face_site_is_planar(site)` | Planarity flag from the placement tolerance. |
| `ps_face_site_family_id(site)` | Classification family id, or `undef`. |
| `ps_face_site_face_family_count(site)` | Number of face families, or `undef`. |
| `ps_face_site_edge_family_count(site)` | Number of edge families, or `undef`. |
| `ps_face_site_vertex_family_count(site)` | Number of vertex families, or `undef`. |
| `ps_face_site_neighbors_idx(site)` | Adjacent face index per source face edge, derived from the nested face-local context. |
| `ps_face_site_dihedrals(site)` | Dihedral metadata per source face edge, derived from the nested face-local context. |

`place_on_faces(...)` exposes the same semantic data as `$ps_face_*`,
`$ps_face_frame`, `$ps_face_local_context`, `$ps_target_local_poly_context`,
`$ps_poly_*`, and family-count variables. The accessor layer is the function
form of that public metadata contract. `ps_face_sites(...)` appends a
`ps_placement_frame(...)` tail element to each site record; the stored frame
is the primary placement contract, and the center/axis accessors derive from
it. The stored face-local context is the next-level shared object for nested
face helpers; the face-local geometry/topology accessors are derived from that
context rather than duplicated in the outer site record.

Describe example:

```scad
site = ps_face_sites(poly)[0];
ps_face_site_describe(site, detail = 1);
```

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

For edge-owned CSG regions, `polysymmetrica/core/edge_regions.scad` provides
`ps_edge_region_shells(...)` and `ps_edge_region_volume(...)`. These derive
edge-region atom shells from the adjacent faces' filled boundary spans, then
emit them in the same edge-local frame: X follows the edge and Z follows the
adjacent-face normal bisector. For placement-driven edge volumes, call
`place_on_edges(..., edge_regions = true)` and then use
`ps_current_edge_region_shells(...)` or `ps_current_edge_region_volume(...)`
inside the child block; `place_on_edges(...)` precomputes the shared context
once for that loop. For custom loops or explicit context reuse, build
`ps_edge_region_context(...)` once and call
`ps_edge_region_shells_from_context(...)` or
`ps_edge_region_volume_from_context(...)`. The one-off functions are
convenience wrappers for isolated edges.

Describe example:

```scad
site = ps_edge_sites(poly)[0];
ps_edge_site_describe(site, detail = 1);
```

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
| `ps_vertex_site_neighbors_idx(site)` | Adjacent vertex indices. Closed vertex fans use cyclic order anchored at the lowest neighbour index; boundary or partial proxy/replay sites use edge-scan order. |
| `ps_vertex_site_neighbor_pts_local(site)` | Adjacent vertex positions in vertex-local coordinates, aligned with `ps_vertex_site_neighbors_idx(site)`. |
| `ps_vertex_site_vertex_figure(site)` | Abstract vertex figure record for closed simple vertex fans, or `undef` for boundary, singular, or partial replay sites. |
| `ps_vertex_site_family_id(site)` | Classification family id, or `undef`. |
| `ps_vertex_site_face_family_count(site)` | Number of face families, or `undef`. |
| `ps_vertex_site_edge_family_count(site)` | Number of edge families, or `undef`. |
| `ps_vertex_site_vertex_family_count(site)` | Number of vertex families, or `undef`. |

`ps_vertex_sites(...)` appends a stored `ps_placement_frame(...)` tail element
to each site record. `place_on_vertices(...)` exposes the same semantic data as
`$ps_vertex_*` and `$ps_vertex_frame`; center/axis accessors derive from the
stored frame.

The vertex figure is an abstract/topological object. Its vertices are the
source edges incident to the placement vertex, its sides are the incident source
faces, and its neighbour list records the adjacent source vertices in the same
cyclic order. It is not a metric cross-section through the vertex.

To draw the current vertex figure inside `place_on_vertices(...)`, use
`ps_current_vertex_figure_points2d(...)` from `core/vertex.scad`:

```scad
use <polysymmetrica/core/placement.scad>
use <polysymmetrica/core/vertex.scad>

place_on_vertices(poly, inter_radius = 30)
    linear_extrude(height = 0.4)
        polygon(points = ps_current_vertex_figure_points2d(
            t = 0.3,
            cap_mode = "planar_edge_fraction"
        ));
```

The helper asserts if the current vertex has no closed simple
`$ps_vertex_figure`, so boundary and singular fallback vertices do not silently
produce edge-scan polygons. It relies on current OpenSCAD development-snapshot
placement special-variable semantics.

Describe example:

```scad
site = ps_vertex_sites(poly)[0];
ps_vertex_site_describe(site, detail = 1);
```

## Replay Site Records

Replay sites are built by:

```scad
ps_face_foreign_face_replay_sites(...)
ps_face_foreign_proxy_replay_sites(...)
ps_proxy_volume_group_face_replay_sites(...)
```

Internally, replay builders should pass a `ps_target_local_poly_context(...)`
through the call graph once the current target face frame is established.
Nested helpers should avoid unpacking and repacking the target poly fields.

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
| `ps_replay_site_frame(site)` | Replay placement frame in target face-local coordinates. |
| `ps_replay_site_center_local(site)` | Replay origin derived from `ps_replay_site_frame(site)`. |
| `ps_replay_site_ex_local(site)` | Replay X axis derived from `ps_replay_site_frame(site)`. |
| `ps_replay_site_ey_local(site)` | Replay Y axis derived from `ps_replay_site_frame(site)`. |
| `ps_replay_site_ez_local(site)` | Replay Z axis derived from `ps_replay_site_frame(site)`. |
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

`place_on_face_foreign_proxy_sites(...)` exposes both `$ps_proxy_*` and
`$ps_replay_*` aliases for replay metadata. For foreign vertex proxy sites, the
vertex-specific fields include:

| Variable | Meaning |
| --- | --- |
| `$ps_proxy_vertex_valence`, `$ps_replay_vertex_valence` | Number of incident source edges for the foreign vertex, or `undef` when the current proxy site is not a vertex. |
| `$ps_proxy_vertex_neighbors_idx`, `$ps_replay_vertex_neighbors_idx` | Adjacent source vertex indices for the foreign vertex, or `undef`. Closed vertex fans use cyclic order anchored at the lowest neighbour index; boundary or singular replay sites use edge-scan order. |
| `$ps_proxy_vertex_neighbor_pts_local`, `$ps_replay_vertex_neighbor_pts_local` | Adjacent vertex positions in replayed vertex-local coordinates, aligned with the corresponding neighbour index list, or `undef`. |
| `$ps_proxy_vertex_figure`, `$ps_replay_vertex_figure` | Abstract vertex figure record for a closed simple foreign vertex fan, or `undef` for non-vertex, boundary, singular, or partial replay sites. |
| `$ps_proxy_vertex_figure_faces_idx`, `$ps_replay_vertex_figure_faces_idx` | Incident face indices from the abstract vertex figure, or `undef`. |
| `$ps_proxy_vertex_figure_edges_idx`, `$ps_replay_vertex_figure_edges_idx` | Incident edge indices from the abstract vertex figure, or `undef`. |
| `$ps_proxy_vertex_figure_neighbors_idx`, `$ps_replay_vertex_figure_neighbors_idx` | Adjacent vertex indices from the abstract vertex figure, or `undef`. |

When `coords="element"` and the selected child is a foreign vertex child, the
same abstract vertex figure is also mirrored into the normal vertex placement
variables: `$ps_vertex_figure`, `$ps_vertex_figure_faces_idx`,
`$ps_vertex_figure_edges_idx`, and `$ps_vertex_figure_neighbors_idx`, so
`ps_current_vertex_figure_points(...)` and
`ps_current_vertex_figure_points2d(...)` work there too.

When proxy replay runs in parent coordinates, the normal `$ps_vertex_*`
placement variables are not rebound. Use the lower-level
`ps_vertex_figure_points_local(...)` with `$ps_proxy_vertex_neighbor_pts_local`
or `$ps_replay_vertex_neighbor_pts_local`, plus the corresponding
`$ps_proxy_poly_center_local` or `$ps_replay_poly_center_local`, when you need
to realize a foreign vertex polygon in that parent-coordinate context.

The internal proxy replay builder also seeds private candidate records with the
kind string `"face_plane_cut_candidate"` when it derives edge/vertex provenance
from an exact face intrusion. Those candidates are helper records, not a public
record family, and they intentionally reuse the same intrusion accessors once
they are converted into replay sites.

Describe example:

```scad
place_on_faces(poly, indices = target_face_idx)
    ps_replay_site_describe(
        ps_face_foreign_face_replay_sites(
            $ps_face_pts2d,
            $ps_face_idx,
            $ps_target_local_poly_context
        )[0],
        detail = 1
    );
```

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

Describe example:

```scad
place_on_faces(poly, indices = target_face_idx)
    place_on_face_foreign_proxy_volume_groups()
        ps_proxy_volume_group_describe($ps_proxy_volume_group_record, detail = 1);
```

## Intrusion Records

Intrusion records are built by:

```scad
records = ps_face_foreign_intrusion_records(...);
```

They are consumed by:

```scad
place_on_face_foreign_intrusions(...);
ps_face_foreign_proxy_replay_sites(...);
ps_face_foreign_proxy_volume_groups(...);
```

Accessors:

| Accessor | Meaning |
| --- | --- |
| `ps_intrusion_kind(record)` | Record kind string, currently `"face_plane_cut"`. |
| `ps_intrusion_target_face_idx(record)` | Target face index receiving the intrusion. |
| `ps_intrusion_foreign_kind(record)` | Foreign source kind, currently `"face"`. |
| `ps_intrusion_foreign_idx(record)` | Foreign source index. |
| `ps_intrusion_segment2d_local(record)` | Target-local 2D cut segment. |
| `ps_intrusion_dihedral(record)` | Face-plane cut dihedral metadata. |
| `ps_intrusion_confidence(record)` | Confidence string, currently `"exact"`. |

Intrusion records are exact provenance records. They are intentionally not
expanded into a solid here; replay and proxy volume grouping are later stages
that decide how much geometry to emit from the same source record.

Describe example:

```scad
place_on_faces(poly, indices = target_face_idx)
    place_on_face_foreign_intrusions()
        ps_intrusion_describe($ps_intrusion_record, detail = 1);
```

## Loop Shell Records

Generic loop shell records are built by adapters such as:

```scad
shells = ps_face_region_loop_shells(...);
```

They are consumed by:

```scad
ps_face_region_loop_volume(...);
ps_loop_shell(shell);
```

Accessors:

| Accessor | Meaning |
| --- | --- |
| `ps_loop_shell_points(shell)` | Generated shell points. |
| `ps_loop_shell_faces(shell)` | Generated shell faces. |
| `ps_loop_shell_source_kind(shell)` | Caller-owned source family, such as `"face_region"`. |
| `ps_loop_shell_source_idx(shell)` | Caller-owned source index. |
| `ps_loop_shell_lineage(shell)` | Caller-owned lineage rows. |
| `ps_loop_shell_capped_count(shell)` | Number of projected spans capped during shell construction. |
| `ps_loop_shell_z0(shell)` | Actual lower shell Z bound after any caller-specific clipping. |
| `ps_loop_shell_z1(shell)` | Actual upper shell Z bound after any caller-specific clipping. |
| `ps_loop_shell_bottom_loop2d(shell)` | Bottom cap loop at `ps_loop_shell_z0(shell)`. |
| `ps_loop_shell_top_loop2d(shell)` | Top cap loop at `ps_loop_shell_z1(shell)`. |
| `ps_loop_shell_exposure_sign(shell)` | `+1` for same- or zero-winding/top-exposed regions, `-1` for opposite-winding/bottom-exposed regions. |

Shell records are mesh outputs, not canonical source records. They should be
treated as derived geometry that can be regenerated from the face-local
context. Face-region/A.I. shells are positive admissible geometry.

Describe example:

```scad
place_on_faces(poly, indices = 0)
    place_on_face_seam_clearance_shells(-0.4, 0.6)
        ps_loop_shell_describe($ps_loop_shell_record, detail = 1);
```

## Arrangement And Boundary-Model Composites

The following helper outputs are structurally important but are not yet treated
as stable semantic records with dedicated accessors:

- `ps_face_arrangement(face_pts3d_local, eps)` returns
  `[face_pts2d, crossings, nodes, spans, cells]`.
- `ps_face_boundary_model(face_pts3d_local, mode, eps)` returns
  `[mode, filled_cell_ids, boundary_loops, boundary_spans]`.
- `ps_face_filled_boundary_source_edges(face_pts3d_local, mode, eps)` returns
  `[[source_edge_idx, source_seg2d, source_boundary_spans], ...]`.

These are best understood as composite helper outputs: the structure is stable
enough for the current algorithms, but the project does not yet treat them as a
first-class record family in the same way as placement frames, contexts, sites,
replay records, or proxy volume groups. If they later become reusable records,
they should get dedicated constructor/accessor functions and their own doc
section.

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

Describe example:

```scad
place_on_faces(poly, indices = target_face_idx)
    ps_boundary_span_site_describe(
        _ps_face_boundary_span_sites(
            $ps_face_pts3d_local,
            $ps_face_idx,
            $ps_poly_faces_idx,
            $ps_poly_verts_local,
            $ps_face_neighbors_idx,
            $ps_face_dihedrals
        )[0],
        detail = 1
    );
```

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
foreign face-plane cuts. The seam frame canonicalizes segment direction so
`+Y` is the current target face side: the current target face normal has
non-negative seam-local `Y`. `+X` therefore follows the seam segment but does
not promise to preserve the raw source endpoint order.

The seam record stores a `ps_placement_frame(...)` in slot 1. The
`center_local`/`ex_local`/`ey_local`/`ez_local` accessors derive from that
stored frame rather than from separate scalar frame fields.

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

Describe example:

```scad
place_on_faces(poly, indices = target_face_idx)
    ps_seam_site_describe(
        ps_face_seam_segment_sites($ps_face_local_context)[0],
        detail = 1
    );
```

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
- raw indexing is only acceptable inside the constructor or accessor that owns
  the record layout.

Raw list positions may change as the data model evolves. Accessors are the
stable compatibility surface.

## Record Boundaries

Not every list-shaped value in the codebase is a semantic record. Plain vertex
lists, edge loops, face loops, arrangement cells, and other local geometry
tuples remain free to use positional indexing when that is the natural
representation. The audit target is the list-backed values that cross helper or
module boundaries with stable meaning: placement frames, contexts, sites,
replay/proxy records, boundary spans, seam segments, intrusion records, and
anti-interference shells.

## Known Remediation Candidates

The audit has identified a few record-shape issues that should be tracked for
later cleanup rather than silently papered over:

- Replay sites still carry both their own frame fields and embedded canonical
  face/edge/vertex site records. This is a deliberate compatibility bridge, but
  it is a candidate for future deduplication once callers have fully moved to
  the accessors.
- Boundary span and seam segment sites expose frame-derived center/axis fields
  alongside their stored frame record. Boundary spans already store the frame
  directly; seam segments now do too, so these records are in the preferred
  shape. If any future helper reintroduces separate scalar frame fields, it
  should be folded back to the frame subrecord pattern.
- Face site records still store both the target-local context record and the
  face-local context record. This is useful for nested helpers today, but the
  duplication should be reassessed if the call graph settles on a single
  context object.
