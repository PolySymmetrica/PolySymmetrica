/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

use <../../polysymmetrica/core/funcs.scad>
use <../../polysymmetrica/models/platonics_all.scad>

// EXPECT FAIL: this current face index is past the face table.
p = poly_with_provenance(tetrahedron());
_ = poly_face_provenance(p, len(poly_faces(p)));

