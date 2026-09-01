/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

use <../../polysymmetrica/core/funcs.scad>
use <../../polysymmetrica/models/platonics_all.scad>

p = poly_with_provenance(tetrahedron());

// EXPECT FAIL: [0, 0] is not a current edge.
_ = poly_edge_provenance(p, [0, 0]);
