(* scratch/test_scaling_formula.wl *)
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

idxList = {{m[1], m[2]}, {m[3], m[4]}};
tag = 2;

tpWithU = GenTensorProjection[idxList, tag, "krep" -> {d2[1, tag] -> u}];
tpWith1 = GenTensorProjection[idxList, tag, "krep" -> {d2[1, tag] -> 1}];

Do[
  Print["\n=== Element ", j, " ==="];
  Print["U version: ", InputForm[tpWithU[[1, j]]]];
  Print["1 version: ", InputForm[tpWith1[[1, j]]]];
  ratio = tpWithU[[1, j]] / tpWith1[[1, j]] // Simplify;
  Print["Ratio (U/1): ", InputForm[ratio]];
, {j, 1, Length[tpWithU[[1]]]}];
