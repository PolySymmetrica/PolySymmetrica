#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OPENSCAD_BIN="${OPENSCAD_BIN:-openscad-nightly}"
IMG_SIZE="${IMG_SIZE:-1280,960}"

usage() {
    cat <<EOF
Usage: $0 [all|first_taste|tutorial_01_models|tutorial_02_placement|tutorial_03_basic_printing|tutorial_04_placement_metadata|tutorial_05_boolean_patterns|tutorial_05_face_region_volumes|tutorial_06_transforms|tutorial_07_prisms_antiprisms|tutorial_08_classification|tutorial_09_profiles|tutorial_10_construction_topology|tutorial_10_construction_johnsons]

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

render_tutorial_03_basic_printing() {
    render_one \
        tutorial_03_basic_printing \
        "${REPO_ROOT}/docs/examples/tutorial_03_basic_printing.scad" \
        "${REPO_ROOT}/docs/images/generated/tutorial_03_basic_printing.png" \
        --projection=o \
        --autocenter \
        --viewall \
        --render=true
}

render_tutorial_04_placement_metadata() {
    render_one \
        tutorial_04_placement_metadata \
        "${REPO_ROOT}/docs/examples/tutorial_04_placement_metadata.scad" \
        "${REPO_ROOT}/docs/images/generated/tutorial_04_placement_metadata.png" \
        --projection=o \
        --autocenter \
        --viewall \
        --render=true
}

render_tutorial_05_boolean_patterns() {
    render_one \
        tutorial_05_boolean_patterns \
        "${REPO_ROOT}/docs/examples/tutorial_05_boolean_patterns.scad" \
        "${REPO_ROOT}/docs/images/generated/tutorial_05_boolean_patterns.png" \
        --projection=o \
        --autocenter \
        --viewall \
        --render=true
}

render_tutorial_05_face_region_volumes() {
    render_one \
        tutorial_05_face_region_volumes \
        "${REPO_ROOT}/docs/examples/tutorial_05_face_region_volumes.scad" \
        "${REPO_ROOT}/docs/images/generated/tutorial_05_face_region_volumes.png" \
        --projection=o \
        --autocenter \
        --viewall \
        --render=true
}

render_tutorial_06_transforms() {
    render_one \
        tutorial_06_transforms \
        "${REPO_ROOT}/docs/examples/tutorial_06_transforms.scad" \
        "${REPO_ROOT}/docs/images/generated/tutorial_06_transforms.png" \
        --projection=o \
        --autocenter \
        --viewall \
        --render=true
}

render_tutorial_07_prisms_antiprisms() {
    render_one \
        tutorial_07_prisms_antiprisms \
        "${REPO_ROOT}/docs/examples/tutorial_07_prisms_antiprisms.scad" \
        "${REPO_ROOT}/docs/images/generated/tutorial_07_prisms_antiprisms.png" \
        --projection=o \
        --autocenter \
        --viewall \
        --render=true
}

render_tutorial_08_classification() {
    render_one \
        tutorial_08_classification \
        "${REPO_ROOT}/docs/examples/tutorial_08_classification.scad" \
        "${REPO_ROOT}/docs/images/generated/tutorial_08_classification.png" \
        --projection=o \
        --autocenter \
        --viewall \
        --render=true
}

render_tutorial_09_profiles() {
    render_one \
        tutorial_09_profiles \
        "${REPO_ROOT}/docs/examples/tutorial_09_profiles.scad" \
        "${REPO_ROOT}/docs/images/generated/tutorial_09_profiles.png" \
        --projection=o \
        --autocenter \
        --viewall \
        --render=true
}

render_tutorial_10_construction_topology() {
    render_one \
        tutorial_10_construction_topology \
        "${REPO_ROOT}/docs/examples/tutorial_10_construction_topology.scad" \
        "${REPO_ROOT}/docs/images/generated/tutorial_10_construction_topology.png" \
        --projection=o \
        --autocenter \
        --viewall \
        --render=true
}

render_tutorial_10_construction_johnsons() {
    render_one \
        tutorial_10_construction_johnsons \
        "${REPO_ROOT}/docs/examples/tutorial_10_construction_johnsons.scad" \
        "${REPO_ROOT}/docs/images/generated/tutorial_10_construction_johnsons.png" \
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
        render_tutorial_03_basic_printing
        render_tutorial_04_placement_metadata
        render_tutorial_05_boolean_patterns
        render_tutorial_05_face_region_volumes
        render_tutorial_06_transforms
        render_tutorial_07_prisms_antiprisms
        render_tutorial_08_classification
        render_tutorial_09_profiles
        render_tutorial_10_construction_topology
        render_tutorial_10_construction_johnsons
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
    tutorial_03_basic_printing)
        render_tutorial_03_basic_printing
        ;;
    tutorial_04_placement_metadata)
        render_tutorial_04_placement_metadata
        ;;
    tutorial_05_boolean_patterns)
        render_tutorial_05_boolean_patterns
        ;;
    tutorial_05_face_region_volumes)
        render_tutorial_05_face_region_volumes
        ;;
    tutorial_06_transforms)
        render_tutorial_06_transforms
        ;;
    tutorial_07_prisms_antiprisms)
        render_tutorial_07_prisms_antiprisms
        ;;
    tutorial_08_classification)
        render_tutorial_08_classification
        ;;
    tutorial_09_profiles)
        render_tutorial_09_profiles
        ;;
    tutorial_10_construction_topology)
        render_tutorial_10_construction_topology
        ;;
    tutorial_10_construction_johnsons)
        render_tutorial_10_construction_johnsons
        ;;
    *)
        echo "Unknown docs image target: $1" >&2
        usage >&2
        exit 2
        ;;
esac
