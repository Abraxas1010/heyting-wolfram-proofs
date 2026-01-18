# Architecture

## Overview

The Wolfram-Lean proof bridge consists of three main components:

```
┌─────────────────────────────────────────────────────────────────┐
│                     LEAN 4 (HeytingLean)                         │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ proof_term_hypergraph                                    │    │
│  │ • Traverse Expr AST with fuel-limited recursion          │    │
│  │ • Build hyperedges: children ++ [parent]                 │    │
│  │ • Export Int64 LE binary + JSON metadata                 │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────┬───────────────────────────────────────────┘
                      │ Binary protocol (lossless)
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                     WOLFRAM ENGINE                               │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ proof_hypergraph_visualize.wls                           │    │
│  │ • Parse binary hypergraph                                │    │
│  │ • Render via WolframModelPlot (SetReplace)               │    │
│  │ • Generate DAG layout for proof structure                │    │
│  └─────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ proof_hypergraph_witness.wls                             │    │
│  │ • Compute topological sort of hypergraph                 │    │
│  │ • Generate derivation steps (premises → parent)          │    │
│  │ • Return JSON witness                                    │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────┬───────────────────────────────────────────┘
                      │ JSON witness
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                     LEAN 4 (verification)                        │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ verifyWitness                                            │    │
│  │ • Check derivedRoot == expected root                     │    │
│  │ • Verify topological order (premises before parent)      │    │
│  │ • Validate each step edge exists in hypergraph           │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow

### Proof → Hypergraph

1. **Input**: Lean constant name (e.g., `HeytingLean.Crypto.QKD.BB84.copyAll_impossible`)
2. **Traverse**: Walk `Expr` AST with fuel-limited recursion
3. **Build nodes**: Each subexpression becomes a node with `{id, kind, depth, label}`
4. **Build edges**: Each application `f arg₁ arg₂` creates edge `(arg₁, arg₂, f)`
5. **Build hyperedges**: Group edges by parent → `[children..., parent]`
6. **Export**: Binary (Int64 LE) + JSON metadata

### Hypergraph → Visualization

1. **Input**: Binary files + metadata JSON
2. **Parse**: `TakeList[data, lengths]` reconstructs hyperedges
3. **Render**: `WolframModelPlot` for hypergraph, `Graph` for DAG
4. **Export**: PNG images

### Witness Protocol

1. **Input**: Binary hypergraph + root ID
2. **Compute leaves**: Vertices not appearing as parent
3. **Toposort**: Iterate: pick available edge (all premises known), mark parent known
4. **Generate steps**: Record `{parent, premises, edge}` for each step
5. **Return**: JSON with `{ok, derivedRoot, leafCount, steps, order}`
6. **Verify** (in Lean): Check structural invariants

## Term Types

| Lean Expr | Node Kind | Hyperedge Pattern |
|-----------|-----------|-------------------|
| `app f a` | `app` | `[a, f]` |
| `lam n ty b` | `lam` | `[ty, b, lam_node]` |
| `forallE n ty b` | `forall` | `[ty, b, forall_node]` |
| `const n _` | `const` | leaf (no outgoing edges) |
| `bvar i` | `bvar` | leaf |
| `fvar id` | `fvar` | leaf |
| `sort u` | `sort` | leaf |
| `letE n ty v b` | `let` | `[ty, v, b, let_node]` |

## Encoding Details

### Binary Format

- **Endianness**: Little-endian
- **Element type**: Int64 (8 bytes)
- **Hypergraph file**: `[v₀, v₁, ..., vₙ]` flattened vertex IDs
- **Lengths file**: `[len₀, len₁, ..., lenₘ]` edge sizes

### Reconstruction

```wolfram
(* Read files *)
data = BinaryReadList[dataPath, "Integer64"];
lengths = BinaryReadList[lengthsPath, "Integer64"];

(* Reconstruct hypergraph *)
hypergraph = TakeList[data, lengths];
(* Result: {{v0,v1,v2}, {v3,v4}, ...} *)
```

### Metadata JSON

```json
{
  "schema": "HeytingLean/ProofTermHypergraph/v1",
  "constant": "HeytingLean.Foo.bar",
  "exprKind": "value",
  "root": 0,
  "nodeCount": 44,
  "nodes": [
    {"id": 0, "kind": "lam", "depth": 0, "label": "λ h"},
    ...
  ],
  "hyperedgeSlots": [["ty", "body"], ...]
}
```
