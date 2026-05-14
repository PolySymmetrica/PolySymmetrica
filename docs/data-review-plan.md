# Data Record Review Plan

This is the execution plan for completing the #105 data abstraction work.
OpenSCAD records are plain arrays, so the goal is to make every semantic record
explicit, documented, accessor-backed, and used consistently.

This file is intended as a handoff prompt for a lower-context implementation
pass. Keep commits small and verify after each phase.

## Goals

- Every semantic list-backed record in `core/` is documented in
  `docs/placement_data_model.md`.
- Every semantic record has named constructor/accessor functions.
- Production code, examples, and tests use accessors rather than raw positional
  indexing into semantic records.
- Records do not duplicate data owned by a nested record, especially placement
  frame fields and target/face context fields.
- Code passes existing record objects through call graphs instead of unpacking
  and rebuilding equivalent records.
- Design defects are recorded clearly, but broad redesigns are not folded into
  this audit unless they are mechanical and behavior-preserving.

## Working Definition

A semantic record is any fixed-position array whose slots have stable domain
meaning across helper boundaries. Examples: placement frames, sites, contexts,
intrusion records, replay sites, proxy volume groups, anti-interference shells,
boundary span sites, seam sites, and parameter override rows.

These are not semantic records for this audit: numeric points/vectors,
segments, face index loops, matrix rows, local throwaway tuples used inside one
function, and the established poly descriptor `[verts, faces, e_over_ir]`.

## Initial Inventory

Audit these record families first.

| Record family | Primary owner | Current status |
| --- | --- | --- |
| `ps_placement_frame(...)` | `core/funcs.scad` | Documented; verify all transform users call frame accessors or `ps_placement_frame_matrix(...)`. |
| `ps_target_local_poly_context(...)` | `core/funcs.scad` | Documented; verify no context-taking API is called with raw `poly_faces_idx`, `poly_verts_local` positionally. |
| `ps_face_local_context(...)` | `core/funcs.scad` | Documented; verify helpers receive this record when they need face points plus target context. |
| Face/edge/vertex site records | `core/placement.scad` | Documented; verify frame is the only stored center/axis source of truth. |
| Intrusion records | `core/segments.scad` | Accessor-backed; needs a first-class docs section. |
| Replay sites | `core/placement.scad` | Documented; fix duplicated paragraph and audit duplicated fields versus embedded canonical sites. |
| Proxy volume groups | `core/placement.scad` | Documented; verify grouped record access is accessor-only. |
| Anti-interference shell records | `core/face_regions.scad` | Accessor-backed; needs a first-class docs section. |
| Boundary span sites | `core/segments.scad` | Documented; check duplicated frame components. |
| Seam segment sites | `core/segments.scad` | Documented; check duplicated frame components. |
| Face arrangement / boundary model composites | `core/segments.scad` | Partially described elsewhere; decide whether to formalize as semantic records and add accessors/docs if so. |
| Params rows / compiled param arrays | `core/params.scad` | Fixed-position public-ish rows; decide whether `placement_data_model.md` or `developer_guide.md` owns them. |

## Phase 1: Build The Audit Table

Create or update an audit table in `docs/placement_data_model.md`, or in a
temporary issue comment if working through GitHub. For every in-scope record,
capture:

- record name and constructor/builders;
- all accessors;
- record owner file;
- coordinate space of each geometric field;
- nested records it owns or references;
- raw-index use-sites outside constructors/accessors;
- duplicate data concerns;
- remediation notes.

Use these discovery commands as starting points:

```sh
rg -n "function ps_[a-z0-9_]+\\((site|record|group|ctx|shell|frame)\\) = .*\\[[0-9]+\\]" src/polysymmetrica/core
rg -n "\\[\\s*\\\"[a-zA-Z0-9_]+\\\"" src/polysymmetrica/core
rg -n "ps_face_foreign_proxy_volume_groups\\(|ps_face_foreign_proxy_replay_sites\\(|ps_face_foreign_face_replay_sites\\(" src/polysymmetrica src/tests docs
```

When reviewing raw indexing, distinguish semantic records from ordinary points,
vectors, faces, edges, and local tuples. Do not mechanically replace every
`[0]`.

## Phase 2: Complete The Data Model Docs

Update `docs/placement_data_model.md` so each in-scope record has:

- a short purpose statement;
- builder/constructor function names;
- accessor table;
- coordinate-space notes;
- invariants and ownership notes;
- explicit guidance on when to pass this record instead of unpacking fields.

Known documentation fixes to include:

- Remove the duplicated sentence in the Replay Site section.
- Add an `Intrusion Records` section for `ps_intrusion_*`.
- Add an `Anti-Interference Shell Records` section for
  `ps_face_anti_interference_shell_*`.
- Add a section for face arrangement and boundary model composites, or explicitly
  state why they are not stable semantic records yet.
- Add a `Known Remediation Candidates` section for defects discovered during
  the audit.

Do not document aspirational APIs as if they already exist. If a record needs a
new accessor or constructor, add it in code first or list it as remediation.

## Phase 3: Enforce Accessor Use

Replace raw semantic-record indexing in:

- `src/polysymmetrica/core/`
- `src/tests/`
- `src/polysymmetrica/examples/`

Rules:

- Raw indexing is allowed inside the constructor/accessor definitions for the
  same record.
- Raw indexing is allowed for plain geometry arrays and local temporary tuples.
- Raw indexing into records such as `site`, `record`, `group`, `ctx`, `shell`,
  or `frame` outside accessors must be replaced.
- When a caller has `face_ctx`, derive target context via
  `ps_face_local_context_target_local_poly_context(face_ctx)`.
- When a caller has a site record, use site/context accessors rather than
  reconstructing context from sibling fields.

High-risk call shape to search repeatedly:

```sh
rg -n "ps_face_foreign_proxy_volume_groups\\([^\\n]*" src/polysymmetrica src/tests docs
```

The third argument must be a `ps_target_local_poly_context(...)` record. The
fourth argument is numeric `eps`. Do not pass `poly_faces_idx` and
`poly_verts_local` as positional arguments to the current API.

## Phase 4: Remove Duplication Or Record It

For each record, check whether stored fields duplicate nested record fields.

Records normalized during this audit:

- Replay sites now store a `ps_placement_frame(...)` subrecord directly.
- Boundary span sites are frame-backed and derive their scalar accessors from
  that frame.
- Seam segment sites now store a `ps_placement_frame(...)` subrecord directly.
- Face site geometry/topology accessors now derive from
  `ps_face_site_face_local_context(site)` rather than being duplicated in the
  outer site record.

Remaining work is the final raw-index scan and any new remediation candidates
found during that pass.

Do not perform broad structural record rewrites in the same PR unless the
change is small, mechanical, and fully covered by tests. Prefer adding a
specific follow-up issue for each non-trivial redesign.

## Phase 5: Tests And Verification

After each meaningful commit, run the relevant focused tests. Before review,
run all of these through the watcher:

- `src/tests/run_all.scad`
- `src/polysymmetrica/examples/experiments/face_interference/test_minimal_printable_punch_through_probe.scad`

The probe is required because it has caught context/argument-order regressions
that the full suite may not make obvious.

Add focused assertions where practical:

- context-taking functions reject or fail loudly when handed raw topology arrays
  instead of context records;
- face/edge/vertex sites expose frame-derived center/axis values;
- replay/proxy volume grouping produces the expected nonzero counts for the
  minimal punch-through probe scenario;
- docs examples compile when copied into a small probe file.

Recommended static checks before review:

```sh
rg -n "ps_face_foreign_proxy_volume_groups\\(" src/polysymmetrica src/tests docs
rg -n "(site|record|group|ctx|shell|frame)\\[[0-9]+\\]" src/polysymmetrica/core src/tests src/polysymmetrica/examples
rg -n "ps_placement_frame\\(|ps_placement_frame_matrix\\(" src/polysymmetrica/core src/tests src/polysymmetrica/examples
```

Manually inspect every hit. The second command has false positives; it is an
audit queue, not an automatic failure list.

## Completion Criteria

The work is complete when:

- `docs/placement_data_model.md` covers every in-scope record family above;
- every record listed in the docs has matching accessors in code;
- raw semantic-record indexing outside constructors/accessors has either been
  removed or explicitly justified in a nearby comment;
- context-taking API call sites pass context records, not unpacked positional
  topology;
- full OpenSCAD tests pass;
- the minimal printable punch-through probe renders cleanly;
- unresolved design defects are listed under remediation candidates with enough
  detail to become follow-up issues.
