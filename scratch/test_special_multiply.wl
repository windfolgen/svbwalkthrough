(* scratch/test_special_multiply.wl *)
rootDir = "/Users/windfolgen/Documents/AntiGravity/svbwalkthrough";
asymDir = FileNameJoin[{rootDir, "asym"}];

(* Load LiteRed2 and define variables *)
Get["LiteRed2`"];
SetDim[d];
Declare[{l1, l2, l3, l4, p}, Vector, {u}, Number];
SetConstraints[{p}, sp[p, p] = u];

(* Load bases *)
Do[
  Get[FileNameJoin[{asymDir, "Bases", b, b}]];
  Quiet[ExecuteDefinitions[ToExpression[b]]];
, {b, {"asym", "asym3L", "asym2L", "asym1L"}}];

(* Load asymptotic expansion engine *)
Get[FileNameJoin[{asymDir, "asym_new.wl"}]];

(* Define optimized SpecialMultiplyNew *)
ClearAll[SpecialMultiplyNew];
SpecialMultiplyNew[temlist_, h_, rep_] := Module[
  {scalar, listA, listB, splitTerm, termsA, termsB, total, i, j, coeffA, coeffB, tensA, tensB, contracted},
  
  scalar = temlist[[1]];
  listA = temlist[[2]];
  listB = temlist[[3]];
  
  splitTerm[term_] := If[term === 0, {0, 1},
    Module[{tens},
      tens = DeleteCases[term, _?((FreeQ[#, vc] && FreeQ[#, g]) &)];
      {term / tens, tens}
    ]
  ];
  
  termsA = splitTerm /@ listA;
  termsB = splitTerm /@ listB;
  
  total = Sum[
    coeffA = termsA[[i, 1]];
    tensA = termsA[[i, 2]];
    coeffB = termsB[[j, 1]];
    tensB = termsB[[j, 2]];
    
    contracted = (tensA * tensB // Expand) /. rep;
    coeffA * coeffB * contracted
  , {i, 1, Length[termsA]}, {j, 1, Length[termsB]}];
  
  Return[Collect[scalar * total, _h, Factor]]
];

(* Generate test data from actual region expansion *)
integrand = (x[1,7] x[2,4] x[3,4] x[5,6])/(x[1,5] x[1,6] x[2,5] x[2,7] x[3,6] x[3,7] x[4,5] x[4,6] x[4,8] x[5,7] x[5,8] x[6,7] x[6,8] x[7,8]);
loops = {5, 6, 7, 8};
order = 4;

Print["Running RegionExpand..."];
exp = RegionExpand[integrand, loops, "order" -> order, "check" -> True];
{top, top1, top2} = exp[[1]];

Print["Total region expansion entries: ", Length[exp[[2]]]];

(* Select 200 random terms to search *)
SeedRandom[1234];
indices = RandomSample[Range[Length[exp[[2]]]], Min[200, Length[exp[[2]]]]];
termsToProcess = exp[[2]][[indices]];
result = Flatten[ToTensorProduct[#, top, top1, top2, "check" -> True] & /@ termsToProcess, 1];

Print["Total tensor terms generated from random sample: ", Length[result]];

(* Find a term with largest number of tensor components *)
bestTerm = None;
bestScore = 0;
bestTemlist = None;

Do[
  vclist = {Cases[{result[[k, 2]]}, vc[__], Infinity] // DeleteDuplicates, Cases[{result[[k, 3]]}, vc[__], Infinity] // DeleteDuplicates};
  If[vclist[[1]] =!= {} && vclist[[2]] =!= {},
    temlist = Take[result[[k]], 3];
    tagp = p;
    
    Quiet[
      Do[
        tem = GatherBy[vclist[[i]], First] /. {vc[a_, b_] :> b} // SortBy[#, Length] &;
        tp = GenTensorProjection[tem, tagp, "krep" -> {d2[1, tagp] -> u}];
        If[i == 2, tp = tp /. {u -> 1, tagp -> 3}, tp = tp /. {tagp -> 2}];
        tem = (result[[k, i + 1]]*tp[[2]] /. {tagp -> (i + 1)} // Expand) /. {d[a_, b_] :> (d2[1, a] + d2[1, b] - d2[a, b])/2} /. {d2[1, 3] -> 1, d2[1, 2] -> u, d2[2, 3] -> v, d[a_, 1] :> 0} /. {G[i, a_] :> Times @@ (Thread@Power[top[[i]], -a])} // Expand;
        
        temp = Reap[
          Do[
            tem1 = tem[[j]] // Expand;
            If[Head[tem1] === Plus, tem1 = List @@ tem1, tem1 = {tem1}];
            Sow[Plus @@ Reap[
                Do[
                  tem2 = ClassifyTopology[tem1[[l]], top[[i]], i, "loops" -> result[[k, -1, i]], "ClassifySub" -> False];
                  If[tem2 === {0, 0, 0, $Failed}, Continue[]];
                  Sow[Times @@ Take[tem2, 3]]
                , {l, 1, Length[tem1]}]
            ][[2, 1]]]
          , {j, 1, Length[tem]}]
        ][[2, 1]];
        
        tensor = Variables[tp[[1]]] // DeleteCases[#, _?((Head[#] =!= vc && Head[#] =!= g) &)] &;
        temlist[[i + 1]] = temp . tp[[1]] // MonomialList[#, tensor] &;
      , {i, 1, 2}];
    ];
    
    score = Length[temlist[[2]]] * Length[temlist[[3]]];
    If[score > bestScore,
      bestScore = score;
      bestTerm = result[[k]];
      bestTemlist = temlist;
      Print["Found term at index ", k, " with product of sizes: ", Length[temlist[[2]]], " * ", Length[temlist[[3]]], " = ", score];
    ];
  ];
, {k, 1, Length[result]}];

If[bestTerm === None,
  Print["Could not find any non-trivial term! Try increasing the sample size."];
  Exit[1];
];

Print["Selected best term: ", Short[bestTerm, 5]];
temlist = bestTemlist;
rep = {d2[1, 3] -> 1, d2[2, 1] -> u, d2[2, 3] -> 1 - Y, d[a_, 1] :> 0, d[2, 3] -> (u + Y)/2, v -> 1 - Y};

Print["temlist[[2]] length: ", Length[temlist[[2]]]];
Print["temlist[[3]] length: ", Length[temlist[[3]]]];

(* Benchmark old SpecialMultiply *)
t0 = SessionTime[];
resOld = SpecialMultiply[temlist, h, rep];
tOld = SessionTime[] - t0;
Print["Old SpecialMultiply Time: ", tOld, "s"];

(* Benchmark new SpecialMultiply *)
t0 = SessionTime[];
resNew = SpecialMultiplyNew[temlist, h, rep];
tNew = SessionTime[] - t0;
Print["New SpecialMultiply Time: ", tNew, "s"];

(* Check correctness *)
diff = resOld - resNew // Expand // Simplify;
If[diff === 0,
  Print["SUCCESS: Results are identical!"],
  Print["WARNING: Results differ! Diff: ", Short[diff, 10]]
];

Print["All tests complete."];
