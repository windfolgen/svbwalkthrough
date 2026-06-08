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
, {b, {"asym", "asym3L", "asym2L", "asym1L"}}];

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
If[i == 2, tp = tp /. {u -> 1, p -> 3}, tp = tp /. {p -> 2}];

temExpr = (result[[k, i + 1]]*tp[[2]] /. {p -> (i + 1)} // Expand) /. {d[a_, b_] :> (d2[1, a] + d2[1, b] - d2[a, b])/2} /. {d2[1, 3] -> 1, d2[1, 2] -> u, d2[2, 3] -> v, d[a_, 1] :> 0} /. {G[i, a_] :> Times @@ (Thread@Power[{top1, top2}[[i]], -a])} // Expand;

temp = Module[{outerReap},
  outerReap = Reap[
    Do[
     tem1 = temExpr[[j]] // Expand;
     If[Head[tem1] === Plus, tem1 = List @@ tem1, tem1 = {tem1}];
      Sow[Plus @@ Flatten[Reap[
          Do[
           tem2 = ClassifyTopology[tem1[[l]], {top1, top2}[[i]], i, "loops" -> result[[k, -1, i]], "ClassifySub" -> False];
           If[tem2 === {0, 0, 0, $Failed}, Continue[]];
           Sow[Times @@ Take[tem2, 3]]
          , {l, 1, Length[tem1]}]
      ][[2]], 1]];
    , {j, 1, Length[temExpr]}]
  ][[2]];
  If[outerReap === {}, {}, outerReap[[1]]]
];

glist = Cases[{temp}, _G, Infinity] // DeleteDuplicates;
rep = AssociationMap[h[Hash[#]] &, glist];

Print["Calculating coeff..."];
coeff = (temp /. rep) . tp[[1]];
Print["coeff Head: ", Head[coeff]];
Print["coeff Dimensions: ", Dimensions[coeff]];

Print["Calculating scalar product..."];
scalar = Total[coeff * tp[[2]]];
Print["scalar Head: ", Head[scalar]];
Print["scalar Dimensions: ", Dimensions[scalar]];

tensor = Variables[tp[[1]]] // DeleteCases[#, _?((Head[#] =!= vc && Head[#] =!= g) &)] &;
monomials = scalar // MonomialList[#, tensor] &;
Print["monomials Head: ", Head[monomials]];
Print["monomials Dimensions: ", Dimensions[monomials]];
Print["monomials Length: ", Length[monomials]];
If[Length[monomials] > 0,
  Print["first element of monomials: ", Short[monomials[[1]], 5]];
];
