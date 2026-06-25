/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

// LibFile: polysymmetrica/core/prisms.scad
use <funcs.scad>

function _ps_prism_height(edge, height, height_scale) =
    ((is_undef(height) ? edge : height) * height_scale);

function _ps_antiprism_height(n, p, edge, angle, eps=1e-12) =
    let(
        r = _ps_polygram_radius(n, p, edge),
        theta = 180 * _ps_polygram_signed_step(n, p) / n + angle,
        d2 = 2 * r * r * (1 - cos(theta)),
        h2 = edge * edge - d2,
        _ok = assert(h2 >= -eps, str("poly_antiprism: invalid angle/edge (no real height), n=", n, " p=", p, " edge=", edge, " angle=", angle))
    )
    (h2 <= 0) ? 0 : sqrt(h2);

// Function: poly_prism()
// Usage:
//   result = poly_prism(n=3, p=1, edge=1, height=undef, height_scale=1);
// Description:
//   Build a regular, star, or compound prism with `{n,p}` caps.
// Arguments:
//   n = cap side count
//   p = polygon step; `p=1` gives a regular prism
//   edge = target edge length
//   height = explicit prism height
//   height_scale = multiplier applied to the chosen height
function poly_prism(n=3, p=1, edge=1, height=undef, height_scale=1) =
    let(
        np = _ps_validate_np(n, p, "poly_prism", allow_compound=true),
        n_eff = np[0],
        p_eff = np[1],
        _e_ok = assert(edge > 0, "poly_prism: edge must be > 0"),
        _hs_ok = assert(height_scale > 0, "poly_prism: height_scale must be > 0"),
        h = _ps_prism_height(edge, height, height_scale),
        _h_ok = assert(h > 0, "poly_prism: height must be > 0"),
        r = _ps_polygram_radius(n_eff, p_eff, edge),
        z0 = -h / 2,
        z1 = h / 2,
        bottom = _ps_ngon_ring(n_eff, r, z0, 0),
        top = _ps_ngon_ring(n_eff, r, z1, 0),
        cycles = _ps_polygram_cycles(n_eff, p_eff),
        verts = concat(bottom, top),
        faces_raw = concat(
            [for (cyc = cycles) cyc], // bottom cap cycle(s) ({n,p})
            [for (cyc = cycles) [for (v = cyc) n_eff + v]], // top cap cycle(s) ({n,p})
            [
                for (cyc = cycles)
                    for (k = [0:1:len(cyc)-1])
                        let(
                            a = cyc[k],
                            b = cyc[(k+1) % len(cyc)]
                        )
                        [a, b, n_eff + b, n_eff + a]
            ]
        ),
        faces = ps_orient_all_faces_outward(verts, faces_raw),
        ir = _ps_poly_ir(verts, faces),
        e_over_ir = edge / ir
    )
    poly_make(verts, faces, e_over_ir);

// Function: poly_antiprism()
// Usage:
//   result = poly_antiprism(n=3, p=1, edge=1, angle=0, height=undef,
//       height_scale=1);
// Description:
//   Build a regular, star, or compound antiprism with `{n,p}` caps and `2n`
//   side triangles.
// Arguments:
//   n = cap side count
//   p = polygon step; `p=1` gives a regular antiprism
//   edge = target edge length
//   angle = additive twist offset in degrees
//   height = explicit antiprism height
//   height_scale = multiplier applied to the chosen height
function poly_antiprism(n=3, p=1, edge=1, angle=0, height=undef, height_scale=1) =
    let(
        np = _ps_validate_np(n, p, "poly_antiprism", allow_compound=true),
        n_eff = np[0],
        p_eff = np[1],
        _e_ok = assert(edge > 0, "poly_antiprism: edge must be > 0"),
        _hs_ok = assert(height_scale > 0, "poly_antiprism: height_scale must be > 0"),
        h_base = is_undef(height) ? _ps_antiprism_height(n_eff, p_eff, edge, angle) : height,
        h = h_base * height_scale,
        _h_ok = assert(h > 0, "poly_antiprism: height must be > 0"),
        r = _ps_polygram_radius(n_eff, p_eff, edge),
        z0 = -h / 2,
        z1 = h / 2,
        theta = 180 * _ps_polygram_signed_step(n_eff, p_eff) / n_eff + angle,
        bottom = _ps_ngon_ring(n_eff, r, z0, 0),
        top = _ps_ngon_ring(n_eff, r, z1, theta),
        cycles = _ps_polygram_cycles(n_eff, p_eff),
        verts = concat(bottom, top),
        faces_raw = concat(
            [for (cyc = cycles) cyc], // bottom cap cycle(s) ({n,p})
            [for (cyc = cycles) [for (v = cyc) n_eff + v]], // top cap cycle(s) ({n,p})
            concat(
                // Side strip: two triangles per cap-cycle edge.
                [
                    for (cyc = cycles)
                        for (k = [0:1:len(cyc)-1])
                            let(
                                a = cyc[k],
                                b = cyc[(k+1) % len(cyc)]
                            )
                            [a, b, n_eff + a]
                ],
                [
                    for (cyc = cycles)
                        for (k = [0:1:len(cyc)-1])
                            let(
                                a = cyc[k],
                                b = cyc[(k+1) % len(cyc)]
                            )
                            [b, n_eff + b, n_eff + a]
                ]
            )
        ),
        faces = ps_orient_all_faces_outward(verts, faces_raw),
        ir = _ps_poly_ir(verts, faces),
        e_over_ir = edge / ir
    )
    poly_make(verts, faces, e_over_ir);
