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
p = poly_antiprism(n=7, p=3, angle = 15);

//p = j1_square_pyramid();
//p = poly_dual(j2_pentagonal_pyramid());

EDGE_T = 3.5 * SC; // 3.5
FACE_T = 1.6 * SC; // 1.6 * SC;
INSET = 1.1 * SC;
FACET_BASE_T = 1;
FACET_BASE_W = 2.2;
BASE_Z = -FACE_T / 2;
// Diagnostic only: current shell-volume polyhedra are useful to inspect, but can
// create expensive/non-manifold preview solids when subtracted by default.
SHOW_PROXY_VOLUME_GROUPS = false;

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
module model(show_faces = undef, clear_airspace = true) {
    let (inter_radius = IR)
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

//model();
//poly_render(p, 20);

module demo_face() {
    face_plate(base_z = BASE_Z, face_thk = FACE_T, clear_space = false, clear_height = 0.1, max_project = 10);
}
module demo_edge(endPoints, edge_t) {
    hull() {
        translate(endPoints[0]) sphere(d = edge_t, $fn = 40);
        translate(endPoints[1]) sphere(d = edge_t, $fn = 40);
    }
}

module demo_vert() {
    cylinder(r=3, $fn = $ps_vertex_valence);
}

/**
 * Function: Close each boundary loop with a centroid triangle fan.
 * Params: poly (open local patch poly descriptor)
 * Returns: local poly descriptor with planar triangular cap faces added
 * Limitations/Gotchas: example helper; cap shape is best-effort, not the true source solid interior
 */
function demo_cap_boundary_loops_with_fans(poly) =
    let(
        verts = poly_verts(poly),
        faces = poly_faces(poly),
        loops = poly_boundary_loops(poly),
        centers = [for (loop = loops) ps_face_centroid(verts, loop)],
        cap_faces = [
            for (li = [0:1:len(loops)-1])
                let(
                    loop = loops[li],
                    center_idx = len(verts) + li
                )
                for (i = [0:1:len(loop)-1])
                    [center_idx, loop[(i + 1) % len(loop)], loop[i]]
        ]
    )
    [concat(verts, centers), concat(faces, cap_faces), poly_e_over_ir(poly)];

/**
 * Function: Build the current proxy volume group as a closed local patch volume.
 * Params: uses `$ps_proxy_volume_group_shell_faces_idx` and `$ps_poly_verts_local`
 * Returns: local poly descriptor suitable for `polyhedron(...)`
 * Limitations/Gotchas: caps open source-face patches with artificial fan faces for subtraction
 */
function demo_volume_group_patch_poly() =
    let(
        patch_faces = $ps_proxy_volume_group_shell_faces_idx,
        patch = [$ps_poly_verts_local, patch_faces, 1]
    )
    demo_cap_boundary_loops_with_fans(patch);

module demo_volume_group() {
    solid = demo_volume_group_patch_poly();
    polyhedron(points = poly_verts(solid), faces = poly_faces(solid), convexity = 10);
}

place_on_faces(p, IR, indices = [1,2,9]) {
    difference() {
        demo_face();

        place_on_face_foreign_proxy_sites() {
            demo_face();
            edge_seg($ps_edge_pts_local, $ps_poly_center_local, edge_t = EDGE_T);
            demo_vert();
        }

        if (SHOW_PROXY_VOLUME_GROUPS) {
            place_on_face_foreign_proxy_volume_groups() {
                demo_volume_group();
            }
        }
    }
}
