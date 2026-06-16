# Visual Regression Tests

This directory contains small OpenSCAD scenes rendered with OpenSCAD and compared
against committed PNG baselines. PNGs are generated with `--render`, matching
the full-render path rather than OpenCSG preview mode.

The suite is intended to catch geometry-visible regressions that are hard to
cover with `assert(...)` tests alone: placement frames, displayed metadata,
transform parameter overrides, self-crossing face segmentation, boundary spans,
and construction variants.

## Running

Run locally from the repository root:

```sh
src/tests/regression/run_regression.sh generate
src/tests/regression/run_regression.sh diff
src/tests/regression/run_regression.sh diff --tolerance strict
src/tests/regression/run_regression.sh diff --tolerance loose
```

Generated local outputs are written under `.tmp/regression/`.

The default output size is `1280,960`. Override it with `IMG_SIZE=WIDTH,HEIGHT`
when needed.

The default OpenSCAD command is `openscad-nightly`. Override it with
`OPENSCAD_BIN=openscad` only when deliberately checking another renderer.
In CI, visual regressions run through `xvfb-run` with
`LIBGL_ALWAYS_SOFTWARE=1` to reduce renderer drift.

Render/compare jobs run with GNU `parallel` when it is available. Other
commands named `parallel`, such as moreutils parallel, are ignored. The default
fan-out is `REGRESSION_JOBS=4`; set `REGRESSION_JOBS=1` for serial output or a
higher value when the renderer is stable under more load. Parallel output is
line-buffered and tagged with `<T>:<name>` so failures remain attributable. If
GNU `parallel` is not installed, the runner falls back to serial execution.

On Susan's local machine, prefer the OpenSCAD nightly watcher bridge described
in the repository `AGENTS.md` for ad hoc image renders. Do not broadly kill
`openscad-nightly`; the user may have an interactive session open.

Diff mode uses ImageMagick's absolute-error metric after a configurable fuzz.
`normal` allows 1% channel fuzz and a small resolution-scaled changed-pixel
budget for renderer antialiasing drift; `strict` allows no changed pixels.

## Layout

- `cases/`: source `.scad` files. Subdirectories become output subdirectories.
- `common/`: shared rendering helpers, labels, colors, and portable digits.
- `baselines/openscad/`: committed expected PNGs.
- `.tmp/regression/actual/`: generated images in `diff` mode.
- `.tmp/regression/diff/`: ImageMagick difference images in `diff` mode.
- `.tmp/regression/logs/`: OpenSCAD render and list logs.

Do not commit `.tmp/` outputs or OpenSCAD `.log` sidecars. Commit only case
files, shared helpers, runner changes, and intentional baseline PNG updates.

## Case Contract

Parameterized cases expose a `TESTS` array and accept `-D T=<index>`. Output
files use zero-padded test indices, for example:

```text
place_all_sites_00_tet.png
place_all_sites_09_trunc_ico.png
```

Each case file must support two modes:

- `REG_LIST=true`: call `reg_list_tests(TESTS)` so the Bash runner can discover
  every `T` value and output name.
- Normal render mode: validate `T`, select data from `TESTS[T]` (often via
  `spec = TESTS[T]`), and render the selected scene.

Cases may echo `REGRESSION_RENDER_ARGS=...` in `REG_LIST` mode to override the
default render framing. The default is:

```text
--projection=o --autocenter --viewall --render
```

Use explicit camera args for scenes where text or other renderer-dependent
geometry would otherwise perturb `--viewall` framing.

Prefer putting the test definition in the `TESTS` entry rather than writing a
large `if (T == ...)` cascade. The first field is always the stable test name
used in the PNG filename. Later fields should be the data needed to render that
specific case: a poly descriptor, a builder function, face index, mode string,
parameter rows, or other small config.

Typical patterns:

```scad
TESTS = [
    ["tet", tetrahedron()],
    ["trunc_ico", truncated_icosahedron()]
];

poly = TESTS[T][1];
```

```scad
TESTS = [
    ["cube_rectify", function() poly_rectify(hexahedron())],
    ["ap5_2_truncate", function() poly_truncate(poly_antiprism(5, 2), t = 0.18)]
];

spec = TESTS[T];
reg_poly_preview(spec[1](), ir = 28, show_face_ids = true);
reg_panel_label(spec[0]);
```

```scad
TESTS = [
    ["atut_boundary_spans", "boundary_spans", function() poly_truncate(tetrahedron(), t = -0.5), 0, "all"]
];
```

The last pattern is useful when a case file has several panel types. A small
kind-based dispatcher is fine; avoid dispatching directly on `T`.

## Visual Style

Use `common/regression_common.scad` for shared colors, panel labels, face fills,
poly previews, segment drawing, and text. `reg_text_label(...)` uses
`Liberation Sans:style=Bold`, which OpenSCAD bundles and is expected to be
portable across platforms. For pure numeric labels, `regression_digits.scad`
provides geometry-based digits that avoid system font differences.

Keep scenes small and diagnostic:

- Include labels when they help identify a swapped index, wrong frame, or lost
  metadata field.
- Use distinct colors for different site kinds or segment kinds.
- Prefer one focused panel per behavior over a general demo scene.
- Keep filenames stable; changing a `TESTS` name renames the baseline.
- Use `printf '%02d'` ordering indirectly by relying on the runner output
  naming; do not bake index text into `TESTS` names.

## Adding Or Updating Tests

1. Add or edit a `.scad` case under `cases/<topic>/`.
2. Include `../../common/regression_common.scad`.
3. Define `TESTS`, `T_MAX`, `T`, `REG_LIST`, and an explicit range assert.
4. Ensure `REG_LIST` calls `reg_list_tests(TESTS)`.
5. Render the selected `T` using data from `TESTS[T]`.
6. Run `src/tests/regression/run_regression.sh generate` to update baselines.
7. Run `src/tests/regression/run_regression.sh diff --tolerance strict` when
   the same machine/render path should be exact, or `--tolerance normal` for
   the CI-equivalent tolerance.
8. Inspect changed PNGs visually before committing them.

When investigating a diff failure, compare:

- `baselines/openscad/...`: expected image.
- `.tmp/regression/actual/...`: newly rendered image.
- `.tmp/regression/diff/...`: red-on-white changed pixels from ImageMagick.

If the diff image looks like a faint copy of the whole object, suspect renderer
or antialiasing drift first. If only local features move, suspect a real
geometry, placement, label, or metadata change.
