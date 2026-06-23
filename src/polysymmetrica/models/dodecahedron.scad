/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

// LibFile: polysymmetrica/models/dodecahedron.scad
//   Dodecahedron model constructor derived as the dual of the icosahedron.

use <../core/duals.scad>
use <icosahedron.scad>

// Function: dodecahedron()
// Usage:
//   result = dodecahedron();
// Description:
//   Return the dodecahedron as a normalized poly descriptor.
function dodecahedron() = poly_dual(icosahedron());
