(* scratch/test_linearsolve_timing.wl *)
rootDir = "/Users/windfolgen/Documents/AntiGravity/svbwalkthrough";
asymDir = FileNameJoin[{rootDir, "asym"}];

(* Load LiteRed2 and define variables *)
Get["LiteRed2`"];
SetDim[d];
Declare[{l1, l2, l3, l4, p}, Vector, {u}, Number];
SetConstraints[{p}, sp[p, p] = u];

(* Load bases *)
Do[
  Get[FileNameJoin[{asymDir, "Bases", b, b}]];
  Quiet[ExecuteDefinitions[ToExpression[b]]];
, {b, {"asym", "asym3L", "asym2L", "asym1L"}}];

(* Load asymptotic expansion engine *)
Get[FileNameJoin[{asymDir, "asym_new.wl"}]];

(* Define optimized GenTensorProjectionNew *)
ClearAll[GenTensorProjectionNew];
Options[GenTensorProjectionNew] = {"krep" -> {}, "outputrank" -> 0};
GenTensorProjectionNew[indexlist_, tagp_, OptionsPattern[]] := Module[
  {tensor, l, M, sol, start, krep},
  start = SessionTime[];
  tensor = MPartition[indexlist, tagp];
  l = Length[tensor];
  krep = OptionValue["krep"];
  
  (* Construct symmetric matrix M *)
  M = Table[
    ((tensor[[i]] * tensor[[j]] // Expand) /. krep),
    {i, 1, l}, {j, 1, l}
  ];
  
  (* Solve using LinearSolve *)
  sol = LinearSolve[M, tensor];
  
  (* Factorize components *)
  Return[{Factor /@ sol, tensor}]
];

(* Dimension 24 index list *)
idxList = {{m[1], m[3]}, {m[2], m[5]}, {m[7], m[9]}};
tag = 2;

Print["Running GenTensorProjectionNew (LinearSolve) on dim 24..."];
t0 = SessionTime[];
resNew = GenTensorProjectionNew[idxList, tag, "krep" -> {d2[1, tag] -> u}];
tNew = SessionTime[] - t0;

Print["New method completed successfully!"];
Print["Basis size (L): ", Length[resNew[[2]]]];
Print["LinearSolve Time: ", tNew, "s"];
Print["First component: ", Short[resNew[[1, 1]], 5]];
