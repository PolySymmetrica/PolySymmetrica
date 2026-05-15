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
p = poly_antiprism(n=5, p=2, angle = 15);
//p = poly_antiprism(n=7, p=3, angle = 0);
//p = poly_antiprism(n=7, p=3, angle = 15);
//p = poly_antiprism(n=7, p=3, angle = 180);
//p = poly_truncate(tetrahedron(), t=-0.5);

//p = j1_square_pyramid();
//p = poly_dual(j2_pentagonal_pyramid());

EDGE_T = 3.5 * SC; // 3.5
FACE_T = 1.6 * SC; // 1.6 * SC;
INSET = 1.1 * SC;
FACET_BASE_T = 1;
FACET_BASE_W = 2.2;
BASE_Z = -FACE_T / 4;
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
                translate([0,0, BASE_Z - FACET_BASE_T]) linear_extrude(FACET_BASE_T)
                    difference() {
                        ps_polygon(points = $ps_face_pts2d);
                        offset(-FACET_BASE_W) ps_polygon(points = $ps_face_pts2d);
                    }
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

module demo_face(clear_height = 0) {
    face_plate(base_z = BASE_Z, face_thk = FACE_T, clear_space = (clear_height > 0), clear_height = clear_height,
            max_project = 10, boundary_inset = INSET);
}

module demo_edge() {
    edge_seg($ps_edge_pts_local, $ps_poly_center_local, edge_t = EDGE_T, fin_t = 0);
}

module demo_vert() {
    // cylinder(r=3, $fn = $ps_vertex_valence);
}

module model_2_f(faces_to_print = undef, clear_height = 0, remove_proxies = false) {
    place_on_faces(p, IR, indices = faces_to_print) {
        difference() {
            // The actual face
            demo_face(clear_height);

            // Minus the face-intersecting proxies
            place_on_face_foreign_proxy_sites() {
                demo_face();
                demo_edge();
                demo_vert();
            }
            // Minus the volume hulls of the face-intersecting planes (to remove face material from those cells)
            if (remove_proxies) {
                place_on_face_foreign_proxy_volume_group_hulls(filter_parent = true);
            }
        }
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
                    color("darkorange") face_seam_supports(support_t = SEAM_SUPPORT_T, extend = 0, top_z = 0);
                    
                    // mounting plate - the edge frame isn't quite substantial enough (disabled - wrong polygon!)
                    color("skyblue") translate([0,0, BASE_Z - FACET_BASE_T]) linear_extrude(FACET_BASE_T)
                            difference() {
                                ps_polygon(points = $ps_face_pts2d);
                                offset(-FACET_BASE_W) ps_polygon(points = $ps_face_pts2d);
                            }
                }
            }
            // faces to be subtracted from frame, with clearance space
            model_2_f(clear_height = EDGE_T/2);
        }
    } else {
        // Face mode selected
        model_2_f(faces_to_print, remove_proxies = true);
    }
}


//F = [1];
if (is_undef(F)) {
    model_2();
} else {
    model_2(F);
}
