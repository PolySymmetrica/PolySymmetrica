/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

use <../../polysymmetrica/core/funcs.scad>
use <../../polysymmetrica/models/platonics_all.scad>

// EXPECT FAIL: current vertex indices must be integers.
_ = poly_vertex_provenance(poly_with_provenance(tetrahedron()), 0.5);

