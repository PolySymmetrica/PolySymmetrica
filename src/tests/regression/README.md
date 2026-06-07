# Visual Regression Tests

This directory contains small OpenSCAD scenes rendered with OpenSCAD and compared
against committed PNG baselines.

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

Parameterized cases expose a `TESTS` array and accept `-D T=<index>`. Output
files use zero-padded test indices, for example:

```text
place_all_sites_00_tet.png
place_all_sites_09_trunc_ico.png
```
