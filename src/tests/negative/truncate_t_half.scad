// This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
// Copyright 2025-2026 Susan Witts
// SPDX-License-Identifier: MIT

use <../../polysymmetrica/core/funcs.scad>
use <../../polysymmetrica/core/truncation.scad>

function _tetra_poly() =
    poly_make(
        [[1,1,1],[-1,-1,1],[-1,1,-1],[1,-1,-1]],
        [[0,1,2],[0,3,1],[0,2,3],[1,3,2]]
    );

// EXPECT FAIL: t out of range
_ = poly_truncate(_tetra_poly(), 0.5);

