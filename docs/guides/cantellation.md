# Cantellation Notes

This document captures current cantellation behavior, parameterization, and solver helpers. It is a working note, not final user documentation.

## Parameterization

`poly_cantellate(poly, df=undef, c=undef, df_max=undef, steps=16, family_edge_idx=0, profile=undef, cleanup=false, style="strict", cap_mode=undef, eps=1e-8, len_eps=1e-6, cleanup_eps=1e-8)`

- **df** controls face offsets (how far original faces move along their normals).
- **c** provides a normalized knob; `c=0.5` targets square edge faces (via `solve_cantellate_square_df`).
- If `df` is omitted, `c` (or a default `c=0.5`) is used to derive a `df`.
- `df_max` bounds the normalized mapping; `steps` controls the square‑target search.
- **style** controls vertex-cap topology:
  - `"strict"` preserves the classic shared-incidence construction.
  - `"planarized"` keeps source/edge sites unchanged, then adds separate
    planarized vertex-cap sites and connector quads.
- **cap_mode** is only valid with `style="planarized"` and uses the shared
  vertex-figure realization modes: `"planar_edge_fraction"`,
  `"edge_fraction"`, `"centric"`, and `"poly_centroidal"`.

Topology:
- Face cycles: original faces (expanded) become larger polygons.
- Edge cycles: quads derived from each original edge.
- Vertex cycles: polygons derived from each original vertex (valence‑gons).
- Planarized connector cycles: one quad per source `(vertex, incident face)`
  side, bridging the strict raw incidence loop to the realized cap loop.

## Components & Current Limitations

Cantellation is constructed from three components:

1) **Face cycles**
   - Derived by shifting each original face corner along that face's normal by `df`.
   - Intended to remain planar by construction.

2) **Edge cycles** (quads)
   - Built from the two edge points per original edge (one per adjacent face).
   - These are the “rectangular/square” faces of cantellation.

3) **Vertex cycles** (valence‑gons)
   - Built from edge‑adjacent points around each original vertex.
   - In strict mode, they share the source/edge incidence points directly.
   - In planarized mode, they use separate realized cap points.

Current limitations:
- Strict vertex caps can be non-planar for irregular or valence > 3 source
  vertices.
- Extreme offsets (large `df`) can yield self‑intersections or degenerate faces; use with care.

## Solvers / Helpers

- `solve_cantellate_square_df(poly, df_min, df_max, steps, family_edge_idx, eps)`
  - Searches for a `df` that makes a chosen edge‑family as square as possible.

- `poly_cantellate_norm(poly, c, df_max=undef, steps=16, family_edge_idx=0, profile=undef, cleanup=false, style="strict", cap_mode=undef, eps=1e-8, len_eps=1e-6, cleanup_eps=1e-8)`
  - Normalized cantellation (maps `c in [0,1]` to a `df` range).
  - Intended as the user‑friendly entry point for many examples.

## Inspecting Planarity

Use `poly_describe(poly, detail=3)` to echo `max_plane_err` per face. This is the max distance of a face’s vertices from its best‑fit plane.

## Usage Examples

### Basic cantellation (explicit df)
```
p = poly_cantellate(hexahedron(), df = 0.2);
```

### Normalized cantellation
```
p = poly_cantellate_norm(hexahedron(), 0.5);
```

### Planarized vertex caps
```
p = poly_cantellate(base, df = 0.1, style = "planarized");
```

### Square‑targeted face family
```
base = poly_rectify(octahedron()); // cuboctahedron
// pick a representative edge from the family you want squared
sol_df = solve_cantellate_square_df(base, 0.0, 1.0, 40, family_edge_idx=0);
p = poly_cantellate(base, sol_df);
```

### Inspect planarity
```
poly_describe(p, detail=3);
```

See also `profile.md` for the shared family-parameter schema used across operators.
