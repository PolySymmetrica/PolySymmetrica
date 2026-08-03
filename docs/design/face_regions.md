# Face Regions

`core/face_regions.scad` builds positive, face-local regions from the filled
boundary model in `segments.scad`. The first use is anti-interference: instead
of cutting away material with overlapping cutter strips, generate the volume
that is allowed to exist and intersect user geometry with it.

## Definitions

- **Boundary span:** One directed segment from `ps_face_boundary_model(...)`,
  after the face loop has been split at self-crossings and filtered by a fill
  rule.
- **Filled side:** The side of a boundary span occupied by the selected fill
  region; `+1` is left of the directed span and `-1` is right.
- **Span frame:** A local frame for one boundary span: `+X` along the span,
  `+Y` to the span-left side in the face plane, and `+Z` along the current
  face frame normal.
- **Loop shell:** A generic closed polyhedron record from
  `core/loop_shells.scad`, with shared `ps_loop_shell_*` accessors and a
  `ps_loop_shell(...)` renderer.
- **Anti-interference shell:** A positive face-region loop shell made by projecting each
  boundary span to two face-local Z planes along its dihedral-bisector
  direction, then intersecting neighbouring projected boundary lines.
- **Boundary inset:** A positive offset that shifts each projected boundary
  line toward the filled side before line intersections are computed. In the
  default `"side"` mode, the value is compensated so it measures clearance
  normal to the angled generated side wall; `"face"` mode uses the raw
  face-plane offset. At source vertices with valence greater than three, the
  same inset also adds a vertex-fan clip side so regions that only meet at a
  high-valence vertex do not touch at the corner.
- **Intrusion clearance profile:** A simple target-face-local 2D strip around
  an exact foreign intrusion segment. This is proxy geometry: useful for
  inspection and later boolean clearance, but not yet user-geometry-aware.

## Main APIs

```scad
use <polysymmetrica/core/face_regions.scad>
use <polysymmetrica/core/loop_shells.scad>
```

### `ps_face_region_loop_shells(...)`

Function: Build mesh data for the face's positive anti-interference volume.

Params: `face_ctx`, `z0`, `z1`, `mode="nonzero"`, `max_project=undef`,
`eps=1e-8`, `boundary_inset=0`, `boundary_inset_mode="side"`.

Returns: one generic `ps_loop_shell` record per filled boundary loop.

`points` and `faces` are directly usable with `polyhedron(...)` or
`ps_loop_shell(...)`. `capped_count` counts span projections limited by
`max_project`. `exposure_sign` is `+1` for same- or zero-winding/top-exposed
regions and `-1` for opposite-winding/bottom-exposed regions.

Accessor helpers:

- `ps_loop_shell_points(shell)`
- `ps_loop_shell_faces(shell)`
- `ps_loop_shell_source_idx(shell)`
- `ps_loop_shell_capped_count(shell)`
- `ps_loop_shell_z0(shell)`
- `ps_loop_shell_z1(shell)`
- `ps_loop_shell_bottom_loop2d(shell)`
- `ps_loop_shell_top_loop2d(shell)`
- `ps_loop_shell_exposure_sign(shell)`

`face_ctx` is a `ps_face_local_context(...)` record. In `place_on_faces(...)`
contexts, pass `$ps_face_local_context`.

The requested `z0` and `z1` are not guaranteed to be the returned shell's
actual cap planes. If a projected loop would self-intersect, reverse, or
collapse before reaching a requested bound, the shell is clipped to the last
valid plane on that side. Consumers that attach shelves, skins, cutters, or
other dependent geometry must read the effective bounds from
`ps_loop_shell_z0(shell)` and `ps_loop_shell_z1(shell)`, and must not assume
their input `z0`/`z1` survived unchanged.

### `ps_face_region_loop_volume(...)`

Module: Emit the generated shell volume for the current `place_on_faces(...)`
context.

Params: `z0`, `z1`, `mode="nonzero"`, `max_project=undef`, `eps=1e-8`,
`convexity=6`, `boundary_inset=0`, `boundary_inset_mode="side"`.

Typical usage:

```scad
place_on_faces(poly) {
    intersection() {
        ps_face_region_loop_volume(
            -0.8,
            1.2,
            max_project = 20,
            boundary_inset = 0.4,
            boundary_inset_mode = "side"
        );
        my_face_geometry();
    }
}
```

## Projection Model

For each boundary span, the implementation reconstructs the source-edge
subsegment in face-local 3D, uses its midpoint as the projection origin, and
projects that midpoint to `z0` and `z1` along the span's anti-interference
direction. The projected line stays parallel to the boundary span. Adjacent
projected lines are intersected to form the projected polygon at each target Z
plane.

When a requested target plane lies beyond a projected-loop convergence, the
implementation retreats that side of the shell toward `z=0` until the projected
loop is still valid. If both requested bounds lie beyond the same convergence
and collapse to the same effective plane, no shell is emitted for that loop.

`boundary_inset` is applied after each boundary span has been projected to the
target Z plane. Positive values move the generated line toward the filled side
of that span, so adjacent projected lines intersect to form a smaller shell.

With `boundary_inset_mode="side"`, the implementation compensates for the
generated side wall angle: the requested distance is measured normal to that
side plane, so sharp and shallow dihedrals get comparable clearance. With
`boundary_inset_mode="face"`, the requested distance is the raw current-face
XY offset, which is simpler for inspection but produces different physical gaps
for different side wall angles.

After the edge-span inset is applied, source-vertex corners with valence
greater than three get an extra projected clip line. The clip direction comes
from the corresponding side of the local vertex figure for the current source
face. Its position is measured from the already-inset adjacent-edge miter
farther into the filled region. This keeps the vertex clip compatible with the
edge-span inset instead of reusing the original source vertex as the clip
origin.

The anti-interference direction is the bisector between a selected current-face
ray and the adjacent-face ray on the current face `+Z` branch. For filled atoms
whose winding sign matches the source face loop, the current-face ray points
outside the filled atom. For filled atoms whose winding sign is opposite to the
source face loop, the current-face ray points into the filled side. This matters
for anti-truncation-style faces where the central atom and corner atoms are
valid filled regions but represent opposite local orientations.

The shell `exposure_sign` records that same relative winding decision: `+1`
for same-winding regions and `-1` for opposite-winding regions. Zero-winding
cells, such as inspection cells included by `mode="all"`, use the same `+1`
fallback as the projection ray selection. Callers that build printable face
details should use this field, not loop area or whether a projection grows
toward `+Z`, to decide whether a region receives top-side or bottom-side
geometry.

For non-planar faces this is deliberately best-effort: each boundary span uses
its own local source-edge midpoint Z. This keeps the generated volume tied to
the face frame without pretending that warped faces have one exact boundary
plane.

`max_project` is a practical safety cap for very sharp or near-flat projection
directions. Leave it `undef` for literal projection; set a finite value to
bound the offset distance.

## Punch-Through Boundary

This layer defines positive face-local admissible volumes. It deliberately does
not include strip-prism "clearance" approximations around intrusion line
segments. Real punch-through handling should use the proxy replay contract in
`proxy_interaction.md`, where caller-supplied face/edge/vertex proxy
geometry is replayed and subtracted deliberately.

## Current Limits

- Each filled boundary loop becomes one shell. Do not rely on holed cap faces;
  use multiple shells for multiple loops.
- The shell is an admissible region, not a finished printable face plate.
- Vertex-fan clipping is applied at true source-vertex corners only. Generated
  self-crossing split points still use only their projected boundary spans.
