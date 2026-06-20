// This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
// Copyright 2025-2026 Susan Witts
// SPDX-License-Identifier: MIT

use <polysymmetrica/core/placement.scad>
use <polysymmetrica/core/truncation.scad>
use <polysymmetrica/models/platonics_all.scad>

p = poly_truncate(hexahedron());
ir = 32;

module inset_face_panel() {
    color("lightsteelblue")
        linear_extrude(height = 1.2)
            polygon(points = [for (pt = $ps_face_pts2d) pt * 0.78]);
}

module edge_bar() {
    color("silver")
        cube([$ps_edge_len * 0.76, 1.5, 1.2], center = true);
}

module vertex_marker() {
    color("gold")
        sphere(1.9, $fn = 20);
}

place_on_faces(p, inter_radius = ir)
    inset_face_panel();

place_on_edges(p, inter_radius = ir)
    edge_bar();

place_on_vertices(p, inter_radius = ir)
    vertex_marker();
