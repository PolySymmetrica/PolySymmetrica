use <../../core/funcs.scad>
use <../../core/face_regions.scad>
use <../../core/loop_shells.scad>
use <../../core/placement.scad>
use <../../core/segments.scad>

// Minimum face radius before adding the pillow (mm).
FACE_PLATE_PILLOW_MIN_RAD = 5;
// Pillow inset at the face surface (mm).
FACE_PLATE_PILLOW_INSET = 3;
// Additional pillow inset at the raised height (mm).
FACE_PLATE_PILLOW_RAMP = 1;
// Pillow thickness above the face (mm).
FACE_PLATE_PILLOW_THK = 0.4;
// Stable full-footprint thickness at the structural face top (mm).
FACE_PLATE_TOP_THK = 0.3;

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
                ps_polygon(points = p0);
    }
}

/**
 * Function: Compute a seam-frame support centerline offset tangent to the current face underside.
 * Params: current_n_seam_local (current face normal in seam element coords), top_z (current underside plane), support_t (bar diameter), eps (degeneracy tolerance)
 * Returns: 3D offset in seam element coords
 */
function _face_plate_seam_support_offset(current_n_seam_local, top_z, support_t, eps=1e-8) =
    let(
        q = top_z - support_t / 2,
        n = is_undef(current_n_seam_local) || norm(current_n_seam_local) <= eps
            ? [0, 0, 1]
            : v_norm(current_n_seam_local)
    )
    abs(n[2]) > eps ? [0, 0, q / n[2]] : n * q;

/**
 * Module: Emit one rounded support bar in the current seam element frame.
 * Params: support_t (bar diameter), top_z (current underside plane), extend (extra length at each end), eps (tolerance)
 * Returns: none
 */
module _face_plate_seam_support_bar(support_t, top_z, extend, eps) {
    off = _face_plate_seam_support_offset($ps_seam_current_normal_seam_local, top_z, support_t, eps);

    hull() {
        translate($ps_edge_pts_local[0] - [extend, 0, 0] + off)
            sphere(d = support_t, $fn = 20);
        translate($ps_edge_pts_local[1] + [extend, 0, 0] + off)
            sphere(d = support_t, $fn = 20);
    }
}

/**
 * Module: Emit printable support bars on classified face seam candidates.
 * Params: support_t (bar diameter), top_z (current face underside plane), extend (extra length at each seam end), mode/eps (seam analysis controls), boundary_kind/include_boundary/include_foreign/filter_parent/foreign_indices/support_only (seam candidate controls)
 * Returns: none
 * Limitations/Gotchas: example helper for `place_on_faces(...)`; real candidate semantics come from `place_on_face_seam_segments(...)`
 */
module face_seam_supports(
    support_t = FACE_PLATE_SEAM_SUPPORT_T,
    top_z = undef,
    extend = 0,
    mode = "nonzero",
    eps = 1e-4,
    boundary_kind = "generated_cut",
    include_boundary = true,
    include_foreign = true,
    filter_parent = true,
    foreign_indices = undef,
    support_only = true
) {
    assert(support_t > 0, "face_seam_supports: support_t must be > 0");
//    assert(extend >= 0, "face_seam_supports: extend must be >= 0");

    top_z_eff = is_undef(top_z) ? 0 : top_z;

    place_on_face_seam_segments(
        mode = mode,
        eps = eps,
        coords = "element",
        boundary_kind = boundary_kind,
        include_boundary = include_boundary,
        include_foreign = include_foreign,
        filter_parent = filter_parent,
        foreign_indices = foreign_indices,
        support_only = support_only
    ) {
        if ($ps_seam_len > eps)
            _face_plate_seam_support_bar(support_t, top_z_eff, extend, eps);
    }
}

/**
 * Module: Emit a face plate clipped by the current face's anti-interference volume.
 * Params: face_thk (structural plate thickness, excluding pillow), face_ctx (face-local context; defaults from `place_on_faces`), clear_space (emit clearance cutter), top_thk (full-footprint structural top skin), pillow_* (raised optional pillow sizing), base_z (bottom Z; defaults to `-face_thk` so the structural top sits on the source face plane), clear_height (clearance height), mode/max_project/boundary_inset/boundary_inset_mode/eps/convexity (anti-interference controls)
 * Returns: none
 * Limitations/Gotchas: pillow and clear-space cutter follow the generated shell top loops
 */
module face_plate(face_thk,
    face_ctx = $ps_face_local_context,
    clear_space=false,
    top_thk = FACE_PLATE_TOP_THK,
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
    assert(!is_undef(face_ctx), "face_plate: face_ctx requires place_on_faces context or an explicit override");
    assert(face_thk > 0, "face_plate: face_thk must be > 0");
    assert(top_thk >= 0, "face_plate: top_thk must be >= 0");
    assert(top_thk < face_thk, "face_plate: top_thk must be less than face_thk");
    assert(pillow_thk >= 0, "face_plate: pillow_thk must be >= 0");

    base_z_eff = is_undef(base_z) ? -face_thk : base_z;
    top_z = base_z_eff + face_thk;
    top_skin_base_z = top_z - top_thk;
    shells = ps_face_region_loop_shells(
        face_ctx,
        base_z_eff,
        top_skin_base_z,
        mode,
        max_project,
        eps,
        boundary_inset,
        boundary_inset_mode
    );

    color(len(ps_face_local_context_pts2d(face_ctx)) == 3 ? "white" : "red") {
        union() {
            for (shell = shells) {
                if (ps_loop_shell_capped_count(shell) > 0)
                    echo(str(
                        "face_plate: capped ",
                        ps_loop_shell_capped_count(shell),
                        " projection(s) on face ",
                        ps_face_local_context_idx(face_ctx),
                        " loop ",
                        ps_loop_shell_source_idx(shell)
                    ));

                color(ps_loop_shell_exposure_sign(shell) > 0? "green" : "blue")
                polyhedron(
                    points = ps_loop_shell_points(shell),
                    faces = ps_loop_shell_faces(shell),
                    convexity = convexity
                );
            }

            if (top_thk > eps) {
                for (shell = shells) {
                    // Keep several structural top layers at the supported
                    // ramp-top footprint before the optional inset pillow begins.
                    translate([0, 0, top_skin_base_z])
                        linear_extrude(height = top_thk)
                            ps_polygon(points = ps_loop_shell_top_loop2d(shell));
                }
            }
        }

        for (shell = shells)
            _face_plate_pillow_loop(
                ps_loop_shell_top_loop2d(shell),
                top_z, pillow_min_rad, pillow_inset, pillow_ramp, pillow_thk, eps);
    }

    if (clear_space)
        color("magenta")
            translate([0, 0, top_z - eps])
                linear_extrude(height = clear_height)
                    union() {
                        for (shell = shells)
                            ps_polygon(points = ps_loop_shell_top_loop2d(shell));
                    }
}


/////////////////////////////
// On-the-spot sanity tests

//// Direct smoke demo: subtract one placed star face cutter from a cube.
//use <../../core/prisms.scad>
//_demo_fstap = poly_antiprism(n=5, p=2, angle=15);
//translate([100,0,0]) difference() {
//    translate([0, -15, 15]) cube(30);
//
//    place_on_faces(_demo_fstap, 17.5, indices = [1])
//        #face_plate(face_thk=1.2, clear_space=false, max_project=10);
//}
//
//// Direct smoke demo: subtract one placed star face cutter from a cube.
//use <../../core/truncation.scad>
//use <../../models/tetrahedron.scad>
//_demo_atut = poly_truncate(tetrahedron(), t = -0.5);
//difference() {
//    translate([-18, -15, 7]) rotate([36, 44, 0]) cube(30);
//
//    place_on_faces(_demo_atut, 17.5, indices = [1])
//        face_plate(face_thk=1.2, clear_space=false, max_project=10);
//}
