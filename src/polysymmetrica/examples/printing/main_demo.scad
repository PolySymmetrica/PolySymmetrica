use <../../core/funcs.scad>
use <../../core/placement.scad>
use <../../core/duals.scad>
use <../../core/truncation.scad>
use <../../core/render.scad>
use <../../core/classify.scad>
use <../../core/prisms.scad>
use <../../core/construction.scad>
use <../../core/face_regions.scad>

use <../../models/platonics_all.scad>
use <../../models/archimedians_all.scad>
use <../../models/johnsons_all.scad>

use <edge_seg.scad>
use <face_plate.scad>

SC = 1;
IR = 20 * SC;

//p = (tetrahedron());
//p = poly_truncate(dodecahedron());
//p = (dodecahedron());
//base = icosahedron();
//sol = solve_cantitruncate_trig(base);
//s = poly_cantellate_norm(base, 0.5);
//p = poly_dual(great_rhombicuboctahedron());
//p = poly_truncate(poly_dual(poly_truncate(hexahedron())), t=0, params_overrides=[["vert", "id", [0,1,2,3,4,55], ["t",0.5001]]]);
//p = poly_attach(octahedron(), icosahedron(), f1=[0,7]);
//p = poly_attach(octahedron(), icosahedron(), f1=[0,1,2,3,4,5,6,7]);
//p = poly_attach(p1, icosahedron(), f1=0);

//AP_CANT_ROWS = [
//    ["face", "family", 0, ["df", 0.30]],
//    ["face", "family", 1, ["df", 0.30]]
//];

//p = poly_cantellate(poly_antiprism(6), params_overrides=AP_CANT_ROWS);
//p = poly_prism(5);
//p = poly_antiprism(5);
//p = poly_prism(n=5, p=2);
//p = poly_antiprism(n=5, p=2, angle = 0);
//p = poly_antiprism(n=5, p=2, angle = 15);
p = poly_antiprism(n=5, p=3, angle = 0);
//p = poly_antiprism(n=7, p=3, angle = 0);
//p = poly_antiprism(n=7, p=3, angle = 15);
//p = poly_antiprism(n=7, p=4, angle = 0); // (12 min)
//p = poly_truncate(tetrahedron(), t=-0.5);

//p = j1_square_pyramid();
//p = poly_dual(j2_pentagonal_pyramid());

EDGE_T = 3.5 * SC; // 3.5
FACE_T = 1.6 * SC; // 1.6 * SC;
INSET = 1.1 * SC;
FACET_BASE_T = 1;
FACET_BASE_W = 2.2;
BASE_Z = -FACE_T / 2;
SEAM_SUPPORT_T = EDGE_T;

//// Or, experimental:
//IR = 12 * SC;
//EDGE_T = 3.0 * SC; // 3.5
//FACE_T = 1.2 * SC; // 1.6 * SC;




/**
* Generate skeletal frame:
    show_faces = undef;

* Generate single face, eg face#8:
    show_faces = [8];
    and place '!'

* Generate multiple faces, eg face#0,#9, and #23:
    show_faces = [0, 9, 23];
    and place '!'
*/
module model_1(show_faces = undef, clear_airspace = true) {
    difference() {
        union() {
            // Constructs the edge-based frame
            color("gray")
            place_on_edges(p, IR) {
                edge_seg($ps_edge_pts_local, $ps_poly_center_local, edge_t = EDGE_T);
            }

            // mounting plate - the edge frame isn't quite substantial enough
            color("blue")
            place_on_faces(p, IR) {
                face_mounting_plate(
                        face_thk = FACE_T, base_z = BASE_Z,
                        mount_thk = FACET_BASE_T, mount_width = FACET_BASE_W,
                        max_project = 10);
            }

            // Supports for classified printable seam candidates.
            color("darkorange")
            place_on_faces(p, IR) {
                face_seam_supports(support_t = SEAM_SUPPORT_T, top_z = BASE_Z, extend = SEAM_SUPPORT_T * 0.25);
            }
        }
        // Constructs faces, removes them from frame to create face-fitting sockets.
        place_on_faces(p, IR) {
            // add '!' here to force faces-only:
            if (is_undef(show_faces) || len(search($ps_face_idx, [for (i=show_faces) i])) > 0) {
                face_plate(face_thk = FACE_T, base_z = BASE_Z, max_project = 10,
                        clear_space = clear_airspace, clear_height = 0.6);
            }
        }
    }
}

//model_1();
//poly_render(p, 20);

SEAM_Z = 1;
SEAM_INSET = 0.0;

module demo_face_plate(clear_height = 0) {
    difference() {
        // raw face plate geometry
        face_plate(base_z = BASE_Z, face_thk = FACE_T, clear_space = (clear_height > 0), clear_height = clear_height,
                max_project = 10, boundary_inset = INSET);

        // minus local seam clearance regions for hidden foreign crossing loops
        ps_face_seam_clearance_volume(
                BASE_Z - 0.5, BASE_Z + FACE_T + 0.5,
                clearance = SEAM_INSET, max_slope_offset = undef, mode = "nonzero", eps = 1e-4);
    }
}


module demo_edge() {
    edge_seg($ps_edge_pts_local, $ps_poly_center_local, edge_t = EDGE_T, fin_t = 0);
}

module demo_vert() {
    // cylinder(r=3, $fn = $ps_vertex_valence);
}

// In a place_on_faces() context, this places the seam support shape onto the face.
module demo_full_seam_supports() {
    face_seam_supports(support_t = SEAM_SUPPORT_T, top_z = SEAM_Z, extend = -2.2,
            include_boundary = false, include_foreign = true);
}

// In a place_on_face_foreign_proxy_sites() face-child context, this places the
// replayed face's seam supports except the support shared with the face being cut.
module demo_proxy_seam_supports() {
    proxy_support_faces = [
        for (i = [0:1:len($ps_poly_faces_idx)-1])
            if (i != $ps_proxy_target_face_idx)
                i
    ];

    face_seam_supports(support_t = SEAM_SUPPORT_T, top_z = SEAM_Z, extend = -2.2,
            include_boundary = false, include_foreign = true, foreign_indices = proxy_support_faces);
}

module demo_face_print_or_socket_cutter(clear_height = 0, remove_proxy_hulls = true) {
    difference() {
        demo_face_plate(clear_height);

        place_on_face_foreign_proxy_sites() {
            union() {
                // foreign face proxy plate
                demo_face_plate();
                
                // foreign proxy seam supports
                demo_proxy_seam_supports();
            }
            demo_edge();
            demo_vert();
        }

        // Minus the volume hulls of the face-intersecting planes (to remove face material from those cells)
        if (remove_proxy_hulls) {
            place_on_face_foreign_proxy_volume_group_hulls(filter_parent = true);
        }
    }
}


module model_2_f(faces_to_print = undef, clear_height = 0, remove_proxy_hulls = true) {
    place_on_faces(p, IR, indices = faces_to_print) {
        demo_face_print_or_socket_cutter(clear_height, remove_proxy_hulls);
    }
}

module model_2(faces_to_print = undef) {
    if (is_undef(F)) {
        // Frame mode selected
        difference() {
            // edge framework
            union() {
                // normal full polyhedral edges
                color("gray") place_on_edges(p, IR) {
                    demo_edge();
                }
                // seam supports
                place_on_faces(p, IR) {
                    color("darkorange")
                        demo_full_seam_supports();
                    
                    // mounting plate - the edge frame isn't quite substantial enough
                    color("skyblue")
                        face_mounting_plate(face_thk = FACE_T, base_z = BASE_Z,
                                mount_thk = FACET_BASE_T, mount_width = FACET_BASE_W, max_project = 10);
                }
            }
            // faces to be subtracted from frame, with clearance space
            model_2_f(clear_height = EDGE_T/2);
        }
    } else {
        // Face mode selected
        model_2_f(faces_to_print);
    }
}


//F = [2];
if (is_undef(F)) {
    model_2();
//    model_2_f(undef); // Shows body with faces too
} else {
    model_2(F);
}
