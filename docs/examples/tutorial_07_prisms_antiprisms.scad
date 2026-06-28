// This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
// Copyright 2025-2026 Susan Witts
// SPDX-License-Identifier: MIT

use <polysymmetrica/core/placement.scad>
use <polysymmetrica/core/prisms.scad>

ir = 22;
gap = 66;
wall_thk = 1.6;
strut_d = 1.4;

module edge_frame(poly) {
    color("dimgray")
        place_on_edges(poly, inter_radius = ir)
            hull() {
                translate([-$ps_edge_len / 2, 0, 0])
                    sphere(d = strut_d, $fn = 14);
                translate([$ps_edge_len / 2, 0, 0])
                    sphere(d = strut_d, $fn = 14);
            }
}

module face_shell(poly, col) {
    color(col)
        place_on_faces(poly, inter_radius = ir)
            translate([0, 0, -wall_thk])
                linear_extrude(height = wall_thk)
                    polygon(points = $ps_face_pts2d * 0.9);
}

module show_poly(poly, x, col) {
    translate([x, 0, ir + wall_thk]) {
        face_shell(poly, col);
        edge_frame(poly);
    }
}

prism = poly_prism(6);
antiprism = poly_antiprism(5);
low_antiprism = poly_antiprism(5, height = 0.55);

show_poly(prism, -gap, "tomato");
show_poly(antiprism, 0, "dodgerblue");
show_poly(low_antiprism, gap, "gold");
