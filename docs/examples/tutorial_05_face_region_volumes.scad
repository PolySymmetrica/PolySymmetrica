// This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
// Copyright 2025-2026 Susan Witts
// SPDX-License-Identifier: MIT

use <polysymmetrica/core/face_regions.scad>
use <polysymmetrica/core/placement.scad>
use <polysymmetrica/models/archimedians_all.scad>

p = truncated_tetrahedron();
ir = 22;
gap = 70;
z0 = -5;
z1 = 9;
plate_z0 = -1.5;
plate_z1 = 4.5;
inset = 1.2;

function face_col() = ($ps_vertex_count == 3) ? "dodgerblue" : "darkorange";

module region_volume() {
    color(face_col())
        ps_face_region_loop_volume(z0, z1, boundary_inset = inset);
}

module oversized_plate_clipped_to_region() {
    color(face_col())
        intersection() {
            ps_face_region_loop_volume(z0, z1, boundary_inset = inset);
            translate([0, 0, plate_z0])
                linear_extrude(height = plate_z1 - plate_z0)
                    polygon(points = $ps_face_pts2d * 1.22);
        }
}

translate([-gap / 2, 0, ir + 2])
    place_on_faces(p, inter_radius = ir)
        region_volume();

translate([gap / 2, 0, ir + 2])
    place_on_faces(p, inter_radius = ir)
        oversized_plate_clipped_to_region();
