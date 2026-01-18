// Tactic Flow Data for HeytingLean.Crypto.QKD.BB84.copyAll_impossible
// Extracted from actual Lean 4 proof source

const tacticFlowData = {
  theorems: [
    {
      name: "copyAll_impossible",
      file: "HeytingLean/Crypto/QKD/BB84/Constructors.lean",
      description: "Proves that cloning all BB84 qubits is impossible (no-cloning theorem)",
      statement: "theorem copyAll_impossible : bb84TaskCT.impossible copyAll",
      nodes: [
        { id: "goal_0", type: "goal", label: "⊢ bb84TaskCT.impossible copyAll", depth: 0 },
        { id: "tactic_1", type: "tactic", label: "intro ⟨c, hc⟩", depth: 1 },
        { id: "hyp_2", type: "hypothesis", label: "c : BB84Ctor", depth: 2 },
        { id: "hyp_3", type: "hypothesis", label: "hc : BB84Implements c copyAll", depth: 2 },
        { id: "goal_4", type: "goal", label: "⊢ False", depth: 2 },
        { id: "tactic_5", type: "tactic", label: "exact not_implements_copyAll c hc", depth: 3 },
        { id: "qed_6", type: "qed", label: "QED", depth: 4 }
      ],
      edges: [
        { from: "goal_0", to: "tactic_1" },
        { from: "tactic_1", to: "hyp_2" },
        { from: "tactic_1", to: "hyp_3" },
        { from: "tactic_1", to: "goal_4" },
        { from: "goal_4", to: "tactic_5" },
        { from: "tactic_5", to: "qed_6" }
      ]
    },
    {
      name: "not_implements_copyAll",
      file: "HeytingLean/Crypto/QKD/BB84/Constructors.lean",
      description: "No BB84 constructor can implement copyAll task",
      statement: "theorem not_implements_copyAll (c : BB84Ctor) : ¬ BB84Implements c copyAll",
      nodes: [
        { id: "goal_0", type: "goal", label: "⊢ ¬ BB84Implements c copyAll", depth: 0 },
        { id: "tactic_1", type: "tactic", label: "intro h", depth: 1 },
        { id: "hyp_2", type: "hypothesis", label: "h : BB84Implements c copyAll", depth: 2 },
        { id: "goal_3", type: "goal", label: "⊢ False", depth: 2 },
        { id: "tactic_4", type: "tactic", label: "have hAllowed : AllowedArc (attrAll, attrAll)", depth: 3 },
        { id: "subgoal_5", type: "goal", label: "⊢ AllowedArc (attrAll, attrAll)", depth: 4 },
        { id: "tactic_6", type: "tactic", label: "apply bb84_implements_allowed_arcs h", depth: 5 },
        { id: "subgoal_7", type: "goal", label: "⊢ (attrAll, attrAll) ∈ copyAll.arcs", depth: 6 },
        { id: "tactic_8", type: "simp_trace", label: "simp [copyAll]", depth: 7 },
        { id: "hyp_9", type: "hypothesis", label: "hAllowed : AllowedArc (attrAll, attrAll)", depth: 3 },
        { id: "tactic_10", type: "tactic", label: "exact copyAll_arc_not_allowed hAllowed", depth: 4 },
        { id: "qed_11", type: "qed", label: "QED", depth: 5 }
      ],
      edges: [
        { from: "goal_0", to: "tactic_1" },
        { from: "tactic_1", to: "hyp_2" },
        { from: "tactic_1", to: "goal_3" },
        { from: "goal_3", to: "tactic_4" },
        { from: "tactic_4", to: "subgoal_5" },
        { from: "subgoal_5", to: "tactic_6" },
        { from: "tactic_6", to: "subgoal_7" },
        { from: "subgoal_7", to: "tactic_8" },
        { from: "tactic_4", to: "hyp_9" },
        { from: "hyp_9", to: "tactic_10" },
        { from: "tactic_10", to: "qed_11" }
      ]
    },
    {
      name: "copyZ_possible",
      file: "HeytingLean/Crypto/QKD/BB84/Constructors.lean",
      description: "Copying Z-basis qubits is possible (term-mode proof)",
      statement: "theorem copyZ_possible : bb84TaskCT.possible copyZ",
      nodes: [
        { id: "term_0", type: "app", label: "⟨BB84Ctor.copyZ, BB84Implements.copyZ⟩", depth: 0 },
        { id: "const_1", type: "const", label: "BB84Ctor.copyZ", depth: 1 },
        { id: "const_2", type: "const", label: "BB84Implements.copyZ", depth: 1 },
        { id: "qed_3", type: "qed", label: "QED (term-mode)", depth: 2 }
      ],
      edges: [
        { from: "term_0", to: "const_1" },
        { from: "term_0", to: "const_2" },
        { from: "const_1", to: "qed_3" },
        { from: "const_2", to: "qed_3" }
      ]
    },
    {
      name: "copyX_possible",
      file: "HeytingLean/Crypto/QKD/BB84/Constructors.lean",
      description: "Copying X-basis qubits is possible (term-mode proof)",
      statement: "theorem copyX_possible : bb84TaskCT.possible copyX",
      nodes: [
        { id: "term_0", type: "app", label: "⟨BB84Ctor.copyX, BB84Implements.copyX⟩", depth: 0 },
        { id: "const_1", type: "const", label: "BB84Ctor.copyX", depth: 1 },
        { id: "const_2", type: "const", label: "BB84Implements.copyX", depth: 1 },
        { id: "qed_3", type: "qed", label: "QED (term-mode)", depth: 2 }
      ],
      edges: [
        { from: "term_0", to: "const_1" },
        { from: "term_0", to: "const_2" },
        { from: "const_1", to: "qed_3" },
        { from: "const_2", to: "qed_3" }
      ]
    },
    {
      name: "bb84_implements_allowed_arcs",
      file: "HeytingLean/Crypto/QKD/BB84/Constructors.lean",
      description: "Implementation implies allowed arcs",
      statement: "theorem bb84_implements_allowed_arcs : BB84Implements c t → ∀ a ∈ t.arcs, AllowedArc a",
      nodes: [
        { id: "goal_0", type: "goal", label: "⊢ ∀ a ∈ t.arcs, AllowedArc a", depth: 0 },
        { id: "tactic_1", type: "tactic", label: "induction c (on BB84Ctor)", depth: 1 },
        { id: "case_2", type: "goal", label: "case copyZ", depth: 2 },
        { id: "case_3", type: "goal", label: "case copyX", depth: 2 },
        { id: "case_4", type: "goal", label: "case seq", depth: 2 },
        { id: "case_5", type: "goal", label: "case par", depth: 2 },
        { id: "tactic_6", type: "tactic", label: "intro a ha; simp; exact AllowedArc.zz", depth: 3 },
        { id: "tactic_7", type: "tactic", label: "intro a ha; simp; exact AllowedArc.xx", depth: 3 },
        { id: "tactic_8", type: "tactic", label: "apply IH recursively", depth: 3 },
        { id: "tactic_9", type: "tactic", label: "apply IH recursively", depth: 3 },
        { id: "qed_10", type: "qed", label: "QED", depth: 4 }
      ],
      edges: [
        { from: "goal_0", to: "tactic_1" },
        { from: "tactic_1", to: "case_2" },
        { from: "tactic_1", to: "case_3" },
        { from: "tactic_1", to: "case_4" },
        { from: "tactic_1", to: "case_5" },
        { from: "case_2", to: "tactic_6" },
        { from: "case_3", to: "tactic_7" },
        { from: "case_4", to: "tactic_8" },
        { from: "case_5", to: "tactic_9" },
        { from: "tactic_6", to: "qed_10" },
        { from: "tactic_7", to: "qed_10" },
        { from: "tactic_8", to: "qed_10" },
        { from: "tactic_9", to: "qed_10" }
      ]
    }
  ]
};

// Node type colors (consistent with Apoth3osis brand)
const tacticFlowColors = {
  'goal': '#3b82f6',       // blue-500
  'hypothesis': '#10b981', // emerald-500
  'tactic': '#f59e0b',     // amber-500
  'simp_trace': '#8b5cf6', // violet-500
  'calc_step': '#06b6d4',  // cyan-500
  'qed': '#22c55e',        // green-500
  'app': '#3b82f6',        // blue-500
  'const': '#f59e0b'       // amber-500
};
