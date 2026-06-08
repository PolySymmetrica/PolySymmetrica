include <../../common/regression_common.scad>

use <../../../../polysymmetrica/core/duals.scad>
use <../../../../polysymmetrica/core/prisms.scad>
use <../../../../polysymmetrica/core/solvers.scad>
use <../../../../polysymmetrica/core/truncation.scad>
use <../../../../polysymmetrica/models/platonics_all.scad>
use <../../../../polysymmetrica/models/archimedians_all.scad>

TESTS = [
    ["tet_truncate"],
    ["cube_rectify"],
    ["dod_chamfer"],
    ["ico_cantellate"],
    ["tet_cantitruncate"],
    ["cube_snub"],
    ["prism6_dual"],
    ["prism6_cantellate"],
    ["ap5_2_truncate"],
    ["ap7_twist_cantellate"],
    ["trunc_dod_dual"],
    ["cuboct_dominant_ct"]
];

T_MAX = len(TESTS);
T = is_undef(T) ? 0 : T;
REG_LIST = is_undef(REG_LIST) ? false : REG_LIST;

assert(T >= 0 && T < T_MAX, str("T out of range: ", T));

function _tm_ap7_rows() = [
    ["face", "family", 0, ["df", 0.30]],
    ["face", "family", 1, ["df", 0.30]]
];

function _tm_poly(i) =
    (i == 0) ? poly_truncate(tetrahedron()) :
    (i == 1) ? poly_rectify(hexahedron()) :
    (i == 2) ? poly_chamfer(dodecahedron()) :
    (i == 3) ? poly_cantellate(icosahedron()) :
    (i == 4) ? poly_cantitruncate(tetrahedron()) :
    (i == 5) ? poly_snub(hexahedron(), c = 0.06, df = 0.03, angle = 12) :
    (i == 6) ? poly_dual(poly_prism(6)) :
    (i == 7) ? poly_cantellate(poly_prism(6)) :
    (i == 8) ? poly_truncate(poly_antiprism(5, 2), t = 0.18) :
    (i == 9) ? poly_cantellate(poly_antiprism(7, 3, angle = 12), params_overrides = _tm_ap7_rows()) :
    (i == 10) ? poly_dual(truncated_dodecahedron()) :
    poly_cantitruncate(
        cuboctahedron(),
        t = 0,
        c = 0,
        params_overrides = solve_cantitruncate_dominant_edges_params(cuboctahedron(), 4)
    );

if (REG_LIST) {
    reg_list_tests(TESTS);
} else {
    reg_poly_preview(_tm_poly(T), ir = 28, show_face_ids = true);
    reg_panel_label(TESTS[T][0]);
}
