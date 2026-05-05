use <../../core/funcs.scad>
use <../../core/face_regions.scad>
use <../../core/placement.scad>
use <../../core/prisms.scad>
use <../../core/segments.scad>

// Minimum face radius before adding the pillow (mm).
FACE_PLATE_PILLOW_MIN_RAD = 5;
// Pillow inset at the face surface (mm).
FACE_PLATE_PILLOW_INSET = 2;
// Additional pillow inset at the raised height (mm).
FACE_PLATE_PILLOW_RAMP = 1;
// Pillow thickness above the face (mm).
FACE_PLATE_PILLOW_THK = 0.4;

// Clearance height for face sockets (mm) - make larger if face is far inset into a face.
FACE_PLATE_CLEAR_HEIGHT = 10;
// Diameter for generated seam support bars (mm).
FACE_PLATE_SEAM_SUPPORT_T = 2.2;

/**
 * Module: Emit one raised pillow loop.
 * Params: pts (2D loop), top_z (face top plane), pillow_min_rad/inset/ramp/thk (pillow sizing), eps (tolerance)
 * Returns: none
 */
module _face_plate_pillow_loop(pts, top_z, pillow_min_rad, pillow_inset, pillow_ramp, pillow_thk, eps) {
    loop_centroid = [
        sum([for (p = pts) p[0]]) / len(pts),
        sum([for (p = pts) p[1]]) / len(pts)
    ];
    loop_rad = sum([for (p = pts) norm([p[0] - loop_centroid[0], p[1] - loop_centroid[1]])]) / len(pts);
    if (loop_rad > pillow_min_rad && loop_rad > pillow_inset + pillow_ramp + eps) {
        s0 = max(0, 1 - pillow_inset / loop_rad);
        s1 = max(0, 1 - (pillow_inset + pillow_ramp) / loop_rad);
        p0 = [for (p = pts) [
            loop_centroid[0] + (p[0] - loop_centroid[0]) * s0,
            loop_centroid[1] + (p[1] - loop_centroid[1]) * s0
        ]];
        scale_xy = s0 <= eps ? 0 : (s1 / s0);
        translate([0, 0, top_z])
            linear_extrude(height = pillow_thk, scale = scale_xy)
                ps_polygon(points = p0, mode = "nonzero");
    }
}

/**
 * Function: Compute the centerline offset for a seam bar tangent to two face underside planes.
 * Params: foreign_n (foreign face +Z normal in current face-local coords), top_z (current underside plane), support_t (bar diameter), eps (degeneracy tolerance)
 * Returns: 3D offset from the source seam line to the support centerline
 */
function _face_plate_bisector_support_offset(foreign_n, top_z, support_t, eps=1e-8) =
    let(
        n0 = [0, 0, 1],
        n1 = is_undef(foreign_n) || norm(foreign_n) <= eps ? undef : v_norm(foreign_n),
        q = top_z - support_t / 2,
        c = is_undef(n1) ? undef : v_dot(n0, n1)
    )
    (is_undef(n1) || abs(1 + c) <= eps)
        ? [0, 0, q]
        : (n0 + n1) * (q / (1 + c));

/**
 * Module: Emit one rounded support bar along a face-local 2D segment on a bisector offset.
 * Params: seg2d (face-local seam segment), support_t (bar diameter), top_z (current underside plane), foreign_n (foreign face +Z normal in current face-local coords), extend (extra length at each end), eps (tolerance)
 * Returns: none
 */
module _face_plate_bisector_segment_support_bar(seg2d, support_t, top_z, foreign_n, extend, eps) {
    d = seg2d[1] - seg2d[0];
    len_d = norm(d);
    u = (len_d <= eps) ? [1, 0] : d / len_d;
    off = _face_plate_bisector_support_offset(foreign_n, top_z, support_t, eps);

    hull() {
        translate([seg2d[0][0] - u[0] * extend, seg2d[0][1] - u[1] * extend, 0] + off)
            sphere(d = support_t, $fn = 20);
        translate([seg2d[1][0] + u[0] * extend, seg2d[1][1] + u[1] * extend, 0] + off)
            sphere(d = support_t, $fn = 20);
    }
}

/**
 * Module: Emit printable support bars under generated cut seams.
 * Params: support_t (bar diameter), top_z (bar top plane; defaults to `base_z` or `0`), base_z (face underside used when `top_z` is omitted), extend (extra length at each span end), mode/eps/kind (boundary-span selection)
 * Returns: none
 * Limitations/Gotchas: intended for use inside `place_on_faces(...)`; defaults to `generated_cut` so split real source edges do not get duplicate support bars
 */
module face_generated_seam_supports(
    support_t = FACE_PLATE_SEAM_SUPPORT_T,
    top_z = undef,
    base_z = undef,
    extend = 0,
    mode = "nonzero",
    eps = 1e-4,
    kind = "generated_cut"
) {
    assert(support_t > 0, "face_generated_seam_supports: support_t must be > 0");
    assert(extend >= 0, "face_generated_seam_supports: extend must be >= 0");

    top_z_eff = is_undef(top_z) ? (is_undef(base_z) ? 0 : base_z) : top_z;

    place_on_face_boundary_spans(mode = mode, eps = eps, coords = "parent", kind = kind) {
        if ($ps_boundary_span_len > eps)
            _face_plate_bisector_segment_support_bar(
                $ps_boundary_span_segment2d_local,
                support_t,
                top_z_eff,
                $ps_boundary_span_adj_face_normal_local,
                extend,
                eps);
    }
}

/**
 * Module: Emit printable support bars under exact foreign face cut seams.
 * Params: support_t (bar diameter), top_z (bar top plane; defaults to `base_z` or `0`), base_z (face underside used when `top_z` is omitted), extend (extra length at each segment end), mode/eps/filter_parent (foreign cut selection), foreign_indices (optional accepted foreign face ids)
 * Returns: none
 * Limitations/Gotchas: intended for use inside `place_on_faces(...)`; these are face-plane cut supports, not arbitrary already-rendered child geometry
 */
module face_foreign_cut_seam_supports(
    support_t = FACE_PLATE_SEAM_SUPPORT_T,
    top_z = undef,
    base_z = undef,
    extend = 0,
    mode = "nonzero",
    eps = 1e-4,
    filter_parent = true,
    foreign_indices = undef
) {
    assert(support_t > 0, "face_foreign_cut_seam_supports: support_t must be > 0");
    assert(extend >= 0, "face_foreign_cut_seam_supports: extend must be >= 0");
    assert(!is_undef($ps_poly_faces_idx), "face_foreign_cut_seam_supports: requires place_on_faces context ($ps_poly_faces_idx)");
    assert(!is_undef($ps_poly_verts_local), "face_foreign_cut_seam_supports: requires place_on_faces context ($ps_poly_verts_local)");

    top_z_eff = is_undef(top_z) ? (is_undef(base_z) ? 0 : base_z) : top_z;

    place_on_face_foreign_intrusions(mode = mode, eps = eps, filter_parent = filter_parent) {
        seg = $ps_intrusion_segment2d_local;
        if (norm(seg[1] - seg[0]) > eps)
            if (is_undef(foreign_indices) || len(search($ps_intrusion_foreign_idx, foreign_indices)) > 0)
                _face_plate_bisector_segment_support_bar(
                    seg,
                    support_t,
                    top_z_eff,
                    ps_face_frame_normal($ps_poly_verts_local, $ps_poly_faces_idx[$ps_intrusion_foreign_idx], eps),
                    extend,
                    eps);
    }
}

/**
 * Module: Emit a face plate clipped by the current face's anti-interference volume.
 * Params: face_thk (plate thickness), idx/face_pts3d_local/poly_faces_idx/poly_verts_local/face_neighbors_idx/face_dihedrals (optional overrides; default from `place_on_faces` context), clear_space (emit clearance cutter), pillow_* (raised pillow sizing), base_z (bottom Z; defaults to `-face_thk` so the top sits on the source face plane), clear_height (clearance height), mode/max_project/boundary_inset/boundary_inset_mode/eps/convexity (anti-interference controls)
 * Returns: none
 * Limitations/Gotchas: requires `place_on_faces` context or explicit context overrides; pillow and clear-space cutter follow the generated shell top loops
 */
module face_plate(face_thk,
    idx = $ps_face_idx,
    face_pts3d_local = $ps_face_pts3d_local,
    poly_faces_idx = $ps_poly_faces_idx,
    poly_verts_local = $ps_poly_verts_local,
    face_neighbors_idx = $ps_face_neighbors_idx,
    face_dihedrals = $ps_face_dihedrals,
    clear_space=false,
    pillow_min_rad = FACE_PLATE_PILLOW_MIN_RAD,
    pillow_inset = FACE_PLATE_PILLOW_INSET,
    pillow_ramp = FACE_PLATE_PILLOW_RAMP,
    pillow_thk = FACE_PLATE_PILLOW_THK,
    base_z = undef,
    clear_height = FACE_PLATE_CLEAR_HEIGHT,
    mode = "nonzero",
    max_project = undef,
    boundary_inset = 0,
    boundary_inset_mode = "side",
    eps = 1e-4,
    convexity = 6
) {
    assert(!is_undef(idx), "face_plate: idx requires place_on_faces context or an explicit override");
    assert(!is_undef(face_pts3d_local), "face_plate: face_pts3d_local requires place_on_faces context or an explicit override");
    assert(!is_undef(poly_faces_idx), "face_plate: poly_faces_idx requires place_on_faces context or an explicit override");
    assert(!is_undef(poly_verts_local), "face_plate: poly_verts_local requires place_on_faces context or an explicit override");
    assert(!is_undef(face_neighbors_idx), "face_plate: face_neighbors_idx requires place_on_faces context or an explicit override");
    assert(!is_undef(face_dihedrals), "face_plate: face_dihedrals requires place_on_faces context or an explicit override");

    base_z_eff = is_undef(base_z) ? -face_thk : base_z;
    top_z = base_z_eff + face_thk;
    pts = ps_xy(face_pts3d_local);
    shells = ps_face_anti_interference_shells(
        face_pts3d_local,
        idx,
        poly_faces_idx,
        poly_verts_local,
        face_neighbors_idx,
        face_dihedrals,
        base_z_eff,
        top_z,
        mode,
        max_project,
        eps,
        boundary_inset,
        boundary_inset_mode
    );

    color(len(pts) == 3 ? "white" : "red") {
        union() {
            for (shell = shells) {
                if (shell[3] > 0)
                    echo(str("face_plate: capped ", shell[3], " projection(s) on face ", idx, " loop ", shell[2]));

                polyhedron(
                    points = ps_face_anti_interference_shell_points(shell),
                    faces = ps_face_anti_interference_shell_faces(shell),
                    convexity = convexity
                );
            }
        }

        for (shell = shells)
            _face_plate_pillow_loop(
                    ps_face_anti_interference_shell_top_loop2d(shell),
                    top_z, pillow_min_rad, pillow_inset, pillow_ramp, pillow_thk, eps);
    }

    if (clear_space)
        color("magenta")
            translate([0, 0, top_z - eps])
                linear_extrude(height = clear_height)
                    union() {
                        for (shell = shells)
                            ps_polygon(points = ps_face_anti_interference_shell_top_loop2d(shell), mode = "nonzero");
                    }
}

// Direct smoke demo: subtract one placed star face cutter from a cube.
_demo_poly = poly_antiprism(n=5, p=2, angle=15);
difference() {
    translate([0, -15, -15]) cube(30);

    place_on_faces(_demo_poly, 17)
        if ($ps_face_idx == 1)
            #face_plate(face_thk=1.2, clear_space=false, max_project=10);
}
