#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OPENSCAD_BIN="${OPENSCAD_BIN:-openscad-nightly}"
IMG_SIZE="${IMG_SIZE:-1280,960}"
TARGETS=(
    first_taste
    tutorial_01_models
    tutorial_02_placement
    tutorial_03_basic_printing
    tutorial_04_placement_metadata
    tutorial_05_boolean_patterns
    tutorial_05_face_region_volumes
    tutorial_06_transforms
    tutorial_07_prisms_antiprisms
    tutorial_08_classification
    tutorial_09_profiles
    tutorial_10_construction_topology
    tutorial_10_construction_johnsons
)

usage() {
    local target_list
    target_list="$(IFS='|'; echo "${TARGETS[*]}")"
    cat <<EOF
Usage: $0 [all|${target_list}]

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

render_named() {
    local name="$1"
    render_one \
        "${name}" \
        "${REPO_ROOT}/docs/examples/${name}.scad" \
        "${REPO_ROOT}/docs/images/generated/${name}.png" \
        --projection=o \
        --autocenter \
        --viewall \
        --render=true
}

target_known() {
    local target="$1"
    local known
    for known in "${TARGETS[@]}"; do
        [[ "${known}" == "${target}" ]] && return 0
    done
    return 1
}

target="${1:-all}"
if [[ "${target}" == "all" ]]; then
    for name in "${TARGETS[@]}"; do
        render_named "${name}"
    done
elif target_known "${target}"; then
    render_named "${target}"
else
    echo "Unknown docs image target: ${target}" >&2
    usage >&2
    exit 2
fi
