// This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
// Copyright 2025-2026 Susan Witts
// SPDX-License-Identifier: MIT

use <polysymmetrica/core/classify.scad>
use <polysymmetrica/core/placement.scad>
use <polysymmetrica/models/archimedians_all.scad>

p = cuboctahedron();
cls = poly_classify(p);

ir = 24;
wall_thk = 2.0;
model_lift = ir + wall_thk;

square_faces = ps_classify_face_idxs_by_n(cls, 4);
triangle_faces = ps_classify_face_idxs_by_n(cls, 3);

module face_plate(col) {
    color(col)
        translate([0, 0, -wall_thk])
            linear_extrude(height = wall_thk)
                polygon(points = $ps_face_pts2d);
}

translate([0, 0, model_lift]) {
    place_on_faces(p, inter_radius = ir, classify = cls, indices = square_faces)
        face_plate("red");

    place_on_faces(p, inter_radius = ir, classify = cls, indices = triangle_faces)
        face_plate("blue");
}
