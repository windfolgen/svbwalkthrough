(* ::Package:: *)

$HistoryLength = 0;
rootDir = "/Users/windfolgen/Documents/AntiGravity/svbwalkthrough";
SetDirectory[rootDir];

Get[FileNameJoin[{rootDir, "config.wl"}]];
Get[FileNameJoin[{rootDir, "asym", "boundary_agent", "boundary_agent.wl"}]];
Get[FileNameJoin[{rootDir, "series_agent", "series_agent.wl"}]];
Get[FileNameJoin[{rootDir, "solve_agent", "solve_agent.wl"}]];
Get[FileNameJoin[{rootDir, "workflow_engine.wl"}]];

Get["LiteRed2`"];
SetDim[d];
Declare[{l1, l2, l3, l4, vecP}, Vector, {u}, Number];
SetConstraints[{vecP}, sp[vecP, vecP] = u];
Do[
  Get[FileNameJoin[{rootDir, "asym", "Bases", b, b}]];
  Quiet[ExecuteDefinitions[ToExpression[b]]];
, {b, $LiteRedBases}];

Get[FileNameJoin[{rootDir, "asym", "asym_new.wl"}]];

integrand = (x[1,7] x[2,4] x[3,4] x[5,6])/(x[1,5] x[1,6] x[2,5] x[2,7] x[3,6] x[3,7] x[4,5] x[4,6] x[4,8] x[5,7] x[5,8] x[6,7] x[6,8] x[7,8]);
perm = {2, 1, 3, 4};
loops = {5, 6, 7, 8};
order = 4;

intCase = integrand /. {x[a__] :> (x[a] /. Thread@Rule[{1, 2, 3, 4}, perm])};
Print["Performing RegionExpand..."];
exp = RegionExpand[intCase, loops, "order" -> order, "check" -> True];
{topVal, top1, top2} = exp[[1]];
Print["Performing ToTensorProduct..."];
result = Flatten[ToTensorProduct[#, topVal, top1, top2, "check" -> True] & /@ (exp[[2]]), 1];

(* Load record *)
commonCache = FileNameJoin[{rootDir, "asym", "tmp", "cache_tensor_record_noremove.mx"}];
record = If[FileExistsQ[commonCache], Import[commonCache], {}];
If[Not[ListQ[record]], record = {}];

(* Extract all unique tensor structures *)
structures1 = {};
structures2 = {};

Do[
  vclist = {Cases[{result[[k, 2]]}, vc[__], Infinity] // DeleteDuplicates, Cases[{result[[k, 3]]}, vc[__], Infinity] // DeleteDuplicates};
  
  If[vclist[[1]] =!= {},
    tem1 = GatherBy[vclist[[1]], First] /. {vc[a_, b_] :> b} // SortBy[#, Length] &;
    AppendTo[structures1, tem1];
  ];
  If[vclist[[2]] =!= {},
    tem2 = GatherBy[vclist[[2]], First] /. {vc[a_, b_] :> b} // SortBy[#, Length] &;
    AppendTo[structures2, tem2];
  ];
, {k, 1, Length[result]}];

unique1 = DeleteDuplicates[structures1];
unique2 = DeleteDuplicates[structures2];
allUnique = DeleteDuplicates[Join[unique1, unique2]];

(* Find misses *)
misses = {};
Do[
  flag = FindTensor[s, record];
  If[!flag[[1]],
    AppendTo[misses, s]
  ];
, {s, allUnique}];

Print["Found ", Length[misses], " misses. Benchmarking them one by one..."];

Do[
  t0 = SessionTime[];
  Print["Benchmarking miss ", idx, " / ", Length[misses], ": ", InputForm[misses[[idx]]]];
  tp = GenTensorProjection[misses[[idx]], vecP, "krep" -> {d2[1, vecP] -> u}];
  dt = SessionTime[] - t0;
  Print["  Miss ", idx, " took ", dt, "s"];
, {idx, 1, Length[misses]}];

Print["All benchmarks finished."];
