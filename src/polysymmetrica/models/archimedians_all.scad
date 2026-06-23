/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

// LibFile: polysymmetrica/models/archimedians_all.scad
//   Archimedean solid constructors and collection helpers.

use <../core/truncation.scad>
use <../core/solvers.scad>
use <../models/platonics_all.scad>

// Section: Archimedean Solids
//   Archimedean solids derived from Platonic bases.

// ---- Truncations ----

// Function: truncated_tetrahedron()
// Usage:
//   result = truncated_tetrahedron();
// Description:
//   Return the truncated tetrahedron.
function truncated_tetrahedron() = poly_truncate(tetrahedron());
// Function: truncated_cube()
// Usage:
//   result = truncated_cube();
// Description:
//   Return the truncated cube.
function truncated_cube() = poly_truncate(hexahedron());
// Function: truncated_octahedron()
// Usage:
//   result = truncated_octahedron();
// Description:
//   Return the truncated octahedron.
function truncated_octahedron() = poly_truncate(octahedron());
// Function: truncated_dodecahedron()
// Usage:
//   result = truncated_dodecahedron();
// Description:
//   Return the truncated dodecahedron.
function truncated_dodecahedron() = poly_truncate(dodecahedron());
// Function: truncated_icosahedron()
// Usage:
//   result = truncated_icosahedron();
// Description:
//   Return the truncated icosahedron.
function truncated_icosahedron() = poly_truncate(icosahedron());

// ---- Rectifications ----

// Function: cuboctahedron()
// Usage:
//   result = cuboctahedron();
// Description:
//   Return the cuboctahedron.
function cuboctahedron() = poly_rectify(hexahedron());
// Function: icosidodecahedron()
// Usage:
//   result = icosidodecahedron();
// Description:
//   Return the icosidodecahedron.
function icosidodecahedron() = poly_rectify(dodecahedron());

// ---- Cantellations (small rhombi*) ----

// Function: rhombicuboctahedron()
// Usage:
//   result = rhombicuboctahedron();
// Description:
//   Return the rhombicuboctahedron.
function rhombicuboctahedron() =
    let(
        base = hexahedron(),
        df = solve_cantellate_square_df(base, 0, 1, 40, 0)
    )
    poly_cantellate(base, df);

// Function: rhombicosidodecahedron()
// Usage:
//   result = rhombicosidodecahedron();
// Description:
//   Return the rhombicosidodecahedron.
function rhombicosidodecahedron() =
    let(
        base = dodecahedron(),
        df = solve_cantellate_square_df(base, 0, 1, 40, 0)
    )
    poly_cantellate(base, df);

// ---- Cantitruncations (great rhombi*) ----

// Function: great_rhombicuboctahedron()
// Usage:
//   result = great_rhombicuboctahedron();
// Description:
//   Return the great rhombicuboctahedron.
function great_rhombicuboctahedron() =
    let(
        base = hexahedron(),
        sol = solve_cantitruncate_trig(base)
    )
    poly_cantitruncate(base, sol[0], sol[1]);

// Function: great_rhombicosidodecahedron()
// Usage:
//   result = great_rhombicosidodecahedron();
// Description:
//   Return the great rhombicosidodecahedron.
function great_rhombicosidodecahedron() =
    let(
        base = dodecahedron(),
        sol = solve_cantitruncate_trig(base)
    )
    poly_cantitruncate(base, sol[0], sol[1]);

// ---- Snubs ----

// Function: snub_cube()
// Usage:
//   result = snub_cube();
// Description:
//   Return the snub cube.
function snub_cube() = poly_snub(hexahedron());
// Function: snub_dodecahedron()
// Usage:
//   result = snub_dodecahedron();
// Description:
//   Return the snub dodecahedron.
function snub_dodecahedron() = poly_snub(dodecahedron());

// Function: archimedians_all()
// Usage:
//   result = archimedians_all();
// Description:
//   Return the Archimedean solid registry as `[[name, fn], ...]`, where `fn`
//   is a zero-argument function returning the corresponding poly descriptor.
function archimedians_all() = [
    ["truncated_tetrahedron", function() truncated_tetrahedron()],
    ["truncated_cube", function() truncated_cube()],
    ["truncated_octahedron", function() truncated_octahedron()],
    ["truncated_dodecahedron", function() truncated_dodecahedron()],
    ["truncated_icosahedron", function() truncated_icosahedron()],
    ["cuboctahedron", function() cuboctahedron()],
    ["icosidodecahedron", function() icosidodecahedron()],
    ["rhombicuboctahedron", function() rhombicuboctahedron()],
    ["rhombicosidodecahedron", function() rhombicosidodecahedron()],
    ["great_rhombicuboctahedron", function() great_rhombicuboctahedron()],
    ["great_rhombicosidodecahedron", function() great_rhombicosidodecahedron()],
    ["snub_cube", function() snub_cube()],
    ["snub_dodecahedron", function() snub_dodecahedron()]
];
