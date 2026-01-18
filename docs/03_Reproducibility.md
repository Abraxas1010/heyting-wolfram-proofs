# Reproducibility Guide

## Prerequisites

### Lean 4

```bash
# Install elan (Lean version manager)
curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh

# Verify installation
lean --version
lake --version
```

### Wolfram Engine (Free Developer License)

1. Download from: https://www.wolfram.com/engine/
2. Install:
   ```bash
   sudo bash WolframEngine_14.x.x_LIN.sh --nox11
   ```
3. Activate:
   ```bash
   wolframscript -activate
   # Enter your Wolfram ID credentials
   ```
4. Verify:
   ```bash
   wolframscript -code '2+2'
   # Expected output: 4
   ```

### SetReplace Package

```wolfram
(* In wolframscript or Mathematica *)
PacletInstall["SetReplace"]

(* Verify *)
Needs["SetReplace`"]
WolframModelPlot[{{1, 2, 3}, {2, 3, 4}}]
```

## Building

```bash
cd RESEARCHER_BUNDLE

# Build executables
lake build proof_term_hypergraph
lake build wolfram_roundtrip
```

## Running

### Echo Demo (Lossless Roundtrip)

```bash
lake exe wolfram_roundtrip -- --echo
```

Expected output:
```
[echo] Lean→Wolfram→Lean (lossless binary echo)
[echo] OK (byte-identical roundtrip)
```

### Proof Visualization

```bash
lake exe proof_term_hypergraph -- \
  --const HeytingLean.Crypto.QKD.BB84.copyAll_impossible \
  --module HeytingLean.Crypto.QKD.BB84 \
  --expr value \
  --fuel 1024 \
  --viz \
  --witness
```

Expected output:
```
[viz] exported plots under: .tmp/proof_term_hypergraph/...
[witness] OK (Wolfram witness verified by Lean)
Wrote:
  *_value_metadata.json
  *_value_hypergraph.bin
  *_value_lengths.bin
  *_constdeps_metadata.json
  *_constdeps_hypergraph.bin
  *_constdeps_lengths.bin
```

## Generated Files

| File | Description |
|------|-------------|
| `*_hypergraph.bin` | Binary hyperedge data |
| `*_lengths.bin` | Edge length data |
| `*_metadata.json` | Node labels, types, positions |
| `*_graph.json` | Full graph structure (JSON) |
| `*_term_hypergraph.png` | Wolfram Physics style plot |
| `*_term_dag.png` | Layered proof DAG |
| `*_constdeps_dag.png` | Constant dependency graph |

## Verification

```bash
./scripts/verify.sh
```

This checks:
1. No `sorry` or `admit` in codebase
2. All Wolfram scripts present
3. Wolfram Engine activation (if available)

## Troubleshooting

### "wolframscript not found"

Add Wolfram to your PATH:
```bash
export PATH="/usr/local/Wolfram/WolframEngine/14.x/Executables:$PATH"
```

### "SetReplace not available"

Install the package:
```wolfram
PacletInstall["SetReplace"]
```

### "witness verification failed"

Ensure the root ID matches:
```bash
# Check metadata
cat .tmp/proof_term_hypergraph/*_metadata.json | jq '.root'
```

### Build errors

Clean and rebuild:
```bash
lake clean
lake build
```

## Reproducibility Guarantee

The binary protocol ensures exact reproducibility:

1. **Deterministic encoding**: Same proof term always produces identical binary
2. **SHA256 verification**: Roundtrip integrity is cryptographically verified
3. **Platform-independent**: Little-endian Int64 works on all modern systems
4. **No floating point**: Integer-only format avoids precision issues
