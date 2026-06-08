include <../../common/regression_common.scad>

use <../../../../polysymmetrica/core/placement.scad>
use <../../../../polysymmetrica/models/platonics_all.scad>
use <../../../../polysymmetrica/models/archimedians_all.scad>

TESTS = [
    ["tet", tetrahedron()],
    ["cube", hexahedron()],
    ["oct", octahedron()],
    ["dod", dodecahedron()],
    ["ico", icosahedron()],
    ["trunc_tet", truncated_tetrahedron()],
    ["trunc_cube", truncated_cube()],
    ["trunc_oct", truncated_octahedron()],
    ["trunc_dod", truncated_dodecahedron()],
    ["trunc_ico", truncated_icosahedron()]
];

T_MAX = len(TESTS);
T = is_undef(T) ? 0 : T;
REG_LIST = is_undef(REG_LIST) ? false : REG_LIST;

assert(T >= 0 && T < T_MAX, str("T out of range: ", T));

P = TESTS[T][1];
IR = 26;
PANEL_SPACING = 78;

module _face_panel(poly) {
    place_on_faces(poly, IR) {
        color(REG_FACE_COLOR)
            translate([0, 0, -0.08])
                linear_extrude(height = 0.16, center = true)
                    polygon(points = $ps_face_pts2d);

        translate([0, 0, 0.10])
            reg_text_label($ps_face_idx, size = 4.2, h = 0.11);
    }
}

module _edge_panel(poly) {
    place_on_edges(poly, IR) {
        color(REG_EDGE_COLOR)
            cube([$ps_edge_len, 0.72, 0.72], center = true);

        translate([0, 1.05, 0.72])
            reg_text_label($ps_edge_idx, size = 2.75, h = 0.10);
    }
}

module _vertex_panel(poly) {
    place_on_vertices(poly, IR) {
        color(REG_VERTEX_COLOR)
            sphere(r = 1.35, $fn = 18);

        translate([0, 0, 1.95])
            reg_text_label($ps_vertex_idx, size = 2.75, h = 0.10);
    }
}

module render_scene(poly) {
    translate([-PANEL_SPACING, 0, 0])
        _face_panel(poly);

    _edge_panel(poly);

    translate([PANEL_SPACING, 0, 0])
        _vertex_panel(poly);
}

if (REG_LIST) {
    reg_list_tests(TESTS);
} else {
    render_scene(P);
}
