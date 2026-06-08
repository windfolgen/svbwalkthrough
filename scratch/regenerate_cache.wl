$HistoryLength = 0;
rootDir = "/Users/windfolgen/Documents/AntiGravity/svbwalkthrough";
SetDirectory[rootDir];

Get[FileNameJoin[{rootDir, "config.wl"}]];
Get["LiteRed2`"];
SetDim[d];
Declare[{l1, l2, l3, l4, p}, Vector, {u}, Number];
SetConstraints[{p}, sp[p, p] = u];
Do[
  Get[FileNameJoin[{rootDir, "asym", "Bases", b, b}]];
  Quiet[ExecuteDefinitions[ToExpression[b]]];
, {b, $LiteRedBases}];

Get[FileNameJoin[{rootDir, "asym", "asym_new.wl"}]];

(* Load custom GenTensorProjection definition with mat output *)
GenTensorProjectionNew[indexlist_, tagp_] := Module[
  {tensor, l, b, bv, rep, c, cv, sys, sol, start},
  tensor = MPartition[indexlist, tagp];
  l = Length[tensor];
  bv = b /@ Range[l];
  cv = c /@ Range[l];
  sys = Table[
    ((tensor[[i]]*(cv . tensor) // Expand) /. {d2[1, tagp] -> u}) == bv[[i]], 
    {i, 1, l}
  ];
  sol = Flatten[Solve[sys, cv]];
  {Normal[CoefficientArrays[cv /. sol, bv]][[2]], tensor}
];

commonCache = FileNameJoin[{rootDir, "asym", "tmp", "cache_tensor_record_noremove.mx"}];
record = If[FileExistsQ[commonCache], Import[commonCache], {}];
If[Not[ListQ[record]], record = {}];

Print["Original record length: ", Length[record]];

newRecord = Table[
  Module[{shape, tem, tpNew},
    shape = record[[i, 1]];
    tem = record[[i, 2]];
    Print["Regenerating Entry ", i, " with shape ", shape];
    tpNew = GenTensorProjectionNew[tem, p];
    {shape, tem, tpNew}
  ]
, {i, 1, Length[record]}];

Export[commonCache, newRecord];
Print["Regeneration complete! Global cache rewritten with matrix format."];
