/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

use <../../polysymmetrica/core/truncation.scad>
use <../../polysymmetrica/core/duals.scad>
use <../../polysymmetrica/models/platonics_all.scad>

// EXPECT FAIL: Stage-B dual provenance mapping is not implemented yet.
_ = poly_dual(poly_chamfer(hexahedron(), t=0.1));
