/**
Defines the dodecahedron - derived from icosahedron() using poly_dual().
*/

use <../core/duals.scad>
use <icosahedron.scad>

function dodecahedron() = poly_dual(icosahedron());
