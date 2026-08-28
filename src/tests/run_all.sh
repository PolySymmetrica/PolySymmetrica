#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_FILE="${ROOT_DIR}/run_all.scad"
TARGET_ROOT="${UNIT_TEST_TARGET:-${ROOT_DIR}/../../target/unit-tests}"
LOG_ROOT="${TARGET_ROOT}/logs"
STATUS_ROOT="${LOG_ROOT}/status"
JOBS_FILE="${TARGET_ROOT}/suites.tsv"
LIST_OUTPUT="${TARGET_ROOT}/suite-list.stl"
LIST_LOG="${LOG_ROOT}/suite-list.log"
OPENSCAD_BIN="${OPENSCAD_BIN:-openscad-nightly}"
UNIT_TEST_JOBS="${UNIT_TEST_JOBS:-4}"
PARALLEL_BIN="${PARALLEL_BIN:-parallel}"
UNIT_TEST_COLOR="${UNIT_TEST_COLOR:-auto}"

usage() {
    cat <<EOF
Usage: $0

Environment:
  OPENSCAD_BIN     OpenSCAD command to use (default: openscad-nightly)
  UNIT_TEST_JOBS   Parallel suite processes (default: 4)
  UNIT_TEST_TARGET Output directory (default: target/unit-tests)
  UNIT_TEST_COLOR  Status colors: auto, always, or never (default: auto)
  PARALLEL_BIN     GNU parallel command (default: parallel)
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
fi

if [[ $# -ne 0 ]]; then
    echo "Unexpected argument: $1" >&2
    usage >&2
    exit 2
fi

case "${UNIT_TEST_COLOR}" in
    auto|always|never) ;;
    *)
        echo "Invalid UNIT_TEST_COLOR: ${UNIT_TEST_COLOR}. Expected auto, always, or never." >&2
        exit 2
        ;;
esac

if [[ ! "${UNIT_TEST_JOBS}" =~ ^[1-9][0-9]*$ ]]; then
    echo "Invalid UNIT_TEST_JOBS: ${UNIT_TEST_JOBS}. Expected a positive integer." >&2
    exit 2
fi

if ! command -v "${OPENSCAD_BIN}" >/dev/null 2>&1; then
    echo "OpenSCAD command not found: ${OPENSCAD_BIN}" >&2
    exit 1
fi

use_color=false
if [[ "${UNIT_TEST_COLOR}" == "always" || ( "${UNIT_TEST_COLOR}" == "auto" && -t 1 ) ]]; then
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

has_gnu_parallel() {
    command -v "${PARALLEL_BIN}" >/dev/null 2>&1 &&
        "${PARALLEL_BIN}" --version 2>/dev/null | head -n 1 | rg -q '^GNU parallel '
}

run_unit_suite() {
    local suite_idx="$1"
    local suite_name="$2"
    local output_file="${TARGET_ROOT}/suite_$(printf '%02d' "${suite_idx}")_${suite_name}.stl"
    local log_file="${LOG_ROOT}/suite_$(printf '%02d' "${suite_idx}")_${suite_name}.log"
    local status_file="${STATUS_ROOT}/suite_$(printf '%02d' "${suite_idx}")_${suite_name}.status"
    local rc open_scad_rc

    mkdir -p "${TARGET_ROOT}" "${LOG_ROOT}" "${STATUS_ROOT}"
    echo "${suite_idx} ${suite_name}: running"

    if "${OPENSCAD_BIN}" \
        -o "${output_file}" \
        -D "T=${suite_idx}" \
        "${TEST_FILE}" >"${log_file}" 2>&1; then
        open_scad_rc=0
    else
        open_scad_rc=$?
    fi

    if [[ "${open_scad_rc}" -eq 0 ]]; then
        if rg -q '(^|[[:space:]])ERROR:' "${log_file}"; then
            rc=1
        else
            printf 'PASS\n' >"${status_file}"
            echo "${suite_idx} ${suite_name}: $(pass_label)"
            return 0
        fi
    else
        rc="${open_scad_rc}"
    fi

    printf 'FAIL\n' >"${status_file}"
    echo "${suite_idx} ${suite_name}: $(fail_label) (see ${log_file})"
    sed 's/^/    /' "${log_file}"
    return "${rc:-1}"
}

mkdir -p "${TARGET_ROOT}" "${LOG_ROOT}" "${STATUS_ROOT}"
rm -f "${JOBS_FILE}" "${STATUS_ROOT}"/*.status

# Discover suites in one serial OpenSCAD process.  Apart from avoiding a second
# source of truth for suite names, this warms shared Snap/desktop state before
# any suite processes are started concurrently.
echo "Discovering unit-test suites"
if ! "${OPENSCAD_BIN}" \
    -o "${LIST_OUTPUT}" \
    -D "T=-2" \
    "${TEST_FILE}" >"${LIST_LOG}" 2>&1; then
    echo "Unable to list unit-test suites; see ${LIST_LOG}" >&2
    sed 's/^/    /' "${LIST_LOG}" >&2
    exit 1
fi
if rg -q '(^|[[:space:]])ERROR:' "${LIST_LOG}"; then
    echo "OpenSCAD reported errors while listing unit-test suites; see ${LIST_LOG}" >&2
    sed 's/^/    /' "${LIST_LOG}" >&2
    exit 1
fi

sed -n \
    's/.*ECHO: "UNIT_TEST_SUITE \([0-9][0-9]*\) \([^"[:space:]]*\)".*/\1\t\2/p' \
    "${LIST_LOG}" >"${JOBS_FILE}"
if [[ ! -s "${JOBS_FILE}" ]]; then
    echo "OpenSCAD listed no unit-test suites; see ${LIST_LOG}" >&2
    sed 's/^/    /' "${LIST_LOG}" >&2
    exit 1
fi

SUITE_INDICES=()
SUITE_NAMES=()
while IFS=$'\t' read -r suite_idx suite_name; do
    if [[ -n "${suite_idx}" && -n "${suite_name}" ]]; then
        SUITE_INDICES+=("${suite_idx}")
        SUITE_NAMES+=("${suite_name}")
    fi
done <"${JOBS_FILE}"

use_parallel=false
if [[ "${UNIT_TEST_JOBS}" -gt 1 ]] && has_gnu_parallel "${PARALLEL_BIN}"; then
    use_parallel=true
fi

export ROOT_DIR TEST_FILE TARGET_ROOT LOG_ROOT STATUS_ROOT OPENSCAD_BIN
export use_color
export -f color_label pass_label fail_label run_unit_suite

failures=0

if [[ "${use_parallel}" == true ]]; then
    parallel_log="${LOG_ROOT}/parallel.joblog"
    rm -f "${parallel_log}"
    echo "Running unit-test suites with ${PARALLEL_BIN} -j ${UNIT_TEST_JOBS}"
    set +e
    "${PARALLEL_BIN}" \
        --will-cite \
        --jobs "${UNIT_TEST_JOBS}" \
        --colsep '\t' \
        --line-buffer \
        --tagstring '{2}' \
        --joblog "${parallel_log}" \
        run_unit_suite {1} {2} :::: "${JOBS_FILE}"
    parallel_rc=$?
    set -e
    if [[ "${parallel_rc}" -ne 0 ]]; then
        failures=1
    fi
else
    if [[ "${UNIT_TEST_JOBS}" -gt 1 ]]; then
        echo "GNU parallel not available; running unit-test suites serially."
    fi
    while IFS=$'\t' read -r suite_idx suite_name; do
        if ! run_unit_suite "${suite_idx}" "${suite_name}"; then
            failures=1
        fi
    done <"${JOBS_FILE}"
fi

echo
echo "Unit-test suite summary:"
for suite_pos in "${!SUITE_INDICES[@]}"; do
    suite_idx="${SUITE_INDICES[${suite_pos}]}"
    suite_name="${SUITE_NAMES[${suite_pos}]}"
    status_file="${STATUS_ROOT}/suite_$(printf '%02d' "${suite_idx}")_${suite_name}.status"
    status="ERROR"
    if [[ -f "${status_file}" ]]; then
        status="$(<"${status_file}")"
    fi
    if [[ "${status}" == "PASS" ]]; then
        echo "  ${suite_idx} ${suite_name}: $(pass_label)"
    else
        echo "  ${suite_idx} ${suite_name}: $(fail_label)"
        failures=1
    fi
done

if [[ "${failures}" -ne 0 ]]; then
    echo "Unit tests failed. Logs: ${LOG_ROOT}" >&2
    exit 1
fi

echo "All unit-test suites passed."
