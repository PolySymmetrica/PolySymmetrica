#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
CASE_ROOT="${SCRIPT_DIR}/cases"
TMP_ROOT="${REPO_ROOT}/.tmp/regression"
BASELINE_ROOT="${BASELINE_ROOT:-${SCRIPT_DIR}/baselines/openscad}"
ACTUAL_ROOT="${ACTUAL_ROOT:-${TMP_ROOT}/actual}"
DIFF_ROOT="${DIFF_ROOT:-${TMP_ROOT}/diff}"
LOG_ROOT="${TMP_ROOT}/logs"
OPENSCAD_BIN="${OPENSCAD_BIN:-openscad-nightly}"
IMG_SIZE="${IMG_SIZE:-1280,960}"
CAMERA_ARGS=(--imgsize="${IMG_SIZE}" --projection=o --autocenter --viewall)
MODE="${1:-}"
TOLERANCE="normal"

usage() {
    cat <<EOF
Usage: $0 generate|diff [--tolerance strict|normal|loose]

Environment:
  OPENSCAD_BIN  OpenSCAD command to use (default: openscad-nightly)
  IMG_SIZE      Output image size, WIDTH,HEIGHT (default: 1280,960)
EOF
}

if [[ -z "${MODE}" ]]; then
    usage
    exit 2
fi
shift

while [[ $# -gt 0 ]]; do
    case "$1" in
        --tolerance)
            TOLERANCE="${2:-}"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage
            exit 2
            ;;
    esac
done

case "${MODE}" in
    generate|diff) ;;
    *)
        echo "Unknown mode: ${MODE}" >&2
        usage
        exit 2
        ;;
esac

case "${TOLERANCE}" in
    strict)
        FUZZ="0%"
        MAX_CHANGED_PIXELS=0
        ;;
    normal)
        FUZZ="1%"
        MAX_CHANGED_PIXELS=50
        ;;
    loose)
        FUZZ="2.5%"
        MAX_CHANGED_PIXELS=500
        ;;
    *)
        echo "Unknown tolerance: ${TOLERANCE}" >&2
        usage
        exit 2
        ;;
esac

if ! command -v "${OPENSCAD_BIN}" >/dev/null 2>&1; then
    echo "OpenSCAD command not found: ${OPENSCAD_BIN}" >&2
    exit 1
fi

if command -v magick >/dev/null 2>&1; then
    COMPARE_CMD=(magick compare)
elif command -v compare >/dev/null 2>&1; then
    COMPARE_CMD=(compare)
else
    COMPARE_CMD=()
fi

if [[ "${MODE}" == "diff" && ${#COMPARE_CMD[@]} -eq 0 ]]; then
    echo "ImageMagick compare command not found. Install imagemagick." >&2
    exit 1
fi

mkdir -p "${ACTUAL_ROOT}" "${DIFF_ROOT}" "${LOG_ROOT}" "${BASELINE_ROOT}"

case_rel_path() {
    local case_file="$1"
    realpath --relative-to="${CASE_ROOT}" "${case_file}"
}

list_case_tests() {
    local case_file="$1"
    local rel base log out

    rel="$(case_rel_path "${case_file}")"
    base="${rel%.scad}"
    log="${LOG_ROOT}/${base}.list.log"
    out="${TMP_ROOT}/list/${base}.stl"
    mkdir -p "$(dirname "${log}")" "$(dirname "${out}")"

    "${OPENSCAD_BIN}" \
        -o "${out}" \
        -D REG_LIST=true \
        -D T=0 \
        "${case_file}" >"${log}" 2>&1

    sed -n 's/.*REGRESSION_TEST=\([0-9][0-9]*\) \([^"]*\).*/\1 \2/p' "${log}"
}

render_case_test() {
    local case_file="$1"
    local idx="$2"
    local name="$3"
    local root="$4"
    local rel base dir stem out log

    rel="$(case_rel_path "${case_file}")"
    base="${rel%.scad}"
    dir="$(dirname "${base}")"
    stem="$(basename "${base}")"
    out="${root}/${dir}/${stem}_$(printf '%02d' "${idx}")_${name}.png"
    log="${LOG_ROOT}/${dir}/${stem}_$(printf '%02d' "${idx}")_${name}.render.log"
    mkdir -p "$(dirname "${out}")" "$(dirname "${log}")"

    echo "Rendering ${rel} T=${idx} (${name}) -> ${out}"
    "${OPENSCAD_BIN}" \
        -o "${out}" \
        "${CAMERA_ARGS[@]}" \
        -D "T=${idx}" \
        "${case_file}" >"${log}" 2>&1
}

compare_images() {
    local expected="$1"
    local actual="$2"
    local diff="$3"
    local metric_log="$4"
    local changed

    mkdir -p "$(dirname "${diff}")" "$(dirname "${metric_log}")"

    set +e
    "${COMPARE_CMD[@]}" -metric AE -fuzz "${FUZZ}" "${expected}" "${actual}" "${diff}" >"${metric_log}" 2>&1
    rc=$?
    set -e

    changed="$(tr -dc '0-9' <"${metric_log}")"
    changed="${changed:-0}"

    if [[ "${rc}" -gt 1 ]]; then
        echo "FAIL: ImageMagick compare failed for ${actual}"
        sed 's/^/      /' "${metric_log}"
        return 1
    fi

    if [[ "${changed}" -gt "${MAX_CHANGED_PIXELS}" ]]; then
        echo "FAIL: ${actual}"
        echo "      changed_pixels=${changed}, allowed=${MAX_CHANGED_PIXELS}, fuzz=${FUZZ}"
        return 1
    fi

    echo "PASS: ${actual} changed_pixels=${changed}"
}

shopt -s nullglob globstar
case_files=("${CASE_ROOT}"/**/*.scad)

if [[ "${#case_files[@]}" -eq 0 ]]; then
    echo "No regression case files found under ${CASE_ROOT}" >&2
    exit 1
fi

failures=0

for case_file in "${case_files[@]}"; do
    while read -r idx name; do
        [[ -n "${idx}" ]] || continue

        if [[ "${MODE}" == "generate" ]]; then
            render_case_test "${case_file}" "${idx}" "${name}" "${BASELINE_ROOT}"
            continue
        fi

        render_case_test "${case_file}" "${idx}" "${name}" "${ACTUAL_ROOT}"

        rel="$(case_rel_path "${case_file}")"
        base="${rel%.scad}"
        dir="$(dirname "${base}")"
        stem="$(basename "${base}")"
        file="${dir}/${stem}_$(printf '%02d' "${idx}")_${name}.png"
        expected="${BASELINE_ROOT}/${file}"
        actual="${ACTUAL_ROOT}/${file}"
        diff="${DIFF_ROOT}/${file}"
        metric_log="${LOG_ROOT}/${file}.compare.log"

        if [[ ! -f "${expected}" ]]; then
            echo "FAIL: missing baseline ${expected}"
            failures=$((failures + 1))
            continue
        fi

        if ! compare_images "${expected}" "${actual}" "${diff}" "${metric_log}"; then
            failures=$((failures + 1))
        fi
    done < <(list_case_tests "${case_file}")
done

if [[ "${failures}" -ne 0 ]]; then
    echo "Regression image failures: ${failures}"
    echo "Actual images: ${ACTUAL_ROOT}"
    echo "Diff images: ${DIFF_ROOT}"
    exit 1
fi

echo "Regression ${MODE} completed successfully."
