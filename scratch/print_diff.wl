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

k = 4074;
i = 1; (* Topology 1 *)

vclist = {Cases[{result[[k, 2]]}, vc[__], Infinity] // DeleteDuplicates, Cases[{result[[k, 3]]}, vc[__], Infinity] // DeleteDuplicates};
tem = GatherBy[vclist[[i]], First] /. {vc[a_, b_] :> b} // SortBy[#, Length] &;

tpA = GenTensorProjection[tem, p, "krep" -> {d2[1, p] -> u}];
tpA = tpA /. {p -> 2};

tpB = GenTensorProjection[tem, p, "krep" -> {d2[1, p] -> 1}];
tpB = tpB /. {p -> 2};

temExpr = (result[[k, i + 1]]*(tpA[[2]]) /. {p -> (i + 1)} // Expand) /. {d[a_, b_] :> (d2[1, a] + d2[1, b] - d2[a, b])/2} /. {d2[1, 3] -> 1, d2[1, 2] -> u, d2[2, 3] -> v, d[a_, 1] :> 0} /. {G[i, a_] :> Times @@ (Thread@Power[topArray[[i]], -a])} // Expand;

temp = Reap[
  Do[
    tem1 = temExpr[[j]] // Expand;
    If[Head[tem1] === Plus, tem1List = List @@ tem1, tem1List = {tem1}];
    Sow[Plus @@ Reap[
      Do[
        tem2 = ClassifyTopology[tem1List[[l]], topArray[[i]], i, "loops" -> result[[k, -1, i]], "ClassifySub" -> False];
        Sow[Times @@ Take[tem2, 3]]
      , {l, 1, Length[tem1List]}]
    ][[2, 1]]]
  , {j, 1, Length[temExpr]}]
][[2, 1]];

glist = Cases[{temp}, _G, Infinity] // DeleteDuplicates;
repG = AssociationMap[h[Hash[#]] &, glist];
tempHashed = temp /. repG;

coeffA = tpA[[1]] . tempHashed;
resA = Table[coeffA[[jj]] * tpA[[2]][[jj]], {jj, 1, Length[tpA[[2]]]}];

coeffB = tpB[[1]] . tempHashed;
resB = Table[coeffB[[jj]] * tpB[[2]][[jj]], {jj, 1, Length[tpB[[2]]]}];

diff = Expand[Total[resA] - Total[resB]];
Print["Difference: ", diff];
Print["Total A: ", Short[Total[resA], 5]];
Print["Total B: ", Short[Total[resB], 5]];
