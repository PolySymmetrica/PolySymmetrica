use <../../polysymmetrica/core/prisms.scad>

// EXPECT FAIL: p=n/2 gives diameter cycles, not polygonal faces
_ = poly_antiprism(6, p=3);
