/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

use <../../polysymmetrica/core/truncation.scad>
use <../../polysymmetrica/models/platonics_all.scad>

// EXPECT FAIL: selective truncation requires integral current vertex IDs.
_ = poly_truncate(tetrahedron(), t=0.1, selected_vertices=[0.5]);
