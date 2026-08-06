# Cantitruncation Notes

This document captures current cantitruncation behavior, parameterization, and the non‑grid (trig) solvers. It is a working note, not final user documentation. Solver implementations live in `core/solvers.scad`.

## Parameterization

`poly_cantitruncate(poly, t=undef, c=undef, eps, len_eps, style="strict", cap_mode=undef)`

- **t** controls edge‑point placement along each original edge.
  - `t=0` at original vertices, `t=0.5` at mid‑edge.
  - `t<0` / `t>1` are allowed (anti/hyper).
- **c** controls face/edge expansion.
  - `d_f = -c * ir` (face plane shift along normal)
  - `d_e =  c * ir` (edge‑bisector plane offset)
If both `t` and `c` are `undef`, the trig solver is used **only for regular bases** (single face size + single edge length). Otherwise it falls back to `_ps_truncate_default_t(poly)` and `c=0`.

Topology with `style="strict"` (the default):
- Face cycles: 2n‑gons built from *face‑edge points*.
- Edge cycles: quads built from the same face‑edge points.
- Vertex cycles: 2·valence‑gons built from face‑edge points (hex for valence 3).

Topology with `style="planarized"`:
- Face and edge cycles keep the same shared face-edge points as strict mode.
- Source-vertex cycles use separate cap points realized from the corresponding
  raw face-edge loop.
- Connector quads bridge each raw source-vertex loop to its planarized cap loop.
- `cap_mode` controls the source-vertex cap realization and defaults to
  `"planar_edge_fraction"`. Use `"edge_fraction"` when you deliberately want
  the raw strict cap shape.

## Components & Current Limitations

Cantitruncation is built from three geometric components, all derived from the
base poly:

1) **Face cycles** (2n‑gons)  
   - Constructed by intersecting each original face plane (shifted by `d_f`)
     with the edge‑bisector planes of its adjacent faces.  
   - These are intended to remain planar by construction.

2) **Edge cycles** (quads)  
   - Constructed from the *face‑edge points* (two points per original edge per face).
   - These are planar when the inputs are consistent; they are the “square/rectangular”
     faces of the cantitruncate.

3) **Vertex cycles** (2·valence‑gons)  
   - Built from the same face‑edge points around each original vertex.  
   - These are the faces most prone to **warp** when a single global `c` is used.
   - `style="planarized"` gives these cycles their own realized cap points, so
     they can be planar without moving the shared face/edge sites.

Current limitations:
- **Mixed face families** (e.g., cuboctahedron) can produce warped vertex faces
  in strict mode unless the dominant family is prioritized.
- Planarized cantitruncation is not the classic shared-site topology: it adds
  connector strips around source vertices.
- On irregular stress cases, those connector strips can be self-crossing even
  when every face is planar and the output remains `star_ok`. Treat
  `style="planarized"` as a source-vertex cap planarity tool, not as a promise
  of `closed` validity for every input/profile.
- `solve_cantitruncate_dominant_edges` returns `c_edge_by_pair` consistent with
  `c_by_size`, which stabilizes defaults but does **not** fully solve planarity
  for all mixed-family cases yet.

## Trig Solver (regular bases)

`solve_cantitruncate_trig(poly, face_idx=0, edge_idx=undef)` returns `[t, c]` directly:

- Let **φ** be the interior angle of the selected face.
- Let **α** be the angle between outward normals of two adjacent faces.
- Let **a** be the original edge length.

Closed‑form:

```
t = 1 / (2 * (1 + sin(φ/2)))
d_f = (1 - 2t) * a / (2 * sin(α/2))
c = |d_f| / ir
```

This avoids any grid search for regular bases (cube, dodecahedron).

## Dominant‑Family Solver (mixed face sizes)

For bases with multiple face families (e.g. cuboctahedron), one global `c` cannot keep all vertex faces planar. Use the dominant‑family path:

- `solve_cantitruncate_dominant(poly, dominant_size)`
  - returns `[t, c_by_size]`
  - `c_by_size` is a list of `[face_size, c]` pairs.

- `solve_cantitruncate_dominant_edges(poly, dominant_size)`
  - returns `[t, c_by_size, c_edge_by_pair]`
  - `c_edge_by_pair` is a list of `[a, b, c]` for edge pairs between face sizes `a` and `b`
  - improves planarity when a single `c_by_size` still warps vertex faces.

- `solve_cantitruncate_dominant_edges_profile_rows(poly, dominant_size)`
  - returns `profile` rows (no tuple), including:
    - one global vertex row for `"t"`
    - face rows for family `"c"`
    - edge rows for pair-family `"c"`
  - use with `poly_cantitruncate(..., t=0, c=0, profile=rows)`.
This keeps the dominant family planar and lets secondary families follow.

## Inspecting Planarity

Use `poly_describe(poly, detail=3)` to echo `max_plane_err` per face. This is the max distance of a face’s vertices from its best‑fit plane (0 means perfectly planar).

## Example (cuboctahedron)

```
base = poly_rectify(octahedron()); // cuboctahedron
sol = solve_cantitruncate_dominant_edges(base, 4); // squares dominate
rows = ps_cantitruncate_profile_rows(base, sol[1], 0, sol[2]);
p = poly_cantitruncate(base, t=sol[0], c=0, profile=rows);
```

## Usage Examples

### Regular base (trig solver)
```
p = poly_cantitruncate(hexahedron()); // defaults to trig solver for regular bases
```

### Dominant family (mixed faces)
```
base = poly_rectify(octahedron()); // cuboctahedron
rows = solve_cantitruncate_dominant_edges_profile_rows(base, 4); // prioritize squares
p = poly_cantitruncate(base, t=0, c=0, profile=rows);
```

### Planarized source-vertex caps
```
p = poly_cantitruncate(tetrakis_hexahedron(), t=0.2, c=0.1, style="planarized");
```

### Per-vertex cap mode
```
p = poly_cantitruncate(
    tetrakis_hexahedron(),
    t=0.2,
    c=0.1,
    style="planarized",
    profile=[["vert", "id", 0, ["cap_mode", "edge_fraction"]]]
);
```

### Inspect planarity
```
poly_describe(p, detail=3); // shows max_plane_err per face
```

See also `profile.md` for the shared family-parameter schema used across operators.
