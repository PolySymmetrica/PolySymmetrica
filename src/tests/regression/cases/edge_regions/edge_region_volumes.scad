/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

include <../../common/regression_common.scad>

use <../../../../polysymmetrica/core/edge_regions.scad>
use <../../../../polysymmetrica/core/placement.scad>
use <../../../../polysymmetrica/core/truncation.scad>
use <../../../../polysymmetrica/models/archimedians_all.scad>
use <../../../../polysymmetrica/models/catalans_all.scad>
use <../../../../polysymmetrica/models/platonics_all.scad>

IR = 26;
OUTSET = 1.4;
Z0 = -1.2;
Z1 = 2.0;

TESTS = [
    ["atet_crossing_wedges", function() poly_truncate(tetrahedron(), t = -1)],
    ["tetrahedron_frustum", function() tetrahedron()],
    ["icosidodecahedron_dense", function() icosidodecahedron()],
    ["rhombic_triacontahedron_dense", function() rhombic_triacontahedron()],
    ["truncated_dodecahedron_t042", function() poly_truncate(dodecahedron(), t = 0.42)]
];

T_MAX = len(TESTS);
T = is_undef(T) ? 0 : T;
REG_LIST = is_undef(REG_LIST) ? false : REG_LIST;

assert(T >= 0 && T < T_MAX, str("T out of range: ", T));

module _edge_region_wire(poly) {
    color("lightgray")
        place_on_edges(poly, IR)
            cube([$ps_edge_len, 0.45, 0.45], center = true);
}

module _edge_region_atoms(poly) {
    color("indianred", 0.70)
        place_on_edges(poly, IR, edge_regions = true)
            ps_current_edge_region_volume(outset = OUTSET, z0 = Z0, z1 = Z1);
}

module _edge_region_panel(poly, label_s) {
    _edge_region_wire(poly);
    _edge_region_atoms(poly);
    reg_panel_label(label_s);
}

if (REG_LIST) {
    reg_list_tests(TESTS, render_args = REG_RENDER_ARGS_POLY_SINGLE);
} else {
    spec = TESTS[T];
    _edge_region_panel(spec[1](), spec[0]);
}
