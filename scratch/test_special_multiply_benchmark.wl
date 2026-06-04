(* scratch/test_special_multiply_benchmark.wl *)
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

(* Define even faster SpecialMultiplyFaster (no Factor, just Collect/Together or nothing) *)
ClearAll[SpecialMultiplyFaster];
SpecialMultiplyFaster[temlist_, h_, rep_] := Module[
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
  
  (* We just return scalar * total without factoring individual terms *)
  Return[scalar * total]
];

rep = {d2[1, 3] -> 1, d2[2, 1] -> u, d2[2, 3] -> 1 - Y, d[a_, 1] :> 0, d[2, 3] -> (u + Y)/2, v -> 1 - Y};

Do[
  Print["\n=== Benchmarking with list size N = ", n, " ==="];
  
  listA = Table[
    (h[i] + u*h[i+100]) * vc[5, m[1]] * g[m[1], m[2]],
    {i, 1, n}
  ];
  
  listB = Table[
    (h[j+1000] - Y*h[j+2000]) * vc[7, m[2]] * g[m[2], m[3]],
    {j, 1, n}
  ];
  
  temlist = {1, listA, listB};
  
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
  
  (* Benchmark faster SpecialMultiply *)
  t0 = SessionTime[];
  resFaster = SpecialMultiplyFaster[temlist, h, rep];
  tFaster = SessionTime[] - t0;
  Print["Faster SpecialMultiply (no Factor) Time: ", tFaster, "s"];
  
  (* Check correctness of Faster after Factor *)
  resFasterFactored = Collect[resFaster, _h, Factor];
  diff = resOld - resFasterFactored // Expand // Simplify;
  If[diff === 0,
    Print["SUCCESS: Faster results are identical after factoring!"],
    Print["WARNING: Faster results differ! Diff: ", Short[diff, 10]]
  ];
, {n, {10, 20, 50}}];

Print["\n=== All benchmarks complete ==="];
