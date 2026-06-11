(* scratch/test_special_multiply.wl *)
$HistoryLength = 0;
rootDir = "/Users/windfolgen/Documents/AntiGravity/svbwalkthrough/";
asymDir = FileNameJoin[{rootDir, "asym"}];
Get[FileNameJoin[{rootDir, "config.wl"}]];
If[!MemberQ[$Packages, "LiteRed`"], Get["LiteRed2`"]];
SetDim[d];
Declare[{l1, l2, l3, l4, p}, Vector, {u}, Number];
SetConstraints[{p}, sp[p, p] = u];
Do[
  Get[FileNameJoin[{asymDir, "Bases", b, b}]];
  Quiet[ExecuteDefinitions[ToExpression["LiteRed2`" <> b]]];
, {b, $LiteRedBases}];
Get[FileNameJoin[{asymDir, "asym_new.wl"}]];

integrand = (x[1,7] x[2,4] x[3,4] x[5,6])/(x[1,5] x[1,6] x[2,5] x[2,7] x[3,6] x[3,7] x[4,5] x[4,6] x[4,8] x[5,7] x[5,8] x[6,7] x[6,8] x[7,8]);
loops = {5, 6, 7, 8};
order = 4;

perm = {2, 1, 3, 4}; (* permutation 2134 *)
int1 = integrand /. {x[a__] :> (x[a] /. Thread@Rule[{1, 2, 3, 4}, perm])};
exp1 = RegionExpand[int1, loops, "order" -> order, "check" -> True];
{topVal, top1, top2} = exp1[[1]];
result1 = Flatten[ToTensorProduct[#, topVal, top1, top2, "check" -> True] & /@ (exp1[[2]]), 1];

term = result1[[4034]];
Print["Term 4034: ", InputForm[term]];

vclist = {Cases[{term[[2]]}, vc[__], Infinity] // DeleteDuplicates, Cases[{term[[3]]}, vc[__], Infinity] // DeleteDuplicates};
top = {top1, top2};

temlist = Take[term, 3];
gtotal = {};
rep = Association[{}];

Do[
  Print["--- Processing Topology ", i, " ---"];
  tem = GatherBy[vclist[[i]], First] /. {vc[a_, b_] :> b} // SortBy[#, Length] &;
  tp = GenTensorProjection[tem, p, "krep" -> {d2[1, p] -> u}];
  If[i == 2, tp = tp /. {u -> 1, p -> 3}, tp = tp /. {p -> 2}];
  
  temVal = (term[[i + 1]]*tp[[2]] /. {p -> (i + 1)} // Expand) /. {d[a_, b_] :> (d2[1, a] + d2[1, b] - d2[a, b])/2} /. {d2[1, 3] -> 1, d2[1, 2] -> u, d2[2, 3] -> v, d[a_, 1] :> 0} /. {G[i, a_] :> Times @@ (Thread@Power[top[[i]], -a])} // Expand;
  
  temp = Reap[
     Do[
      tem1 = temVal[[j]] // Expand;
      If[Head[tem1] === Plus, tem1 = List @@ tem1, tem1 = {tem1}];
      Sow[Total @ Reap[
          Do[
           tem2 = ClassifyTopology[tem1[[l]], top[[i]], i, "loops" -> term[[-1, i]], "ClassifySub" -> False];
           If[tem2 === {0, 0, 0, $Failed}, Sow[0]; Continue[]];
           Sow[Times @@ Take[tem2, 3]]
          , {l, 1, Length[tem1]}]
         ][[2, 1]]]
     , {j, 1, Length[temVal]}]
  ][[2, 1]];
  
  temp = Together /@ temp;
  glist = Complement[Cases[{temp}, _G, Infinity] // DeleteDuplicates, gtotal];
  If[glist =!= {}, rep = Join[rep, AssociationMap[h[Hash[#]] &, glist]]];
  gtotal = Join[gtotal, glist];
  
  dist = Distribute[(temp /. rep) . tp[[1]], Plus];
  temlist[[i + 1]] = If[Head[dist] === Plus, List @@ dist, {dist}];
  Print["Topology ", i, " contracted to ", Length[temlist[[i + 1]]], " terms"];
, {i, 1, 2}];

SpecialMultiplyTest[temlist_, h_, rep_, simplifyFunc_] := Module[
  {scalar, listA, listB, splitTerm, termsA, termsB, scalarTens, scalarCoeff, total, i, j, coeffA, tensA, coeffB, tensB, contracted, splitScalar},
  
  scalar = temlist[[1]] /. rep;
  listA = temlist[[2]] /. rep;
  listB = temlist[[3]] /. rep;
  
  splitTerm[term_] := Which[
    term === 0, {0, 1},
    FreeQ[term, vc] && FreeQ[term, g], {term, 1},
    Head[term] === Times, 
      Module[{factors = List @@ term, tensParts, coeffParts},
        tensParts = Select[factors, !FreeQ[#, vc] || !FreeQ[#, g] &];
        coeffParts = Select[factors, FreeQ[#, vc] && FreeQ[#, g] &];
        {Times @@ coeffParts, Times @@ tensParts}
      ],
    True, {1, term}
  ];
  
  splitScalar = splitTerm[scalar];
  scalarCoeff = splitScalar[[1]];
  scalarTens = splitScalar[[2]];
  
  termsA = splitTerm /@ listA;
  termsB = splitTerm /@ listB;
  
  total = Sum[
    coeffA = termsA[[i, 1]];
    tensA = termsA[[i, 2]];
    coeffB = termsB[[j, 1]];
    tensB = termsB[[j, 2]];
    
    contracted = (scalarTens * tensA * tensB // Expand) /. rep;
    coeffA * coeffB * scalarCoeff * contracted
  , {i, 1, Length[termsA]}, {j, 1, Length[termsB]}];
  
  Return[Collect[total, _h, simplifyFunc]]
];

mrep = {d2[1, 3] -> 1, d2[2, 1] -> u, d2[2, 3] -> 1 - Y, d[a_, 1] :> 0, d[2, 3] -> (u + Y)/2, v -> 1 - Y};

Print["--- Testing SpecialMultiply with Identity (No Simplification) ---"];
tMult1 = SessionTime[];
res1 = SpecialMultiplyTest[temlist, h, mrep, Identity];
Print["SpecialMultiply with Identity completed in ", SessionTime[] - tMult1, "s. Terms count: ", Length[res1]];

Print["--- Testing SpecialMultiply with Together ---"];
tMult2 = SessionTime[];
TimeConstrained[
  res2 = SpecialMultiplyTest[temlist, h, mrep, Together];
  Print["SpecialMultiply with Together completed in ", SessionTime[] - tMult2, "s. Terms count: ", Length[res2]];
, 15, Print["SpecialMultiply with Together TIMEOUT"]];

Print["--- Testing SpecialMultiply with Factor ---"];
tMult3 = SessionTime[];
TimeConstrained[
  res3 = SpecialMultiplyTest[temlist, h, mrep, Factor];
  Print["SpecialMultiply with Factor completed in ", SessionTime[] - tMult3, "s. Terms count: ", Length[res3]];
, 15, Print["SpecialMultiply with Factor TIMEOUT"]];
