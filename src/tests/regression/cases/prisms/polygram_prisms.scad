include <../../common/regression_common.scad>

use <../../../../polysymmetrica/core/funcs.scad>
use <../../../../polysymmetrica/core/prisms.scad>

IR = 30;
EDGE_R = 0.34;
NODE_R = 1.05;
MARK_R = 1.70;
LABEL_Z = 2.0;

TESTS = [
    ["prism_7_3", function() poly_prism(7, p = 3), 7, undef],
    ["prism_7_4_retro", function() poly_prism(7, p = 4), 7, undef],
    ["antiprism_7_2_phase", function() poly_antiprism(7, p = 2), 7, 6],
    ["antiprism_7_4_retro_phase", function() poly_antiprism(7, p = 4), 7, 5],
    ["prism_6_2_compound", function() poly_prism(6, p = 2), 6, undef],
    ["antiprism_6_2_compound", function() poly_antiprism(6, p = 2), 6, undef]
];

T_MAX = len(TESTS);
T = is_undef(T) ? 0 : T;
REG_LIST = is_undef(REG_LIST) ? false : REG_LIST;

assert(T >= 0 && T < T_MAX, str("T out of range: ", T));

function _pp_scaled_verts(poly, ir = IR) =
    [for (v = poly_verts(poly)) v * (ir * poly_e_over_ir(poly))];

function _pp_xy(p) = [p[0], p[1]];

function _pp_dedup_sorted(list, i = 0, acc = []) =
    (i >= len(list)) ? acc :
    _pp_dedup_sorted(
        list,
        i + 1,
        (i > 0 && list[i] == list[i - 1]) ? acc : concat(acc, [list[i]])
    );

function _pp_sorted_unique(list) =
    _pp_dedup_sorted(_ps_sort(list));

function _pp_top_bottom_neighbors(poly, n, top_i) =
    _pp_sorted_unique([
        for (f = poly_faces(poly))
            if (len([for (v = f) if (v == n + top_i) 1]) > 0)
                for (v = f)
                    if (v < n) v
    ]);

module _pp_segment(a, b, r = EDGE_R, h = 0.18) {
    linear_extrude(height = h, center = true)
        hull() {
            translate(a) circle(r = r, $fn = 18);
            translate(b) circle(r = r, $fn = 18);
        }
}

module _pp_node(p, r = NODE_R, h = 0.28) {
    translate(p)
        linear_extrude(height = h, center = true)
            circle(r = r, $fn = 22);
}

module _pp_label(p, s, size = 2.2) {
    translate([p[0], p[1], LABEL_Z])
        reg_text_label(s, size = size, h = 0.09);
}

module _pp_edge_overlay(poly, n, selected_top = undef) {
    verts = _pp_scaled_verts(poly);
    edges = poly_edges(poly);
    selected_bottoms = is_undef(selected_top) ? [] : _pp_top_bottom_neighbors(poly, n, selected_top);

    for (e = edges) {
        a = e[0];
        b = e[1];
        both_bottom = a < n && b < n;
        both_top = a >= n && b >= n;
        is_selected_side = !is_undef(selected_top) &&
            ((a == n + selected_top && b < n) || (b == n + selected_top && a < n));

        color(
            is_selected_side ? "crimson" :
            both_bottom ? "slategray" :
            both_top ? "deepskyblue" :
            "tomato"
        )
            _pp_segment(_pp_xy(verts[a]), _pp_xy(verts[b]), r = is_selected_side ? EDGE_R * 1.8 : EDGE_R);
    }

    for (i = [0:1:n - 1]) {
        color(i == 0 ? "black" : "gold")
            _pp_node(_pp_xy(verts[i]), r = i == 0 ? MARK_R : NODE_R);
        color(i == selected_top ? "crimson" : "lightskyblue")
            _pp_node(_pp_xy(verts[n + i]), r = i == selected_top ? MARK_R * 0.90 : NODE_R * 0.76);
    }

    _pp_label(_pp_xy(verts[0]), "b0", size = 2.1);

    if (!is_undef(selected_top)) {
        _pp_label(_pp_xy(verts[n + selected_top]), str("t", selected_top), size = 2.1);
        for (b = selected_bottoms)
            _pp_label(_pp_xy(verts[b]), str("b", b), size = 1.8);
    }
}

if (REG_LIST) {
    reg_list_tests(TESTS);
} else {
    spec = TESTS[T];
    _pp_edge_overlay(spec[1](), spec[2], spec[3]);
    reg_panel_label(spec[0], y = -43, z = -8, size = 3.0);
}
