/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

use <core/TestFuncs.scad>
use <core/TestVertex.scad>
use <core/TestDuals.scad>
use <core/TestCantellation.scad>
use <core/TestTruncation.scad>
use <core/TestCleanup.scad>
use <core/TestValidity.scad>
use <core/TestClassify.scad>
use <core/TestPlacement.scad>
use <core/TestEdgeRegions.scad>
use <core/TestFaceRegions.scad>
use <core/TestSelfCrossing.scad>
use <core/TestPrisms.scad>
use <core/TestAttach.scad>
use <core/TestRender.scad>
use <core/TestConstruction.scad>

T = -1;

// OpenSCAD cannot invoke modules stored in values, so keep stable indices and names.
TEST_SUITES = [
    [0, "TestFuncs"],
    [1, "TestVertex"],
    [2, "TestDuals"],
    [3, "TestCantellation"],
    [4, "TestTruncation"],
    [5, "TestCleanup"],
    [6, "TestValidity"],
    [7, "TestClassify"],
    [8, "TestPlacement"],
    [9, "TestEdgeRegions"],
    [10, "TestFaceRegions"],
    [11, "TestSelfCrossing"],
    [12, "TestPrisms"],
    [13, "TestAttach"],
    [14, "TestRender"],
    [15, "TestConstruction"]
];

function _ps_test_selector_values(t) = is_num(t) ? [t] : [for (v = t) v];
function _ps_test_selector_is_all(t) = is_num(t) && t == -1;
function _ps_test_selector_is_list(t) = is_num(t) && t == -2;
function _ps_test_selector_value_ok(t) =
    t >= 0 && t < len(TEST_SUITES) && t == floor(t);
function _ps_test_selector_ok(t) =
    _ps_test_selector_is_all(t) || _ps_test_selector_is_list(t)
    || (
        len(_ps_test_selector_values(t)) > 0
        && len([
            for (v = _ps_test_selector_values(t))
                if (_ps_test_selector_value_ok(v)) v
        ]) == len(_ps_test_selector_values(t))
    );
echo("=== PolySymmetrica tests: START ===");

module _ps_list_test_suites() {
    for (suite = TEST_SUITES)
        echo(str("UNIT_TEST_SUITE ", suite[0], " ", suite[1]));
}

module _ps_run_test_suite(suite_idx, suite_name) {
    echo(str("=== PolySymmetrica tests: suite ", suite_idx, " ", suite_name, " START ==="));
    if (suite_idx == 0) {
        run_TestFuncs();
    } else if (suite_idx == 1) {
        run_TestVertex();
    } else if (suite_idx == 2) {
        run_TestDuals();
    } else if (suite_idx == 3) {
        run_TestCantellation();
    } else if (suite_idx == 4) {
        run_TestTruncation();
    } else if (suite_idx == 5) {
        run_TestCleanup();
    } else if (suite_idx == 6) {
        run_TestValidity();
    } else if (suite_idx == 7) {
        run_TestClassify();
    } else if (suite_idx == 8) {
        run_TestPlacement();
    } else if (suite_idx == 9) {
        run_TestEdgeRegions();
    } else if (suite_idx == 10) {
        run_TestFaceRegions();
    } else if (suite_idx == 11) {
        run_TestSelfCrossing();
    } else if (suite_idx == 12) {
        run_TestPrisms();
    } else if (suite_idx == 13) {
        run_TestAttach();
    } else if (suite_idx == 14) {
        run_TestRender();
    } else if (suite_idx == 15) {
        run_TestConstruction();
    }
    echo(str("=== PolySymmetrica tests: suite ", suite_idx, " ", suite_name, " PASS ==="));
}

// T=-2 lists suites, -1 runs all, and a scalar/list/range selects suites.
module _ps_run_test_suites(t) {
    assert(
        _ps_test_selector_ok(t),
        str("T must be -2, -1, or a list of suite indices from 0 to ", len(TEST_SUITES) - 1, ", got ", t)
    );

    if (_ps_test_selector_is_list(t)) {
        _ps_list_test_suites();
    } else {
        selected = _ps_test_selector_values(t);
        for (suite = TEST_SUITES)
            if (_ps_test_selector_is_all(t) || search(suite[0], selected) != [])
                _ps_run_test_suite(suite[0], suite[1]);
    }
}

if (T == -2) {
    _ps_run_test_suites(T);
    echo("=== PolySymmetrica tests: LIST PASS ===");
} else {
    _ps_run_test_suites(T);
    echo("=== PolySymmetrica tests: PASS ===");
}

color("green") 
linear_extrude(height = 2)
    text(str("Tests Passed!"));
