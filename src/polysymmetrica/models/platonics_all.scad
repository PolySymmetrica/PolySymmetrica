/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

// LibFile: polysymmetrica/models/platonics_all.scad
//   Convenience includes and collection helpers for the five Platonic solids.

include <tetrahedron.scad>
include <octahedron.scad>
include <icosahedron.scad>

include <hexahedron.scad>
include <dodecahedron.scad>

// Function: platonics_all()
// Usage:
//   result = platonics_all();
// Description:
//   Return the Platonic solid registry as `[[name, fn], ...]`, where `fn` is a
//   zero-argument function returning the corresponding poly descriptor.
function platonics_all() = [
    ["tetrahedron", function() tetrahedron()],
    ["hexahedron", function() hexahedron()],
    ["octahedron", function() octahedron()],
    ["dodecahedron", function() dodecahedron()],
    ["icosahedron", function() icosahedron()]
];
