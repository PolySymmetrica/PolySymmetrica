#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SCRATCH_ROOT="${API_SCRATCH_ROOT:-${REPO_ROOT}/target/docs-api}"
DOCS_OUT="${API_DOCS_OUT:-${REPO_ROOT}/target/docsgen-out}"
API_LINK_EXT="${API_LINK_EXT:-md}"

usage() {
    cat <<EOF
Usage: $0

Build the generated API reference preview for the currently supported source
trees (`core/` and `models/`) under:

  ${SCRATCH_ROOT}

Environment:
  API_SCRATCH_ROOT    Override the publish-style preview root.
  API_DOCS_OUT        Override the docsgen markdown output tree.
  API_LINK_EXT        Link extension for generated indexes (`md` or `html`).
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
fi

case "${API_LINK_EXT}" in
    md|html) ;;
    *)
        echo "API_LINK_EXT must be 'md' or 'html'" >&2
        exit 1
        ;;
esac

mkdir -p "${SCRATCH_ROOT}"
mkdir -p "${DOCS_OUT}"

if command -v openscad-docsgen >/dev/null 2>&1; then
    DOCSGEN_BIN="openscad-docsgen"
elif [[ -x "${HOME}/.local/bin/openscad-docsgen" ]]; then
    DOCSGEN_BIN="${HOME}/.local/bin/openscad-docsgen"
else
    echo "openscad-docsgen not found in PATH or ~/.local/bin" >&2
    exit 1
fi

rm -rf "${DOCS_OUT}/src/polysymmetrica/core" "${DOCS_OUT}/src/polysymmetrica/models"

"${DOCSGEN_BIN}" -q -n -m -r \
    -D "${DOCS_OUT}" \
    src/polysymmetrica/core/*.scad \
    src/polysymmetrica/models/*.scad >/dev/null

rm -rf "${SCRATCH_ROOT}/core" "${SCRATCH_ROOT}/models"
mkdir -p "${SCRATCH_ROOT}/core" "${SCRATCH_ROOT}/models"

copy_generated_markdown() {
    local section="$1"
    local output_dir="$2"
    local -a docsgen_candidates

    shopt -s nullglob
    docsgen_candidates=("${DOCS_OUT}/src/polysymmetrica/${section}"/*.md)
    shopt -u nullglob

    if ((${#docsgen_candidates[@]} > 0)); then
        cp "${docsgen_candidates[@]}" "${output_dir}/"
    else
        echo "No generated markdown found for ${section} in ${DOCS_OUT}" >&2
        exit 1
    fi
}

copy_generated_markdown core "${SCRATCH_ROOT}/core"
copy_generated_markdown models "${SCRATCH_ROOT}/models"

api_link() {
    local path="$1"
    case "${API_LINK_EXT}" in
        md) printf '%s' "${path}" ;;
        html) printf '%s' "${path%.md}.html" ;;
    esac
}

{
    cat <<'EOF'
title: PolySymmetrica API Reference
markdown: kramdown
EOF
} > "${SCRATCH_ROOT}/_config.yml"

{
    cat <<EOF
# API Reference

This preview tree is generated from source comments.

- [API by concept]($(api_link "concepts.md"))
- [Core file index]($(api_link "core/index.md"))
- [Model file index]($(api_link "models/index.md"))
EOF
} > "${SCRATCH_ROOT}/index.md"

{
    cat <<EOF
# API Reference By Concept

This index groups generated API pages by common user task. The source-file
indexes remain available when you need to inspect a specific implementation
module.

## Descriptor Basics And Helpers

- [Poly descriptors and vector helpers]($(api_link "core/funcs.scad.md"))
- [Validation]($(api_link "core/validate.scad.md"))
- [Cleanup]($(api_link "core/cleanup.scad.md"))

## Models

- [Platonic solids]($(api_link "models/platonics_all.scad.md"))
- [Archimedean solids]($(api_link "models/archimedians_all.scad.md"))
- [Catalan solids]($(api_link "models/catalans_all.scad.md"))
- [Johnson solids]($(api_link "models/johnsons_all.scad.md"))
- [Prisms and antiprisms]($(api_link "core/prisms.scad.md"))
- [Individual model files]($(api_link "models/index.md"))

## Placement

- [Face, edge, vertex, and proxy placement]($(api_link "core/placement.scad.md"))
- [Placement data records]($(api_link "core/placement_data.scad.md"))
- [Vertex fans and vertex figures]($(api_link "core/vertex.scad.md"))

## Classification And Profiles

- [Classification]($(api_link "core/classify.scad.md"))
- [Profile rows and compiled profile lookup]($(api_link "core/profile.scad.md"))

## Transforms

- [Truncation, rectification, cantellation, cantitruncation, and snubs]($(api_link "core/truncation.scad.md"))
- [Generic transforms]($(api_link "core/transform.scad.md"))
- [Transform helpers]($(api_link "core/transform_util.scad.md"))
- [Duals]($(api_link "core/duals.scad.md"))

## Construction

- [Delete, cap, slice, attach, cupola, rotunda, and elongation helpers]($(api_link "core/construction.scad.md"))

## Segments And Face Regions

- [Segment and self-crossing face analysis]($(api_link "core/segments.scad.md"))
- [Segment data records]($(api_link "core/segments_data.scad.md"))
- [Face-region volumes]($(api_link "core/face_regions.scad.md"))
- [Loop-shell geometry]($(api_link "core/loop_shells.scad.md"))

## Rendering And Description

- [Rendering helpers]($(api_link "core/render.scad.md"))
- [Shared describe/string helpers]($(api_link "core/funcs.scad.md"))

## Solvers

- [Numeric and geometry solvers]($(api_link "core/solvers.scad.md"))
EOF
} > "${SCRATCH_ROOT}/concepts.md"

{
    cat <<'EOF'
# Core API

Generated API reference for `src/polysymmetrica/core/`.

EOF
    for path in "${SCRATCH_ROOT}"/core/*.md; do
        file="$(basename "${path}")"
        [[ "${file}" == "index.md" ]] && continue
        name="${file%.scad.md}"
        printf -- "- [%s](%s)\n" "${name}" "$(api_link "${file}")"
    done
} > "${SCRATCH_ROOT}/core/index.md"

{
    cat <<'EOF'
# Model API

Generated API reference for `src/polysymmetrica/models/`.

EOF
    for path in "${SCRATCH_ROOT}"/models/*.md; do
        file="$(basename "${path}")"
        [[ "${file}" == "index.md" ]] && continue
        name="${file%.scad.md}"
        printf -- "- [%s](%s)\n" "${name}" "$(api_link "${file}")"
    done
} > "${SCRATCH_ROOT}/models/index.md"

echo "API reference preview written to ${SCRATCH_ROOT}"
