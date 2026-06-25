(* generate_sv.wl *)
$HistoryLength = 0;
rootDir = DirectoryName[$InputFileName];
If[rootDir === "", rootDir = Directory[]];
If[StringEndsQ[rootDir, "transform/"] || StringEndsQ[rootDir, "transform"] || StringEndsQ[rootDir, "scratch/"] || StringEndsQ[rootDir, "scratch"], rootDir = ParentDirectory[rootDir]];
SetDirectory[rootDir];
yOrderFinal = 7;
LaunchKernels[6];

ParallelEvaluate[
  evaluatedMPL0 = Import["allsvliste0_uptow8.txt", "String"] // StringTrim // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;
  evaluatedMPL1 = Import["allsvliste1_uptow8.txt", "String"] // StringTrim // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;
  evaluatedMPLInf = Import["allsvlisteinf_uptow8.txt", "String"] // StringTrim // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;
];

evaluatedMPL0 = Import["allsvliste0_uptow8.txt", "String"] // StringTrim // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;
evaluatedMPL1 = Import["allsvliste1_uptow8.txt", "String"] // StringTrim // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;
evaluatedMPLInf = Import["allsvlisteinf_uptow8.txt", "String"] // StringTrim // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;

len0 = Length[evaluatedMPL0];
len1 = Length[evaluatedMPL1];
lenInf = Length[evaluatedMPLInf];

(* Pre-compute zrep definitions up to power 10 *)
Print["Precomputing zrep definitions..."];
zrep1 = Dispatch@Flatten@Table[{
  Power[z, i] -> (Power[(1 - u + Sqrt[(-1 + u - v)^2 - 4 v] + v)/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i] -> (Power[(1 - u - Sqrt[(-1 + u - v)^2 - 4 v] + v)/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[z1, i] -> (Power[(1 - u + Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz1, i] -> (Power[(1 - u - Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
}, {i, 1, 10}];

zrep1P = Dispatch@Flatten@Table[{
  Power[z, i] -> (Power[1/2*(1 - u + v + Sqrt[-4 v + (1 - u + v)^2]), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i] -> (Power[1/2*(1 - u + v - Sqrt[-4 v + (1 - u + v)^2]), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[z1, i] -> (Power[1/2*(-1 - u + v + Sqrt[-4 v + (1 - u + v)^2]), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz1, i] -> (Power[1/2*(-1 - u + v - Sqrt[-4 v + (1 - u + v)^2]), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
}, {i, 1, 10}];

zrep0 = Dispatch@Flatten@Table[{
  Power[z, i] -> (Power[1/2*(1 + u + Sqrt[-4 u + (1 + u - v)^2] - v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i] -> (Power[1/2*(1 + u - Sqrt[-4 u + (1 + u - v)^2] - v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
}, {i, 1, 10}];

zrep0P = Dispatch@Flatten@Table[{
  Power[z, i] -> (Power[(-1 + u + v + Sqrt[-4 u v + (-1 + u + v)^2])/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i] -> (Power[(-1 + u + v - Sqrt[-4 u v + (-1 + u + v)^2])/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
}, {i, 1, 10}];

zrepInf = Dispatch@Flatten@Table[{
  Power[z, i] -> (Power[(1 + u - v - Sqrt[-4 u + (-1 - u + v)^2])/(2 u), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i] -> (Power[(1 + u - v + Sqrt[-4 u + (-1 - u + v)^2])/(2 u), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
}, {i, 1, 10}];

zrepInfP = Dispatch@Flatten@Table[{
  Power[z, i] -> (Power[(-1 + u + v - Sqrt[-4 u v + (-1 + u + v)^2])/(2 u), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i] -> (Power[(-1 + u + v + Sqrt[-4 u v + (-1 + u + v)^2])/(2 u), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
}, {i, 1, 10}];

ProcessTerm[termOld_, repRulesA_, repRulesB_, repRulesC_, zzToZRule_, negZRules_, zrep_, assumption_] := Module[
  {term1, term2, term3, exactExpr, s0, uPole, yOrderReq, finalSeriesEval},
  
  term1 = termOld /. repRulesA /. repRulesB /. repRulesC /. zzToZRule // Expand;
  term2 = term1 /. negZRules;
  term3 = Collect[term2, {z1, zz1, z, zz}, Factor];
  
  exactExpr = term3 /. zrep /. {v -> 1 - Y};
  
  s0 = Series[exactExpr /. {Log[u] -> 1, Zeta[_] -> 1}, {u, 0, 0}, {Y, 0, 1}, Assumptions -> {assumption, u > 0}];
  If[Head[s0] === SeriesData,
    uPole = Max[0, -s0[[4]]],
    uPole = Max[0, -Exponent[Normal[s0], u, Min]]
  ];
  
  yOrderReq = yOrderFinal + 2*uPole + 2;
  
  finalSeriesEval = Series[exactExpr /. {Log[u] -> logU}, {u, 0, 0}, {Y, 0, yOrderReq}, Assumptions -> {assumption, u > 0}] /. {logU -> Log[u]};
  
  Expand[Normal[finalSeriesEval]]
];
DistributeDefinitions[ProcessTerm, yOrderFinal, evaluatedMPL0, evaluatedMPL1, evaluatedMPLInf, zrep1, zrep1P, zrep0, zrep0P, zrepInf, zrepInfP];

(* === e1uv === *)
Print["Processing e1uv..."];
res1 = ParallelTable[
  ProcessTerm[evaluatedMPL1[[i]], 
    {-1 + z -> z1, -1 + zz -> zz1}, 
    {I[z, 1, 0] -> Log[u/v]},
    {f[a_] :> Zeta[a], f[3, 3] -> Zeta[3]^2/2, f[3, 5] -> Zeta[3]*Zeta[5] - f[5, 3]}, 
    {zz1 -> u/v/z1}, 
    {Power[z1, a_ /; a < 0] :> Power[zz1*v/u, -a]},
    zrep1,
    Y > 0
  ],
  {i, 1, len1}
];
Export["allsvliste1_uptow8_inuv.txt", ToString[InputForm[res1], PageWidth -> Infinity], "String"];
Print["Finished e1uv."];

(* === e1uvp === *)
Print["Processing e1uvp..."];
res1P = ParallelTable[
  ProcessTerm[evaluatedMPL1[[i]], 
    {-1 + z -> z1, -1 + zz -> zz1}, 
    {I[z, 1, 0] -> Log[u]},
    {f[a_] :> Zeta[a], f[3, 3] -> Zeta[3]^2/2, f[3, 5] -> Zeta[3]*Zeta[5] - f[5, 3]}, 
    {zz1 -> u/z1}, 
    {Power[z1, a_ /; a < 0] :> Power[zz1/u, -a]},
    zrep1P,
    Y < 0
  ],
  {i, 1, len1}
];
Export["allsvliste1_uptow8_inuvp.txt", ToString[InputForm[res1P], PageWidth -> Infinity], "String"];
Print["Finished e1uvp."];

(* === e0uv === *)
Print["Processing e0uv..."];
res0 = ParallelTable[
  ProcessTerm[evaluatedMPL0[[i]], 
    {}, 
    {I[z, 0, 0] -> Log[u]},
    {f[a_] :> Zeta[a], f[3, 3] -> Zeta[3]^2/2, f[3, 5] -> Zeta[3]*Zeta[5] - f[5, 3]}, 
    {zz -> u/z}, 
    {Power[z, a_ /; a < 0] :> Power[zz/u, -a]},
    zrep0,
    Y > 0
  ],
  {i, 1, len0}
];
Export["allsvliste0_uptow8_inuv.txt", ToString[InputForm[res0], PageWidth -> Infinity], "String"];
Print["Finished e0uv."];

(* === e0uvp === *)
Print["Processing e0uvp..."];
res0P = ParallelTable[
  ProcessTerm[evaluatedMPL0[[i]], 
    {}, 
    {I[z, 0, 0] -> Log[u/v]},
    {f[a_] :> Zeta[a], f[3, 3] -> Zeta[3]^2/2, f[3, 5] -> Zeta[3]*Zeta[5] - f[5, 3]}, 
    {zz -> u/z/v}, 
    {Power[z, a_ /; a < 0] :> Power[zz*v/u, -a]},
    zrep0P,
    Y < 0
  ],
  {i, 1, len0}
];
Export["allsvliste0_uptow8_inuvp.txt", ToString[InputForm[res0P], PageWidth -> Infinity], "String"];
Print["Finished e0uvp."];

(* === einfuv === *)
Print["Processing einfuv..."];
resInf = ParallelTable[
  ProcessTerm[evaluatedMPLInf[[i]], 
    {}, 
    {P[0] -> -Log[u]},
    {f[a_] :> Zeta[a], f[3, 3] -> Zeta[3]^2/2, f[3, 5] -> Zeta[3]*Zeta[5] - f[5, 3]}, 
    {zz -> 1/u/z}, 
    {Power[z, a_ /; a < 0] :> Power[zz*u, -a]},
    zrepInf,
    Y > 0
  ],
  {i, 1, lenInf}
];
Export["allsvlisteinf_uptow8_inuv.txt", ToString[InputForm[resInf], PageWidth -> Infinity], "String"];
Print["Finished einfuv."];

(* === einfuvp === *)
Print["Processing einfuvp..."];
resInfP = ParallelTable[
  ProcessTerm[evaluatedMPLInf[[i]], 
    {}, 
    {P[0] -> -Log[u/v]},
    {f[a_] :> Zeta[a], f[3, 3] -> Zeta[3]^2/2, f[3, 5] -> Zeta[3]*Zeta[5] - f[5, 3]}, 
    {zz -> v/u/z}, 
    {Power[z, a_ /; a < 0] :> Power[zz*u/v, -a]},
    zrepInfP,
    Y < 0
  ],
  {i, 1, lenInf}
];
Export["allsvlisteinf_uptow8_inuvp.txt", ToString[InputForm[resInfP], PageWidth -> Infinity], "String"];
Print["Finished einfuvp."];

CloseKernels[];
