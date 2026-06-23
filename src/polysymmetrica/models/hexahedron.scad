/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

// LibFile: polysymmetrica/models/hexahedron.scad
//   Cube model constructor derived as the dual of the octahedron.

use <../core/duals.scad>
use <octahedron.scad>

// Function: hexahedron()
// Usage:
//   result = hexahedron();
// Description:
//   Return the hexahedron, or cube, as a normalized poly descriptor.
function hexahedron() = poly_dual(octahedron());
