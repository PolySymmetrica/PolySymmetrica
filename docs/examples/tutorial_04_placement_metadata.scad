// This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
// Copyright 2025-2026 Susan Witts
// SPDX-License-Identifier: MIT

use <polysymmetrica/core/placement.scad>
use <polysymmetrica/models/archimedians_all.scad>

ir = 20;
gap = 65;
wall_thk = 2.0;

face_poly = rhombicuboctahedron();
edge_poly = cuboctahedron();
cavity_poly = truncated_octahedron();

module face_count_shell() {
    col = ($ps_vertex_count == 3) ? "royalblue" : "tomato";

    color(col)
        translate([0, 0, -wall_thk])
            linear_extrude(height = wall_thk)
                polygon(points = $ps_face_pts2d);
}

module fitted_edge_strut() {
    color("dimgray")
        hull() {
            translate([-$ps_edge_len / 2, 0, 0])
                sphere(d = 2.0, $fn = 16);
            translate([$ps_edge_len / 2, 0, 0])
                sphere(d = 2.0, $fn = 16);
        }
}

module face_cavity_cutter() {
    hull() {
        translate([0, 0, 5])
            linear_extrude(height = 1)
                polygon(points = $ps_face_pts2d * 0.78);
        translate($ps_poly_center_local)
            sphere(r = 0.8, $fn = 12);
    }
}

translate([-gap, 0, ir + wall_thk])
    place_on_faces(face_poly, inter_radius = ir)
        face_count_shell();

translate([0, 0, ir + 1])
    place_on_edges(edge_poly, inter_radius = ir)
        fitted_edge_strut();

translate([gap, 0, ir + 2])
    difference() {
        color("gainsboro")
            sphere(r = ir + 4, $fn = 64);
        place_on_faces(cavity_poly, inter_radius = ir)
            face_cavity_cutter();
    }
