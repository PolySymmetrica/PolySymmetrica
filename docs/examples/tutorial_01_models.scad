// This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
// Copyright 2025-2026 Susan Witts
// SPDX-License-Identifier: MIT

use <polysymmetrica/core/placement.scad>
use <polysymmetrica/models/platonics_all.scad>

module preview_poly(poly, inter_radius, face_color) {
    color(face_color)
        place_on_faces(poly, inter_radius = inter_radius)
            linear_extrude(height = 0.8)
                polygon(points = $ps_face_pts2d);

    color("gray")
        place_on_edges(poly, inter_radius = inter_radius)
            cube([$ps_edge_len, 1.5, 1.5], center = true);

    color("gold")
        place_on_vertices(poly, inter_radius = inter_radius)
            sphere(1.2, $fn = 16);
}

translate([-72, 0, 0])
    preview_poly(tetrahedron(), 24, "plum");

preview_poly(octahedron(), 24, "orange");

translate([72, 0, 0])
    preview_poly(dodecahedron(), 24, "palegreen");
