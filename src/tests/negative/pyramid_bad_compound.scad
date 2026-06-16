use <../../polysymmetrica/core/construction.scad>

// EXPECT FAIL: compound pyramid bases would share one apex
_ = poly_pyramid(6, p=2);
