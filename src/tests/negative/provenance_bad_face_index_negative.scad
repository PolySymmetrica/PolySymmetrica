/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

use <../../polysymmetrica/core/funcs.scad>
use <../../polysymmetrica/models/platonics_all.scad>

// EXPECT FAIL: current face indices cannot be negative.
_ = poly_face_provenance(poly_with_provenance(tetrahedron()), -1);
