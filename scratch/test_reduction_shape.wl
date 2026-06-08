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

(* threeloophard1 input *)
integrand = ((x[5,6]*x[3,4] - x[3,6]x[4,5] - x[3,5]x[4,6])/
  (x[5,1]x[5,2]x[5,3]x[5,4]x[6,1]x[6,2]x[6,3]x[6,4]x[6,7]x[5,7]x[7,3]x[7,4]));
loops = {5, 6, 7};
order = 3;

Print["Running RegionExpand..."];
exp = RegionExpand[integrand, loops, "order" -> order, "check" -> True];
{top, top1, top2} = exp[[1]];
result = Flatten[ToTensorProduct[#, top, top1, top2, "check" -> True] & /@ (exp[[2]]), 1];

Print["Total terms: ", Length[result]];

(* Let's run the first term *)
(* Find a term with tensor structure *)
k = None;
Do[
  vcTry = {Cases[{result[[j, 2]]}, vc[__], Infinity], Cases[{result[[j, 3]]}, vc[__], Infinity]};
  If[vcTry[[1]] =!= {} || vcTry[[2]] =!= {},
    k = j;
    Break[];
  ];
, {j, 1, Length[result]}];

If[k === None,
  Print["No terms with tensor structures found!"];
  Exit[1];
];

Print["Selected term index k = ", k];
temlist = Take[result[[k]], 3];
vclist = {Cases[{result[[k, 2]]}, vc[__], Infinity] // DeleteDuplicates, Cases[{result[[k, 3]]}, vc[__], Infinity] // DeleteDuplicates};


Print["vclist structure: ", vclist];

Do[
  Print["\n=== Topology ", i, " ==="];
  If[vclist[[i]] === {},
    Print["No tensor structure"];
    Continue[]
  ];
  tem = GatherBy[vclist[[i]], First] /. {vc[a_, b_] :> b} // SortBy[#, Length] &;
  tp = GenTensorProjection[tem, p, "krep" -> {d2[1, p] -> u}];
  If[i == 2, tp = tp /. {u -> 1, p -> 3}, tp = tp /. {p -> 2}];
  
  Print["Matrix tp[[1]] dimensions: ", Dimensions[tp[[1]]]];
  Print["Matrix tp[[1]] MatrixQ: ", MatrixQ[tp[[1]]]];
  
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
  
  Print["temp shape: ", Dimensions[temp]];
  
  glist = Cases[{temp}, _G, Infinity] // DeleteDuplicates;
  rep = AssociationMap[h[Hash[#]] &, glist];
  
  Print["temp /. rep shape: ", Dimensions[temp /. rep]];
  
  dotProduct = (temp /. rep) . tp[[1]] . tp[[2]];
  Print["dot product shape: ", Dimensions[dotProduct]];
  Print["dot product Head: ", Head[dotProduct]];
  
  tensor = Variables[tp[[1]]] // DeleteCases[#, _?((Head[#] =!= vc && Head[#] =!= g) &)] &;
  Print["tensor list: ", tensor];
  
  monomials = dotProduct // MonomialList[#, tensor] &;
  Print["monomials shape: ", Dimensions[monomials]];
  Print["monomials Head: ", Head[monomials]];
  If[Length[monomials] > 0,
    Print["first element of monomials: ", Short[monomials[[1]], 5]];
    Print["first element of monomials Head: ", Head[monomials[[1]]]];
  ];
, {i, 1, 2}];
