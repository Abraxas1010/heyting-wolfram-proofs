#!/usr/bin/env wolframscript

(* ============================================= *)
(* Lean proof term hypergraph visualization       *)
(* Wolfram Physics style - works without SetReplace *)
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
  If[StringLength[lbl] > 0, lbl, ToString[v]]
];

shortLabelOf[v_] := Module[{lbl = labelOf[v]},
  If[StringLength[lbl] > 24, StringTake[lbl, 21] <> "\[Ellipsis]", lbl]
];

(* Wolfram Physics dark theme *)
darkBackground = RGBColor[0.05, 0.05, 0.05];

(* Color nodes by kind - Wolfram Physics palette *)
kindColors = <|
  "lam" -> RGBColor[0.4, 0.8, 1.0],      (* cyan for lambda *)
  "app" -> RGBColor[0.7, 0.4, 1.0],      (* purple for app *)
  "const" -> RGBColor[1.0, 0.6, 0.2],    (* orange for const *)
  "bvar" -> RGBColor[0.4, 1.0, 0.5],     (* green for bound var *)
  "fvar" -> RGBColor[0.5, 1.0, 0.5],     (* light green for free var *)
  "forall" -> RGBColor[1.0, 0.4, 0.6],   (* pink for forall *)
  "mdata" -> RGBColor[0.5, 0.5, 0.5],    (* gray for metadata *)
  "sort" -> RGBColor[1.0, 1.0, 0.4],     (* yellow for sort *)
  "let" -> RGBColor[0.6, 0.8, 1.0],      (* light blue for let *)
  "proj" -> RGBColor[0.8, 0.6, 0.4]      (* tan for proj *)
|>;

nodeColorOf[v_] := Lookup[kindColors, Lookup[kindAssoc, v, ""], White];

(* Convert hypergraph to directed edges for visualization *)
dirEdges = DeleteDuplicates @ Flatten[
  Table[
    DirectedEdge[child, Last[edge]],
    {edge, hyper},
    {child, Most[edge]}
  ],
  1
];

vertices = Union[Flatten[hyper]];

(* ========================================= *)
(* 2D HYPERGRAPH - Wolfram Physics Style    *)
(* Use GraphPlot with custom vertex/edge rendering *)
(* ========================================= *)

(* Create base graph for layout *)
baseGraph = Graph[dirEdges];
coords2D = AssociationThread[
  VertexList[baseGraph] -> GraphEmbedding[baseGraph, "SpringElectricalEmbedding"]
];

(* Rainbow colors for hyperedges like Wolfram Physics *)
numEdges = Length[hyper];
edgeColors = Table[ColorData["Rainbow"][i/numEdges], {i, numEdges}];

(* Draw hyperedges as filled polygons connecting vertices *)
hyperedgeGraphics2D = Table[
  Module[{pts, col, center},
    pts = coords2D /@ hyper[[i]];
    col = edgeColors[[i]];
    center = Mean[pts];
    (* Draw as semi-transparent polygon with border *)
    {Opacity[0.25], col, EdgeForm[{col, Thickness[0.003]}],
     If[Length[pts] >= 3,
       Polygon[pts],
       (* For 2-vertex edges, draw thick line *)
       {Opacity[0.6], Thickness[0.008], Line[pts]}
     ]}
  ],
  {i, numEdges}
];

(* Draw vertices as colored disks *)
vertexGraphics2D = Table[
  {nodeColorOf[v], EdgeForm[{White, Thickness[0.002]}],
   Disk[coords2D[v], 0.06]},
  {v, vertices}
];

(* Combine into full 2D plot *)
hgPlot = Graphics[
  {hyperedgeGraphics2D, vertexGraphics2D},
  Background -> darkBackground,
  ImageSize -> 800,
  PlotRange -> All,
  PlotRangePadding -> Scaled[0.1]
];

Export[FileNameJoin[{outDir, modelKey <> "_term_hypergraph.png"}], hgPlot];
Print["Exported: ", modelKey <> "_term_hypergraph.png"];

(* Labeled version *)
vertexLabels2D = Table[
  Text[Style[shortLabelOf[v], 7, White], coords2D[v] + {0, 0.12}],
  {v, vertices}
];

hgPlotLabeled = Graphics[
  {hyperedgeGraphics2D, vertexGraphics2D, vertexLabels2D},
  Background -> darkBackground,
  ImageSize -> 1200,
  PlotRange -> All,
  PlotRangePadding -> Scaled[0.15]
];

Export[FileNameJoin[{outDir, modelKey <> "_term_hypergraph_labeled.png"}], hgPlotLabeled];
Print["Exported: ", modelKey <> "_term_hypergraph_labeled.png"];

(* ========================================= *)
(* 3D HYPERGRAPH - Wolfram Physics Style    *)
(* ========================================= *)

graph3DHyper = Graph3D[dirEdges, GraphLayout -> "SpringElectricalEmbedding"];
coords3DHyper = AssociationThread[
  VertexList[graph3DHyper] -> GraphEmbedding[graph3DHyper]
];

(* Draw hyperedges as 3D surfaces/tubes *)
hyperedgeGraphics3D = Table[
  Module[{pts, col},
    pts = coords3DHyper /@ hyper[[i]];
    col = edgeColors[[i]];
    {Opacity[0.35], col,
     If[Length[pts] >= 3,
       (* Draw as mesh of triangles from centroid *)
       Module[{center = Mean[pts]},
         Table[
           Polygon[{pts[[j]], pts[[Mod[j, Length[pts]] + 1]], center}],
           {j, Length[pts]}
         ]
       ],
       (* For 2-vertex edges, draw tube *)
       {Opacity[0.7], Tube[pts, 0.02]}
     ]}
  ],
  {i, numEdges}
];

(* Draw vertices as spheres *)
vertexGraphics3DHyper = Table[
  {nodeColorOf[v], Specularity[White, 30], Sphere[coords3DHyper[v], 0.05]},
  {v, vertices}
];

hgPlot3D = Graphics3D[
  {hyperedgeGraphics3D, vertexGraphics3DHyper},
  Background -> Black,
  Lighting -> {{"Ambient", GrayLevel[0.3]}, {"Directional", White, {1, 1, 1}}},
  ImageSize -> 800,
  ViewPoint -> {2.5, 2, 1.5},
  Boxed -> False
];

Export[FileNameJoin[{outDir, modelKey <> "_term_hypergraph.x3d"}], hgPlot3D];
Print["Exported: ", modelKey <> "_term_hypergraph.x3d"];

Export[FileNameJoin[{outDir, modelKey <> "_term_hypergraph_3d.png"}], hgPlot3D];
Print["Exported: ", modelKey <> "_term_hypergraph_3d.png"];

(* ========================================= *)
(* 2D DAG - Layered Proof Structure         *)
(* ========================================= *)

dagPlot = Graph[
  dirEdges,
  VertexLabels -> (v_ :> Placed[Style[shortLabelOf[v], 8, White], Above]),
  VertexStyle -> (v_ :> Directive[nodeColorOf[v], EdgeForm[{Thin, GrayLevel[0.3]}]]),
  VertexSize -> 0.4,
  EdgeStyle -> Directive[GrayLevel[0.5], Arrowheads[0.02]],
  GraphLayout -> "LayeredDigraphEmbedding",
  Background -> darkBackground,
  ImageSize -> 1000,
  ImagePadding -> 30
];

Export[FileNameJoin[{outDir, modelKey <> "_term_dag.png"}], dagPlot];
Print["Exported: ", modelKey <> "_term_dag.png"];

(* ========================================= *)
(* 3D DAG - Different layout from hypergraph *)
(* Use layered embedding for tree structure  *)
(* ========================================= *)

(* Get 2D layered positions and add depth as Z *)
dagGraph2D = Graph[dirEdges, GraphLayout -> "LayeredDigraphEmbedding"];
layeredCoords = GraphEmbedding[dagGraph2D];
vertexListDAG = VertexList[dagGraph2D];

(* Convert 2D layered to 3D with some spread *)
coords3DDAG = AssociationThread[
  vertexListDAG -> Table[
    {layeredCoords[[i, 1]],
     layeredCoords[[i, 2]],
     0.3 * Sin[layeredCoords[[i, 1]]] + 0.2 * Cos[layeredCoords[[i, 2]]]},
    {i, Length[vertexListDAG]}
  ]
];

(* Draw directed edges as tubes with arrow cones *)
edgeGraphics3DDAG = Table[
  Module[{p1, p2, dir, len},
    p1 = coords3DDAG[edge[[1]]];
    p2 = coords3DDAG[edge[[2]]];
    dir = Normalize[p2 - p1];
    len = Norm[p2 - p1];
    {GrayLevel[0.5], Opacity[0.8],
     Tube[{p1, p2 - 0.08 * dir}, 0.015],
     (* Arrow cone *)
     Cone[{p2 - 0.12 * dir, p2 - 0.02 * dir}, 0.035]}
  ],
  {edge, dirEdges}
];

(* Draw vertices as colored spheres *)
vertexGraphics3DDAG = Table[
  {nodeColorOf[v], Specularity[White, 20],
   Sphere[coords3DDAG[v], 0.06]},
  {v, vertexListDAG}
];

dagPlot3D = Graphics3D[
  {edgeGraphics3DDAG, vertexGraphics3DDAG},
  Background -> Black,
  Lighting -> {{"Ambient", GrayLevel[0.4]}, {"Directional", White, {0, 1, 1}}},
  ImageSize -> 800,
  ViewPoint -> {3, 1, 2},
  Boxed -> False
];

Export[FileNameJoin[{outDir, modelKey <> "_term_dag.x3d"}], dagPlot3D];
Print["Exported: ", modelKey <> "_term_dag.x3d"];

Export[FileNameJoin[{outDir, modelKey <> "_term_dag_3d.png"}], dagPlot3D];
Print["Exported: ", modelKey <> "_term_dag_3d.png"];

(* ========================================= *)
(* Constant dependency graph if present     *)
(* ========================================= *)

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
      cplot = Graph[
        DeleteDuplicates[cdir],
        VertexLabels -> (v_ :> Placed[Style[labelConst[v], 10, White], Above]),
        VertexStyle -> Directive[RGBColor[1.0, 0.6, 0.2], EdgeForm[{Thin, GrayLevel[0.3]}]],
        VertexSize -> 0.5,
        EdgeStyle -> Directive[GrayLevel[0.5], Arrowheads[0.03]],
        GraphLayout -> "LayeredDigraphEmbedding",
        Background -> darkBackground,
        ImageSize -> 1000,
        ImagePadding -> 40
      ];
      Export[FileNameJoin[{outDir, constModel <> "_dag.png"}], cplot];
      Print["Exported: ", constModel <> "_dag.png"];
    ];
  ];
];

If[rootId =!= Missing["NoRoot"],
  Export[FileNameJoin[{outDir, modelKey <> "_root.txt"}], ToString[rootId], "Text"];
];

Print["Done."];
Exit[0];
