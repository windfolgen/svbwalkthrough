(* ::Package:: *)
$HistoryLength = 0;
rootDir = "/Users/windfolgen/Documents/AntiGravity/svbwalkthrough";
SetDirectory[rootDir];

Get[FileNameJoin[{rootDir, "config.wl"}]];
Get[FileNameJoin[{rootDir, "asym", "boundary_agent", "boundary_agent.wl"}]];
Get[FileNameJoin[{rootDir, "asym", "asym_new.wl"}]];

Get["LiteRed2`"];
SetDim[d];
Declare[{l1, l2, l3, l4, vecP}, Vector, {u}, Number];
SetConstraints[{vecP}, sp[vecP, vecP] = u];
Do[
  Get[FileNameJoin[{rootDir, "asym", "Bases", b, b}]];
  Quiet[ExecuteDefinitions[ToExpression[b]]];
, {b, $LiteRedBases}];

(* The 15 misses we found *)
misses = {
  {{m[1]}, {m[3]}, {m[5], m[7], m[9], m[11]}},
  {{m[3]}, {m[1], m[5]}, {m[7], m[9], m[11]}},
  {{m[2]}, {m[1], m[4]}, {m[6], m[8], m[10]}},
  {{m[3]}, {m[9], m[11]}, {m[1], m[5], m[7]}},
  {{m[1], m[4]}, {m[2], m[6]}, {m[8], m[10]}},
  {{m[3]}, {m[7], m[9]}, {m[1], m[2], m[5]}},
  {{m[3]}, {m[11]}, {m[1], m[5], m[7], m[9]}},
  {{m[10]}, {m[1], m[4]}, {m[2], m[6], m[8]}},
  {{m[9]}, {m[3], m[7]}, {m[1], m[2], m[5]}},
  {{m[4]}, {m[8]}, {m[1], m[2], m[3], m[6]}},
  {{m[3]}, {m[1], m[5], m[7], m[9], m[11]}},
  {{m[1], m[4]}, {m[2], m[6], m[8], m[10]}},
  {{m[1], m[2], m[5]}, {m[3], m[7], m[9]}},
  {{m[4], m[8]}, {m[1], m[2], m[3], m[6]}},
  {{m[5]}, {m[1], m[2], m[3], m[4], m[7]}}
};

Print["Launching 6 subkernels..."];
LaunchKernels[6];

Print["Loading packages on subkernels..."];
ParallelEvaluate[
  SetDirectory["/Users/windfolgen/Documents/AntiGravity/svbwalkthrough"];
  Get["LiteRed2`"];
  SetDim[d];
  Declare[{l1, l2, l3, l4, vecP}, Vector, {u}, Number];
  SetConstraints[{vecP}, sp[vecP, vecP] = u];
  Get["asym/asym_new.wl"];
];

Print["Computing 15 tensor projections in parallel..."];
results = ParallelTable[
  Print["Starting miss ", idx];
  t0 = SessionTime[];
  tp = GenTensorProjection[misses[[idx]], vecP, "krep" -> {d2[1, vecP] -> u}];
  Print["Finished miss ", idx, " in ", SessionTime[] - t0, "s"];
  {Length /@ misses[[idx]], misses[[idx]], tp}
, {idx, 1, Length[misses]}];

CloseKernels[];

(* Load existing cache *)
commonCache = FileNameJoin[{rootDir, "asym", "tmp", "cache_tensor_record_noremove.mx"}];
record = If[FileExistsQ[commonCache], Import[commonCache], {}];
If[Not[ListQ[record]], record = {}];

(* Append new ones if they are not already there *)
Do[
  flag = FindTensor[r[[2]], record];
  If[!flag[[1]],
    AppendTo[record, r];
    Print["Added new tensor to record: ", InputForm[r[[2]]]];
  ];
, {r, results}];

Export[commonCache, record];
Print["Updated cache saved to ", commonCache, ". Total cached tensors: ", Length[record]];
