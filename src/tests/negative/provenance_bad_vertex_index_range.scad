/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

use <../../polysymmetrica/core/funcs.scad>
use <../../polysymmetrica/models/platonics_all.scad>

// EXPECT FAIL: this current vertex index is past the vertex table.
p = poly_with_provenance(tetrahedron());
_ = poly_vertex_provenance(p, len(poly_verts(p)));
