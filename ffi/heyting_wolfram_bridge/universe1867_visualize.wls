#!/usr/bin/env wolframscript

(* ============================================================ *)
(* Universe 1867 Visualization                                    *)
(* Wolfram Physics Project → Lean 4 Bridge Demo                  *)
(*                                                                *)
(* Source: https://www.wolframphysics.org/universes/wm1867/       *)
(* Rule: {{{1,2},{2,3}} -> {{2,3},{2,3},{3,4},{1,3}}}            *)
(* Initial: {{1,1},{1,1}}                                         *)
(* Steps: 7 generations                                           *)
(* ============================================================ *)

Print["Universe 1867 Hypergraph Evolution"];
Print["====================================="];
Print["Rule: {{{1,2},{2,3}} -> {{2,3},{2,3},{3,4},{1,3}}}"];
Print["Initial: {{1,1},{1,1}}"];
Print[""];

(* Universe 1867 specification *)
rule1867 = {{{1, 2}, {2, 3}} -> {{2, 3}, {2, 3}, {3, 4}, {1, 3}}};
init1867 = {{1, 1}, {1, 1}};
steps = 7;

args = Rest[$ScriptCommandLine];
outDir = If[Length[args] >= 1, args[[1]], ".tmp/universe1867"];
CreateDirectory[outDir, CreateIntermediateDirectories -> True];

(* Try to load SetReplace for WolframModel *)
Quiet[Check[
  PacletInstall["SetReplace", AllowVersionUpdate -> False];
  << SetReplace`;
  hasSetReplace = True;
, hasSetReplace = False]];

If[hasSetReplace,
  Print["Using SetReplace package for WolframModel"];

  (* Evolve using WolframModel *)
  model = WolframModel[rule1867, init1867, steps];
  finalState = model["FinalState"];
  statesList = model["StatesList"];
  eventCount = model["EventsCount"];

  Print["Evolution complete:"];
  Print["  Steps: ", steps];
  Print["  Events: ", eventCount];
  Print["  Final edges: ", Length[finalState]];
  Print["  Final vertices: ", Length[Union[Flatten[finalState]]]];
  Print[""];

  (* Generate proper WolframModelPlot with visible colors *)
  plot = WolframModelPlot[finalState,
    VertexSize -> 0.5,
    "HyperedgeRendering" -> "Subgraphs",
    EdgeStyle -> Directive[Opacity[0.7], Thickness[0.003]],
    VertexStyle -> Directive[White, EdgeForm[{Thin, Gray}]],
    Background -> RGBColor[0.05, 0.05, 0.05],
    ImageSize -> 800,
    PlotRangePadding -> Scaled[0.1]
  ];

  Export[FileNameJoin[{outDir, "universe1867_hypergraph.png"}], plot];
  Print["Exported: universe1867_hypergraph.png"];

  (* Export evolution animation frames with proper styling *)
  Do[
    frame = WolframModelPlot[statesList[[i]],
      VertexSize -> 0.6,
      "HyperedgeRendering" -> "Subgraphs",
      EdgeStyle -> Directive[Opacity[0.8], Thickness[0.004]],
      VertexStyle -> Directive[Cyan, EdgeForm[{Thin, White}]],
      Background -> RGBColor[0.05, 0.05, 0.05],
      ImageSize -> 400,
      PlotRangePadding -> Scaled[0.15]
    ];
    Export[FileNameJoin[{outDir, "frame_" <> ToString[i-1] <> ".png"}], frame];
  , {i, Min[Length[statesList], 8]}];
  Print["Exported evolution frames"];

  hypergraph = finalState;

, (* Fallback without SetReplace - use Graph visualization *)
  Print["SetReplace not available, using Graph-based visualization"];

  (* Manual evolution - apply all matches per generation *)
  findAllMatches[edges_] := Module[{matches = {}},
    Do[
      Do[
        If[i != j && edges[[i, 2]] === edges[[j, 1]],
          AppendTo[matches, {i, j}];
        ];
      , {j, Length[edges]}];
    , {i, Length[edges]}];
    matches
  ];

  applyAllMatches[edges_] := Module[{matches, newEdges, usedIndices, fresh},
    matches = findAllMatches[edges];
    If[Length[matches] == 0, Return[edges]];

    fresh = Max[Flatten[edges]] + 1;
    newEdges = {};
    usedIndices = {};

    Do[
      {i, j} = match;
      If[!MemberQ[usedIndices, i] && !MemberQ[usedIndices, j],
        AppendTo[usedIndices, i];
        AppendTo[usedIndices, j];
        {a, b} = edges[[i]];
        {_, c} = edges[[j]];
        newEdges = Join[newEdges, {{b, c}, {b, c}, {c, fresh}, {a, c}}];
        fresh++;
      ];
    , {match, matches}];

    Join[Delete[edges, List /@ usedIndices], newEdges]
  ];

  statesList = NestList[applyAllMatches, init1867, steps];
  finalState = Last[statesList];
  eventCount = Total[Length[findAllMatches[#]] & /@ Most[statesList]];

  Print["Evolution complete (manual):"];
  Print["  Steps: ", steps];
  Print["  Events: ~", eventCount];
  Print["  Final edges: ", Length[finalState]];
  Print[""];

  hypergraph = finalState;
];

(* ===================================== *)
(* Export to Bridge Binary Format        *)
(* ===================================== *)

hyperedges = hypergraph;

(* Write binary files *)
flatData = Flatten[hyperedges];
lengths = Length /@ hyperedges;

BinaryWrite[FileNameJoin[{outDir, "universe1867_hypergraph.bin"}], flatData, "Integer64"];
BinaryWrite[FileNameJoin[{outDir, "universe1867_lengths.bin"}], lengths, "Integer64"];

Print["Exported binary: universe1867_hypergraph.bin, universe1867_lengths.bin"];

(* Write metadata JSON *)
vertices = Union[Flatten[hyperedges]];
nodeList = Map[
  <|"id" -> #, "label" -> ToString[#], "kind" -> "vertex"|> &,
  vertices
];

metadata = <|
  "model" -> "universe1867",
  "source" -> "https://www.wolframphysics.org/universes/wm1867/",
  "rule" -> "{{{1,2},{2,3}} -> {{2,3},{2,3},{3,4},{1,3}}}",
  "initial" -> "{{1,1},{1,1}}",
  "steps" -> steps,
  "events" -> eventCount,
  "edgeCount" -> Length[hyperedges],
  "vertexCount" -> Length[vertices],
  "root" -> Max[vertices],
  "nodes" -> nodeList
|>;

Export[FileNameJoin[{outDir, "universe1867_metadata.json"}], metadata, "RawJSON"];
Print["Exported: universe1867_metadata.json"];

(* ===================================== *)
(* Generate Graph-based 2D Visualization *)
(* (Fallback that always works)          *)
(* ===================================== *)

edges2D = DirectedEdge @@@ hypergraph;
g2D = Graph[edges2D,
  VertexStyle -> Directive[Cyan, EdgeForm[{Thin, White}]],
  VertexSize -> 0.3,
  VertexLabels -> Placed["Name", Center],
  VertexLabelStyle -> Directive[8, White],
  EdgeStyle -> Directive[Opacity[0.5], Thickness[0.002],
    Blend[{Orange, Red}, 0.5]],
  Background -> RGBColor[0.05, 0.05, 0.05],
  GraphLayout -> "SpringElectricalEmbedding",
  ImageSize -> 800,
  ImagePadding -> 20
];

Export[FileNameJoin[{outDir, "universe1867_graph.png"}], g2D];
Print["Exported: universe1867_graph.png"];

(* ===================================== *)
(* Generate 3D Visualization             *)
(* ===================================== *)

edges3D = DirectedEdge @@@ hypergraph;
g3D = Graph3D[edges3D,
  VertexStyle -> Directive[Cyan, Specularity[White, 30]],
  VertexSize -> 0.3,
  EdgeStyle -> Directive[Opacity[0.4], Thickness[0.002], Orange],
  Background -> Black,
  GraphLayout -> "SpringElectricalEmbedding",
  ImageSize -> 800
];

Export[FileNameJoin[{outDir, "universe1867_3d.png"}], g3D];
Print["Exported: universe1867_3d.png"];

(* Export edge list for JavaScript viewer *)
edgeListJS = Map[{#[[1]], #[[2]]} &, hypergraph];
Export[FileNameJoin[{outDir, "universe1867_edges.json"}], edgeListJS, "RawJSON"];
Print["Exported: universe1867_edges.json"];

Print[""];
Print["Done. Output in: ", outDir];

Exit[0];
