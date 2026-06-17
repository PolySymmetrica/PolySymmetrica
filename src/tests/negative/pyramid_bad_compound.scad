// This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
// Copyright 2025-2026 Susan Witts
// SPDX-License-Identifier: MIT

use <../../polysymmetrica/core/construction.scad>

// EXPECT FAIL: compound pyramid bases would share one apex
_ = poly_pyramid(6, p=2);
