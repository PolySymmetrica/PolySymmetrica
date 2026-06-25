// This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
// Copyright 2025-2026 Susan Witts
// SPDX-License-Identifier: MIT

use <polysymmetrica/core/placement.scad>
use <polysymmetrica/core/truncation.scad>
use <polysymmetrica/models/platonics_all.scad>

p = poly_truncate(hexahedron());
ir = 34;

strut_d = 1.8;
vertex_d = 3.2;
plate_thk = 0.8;
plate_scale = 0.68;

module frame_strut() {
    color("dimgray")
        hull() {
            translate([-$ps_edge_len / 2, 0, 0])
                sphere(d = strut_d, $fn = 16);
            translate([$ps_edge_len / 2, 0, 0])
                sphere(d = strut_d, $fn = 16);
        }
}

module vertex_boss() {
    color("gold")
        sphere(d = vertex_d, $fn = 20);
}

module simple_face_plate() {
    color("mediumseagreen", 0.72)
        translate([0, 0, 0.35])
            linear_extrude(height = plate_thk)
                polygon(points = $ps_face_pts2d * plate_scale);
}

place_on_edges(p, inter_radius = ir)
    frame_strut();

place_on_vertices(p, inter_radius = ir)
    vertex_boss();

place_on_faces(p, inter_radius = ir)
    simple_face_plate();
