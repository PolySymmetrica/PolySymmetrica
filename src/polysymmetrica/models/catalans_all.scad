/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

// LibFile: polysymmetrica/models/catalans_all.scad
//   Catalan solid constructors and Archimedean pairing helpers.

use <../core/duals.scad>
use <../models/archimedians_all.scad>

// Section: Catalan Solids
//   Catalan solids derived as duals of Archimedean solids.

// ---- Duals of truncations ----

// Function: triakis_tetrahedron()
// Usage:
//   result = triakis_tetrahedron();
// Description:
//   Return the triakis tetrahedron.
function triakis_tetrahedron() = poly_dual(truncated_tetrahedron());
// Function: triakis_octahedron()
// Usage:
//   result = triakis_octahedron();
// Description:
//   Return the triakis octahedron.
function triakis_octahedron() = poly_dual(truncated_cube());
// Function: tetrakis_hexahedron()
// Usage:
//   result = tetrakis_hexahedron();
// Description:
//   Return the tetrakis hexahedron.
function tetrakis_hexahedron() = poly_dual(truncated_octahedron());
// Function: triakis_icosahedron()
// Usage:
//   result = triakis_icosahedron();
// Description:
//   Return the triakis icosahedron.
function triakis_icosahedron() = poly_dual(truncated_dodecahedron());
// Function: pentakis_dodecahedron()
// Usage:
//   result = pentakis_dodecahedron();
// Description:
//   Return the pentakis dodecahedron.
function pentakis_dodecahedron() = poly_dual(truncated_icosahedron());

// ---- Duals of rectifications ----

// Function: rhombic_dodecahedron()
// Usage:
//   result = rhombic_dodecahedron();
// Description:
//   Return the rhombic dodecahedron.
function rhombic_dodecahedron() = poly_dual(cuboctahedron());
// Function: rhombic_triacontahedron()
// Usage:
//   result = rhombic_triacontahedron();
// Description:
//   Return the rhombic triacontahedron.
function rhombic_triacontahedron() = poly_dual(icosidodecahedron());

// ---- Duals of cantellations (small rhombi*) ----

// Function: deltoidal_icositetrahedron()
// Usage:
//   result = deltoidal_icositetrahedron();
// Description:
//   Return the deltoidal icositetrahedron.
function deltoidal_icositetrahedron() = poly_dual(rhombicuboctahedron());
// Function: deltoidal_hexecontahedron()
// Usage:
//   result = deltoidal_hexecontahedron();
// Description:
//   Return the deltoidal hexecontahedron.
function deltoidal_hexecontahedron() = poly_dual(rhombicosidodecahedron());

// ---- Duals of cantitruncations (great rhombi*) ----

// Function: disdyakis_dodecahedron()
// Usage:
//   result = disdyakis_dodecahedron();
// Description:
//   Return the disdyakis dodecahedron.
function disdyakis_dodecahedron() = poly_dual(great_rhombicuboctahedron());
// Function: disdyakis_triacontahedron()
// Usage:
//   result = disdyakis_triacontahedron();
// Description:
//   Return the disdyakis triacontahedron.
function disdyakis_triacontahedron() = poly_dual(great_rhombicosidodecahedron());

// ---- Snub duals ----

// Function: pentagonal_icositetrahedron()
// Usage:
//   result = pentagonal_icositetrahedron();
// Description:
//   Return the pentagonal icositetrahedron.
function pentagonal_icositetrahedron() = poly_dual(snub_cube());
// Function: pentagonal_hexecontahedron()
// Usage:
//   result = pentagonal_hexecontahedron();
// Description:
//   Return the pentagonal hexecontahedron.
function pentagonal_hexecontahedron() = poly_dual(snub_dodecahedron());

// Archimedean -> Catalan name mapping (for pairing in demos)
// Function: archimedean_catalan_name_pairs()
// Usage:
//   result = archimedean_catalan_name_pairs();
// Description:
//   Return the Archimedean-to-Catalan name mapping used by demos and pairing
//   helpers.
function archimedean_catalan_name_pairs() = [
    ["truncated_tetrahedron", "triakis_tetrahedron"],
    ["truncated_cube", "triakis_octahedron"],
    ["truncated_octahedron", "tetrakis_hexahedron"],
    ["truncated_dodecahedron", "triakis_icosahedron"],
    ["truncated_icosahedron", "pentakis_dodecahedron"],
    ["cuboctahedron", "rhombic_dodecahedron"],
    ["icosidodecahedron", "rhombic_triacontahedron"],
    ["rhombicuboctahedron", "deltoidal_icositetrahedron"],
    ["rhombicosidodecahedron", "deltoidal_hexecontahedron"],
    ["great_rhombicuboctahedron", "disdyakis_dodecahedron"],
    ["great_rhombicosidodecahedron", "disdyakis_triacontahedron"],
    ["snub_cube", "pentagonal_icositetrahedron"],
    ["snub_dodecahedron", "pentagonal_hexecontahedron"]
];

// Function: archimedean_to_catalan_name()
// Usage:
//   result = archimedean_to_catalan_name(n);
// Description:
//   Look up the Catalan solid name paired with one Archimedean solid name.
// Arguments:
//   n = Archimedean solid function name
function archimedean_to_catalan_name(n) =
    let(
        pairs = archimedean_catalan_name_pairs(),
        idxs = search([n], [for (p = pairs) p[0]], 1)
    )
    (len(idxs) == 0 || idxs[0] < 0) ? undef : pairs[idxs[0]][1];

// Function: catalans_all()
// Usage:
//   result = catalans_all();
// Description:
//   Return the Catalan solid registry as `[[name, fn], ...]`, where `fn` is a
//   zero-argument function returning the corresponding poly descriptor.
function catalans_all() = [
    ["triakis_tetrahedron", function() triakis_tetrahedron()],
    ["triakis_octahedron", function() triakis_octahedron()],
    ["tetrakis_hexahedron", function() tetrakis_hexahedron()],
    ["triakis_icosahedron", function() triakis_icosahedron()],
    ["pentakis_dodecahedron", function() pentakis_dodecahedron()],
    ["rhombic_dodecahedron", function() rhombic_dodecahedron()],
    ["rhombic_triacontahedron", function() rhombic_triacontahedron()],
    ["deltoidal_icositetrahedron", function() deltoidal_icositetrahedron()],
    ["deltoidal_hexecontahedron", function() deltoidal_hexecontahedron()],
    ["disdyakis_dodecahedron", function() disdyakis_dodecahedron()],
    ["disdyakis_triacontahedron", function() disdyakis_triacontahedron()],
    ["pentagonal_icositetrahedron", function() pentagonal_icositetrahedron()],
    ["pentagonal_hexecontahedron", function() pentagonal_hexecontahedron()]
];
