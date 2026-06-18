[![Run Tests under OpenSCAD](https://github.com/susanw1/PolySymmetrica/actions/workflows/run_tests.yml/badge.svg)](https://github.com/susanw1/PolySymmetrica/actions/workflows/run_tests.yml)

# PolySymmetrica

PolySymmetrica is a polyhedral modelling library for OpenSCAD.

It gives you named solids, geometric transforms, placement tools, and topology
helpers for building structured polyhedral models without hand-writing the
rotations and coordinate frames yourself.

Use it to make:

- decorated Platonic, Archimedean, Catalan, Johnson, prism, and antiprism forms;
- custom geometry attached cleanly to every face, edge, or vertex of a solid;
- transformed solids using duals, truncation, rectification, chamfering,
  cantellation, cantitruncation, snubs, and construction helpers;
- exploratory or printable polyhedral frame and face assemblies.

PolySymmetrica is still OpenSCAD: the output is ordinary OpenSCAD geometry, and
your child modules can be regular OpenSCAD modules. The library supplies the
polyhedral structure, local frames, and metadata.

## The Core Idea

OpenSCAD is good at describing a piece of geometry. It is less pleasant when
you need to repeat that geometry across every symmetry site of a polyhedron.

PolySymmetrica turns a polyhedron into a reusable placement surface:

- `place_on_faces(...)` runs child geometry once per face;
- `place_on_edges(...)` runs child geometry once per edge;
- `place_on_vertices(...)` runs child geometry once per vertex.

Inside those child modules, `$ps_*` values describe the current site: local
axes, lengths, radii, source indices, family ids, neighbouring faces, and other
context. That lets a child module size and orient itself from the polyhedron
instead of from hand-coded rotations.

## First Taste

Create an OpenSCAD file in the repository root:

```scad
use <src/polysymmetrica/core/placement.scad>
use <src/polysymmetrica/core/render.scad>
use <src/polysymmetrica/core/truncation.scad>
use <src/polysymmetrica/models/platonics_all.scad>

p = poly_truncate(dodecahedron());

color("lightsteelblue")
    place_on_faces(p, inter_radius = 35)
        linear_extrude(1) offset(-1.5) polygon($ps_face_pts2d);

color("gold")
    place_on_vertices(p, inter_radius = 35)
        sphere(1.6, $fn = 16);

color("silver")
    place_on_edges(p, inter_radius = 35)
        cube([$ps_edge_len, 1, 1], center = true);

```

This builds a truncated dodecahedron: it renders a polygon on each face, places a small
sphere on every vertex using the vertex-local placement context, and puts a silver bar on
each edge.

## What You Can Build With

**Named models**

Platonic solids, Archimedean and Catalan families, selected Johnson solids,
prisms, antiprisms, and polygram variants.

**Transforms**

Duals, truncation, rectification, chamfering, cantellation, cantitruncation,
snub construction, and construction operations such as delete/cap/slice/attach.

**Placement**

Face, edge, and vertex placement with stable local frames and site metadata.
This is the main route for decorative surfaces, frames, labels, sockets, and
custom repeated geometry.

**Classification and profiles**

Faces, edges, and vertices can be grouped into families. Those families can
drive placement, structured parameter profiles, and transform behavior.

**Advanced face analysis**

Self-crossing and non-convex faces can be split, inspected, and used in more
specialized face-region and proxy-interaction workflows.

## Examples To Open

Start here:

- `src/polysymmetrica/examples/basics/main_basics.scad`
- `src/polysymmetrica/examples/basics/main_prisms.scad`
- `src/polysymmetrica/examples/basics/main_attach.scad`
- `src/polysymmetrica/examples/truncation/main_transforms_all.scad`
- `src/polysymmetrica/examples/classify/main_classify.scad`

More advanced demos live under:

- `src/polysymmetrica/examples/segments/`
- `src/polysymmetrica/examples/printing/`
- `src/polysymmetrica/examples/poly-frame/`

## Documentation

Current guides and notes:

- [Developer guide](docs/developer_guide.md)
- [Construction helpers](docs/construction.md)
- [Face attachment](docs/attach.md)
- [Prisms and antiprisms](docs/prisms.md)
- [Profile rows](docs/profile.md)
- [Cantellation](docs/cantellation.md)
- [Cantitruncation](docs/cantitruncation.md)
- [Snubs](docs/snubs.md)

Advanced design notes:

- [Placement data model](docs/placement_data_model.md)
- [Face segments](docs/segments.md)
- [Face regions](docs/face_regions.md)
- [Face arrangement](docs/face_arrangement.md)
- [Proxy interaction](docs/proxy_interaction.md)

## License

PolySymmetrica is released under the MIT license.
