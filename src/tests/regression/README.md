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

# Run every case below one directory.
src/tests/regression/run_regression.sh diff --case transforms

# Run every T value from one case file.
src/tests/regression/run_regression.sh diff --case transforms/snubs.scad

# Run one T value from one case file.
src/tests/regression/run_regression.sh diff --case transforms/snubs.scad --test 3
```

`--case` paths are resolved relative to `cases/`. A directory is searched
recursively for `.scad` cases. `--test` is an index in the selected case's
`TESTS` array and requires `--case` to name one file. With no selector, the
entire regression suite runs as before. Partial `generate` runs update only
the selected images; the committed baseline renderer marker is updated only
after a successful unfiltered full-suite generation.

Generated local outputs are written under `target/regression-tests/`.

The default output size is `1280,960`. Override it with `IMG_SIZE=WIDTH,HEIGHT`
when needed.
Status labels are colored when output is a terminal. Use
`REGRESSION_COLOR=always` to force ANSI color in CI logs, or
`REGRESSION_COLOR=never` for plain output.

The default OpenSCAD command is `openscad-nightly`. Override it with
`OPENSCAD_BIN=openscad` only when deliberately checking another renderer.
In CI, visual regressions run through `xvfb-run` with
`LIBGL_ALWAYS_SOFTWARE=1` to reduce renderer drift.

The committed baseline set records the renderer version in
`baselines/openscad/version.properties`. Each run writes the current renderer
version to `target/regression-tests/version.properties`; on a regression
failure, the runner prints both versions and warns loudly when they differ.
The runner prints `FAIL` for image differences and `ERROR` for discovery,
render/assertion, missing-baseline, or ImageMagick execution errors. On
non-success, the final summary lists the exact tests in each group. After all
jobs finish, an aggregate `STATUS: PASS`, `STATUS: FAIL`, or `STATUS: ERROR`
banner is printed before the counts; execution errors take precedence over
image diffs.

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
- `baselines/openscad/`: committed expected PNGs and renderer version marker.
- `target/regression-tests/actual/`: generated images in `diff` mode.
- `target/regression-tests/diff/`: ImageMagick difference images in `diff` mode.
- `target/regression-tests/logs/`: OpenSCAD render, list, compare, and status logs.

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

- `REG_LIST=true`: call `reg_list_tests(TESTS, render_args = ...)` so the Bash
  runner can discover every `T` value, output name, and fixed camera args.
- Normal render mode: validate `T`, select data from `TESTS[T]` (often via
  `spec = TESTS[T]`), and render the selected scene.

Cases may echo `REGRESSION_RENDER_ARGS=...` in `REG_LIST` mode to override the
default render framing. The default is:

```text
--projection=o --autocenter --viewall --render
```

Prefer explicit camera args for committed regression cases. `--viewall` is
convenient for ad hoc previews, but it makes the camera depend on the rendered
bounding box: small size or placement changes can rescale or recenter the whole
image, and genuine size changes can be normalized away. The shared
`common/regression_common.scad` presets cover the usual scene layouts:

```scad
reg_list_tests(TESTS, render_args = REG_RENDER_ARGS_POLY_SINGLE);
reg_list_tests(TESTS, render_args = REG_RENDER_ARGS_POLY_ROW);
reg_list_tests(TESTS, render_args = REG_RENDER_ARGS_POLY_GRID);
reg_list_tests(TESTS, render_args = REG_RENDER_ARGS_FLAT);
```

Keep the default `--autocenter --viewall` only for a case that intentionally
tests renderer auto-framing.

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
4. Ensure `REG_LIST` calls `reg_list_tests(TESTS, render_args = ...)` with a
   fixed-camera preset unless auto-framing is intentional.
5. Render the selected `T` using data from `TESTS[T]`.
6. Run `src/tests/regression/run_regression.sh generate` to update baselines.
7. Run `src/tests/regression/run_regression.sh diff --tolerance strict` when
   the same machine/render path should be exact, or `--tolerance normal` for
   the CI-equivalent tolerance.
8. Inspect changed PNGs visually before committing them.

When investigating a diff failure, compare:

- `baselines/openscad/...`: expected image.
- `target/regression-tests/actual/...`: newly rendered image.
- `target/regression-tests/diff/...`: red-on-white changed pixels from ImageMagick.

If the diff image looks like a faint copy of the whole object, suspect renderer
or antialiasing drift first. If only local features move, suspect a real
geometry, placement, label, or metadata change.
