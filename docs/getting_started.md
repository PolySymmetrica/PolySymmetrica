# Getting Started

This guide gets from a checkout of PolySymmetrica to a rendered OpenSCAD model.

## Prerequisites

You need a current OpenSCAD development snapshot. PolySymmetrica does not target
the 2021 release.

Install a snapshot build from the
[OpenSCAD downloads page](https://openscad.org/downloads.html#snapshots). On
Linux, the Snap package is:

```bash
sudo snap install openscad-nightly
```

PolySymmetrica is an OpenSCAD source library. There is no package manager or
library descriptor yet, so setup means making the directory that contains
`polysymmetrica/` visible to OpenSCAD.

The public import form is:

```scad
use <polysymmetrica/core/placement.scad>
use <polysymmetrica/models/platonics_all.scad>
```

In this repository, that library root is `src/`:

```text
PolySymmetrica/
    src/
        polysymmetrica/
            core/
            models/
            examples/
```

The `src/` directory is a repository layout detail, not part of the public
import path.

## Recommended Setup

For a project you want to keep reproducible, copy PolySymmetrica into the
project so your `.scad` file can see a local `polysymmetrica/` directory.

```text
my-model/
    main.scad
    polysymmetrica/
        core/
        models/
        examples/
```

That can be a copied directory, a release bundle, or a symlink/submodule that
points at `PolySymmetrica/src/polysymmetrica`.

Then `main.scad` can use stable imports:

```scad
use <polysymmetrica/core/placement.scad>
use <polysymmetrica/core/truncation.scad>
use <polysymmetrica/models/platonics_all.scad>
```

This keeps the dependency visible in the project instead of hiding it in a
machine-global environment variable.

## Rendering From A Checkout

When working directly from this repository, use a scoped `OPENSCADPATH` for the
render command:

```bash
OPENSCADPATH="$PWD/src" openscad-nightly -o /tmp/ps-first.stl first.scad
```

This tells OpenSCAD that `src/` is a library root for that one command. The
`.scad` file can still use the stable `polysymmetrica/...` imports.

You can also set OpenSCAD's library path in the GUI, but for shared examples and
scripts prefer a project-local setup or a command-scoped `OPENSCADPATH`.

## First Model

The full runnable source for this example is
[`docs/examples/first_taste.scad`](examples/first_taste.scad).

![Truncated dodecahedron with face, edge, and vertex placements](images/generated/first_taste.png)

Create `first.scad` in the repository root:

```scad
use <polysymmetrica/core/placement.scad>
use <polysymmetrica/core/truncation.scad>
use <polysymmetrica/models/platonics_all.scad>

p = poly_truncate(dodecahedron());
ir = 35;

color("plum")
    place_on_faces(p, inter_radius = ir)
        linear_extrude(height = 1)
            polygon(points = $ps_face_pts2d);

color("silver")
    place_on_edges(p, inter_radius = ir)
        cube([$ps_edge_len, 1.5, 1], center = true);

color("gold")
    place_on_vertices(p, inter_radius = ir)
        sphere(r = 1.6, $fn = 16);
```

Render it:

```bash
OPENSCADPATH="$PWD/src" openscad-nightly -o /tmp/ps-first.stl first.scad
```

This does three things:

- builds a truncated dodecahedron;
- fills each face using that face's local 2D polygon;
- places a bar on every edge and a sphere on every vertex.

## The Minimum Concepts

**Poly descriptor**

A polyhedron is a compact descriptor:

```scad
[verts, faces, e_over_ir]
```

Most users do not need to build this list by hand. Start with model constructors
such as `dodecahedron()`, `icosahedron()`, `poly_prism(...)`, or transform
functions such as `poly_truncate(...)`.

**Inter-radius**

Placement modules need a size. `inter_radius` is the radius to the midpoint of
an edge. It is stable across many transforms and duals, so it is the normal size
parameter for placement examples.

**Placement context**

Inside `place_on_faces`, `place_on_edges`, or `place_on_vertices`, PolySymmetrica
sets `$ps_*` variables for the current site.

Common examples:

- `$ps_face_pts2d`: current face loop in face-local 2D coordinates;
- `$ps_face_radius`: useful face-local radius;
- `$ps_edge_len`: current edge length;
- `$ps_vertex_idx`, `$ps_edge_idx`, `$ps_face_idx`: source indices.

## Where To Go Next

- Work through the [tutorials](tutorials/index.md) for small runnable lessons.
- Open `src/polysymmetrica/examples/basics/main_basics.scad` for the broadest
  first demo.
- Read [prisms and antiprisms](guides/prisms.md) for prism/polygram constructors.
- Read [construction helpers](guides/construction.md) for delete/cap/slice/attach.
- Read [profile rows](guides/profile.md) once you want family-specific transform
  parameters.
- Read [placement data model](reference/placement_data_model.md) for the full `$ps_*`
  metadata contract.
