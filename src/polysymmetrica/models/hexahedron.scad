
/**
Defines the hexahedron (simple cube!) - derived from icosahedron() using poly_dual().
*/

use <../core/duals.scad>
use <octahedron.scad>

function hexahedron() = poly_dual(octahedron());
