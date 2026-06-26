# Classification

Classification groups faces, edges, and vertices into matching families. A
simple first use is choosing which faces receive which placed geometry.

![A rhombicuboctahedron shell with square faces in red and triangular faces in blue](../images/generated/tutorial_04_classification.png)

Source: [`docs/examples/tutorial_04_classification.scad`](../examples/tutorial_04_classification.scad)

The example starts with a rhombicuboctahedron and computes a classification
record:

```scad
p = rhombicuboctahedron();
cls = poly_classify(p);
```

Classification metadata is available inside placement when `classify = cls` is
passed to the placement module:

```scad
face_family_colors = ["red", "red", "blue"];

place_on_faces(p, inter_radius = ir, classify = cls) {
    col = face_family_colors[$ps_face_family_id];
    color(col)
        face_plate();
}
```

For this model, the first two face families are square faces and the third is
the triangular face family, so the square panels render red and the triangular
panels render blue.

The child module is the same inward face plate from the printing tutorial:

```scad
module face_plate() {
    translate([0, 0, -wall_thk])
        linear_extrude(height = wall_thk)
            polygon(points = $ps_face_pts2d);
}
```

This is the basic classification workflow: compute `cls` once, pass it into
placement, then use the resulting `$ps_*_family_id` metadata inside the child
geometry.
