#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SCRATCH_ROOT="${API_SCRATCH_ROOT:-${REPO_ROOT}/target/docs-api}"
DOCS_OUT="${API_DOCS_OUT:-${REPO_ROOT}/target/docsgen-out}"

usage() {
    cat <<EOF
Usage: $0

Build the generated API reference preview for the currently supported source
trees (`core/` and `models/`) under:

  ${SCRATCH_ROOT}

Environment:
  API_SCRATCH_ROOT    Override the publish-style preview root.
  API_DOCS_OUT        Override the docsgen markdown output tree.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
fi

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

{
    cat <<'EOF'
# API Reference

This preview tree is generated from source comments.

- [Core API](core/index.md)
- [Model API](models/index.md)
EOF
} > "${SCRATCH_ROOT}/index.md"

{
    cat <<'EOF'
# Core API

Generated API reference for `src/polysymmetrica/core/`.

EOF
    for path in "${SCRATCH_ROOT}"/core/*.md; do
        file="$(basename "${path}")"
        [[ "${file}" == "index.md" ]] && continue
        name="${file%.scad.md}"
        printf -- "- [%s](%s)\n" "${name}" "${file}"
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
        printf -- "- [%s](%s)\n" "${name}" "${file}"
    done
} > "${SCRATCH_ROOT}/models/index.md"

echo "API reference preview written to ${SCRATCH_ROOT}"
