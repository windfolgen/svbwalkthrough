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

commonCache = FileNameJoin[{rootDir, "asym", "tmp", "cache_tensor_record_noremove.mx"}];
record = Import[commonCache];

k = 4034;
i = 2; (* Topology 2 *)

vclist = {Cases[{result[[k, 2]]}, vc[__], Infinity] // DeleteDuplicates, Cases[{result[[k, 3]]}, vc[__], Infinity] // DeleteDuplicates};
tem = GatherBy[vclist[[i]], First] /. {vc[a_, b_] :> b} // SortBy[#, Length] &;

flag = FindTensor[tem, record];
rep = flag[[2]];
tp = flag[[3]];

If[i == 2, 
  tpReplaced = tp /. {u -> 1, p -> 3};
, 
  tpReplaced = tp /. {p -> 2};
];

tExp = SessionTime[];
temExpr = (result[[k, i + 1]]*(tpReplaced[[2]]) /. {p -> (i + 1)} // Expand) /. {d[a_, b_] :> (d2[1, a] + d2[1, b] - d2[a, b])/2} /. {d2[1, 3] -> 1, d2[1, 2] -> u, d2[2, 3] -> v, d[a_, 1] :> 0} /. {G[i, a_] :> Times @@ (Thread@Power[topArray[[i]], -a])} // Expand;
Print["Expansion took ", SessionTime[] - tExp, "s. Terms: ", Length[temExpr]];

tClass = SessionTime[];
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
Print["Classification took ", SessionTime[] - tClass, "s"];

glist = Cases[{temp}, _G, Infinity] // DeleteDuplicates;
repG = AssociationMap[h[Hash[#]] &, glist];
tempHashed = temp /. repG;

tCont = SessionTime[];
coeff = tpReplaced[[1]] . (tempHashed /. rep);
temlist = Table[coeff[[jj]] * tpReplaced[[2]][[jj]], {jj, 1, Length[tpReplaced[[2]]]}];
Print["Optimized contraction took ", SessionTime[] - tCont, "s"];

tMult = SessionTime[];
temlist2 = {result[[k, 1]], {1}, temlist};
res = SpecialMultiply[temlist2, h, {d2[1, 3] -> 1, d2[2, 1] -> u, d2[2, 3] -> 1 - Y, d[a_, 1] :> 0, d[2, 3] -> (u + Y)/2, v -> 1 - Y}];
Print["SpecialMultiply took ", SessionTime[] - tMult, "s"];
