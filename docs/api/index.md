# API Reference

PolySymmetrica's API reference is generated from source comments rather than
maintained by hand.

For now, the generated markdown is treated as a build artifact instead of a
checked-in documentation tree. That keeps the source of truth in `src/` while
the published-docs path settles down.

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
    core/
        index.md
        *.scad.md
    models/
        index.md
        *.scad.md
```

Design choices for this phase:

- keep generated API docs reproducible from source comments;
- keep generated markdown out of the repository for now;
- publish `core/` and `models/` first, then decide whether `examples/` belongs
  in the reference at all.
