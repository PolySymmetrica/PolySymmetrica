/*
 * This file is part of PolySymmetrica, a Polyhedral Geometry Modelling System.
 * Copyright 2025-2026 Susan Witts
 * SPDX-License-Identifier: MIT
 */

// LibFile: polysymmetrica/core/profile.scad
// Shared parameter override helpers for transform operators.
//
// INPUT FORMAT (`profile`)
// ---------------------------------
// `profile` is a list of rows. Each row targets an element kind
// ("face" | "vert" | "edge"), a selector scope, and one or more key/value
// pairs.
//
// Row schemas.
//   ["face"|"vert"|"edge", "all", ["key", value], ...]
//   ["face"|"vert"|"edge", "family", family_id, ["key", value], ...]
//   ["face"|"vert"|"edge", "id", id_or_ids, ["key", value], ...]
//
// Where.
// - `id_or_ids` may be a single index or a list of indices.
// - keys are operator-defined (examples: "df", "angle", "c", "de", "t").
//
// Precedence is fixed and deterministic:
//   id > family > all
// For the same scope/key, later rows win.
// For duplicate keys in one row, the last key/value wins.
//
// EXAMPLE INPUT
// -------------
// rows = [
//   ["face", "all", ["angle", 15]],
//   ["face", "family", 1, ["df", 0.04]],
//   ["face", "id", [2, 7], ["angle", 19]],
//   ["vert", "family", 0, ["c", 0.06]]
// ];
//
// OUTPUT FORMAT (compiled arrays)
// --------------------------------
// `ps_profile_compile_key(...)` returns a dense per-index array of length
// `count`, containing either a resolved value or `undef`.
//
// `ps_profile_compile_specs(...)` returns a list of dense arrays, one per spec,
// in the same order as `specs`.
//
// Example.
// face_fid = [0, 1, 1, 0];
// face_df = ps_profile_compile_key(rows, "face", "df", 4, face_fid);
// // => [undef, 0.04, 0.04, undef]
//
// face_angle = ps_profile_compile_key(rows, "face", "angle", 4, face_fid);
// // => [15, 15, 19, 15]
//
// specs = [
//   ["face", "df", 4, face_fid],
//   ["face", "angle", 4, face_fid]
// ];
// compiled = ps_profile_compile_specs(rows, specs);
// // => [face_df, face_angle]
//
// ACCESSOR USAGE
// --------------
// v = ps_compiled_param_get(compiled[0], face_idx); // safe bounds + undef
//
// DEBUG PRINT
// -----------
// Use `ps_profile_print(rows);` to dump normalized row interpretation.

function _ps_profile_row_kind(row) =
    (!is_list(row) || len(row) < 1) ? undef : row[0];

function _ps_profile_row_scope(row) =
    (!is_list(row) || len(row) < 2) ? undef
        : (is_string(row[1]) && (row[1] == "all" || row[1] == "family" || row[1] == "id")) ? row[1]
        : undef;

function _ps_profile_row_selector(row) =
    let(scope = _ps_profile_row_scope(row))
    (scope == "all") ? undef
        : (scope == "family") ? row[2]
        : (scope == "id") ? row[2]
        : undef;

function _ps_profile_row_kv_start(row) =
    let(scope = _ps_profile_row_scope(row))
    (scope == "family" || scope == "id") ? 3
        : (scope == "all") ? 2
        : 999999;

function _ps_profile_selector_has_id(selector, id) =
    is_undef(id) ? false
        : is_list(selector)
            ? (len([for (x = selector) if (x == id) 1]) > 0)
            : (selector == id);

function _ps_profile_row_applies(row, kind, scope, element_id=undef, family_id=undef) =
    let(
        row_kind = _ps_profile_row_kind(row),
        row_scope = _ps_profile_row_scope(row),
        selector = _ps_profile_row_selector(row)
    )
    (row_kind == kind) && (row_scope == scope) && (
        (scope == "all")
        || (scope == "family" && !is_undef(family_id) && selector == family_id)
        || (scope == "id" && _ps_profile_selector_has_id(selector, element_id))
    );

function _ps_profile_row_get(row, key) =
    let(
        start = _ps_profile_row_kv_start(row),
        vals = [
            for (i = [start:1:len(row)-1])
                let(p = row[i])
                if (is_list(p) && len(p) >= 2 && p[0] == key) p[1]
        ],
        vals2 = [for (v = vals) if (!is_undef(v)) v]
    )
    (len(vals2) == 0) ? undef : vals2[len(vals2)-1];

// Function: ps_profile_get()
// Usage:
//   result = ps_profile_get(profile, kind, key, element_id=undef, family_id=undef);
// Description:
//   Resolve one override value from a profile using fixed precedence
//   `id > family > all`, with later rows winning inside the same scope.
// Arguments:
//   profile = profile row list
//   kind = `"face"`, `"vert"`, or `"edge"`
//   key = operator-defined parameter key
//   element_id = element index for `"id"` lookups
//   family_id = family id for `"family"` lookups
function ps_profile_get(profile, kind, key, element_id=undef, family_id=undef) =
    let(
        rows = is_undef(profile) ? [] : profile,
        vals_all = [for (row = rows) if (_ps_profile_row_applies(row, kind, "all", element_id, family_id)) _ps_profile_row_get(row, key)],
        vals_family = [for (row = rows) if (_ps_profile_row_applies(row, kind, "family", element_id, family_id)) _ps_profile_row_get(row, key)],
        vals_id = [for (row = rows) if (_ps_profile_row_applies(row, kind, "id", element_id, family_id)) _ps_profile_row_get(row, key)],
        all2 = [for (v = vals_all) if (!is_undef(v)) v],
        fam2 = [for (v = vals_family) if (!is_undef(v)) v],
        id2 = [for (v = vals_id) if (!is_undef(v)) v],
        v_all = (len(all2) == 0) ? undef : all2[len(all2)-1],
        v_family = (len(fam2) == 0) ? undef : fam2[len(fam2)-1],
        v_id = (len(id2) == 0) ? undef : id2[len(id2)-1]
    )
    !is_undef(v_id) ? v_id
        : !is_undef(v_family) ? v_family
        : v_all;

// Function: ps_profile_count_kind()
// Usage:
//   result = ps_profile_count_kind(profile, kind);
// Description:
//   Count profile rows for one element kind.
// Arguments:
//   profile = profile row list
//   kind = `"face"`, `"vert"`, or `"edge"`
function ps_profile_count_kind(profile, kind) =
    is_undef(profile) ? 0
        : len([for (row = profile) if (_ps_profile_row_kind(row) == kind) 1]);

// Function: ps_profile_row_count()
// Usage:
//   result = ps_profile_row_count(profile);
// Description:
//   Count the total number of profile rows.
// Arguments:
//   profile = profile row list
function ps_profile_row_count(profile) =
    is_undef(profile) ? 0 : len(profile);

// Function: ps_profile_has_scope()
// Usage:
//   result = ps_profile_has_scope(profile, kind, scope);
// Description:
//   Determine whether a profile contains at least one row for the supplied kind
//   and scope.
// Arguments:
//   profile = profile row list
//   kind = `"face"`, `"vert"`, or `"edge"`
//   scope = `"all"`, `"family"`, or `"id"`
function ps_profile_has_scope(profile, kind, scope) =
    is_undef(profile) ? false
        : (len([
            for (row = profile)
                if (_ps_profile_row_kind(row) == kind && _ps_profile_row_scope(row) == scope) 1
        ]) > 0);

// Function: ps_profile_uses_family()
// Usage:
//   result = ps_profile_uses_family(profile, kind);
// Description:
//   Convenience test for whether a profile uses family-scoped rows for one kind.
// Arguments:
//   profile = profile row list
//   kind = `"face"`, `"vert"`, or `"edge"`
function ps_profile_uses_family(profile, kind) =
    ps_profile_has_scope(profile, kind, "family");

// Function: ps_profile_compile_key()
// Usage:
//   result = ps_profile_compile_key(profile, kind, key, count, family_ids=undef);
// Description:
//   Compile one `kind`/`key` profile view into a dense lookup array.
// Arguments:
//   profile = profile row list
//   kind = `"face"`, `"vert"`, or `"edge"`
//   key = operator-defined parameter key
//   count = output array length
//   family_ids = optional parallel family-id array for family-scoped lookups
function ps_profile_compile_key(profile, kind, key, count, family_ids=undef) =
    [for (idx = [0:1:max(0, count-1)])
        ps_profile_get(
            profile,
            kind,
            key,
            idx,
            (is_undef(family_ids) || idx >= len(family_ids)) ? undef : family_ids[idx]
        )
    ];

// Compile multiple specs into dense lookup arrays.
// Spec row format.
//   [kind, key, count]
//   [kind, key, count, family_ids]
// Function: ps_profile_compile_specs()
// Usage:
//   result = ps_profile_compile_specs(profile, specs);
// Description:
//   Compile multiple profile specs into dense lookup arrays in spec order.
// Arguments:
//   profile = profile row list
//   specs = compile spec rows `[kind, key, count]` or
//       `[kind, key, count, family_ids]`
function ps_profile_compile_specs(profile, specs) =
    [for (spec = specs)
        ps_profile_compile_key(
            profile,
            spec[0],
            spec[1],
            spec[2],
            (len(spec) >= 4) ? spec[3] : undef
        )
    ];

// Function: ps_compiled_param_get()
// Usage:
//   result = ps_compiled_param_get(arr, idx);
// Description:
//   Safely read one compiled parameter entry with bounds checking.
// Arguments:
//   arr = compiled parameter array
//   idx = element index
function ps_compiled_param_get(arr, idx) =
    (is_undef(arr) || idx < 0 || idx >= len(arr)) ? undef : arr[idx];

// Module: ps_profile_print()
// Usage:
//   ps_profile_print(profile);
// Description:
//   Echo a normalized interpretation of a profile for debugging.
// Arguments:
//   profile = profile row list
module ps_profile_print(profile) {
    rows = is_undef(profile) ? [] : profile;
    echo(str("profile: rows=", len(rows)));
    for (ri = [0:1:len(rows)-1]) {
        row = rows[ri];
        kind = _ps_profile_row_kind(row);
        scope = _ps_profile_row_scope(row);
        sel = _ps_profile_row_selector(row);
        start = _ps_profile_row_kv_start(row);
        kv = (start > len(row)-1) ? [] : [for (i = [start:1:len(row)-1]) row[i]];
        echo(str("  row#", ri, " kind=", kind, " scope=", scope, " selector=", sel, " kv=", kv));
    }
}
