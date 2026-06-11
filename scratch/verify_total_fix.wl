(* scratch/verify_total_fix.wl *)
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

(* Original GenTensorProjection *)
GenTensorProjectionOld = GenTensorProjection;

(* New Optimized GenTensorProjection *)
ClearAll[GenTensorProjectionNew];
Options[GenTensorProjectionNew] = {"krep" -> {}, "outputrank" -> 0};
GenTensorProjectionNew[indexlist_, tagp_, OptionsPattern[]] := Module[
  {tensor, l, M, sol, start, krep1, uVal, kList, solScaled, solFactored},
  start = SessionTime[];
  tensor = MPartition[indexlist, tagp];
  l = Length[tensor];
  
  (* Extract scaling variable uVal *)
  uVal = d2[1, tagp] /. OptionValue["krep"];
  
  (* Construct M with u -> 1 *)
  krep1 = {d2[1, tagp] -> 1};
  M = Table[
    ((tensor[[i]] * tensor[[j]] // Expand) /. krep1),
    {i, 1, l}, {j, 1, l}
  ];
  
  (* Invert M *)
  invM = Inverse[M];
  
  (* Count vector occurrences for scaling *)
  kList = Table[
    Module[{expanded = Expand[tensor[[i]]], firstTerm},
      firstTerm = If[Head[expanded] === Plus, expanded[[1]], expanded];
      Length[Cases[{firstTerm}, vc[tagp, _], Infinity]]
    ],
    {i, 1, l}
  ];
  
  (* Scale the inverse matrix elements *)
  invMScaled = Table[
    invM[[i, j]] * uVal^(-(kList[[i]] + kList[[j]])/2),
    {i, 1, l}, {j, 1, l}
  ];
  
  (* Multiply invM . tensor to get projection tensors *)
  sol = invMScaled . tensor;
  
  solFactored = Factor /@ sol;
  
  If[l > 24, 
    Print["time consuming: ", SessionTime[] - start]
  ];
  Return[{solFactored, tensor}]
];

(* Shapes to test *)
shapes = {
  {{m[1]}},
  {{m[1]}, {m[2]}},
  {{m[1], m[2]}},
  {{m[3]}, {m[1], m[2]}},
  {{m[1], m[2], m[3]}},
  {{m[1]}, {m[2]}, {m[4]}},
  {{m[4]}, {m[1], m[2], m[3]}},
  {{m[1], m[2]}, {m[3], m[4]}},
  {{m[1], m[2], m[3], m[4]}},
  {{m[1]}, {m[6]}, {m[2], m[4]}},
  {{m[1]}, {m[3], m[5], m[7], m[9]}},
  {{m[2], m[4], m[6], m[8], m[10]}},
  {{m[1]}, {m[9]}, {m[3], m[5], m[7]}},
  {{m[1]}, {m[3], m[5]}, {m[7], m[9]}},
  {{m[7], m[9]}, {m[1], m[3], m[5]}}
};

Do[
  Print["\nTesting shape ", i, ": ", shapes[[i]]];
  
  t0 = SessionTime[];
  resOld = GenTensorProjectionOld[shapes[[i]], p, "krep" -> {d2[1, p] -> u}];
  tOld = SessionTime[] - t0;
  
  t0 = SessionTime[];
  resNew = GenTensorProjectionNew[shapes[[i]], p, "krep" -> {d2[1, p] -> u}];
  tNew = SessionTime[] - t0;
  
  diff = resOld[[1]] - resNew[[1]] // Expand // Simplify;
  isSame = (diff === Table[0, {Length[resOld[[1]]]}]);
  
  Print["  Old time: ", tOld, "s"];
  Print["  New time: ", tNew, "s"];
  Print["  Are results algebraically identical? ", isSame];
  If[!isSame,
    Print["  WARNING: mismatch found!"];
    Print["  diff: ", diff];
    Exit[1];
  ];
, {i, 1, Length[shapes]}];

Print["\n=== All tests passed successfully! ==="];
