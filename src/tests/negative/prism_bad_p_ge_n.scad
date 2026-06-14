use <../../polysymmetrica/core/prisms.scad>

// EXPECT FAIL: p must satisfy p < n
_ = poly_prism(5, p=5);
