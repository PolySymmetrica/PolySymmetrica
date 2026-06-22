# Documentation Inventory

Issue: #185

This document records the current documentation surface and the proposed public
documentation structure for the release documentation work tracked by #25.

## Current Material

### Release-Facing Entry Points

| Path | Current role | Proposed role |
| --- | --- | --- |
| `README.md` | Short project overview and old quick start | Public landing page |
| `docs/developer_guide.md` | Broad developer-facing guide | Split source for user guides and design notes |

### Concept And Feature Notes

| Path | Current role | Proposed role |
| --- | --- | --- |
| `docs/guides/attach.md` | Face attachment API note | User guide or API companion |
| `docs/guides/cantellation.md` | Cantellation implementation/use note | User guide for cantellation |
| `docs/guides/cantitruncation.md` | Cantitruncation implementation/use note | User guide for cantitruncation |
| `docs/guides/construction.md` | Construction helper notes | User guide plus API companion |
| `docs/guides/prisms.md` | Prism and antiprism notes | User guide |
| `docs/guides/profile.md` | Profile row schema | User guide plus API companion |
| `docs/guides/snubs.md` | Snub API, caveats, and usage | User guide |

### Lower-Level Design Notes

| Path | Current role | Proposed role |
| --- | --- | --- |
| `docs/design/face_arrangement.md` | Proposed arrangement/boundary model design | Design note |
| `docs/design/face_regions.md` | Face-region and shell internals | Design note with API companion links |
| `docs/reference/placement_data_model.md` | Placement and record model reference, including `$ps_*` variables | Reference note |
| `docs/design/proxy_interaction.md` | Proxy replay and punch-through design | Design note |
| `docs/design/segments.md` | Face segmentation APIs and internals | Design note plus API companion |

### Examples

There are currently 37 `.scad` examples under `src/polysymmetrica/examples/`.
They fall into these groups:

| Path | Current role | Proposed role |
| --- | --- | --- |
| `examples/basics/` | Models, placement, profiles, attachment | Source for getting-started and early tutorials |
| `examples/classify/` | Classification demo | Classification tutorial support |
| `examples/dev-guide/` | Developer-guide example | Retire or fold into tutorials |
| `examples/segments/` | Face segmentation demos | Advanced guide/design support |
| `examples/truncation/` | Transform demos | Transform tutorial support |
| `examples/poly-frame/` | Older printable frame experiments | Gallery/advanced examples after review |
| `examples/printing/` | Current printable frame/face demo system | Advanced tutorial/gallery material |
| `examples/experiments/` | Focused probes | Internal/dev examples, not first-user docs |

### Images

There are currently 9 image assets in `docs/images/`, including generated
tutorial and getting-started renders.

The docs should distinguish:

- stable generated renders committed to the repo, with known source `.scad` and
  render command;
- gallery or print photos, which can live in GitHub Wiki or another showcase
  location if they are less reproducible or would bloat the repo.

## Proposed Public Structure

Keep primary documentation in the repository so it is versioned with the code.
Use GitHub Wiki only for larger gallery/showcase material if needed.

```text
README.md
docs/
    getting_started.md
    documentation_inventory.md
    tutorials/
        01_models.md
        02_placement.md
        03_classification.md
        04_transforms.md
        05_prisms.md
        06_construction.md
        07_printing.md
    guides/
        attach.md
        cantellation.md
        cantitruncation.md
        construction.md
        placement.md
        prisms.md
        profile.md
        snubs.md
    reference/
        placement_data_model.md
    api/
        index.md
        core/
        models/
    design/
        face_arrangement.md
        face_regions.md
        proxy_interaction.md
        segments.md
    images/
        ...
```

This structure is a target for later issues. #185 should not move files beyond
this inventory unless the structure is explicitly accepted.

## Public API Boundary

Rough current survey:

- about 401 public-looking declarations in `src/polysymmetrica/core/` and
  `src/polysymmetrica/models/`;
- about 394 `_ps_*` private declarations in the same tree.

Generated API docs should include:

- `poly_*` functions and modules;
- `ps_*` functions and modules that are public helpers, accessors, solvers, or
  record APIs;
- `place_on_*` placement modules;
- named model constructors such as `tetrahedron()`, `octahedron()`,
  `icosahedron()`, and named Archimedean/Catalan/Johnson helpers;
- public example-facing utilities that are intentionally reusable.

Generated API docs should exclude by default:

- `_ps_*` private helpers;
- scratch/example-only local modules;
- regression-test modules;
- exploratory probes under `examples/experiments/`.

If a private helper is important for maintainers, document it in a design note
instead of promoting it into the public API reference.

## Immediate Cleanup Candidates

These are good follow-up checks for #186, #187, #190, or #193:

- `README.md` is old and undersells current features such as transforms,
  profiles, construction helpers, face segmentation, and printable face/frame
  work.
- `README.md` links only to `docs/developer_guide.md`; it needs a user-facing
  route to getting started, tutorials, API reference, design notes, and example
  renders.
- `docs/developer_guide.md` is too broad for one page and currently mixes user
  guide, repository tour, API overview, and design-note links.
- `docs/developer_guide.md` lists `construction.scad` twice in the repository
  tree.
- `docs/developer_guide.md` still uses "override" language in places where the
  public concept is now `profile`.
- `docs/guides/snubs.md` has one example assigning `profile=params`; that should be
  checked against current naming conventions.
- `docs/design/face_arrangement.md` is explicitly proposal-oriented and should
  stay in `docs/design/` unless or until those APIs are fully public.
- `docs/images/` contains useful existing renders, but their source examples
  and render commands are not documented yet.

## Documentation Principles

- Prefer runnable examples over prose-only explanations.
- Keep beginner docs short and linear.
- Keep design notes honest about limitations and moving APIs.
- Avoid generic promotional language; use concrete claims and real renders.
- Link every committed docs image to its source or provenance.
- Keep API reference generated or reproducibly extractable from source comments.
- Keep generated API markdown out of the repo until the published-docs path is
  stable; use a reproducible scratch build in the meantime.
