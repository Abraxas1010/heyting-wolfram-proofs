# Binary Protocol Specification

## Overview

The Wolfram-Lean bridge uses a simple, lossless binary protocol for hypergraph data exchange. This ensures byte-identical roundtrips and efficient storage.

## File Pair Convention

Each hypergraph is stored as two files:

| File Suffix | Contents |
|-------------|----------|
| `*_hypergraph.bin` | Flattened vertex IDs |
| `*_lengths.bin` | Length of each hyperedge |

## Binary Format

### Encoding

- **Byte order**: Little-endian (LE)
- **Element type**: Signed 64-bit integer (`Int64`)
- **No header**: Raw data only

### Hypergraph File (`*_hypergraph.bin`)

Contains all vertex IDs in order, concatenated:

```
[edge₀_v₀, edge₀_v₁, ..., edge₀_vₙ, edge₁_v₀, edge₁_v₁, ...]
```

Each element is 8 bytes (Int64 LE).

### Lengths File (`*_lengths.bin`)

Contains the size of each hyperedge:

```
[len₀, len₁, len₂, ...]
```

The sum of all lengths equals the number of elements in the hypergraph file.

## Example

### Hypergraph

```
{{1, 2, 3}, {2, 4, 5}, {6, 7}}
```

### Hypergraph File (24 + 24 + 16 = 64 bytes)

```
01 00 00 00 00 00 00 00  # 1
02 00 00 00 00 00 00 00  # 2
03 00 00 00 00 00 00 00  # 3
02 00 00 00 00 00 00 00  # 2
04 00 00 00 00 00 00 00  # 4
05 00 00 00 00 00 00 00  # 5
06 00 00 00 00 00 00 00  # 6
07 00 00 00 00 00 00 00  # 7
```

### Lengths File (24 bytes)

```
03 00 00 00 00 00 00 00  # 3
03 00 00 00 00 00 00 00  # 3
02 00 00 00 00 00 00 00  # 2
```

## Reading in Wolfram

```wolfram
readInt64List[path_String] := Module[{stream, data},
  stream = OpenRead[path, BinaryFormat -> True, ByteOrdering -> -1];
  data = BinaryReadList[stream, "Integer64"];
  Close[stream];
  data
];

reconstructHypergraph[dataPath_, lengthsPath_] := Module[{data, lengths},
  data = readInt64List[dataPath];
  lengths = readInt64List[lengthsPath];
  TakeList[data, lengths]
];
```

## Writing in Wolfram

```wolfram
writeInt64List[path_String, xs_List] := Module[{stream},
  stream = OpenWrite[path, BinaryFormat -> True, ByteOrdering -> -1];
  BinaryWrite[stream, xs, "Integer64"];
  Close[stream];
];

exportHypergraph[hypergraph_List, dataPath_, lengthsPath_] := Module[{},
  writeInt64List[dataPath, Flatten[hypergraph]];
  writeInt64List[lengthsPath, Length /@ hypergraph];
];
```

## Reading in Lean

```lean
private def decodeU64AtLE (bytes : ByteArray) (offset : Nat) : UInt64 :=
  let rec go (i : Nat) (pow : Nat) (acc : Nat) : Nat :=
    if i < 8 then
      let b := bytes.get! (offset + i) |>.toNat
      go (i + 1) (pow * 256) (acc + b * pow)
    else
      acc
  UInt64.ofNat (go 0 1 0)

private def decodeU64LEList (bytes : ByteArray) : Except String (List UInt64) := Id.run do
  let sz := bytes.size
  if sz % 8 != 0 then
    return .error s!"binary size not multiple of 8 (size={sz})"
  let n := sz / 8
  let mut acc : Array UInt64 := #[]
  for i in [0:n] do
    acc := acc.push (decodeU64AtLE bytes (i * 8))
  return .ok acc.toList
```

## Writing in Lean

```lean
private def u64BytesLE (u : UInt64) : Array UInt8 :=
  let rec go (k : Nat) (n : Nat) (acc : Array UInt8) : Array UInt8 :=
    match k with
    | 0 => acc
    | k + 1 =>
        let b : UInt8 := UInt8.ofNat (n % 256)
        go k (n / 256) (acc.push b)
  go 8 u.toNat #[]

private def encodeU64LEList (xs : List UInt64) : ByteArray :=
  let out : Array UInt8 := Id.run do
    let mut acc : Array UInt8 := #[]
    for x in xs do
      for b in u64BytesLE x do
        acc := acc.push b
    return acc
  ByteArray.mk out
```

## Verification

The protocol is verified by SHA256 hash comparison:

```lean
let shaInData ← sha256HexOfFileIO inData
let shaOutData ← sha256HexOfFileIO outData
if shaInData != shaOutData then
  return .error "sha256 mismatch"
```

This ensures byte-identical roundtrips through the Wolfram-Lean bridge.
