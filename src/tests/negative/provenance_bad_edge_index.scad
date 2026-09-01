/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

use <../../polysymmetrica/core/funcs.scad>
use <../../polysymmetrica/models/platonics_all.scad>

p = poly_with_provenance(tetrahedron());

// EXPECT FAIL: this numeric edge ID is past the derived edge table.
_ = poly_edge_provenance(p, len(poly_edges(p)));

