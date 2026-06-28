// This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
// Copyright 2025-2026 Susan Witts
// SPDX-License-Identifier: MIT

use <polysymmetrica/core/construction.scad>
use <polysymmetrica/core/placement.scad>
use <polysymmetrica/models/platonics_all.scad>

ir = 20;
gap = 74;
wall_thk = 1.5;
strut_d = 1.15;
face_inset = 1.1;

cube_pair = poly_attach(hexahedron(), hexahedron(), f1 = 0, f2 = 0);
tetra_on_octa = poly_attach(octahedron(), tetrahedron(), f1 = 0, f2 = 0);
tetra_cluster = poly_attach(octahedron(), tetrahedron(), f1 = [0, 2, 4], f2 = 0);

module edge_frame(poly) {
    color("dimgray")
        place_on_edges(poly, inter_radius = ir)
            cube([$ps_edge_len, strut_d, strut_d], center = true);
}

module face_shell(poly, col) {
    color(col)
        place_on_faces(poly, inter_radius = ir)
            translate([0, 0, -wall_thk])
                linear_extrude(height = wall_thk)
                    offset(delta = -face_inset)
                        polygon(points = $ps_face_pts2d);
}

module show_poly(poly, x, col) {
    translate([x, 0, ir + wall_thk]) {
        face_shell(poly, col);
        edge_frame(poly);
    }
}

show_poly(cube_pair, -gap, "tomato");
show_poly(tetra_on_octa, 0, "gold");
show_poly(tetra_cluster, gap, "dodgerblue");
