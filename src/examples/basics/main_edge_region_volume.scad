/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

use <../../polysymmetrica/core/edge_regions.scad>
use <../../polysymmetrica/core/placement.scad>
use <../../polysymmetrica/core/truncation.scad>
use <../../polysymmetrica/models/archimedians_all.scad>
use <../../polysymmetrica/models/catalans_all.scad>
use <../../polysymmetrica/models/platonics_all.scad>

IR = 26;
OUTSET = 1.5;
Z_MIN = -1.2;
Z_MAX = 2.0;
SPACING = 92;

module edge_region_preview(poly, label_s) {
    ctx = ps_edge_region_context(poly, inter_radius = IR);

    color("lightgray")
        place_on_edges(poly, IR)
            cube([$ps_edge_len, 0.45, 0.45], center = true);

    color("indianred", 0.72)
        place_on_edges(poly, IR)
            ps_edge_region_volume_from_context(ctx, outset = OUTSET, z0 = Z_MIN, z1 = Z_MAX);

    translate([0, -36, -18])
        linear_extrude(height = 0.4)
            text(label_s, size = 4, halign = "center", valign = "center");
}

translate([-SPACING * 2.5, 0, 0])
    edge_region_preview(poly_truncate(tetrahedron(), -1), "atet");

translate([-SPACING * 1.5, 0, 0])
    edge_region_preview(tetrahedron(), "tetrahedron");

translate([-SPACING * 0.5, 0, 0])
    edge_region_preview(icosidodecahedron(), "icosidodecahedron");

translate([SPACING * 0.5, 0, 0])
    edge_region_preview(rhombic_triacontahedron(), "rhombic triacontahedron");

translate([SPACING * 1.5, 0, 0])
    edge_region_preview(poly_truncate(dodecahedron(), t = 0.42), "truncated dodeca t=0.42");
