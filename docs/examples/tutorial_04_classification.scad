// This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
// Copyright 2025-2026 Susan Witts
// SPDX-License-Identifier: MIT

use <polysymmetrica/core/classify.scad>
use <polysymmetrica/core/placement.scad>
use <polysymmetrica/models/archimedians_all.scad>

p = rhombicuboctahedron();
cls = poly_classify(p);

ir = 24;
wall_thk = 2.0;
model_lift = ir + wall_thk;
face_family_colors = ["red", "red", "blue"];

module face_plate() {
    translate([0, 0, -wall_thk])
        linear_extrude(height = wall_thk)
            polygon(points = $ps_face_pts2d);
}

translate([0, 0, model_lift])
    place_on_faces(p, inter_radius = ir, classify = cls) {
        col = face_family_colors[$ps_face_family_id];
        color(col)
            face_plate();
    }
