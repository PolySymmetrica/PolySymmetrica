include <../../common/regression_common.scad>

use <../../../../polysymmetrica/core/duals.scad>
use <../../../../polysymmetrica/core/prisms.scad>
use <../../../../polysymmetrica/core/solvers.scad>
use <../../../../polysymmetrica/core/truncation.scad>
use <../../../../polysymmetrica/models/platonics_all.scad>
use <../../../../polysymmetrica/models/archimedians_all.scad>

TESTS = [
    ["tet_truncate", function() poly_truncate(tetrahedron())],
    ["cube_rectify", function() poly_rectify(hexahedron())],
    ["dod_chamfer", function() poly_chamfer(dodecahedron())],
    ["ico_cantellate", function() poly_cantellate(icosahedron())],
    ["tet_cantitruncate", function() poly_cantitruncate(tetrahedron())],
    ["cube_snub", function() poly_snub(hexahedron(), c = 0.06, df = 0.03, angle = 12)],
    ["prism6_dual", function() poly_dual(poly_prism(6))],
    ["prism6_cantellate", function() poly_cantellate(poly_prism(6))],
    ["ap5_2_truncate", function() poly_truncate(poly_antiprism(5, 2), t = 0.18)],
    ["ap7_twist_cantellate", function() poly_cantellate(poly_antiprism(7, 3, angle = 12), profile = _tm_ap7_rows())],
    ["trunc_dod_dual", function() poly_dual(truncated_dodecahedron())],
    [
        "cuboct_dominant_ct",
        function() poly_cantitruncate(
            cuboctahedron(),
            t = 0,
            c = 0,
            profile = solve_cantitruncate_dominant_edges_params(cuboctahedron(), 4)
        )
    ]
];

T_MAX = len(TESTS);
T = is_undef(T) ? 0 : T;
REG_LIST = is_undef(REG_LIST) ? false : REG_LIST;

assert(T >= 0 && T < T_MAX, str("T out of range: ", T));

function _tm_ap7_rows() = [
    ["face", "family", 0, ["df", 0.30]],
    ["face", "family", 1, ["df", 0.30]]
];

if (REG_LIST) {
    reg_list_tests(TESTS);
} else {
    spec = TESTS[T];
    reg_poly_preview(spec[1](), ir = 28, show_face_ids = true);
    reg_panel_label(spec[0]);
}
