// This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
// Copyright 2025-2026 Susan Witts
// SPDX-License-Identifier: MIT

use <polysymmetrica/core/face_regions.scad>
use <polysymmetrica/core/placement.scad>
use <polysymmetrica/models/archimedians_all.scad>

ir = 20;
gap = 65;
wall_thk = 2.0;
pad_h = 4.0;

cavity_poly = truncated_octahedron();
pad_poly = cuboctahedron();

module face_cavity_cutter() {
    hull() {
        translate([0, 0, 5])
            linear_extrude(height = 1)
                polygon(points = $ps_face_pts2d * 0.78);
        translate($ps_poly_center_local)
            sphere(r = 0.8, $fn = 12);
    }
}

module clipped_face_pad() {
    col = ($ps_vertex_count == 3) ? "dodgerblue" : "darkorange";

    color(col)
        intersection() {
            ps_face_region_loop_volume(
                -wall_thk,
                pad_h,
                boundary_inset = 0.45,
                boundary_inset_mode = "side"
            );
            translate([0, 0, -wall_thk])
                linear_extrude(height = wall_thk + pad_h)
                    polygon(points = $ps_face_pts2d * 0.92);
        }
}

translate([-gap / 2, 0, ir + 2])
    difference() {
        color("gainsboro")
            sphere(r = ir + 4, $fn = 64);
        place_on_faces(cavity_poly, inter_radius = ir)
            face_cavity_cutter();
    }

translate([gap / 2, 0, ir + wall_thk])
    place_on_faces(pad_poly, inter_radius = ir)
        clipped_face_pad();
