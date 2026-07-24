#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
CASE_ROOT="${SCRIPT_DIR}/cases"
TARGET_REG_ROOT="${REPO_ROOT}/target/regression-tests"
BASELINE_ROOT="${BASELINE_ROOT:-${SCRIPT_DIR}/baselines/openscad}"
ACTUAL_ROOT="${ACTUAL_ROOT:-${TARGET_REG_ROOT}/actual}"
DIFF_ROOT="${DIFF_ROOT:-${TARGET_REG_ROOT}/diff}"
LOG_ROOT="${TARGET_REG_ROOT}/logs"
RESULT_ROOT="${LOG_ROOT}/status"
OPENSCAD_BIN="${OPENSCAD_BIN:-openscad-nightly}"
BASELINE_VERSION_FILE="${BASELINE_ROOT}/version.properties"
CURRENT_VERSION_FILE="${TARGET_REG_ROOT}/version.properties"
IMG_SIZE="${IMG_SIZE:-1280,960}"
REGRESSION_JOBS="${REGRESSION_JOBS:-4}"
PARALLEL_BIN="${PARALLEL_BIN:-parallel}"
REGRESSION_COLOR="${REGRESSION_COLOR:-auto}"
MODE="${1:-}"
TOLERANCE="normal"

case "${REGRESSION_COLOR}" in
    auto|always|never) ;;
    *)
        echo "Invalid REGRESSION_COLOR: ${REGRESSION_COLOR}. Expected auto, always, or never." >&2
        exit 2
        ;;
esac

use_color=false
if [[ "${REGRESSION_COLOR}" == "always" || ( "${REGRESSION_COLOR}" == "auto" && -t 1 ) ]]; then
    use_color=true
fi

color_label() {
    local code="$1"
    local label="$2"

    if [[ "${use_color}" == true ]]; then
        printf '\033[%sm%s\033[0m' "${code}" "${label}"
    else
        printf '%s' "${label}"
    fi
}

pass_label() {
    color_label "32" "PASS"
}

fail_label() {
    color_label "91" "FAIL"
}

error_label() {
    color_label "91" "ERROR"
}

usage() {
    cat <<EOF
Usage: $0 generate|diff [--tolerance strict|normal|loose]

Environment:
  OPENSCAD_BIN  OpenSCAD command to use (default: openscad-nightly)
  IMG_SIZE      Output image size, WIDTH,HEIGHT (default: 1280,960)
  REGRESSION_JOBS
                Parallel render/compare jobs to run when GNU parallel is
                available (default: 4)
  REGRESSION_COLOR
                Color labels: auto, always, or never (default: auto)
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
rm -rf "${RESULT_ROOT}"
mkdir -p "${RESULT_ROOT}"

case_rel_path() {
    local case_file="$1"
    realpath --relative-to="${CASE_ROOT}" "${case_file}"
}

result_status_file() {
    local case_file="$1"
    local idx="$2"
    local name="$3"
    local rel base dir stem suffix

    rel="$(case_rel_path "${case_file}")"
    base="${rel%.scad}"
    dir="$(dirname "${base}")"
    stem="$(basename "${base}")"
    if [[ "${idx}" == "LIST" ]]; then
        suffix="list"
    else
        suffix="$(printf '%02d' "${idx}")_${name}"
    fi

    printf '%s/%s/%s_%s.status\n' "${RESULT_ROOT}" "${dir}" "${stem}" "${suffix}"
}

record_regression_result() {
    local kind="$1"
    local case_file="$2"
    local idx="$3"
    local name="$4"
    local detail="$5"
    local rel status_file

    rel="$(case_rel_path "${case_file}")"
    status_file="$(result_status_file "${case_file}" "${idx}" "${name}")"
    mkdir -p "$(dirname "${status_file}")"
    printf '%s\t%s\t%s\t%s\t%s\n' "${kind}" "${rel}" "${idx}" "${name}" "${detail}" >"${status_file}"
}

result_count() {
    local kind="$1"
    local count status_files

    status_files="$(find "${RESULT_ROOT}" -type f -name '*.status' -print)"
    if [[ -z "${status_files}" ]]; then
        echo 0
        return
    fi

    count="$(
        printf '%s\n' "${status_files}" |
            xargs awk -F '\t' -v kind="${kind}" '$1 == kind { n++ } END { print n + 0 }'
    )"
    printf '%s\n' "${count:-0}"
}

print_result_group() {
    local kind="$1"
    local title="$2"

    if [[ "$(result_count "${kind}")" -eq 0 ]]; then
        return
    fi

    echo "${title}:"
    find "${RESULT_ROOT}" -type f -name '*.status' -print0 |
        xargs -0r awk -F '\t' -v kind="${kind}" '
            $1 == kind {
                label = ($3 == "LIST") ? ($2 " discovery") : ($2 " T=" $3 " (" $4 ")")
                print "  - " label ": " $5
            }
        ' |
        sort
}

print_regression_result_summary() {
    local fail_count error_count

    fail_count="$(result_count "FAIL")"
    error_count="$(result_count "ERROR")"

    echo "Regression image diffs: ${fail_count}"
    echo "Regression execution errors: ${error_count}"
    print_result_group "FAIL" "Image diffs"
    print_result_group "ERROR" "Execution errors"
}

aggregate_status() {
    local fail_count="$1"
    local error_count="$2"

    if [[ "${error_count}" -gt 0 ]]; then
        echo "ERROR"
    elif [[ "${fail_count}" -gt 0 ]]; then
        echo "FAIL"
    else
        echo "PASS"
    fi
}

status_label() {
    local status="$1"

    case "${status}" in
        PASS) pass_label ;;
        FAIL) fail_label ;;
        ERROR) error_label ;;
        *) printf '%s' "${status}" ;;
    esac
}

print_status_banner() {
    local status="$1"

    echo
    echo "======================================================================"
    echo "STATUS: $(status_label "${status}")"
    echo "======================================================================"
}

openscad_log_has_error() {
    local log="$1"

    rg -q '(^|[[:space:]])ERROR:' "${log}"
}

has_gnu_parallel() {
    local parallel_bin="$1"

    command -v "${parallel_bin}" >/dev/null 2>&1 &&
        "${parallel_bin}" --version 2>/dev/null | head -n 1 | rg -q '^GNU parallel '
}

openscad_version_line() {
    local version rc first_line

    set +e
    version="$("${OPENSCAD_BIN}" --version 2>&1)"
    rc=$?
    set -e

    if [[ "${rc}" -ne 0 ]]; then
        printf 'UNKNOWN: %s --version failed with exit code %s\n' "${OPENSCAD_BIN}" "${rc}"
        return
    fi

    first_line="$(printf '%s\n' "${version}" | sed '/^[[:space:]]*$/d' | head -n 1)"
    printf '%s\n' "${first_line:-UNKNOWN: empty version output}"
}

write_version_properties() {
    local file="$1"
    local openscad_path openscad_version

    openscad_path="$(command -v "${OPENSCAD_BIN}" 2>/dev/null || true)"
    openscad_version="$(openscad_version_line)"

    mkdir -p "$(dirname "${file}")"
    {
        printf 'openscad.bin=%s\n' "${OPENSCAD_BIN}"
        printf 'openscad.path=%s\n' "${openscad_path}"
        printf 'openscad.version=%s\n' "${openscad_version}"
    } >"${file}"
}

property_value() {
    local file="$1"
    local key="$2"

    [[ -f "${file}" ]] || return 0
    awk -F= -v key="${key}" '
        $1 == key {
            sub(/^[^=]*=/, "")
            value = $0
        }
        END {
            if (value != "")
                print value
        }
    ' "${file}"
}

print_version_drift_notice() {
    local baseline_version current_version baseline_path current_path

    baseline_version="$(property_value "${BASELINE_VERSION_FILE}" openscad.version)"
    current_version="$(property_value "${CURRENT_VERSION_FILE}" openscad.version)"
    baseline_path="$(property_value "${BASELINE_VERSION_FILE}" openscad.path)"
    current_path="$(property_value "${CURRENT_VERSION_FILE}" openscad.path)"

    echo
    echo "======================================================================"
    echo "OPENSCAD VERSION CHECK FOR VISUAL REGRESSION FAILURE"
    echo "Baseline marker: ${BASELINE_VERSION_FILE}"
    echo "Current marker:  ${CURRENT_VERSION_FILE}"
    echo
    echo "Baseline OpenSCAD: ${baseline_version:-UNKNOWN: no baseline version marker}"
    echo "Current OpenSCAD:  ${current_version:-UNKNOWN: no current version marker}"

    if [[ -n "${baseline_path}" || -n "${current_path}" ]]; then
        echo "Baseline path:     ${baseline_path:-UNKNOWN}"
        echo "Current path:      ${current_path:-UNKNOWN}"
    fi

    if [[ -n "${baseline_version}" && -n "${current_version}" && "${baseline_version}" != "${current_version}" ]]; then
        echo
        echo "WARNING: OpenSCAD version drift detected."
        echo "Check renderer drift before debugging geometry or updating baselines."
    else
        echo
        echo "No OpenSCAD version drift was detected from the recorded markers."
    fi

    echo "======================================================================"
    echo
}

write_version_properties "${CURRENT_VERSION_FILE}"
if [[ "${MODE}" == "generate" ]]; then
    cp "${CURRENT_VERSION_FILE}" "${BASELINE_VERSION_FILE}"
fi

list_case_tests() {
    local case_file="$1"
    local rel base log out render_args render_args_file

    rel="$(case_rel_path "${case_file}")"
    base="${rel%.scad}"
    log="${LOG_ROOT}/${base}.list.log"
    out="${TARGET_REG_ROOT}/list/${base}.stl"
    render_args_file="${TARGET_REG_ROOT}/list/${base}.render_args"
    mkdir -p "$(dirname "${log}")" "$(dirname "${out}")" "$(dirname "${render_args_file}")"

    if ! "${OPENSCAD_BIN}" \
        -o "${out}" \
        -D REG_LIST=true \
        -D T=0 \
        "${case_file}" >"${log}" 2>&1; then
        echo "$(error_label): could not list regression tests for ${rel}" >&2
        sed 's/^/      /' "${log}" >&2
        record_regression_result "ERROR" "${case_file}" "LIST" "list" "could not list tests; see ${log}"
        return 1
    fi

    if openscad_log_has_error "${log}"; then
        echo "$(error_label): OpenSCAD reported errors while listing regression tests for ${rel}" >&2
        sed 's/^/      /' "${log}" >&2
        record_regression_result "ERROR" "${case_file}" "LIST" "list" "OpenSCAD reported errors while listing tests; see ${log}"
        return 1
    fi

    render_args="$(sed -n 's/.*REGRESSION_RENDER_ARGS=\([^"]*\).*/\1/p' "${log}" | tail -n 1)"
    render_args="${render_args:---projection=o --autocenter --viewall --render}"
    printf '%s\n' "${render_args}" >"${render_args_file}"

    sed -n 's/.*REGRESSION_TEST=\([0-9][0-9]*\) \([^"]*\).*/\1 \2/p' "${log}"
}

render_case_test() {
    local case_file="$1"
    local idx="$2"
    local name="$3"
    local root="$4"
    local rel base dir stem out log render_args_file render_args
    local -a render_args_arr

    rel="$(case_rel_path "${case_file}")"
    base="${rel%.scad}"
    dir="$(dirname "${base}")"
    stem="$(basename "${base}")"
    out="${root}/${dir}/${stem}_$(printf '%02d' "${idx}")_${name}.png"
    log="${LOG_ROOT}/${dir}/${stem}_$(printf '%02d' "${idx}")_${name}.render.log"
    render_args_file="${TARGET_REG_ROOT}/list/${base}.render_args"
    render_args="--projection=o --autocenter --viewall --render"
    if [[ -f "${render_args_file}" ]]; then
        render_args="$(<"${render_args_file}")"
    fi
    read -r -a render_args_arr <<<"${render_args}"
    mkdir -p "$(dirname "${out}")" "$(dirname "${log}")"

    echo "Rendering ${rel} T=${idx} (${name}) -> ${out}"
    if ! "${OPENSCAD_BIN}" \
        -o "${out}" \
        --imgsize="${IMG_SIZE}" \
        "${render_args_arr[@]}" \
        -D "T=${idx}" \
        "${case_file}" >"${log}" 2>&1; then
        echo "$(error_label): render failed for ${rel} T=${idx} (${name})"
        sed 's/^/      /' "${log}"
        return 1
    fi

    if openscad_log_has_error "${log}"; then
        echo "$(error_label): OpenSCAD reported errors for ${rel} T=${idx} (${name})"
        sed 's/^/      /' "${log}"
        return 1
    fi
}

compare_images() {
    local expected="$1"
    local actual="$2"
    local diff="$3"
    local metric_log="$4"
    local case_file="$5"
    local idx="$6"
    local name="$7"
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
        echo "$(error_label): ImageMagick compare failed for ${actual}"
        sed 's/^/      /' "${metric_log}"
        record_regression_result "ERROR" "${case_file}" "${idx}" "${name}" "image compare failed; see ${metric_log}"
        return 1
    fi

    if [[ "${changed}" -gt "${MAX_CHANGED_PIXELS}" ]]; then
        echo "$(fail_label): ${actual}"
        echo "      changed_pixels=${changed}, allowed=${MAX_CHANGED_PIXELS}, fuzz=${FUZZ}"
        record_regression_result "FAIL" "${case_file}" "${idx}" "${name}" "image differs; actual=${actual}; diff=${diff}"
        return 1
    fi

    echo "$(pass_label): ${actual} changed_pixels=${changed}"
}

run_regression_test() {
    local case_file="$1"
    local idx="$2"
    local name="$3"
    local rel base dir stem file expected actual diff metric_log

    rel="$(case_rel_path "${case_file}")"
    base="${rel%.scad}"
    dir="$(dirname "${base}")"
    stem="$(basename "${base}")"

    if [[ "${MODE}" == "generate" ]]; then
        if ! render_case_test "${case_file}" "${idx}" "${name}" "${BASELINE_ROOT}"; then
            record_regression_result "ERROR" "${case_file}" "${idx}" "${name}" "render failed while generating baseline"
            return 1
        fi
        return
    fi

    if ! render_case_test "${case_file}" "${idx}" "${name}" "${ACTUAL_ROOT}"; then
        record_regression_result "ERROR" "${case_file}" "${idx}" "${name}" "render failed; see ${LOG_ROOT}/${dir}/${stem}_$(printf '%02d' "${idx}")_${name}.render.log"
        return 1
    fi

    file="${dir}/${stem}_$(printf '%02d' "${idx}")_${name}.png"
    expected="${BASELINE_ROOT}/${file}"
    actual="${ACTUAL_ROOT}/${file}"
    diff="${DIFF_ROOT}/${file}"
    metric_log="${LOG_ROOT}/${file}.compare.log"

    if [[ ! -f "${expected}" ]]; then
        echo "$(error_label): missing baseline ${expected}"
        record_regression_result "ERROR" "${case_file}" "${idx}" "${name}" "missing baseline ${expected}"
        return 1
    fi

    compare_images "${expected}" "${actual}" "${diff}" "${metric_log}" "${case_file}" "${idx}" "${name}"
}

shopt -s nullglob globstar
case_files=("${CASE_ROOT}"/**/*.scad)

if [[ "${#case_files[@]}" -eq 0 ]]; then
    echo "No regression case files found under ${CASE_ROOT}" >&2
    exit 1
fi

failures=0
jobs_file="${TARGET_REG_ROOT}/list/jobs.tsv"
mkdir -p "$(dirname "${jobs_file}")"
: >"${jobs_file}"

for case_file in "${case_files[@]}"; do
    rel="$(case_rel_path "${case_file}")"
    base="${rel%.scad}"
    tests_file="${TARGET_REG_ROOT}/list/${base}.tests"
    mkdir -p "$(dirname "${tests_file}")"

    if ! list_case_tests "${case_file}" >"${tests_file}"; then
        failures=$((failures + 1))
        continue
    fi

    if [[ ! -s "${tests_file}" ]]; then
        echo "$(error_label): no regression tests discovered for ${rel}"
        record_regression_result "ERROR" "${case_file}" "LIST" "list" "no regression tests discovered"
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
        export CASE_ROOT TARGET_REG_ROOT BASELINE_ROOT ACTUAL_ROOT DIFF_ROOT LOG_ROOT RESULT_ROOT OPENSCAD_BIN IMG_SIZE
        export MODE FUZZ MAX_CHANGED_PIXELS COMPARE_BIN COMPARE_STYLE use_color
        export -f color_label pass_label fail_label error_label openscad_log_has_error
        export -f case_rel_path result_status_file record_regression_result render_case_test compare_images run_regression_test

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

image_failures="$(result_count "FAIL")"
execution_errors="$(result_count "ERROR")"
total_failures=$((image_failures + execution_errors))
status="$(aggregate_status "${image_failures}" "${execution_errors}")"
if [[ "${total_failures}" -eq 0 && "${failures}" -ne 0 ]]; then
    status="ERROR"
fi

print_status_banner "${status}"

if [[ "${total_failures}" -ne 0 ]]; then
    print_regression_result_summary
    echo "Actual images: ${ACTUAL_ROOT}"
    echo "Diff images: ${DIFF_ROOT}"
    print_version_drift_notice
    exit 1
fi

if [[ "${failures}" -ne 0 ]]; then
    echo "Regression script errors: ${failures}"
    echo "No per-test status records were written; inspect ${LOG_ROOT}."
    exit 1
fi

echo "Regression ${MODE} completed successfully."
