include <../../common/regression_common.scad>

use <../../../../polysymmetrica/core/classify.scad>
use <../../../../polysymmetrica/core/construction.scad>
use <../../../../polysymmetrica/core/funcs.scad>
use <../../../../polysymmetrica/core/truncation.scad>
use <../../../../polysymmetrica/models/platonics_all.scad>

OCTA = octahedron();
TETRA = tetrahedron();
TETRA_SKEW = let(v = poly_verts(TETRA), f = poly_faces(TETRA), apex = v[3] + [0.28, -0.12, 0.22])
    [[v[0], v[1], v[2], apex], f, poly_e_over_ir(TETRA)];
TETRA_SKEW_SCALED = [
    [for (v = poly_verts(TETRA_SKEW)) v * 1.6],
    poly_faces(TETRA_SKEW),
    poly_e_over_ir(TETRA_SKEW)
];
TRUNC_DOD = poly_truncate(dodecahedron());
TRI_FACES = ps_classify_face_idxs_by_n(poly_classify(TRUNC_DOD, detail = 0), 3);

TESTS = [
    ["octa_skew_tet", function() poly_attach(OCTA, TETRA_SKEW)],
    ["octa_skew_tet_rotate", function() poly_attach(OCTA, TETRA_SKEW, rotate_step = 1)],
    ["octa_skew_tet_mirror", function() poly_attach(OCTA, TETRA_SKEW, mirror = true)],
    ["octa_skew_tet_fit_edge", function() poly_attach(OCTA, TETRA_SKEW_SCALED, scale_mode = "fit_edge")],
    ["octa_tet_selected_faces", function() poly_attach(OCTA, TETRA, f1 = [0, 2, 4], f2 = 0)],
    ["trunc_dod_tet_tri_family", function() poly_attach(TRUNC_DOD, TETRA, f1 = TRI_FACES, f2 = 0)]
];

T_MAX = len(TESTS);
T = is_undef(T) ? 0 : T;
REG_LIST = is_undef(REG_LIST) ? false : REG_LIST;

assert(T >= 0 && T < T_MAX, str("T out of range: ", T));

if (REG_LIST) {
    reg_list_tests(TESTS);
} else {
    spec = TESTS[T];
    reg_poly_preview(spec[1](), ir = 28, show_face_ids = true);
    reg_panel_label(spec[0]);
}
