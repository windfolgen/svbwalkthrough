(* scratch/debug_verify.wl *)
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

commonCache = FileNameJoin[{rootDir, "asym", "tmp", "cache_tensor_record_noremove.mx"}];
record = Import[commonCache];

integrand = (x[1,7] x[2,4] x[3,4] x[5,6])/(x[1,5] x[1,6] x[2,5] x[2,7] x[3,6] x[3,7] x[4,5] x[4,6] x[4,8] x[5,7] x[5,8] x[6,7] x[6,8] x[7,8]);
perm = {2, 1, 3, 4};
loops = {5, 6, 7, 8};
order = 4;

intCase = integrand /. {x[a__] :> (x[a] /. Thread@Rule[{1, 2, 3, 4}, perm])};
exp = RegionExpand[intCase, loops, "order" -> order, "check" -> False];
{topOverall, top1, top2} = exp[[1]];
topArray = {top1, top2};
result = Flatten[ToTensorProduct[#, topOverall, top1, top2, "check" -> False] & /@ (exp[[2]]), 1];

k = 4030;
temlist = Take[result[[k]], 3];
vclist = {Cases[{result[[k, 2]]}, vc[__], Infinity] // DeleteDuplicates, Cases[{result[[k, 3]]}, vc[__], Infinity] // DeleteDuplicates};

gtotal = {};
repH = Association[{}];

Do[
  If[vclist[[i]] === {},
    glist = Complement[Cases[{temlist[[i + 1]]}, _G, Infinity] // DeleteDuplicates, gtotal];
    If[glist =!= {}, repH = Join[repH, AssociationMap[h[Hash[#]] &, glist]]];
    gtotal = Join[gtotal, glist];
    temlist[[i + 1]] = {temlist[[i + 1]] /. repH};
    Continue[]
  ];
  
  tem = GatherBy[vclist[[i]], First] /. {vc[a_, b_] :> b} // SortBy[#, Length] &;
  flag = FindTensor[tem, record];
  If[flag[[1]],
    tp = flag[[3]],
    tp = GenTensorProjection[tem, p, "krep" -> {d2[1, p] -> u}];
    AppendTo[record, {Length /@ tem, tem, tp}]
  ];
  If[i == 2, tp = tp /. {u -> 1, p -> 3}, tp = tp /. {p -> 2}];
  
  temExpr = (result[[k, i + 1]]*tp[[2]] /. {p -> (i + 1)} // Expand) /. {d[a_, b_] :> (d2[1, a] + d2[1, b] - d2[a, b])/2} /. {d2[1, 3] -> 1, d2[1, 2] -> u, d2[2, 3] -> v, d[a_, 1] :> 0} /. {G[i, a_] :> Times @@ (Thread@Power[topArray[[i]], -a])} // Expand;
  
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
  
  glist = Complement[Cases[{temp}, _G, Infinity] // DeleteDuplicates, gtotal];
  If[glist =!= {}, repH = Join[repH, AssociationMap[h[Hash[#]] &, glist]]];
  gtotal = Join[gtotal, glist];
  
  coeff = tp[[1]] . (temp /. repH);
  temlist[[i + 1]] = Table[coeff[[jj]] * tp[[2]][[jj]], {jj, 1, Length[tp[[2]]]}];
, {i, 1, 2}];

repMult = {d2[1, 3] -> 1, d2[2, 1] -> u, d2[2, 3] -> 1 - Y, d[a_, 1] :> 0, d[2, 3] -> (u + Y)/2, v -> 1 - Y};

(* Proposed SpecialMultiplyNew *)
SpecialMultiplyNew[temlist_, h_, rep_] := Module[
  {splitTerm, coeffS, tensS, termsA, termsB, total, i, j, coeffA, coeffB, tensA, tensB, contracted},
  splitTerm[term_] := Module[{factors, tensFactors, coeffFactors},
    If[FreeQ[term, vc | g],
      Return[{term /. rep, 1}]
    ];
    If[Head[term] === Times,
      factors = List @@ term;
      tensFactors = Select[factors, !FreeQ[#, vc | g] &];
      coeffFactors = Select[factors, FreeQ[#, vc | g] &];
      Return[{(Times @@ coeffFactors) /. rep, Times @@ tensFactors}]
    ,
      Return[{1, term}]
    ]
  ];
  {coeffS, tensS} = splitTerm[temlist[[1]]];
  termsA = splitTerm /@ temlist[[2]];
  termsB = splitTerm /@ temlist[[3]];
  total = Sum[
    coeffA = termsA[[i, 1]];
    tensA = termsA[[i, 2]];
    coeffB = termsB[[j, 1]];
    tensB = termsB[[j, 2]];
    contracted = (tensS * tensA * tensB // Expand) /. rep;
    coeffA * coeffB * contracted
  , {i, 1, Length[termsA]}, {j, 1, Length[termsB]}];
  Return[coeffS * total]
];

(* Old SpecialMultiply *)
SpecialMultiplyOld[temlist_, h_, rep_] := Module[
  {scalar, listA, listB, totalB},
  scalar = temlist[[1]]/.rep;
  If[Length[temlist[[2]]] > Length[temlist[[3]]],
    listA = temlist[[2]]/.rep; 
    listB = temlist[[3]]/.rep,
    listA = temlist[[3]]/.rep; 
    listB = temlist[[2]]/.rep
  ];
  totalB = Total[listB]/.rep;
  Total @ Map[
    Collect[Expand[scalar * # * totalB] /. rep, _h, Together] &, 
    listA
  ] // Collect[#, _h, Factor] &
];

resOld = SpecialMultiplyOld[temlist, h, repMult];
resNew = Collect[SpecialMultiplyNew[temlist, h, repMult], _h, Factor];

Print["\n=== DEBUGGING TERM 4030 ==="];
Print["temlist[[1]] (scalar): ", InputForm[temlist[[1]]]];
Print["temlist[[2]] (listA) Length: ", Length[temlist[[2]]]];
Print["temlist[[3]] (listB) Length: ", Length[temlist[[3]]]];

Print["\ntemlist[[2]] (listA) elements:"];
Do[Print[jj, ": ", InputForm[temlist[[2, jj]]]], {jj, 1, Length[temlist[[2]]]}];

Print["\ntemlist[[3]] (listB) elements:"];
Do[Print[jj, ": ", InputForm[temlist[[3, jj]]]], {jj, 1, Length[temlist[[3]]]}];

Print["\nresOld: ", InputForm[resOld]];
Print["\nresNew: ", InputForm[resNew]];

diff = resOld - resNew // Expand // Simplify;
Print["\ndiff: ", InputForm[diff]];
