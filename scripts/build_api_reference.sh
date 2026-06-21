#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SCRATCH_ROOT="${API_SCRATCH_ROOT:-${REPO_ROOT}/.tmp/docs-api}"
CONVERTED_ROOT="${API_CONVERTED_ROOT:-${REPO_ROOT}/.tmp/docsgen-src}"

usage() {
    cat <<EOF
Usage: $0

Build the generated API reference preview for the currently supported source
trees (`core/` and `models/`) under:

  ${SCRATCH_ROOT}

Environment:
  API_SCRATCH_ROOT    Override the publish-style preview root.
  API_CONVERTED_ROOT  Override the scratch docsgen source tree.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
fi

mkdir -p "${SCRATCH_ROOT}"

"${REPO_ROOT}/scripts/convert_docsgen.py" \
    --run-docsgen \
    --output-root "${CONVERTED_ROOT}" \
    src/polysymmetrica/core \
    src/polysymmetrica/models >/dev/null

rm -rf "${SCRATCH_ROOT}/core" "${SCRATCH_ROOT}/models"
mkdir -p "${SCRATCH_ROOT}/core" "${SCRATCH_ROOT}/models"

cp "${CONVERTED_ROOT}/polysymmetrica/core/"*.md "${SCRATCH_ROOT}/core/"
cp "${CONVERTED_ROOT}/polysymmetrica/models/"*.md "${SCRATCH_ROOT}/models/"

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
