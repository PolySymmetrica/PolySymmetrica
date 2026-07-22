/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

use <../../polysymmetrica/core/truncation.scad>
use <../../polysymmetrica/models/catalans_all.scad>

// EXPECT FAIL: default planarized caps can realize beyond half-edge at t=0.5.
_ = poly_truncate(tetrakis_hexahedron(), t = 0.5);
