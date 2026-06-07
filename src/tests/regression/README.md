# Visual Regression Tests

This directory contains small OpenSCAD scenes rendered with OpenSCAD and compared
against committed PNG baselines. PNGs are generated with `--render`, matching
the full-render path rather than OpenCSG preview mode.

Run locally:

```sh
src/tests/regression/run_regression.sh generate
src/tests/regression/run_regression.sh diff
src/tests/regression/run_regression.sh diff --tolerance strict
src/tests/regression/run_regression.sh diff --tolerance loose
```

Generated local outputs are written under `.tmp/regression/`.

The default output size is `1280,960`. Override it with `IMG_SIZE=WIDTH,HEIGHT`
when needed.

Diff mode uses ImageMagick's absolute-error metric after a configurable fuzz.
`normal` allows 1% channel fuzz and a small resolution-scaled changed-pixel
budget for renderer antialiasing drift; `strict` allows no changed pixels.

Parameterized cases expose a `TESTS` array and accept `-D T=<index>`. Output
files use zero-padded test indices, for example:

```text
place_all_sites_00_tet.png
place_all_sites_09_trunc_ico.png
```
