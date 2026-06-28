// This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
// Copyright 2025-2026 Susan Witts
// SPDX-License-Identifier: MIT

use <polysymmetrica/core/construction.scad>
use <polysymmetrica/core/placement.scad>

ir = 22;
gap = 84;
wall_thk = 1.5;
strut_d = 1.2;

j1 = poly_pyramid(4);
j4 = poly_cupola(4);
j6 = poly_rotunda();

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
                    polygon(points = $ps_face_pts2d);
}

module show_poly(poly, x, col) {
    translate([x, 0, ir + wall_thk]) {
        face_shell(poly, col);
        edge_frame(poly);
    }
}

show_poly(j1, -gap, "tomato");
show_poly(j4, 0, "gold");
show_poly(j6, gap, "dodgerblue");
