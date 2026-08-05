/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

use <../../../polysymmetrica/core/face_regions.scad>
use <../../../polysymmetrica/core/edge_regions.scad>
use <../../../polysymmetrica/core/placement.scad>
use <../../../polysymmetrica/core/duals.scad>
use <../../../polysymmetrica/core/truncation.scad>
use <../../../polysymmetrica/models/platonics_all.scad>

IR = 20;
SHELL_T = 3;
SHELL_W = 5;

Z_MIN = -SHELL_T - 2;
Z_MAX = 10.0;

RES = 80;

t0 = poly_truncate(tetrahedron());
//t1 = poly_dual(t0);

//p0 = octahedron();
//r1 = poly_rectify(p0);
//d1 = poly_dual(r1);
//r2 = poly_rectify(d1);
//d2 = poly_dual(r2);
//r3 = poly_rectify(d2);
//d3 = poly_dual(r3);

//p = poly_rectify(poly_truncate(tetrahedron()));

$fn = RES;

module show_spherical(i, poly, indices = undef) {
    module shell() {
        difference() {
            sphere(r = IR);
            sphere(r = IR - SHELL_T);
        }
    }
    module faces() {
        place_on_faces(poly, IR, indices = indices) {
            ps_face_region_loop_volume(Z_MIN, Z_MAX, max_project = undef, boundary_inset=SHELL_W/2);
        }
    }
    
    translate([i * IR * 3, 0, 0])
    if (is_undef(indices)) {
        difference() {
            shell();
            faces();
        }  
    } else {
        intersection() {
            sphere(r = IR);
            faces();
        }  
    }
}


show_spherical(0, t0);
