/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

use <../../../polysymmetrica/core/edge_regions.scad>
use <../../../polysymmetrica/core/placement.scad>
use <../../../polysymmetrica/core/truncation.scad>
use <../../../polysymmetrica/models/platonics_all.scad>

IR = 20;
OUTSET = 5;
Z_MIN = -6.0;
Z_MAX = 4.0;
SHELL_T = 4;
SHELL_W = 7;
BLOCK = 50;
RES = 80;

poly = poly_rectify(hexahedron());

$fn = RES;

module band(or, w, t) {
    difference() {
        cylinder(r = or, h = w, center = true);
        cylinder(r = or - t, h = w, center = true);
    }
}

module band2(or, w, t) {
    rotate_extrude() 
        translate([or, 0, 0]) 
            resize([t, w]) 
                circle(1);
}

place_on_edges(poly, IR, edge_regions = true, indices = [for(i=[0:1:43]) i]) {
    *ps_current_edge_region_volume(outset = 1, z0 = -0.2, z1 = 0.2);

    intersection() {
        ps_current_edge_region_volume(outset = OUTSET, z0 = Z_MIN, z1 = Z_MAX);
        //cube([$ps_edge_len, SHELL_W, $ps_edge_midradius], center = true);
//        *echo($ps_poly_center_local);
        let(r = norm($ps_edge_pts_local[0] - $ps_poly_center_local))
        translate([0,0,-r]) rotate([90, 0, 0]) {
            band2(r, SHELL_W, SHELL_T);
        }
    }
    
    // Just lets us see the default edge
    *cube([$ps_edge_len, 0.2, 0.6], center = true);
}

*place_on_vertices(poly, IR)
    translate([0,0,-SHELL_T/2]) resize([SHELL_W, SHELL_W, SHELL_T]) sphere(1, $fn = 20);

*band2(20, SHELL_W, SHELL_T);

