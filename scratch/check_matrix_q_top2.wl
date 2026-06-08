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

integrand = (x[1,7] x[2,4] x[3,4] x[5,6])/(x[1,5] x[1,6] x[2,5] x[2,7] x[3,6] x[3,7] x[4,5] x[4,6] x[4,8] x[5,7] x[5,8] x[6,7] x[6,8] x[7,8]);
perm = {2, 1, 3, 4};
loops = {5, 6, 7, 8};
order = 4;

intCase = integrand /. {x[a__] :> (x[a] /. Thread@Rule[{1, 2, 3, 4}, perm])};
exp = RegionExpand[intCase, loops, "order" -> order, "check" -> False];
{topOverall, top1, top2} = exp[[1]];
topArray = {top1, top2};
result = Flatten[ToTensorProduct[#, topOverall, top1, top2, "check" -> False] & /@ (exp[[2]]), 1];

k = 4034;
i = 2; (* Topology 2 *)
temlist = Take[result[[k]], 3];
vclist = {Cases[{result[[k, 2]]}, vc[__], Infinity] // DeleteDuplicates, Cases[{result[[k, 3]]}, vc[__], Infinity] // DeleteDuplicates};
tem = GatherBy[vclist[[i]], First] /. {vc[a_, b_] :> b} // SortBy[#, Length] &;

Print["Running GenTensorProjection..."];
tp = GenTensorProjection[tem, p, "krep" -> {d2[1, p] -> u}];

Print["\n=== Before Replacement ==="];
Print["tp[[1]] MatrixQ: ", MatrixQ[tp[[1]]]];
Print["tp[[1]] Dimensions: ", Dimensions[tp[[1]]]];

If[i == 2, tp = tp /. {u -> 1, p -> 3}, tp = tp /. {p -> 2}];

Print["\n=== After Replacement ==="];
Print["tp[[1]] MatrixQ: ", MatrixQ[tp[[1]]]];
Print["tp[[1]] Dimensions: ", Dimensions[tp[[1]]]];
Print["tp[[1]] Head: ", Head[tp[[1]]]];
If[Length[tp[[1]]] > 0,
  Print["tp[[1]][[1]] Head: ", Head[tp[[1]][[1]]]];
  Print["tp[[1]][[1]] Length: ", Length[tp[[1]][[1]]]];
];
