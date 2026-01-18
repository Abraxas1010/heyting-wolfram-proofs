// UMAP-style data for proof constant dependencies
// Positions computed from proof term depth and dependency structure

const wolframProofsData = {
  items: [
    // Main theorem (center)
    { name: "copyAll_impossible", kind: "theorem", family: "QKD/BB84", pos: { x: 0.5, y: 0.2, z: 0.5 } },

    // Core type theory (left cluster)
    { name: "False", kind: "type", family: "Core", pos: { x: 0.15, y: 0.4, z: 0.3 } },
    { name: "TaskCT.Ctor", kind: "structure", family: "Constructor", pos: { x: 0.25, y: 0.5, z: 0.4 } },
    { name: "TaskCT.implements", kind: "def", family: "Constructor", pos: { x: 0.3, y: 0.6, z: 0.35 } },
    { name: "TaskCT.possible", kind: "def", family: "Constructor", pos: { x: 0.35, y: 0.55, z: 0.45 } },

    // BB84 protocol (right cluster)
    { name: "BB84Substrate", kind: "structure", family: "QKD/BB84", pos: { x: 0.7, y: 0.45, z: 0.5 } },
    { name: "bb84TaskCT", kind: "def", family: "QKD/BB84", pos: { x: 0.75, y: 0.55, z: 0.55 } },
    { name: "copyAll", kind: "def", family: "QKD/BB84", pos: { x: 0.8, y: 0.5, z: 0.6 } },

    // Supporting lemmas (bottom)
    { name: "match_1_1", kind: "aux", family: "QKD/BB84", pos: { x: 0.55, y: 0.75, z: 0.4 } },
    { name: "not_implements_copyAll", kind: "lemma", family: "QKD/BB84", pos: { x: 0.6, y: 0.85, z: 0.5 } }
  ],
  edges: [
    // Dependencies to main theorem
    [1, 0], [2, 0], [3, 0], [4, 0], [5, 0], [6, 0], [7, 0], [8, 0], [9, 0]
  ]
};

// Color scheme for families
const familyColors = {
  'Core': '#ef4444',
  'Constructor': '#8b5cf6',
  'QKD/BB84': '#f59e0b'
};

// Node type shapes
const kindShapes = {
  'theorem': 'hexagon',
  'lemma': 'diamond',
  'def': 'rect',
  'structure': 'ellipse',
  'type': 'circle',
  'aux': 'triangle'
};
