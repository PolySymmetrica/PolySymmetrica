/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

use <regression_digits.scad>
use <../../../polysymmetrica/core/funcs.scad>
use <../../../polysymmetrica/core/placement.scad>
use <../../../polysymmetrica/core/segments.scad>

REG_FACE_COLOR = "lightskyblue";
REG_EDGE_COLOR = "tomato";
REG_VERTEX_COLOR = "gold";
REG_SOLID_COLOR = "gainsboro";
REG_LABEL_SIZE = 2.4;
REG_LABEL_H = 0.12;
REG_LABEL_FONT = "Liberation Sans:style=Bold";
REG_RENDER_ARGS_POLY_SINGLE = "--projection=o --camera=0,0,0,55,0,25,280 --render";
REG_RENDER_ARGS_POLY_ROW = "--projection=o --camera=0,0,0,55,0,25,430 --render";
REG_RENDER_ARGS_POLY_GRID = "--projection=o --camera=0,0,0,55,0,25,410 --render";
REG_RENDER_ARGS_FLAT = "--projection=o --camera=0,0,0,0,0,0,380 --render";

module reg_list_tests(tests, render_args = undef) {
    echo(str("REGRESSION_T_MAX=", len(tests)));
    for (i = [0:1:len(tests) - 1])
        echo(str("REGRESSION_TEST=", i, " ", tests[i][0]));

    if (!is_undef(render_args))
        echo(str("REGRESSION_RENDER_ARGS=", render_args));

    cube([0.01, 0.01, 0.01], center = true);
}

module reg_panel_label_num(n, size = REG_LABEL_SIZE, h = REG_LABEL_H) {
    reg_label_num(n, size = size, h = h, backing = true);
}

module reg_text_label(s, size = REG_LABEL_SIZE, h = REG_LABEL_H, font = REG_LABEL_FONT) {
    color("white")
        translate([0, 0, -h * 0.15])
            linear_extrude(height = h * 0.35)
                offset(size * 0.09)
                    text(str(s), size = size, font = font, halign = "center", valign = "center");

    color("black")
        linear_extrude(height = h)
            text(str(s), size = size, font = font, halign = "center", valign = "center");
}

function reg_with_index(a, start = 0) =
    [for (i = [0:1:len(a) - 1]) [i + start, a[i]]];

function reg_cycle_color(i) =
    (i % 8 == 0) ? "tomato" :
    (i % 8 == 1) ? "gold" :
    (i % 8 == 2) ? "mediumseagreen" :
    (i % 8 == 3) ? "deepskyblue" :
    (i % 8 == 4) ? "orchid" :
    (i % 8 == 5) ? "darkorange" :
    (i % 8 == 6) ? "turquoise" :
    "sienna";

module reg_face_fill(thk = 0.16, mode = "nonzero") {
    cells = ps_face_segments($ps_face_pts3d_local, mode);
    for (cell = cells)
        linear_extrude(height = thk, center = true)
            polygon(points = cell[0]);
}

module reg_poly_preview(poly, ir = 28, show_face_ids = false, show_edge_ids = false, show_vertex_ids = false) {
    place_on_faces(poly, ir) {
        color(reg_cycle_color($ps_vertex_count))
            reg_face_fill(0.18);

        if (show_face_ids)
            translate([0, 0, 0.42])
                reg_text_label($ps_face_idx, size = 3.4, h = 0.10);
    }

    color("silver")
        place_on_edges(poly, ir) {
            cube([$ps_edge_len, 0.72, 0.72], center = true);

            if (show_edge_ids)
                translate([0, 1.05, 0.72])
                    reg_text_label($ps_edge_idx, size = 2.1, h = 0.08);
        }

    color(REG_VERTEX_COLOR)
        place_on_vertices(poly, ir) {
            sphere(r = 1.25, $fn = 14);

            if (show_vertex_ids)
                translate([0, 0, 1.75])
                    reg_text_label($ps_vertex_idx, size = 2.0, h = 0.08);
        }
}

module reg_panel_label(s, y = -42, z = -24, size = 3.2, h = 0.16) {
    translate([0, y, z])
        reg_text_label(s, size = size, h = h);
}

module reg_local_segment(seg2d, r = 0.6, h = 0.22) {
    linear_extrude(height = h, center = true)
        hull() {
            translate(seg2d[0]) circle(r = r, $fn = 16);
            translate(seg2d[1]) circle(r = r, $fn = 16);
        }
}

module reg_element_axis(len, r = 0.24) {
    color("black")
        cube([len, r, r], center = true);

    color("limegreen")
        translate([0, len * 0.22, r * 2])
            cube([r, len * 0.44, r], center = true);

    color("crimson")
        translate([0, -len * 0.22, r * 2])
            cube([r, len * 0.44, r], center = true);
}
