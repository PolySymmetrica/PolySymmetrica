# Boolean Print Patterns

Placement works naturally with OpenSCAD booleans. The child module can be a
solid part, a cutter, or a volume that clips another piece of geometry.

![A face-cavity sphere and anti-interference-clipped face pads](../images/generated/tutorial_05_boolean_patterns.png)

Source: [`docs/examples/tutorial_05_boolean_patterns.scad`](../examples/tutorial_05_boolean_patterns.scad)

## Face-Shaped Cutters

A placed face cutter can use `$ps_face_pts2d` for the mouth of the recess and
`$ps_poly_center_local` for its inward direction:

```scad
module face_cavity_cutter() {
    hull() {
        translate([0, 0, 5])
            linear_extrude(height = 1)
                polygon(points = $ps_face_pts2d * 0.78);
        translate($ps_poly_center_local)
            sphere(r = 0.8, $fn = 12);
    }
}
```

Use it inside `difference()` to subtract a family of aligned cavities:

```scad
difference() {
    sphere(r = ir + 4, $fn = 64);
    place_on_faces(cavity_poly, inter_radius = ir)
        face_cavity_cutter();
}
```

## Anti-Interference Volumes

Face-local geometry can collide with neighbouring face space when it gets thick
or decorative. `ps_face_region_loop_volume(...)` builds the positive region
available to the current face. Intersecting with it clips the placed geometry to
that admissible volume:

```scad
module clipped_face_pad() {
    intersection() {
        ps_face_region_loop_volume(
            -wall_thk,
            pad_h,
            boundary_inset = 0.45,
            boundary_inset_mode = "side"
        );
        translate([0, 0, -wall_thk])
            linear_extrude(height = wall_thk + pad_h)
                polygon(points = $ps_face_pts2d * 0.92);
    }
}
```

This is the beginner version of anti-interference: use the generated volume as
a practical cutter that keeps each face's print geometry inside its own local
space. Later printing material covers the lower-level face-region model.
