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
tagp = p;

Print["\n=== Method 1: MatrixQ Conditional (from run_term34_by_hand.wl) ==="];
Block[{temlist, tp, temExpr, temp, repLocal, glist, coeff, tensor},
  temlist = Take[result[[k]], 3];
  vclist = {Cases[{result[[k, 2]]}, vc[__], Infinity] // DeleteDuplicates, Cases[{result[[k, 3]]}, vc[__], Infinity] // DeleteDuplicates};
  
  Do[
    If[vclist[[i]] === {}, temlist[[i + 1]] = {temlist[[i + 1]] /. rep}; Continue[]];
    tem = GatherBy[vclist[[i]], First] /. {vc[a_, b_] :> b} // SortBy[#, Length] &;
    tp = GenTensorProjection[tem, tagp, "krep" -> {d2[1, tagp] -> u}];
    If[i == 2, tp = tp /. {u -> 1, tagp -> 3}, tp = tp /. {tagp -> 2}];
    
    temExpr = (result[[k, i + 1]]*tp[[2]] /. {tagp -> (i + 1)} // Expand) /. {d[a_, b_] :> (d2[1, a] + d2[1, b] - d2[a, b])/2} /. {d2[1, 3] -> 1, d2[1, 2] -> u, d2[2, 3] -> v, d[a_, 1] :> 0} /. {G[i, a_] :> Times @@ (Thread@Power[topArray[[i]], -a])} // Expand;
    
    temp = Module[{outerReap},
      outerReap = Reap[
        Do[
         tem1 = temExpr[[j]] // Expand;
         If[Head[tem1] === Plus, tem1 = List @@ tem1, tem1 = {tem1}];
          Sow[Plus @@ Flatten[Reap[
              Do[
               tem2 = ClassifyTopology[tem1[[l]], topArray[[i]], i, "loops" -> result[[k, -1, i]], "ClassifySub" -> False];
               If[tem2 === {0, 0, 0, $Failed}, Continue[]];
               Sow[Times @@ Take[tem2, 3]]
              , {l, 1, Length[tem1]}]
          ][[2]], 1]];
        , {j, 1, Length[temExpr]}]
      ][[2]];
      If[outerReap === {}, {}, outerReap[[1]]]
    ];
    
    glist = Cases[{temp}, _G, Infinity] // DeleteDuplicates;
    repLocal = AssociationMap[h[Hash[#]] &, glist];
    
    If[MatrixQ[tp[[1]]],
      coeff = tp[[1]] . (temp /. repLocal);
      temlist[[i + 1]] = Table[coeff[[jj]] * tp[[2]][[jj]], {jj, 1, Length[tp[[2]]]}],
      
      tensor = Variables[tp[[1]]] // DeleteCases[#, _?((Head[#] =!= vc && Head[#] =!= g) &)] &;
      temlist[[i + 1]] = (temp /. repLocal) . tp[[1]] // MonomialList[#, tensor] &
    ];
  , {i, 1, 2}];
  
  resMethod1 = SpecialMultiply[temlist, h, {d2[1, 3] -> 1, d2[2, 1] -> u, d2[2, 3] -> 1 - Y, d[a_, 1] :> 0, d[2, 3] -> (u + Y)/2, v -> 1 - Y}];
];

Print["\n=== Method 2: Proposed Total Fix (temlist always flat list of monomials) ==="];
Block[{temlist, tp, temExpr, temp, repLocal, glist, tensor, scalar},
  temlist = Take[result[[k]], 3];
  vclist = {Cases[{result[[k, 2]]}, vc[__], Infinity] // DeleteDuplicates, Cases[{result[[k, 3]]}, vc[__], Infinity] // DeleteDuplicates};
  
  Do[
    If[vclist[[i]] === {},
      glist = Complement[Cases[{result[[k, i + 1]]}, _G, Infinity] // DeleteDuplicates, glist];
      repLocal = AssociationMap[h[Hash[#]] &, glist];
      temlist[[i + 1]] = {temlist[[i + 1]] /. repLocal};
      Continue[]
    ];
    tem = GatherBy[vclist[[i]], First] /. {vc[a_, b_] :> b} // SortBy[#, Length] &;
    tp = GenTensorProjection[tem, tagp, "krep" -> {d2[1, tagp] -> u}];
    If[i == 2, tp = tp /. {u -> 1, tagp -> 3}, tp = tp /. {tagp -> 2}];
    
    temExpr = (result[[k, i + 1]]*tp[[2]] /. {tagp -> (i + 1)} // Expand) /. {d[a_, b_] :> (d2[1, a] + d2[1, b] - d2[a, b])/2} /. {d2[1, 3] -> 1, d2[1, 2] -> u, d2[2, 3] -> v, d[a_, 1] :> 0} /. {G[i, a_] :> Times @@ (Thread@Power[topArray[[i]], -a])} // Expand;
    
    temp = Module[{outerReap},
      outerReap = Reap[
        Do[
         tem1 = temExpr[[j]] // Expand;
         If[Head[tem1] === Plus, tem1 = List @@ tem1, tem1 = {tem1}];
          Sow[Plus @@ Flatten[Reap[
              Do[
               tem2 = ClassifyTopology[tem1[[l]], topArray[[i]], i, "loops" -> result[[k, -1, i]], "ClassifySub" -> False];
               If[tem2 === {0, 0, 0, $Failed}, Continue[]];
               Sow[Times @@ Take[tem2, 3]]
              , {l, 1, Length[tem1]}]
          ][[2]], 1]];
        , {j, 1, Length[temExpr]}]
      ][[2]];
      If[outerReap === {}, {}, outerReap[[1]]]
    ];
    
    glist = Cases[{temp}, _G, Infinity] // DeleteDuplicates;
    repLocal = AssociationMap[h[Hash[#]] &, glist];
    
    tensor = Variables[tp[[1]]] // DeleteCases[#, _?((Head[#] =!= vc && Head[#] =!= g) &)] &;
    (* Proposed Fix line *)
    temlist[[i + 1]] = Total[(temp /. repLocal) . tp[[1]]] // MonomialList[#, tensor] &;
  , {i, 1, 2}];
  
  resMethod2 = SpecialMultiply[temlist, h, {d2[1, 3] -> 1, d2[2, 1] -> u, d2[2, 3] -> 1 - Y, d[a_, 1] :> 0, d[2, 3] -> (u + Y)/2, v -> 1 - Y}];
];

diff = resMethod1 - resMethod2 // Expand // Simplify;
Print["\n=== Correctness Verification ==="];
Print["Difference between Method 1 and Method 2 is: ", diff];
If[diff === 0,
  Print["SUCCESS: Method 1 and Method 2 are IDENTICAL!"],
  Print["FAILURE: Method 1 and Method 2 differ!"]
];
