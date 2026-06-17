// This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
// Copyright 2025-2026 Susan Witts
// SPDX-License-Identifier: MIT

/**
Defines the hexahedron (simple cube!) - derived from icosahedron() using poly_dual().
*/

use <../core/duals.scad>
use <octahedron.scad>

function hexahedron() = poly_dual(octahedron());
