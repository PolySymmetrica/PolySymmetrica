// This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
// Copyright 2025-2026 Susan Witts
// SPDX-License-Identifier: MIT

use <polysymmetrica/core/placement.scad>
use <polysymmetrica/models/archimedians_all.scad>

p = cuboctahedron();
ir = 20;

strut_d = 2.0;
wall_thk = 2.0;
model_gap = 70;
face_colors = ["tomato", "gold", "dodgerblue", "mediumseagreen", "orchid", "darkorange"];

// The cuboctahedron is already a more interesting printable than a cube, while
// still having broad lower faces and short overhangs in this orientation.
model_lift = ir + strut_d / 2;

module frame_strut() {
    color("dimgray")
        hull() {
            translate([-$ps_edge_len / 2, 0, 0])
                sphere(d = strut_d, $fn = 16);
            translate([$ps_edge_len / 2, 0, 0])
                sphere(d = strut_d, $fn = 16);
        }
}

module inward_face_plate() {
    color(face_colors[$ps_face_idx % len(face_colors)])
        translate([0, 0, -wall_thk])
            linear_extrude(height = wall_thk)
                polygon(points = $ps_face_pts2d);
}

// Example 1: a simple edge frame. Many printable polyhedron models start here.
translate([-model_gap / 2, 0, model_lift])
    place_on_edges(p, inter_radius = ir)
        frame_strut();

// Example 2: a face-only shell. Each face's outer surface stays on the original
// face plane while the thickness grows inward.
translate([model_gap / 2, 0, model_lift])
    place_on_faces(p, inter_radius = ir)
        inward_face_plate();
