(* scratch/test_u_scaling.wl *)
$HistoryLength = 0;
rootDir = "/Users/windfolgen/Documents/AntiGravity/svbwalkthrough";
asymDir = FileNameJoin[{rootDir, "asym"}];

Get["LiteRed2`"];
SetDim[d];
Declare[{l1, l2, l3, l4, p}, Vector, {u}, Number];
SetConstraints[{p}, sp[p, p] = u];

Do[
  Get[FileNameJoin[{asymDir, "Bases", b, b}]];
  Quiet[ExecuteDefinitions[ToExpression[b]]];
, {b, {"asym", "asym3L", "asym2L", "asym1L"}}];

Get[FileNameJoin[{asymDir, "asym_new.wl"}]];

(* Rank 4 shape: {2, 2} *)
idxList = {{m[1], m[2]}, {m[3], m[4]}};
tag = 2;

Print["Running GenTensorProjection with u..."];
t0 = SessionTime[];
tpWithU = GenTensorProjection[idxList, tag, "krep" -> {d2[1, tag] -> u}];
Print["Done in ", SessionTime[] - t0, "s"];

Print["Running GenTensorProjection with u -> 1..."];
t0 = SessionTime[];
tpWith1 = GenTensorProjection[idxList, tag, "krep" -> {d2[1, tag] -> 1}];
Print["Done in ", SessionTime[] - t0, "s"];

matU = tpWithU[[1]];
mat1 = tpWith1[[1]];
tensor = tpWithU[[2]];
l = Length[tensor];

(* Count vector occurrences in each tensor basis element *)
kList = Table[
  Module[{expanded = Expand[tensor[[i]]], firstTerm},
    firstTerm = If[Head[expanded] === Plus, expanded[[1]], expanded];
    Length[Cases[{firstTerm}, vc[tag, _], Infinity]]
  ],
  {i, 1, l}
];

Print["kList: ", kList];

(* Scale tpWith1[[1]] and compare *)
tpReconstructed = Table[
  mat1[[j]] * u^(-kList[[j]]/2),
  {j, 1, l}
];

diff = matU - tpReconstructed // Expand // Simplify;
Print["Max difference: ", Max[Abs[diff /. {d -> 4, u -> 2}]]];
Print["Are they algebraically identical? ", diff === Table[0, {l}]];
