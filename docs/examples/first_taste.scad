// This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
// Copyright 2025-2026 Susan Witts
// SPDX-License-Identifier: MIT

use <polysymmetrica/core/placement.scad>
use <polysymmetrica/core/truncation.scad>
use <polysymmetrica/models/platonics_all.scad>

p = poly_truncate(dodecahedron());
ir = 35;

color("lightsteelblue")
    place_on_faces(p, inter_radius = ir)
        linear_extrude(height = 1)
            polygon(points = $ps_face_pts2d);

color("silver")
    place_on_edges(p, inter_radius = ir)
        cube([$ps_edge_len, 1, 1], center = true);

color("gold")
    place_on_vertices(p, inter_radius = ir)
        sphere(1.6, $fn = 16);
