# Basic Printing

Placement is enough to make a first printable object. Start with a simple frame:
edge struts join the vertices, vertex bosses strengthen the corners, and small
polygon plates show where face pieces could sit.

![A truncated cube printable starter with edge struts, vertex bosses, and simple face plates](../images/generated/tutorial_03_basic_printing.png)

Source: [`docs/examples/tutorial_03_basic_printing.scad`](../examples/tutorial_03_basic_printing.scad)

The example uses a truncated cube:

```scad
p = poly_truncate(hexahedron());
ir = 34;
```

The frame strut is ordinary OpenSCAD geometry. `place_on_edges(...)` supplies
an edge-local frame where X runs along the current edge, so `$ps_edge_len` gives
the strut length:

```scad
module frame_strut() {
    color("dimgray")
        hull() {
            translate([-$ps_edge_len / 2, 0, 0])
                sphere(d = strut_d, $fn = 16);
            translate([$ps_edge_len / 2, 0, 0])
                sphere(d = strut_d, $fn = 16);
        }
}

place_on_edges(p, inter_radius = ir)
    frame_strut();
```

The same pattern adds vertex bosses:

```scad
place_on_vertices(p, inter_radius = ir)
    vertex_boss();
```

Face plates can start as plain scaled polygons:

```scad
module simple_face_plate() {
    color("mediumseagreen", 0.72)
        translate([0, 0, 0.35])
            linear_extrude(height = plate_thk)
                polygon(points = $ps_face_pts2d * plate_scale);
}

place_on_faces(p, inter_radius = ir)
    simple_face_plate();
```

This is deliberately basic. It does not add sockets, clearances, print
tolerances, or separate print-bed layout. Those are later steps once the shape,
scale, and part breakdown are clear.

For family-specific sizing and transform parameters, continue with
[profile rows](../guides/profile.md).
