// This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
// Copyright 2025-2026 Susan Witts
// SPDX-License-Identifier: MIT

use <../../polysymmetrica/core/prisms.scad>

// EXPECT FAIL: p=n/2 gives diameter cycles, not polygonal faces
_ = poly_antiprism(6, p=3);
