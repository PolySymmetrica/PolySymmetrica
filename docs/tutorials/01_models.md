# Models

PolySymmetrica starts with a polyhedron descriptor. Most examples get one from a
model constructor such as `tetrahedron()`, `octahedron()`, or `dodecahedron()`.

![Tetrahedron, octahedron, and dodecahedron rendered from model descriptors](../images/generated/tutorial_01_models.png)

Source: [`docs/examples/tutorial_01_models.scad`](../examples/tutorial_01_models.scad)

Start by making one descriptor:

```scad
p = tetrahedron();
```

That descriptor can then drive each placement family. Faces get a local 2D
polygon, edges get a local edge length, and vertices get a local origin:

```scad
color("plum")
    place_on_faces(p, inter_radius = 24)
        linear_extrude(height = 0.8)
            polygon(points = $ps_face_pts2d);

color("gray")
    place_on_edges(p, inter_radius = 24)
        cube([$ps_edge_len, 1.5, 1.5], center = true);

color("gold")
    place_on_vertices(p, inter_radius = 24)
        sphere(1.2, $fn = 16);
```

The source file wraps those three placement calls in `preview_poly(...)`, then
reuses the same module for a tetrahedron, octahedron, and dodecahedron:

```scad
preview_poly(tetrahedron(), 24, "plum");
preview_poly(octahedron(), 24, "orange");
preview_poly(dodecahedron(), 24, "palegreen");
```

The important habit is to keep the descriptor separate from the geometry you
place on it. Once the descriptor changes, the same child modules can be replayed
on a different solid.

Next: [Placement](02_placement.md).
