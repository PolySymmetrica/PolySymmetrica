// This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
// Copyright 2025-2026 Susan Witts
// SPDX-License-Identifier: MIT

use <polysymmetrica/core/duals.scad>
use <polysymmetrica/core/render.scad>
use <polysymmetrica/core/truncation.scad>
use <polysymmetrica/models/platonics_all.scad>

base = dodecahedron();
ir = 16;
spacing = 58;

module show_poly(poly, x, y, col) {
    translate([x, y, 0])
        color(col)
            poly_render(poly, inter_radius = ir);
}

show_poly(base, -spacing, spacing / 2, "gainsboro");
show_poly(poly_truncate(base), 0, spacing / 2, "tomato");
show_poly(poly_rectify(base), spacing, spacing / 2, "gold");

show_poly(poly_chamfer(base), -spacing, -spacing / 2, "mediumseagreen");
show_poly(poly_cantellate(base), 0, -spacing / 2, "dodgerblue");
show_poly(poly_dual(base), spacing, -spacing / 2, "orchid");
