# API Reference

PolySymmetrica's API reference is generated from source comments rather than
maintained by hand.

The generated markdown is treated as a build artifact instead of a checked-in
documentation tree. That keeps the source of truth in `src/`.

The build now runs `openscad-docsgen` directly over the source files in
`core/` and `models/`; it no longer depends on the temporary comment-conversion
path for those directories.

Current scope:

- `src/polysymmetrica/core/`
- `src/polysymmetrica/models/`

Local preview:

```bash
scripts/build_api_reference.sh
```

That builds a publish-style preview tree at:

```text
target/docs-api/
    index.md
    concepts.md
    core/
        index.md
        *.scad.md
    models/
        index.md
        *.scad.md
```

Published reference:

- `.github/workflows/publish_api_docs.yml` builds the same generated tree on
  pushes to `main` and manual dispatches;
- the current `main` API reference is published under `/dev/` so later tagged
  releases can live beside it under versioned paths;
- the workflow renders the generated Markdown with GitHub Pages/Jekyll;
- the workflow's `github-pages` environment records the published URL.

Generated navigation:

- `target/docs-api/index.md`: generated entry point;
- `target/docs-api/concepts.md`: generated concept map;
- `target/docs-api/core/index.md`: generated core source-file index;
- `target/docs-api/models/index.md`: generated model source-file index.

The concept map groups generated pages into descriptors/helpers, models,
placement, classification, transforms, profiles, construction, segments/face
regions, rendering/describe helpers, and solvers. It links to generated
source-file pages rather than duplicating symbol lists by hand.

Design choices for this phase:

- keep generated API docs reproducible from source comments;
- keep generated markdown out of the repository for now;
- publish the generated reference through GitHub Pages rather than committing
  generated Markdown;
- reserve `/dev/` for the current `main` API reference and leave room for
  future immutable release paths;
- publish `core/` and `models/` first;
- keep `examples/` out of the generated reference for now, even though their
  comments use the same line-comment style.
