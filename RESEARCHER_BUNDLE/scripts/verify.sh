#!/usr/bin/env bash
set -euo pipefail

echo "=== Wolfram-Lean Bridge Verification ==="
echo ""

# Check for sorry/admit (recursive scan of ALL Lean files)
echo "Checking for sorry/admit..."
if grep -RIn --include='*.lean' -E '\b(sorry|admit)\b' HeytingLean/ 2>/dev/null; then
    echo "ERROR: Found sorry/admit in codebase"
    exit 1
fi
echo "✓ No sorry/admit found"
echo ""

# Check Wolfram scripts exist
echo "Checking Wolfram scripts..."
for script in proof_hypergraph_visualize.wls proof_hypergraph_witness.wls echo_hypergraph_binary.wls; do
    if [[ -f "ffi/heyting_wolfram_bridge/$script" ]]; then
        echo "  ✓ $script"
    else
        echo "  ✗ $script MISSING"
        exit 1
    fi
done
echo ""

# Check wolframscript if available
if command -v wolframscript >/dev/null 2>&1; then
    echo "Checking Wolfram Engine..."
    if wolframscript -code '1+1' 2>/dev/null | grep -q "2"; then
        echo "  ✓ Wolfram Engine activated"
    else
        echo "  ⚠ Wolfram Engine not activated (run: wolframscript -activate)"
    fi
else
    echo "⚠ wolframscript not found (Wolfram features unavailable)"
fi
echo ""

echo "=== All checks passed ==="
