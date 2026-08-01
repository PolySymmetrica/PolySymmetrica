/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

use <../../polysymmetrica/core/edge_regions.scad>
use <../../polysymmetrica/models/platonics_all.scad>

shells = ps_edge_region_shells(tetrahedron(), outset = 0.4, z0 = 1, z1 = -1, edge_idx = 0);

cube([0.01, 0.01, 0.01], center = true);
