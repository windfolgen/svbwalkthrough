(* scratch/test_linearsolve_profile.wl *)
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

(* Profile GenTensorProjectionNew *)
idxList = {{m[1], m[3]}, {m[2], m[5]}, {m[7], m[9]}};
tag = 2;
krep = {d2[1, tag] -> u};

Print["=== Profiling GenTensorProjectionNew on dim 24 ==="];

t0 = SessionTime[];
tensor = MPartition[idxList, tag];
l = Length[tensor];
Print["1. MPartition completed in: ", SessionTime[] - t0, "s. Basis size (l): ", l];

t0 = SessionTime[];
M = Table[
  ((tensor[[i]] * tensor[[j]] // Expand) /. krep),
  {i, 1, l}, {j, 1, l}
];
tM = SessionTime[] - t0;
Print["2. Matrix M constructed in: ", tM, "s"];

t0 = SessionTime[];
sol = LinearSolve[M, tensor];
tLS = SessionTime[] - t0;
Print["3. LinearSolve completed in: ", tLS, "s"];

t0 = SessionTime[];
solFactored = Factor /@ sol;
tFact = SessionTime[] - t0;
Print["4. Factorization completed in: ", tFact, "s"];
Print["Total New Method Time: ", tM + tLS + tFact, "s"];

(* --- Corrected SpecialMultiply Benchmark --- *)
Print["\n=== Corrected SpecialMultiply Benchmark ==="];

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
  
  Return[scalar * total]
];

rep = {d2[1, 3] -> 1, d2[2, 1] -> u, d2[2, 3] -> 1 - Y, d[a_, 1] :> 0, d[2, 3] -> (u + Y)/2, v -> 1 - Y};

Do[
  Print["\nBenchmark size N = ", n];
  
  (* Topology 1: free index is m[2] *)
  listA = Table[
    (h[i] + u*h[i+100]) * vc[5, m[1]] * g[m[1], m[2]],
    {i, 1, n}
  ];
  
  (* Topology 2: free index is also m[2], contracting with Topology 1 *)
  listB = Table[
    (h[j+1000] - Y*h[j+2000]) * vc[7, m[2]],
    {j, 1, n}
  ];
  
  temlist = {1, listA, listB};
  
  (* Benchmark old SpecialMultiply *)
  t0 = SessionTime[];
  resOld = SpecialMultiply[temlist, h, rep];
  tOld = SessionTime[] - t0;
  Print["  Old SpecialMultiply: ", tOld, "s"];
  
  (* Benchmark new SpecialMultiply (with Factor) *)
  t0 = SessionTime[];
  resNew = SpecialMultiplyNew[temlist, h, rep];
  tNew = SessionTime[] - t0;
  Print["  New SpecialMultiply: ", tNew, "s"];
  
  (* Benchmark faster SpecialMultiply (no Factor) *)
  t0 = SessionTime[];
  resFaster = SpecialMultiplyFaster[temlist, h, rep];
  tFaster = SessionTime[] - t0;
  Print["  Faster SpecialMultiply (no Factor): ", tFaster, "s"];
  
  (* Verify correctness *)
  resFasterFactored = Collect[resFaster, _h, Factor];
  diff = resOld - resFasterFactored // Expand // Simplify;
  If[diff === 0,
    Print["  SUCCESS: Results are identical!"],
    Print["  WARNING: Results differ! Diff: ", Short[diff, 10]]
  ];
, {n, {10, 20}}];

Print["\n=== Profiling complete ==="];
