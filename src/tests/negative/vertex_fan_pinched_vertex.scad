/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

use <../../polysymmetrica/core/funcs.scad>

function _pinched_vertex_poly() =
    poly_make(
        [
            [0,0,0],
            [1,0,0], [0,1,0], [0,0,1],
            [-1,0,0], [0,-1,0], [0,0,-1]
        ],
        [
            [0,2,1], [0,1,3], [0,3,2], [1,2,3],
            [0,4,5], [0,6,4], [0,5,6], [4,6,5]
        ],
        1
    );

// EXPECT FAIL: vertex 0 has two disconnected closed fan lobes.
_ = ps_vertex_fan(_pinched_vertex_poly(), 0);
