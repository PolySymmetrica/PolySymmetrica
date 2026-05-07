# Proxy Interaction

Proxy interaction is the punch-through layer that replays deliberate proxy
geometry for foreign placement sites. It exists because OpenSCAD cannot inspect
arbitrary geometry after a child module has emitted it.

## Contract

Use `place_on_face_foreign_proxy_sites(...)` inside `place_on_faces(...)`:

```scad
place_on_faces(poly) {
    if ($ps_face_idx == target_face_idx) {
        difference() {
            my_target_face_geometry();

            place_on_face_foreign_proxy_sites() {
                my_foreign_face_proxy();   // child slot 0
                my_foreign_edge_proxy();   // child slot 1, reserved
                my_foreign_vertex_proxy(); // child slot 2, reserved
            }
        }
    }
}
```

The module dispatches to child slots by source kind:

- `face_child=0` receives foreign face proxy callbacks.
- `edge_child=1` receives foreign edge proxy callbacks.
- `vertex_child=2` receives foreign vertex proxy callbacks.

Foreign face callbacks are exact face-plane intrusions. Foreign edge and vertex
callbacks are conservative provenance-driven candidates derived from those face
intrusions: they identify source edges and vertices implicated by a known
punch-through. For each exact intruding face, all of its boundary edges and
vertices are emitted as candidates, then deduplicated by source kind/index.
They are not distance/proximity envelope tests.

## Coordinate Modes

`coords="element"` is the default. Children run in the replayed foreign site
frame, transformed into the current target face-local coordinate system. This is
the normal mode for proxy bodies authored like placement children.

`coords="parent"` leaves children in the target face-local coordinate system.
Use this for debugging or for manually applying `$ps_proxy_center_local` and the
`$ps_proxy_*_local` axes.

## Metadata

Each callback exposes:

- `$ps_proxy_idx`, `$ps_proxy_count`
- `$ps_proxy_kind`
- `$ps_proxy_source_kind`, `$ps_proxy_source_idx`
- `$ps_proxy_target_face_idx`, `$ps_proxy_child_idx`
- `$ps_proxy_center_local`, `$ps_proxy_ex_local`, `$ps_proxy_ey_local`, `$ps_proxy_ez_local`
- `$ps_proxy_intrusion_record`, `$ps_proxy_intrusion_segment2d_local`, `$ps_proxy_intrusion_dihedral`, `$ps_proxy_intrusion_confidence`
- `$ps_proxy_face_pts2d`, `$ps_proxy_face_pts3d_local`, `$ps_proxy_face_verts_idx`
- `$ps_proxy_edge_pts_local`, `$ps_proxy_edge_verts_idx`, `$ps_proxy_edge_adj_faces_idx`
- `$ps_proxy_vertex_valence`, `$ps_proxy_vertex_neighbors_idx`, `$ps_proxy_vertex_neighbor_pts_local`
- `$ps_proxy_poly_verts_local`, `$ps_proxy_poly_center_local`

The corresponding `$ps_replay_*` variables are also exposed for compatibility
with the lower-level replay iterator.

With `coords="element"`, the child also receives the normal placement context
for its source kind:

- face callbacks expose the usual `$ps_face_*` variables;
- edge callbacks expose the usual `$ps_edge_*` variables;
- vertex callbacks expose the usual `$ps_vertex_*` variables.

## Responsibilities

The proxy child must emit the boolean body that represents possible collision
from that foreign source. For reliable later subtraction, that body should be
closed and deliberately oversized/toleranced where appropriate.

The library only identifies and positions replay contexts. It cannot discover
already-rendered arbitrary geometry, and it does not infer a closed punch-through
body from filtered face-plane cut segments.

## Volume Group Records

`ps_face_foreign_proxy_volume_groups(...)` and
`place_on_face_foreign_proxy_volume_groups(...)` provide a first-pass,
data-only view of possible solid punch-through groups. They group exact
foreign face intrusions by source-topology connectivity: if two exact intruding
source faces share an original source edge, they are reported in the same group.

Volume groups are provenance records, not generated geometry. They are intended
as the stable data layer for later optional volume replay, and for callers that
want to inspect which source faces/edges/vertices are implicated before deciding
what body to subtract.

Each volume-group record exposes:

- `ps_proxy_volume_group_kind(group)`: `"foreign_proxy_volume_group"`
- `ps_proxy_volume_group_target_face_idx(group)`: target face being affected
- `ps_proxy_volume_group_idx(group)`: zero-based group index
- `ps_proxy_volume_group_face_idxs(group)`: connected exact foreign face ids
- `ps_proxy_volume_group_record_idxs(group)`: positions of the exact intrusion records used by the group
- `ps_proxy_volume_group_records(group)`: the exact intrusion records themselves
- `ps_proxy_volume_group_edge_idxs(group)`: source edge ids from grouped exact foreign faces
- `ps_proxy_volume_group_vertex_idxs(group)`: source vertex ids from grouped exact foreign faces
- `ps_proxy_volume_group_support_face_idxs(group)`: adjacent non-seed source faces that may help future volume construction

The iterator form runs in the current target face-local frame and exposes the
same fields as `$ps_proxy_volume_group_*` variables. It also exposes the generic
aliases `$ps_proxy_kind="foreign_volume_group"`,
`$ps_proxy_source_kind="volume_group"`, `$ps_proxy_source_idx`, and
`$ps_proxy_target_face_idx`.

`place_on_face_foreign_proxy_volume_group_faces(...)` is the renderable face-unit
iterator for the same data. It visits each exact intruding face in each group,
runs child slot 0 in that source-face frame by default, and also exposes the
group metadata above. Slot 0 receives face-compatible `$ps_proxy_*` variables, so
the face child from a `place_on_face_foreign_proxy_sites(...)` proxy body can
usually be reused unchanged:

```scad
place_on_face_foreign_proxy_volume_group_faces() {
    color(example_color($ps_proxy_volume_group_idx))
        my_foreign_face_proxy();   // child slot 0
        my_foreign_edge_proxy();   // child slot 1, ignored here
        my_foreign_vertex_proxy(); // child slot 2, ignored here
}
```

This renders grouped face planes, not the filled solid between those planes.
Closed proxy-cell volume construction is a later layer.

`place_on_face_foreign_proxy_volume_group_hulls(...)` is a debug/conservative
step beyond face-unit replay. It emits one convex hull per group, using the
grouped source-face vertices in the current target face-local frame:

```scad
color("mediumseagreen", 0.18)
    place_on_face_foreign_proxy_volume_group_hulls();
```

The hull iterator exposes the same `$ps_proxy_volume_group_*` metadata, plus
`$ps_proxy_volume_hull_vertex_idxs`,
`$ps_proxy_volume_hull_vertex_count`, `$ps_proxy_volume_hull_vertex_idx`, and
`$ps_proxy_volume_hull_vertex_pos_local` when a child point primitive is
provided. It deliberately convexifies each group, so it can over-subtract
concave groups, disconnected user geometry, or detailed proxy features. Treat it
as inspection/tooling, not as the exact punch-through cell model.

`examples/printing/face_plate.scad` exposes this as the opt-in printable wrapper
`face_plate_minus_foreign_proxy_volume_group_hulls(...)`. It is just
`face_plate(...)` minus the conservative group hulls, and has the same
over-subtraction caveat as the hull iterator. When explicit face/poly overrides
are passed, both the positive plate body and the subtractive hulls are computed
from those same overrides.

## Printable Face Plates

For exact caller-supplied proxy subtraction, keep the proxy bodies explicit:

```scad
place_on_faces(poly) {
    if ($ps_face_idx == target_face_idx) {
        difference() {
            face_plate(face_thk = face_thk);

            place_on_face_foreign_proxy_sites() {
                my_foreign_face_proxy();   // child slot 0
                my_foreign_edge_proxy();   // child slot 1
                my_foreign_vertex_proxy(); // child slot 2
            }
        }
    }
}
```

For automatic best-effort volume removal, use the conservative grouped-hull
wrapper:

```scad
place_on_faces(poly) {
    if ($ps_face_idx == target_face_idx) {
        face_plate_minus_foreign_proxy_volume_group_hulls(
            face_thk = 1.2,
            mode = "nonzero"
        );
    }
}
```

`face_plate_minus_foreign_proxy_volume_group_hulls(...)` is the current opt-in
wrapper for automatically subtracting conservative grouped hulls. Keep using the
explicit pattern when the proxy body must preserve user-authored detail.
