# Provenance Data Model

This document describes the optional provenance metadata carried by a
PolySymmetrica polyhedron. It is both an implementation reference for the
current Stage-A system and a design contract for Stage B. The implementation
lives primarily in `core/funcs.scad`, `core/transform.scad`,
`core/cleanup.scad`, and `core/truncation.scad`.

Provenance answers a different question from geometry and topology:

> Where did this current vertex or face come from, and which semantic
> operation produced it?

It must never become a second topology definition. The face cycles remain the
sole topology authority; edges are reconstructed from those cycles whenever
they are needed.

## Descriptor shape

The ordinary descriptor remains a three-element list:

```scad
[verts, faces, e_over_ir]
```

A provenance-bearing descriptor appends one optional element:

```scad
[verts, faces, e_over_ir, provenance]
```

The first three fields have their existing meanings:

- `verts` is the current list of 3D points.
- `faces` is the current list of ordered vertex-index cycles.
- `e_over_ir` is the edge-length/inter-radius scale ratio. It is unrelated to
  provenance semantics and may be removed or replaced independently.
- `provenance` is an implementation-private list-backed record.

Raw three-element descriptors are valid and remain intentionally cheap. Do not
append an empty placeholder yourself: absence of the fourth element means
that provenance has not been initialized.

Use the accessors in `core/funcs.scad` rather than depending on list positions:

```scad
poly_has_provenance(poly)
poly_provenance(poly)
poly_with_provenance(poly)
poly_vertex_provenance(poly, vertex_idx)
poly_face_provenance(poly, face_idx)
poly_source_vertex_indices(poly, source_vertex_idx=undef)
poly_vertex_descends_from(poly, vertex_idx, source_vertex_idx)
poly_edge_provenance(poly, edge)
poly_edge_source_ids(poly, edge)
poly_provenance_history(poly)
```

`poly_provenance_init(poly)` is an alias for `poly_with_provenance(poly)` for
call sites that prefer an explicit initializer name.

## Current private record format

The current version tag is `"ps_provenance_v1"`. The record currently has this
shape:

```scad
[
    "ps_provenance_v1",
    vertex_records,
    face_records,
    semantic_history
]
```

Each current vertex and face has one aligned record. An element record has the
following shape:

```scad
[root_vertex_ids, root_face_ids, derivation_events]
```

Root IDs are currently represented as two-element lists:

```scad
["vertex", source_vertex_index]
["face", source_face_index]
```

For example, after lazy initialization of a raw descriptor, current vertex 3
has a record equivalent to:

```scad
[
    [["vertex", 3]],
    [],
    [["source_vertex", 3]]
]
```

and source face 2 has:

```scad
[
    [],
    [["face", 2]],
    [["source_face", 2]]
]
```

The lists of roots are sets in intent, although they are represented as
ordered lists. Lineage operations merge and remove duplicate roots. A record
may have several vertex roots or face roots: a generated site can depend on
multiple source elements.

The current event vocabulary includes:

- `source_vertex` and `source_face` for lazy source records;
- `chamfer_site` for generated chamfer sites;
- `truncation_site` for generated truncation sites;
- `rectify_site` for strict-rectification edge-midpoint sites;
- `cantitruncate_site` for generated cantitruncation sites;
- operation-specific face events such as `chamfer_face` and
  `truncate_face`;
- `merged_vertex` when cleanup combines coincident vertices;
- `triangulated_face` when cleanup replaces a non-planar face with triangles;
- `derived_edge` for the transient result returned by an edge query.

Event records are diagnostic lineage, not a topology table. Their exact
arguments are private and may grow as the event vocabulary is standardized.
The public contract is that events identify derivation, while root IDs identify
source ancestry.

Semantic history is separate from element lineage. It is currently a list of
one-element operation records:

```scad
[["chamfer"], ["truncate"]]
```

For a compound public operation, history contains one semantic operation even
when the element records contain several internal derivation events. This
separation is important: users should be able to ask what operation was
performed without treating the internal construction steps as separate public
history entries.

The list layout above is documented to make debugging possible. It is not a
stable application-facing ABI. In particular, do not write `poly[3][1][i]`
in user code or in a new core module; add or use a named accessor instead.

## Lineage rules

### Vertices and generated sites

An original current vertex is represented by its source vertex root and a
`source_vertex` event. A generated point receives the roots of the source
vertices and faces that define its site, plus a derivation event. Generated
points do not inherit a `source_vertex` event merely because they depend on an
original vertex.

Selective truncation is a deliberate exception for unchanged geometry: a
zero-cut site reuses the complete provenance record of its near endpoint.
Consequently, an unselected source vertex remains a retained source vertex
after the surrounding topology is rebuilt and can be selected by a later
selective operation.

That distinction makes the following two queries intentionally different:

- `poly_source_vertex_indices(poly)` returns current vertices that are still
  retained source vertices.
- `poly_vertex_descends_from(poly, i, source_vertex)` returns any current
  vertex whose ancestry includes that source vertex, including generated
  descendants.

Selection for the Stage-A compound truncation path uses the first meaning. It
selects current vertices by provenance-derived current indices, not by their
coordinates, edge lengths, or incidental output ordering.

### Faces

Face lineage follows the face cycles used to build the output. A generated face
merges the lineage records of the sites and original vertices in its cycle and
then receives an operation-specific face event. If a face is dropped during
cleanup, its record is dropped with it. If a face is triangulated, every
resulting triangle inherits the source face record and receives a
`triangulated_face` event.

Face indices are current indices, not persistent identities. Reordering,
filtering, or triangulating faces can change them; the roots and events are the
persistent part.

### Point merging and cleanup

The site transform kernel first deduplicates coincident points. The resulting
point receives the merged lineage of the first matching point and all
contributing site records. Cleanup can then merge vertices again, remove
unreferenced vertices, remove degenerate faces, triangulate non-planar faces,
and normalize winding. Each of these operations preserves or remaps the
aligned records.

Because geometric equality can merge distinct construction sites, a current
vertex may legitimately have multiple roots and multiple derivation events.
Do not assume that one current vertex corresponds to one source vertex.

### Winding

Winding changes alter the order of a face cycle but not its lineage. The face
record stays attached to the face. Since topology is read from the current
cycles, edge queries automatically see the normalized winding.

## Derived edge provenance

There is deliberately no fourth edge table. For a requested current edge,
`poly_edge_provenance(poly, edge)` derives a record from:

1. the edge endpoints in the current face cycles;
2. the vertex lineage of both endpoints; and
3. the face lineage of the incident current faces.

The current returned record is:

```scad
[
    source_edge_ids,
    endpoint_vertex_roots,
    incident_face_roots,
    [["derived_edge", current_edge_index]]
]
```

An inferred source edge ID currently has the form `["edge", a, b]`, where
`a < b` are source vertex indices. `poly_edge_source_ids(poly, edge)` returns
only these IDs.

This is intentionally a many-to-many query. A chamfer edge can be related to
several source edges, and an edge may have no inferred source edge when its
endpoints do not provide enough source-vertex ancestry. Incident face roots
remain useful in that case. Callers must not treat a source edge ID as a
replacement for the current edge index or as an independently stored edge
identity.

## Lifecycle and supported operations

### Lazy initialization

Calling `poly_with_provenance(raw_poly)` creates source records without
changing the geometry, faces, or scale field. Calling it on an already
provenance-bearing poly returns that poly unchanged. `poly_make(...)` also
accepts an optional fourth `provenance` argument and validates the vertex and
face record counts when it is supplied.

### Stage-A operations currently supported

The following paths currently preserve or create provenance:

- `poly_chamfer(...)` lazily initializes a raw input and records one semantic
  `chamfer` operation.
- `poly_truncate(...)` preserves provenance. Its internal
  `selected_vertices` argument is the Stage-A selective selector.
- `poly_rectify(...)` preserves provenance through strict rectification and
  through the provenance-aware truncation path used by planarized
  rectification. Both styles record one semantic `rectify` operation; the
  planarized implementation detail does not appear as `truncate` in history.
- `poly_cantitruncate(...)` preserves a supplied provenance record and records
  one semantic `cantitruncate` operation. Its generated site events retain
  the source face/vertex information needed by current lineage queries.
- `poly_fix_winding(...)` preserves the record without inventing a new
  semantic operation.
- `poly_cleanup(...)` remaps vertex and face records through merging,
  filtering, triangulation, compaction, and winding normalization.

The public history for a chamfer followed by selective truncation is therefore
expected to be:

```scad
[["chamfer"], ["truncate"]]
```

The internal site events can be more detailed than that history.

### Raw behavior and `e_over_ir`

Raw three-slot inputs and ordinary raw transforms remain supported. Where an
operator has not entered a provenance-aware path, it should return the same
three-slot shape it returned before this feature. `e_over_ir` is copied or
recomputed according to the existing geometry contract; it is not a source
identity and must not be used for lineage decisions.

## Current limitations and things to be careful of

- The fourth slot is private metadata, not a general predicate or history API.
  Keep application code on named accessors.
- Current root IDs are local to the descriptor that was first initialized.
  They are not yet globally unique across independently constructed polys.
- Current source roots use source indices. Those indices are stable only
  relative to that source descriptor; current vertex and face indices are
  allowed to change.
- Edge lineage is derived and can be incomplete or ambiguous. There is no
  supported operation for mutating an edge record.
- A generated descendant is not a retained source vertex. Use
  `poly_vertex_descends_from` when ancestry is wanted, and
  `poly_source_vertex_indices` when selecting retained source vertices.
- Coincident points may merge several lineages. This is correct, but code
  assuming one-to-one ancestry will be wrong on irregular or degenerate input.
- A provenance-aware transform must pass the correct operation and site
  metadata to the site kernel. Generic site records from an unrelated
  operator must not be guessed at or reinterpreted by positional convention.
- Provenance-bearing polys must not currently be sent to unsupported
  topology-changing operators. They assert explicitly at the operator entry
  point. Current guarded entry points include `poly_dual`, `poly_cantellate`,
  `poly_snub`, `poly_cap_loops`, `poly_delete_faces`, `poly_slice`, and
  `poly_attach`.
- Geometry validity is still independent of lineage validity. Continue to use
  `poly_valid(...)`, operation-specific count/adjacency checks, and geometric
  tolerances; provenance assertions do not prove that a mesh is sound.
- The current cantitruncate implementation records the public operation as a
  single history entry, but its site construction is still operator-specific.
  Stage B should make its internal compound mapping explicit and reusable
  rather than relying on the current event vocabulary.

## Stage B target design

Stage B should complete provenance without changing the topology authority or
making raw descriptors mandatory. The following principles are the intended
design, not all current behavior.

### Stable source namespaces

Source indices are sufficient for one input, but not for compound operations.
Stage B should give every source a namespace or compound-root identity. A
conceptual root ID could be represented as:

```scad
["root", source_namespace, "vertex", source_index]
["root", source_namespace, "face", source_index]
["root", source_namespace, "edge", source_edge_key]
```

The exact private representation can differ, but it must distinguish two
independently built cubes attached into one output. `poly_attach` and all
other compound constructors should preserve both namespaces and record the
relationship between them.

Namespaces should be assigned by the operation that combines inputs, not by
current list positions. Reordering or cleanup must never change a root
identity.

### A common operation and mapping contract

Every topology-changing operator should use the same conceptual contract:

1. validate or initialize the input provenance records;
2. define source-to-site mapping for each generated point;
3. define output face cycles from those sites;
4. merge point and face lineage while building the output;
5. append one semantic public operation record;
6. run cleanup and winding normalization without losing alignment.

The transform kernel should accept semantic site lineage records, not infer
meaning from an operator's incidental numeric layout. Each operator should
provide explicit mappings for its generated vertices, output faces, removed
faces, caps, and any internal triangulation.

The semantic history should become a read-only operation graph or an
equivalent versioned list. It should record the public operator, source
namespace(s), and stable operation identity, while element records retain the
fine-grained ancestry needed for queries. Internal construction steps may be
represented in lineage without being promoted to public history.

### Dual mapping

Duals need a dedicated mapping because their dimensions exchange roles:

- each source face becomes one dual vertex;
- each source vertex becomes one dual face whose cycle is the ordered set of
  incident source faces;
- each dual edge is derived from adjacent source faces and the resulting dual
  face cycles;
- source face and source vertex roots must be carried to the corresponding
  dual element records;
- winding normalization must preserve the source-vertex-to-dual-face mapping.

The dual implementation must not create an edge table merely to support this
mapping. The source edge relationship can be derived from the two incident
source faces and from the resulting dual face cycles. A dual of a compound
input must preserve source namespaces and identify whether a dual element is
derived from one source or from a mixed boundary.

### Remaining topology-changing operators

Stage B should map all currently guarded or partially supported operations:

- `poly_cantellate` and `poly_snub`: face offsets, edge sites, vertex caps,
  connectors, and strict/planarized variants;
- `poly_cantitruncate`: explicit internal chamfer/truncation or equivalent
  operation mapping, with one public semantic history entry;
- `poly_cap_loops` and `poly_delete_faces`: retained faces, removed faces,
  cap faces, and boundary-edge lineage;
- `poly_slice`: surviving source faces, split faces, intersection vertices,
  and generated cap faces;
- `poly_attach`: separate namespaces, transformed source ancestry, seam
  faces/edges, and cleanup across coincident attachment points;
- any construction helper that creates, removes, or rewrites topology.

Pure geometry queries, rendering, classification, placement, and validation do
not need to rewrite provenance. They should accept a fourth slot without
silently dropping it when they pass a poly through to another operation.

### Read-only query surface

The Stage-B public API should remain small and accessor-based, but should add
queries for:

- all current vertices/faces descended from a namespaced source root;
- all current elements derived by a named operation or operation identity;
- source descendants grouped by element kind;
- derived edge lineage including source edge roots, endpoint roots, and
  incident-face roots;
- semantic operation history and the input/output namespaces for each
  compound operation.

Queries should return current indices only as results. They should never make
current indices persistent or expose the record layout as the API. A query that
needs to distinguish retained source elements from generated descendants
should make that distinction explicit in its name or result record.

### Versioning and validation

The version tag should be checked by provenance-aware internals. A future
record version must either be migrated by a named helper or fail clearly; it
must not be misread as a v1 record. `poly_make` and transform finalization
should validate alignment between current vertices/faces and their records.

Stage B should add invariants for:

- one vertex record per current vertex and one face record per current face;
- roots having valid namespace/kind/id shapes;
- operation records being append-only and semantically ordered;
- cleanup preserving root/event content under remapping;
- dual mappings covering every source face and source vertex exactly once;
- compound namespaces never colliding;
- edge queries matching the edges derived from current face cycles.

These invariants complement, rather than replace, the existing structural,
closed, star, convexity, orientation, adjacency, and geometry tests.

## Development status

### Implemented and working well

- Optional fourth-slot descriptors with raw three-slot compatibility.
- Lazy source initialization.
- Vertex and face root/event lineage for Stage-A site transforms.
- Selective truncation of retained source vertices after chamfer.
- Lineage preservation through site deduplication and cleanup.
- Derived edge queries without storing a second topology table.
- Single semantic history entries for the supported public operations.
- Explicit failures for unsupported provenance-bearing topology operators.

### Not implemented yet

- Globally unique source namespaces and compound-root identities.
- Provenance-aware dual mapping.
- Full lineage mapping for cantellation, snub, construction, slicing, and
  attachment.
- A stable public operation-history graph.
- General descendant/operation query families beyond the current small API.
- A finalized, versioned event vocabulary and migration path.

### Recommended development order

1. Stabilize source namespaces and versioned private records.
2. Extract the common operator mapping contract from the Stage-A kernel.
3. Implement and test dual mapping.
4. Implement compound namespaces and attachment/construction mappings.
5. Complete cantellation, cantitruncation, snub, deletion, capping, and
   slicing mappings.
6. Add the read-only descendant and history queries.
7. Expand regression tests over irregular valence, non-uniform lengths,
   star-prism inputs, point merging, cleanup, and winding changes.

At every step, preserve the central rule: provenance describes the current
face-derived topology; it does not define a second topology beside it.
