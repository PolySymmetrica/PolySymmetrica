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
 * Params: support_t (bar diameter), top_z/base_z (current face underside plane), extend (extra length at each seam end), mode/eps (seam analysis controls), boundary_kind/include_boundary/include_foreign/filter_parent/foreign_indices/support_only (seam candidate controls)
 * Returns: none
 * Limitations/Gotchas: example helper for `place_on_faces(...)`; real candidate semantics come from `place_on_face_seam_segments(...)`
 */
module face_seam_supports(
    support_t = FACE_PLATE_SEAM_SUPPORT_T,
    top_z = undef,
    base_z = undef,
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
    assert(extend >= 0, "face_seam_supports: extend must be >= 0");

    top_z_eff = is_undef(top_z) ? (is_undef(base_z) ? 0 : base_z) : top_z;

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
 * Params: face_thk (plate thickness), face_ctx (face-local context; defaults from `place_on_faces`), clear_space (emit clearance cutter), pillow_* (raised pillow sizing), base_z (bottom Z; defaults to `-face_thk` so the top sits on the source face plane), clear_height (clearance height), mode/max_project/boundary_inset/boundary_inset_mode/eps/convexity (anti-interference controls)
 * Returns: none
 * Limitations/Gotchas: pillow and clear-space cutter follow the generated shell top loops
 */
module face_plate(face_thk,
    face_ctx = $ps_face_local_context,
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
    assert(!is_undef(face_ctx), "face_plate: face_ctx requires place_on_faces context or an explicit override");

    base_z_eff = is_undef(base_z) ? -face_thk : base_z;
    top_z = base_z_eff + face_thk;
    shells = ps_face_anti_interference_shells(
        face_ctx,
        base_z_eff,
        top_z,
        mode,
        max_project,
        eps,
        boundary_inset,
        boundary_inset_mode
    );

    color(len(ps_face_local_context_pts2d(face_ctx)) == 3 ? "white" : "red") {
        union() {
            for (shell = shells) {
                if (ps_face_anti_interference_shell_capped_count(shell) > 0)
                    echo(str(
                        "face_plate: capped ",
                        ps_face_anti_interference_shell_capped_count(shell),
                        " projection(s) on face ",
                        ps_face_local_context_idx(face_ctx),
                        " loop ",
                        ps_face_anti_interference_shell_loop_idx(shell)
                    ));

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

/**
 * Module: Emit conservative foreign proxy volume-group hull cutters from explicit face context.
 * Params: face_ctx (face-local context), target_ctx (target-local poly context; defaults from `face_ctx`), mode/eps/filter_parent (intrusion grouping controls), point_r/point_fn (hull point primitive)
 * Returns: none
 * Limitations/Gotchas: internal helper; convexifies each grouped source vertex set
 */
module _face_plate_foreign_proxy_volume_group_hulls(
    face_ctx,
    target_ctx = ps_face_local_context_target_local_poly_context(face_ctx),
    mode,
    eps,
    filter_parent,
    point_r,
    point_fn
) {
    groups = ps_face_foreign_proxy_volume_groups(
        ps_face_local_context_pts2d(face_ctx),
        ps_face_local_context_idx(face_ctx),
        target_ctx,
        eps,
        mode,
        filter_parent
    );

    for (group = groups) {
        vertex_idxs = ps_proxy_volume_group_vertex_idxs(group);
        if (len(vertex_idxs) > 0) {
            hull() {
                for (vi = vertex_idxs)
                        translate(ps_target_local_poly_context_verts_local(target_ctx)[vi])
                        sphere(r = point_r, $fn = point_fn);
            }
        }
    }
}

/**
 * Module: Emit a face plate after subtracting conservative foreign proxy volume-group hulls.
 * Params: face_thk (plate thickness), face_ctx (face-local context; defaults from `place_on_faces`), clear_space/pillow params/base_z/clear_height/mode/max_project/boundary_inset/boundary_inset_mode/eps/convexity (forwarded to `face_plate`), filter_parent (foreign intrusion filtering), hull_point_r/hull_point_fn (hull point primitive)
 * Returns: none
 * Limitations/Gotchas: subtracts convex hulls of proxy volume groups computed from the same explicit face context as the plate; this is conservative and can over-subtract concave or detailed user geometry
 */
module face_plate_minus_foreign_proxy_volume_group_hulls(face_thk,
    face_ctx = $ps_face_local_context,
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
    convexity = 6,
    filter_parent = true,
    hull_point_r = 0.04,
    hull_point_fn = 8
) {
    target_ctx_eff = ps_face_local_context_target_local_poly_context(face_ctx);

    difference() {
        face_plate(
            face_thk = face_thk,
            face_ctx = face_ctx,
            clear_space = clear_space,
            pillow_min_rad = pillow_min_rad,
            pillow_inset = pillow_inset,
            pillow_ramp = pillow_ramp,
            pillow_thk = pillow_thk,
            base_z = base_z,
            clear_height = clear_height,
            mode = mode,
            max_project = max_project,
            boundary_inset = boundary_inset,
            boundary_inset_mode = boundary_inset_mode,
            eps = eps,
            convexity = convexity
        );

        _face_plate_foreign_proxy_volume_group_hulls(
            face_ctx = face_ctx,
            target_ctx = target_ctx_eff,
            mode = mode,
            eps = eps,
            filter_parent = filter_parent,
            point_r = hull_point_r,
            point_fn = hull_point_fn
        );
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
