/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

use <../../../polysymmetrica/core/funcs.scad>
use <../../../polysymmetrica/core/face_regions.scad>
use <../../../polysymmetrica/core/loop_shells.scad>
use <../../../polysymmetrica/core/placement.scad>
use <../../../polysymmetrica/core/segments.scad>

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

// Module: _face_plate_pillow_loop()
// Usage:
//   _face_plate_pillow_loop(pts, top_z, pillow_min_rad, pillow_inset, pillow_ramp, pillow_thk, eps);
// Description:
//   Emit one raised pillow loop.
//   .
//   - Returns: none
// Arguments:
//   pts = 2D loop
//   top_z = face top plane
//   pillow_min_rad = pillow sizing
//   inset = pillow sizing
//   ramp = pillow sizing
//   thk = pillow sizing
//   eps = tolerance
module _face_plate_pillow_loop(pts, top_z, pillow_min_rad, pillow_inset, pillow_ramp, pillow_thk, eps) {
    loop_centroid = [
        ps_sum([for (p = pts) p[0]]) / len(pts),
        ps_sum([for (p = pts) p[1]]) / len(pts)
    ];
    loop_rad = ps_sum([for (p = pts) norm([p[0] - loop_centroid[0], p[1] - loop_centroid[1]])]) / len(pts);
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

// Module: _face_plate_loop_ring()
// Usage:
//   _face_plate_loop_ring(pts, width, eps);
// Description:
//   Emit an inset ring from a 2D loop.
//   .
//   - Returns: none
// Arguments:
//   pts = 2D loop
//   width = ring width
//   eps = tolerance
module _face_plate_loop_ring(pts, width, eps) {
    assert(width > 0, "_face_plate_loop_ring: width must be > 0");

    difference() {
        ps_polygon(points = pts);
        offset(-width)
            ps_polygon(points = pts);
    }
}

function _face_plate_shell_lower_clipped(shell, requested_z, eps) =
    abs(ps_loop_shell_z0(shell) - requested_z) > eps;

function _face_plate_shell_upper_clipped(shell, requested_z, eps) =
    abs(ps_loop_shell_z1(shell) - requested_z) > eps;

// Function: _face_plate_seam_support_offset()
// Usage:
//   result = _face_plate_seam_support_offset(current_n_seam_local, top_z, support_t, eps);
// Description:
//   Compute a seam-frame support centerline offset tangent to the current face underside.
//   .
//   - Returns: 3D offset in seam element coords
// Arguments:
//   current_n_seam_local = current face normal in seam element coords
//   top_z = current underside plane
//   support_t = bar diameter
//   eps = degeneracy tolerance
function _face_plate_seam_support_offset(current_n_seam_local, top_z, support_t, eps=1e-8) =
    let(
        q = top_z - support_t / 2,
        n = is_undef(current_n_seam_local) || norm(current_n_seam_local) <= eps
            ? [0, 0, 1]
            : v_norm(current_n_seam_local)
    )
    abs(n[2]) > eps ? [0, 0, q / n[2]] : n * q;

// Module: _face_plate_seam_support_bar()
// Usage:
//   _face_plate_seam_support_bar(support_t, top_z, extend, eps);
// Description:
//   Emit one rounded support bar in the current seam element frame.
//   .
//   - Returns: none
// Arguments:
//   support_t = bar diameter
//   top_z = current underside plane
//   extend = extra length at each end
//   eps = tolerance
module _face_plate_seam_support_bar(support_t, top_z, extend, eps) {
    off = _face_plate_seam_support_offset($ps_seam_current_normal_seam_local, top_z, support_t, eps);

    hull() {
        translate($ps_edge_pts_local[0] - [extend, 0, 0] + off)
            sphere(d = support_t, $fn = 20);
        translate($ps_edge_pts_local[1] + [extend, 0, 0] + off)
            sphere(d = support_t, $fn = 20);
    }
}

// Module: face_seam_supports()
// Usage:
//   face_seam_supports(support_t, top_z, extend, mode, eps, boundary_kind, include_boundary, include_foreign, filter_parent, foreign_indices, support_only);
// Description:
//   Emit printable support bars on classified face seam candidates.
//   .
//   - Returns: none
//   .
//   - Limitations/Gotchas: example helper for `place_on_faces(...)`; real candidate semantics come from `place_on_face_seam_segments(...)`
// Arguments:
//   support_t = bar diameter
//   top_z = current face underside plane
//   extend = extra length at each seam end
//   mode = seam analysis controls
//   eps = seam analysis controls
//   boundary_kind = seam candidate controls
//   include_boundary = seam candidate controls
//   include_foreign = seam candidate controls
//   filter_parent = seam candidate controls
//   foreign_indices = seam candidate controls
//   support_only = seam candidate controls
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

// Module: face_plate()
// Usage:
//   face_plate(face_thk, face_ctx, clear_space, top_thk, pillow_min_rad, pillow_inset, pillow_ramp, pillow_thk, base_z, clear_height, mode, max_project, boundary_inset, boundary_inset_mode, eps, convexity);
// Description:
//   Emit a face plate clipped by the current face's anti-interference volume.
//   .
//   - Returns: none
//   .
//   - Limitations/Gotchas: pillow is emitted only on top-exposed shell regions; clear-space cutter follows each region's exposed side
// Arguments:
//   face_thk = structural plate thickness, excluding pillow
//   face_ctx = face-local context; defaults from `place_on_faces`
//   clear_space = emit clearance cutter
//   top_thk = full-footprint structural top skin
//   pillow_* = raised optional pillow sizing
//   base_z = bottom Z; defaults to `-face_thk` so the structural top sits on the source face plane
//   clear_height = clearance height
//   mode = anti-interference controls
//   max_project = anti-interference controls
//   boundary_inset = anti-interference controls
//   boundary_inset_mode = anti-interference controls
//   eps = anti-interference controls
//   convexity = anti-interference controls
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
                    if (!_face_plate_shell_upper_clipped(shell, top_skin_base_z, eps))
                        translate([0, 0, ps_loop_shell_z1(shell)])
                            linear_extrude(height = top_thk)
                                ps_polygon(points = ps_loop_shell_top_loop2d(shell));
                }
            }
        }

        for (shell = shells)
            if (ps_loop_shell_exposure_sign(shell) > 0
                    && !_face_plate_shell_upper_clipped(shell, top_skin_base_z, eps))
                _face_plate_pillow_loop(
                    ps_loop_shell_top_loop2d(shell),
                    ps_loop_shell_z1(shell) + top_thk, pillow_min_rad, pillow_inset, pillow_ramp, pillow_thk, eps);
    }

    if (clear_space)
        color("magenta")
            union() {
                for (shell = shells) {
                    if (ps_loop_shell_exposure_sign(shell) > 0) {
                        if (!_face_plate_shell_upper_clipped(shell, top_skin_base_z, eps))
                            translate([0, 0, ps_loop_shell_z1(shell) + top_thk - eps])
                                linear_extrude(height = clear_height)
                                    ps_polygon(points = ps_loop_shell_top_loop2d(shell));
                    } else {
                        if (!_face_plate_shell_lower_clipped(shell, base_z_eff, eps))
                            translate([0, 0, ps_loop_shell_z0(shell) - clear_height + eps])
                                linear_extrude(height = clear_height)
                                    ps_polygon(points = ps_loop_shell_bottom_loop2d(shell));
                    }
                }
            }
}

// Module: face_mounting_plate()
// Usage:
//   face_mounting_plate(face_thk, mount_thk, mount_width, face_ctx, base_z, top_thk, mode, max_project, boundary_inset, boundary_inset_mode, eps);
// Description:
//   Emit frame mounting shelves behind each face-region shell.
//   .
//   - Returns: none
//   .
//   - Limitations/Gotchas: shelves are emitted on the side opposite each region's exposed side
// Arguments:
//   face_thk = matching structural face thickness
//   mount_thk = shelf thickness
//   mount_width = inset ring width
//   face_ctx = matching `face_plate` controls
//   base_z = matching `face_plate` controls
//   top_thk = matching `face_plate` controls
//   mode = matching `face_plate` controls
//   max_project = matching `face_plate` controls
//   boundary_inset = matching `face_plate` controls
//   boundary_inset_mode = matching `face_plate` controls
//   eps = matching `face_plate` controls
module face_mounting_plate(
    face_thk,
    mount_thk,
    mount_width,
    face_ctx = $ps_face_local_context,
    base_z = undef,
    top_thk = FACE_PLATE_TOP_THK,
    mode = "nonzero",
    max_project = undef,
    boundary_inset = 0,
    boundary_inset_mode = "side",
    eps = 1e-4
) {
    assert(!is_undef(face_ctx), "face_mounting_plate: face_ctx requires place_on_faces context or an explicit override");
    assert(face_thk > 0, "face_mounting_plate: face_thk must be > 0");
    assert(mount_thk > 0, "face_mounting_plate: mount_thk must be > 0");
    assert(mount_width > 0, "face_mounting_plate: mount_width must be > 0");
    assert(top_thk >= 0, "face_mounting_plate: top_thk must be >= 0");
    assert(top_thk < face_thk, "face_mounting_plate: top_thk must be less than face_thk");

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

    for (shell = shells) {
        if (ps_loop_shell_exposure_sign(shell) > 0) {
            if (!_face_plate_shell_lower_clipped(shell, base_z_eff, eps))
                translate([0, 0, ps_loop_shell_z0(shell) - mount_thk])
                    linear_extrude(height = mount_thk)
                        _face_plate_loop_ring(ps_loop_shell_bottom_loop2d(shell), mount_width, eps);
        } else {
            if (!_face_plate_shell_upper_clipped(shell, top_skin_base_z, eps))
                translate([0, 0, ps_loop_shell_z1(shell) + top_thk])
                    linear_extrude(height = mount_thk)
                        _face_plate_loop_ring(ps_loop_shell_top_loop2d(shell), mount_width, eps);
        }
    }
}


/////////////////////////////
// On-the-spot sanity tests

// Direct smoke demo: subtract one placed star face cutter from a cube.
use <../../../polysymmetrica/core/prisms.scad>
_demo_fstap = poly_antiprism(n=5, p=2, angle=15);
translate([100,0,0]) difference() {
    translate([0, -15, 15]) cube(30);

    place_on_faces(_demo_fstap, 17.5, indices = [1])
        #face_plate(face_thk=1.2, clear_space=false, max_project=10);
}

// Direct smoke demo: subtract one placed star face cutter from a cube.
use <../../../polysymmetrica/core/truncation.scad>
use <../../../polysymmetrica/models/tetrahedron.scad>
_demo_atut = poly_truncate(tetrahedron(), t = -0.5);
difference() {
    translate([-18, -15, 7]) rotate([36, 44, 0]) cube(30);

    place_on_faces(_demo_atut, 17.5, indices = [1])
        face_plate(face_thk=1.2, clear_space=false, max_project=10);
}
