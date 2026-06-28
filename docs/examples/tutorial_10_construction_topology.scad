// This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
// Copyright 2025-2026 Susan Witts
// SPDX-License-Identifier: MIT

use <polysymmetrica/core/construction.scad>
use <polysymmetrica/core/placement.scad>
use <polysymmetrica/models/platonics_all.scad>

ir = 20;
gap = 62;
wall_thk = 1.6;
strut_d = 1.2;

open_cube = poly_delete_faces(hexahedron(), 0, cap = false);
capped_cube = poly_delete_faces(hexahedron(), 0, cap = true);
sliced_dodeca = poly_slice(dodecahedron(), [0, 0, 0], [0, 0, 1], keep = "above");

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

show_poly(open_cube, -gap, "tomato");
show_poly(capped_cube, 0, "gold");
show_poly(sliced_dodeca, gap, "dodgerblue");
