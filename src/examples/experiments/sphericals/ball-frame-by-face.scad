/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

use <../../../polysymmetrica/core/face_regions.scad>
use <../../../polysymmetrica/core/edge_regions.scad>
use <../../../polysymmetrica/core/placement.scad>
use <../../../polysymmetrica/core/truncation.scad>
use <../../../polysymmetrica/models/platonics_all.scad>

IR = 20;
SHELL_T = 5;
SHELL_W = 6;

OUTSET = 5;
Z_MIN = -SHELL_T;
Z_MAX = 4.0;
BLOCK = 50;
RES = 80;

//poly = poly_rectify(octahedron());
poly = poly_rectify(dodecahedron());

$fn = RES;

T = 0.1;

difference() {
    sphere(r = IR);
    sphere(r = IR - SHELL_T);

    place_on_faces(poly, IR, indices = 13) {
        ps_face_region_loop_volume(Z_MIN, Z_MAX, max_project = undef, boundary_inset=SHELL_W/2);
    };
}