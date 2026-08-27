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

function _ps_test_selector_values(t) = is_num(t) ? [t] : [for (v = t) v];
function _ps_test_selector_is_all(t) = is_num(t) && t == -1;
function _ps_test_selector_value_ok(t) = t >= 0 && t <= 15 && t == floor(t);
function _ps_test_selector_ok(t) =
    _ps_test_selector_is_all(t)
    || (
        len(_ps_test_selector_values(t)) > 0
        && len([
            for (v = _ps_test_selector_values(t))
                if (_ps_test_selector_value_ok(v)) v
        ]) == len(_ps_test_selector_values(t))
    );
function _ps_test_suite_selected(t, suite_idx) =
    _ps_test_selector_is_all(t)
    || search(suite_idx, _ps_test_selector_values(t)) != [];

echo("=== PolySymmetrica tests: START ===");

// T selects one suite or a list/range of suites for external runners;
// scalar -1 runs the full suite.
module _ps_run_test_suite(t) {
    assert(
        _ps_test_selector_ok(t),
        str("T must be -1 or a list of integers from 0 to 15, got ", t)
    );

    if (_ps_test_suite_selected(t, 0)) {
        echo("=== PolySymmetrica tests: suite 0 TestFuncs START ===");
        run_TestFuncs();
        echo("=== PolySymmetrica tests: suite 0 TestFuncs PASS ===");
    }
    if (_ps_test_suite_selected(t, 1)) {
        echo("=== PolySymmetrica tests: suite 1 TestVertex START ===");
        run_TestVertex();
        echo("=== PolySymmetrica tests: suite 1 TestVertex PASS ===");
    }
    if (_ps_test_suite_selected(t, 2)) {
        echo("=== PolySymmetrica tests: suite 2 TestDuals START ===");
        run_TestDuals();
        echo("=== PolySymmetrica tests: suite 2 TestDuals PASS ===");
    }
    if (_ps_test_suite_selected(t, 3)) {
        echo("=== PolySymmetrica tests: suite 3 TestCantellation START ===");
        run_TestCantellation();
        echo("=== PolySymmetrica tests: suite 3 TestCantellation PASS ===");
    }
    if (_ps_test_suite_selected(t, 4)) {
        echo("=== PolySymmetrica tests: suite 4 TestTruncation START ===");
        run_TestTruncation();
        echo("=== PolySymmetrica tests: suite 4 TestTruncation PASS ===");
    }
    if (_ps_test_suite_selected(t, 5)) {
        echo("=== PolySymmetrica tests: suite 5 TestCleanup START ===");
        run_TestCleanup();
        echo("=== PolySymmetrica tests: suite 5 TestCleanup PASS ===");
    }
    if (_ps_test_suite_selected(t, 6)) {
        echo("=== PolySymmetrica tests: suite 6 TestValidity START ===");
        run_TestValidity();
        echo("=== PolySymmetrica tests: suite 6 TestValidity PASS ===");
    }
    if (_ps_test_suite_selected(t, 7)) {
        echo("=== PolySymmetrica tests: suite 7 TestClassify START ===");
        run_TestClassify();
        echo("=== PolySymmetrica tests: suite 7 TestClassify PASS ===");
    }
    if (_ps_test_suite_selected(t, 8)) {
        echo("=== PolySymmetrica tests: suite 8 TestPlacement START ===");
        run_TestPlacement();
        echo("=== PolySymmetrica tests: suite 8 TestPlacement PASS ===");
    }
    if (_ps_test_suite_selected(t, 9)) {
        echo("=== PolySymmetrica tests: suite 9 TestEdgeRegions START ===");
        run_TestEdgeRegions();
        echo("=== PolySymmetrica tests: suite 9 TestEdgeRegions PASS ===");
    }
    if (_ps_test_suite_selected(t, 10)) {
        echo("=== PolySymmetrica tests: suite 10 TestFaceRegions START ===");
        run_TestFaceRegions();
        echo("=== PolySymmetrica tests: suite 10 TestFaceRegions PASS ===");
    }
    if (_ps_test_suite_selected(t, 11)) {
        echo("=== PolySymmetrica tests: suite 11 TestSelfCrossing START ===");
        run_TestSelfCrossing();
        echo("=== PolySymmetrica tests: suite 11 TestSelfCrossing PASS ===");
    }
    if (_ps_test_suite_selected(t, 12)) {
        echo("=== PolySymmetrica tests: suite 12 TestPrisms START ===");
        run_TestPrisms();
        echo("=== PolySymmetrica tests: suite 12 TestPrisms PASS ===");
    }
    if (_ps_test_suite_selected(t, 13)) {
        echo("=== PolySymmetrica tests: suite 13 TestAttach START ===");
        run_TestAttach();
        echo("=== PolySymmetrica tests: suite 13 TestAttach PASS ===");
    }
    if (_ps_test_suite_selected(t, 14)) {
        echo("=== PolySymmetrica tests: suite 14 TestRender START ===");
        run_TestRender();
        echo("=== PolySymmetrica tests: suite 14 TestRender PASS ===");
    }
    if (_ps_test_suite_selected(t, 15)) {
        echo("=== PolySymmetrica tests: suite 15 TestConstruction START ===");
        run_TestConstruction();
        echo("=== PolySymmetrica tests: suite 15 TestConstruction PASS ===");
    }
}

_ps_run_test_suite(T);

echo("=== PolySymmetrica tests: PASS ===");

color("green") 
linear_extrude(height = 2)
    text(str("Tests Passed!"));
