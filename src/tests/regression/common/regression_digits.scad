/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

// Deterministic numeric labels for visual regression scenes.
//
// OpenSCAD text() depends on platform font discovery. These labels use a tiny
// seven-segment geometry font so the generated meshes stay platform-stable.

REG_DIGIT_SEGS = [
    [1, 1, 1, 1, 1, 1, 0], // 0
    [0, 1, 1, 0, 0, 0, 0], // 1
    [1, 1, 0, 1, 1, 0, 1], // 2
    [1, 1, 1, 1, 0, 0, 1], // 3
    [0, 1, 1, 0, 0, 1, 1], // 4
    [1, 0, 1, 1, 0, 1, 1], // 5
    [1, 0, 1, 1, 1, 1, 1], // 6
    [1, 1, 1, 0, 0, 0, 0], // 7
    [1, 1, 1, 1, 1, 1, 1], // 8
    [1, 1, 1, 1, 0, 1, 1]  // 9
];

function reg_digit_count(n) =
    n < 10 ? 1 : 1 + reg_digit_count(floor(n / 10));

function reg_digit_at(n, pos) =
    let(div = pow(10, reg_digit_count(n) - pos - 1))
    floor(n / div) % 10;

function reg_label_width(n, size = 1, gap = 0.22) =
    let(count = reg_digit_count(n))
    count * size + (count - 1) * gap * size;

module _reg_digit_bar(seg, size = 1, thick = 0.24) {
    w = size;
    h = size * 1.55;
    t = thick * size;
    long = w - t;
    y_top = h / 2 - t / 2;
    y_mid = 0;
    y_bot = -h / 2 + t / 2;
    x_left = -w / 2 + t / 2;
    x_right = w / 2 - t / 2;
    y_upper = h / 4;
    y_lower = -h / 4;

    if (seg == 0)
        translate([0, y_top]) square([long, t], center = true);
    else if (seg == 1)
        translate([x_right, y_upper]) square([t, h / 2 - t], center = true);
    else if (seg == 2)
        translate([x_right, y_lower]) square([t, h / 2 - t], center = true);
    else if (seg == 3)
        translate([0, y_bot]) square([long, t], center = true);
    else if (seg == 4)
        translate([x_left, y_lower]) square([t, h / 2 - t], center = true);
    else if (seg == 5)
        translate([x_left, y_upper]) square([t, h / 2 - t], center = true);
    else if (seg == 6)
        translate([0, y_mid]) square([long, t], center = true);
}

module reg_digit_2d(d, size = 1, thick = 0.24) {
    segs = REG_DIGIT_SEGS[d];
    for (seg = [0:1:6])
        if (segs[seg])
            _reg_digit_bar(seg, size, thick);
}

module reg_number_2d(n, size = 1, gap = 0.22, thick = 0.24) {
    count = reg_digit_count(n);
    step = size * (1 + gap);
    x0 = -((count - 1) * step) / 2;

    for (pos = [0:1:count - 1])
        translate([x0 + pos * step, 0])
            reg_digit_2d(reg_digit_at(n, pos), size, thick);
}

module reg_label_num(n, size = 1, h = 0.08, backing = true) {
    w = reg_label_width(n, size);
    if (backing)
        color("white")
            translate([0, 0, -h * 0.15])
                linear_extrude(height = h * 0.35)
                    square([w + size * 0.65, size * 2.1], center = true);

    color("black")
        linear_extrude(height = h)
            reg_number_2d(n, size);
}
