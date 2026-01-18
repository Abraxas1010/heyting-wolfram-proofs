#!/usr/bin/env wolframscript

(* ============================================= *)
(* Lean proof term hypergraph visualization       *)
(* Wolfram Physics style via WolframModelPlot     *)
(* ============================================= *)

readInt64List[path_String] := Module[{stream, data},
  stream = OpenRead[path, BinaryFormat -> True, ByteOrdering -> -1];
  If[stream === $Failed, Return[$Failed]];
  data = BinaryReadList[stream, "Integer64"];
  Close[stream];
  data
];

reconstructHypergraph[data_List, lengths_List] := TakeList[data, lengths];

args = Rest[$ScriptCommandLine];
If[Length[args] < 4,
  Print["Usage: proof_hypergraph_visualize.wls <data.bin> <lengths.bin> <metadata.json> <outDir>"];
  Exit[2];
];

dataPath = args[[1]];
lengthsPath = args[[2]];
metaPath = args[[3]];
outDir = args[[4]];

If[!FileExistsQ[dataPath] || !FileExistsQ[lengthsPath] || !FileExistsQ[metaPath],
  Print["ERROR: missing input file(s)."];
  Print["  data:   ", dataPath];
  Print["  lens:   ", lengthsPath];
  Print["  meta:   ", metaPath];
  Exit[2];
];

CreateDirectory[outDir, CreateIntermediateDirectories -> True];

data = readInt64List[dataPath];
lengths = readInt64List[lengthsPath];
If[data === $Failed || lengths === $Failed,
  Print["ERROR: failed to read binary inputs."];
  Exit[1];
];

hyper = reconstructHypergraph[data, lengths];
meta = Quiet @ Check[Import[metaPath, "RawJSON"], $Failed];
If[meta === $Failed,
  Print["ERROR: failed to parse metadata JSON: ", metaPath];
  Exit[1];
];

modelKey = Lookup[meta, "model", FileBaseName[dataPath]];
rootId = Lookup[meta, "root", Missing["NoRoot"]];

nodes = Lookup[meta, "nodes", {}];
labelAssoc = Association @ Map[
  (ToExpression[Lookup[#, "id", -1]] -> Lookup[#, "label", ""]) &,
  nodes
];
kindAssoc = Association @ Map[
  (ToExpression[Lookup[#, "id", -1]] -> Lookup[#, "kind", ""]) &,
  nodes
];

labelOf[v_] := Module[{lbl = Lookup[labelAssoc, v, ""]},
  If[StringLength[lbl] > 0,
    lbl,
    ToString[v]
  ]
];

shortLabelOf[v_] := Module[{lbl = labelOf[v]},
  If[StringLength[lbl] > 24, StringTake[lbl, 21] <> "…", lbl]
];

(* Hypergraph plot - Wolfram Physics style *)
(* Load SetReplace with proper context handling to avoid symbol conflicts *)
setReplaceOk = Quiet @ Check[
  Block[{$ContextPath = $ContextPath},
    PacletInstall["SetReplace", "UpdatePacletSites" -> False];
    Needs["SetReplace`"];
  ];
  TrueQ[MatchQ[WolframModelPlot, _Symbol]],
  False
];

Print["SetReplace loaded: ", setReplaceOk];

(* Wolfram Physics dark theme styling *)
darkBackground = RGBColor[0.05, 0.05, 0.05];
vertexColor = RGBColor[0.95, 0.95, 0.95];

(* Custom color function for hyperedges like Wolfram Physics gallery *)
edgeColorFunc = ColorData["Rainbow"];

(* 2D Wolfram Physics style hypergraph *)
hgPlot =
  If[setReplaceOk,
    WolframModelPlot[
      hyper,
      VertexSize -> 0.4,
      "EdgePolygonStyle" -> Opacity[0.2],
      VertexStyle -> Directive[vertexColor, EdgeForm[None]],
      VertexLabels -> None,  (* Remove labels for cleaner look *)
      Background -> darkBackground,
      ImageSize -> 800,
      PlotRangePadding -> Scaled[0.1]
    ],
    (* Fallback to HypergraphPlot if SetReplace not available *)
    HypergraphPlot[
      hyper,
      VertexLabels -> None,
      VertexStyle -> vertexColor,
      Background -> darkBackground,
      ImageSize -> 800
    ]
  ];

Export[FileNameJoin[{outDir, modelKey <> "_term_hypergraph.png"}], hgPlot];
Print["Exported: ", modelKey <> "_term_hypergraph.png"];

(* Also export a labeled version for reference *)
hgPlotLabeled =
  If[setReplaceOk,
    WolframModelPlot[
      hyper,
      VertexSize -> 0.3,
      "EdgePolygonStyle" -> Opacity[0.15],
      VertexStyle -> Directive[vertexColor, EdgeForm[None]],
      VertexLabels -> Placed[
        Thread[Union[Flatten[hyper]] -> (Style[shortLabelOf[#], 6, White] & /@ Union[Flatten[hyper]])],
        Tooltip
      ],
      Background -> darkBackground,
      ImageSize -> 1200,
      PlotRangePadding -> Scaled[0.1]
    ],
    HypergraphPlot[
      hyper,
      VertexLabels -> Placed[
        Thread[Union[Flatten[hyper]] -> (Tooltip[shortLabelOf[#], labelOf[#]] & /@ Union[Flatten[hyper]])],
        Center
      ],
      Background -> darkBackground,
      ImageSize -> 1200
    ]
  ];

Export[FileNameJoin[{outDir, modelKey <> "_term_hypergraph_labeled.png"}], hgPlotLabeled];
Print["Exported: ", modelKey <> "_term_hypergraph_labeled.png"];

(* 3D version using Graph3D for X3D export compatibility *)
(* Convert hyperedges to directed edges for 3D visualization *)
dirEdges3D = DeleteDuplicates @ Flatten[
  Table[
    DirectedEdge[child, Last[edge]],
    {edge, hyper},
    {child, Most[edge]}
  ],
  1
];

(* Build 3D proof graph using Graph3D for proper 3D embedding *)
vertices3D = Union[Flatten[hyper]];
graph3D = Graph3D[dirEdges3D, GraphLayout -> "SpringElectricalEmbedding"];
vertexCoords3D = Association @ Thread[
  VertexList[graph3D] -> GraphEmbedding[graph3D]
];

(* Create 3D graphics with spheres and tubes *)
hgPlot3D = Graphics3D[{
  (* Vertices as glowing spheres *)
  White, Specularity[White, 20],
  Table[
    With[{pos = vertexCoords3D[v]},
      {Sphere[pos, 0.03]}
    ],
    {v, vertices3D}
  ],
  (* Edges as tubes *)
  GrayLevel[0.5], Opacity[0.7],
  Table[
    With[{
      p1 = vertexCoords3D[edge[[1]]],
      p2 = vertexCoords3D[edge[[2]]]
    },
      Tube[{p1, p2}, 0.008]
    ],
    {edge, dirEdges3D}
  ]
},
  Background -> Black,
  Lighting -> {{"Ambient", White}, {"Directional", White, {1, 1, 1}}},
  ImageSize -> 800,
  ViewPoint -> {2, 2, 2},
  Boxed -> False
];

(* Export as X3D for 3D/VR viewing *)
Export[FileNameJoin[{outDir, modelKey <> "_term_hypergraph.x3d"}], hgPlot3D];
Print["Exported: ", modelKey <> "_term_hypergraph.x3d"];

(* Also export a high-quality PNG of 3D view *)
Export[FileNameJoin[{outDir, modelKey <> "_term_hypergraph_3d.png"}], hgPlot3D];
Print["Exported: ", modelKey <> "_term_hypergraph_3d.png"];

(* Directed "proof DAG" view: premise → parent (parent = last vertex in each hyperedge). *)
dirEdges = Flatten[
  Table[
    DirectedEdge[child, Last[edge]],
    {edge, hyper},
    {child, Most[edge]}
  ],
  1
];

(* Color nodes by kind *)
kindColors = <|
  "lam" -> RGBColor[0.4, 0.7, 0.9],     (* cyan for lambda *)
  "app" -> RGBColor[0.6, 0.4, 0.9],     (* purple for app *)
  "const" -> RGBColor[0.9, 0.6, 0.1],   (* orange for const *)
  "bvar" -> RGBColor[0.4, 0.9, 0.4],    (* green for bound var *)
  "mdata" -> RGBColor[0.5, 0.5, 0.5]    (* gray for metadata *)
|>;

nodeColorOf[v_] := Lookup[kindColors, Lookup[kindAssoc, v, ""], White];

dagPlot =
  Graph[
    DeleteDuplicates[dirEdges],
    VertexLabels -> (v_ :> Placed[Style[shortLabelOf[v], 8, White], Above]),
    VertexStyle -> (v_ :> Directive[nodeColorOf[v], EdgeForm[{Thin, GrayLevel[0.3]}]]),
    VertexSize -> 0.4,
    EdgeStyle -> Directive[GrayLevel[0.4], Arrowheads[0.02]],
    GraphLayout -> "LayeredDigraphEmbedding",
    Background -> darkBackground,
    ImageSize -> 1000,
    ImagePadding -> 30
  ];

Export[FileNameJoin[{outDir, modelKey <> "_term_dag.png"}], dagPlot];
Print["Exported: ", modelKey <> "_term_dag.png"];

(* 3D DAG visualization for the proof structure *)
dagGraph3D = Graph3D[DeleteDuplicates[dirEdges], GraphLayout -> "SpringElectricalEmbedding"];
dagCoords3D = Association @ Thread[
  VertexList[dagGraph3D] -> GraphEmbedding[dagGraph3D]
];

dagPlot3D = Graphics3D[{
  (* Vertices as colored spheres based on node kind *)
  Table[
    With[{pos = dagCoords3D[v], col = nodeColorOf[v]},
      {col, Specularity[White, 20], Sphere[pos, 0.04]}
    ],
    {v, Keys[dagCoords3D]}
  ],
  (* Directed edges as tubes with arrows *)
  GrayLevel[0.4], Opacity[0.8],
  Table[
    With[{
      p1 = dagCoords3D[edge[[1]]],
      p2 = dagCoords3D[edge[[2]]]
    },
      {Tube[{p1, p2}, 0.01],
       (* Arrow tip *)
       Cone[{p2 - 0.05 * Normalize[p2 - p1], p2}, 0.02]}
    ],
    {edge, DeleteDuplicates[dirEdges]}
  ]
},
  Background -> Black,
  Lighting -> {{"Ambient", White}, {"Directional", White, {1, 1, 1}}},
  ImageSize -> 800,
  ViewPoint -> {2, 2, 2},
  Boxed -> False
];

Export[FileNameJoin[{outDir, modelKey <> "_term_dag.x3d"}], dagPlot3D];
Print["Exported: ", modelKey <> "_term_dag.x3d"];

Export[FileNameJoin[{outDir, modelKey <> "_term_dag_3d.png"}], dagPlot3D];
Print["Exported: ", modelKey <> "_term_dag_3d.png"];

(* Optional: collapsed constant-dependency view if present. *)
constMetaFiles = FileNames["*_constdeps_metadata.json", outDir];
If[Length[constMetaFiles] >= 1,
  constMeta = Quiet @ Check[Import[First[constMetaFiles], "RawJSON"], $Failed];
  If[constMeta =!= $Failed,
    constModel = Lookup[constMeta, "model", "constdeps"];
    constLabels = Lookup[constMeta, "labels", {}];
    constDataFiles = FileNames["*_constdeps_hypergraph.bin", outDir];
    constLenFiles = FileNames["*_constdeps_lengths.bin", outDir];
    If[Length[constDataFiles] >= 1 && Length[constLenFiles] >= 1,
      cdata = readInt64List[First[constDataFiles]];
      clens = readInt64List[First[constLenFiles]];
      cedges = reconstructHypergraph[cdata, clens];
      labelConst[v_] := Module[{i = v + 1},
        If[1 <= i <= Length[constLabels], constLabels[[i]], ToString[v]]
      ];
      cdir = DirectedEdge @@@ cedges;
      cplot =
        Graph[
          DeleteDuplicates[cdir],
          VertexLabels -> (v_ :> Placed[Style[labelConst[v], 10, White], Above]),
          VertexStyle -> Directive[RGBColor[0.9, 0.6, 0.1], EdgeForm[{Thin, GrayLevel[0.3]}]],
          VertexSize -> 0.5,
          EdgeStyle -> Directive[GrayLevel[0.4], Arrowheads[0.03]],
          GraphLayout -> "LayeredDigraphEmbedding",
          Background -> darkBackground,
          ImageSize -> 1000,
          ImagePadding -> 40
        ];
      Export[FileNameJoin[{outDir, constModel <> "_dag.png"}], cplot];
    ];
  ];
];

If[rootId =!= Missing["NoRoot"],
  Export[FileNameJoin[{outDir, modelKey <> "_root.txt"}], ToString[rootId], "Text"];
];

Exit[0];

