$HistoryLength = 0;
rootDir = "/Users/windfolgen/Documents/AntiGravity/svbwalkthrough";
asymDir = FileNameJoin[{rootDir, "asym"}];

Get[FileNameJoin[{rootDir, "config.wl"}]];
Get[FileNameJoin[{asymDir, "boundary_agent", "boundary_agent.wl"}]];
Get["LiteRed2`"];
SetDim[d];
Declare[{l1, l2, l3, l4, p}, Vector, {u}, Number];
SetConstraints[{p}, sp[p, p] = u];
Do[
  Get[FileNameJoin[{asymDir, "Bases", b, b}]];
  Quiet[ExecuteDefinitions[ToExpression[b]]];
, {b, $LiteRedBases}];
Get[FileNameJoin[{asymDir, "asym_new.wl"}]];

order = 4;
loops = {5, 6, 7, 8};
perm = {3, 2, 1, 4};

(* Cases *)
case1 = perm;
case2 = perm /. {1 -> 3, 3 -> 1, 2 -> 4, 4 -> 2};
case3 = perm /. {1 -> 2, 2 -> 1, 3 -> 4, 4 -> 3};
case4 = perm /. {1 -> 4, 4 -> 1, 2 -> 3, 3 -> 2};
cases = {case1, case2, case3, case4};

integrandI41 = (x[4,7]*x[5,6] - x[4,5]*x[6,7] - x[4,6]*x[5,7]) / (x[1,5]*x[1,6]*x[2,5]*x[2,7]*x[3,6]*x[3,7]*x[4,5]*x[4,6]*x[4,8]*x[5,7]*x[5,8]*x[6,7]*x[6,8]*x[7,8]);
integrandI42c1 = (x[1,7]*x[2,4]*x[3,4]*x[5,6]) / (x[1,5]*x[1,6]*x[2,5]*x[2,7]*x[3,6]*x[3,7]*x[4,5]*x[4,6]*x[4,8]*x[5,7]*x[5,8]*x[6,7]*x[6,8]*x[7,8]);

Print["=== Permutation {3,2,1,4} for fourloopI41 ==="];
Do[
  intCase = integrandI41 /. {x[a__] :> (x[a] /. Thread@Rule[{1, 2, 3, 4}, cases[[idx]]])};
  Quiet[
    exp = RegionExpand[intCase, loops, "order" -> order, "check" -> False];
    {top, top1, top2} = exp[[1]];
    reTerms = Length[exp[[2]]];
    totTerms = Length[Flatten[ToTensorProduct[#, top, top1, top2, "check" -> False] & /@ (exp[[2]]), 1]];
  ];
  Print["Case ", idx, " (target perm ", cases[[idx]], ") -> RegionExpand: ", reTerms, ", ToTensorProduct: ", totTerms];
, {idx, 1, 4}];

Print["=== Permutation {3,2,1,4} for fourloopI42 comp 1 ==="];
Do[
  intCase = integrandI42c1 /. {x[a__] :> (x[a] /. Thread@Rule[{1, 2, 3, 4}, cases[[idx]]])};
  Quiet[
    exp = RegionExpand[intCase, loops, "order" -> order, "check" -> False];
    {top, top1, top2} = exp[[1]];
    reTerms = Length[exp[[2]]];
    totTerms = Length[Flatten[ToTensorProduct[#, top, top1, top2, "check" -> False] & /@ (exp[[2]]), 1]];
  ];
  Print["Case ", idx, " (target perm ", cases[[idx]], ") -> RegionExpand: ", reTerms, ", ToTensorProduct: ", totTerms];
, {idx, 1, 4}];

Exit[];
