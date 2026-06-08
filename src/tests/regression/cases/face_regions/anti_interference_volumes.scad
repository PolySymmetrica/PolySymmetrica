include <../../common/regression_common.scad>

use <../../../../polysymmetrica/core/face_regions.scad>
use <../../../../polysymmetrica/core/placement.scad>
use <../../../../polysymmetrica/core/prisms.scad>
use <../../../../polysymmetrica/core/segments.scad>
use <../../../../polysymmetrica/core/truncation.scad>
use <../../../../polysymmetrica/models/dodecahedron.scad>
use <../../../../polysymmetrica/models/tetrahedron.scad>

TESTS = [
    ["dodeca_volume_control"],
    ["star_ap_volume"],
    ["atut_hex_volume"],
    ["atut_hex_volume_inset"]
];

T_MAX = len(TESTS);
T = is_undef(T) ? 0 : T;
REG_LIST = is_undef(REG_LIST) ? false : REG_LIST;

assert(T >= 0 && T < T_MAX, str("T out of range: ", T));

IR = 30;
Z0 = -2.0;
Z1 = 2.0;
MAX_PROJECT = 40;
DOD_POLY = dodecahedron();
STAR_POLY = poly_antiprism(5, 2);
ATUT_POLY = poly_truncate(tetrahedron(), t = -0.5);

function _poly_for(i) = (i == 0) ? DOD_POLY : (i == 1) ? STAR_POLY : ATUT_POLY;
function _face_for(i) = (i == 0) ? 0 : (i == 1) ? 0 : 0;
function _inset_for(i) = (i == 3) ? 1.2 : 0;

module _wire_context(poly, face_idx) {
    color("silver")
        place_on_edges(poly, IR)
            cube([$ps_edge_len, 0.6, 0.6], center = true);

    color("gold")
        place_on_vertices(poly, IR)
            sphere(r = 1.0, $fn = 12);

    place_on_faces(poly, IR)
        if ($ps_face_idx == face_idx)
            translate([0, 0, 0.58])
                reg_text_label(str("f", $ps_face_idx), size = 2.0, h = 0.08);
}

module _volume_panel(poly, face_idx, label_s, boundary_inset = 0) {
    _wire_context(poly, face_idx);

    place_on_faces(poly, IR)
        if ($ps_face_idx == face_idx) {
            color("gainsboro", 0.28)
                translate([0, 0, -0.18])
                    reg_face_fill(0.24);

            color("deepskyblue", 0.36)
                ps_face_anti_interference_volume(
                    Z0,
                    Z1,
                    mode = "nonzero",
                    max_project = MAX_PROJECT,
                    boundary_inset = boundary_inset
                );

            color("black")
                place_on_face_boundary_spans(mode = "nonzero")
                    cube([$ps_boundary_span_len, 0.54, 0.54], center = true);

            shells = ps_face_anti_interference_shells(
                $ps_face_local_context,
                Z0,
                Z1,
                "nonzero",
                MAX_PROJECT,
                boundary_inset = boundary_inset
            );

            for (shell = shells) {
                color(ps_face_anti_interference_shell_exposure_sign(shell) > 0 ? "navy" : "crimson")
                    for (pt = ps_face_anti_interference_shell_points(shell))
                        translate(pt)
                            sphere(r = 0.62, $fn = 10);

                top = ps_face_anti_interference_shell_top_loop2d(shell);
                if (len(top) > 0)
                    translate([ps_centroid2d(top)[0], ps_centroid2d(top)[1], Z1 + 0.35])
                        reg_text_label(
                            str("L", ps_face_anti_interference_shell_loop_idx(shell)),
                            size = 1.5,
                            h = 0.06
                        );
            }
        }

    reg_panel_label(label_s);
}

if (REG_LIST) {
    reg_list_tests(TESTS);
} else {
    _volume_panel(_poly_for(T), _face_for(T), TESTS[T][0], boundary_inset = _inset_for(T));
}
