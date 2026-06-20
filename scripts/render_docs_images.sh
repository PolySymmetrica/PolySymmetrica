#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OPENSCAD_BIN="${OPENSCAD_BIN:-openscad-nightly}"
IMG_SIZE="${IMG_SIZE:-1280,960}"

usage() {
    cat <<EOF
Usage: $0 [all|first_taste|tutorial_01_models|tutorial_02_placement]

Environment:
  OPENSCAD_BIN  OpenSCAD command to use (default: openscad-nightly)
  IMG_SIZE      Output image size, WIDTH,HEIGHT (default: 1280,960)
EOF
}

if [[ "${1:-all}" == "--help" || "${1:-all}" == "-h" ]]; then
    usage
    exit 0
fi

if ! command -v "${OPENSCAD_BIN}" >/dev/null 2>&1; then
    echo "OpenSCAD command not found: ${OPENSCAD_BIN}" >&2
    exit 1
fi

render_one() {
    local name="$1"
    local source="$2"
    local output="$3"
    shift 3
    local -a render_args=("$@")

    mkdir -p "$(dirname "${output}")"

    echo "render_docs_images: ${name}"
    OPENSCADPATH="${REPO_ROOT}/src${OPENSCADPATH:+:${OPENSCADPATH}}" \
        "${OPENSCAD_BIN}" \
            -o "${output}" \
            --imgsize="${IMG_SIZE}" \
            "${render_args[@]}" \
            "${source}"
}

render_first_taste() {
    render_one \
        first_taste \
        "${REPO_ROOT}/docs/examples/first_taste.scad" \
        "${REPO_ROOT}/docs/images/generated/first_taste.png" \
        --projection=o \
        --autocenter \
        --viewall \
        --render=true
}

render_tutorial_01_models() {
    render_one \
        tutorial_01_models \
        "${REPO_ROOT}/docs/examples/tutorial_01_models.scad" \
        "${REPO_ROOT}/docs/images/generated/tutorial_01_models.png" \
        --projection=o \
        --autocenter \
        --viewall \
        --render=true
}

render_tutorial_02_placement() {
    render_one \
        tutorial_02_placement \
        "${REPO_ROOT}/docs/examples/tutorial_02_placement.scad" \
        "${REPO_ROOT}/docs/images/generated/tutorial_02_placement.png" \
        --projection=o \
        --autocenter \
        --viewall \
        --render=true
}

case "${1:-all}" in
    all)
        render_first_taste
        render_tutorial_01_models
        render_tutorial_02_placement
        ;;
    first_taste)
        render_first_taste
        ;;
    tutorial_01_models)
        render_tutorial_01_models
        ;;
    tutorial_02_placement)
        render_tutorial_02_placement
        ;;
    *)
        echo "Unknown docs image target: $1" >&2
        usage >&2
        exit 2
        ;;
esac
