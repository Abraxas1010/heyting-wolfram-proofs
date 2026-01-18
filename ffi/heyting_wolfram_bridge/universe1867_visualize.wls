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

  (* Generate WolframModelPlot *)
  plot = WolframModelPlot[finalState,
    VertexSize -> 0.6,
    "HyperedgeRendering" -> "Polygons",
    PlotStyle -> ColorData["Rainbow"],
    Background -> Black,
    ImageSize -> 800
  ];

  Export[FileNameJoin[{outDir, "universe1867_hypergraph.png"}], plot];
  Print["Exported: universe1867_hypergraph.png"];

  (* Export evolution animation frames *)
  Do[
    frame = WolframModelPlot[statesList[[i]],
      VertexSize -> 0.6,
      "HyperedgeRendering" -> "Polygons",
      PlotStyle -> ColorData["Rainbow"],
      Background -> Black,
      ImageSize -> 600
    ];
    Export[FileNameJoin[{outDir, "frame_" <> ToString[i-1] <> ".png"}], frame];
  , {i, Min[Length[statesList], 8]}];
  Print["Exported evolution frames"];

  (* Use finalState for export *)
  hypergraph = finalState;

, (* Fallback without SetReplace *)
  Print["SetReplace not available, using manual evolution"];

  (* Manual evolution implementation *)
  matchAndReplace[edges_] := Module[{e1, e2, rest, a, b, c, fresh},
    (* Find two edges where e1.tgt = e2.src *)
    Do[
      Do[
        If[edges[[i, 2]] === edges[[j, 1]],
          e1 = edges[[i]];
          e2 = edges[[j]];
          rest = Delete[edges, {{i}, {j}}];
          a = e1[[1]]; b = e1[[2]]; c = e2[[2]];
          fresh = Max[Flatten[edges]] + 1;
          Return[rest ~Join~ {{b, c}, {b, c}, {c, fresh}, {a, c}}, Module]
        ];
      , {j, Length[edges]}];
    , {i, Length[edges]}];
    edges (* No match found *)
  ];

  evolve[init_, n_] := NestList[matchAndReplace, init, n];

  statesList = evolve[init1867, steps];
  finalState = Last[statesList];

  Print["Evolution complete (manual):"];
  Print["  Steps: ", steps];
  Print["  Final edges: ", Length[finalState]];
  Print[""];

  hypergraph = finalState;
];

(* ===================================== *)
(* Export to Bridge Binary Format        *)
(* ===================================== *)

(* Convert hypergraph to our format: each edge is [src, tgt] *)
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
  "edgeCount" -> Length[hyperedges],
  "vertexCount" -> Length[vertices],
  "root" -> Max[vertices],
  "nodes" -> nodeList
|>;

Export[FileNameJoin[{outDir, "universe1867_metadata.json"}], metadata, "RawJSON"];
Print["Exported: universe1867_metadata.json"];

(* ===================================== *)
(* Generate 2D Visualization (fallback)  *)
(* ===================================== *)

If[!hasSetReplace,
  (* Create graph visualization *)
  edges = DirectedEdge @@@ hypergraph;
  g = Graph[edges,
    VertexStyle -> Directive[White, EdgeForm[{Thin, Gray}]],
    VertexSize -> 0.5,
    VertexLabels -> Placed["Name", Center],
    EdgeStyle -> Directive[Opacity[0.6], Thickness[0.003]],
    Background -> Black,
    GraphLayout -> "SpringElectricalEmbedding",
    ImageSize -> 800
  ];
  Export[FileNameJoin[{outDir, "universe1867_hypergraph.png"}], g];
  Print["Exported: universe1867_hypergraph.png (graph mode)"];
];

(* ===================================== *)
(* Generate 3D Visualization             *)
(* ===================================== *)

edges3D = DirectedEdge @@@ hypergraph;
g3D = Graph3D[edges3D,
  VertexStyle -> Directive[Cyan, Specularity[White, 30]],
  VertexSize -> 0.4,
  EdgeStyle -> Directive[Opacity[0.5], Thickness[0.002], GrayLevel[0.7]],
  Background -> Black,
  GraphLayout -> "SpringElectricalEmbedding"
];

Export[FileNameJoin[{outDir, "universe1867_3d.png"}], g3D];
Print["Exported: universe1867_3d.png"];

Export[FileNameJoin[{outDir, "universe1867.x3d"}], g3D];
Print["Exported: universe1867.x3d"];

Print[""];
Print["Done. Output in: ", outDir];

Exit[0];
