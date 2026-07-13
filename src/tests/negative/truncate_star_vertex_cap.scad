/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

use <../../polysymmetrica/core/funcs.scad>
use <../../polysymmetrica/core/truncation.scad>

function _star_fan_pyramid() =
    let(
        s = [1, 3, 5, 2, 4],
        base = [for (i = [0:1:4]) [cos(90 + i * 72), sin(90 + i * 72), 0]],
        verts = concat([[0, 0, 1]], base),
        side_faces = [
            for (i = [0:1:len(s)-1])
                [0, s[i], s[(i + 1) % len(s)]]
        ],
        base_face = [for (i = [len(s)-1:-1:0]) s[i]]
    )
    poly_make(verts, concat(side_faces, [base_face]), 1);

// EXPECT FAIL: truncating the apex would create a self-crossing vertex cap.
_ = poly_truncate(_star_fan_pyramid(), 0.2);
