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
REGRESSION_JOBS="${REGRESSION_JOBS:-4}"
PARALLEL_BIN="${PARALLEL_BIN:-parallel}"
MODE="${1:-}"
TOLERANCE="normal"

usage() {
    cat <<EOF
Usage: $0 generate|diff [--tolerance strict|normal|loose]

Environment:
  OPENSCAD_BIN  OpenSCAD command to use (default: openscad-nightly)
  IMG_SIZE      Output image size, WIDTH,HEIGHT (default: 1280,960)
  REGRESSION_JOBS
                Parallel render/compare jobs to run when GNU parallel is
                available (default: 4)
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
        MAX_CHANGED_PPM=0
        MAX_CHANGED_FLOOR=0
        ;;
    normal)
        FUZZ="1%"
        MAX_CHANGED_PPM=100
        MAX_CHANGED_FLOOR=100
        ;;
    loose)
        FUZZ="2.5%"
        MAX_CHANGED_PPM=500
        MAX_CHANGED_FLOOR=500
        ;;
    *)
        echo "Unknown tolerance: ${TOLERANCE}" >&2
        usage
        exit 2
        ;;
esac

IFS=, read -r IMG_WIDTH IMG_HEIGHT IMG_EXTRA <<<"${IMG_SIZE}"
if [[ -n "${IMG_EXTRA:-}" || ! "${IMG_WIDTH}" =~ ^[1-9][0-9]*$ || ! "${IMG_HEIGHT}" =~ ^[1-9][0-9]*$ ]]; then
    echo "Invalid IMG_SIZE: ${IMG_SIZE}. Expected WIDTH,HEIGHT." >&2
    exit 2
fi

if [[ ! "${REGRESSION_JOBS}" =~ ^[1-9][0-9]*$ ]]; then
    echo "Invalid REGRESSION_JOBS: ${REGRESSION_JOBS}. Expected a positive integer." >&2
    exit 2
fi

if [[ "${TOLERANCE}" != "strict" ]]; then
    IMG_PIXELS=$((IMG_WIDTH * IMG_HEIGHT))
    MAX_CHANGED_PIXELS=$(((IMG_PIXELS * MAX_CHANGED_PPM + 999999) / 1000000))
    if [[ "${MAX_CHANGED_PIXELS}" -lt "${MAX_CHANGED_FLOOR}" ]]; then
        MAX_CHANGED_PIXELS="${MAX_CHANGED_FLOOR}"
    fi
fi

if ! command -v "${OPENSCAD_BIN}" >/dev/null 2>&1; then
    echo "OpenSCAD command not found: ${OPENSCAD_BIN}" >&2
    exit 1
fi

COMPARE_BIN=""
COMPARE_STYLE=""
if command -v magick >/dev/null 2>&1; then
    COMPARE_BIN="$(command -v magick)"
    COMPARE_STYLE="magick"
elif command -v compare >/dev/null 2>&1; then
    COMPARE_BIN="$(command -v compare)"
    COMPARE_STYLE="compare"
else
    COMPARE_BIN=""
fi

if [[ "${MODE}" == "diff" && -z "${COMPARE_BIN}" ]]; then
    echo "ImageMagick compare command not found. Install imagemagick." >&2
    exit 1
fi

mkdir -p "${ACTUAL_ROOT}" "${DIFF_ROOT}" "${LOG_ROOT}" "${BASELINE_ROOT}"

case_rel_path() {
    local case_file="$1"
    realpath --relative-to="${CASE_ROOT}" "${case_file}"
}

has_gnu_parallel() {
    local parallel_bin="$1"

    command -v "${parallel_bin}" >/dev/null 2>&1 &&
        "${parallel_bin}" --version 2>/dev/null | head -n 1 | rg -q '^GNU parallel '
}

list_case_tests() {
    local case_file="$1"
    local rel base log out

    rel="$(case_rel_path "${case_file}")"
    base="${rel%.scad}"
    log="${LOG_ROOT}/${base}.list.log"
    out="${TMP_ROOT}/list/${base}.stl"
    mkdir -p "$(dirname "${log}")" "$(dirname "${out}")"

    if ! "${OPENSCAD_BIN}" \
        -o "${out}" \
        -D REG_LIST=true \
        -D T=0 \
        "${case_file}" >"${log}" 2>&1; then
        echo "FAIL: could not list regression tests for ${rel}" >&2
        sed 's/^/      /' "${log}" >&2
        return 1
    fi

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
    if ! "${OPENSCAD_BIN}" \
        -o "${out}" \
        --imgsize="${IMG_SIZE}" \
        --projection=o \
        --autocenter \
        --viewall \
        --render \
        -D "T=${idx}" \
        "${case_file}" >"${log}" 2>&1; then
        echo "FAIL: render failed for ${rel} T=${idx} (${name})"
        sed 's/^/      /' "${log}"
        return 1
    fi
}

compare_images() {
    local expected="$1"
    local actual="$2"
    local diff="$3"
    local metric_log="$4"
    local changed rc

    mkdir -p "$(dirname "${diff}")" "$(dirname "${metric_log}")"

    set +e
    if [[ "${COMPARE_STYLE}" == "magick" ]]; then
        "${COMPARE_BIN}" compare \
            -metric AE \
            -fuzz "${FUZZ}" \
            -highlight-color red \
            -lowlight-color white \
            "${expected}" \
            "${actual}" \
            "${diff}" >"${metric_log}" 2>&1
    else
        "${COMPARE_BIN}" \
            -metric AE \
            -fuzz "${FUZZ}" \
            -highlight-color red \
            -lowlight-color white \
            "${expected}" \
            "${actual}" \
            "${diff}" >"${metric_log}" 2>&1
    fi
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

run_regression_test() {
    local case_file="$1"
    local idx="$2"
    local name="$3"
    local rel base dir stem file expected actual diff metric_log

    if [[ "${MODE}" == "generate" ]]; then
        render_case_test "${case_file}" "${idx}" "${name}" "${BASELINE_ROOT}"
        return
    fi

    render_case_test "${case_file}" "${idx}" "${name}" "${ACTUAL_ROOT}" || return 1

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
        return 1
    fi

    compare_images "${expected}" "${actual}" "${diff}" "${metric_log}"
}

shopt -s nullglob globstar
case_files=("${CASE_ROOT}"/**/*.scad)

if [[ "${#case_files[@]}" -eq 0 ]]; then
    echo "No regression case files found under ${CASE_ROOT}" >&2
    exit 1
fi

failures=0
jobs_file="${TMP_ROOT}/list/jobs.tsv"
mkdir -p "$(dirname "${jobs_file}")"
: >"${jobs_file}"

for case_file in "${case_files[@]}"; do
    rel="$(case_rel_path "${case_file}")"
    base="${rel%.scad}"
    tests_file="${TMP_ROOT}/list/${base}.tests"
    mkdir -p "$(dirname "${tests_file}")"

    if ! list_case_tests "${case_file}" >"${tests_file}"; then
        failures=$((failures + 1))
        continue
    fi

    if [[ ! -s "${tests_file}" ]]; then
        echo "FAIL: no regression tests discovered for ${rel}"
        failures=$((failures + 1))
        continue
    fi

    while read -r idx name; do
        [[ -n "${idx}" ]] || continue
        printf '%s\t%s\t%s\n' "${case_file}" "${idx}" "${name}" >>"${jobs_file}"
    done <"${tests_file}"
done

if [[ "${failures}" -eq 0 ]]; then
    if [[ ! -s "${jobs_file}" ]]; then
        echo "No regression tests discovered." >&2
        exit 1
    fi

    use_parallel=false
    if [[ "${REGRESSION_JOBS}" -gt 1 ]] && has_gnu_parallel "${PARALLEL_BIN}"; then
        use_parallel=true
    fi

    if [[ "${use_parallel}" == true ]]; then
        parallel_log="${LOG_ROOT}/parallel-${MODE}.joblog"
        rm -f "${parallel_log}"
        export CASE_ROOT BASELINE_ROOT ACTUAL_ROOT DIFF_ROOT LOG_ROOT OPENSCAD_BIN IMG_SIZE
        export MODE FUZZ MAX_CHANGED_PIXELS COMPARE_BIN COMPARE_STYLE
        export -f case_rel_path render_case_test compare_images run_regression_test

        echo "Running regression ${MODE} jobs with ${PARALLEL_BIN} -j ${REGRESSION_JOBS}"
        set +e
        "${PARALLEL_BIN}" \
            --will-cite \
            --jobs "${REGRESSION_JOBS}" \
            --colsep '\t' \
            --line-buffer \
            --tagstring '{2}:{3}' \
            --joblog "${parallel_log}" \
            run_regression_test {1} {2} {3} :::: "${jobs_file}"
        parallel_rc=$?
        set -e

        if [[ "${parallel_rc}" -ne 0 ]]; then
            failures="$(awk 'NR > 1 && $7 != 0 { n++ } END { print n + 0 }' "${parallel_log}")"
        fi
    else
        if [[ "${REGRESSION_JOBS}" -gt 1 ]]; then
            echo "GNU parallel not available; running regression ${MODE} jobs serially."
        fi

        while IFS=$'\t' read -r case_file idx name; do
            if ! run_regression_test "${case_file}" "${idx}" "${name}"; then
                failures=$((failures + 1))
            fi
        done <"${jobs_file}"
    fi
fi

if [[ "${failures}" -ne 0 ]]; then
    echo "Regression image failures: ${failures}"
    echo "Actual images: ${ACTUAL_ROOT}"
    echo "Diff images: ${DIFF_ROOT}"
    exit 1
fi

echo "Regression ${MODE} completed successfully."
