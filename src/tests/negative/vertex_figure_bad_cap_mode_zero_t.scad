/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

use <../../polysymmetrica/core/vertex.scad>

pts = ps_vertex_figure_points_from_neighbors(
    [0, 0, 0],
    [[1, 0, 0], [0, 1, 0], [0, 0, 1]],
    t = 0,
    cap_mode = "bogus"
);

echo(pts);

cube([0.01, 0.01, 0.01], center = true);
