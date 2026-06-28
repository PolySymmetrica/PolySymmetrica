// This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
// Copyright 2025-2026 Susan Witts
// SPDX-License-Identifier: MIT

use <polysymmetrica/core/placement.scad>
use <polysymmetrica/core/truncation.scad>
use <polysymmetrica/models/archimedians_all.scad>

base = rhombicuboctahedron();
ir = 18;
gap = 62;
wall_thk = 1.4;
strut_d = 1.0;

profile = [
    ["face", "all", ["df", 0.03]],
    ["face", "family", 1, ["df", 0.15]]
];

uniform = poly_cantellate(base, df = 0.08, cleanup = true);
profiled = poly_cantellate(base, df = 0, profile = profile, cleanup = true);

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
                    polygon(points = $ps_face_pts2d * 0.92);
}

module show_poly(poly, x, col) {
    translate([x, 0, ir + wall_thk]) {
        face_shell(poly, col);
        edge_frame(poly);
    }
}

show_poly(base, -gap, "gainsboro");
show_poly(uniform, 0, "mediumseagreen");
show_poly(profiled, gap, "orchid");
