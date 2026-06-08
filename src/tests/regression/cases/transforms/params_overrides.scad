include <../../common/regression_common.scad>

use <../../../../polysymmetrica/core/classify.scad>
use <../../../../polysymmetrica/core/funcs.scad>
use <../../../../polysymmetrica/core/truncation.scad>
use <../../../../polysymmetrica/models/platonics_all.scad>

TESTS = [
    ["tet_some_vertices_trunc"],
    ["cube_top_face_cant"],
    ["cube_top_face_chamfer"],
    ["cube_top_face_ct"],
    ["cube_top_face_snub"],
    ["trunc_dod_tri_family_cant"]
];

T_MAX = len(TESTS);
T = is_undef(T) ? 0 : T;
REG_LIST = is_undef(REG_LIST) ? false : REG_LIST;

assert(T >= 0 && T < T_MAX, str("T out of range: ", T));

function _idx_of_max(vals) =
    let(m = max(vals), idxs = [for (i = [0:1:len(vals) - 1]) if (vals[i] == m) i])
    idxs[0];

function _top_face_idx(poly) =
    let(faces = poly_faces(poly))
    _idx_of_max([for (fi = [0:1:len(faces) - 1]) poly_face_center(poly, fi, 1)[2]]);

function _top_face_verts(poly) =
    let(faces = poly_faces(poly), fi = _top_face_idx(poly))
    faces[fi];

function _some_top_verts(poly, n = 4) =
    let(vs = _top_face_verts(poly))
    [for (i = [0:1:min(n - 1, len(vs) - 1)]) vs[i]];

function _tri_family_faces(poly) =
    ps_classify_face_idxs_by_n(poly_classify(poly, detail = 0), 3);

function _po_poly(i) =
    (i == 0) ? poly_truncate(
        tetrahedron(),
        t = 0.001,
        params_overrides = [["vert", "id", _some_top_verts(tetrahedron(), 2), ["t", 0.25]]],
        cleanup = true,
        cleanup_eps = 1e-8
    ) :
    (i == 1) ? poly_cantellate(
        hexahedron(),
        df = 0,
        params_overrides = [["face", "id", [_top_face_idx(hexahedron())], ["df", 0.14]]],
        cleanup = true,
        cleanup_eps = 1e-8
    ) :
    (i == 2) ? poly_chamfer(
        hexahedron(),
        t = 0,
        params_overrides = [["face", "id", [_top_face_idx(hexahedron())], ["t", 0.30]]],
        cleanup = true,
        cleanup_eps = 1e-8
    ) :
    (i == 3) ? poly_cantitruncate(
        hexahedron(),
        t = 0,
        c = 0,
        params_overrides = [
            ["face", "all", ["c", 0.0]],
            ["face", "id", [_top_face_idx(hexahedron())], ["c", 0.40]]
        ],
        cleanup = true,
        cleanup_eps = 1e-8
    ) :
    (i == 4) ? poly_snub(
        hexahedron(),
        angle = 0,
        c = 0,
        df = 0,
        params_overrides = [
            ["face", "all", ["df", 0.2], ["angle", 0]],
            ["face", "id", [_top_face_idx(hexahedron())], ["df", 0.02], ["angle", 25]],
            ["vert", "all", ["c", 0.01]]
        ],
        cleanup = true,
        cleanup_eps = 1e-8
    ) :
    let(p = poly_truncate(dodecahedron()))
    poly_cantellate(
        p,
        df = 0,
        params_overrides = [["face", "id", _tri_family_faces(p), ["df", 0.12]]],
        cleanup = true,
        cleanup_eps = 1e-8
    );

if (REG_LIST) {
    reg_list_tests(TESTS);
} else {
    reg_poly_preview(_po_poly(T), ir = 28, show_face_ids = true);
    reg_panel_label(TESTS[T][0]);
}
