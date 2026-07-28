# Repository Guide

This repo is OpenSCAD-first. Keep this file short: put durable concepts here
and move feature-specific design notes to `docs/`.

## Project Layout

- `src/polysymmetrica/core/`: core math, topology, placement, construction,
  segmentation, and printing helpers.
- `src/polysymmetrica/models/`: named polyhedra and model aggregates.
- `src/examples/`: runnable OpenSCAD examples and demos.
- `src/tests/`: OpenSCAD tests, including `src/tests/core/` and
  `src/tests/negative/`.
- `docs/`: design notes and API explanations. Start with:
  - `docs/developer_guide.md`
  - `docs/reference/placement_data_model.md`
  - `docs/design/segments.md`
  - `docs/design/face_regions.md`
  - `docs/design/proxy_interaction.md`
  - `docs/guides/construction.md`

## Commands

- Render an example:
  `openscad-nightly -o /tmp/ps-preview.stl src/examples/basics/main_basics.scad`
- Run full tests:
  `openscad-nightly -o /tmp/ps-tests.stl src/tests/run_all.scad`
- Run negative tests:
  `src/tests/run_negative_all.sh`
- Use `openscad-nightly`, though it's snap-sandboxed, so on this machine, use the watcher
  bridge in `.tmp/openscad_nightly_render.spec` and inspect it with:
  `.tmp/openscad_nightly_status.sh` - don't vary the commands unnecessarily, to avoid repeated permission requests.

Do not broadly kill `openscad-nightly`; the user may have an interactive session
open. Only target exact non-interactive commands started for the current task.

Scratch `.scad` probes and generated outputs belong in `/tmp` or `.tmp/`, not
the repo root. Do not commit `.tmp/` artifacts.

## Code Style

- Indent with 4 spaces.
- Use `snake_case` for functions/modules and lower snake case for files.
- Use named colors in examples where practical.
- Prefer small modules and push reusable logic into pure functions that can be
  tested.
- Add Javadoc-style comments for public functions/modules. Use concise
  `Function`, `Params`, `Returns`, and optional `Limitations/Gotchas` lines.
- Prefer shared helpers in `core/funcs.scad` over duplicated private utilities.
- Remove thin pass-through wrappers when they add no semantic value.
- Avoid going out of the way to maintain backwards compatibility - the only user code is in this project
  at this time, so better to check and fix usages than add clutter.
- Openscad is very weakly typed so high functional test coverage must be maintained.
- Avoid "fallback" defensive coding and unwarranted defaults, which can lead to inexplicable behaviour. In cases of invalid use,
  try to (in decrease order of preference) a) fix the usage site, b) assert, c) ok, maybe a default action. This is a higher priority 
  for the lower level internals; high-level user-facing code can be more generous.

## Data Model

- Poly descriptors are `[verts, faces, e_over_ir]`; use accessors from
  `core/funcs.scad`.
- Orientation follows OpenSCAD LHR: faces are clockwise when viewed from
  outside. `ps_face_normal(...)` and `poly_face_ez(...)` follow this convention.
- Placement metadata uses `$ps_*` variables. Keep names stable and document new
  public metadata in `docs/reference/placement_data_model.md`.
- In proxy replay, child modules run in the replayed foreign element context;
  use `$ps_proxy_target_face_idx` when filtering geometry that must not include
  the original face being cut.
- Treat list-backed records as private layouts. Use accessor functions and pass
  semantic records such as `ps_placement_frame(...)`,
  `ps_target_local_poly_context(...)`, and `ps_face_local_context(...)` rather
  than raw field bundles.
- If classification matters, compute it once and reuse the same `cls` through
  placement and override code to avoid family-id drift.

## Testing

- Tests are OpenSCAD modules with `assert(...)` calls in `src/tests/core/`.
- Add new tests with a `test_*` prefix and register them in
  `src/tests/run_all.scad`.
- Keep tolerances explicit.
- Do not rely on `poly_valid(...)` alone for transform/operator correctness;
  add operation-specific checks for counts, adjacency, orientation, family IDs,
  and generated metadata.
- For behavior changes, run the focused test first, then the full suite.

## Validation Modes

- `poly_valid(poly, "struct")`: structure and planarity.
- `poly_valid(poly, "closed")`: manifoldness and no self-intersections.
- `poly_valid(poly, "star_ok")`: allows self-intersections but keeps
  manifoldness.
- `poly_valid(poly, "convex")`: outward orientation and convexity.

## Documentation Map

- Placement frames, `$ps_*` metadata, site records:
  `docs/reference/placement_data_model.md`
- Self-crossing faces, boundary spans, seam segments:
  `docs/design/segments.md` and `docs/design/face_arrangement.md`
- Positive face volumes and anti-interference shells:
  `docs/design/face_regions.md`
- Foreign proxy replay and punch-through handling:
  `docs/design/proxy_interaction.md`
- Construction, attach, slice, cap, Johnson helpers:
  `docs/guides/construction.md`
- Prisms, antiprisms, snubs, cantellation/cantitruncation:
  `docs/guides/prisms.md`, `docs/guides/snubs.md`,
  `docs/guides/cantellation.md`, `docs/guides/cantitruncation.md`, and
  `docs/guides/profile.md`

## Git And PRs

- Commit messages are short, imperative, and capitalized; prefix with an issue
  number when useful, e.g. `[#131] Refactor shell context wiring`.
- PRs should summarize behavior, list affected `.scad` paths, and mention tests
  or renders. Include screenshots/renders for geometry-visible changes.
- Never revert user changes unless explicitly asked. Work with dirty trees and
  keep edits scoped to the current task.
- If GitHub access fails due to auth problems, just pause to let the user remediate - don't
  waste tokens trying to work around it. Advise that client restart may work.
