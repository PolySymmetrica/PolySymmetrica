/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

use <../../polysymmetrica/core/prisms.scad>

// EXPECT FAIL: p must be >= 1
_ = poly_prism(5, p=0);

