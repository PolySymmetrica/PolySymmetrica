/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

/**
Defines the dodecahedron - derived from icosahedron() using poly_dual().
*/

use <../core/duals.scad>
use <icosahedron.scad>

function dodecahedron() = poly_dual(icosahedron());
