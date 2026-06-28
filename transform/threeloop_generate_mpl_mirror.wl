(* threeloop_generate_mpl_mirror.wl *)
$HistoryLength = 0;
rootDir = DirectoryName[$InputFileName];
If[rootDir === "", rootDir = Directory[]];
If[StringEndsQ[rootDir, "transform/"] || StringEndsQ[rootDir, "transform"] || StringEndsQ[rootDir, "scratch/"] || StringEndsQ[rootDir, "scratch"], rootDir = ParentDirectory[rootDir]];
SetDirectory[rootDir];
yOrderFinal = 5;

Print["Importing three-loop datasets..."];
evaluatedMPL0 = Import["data/allsvlistmpl_threeloope0.txt", "String"] // StringTrim // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;
evaluatedMPL1 = Import["data/allsvlistmpl_threeloope1.txt", "String"] // StringTrim // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;

len0 = Length[evaluatedMPL0];
len1 = Length[evaluatedMPL1];

ProcessTerm[term_, preSub_, logSub_, zetaSub_, midSub_, postSub_, zSub1_, zzSub1_, z1Sub1_, zz1Sub1_, assumption_] := Module[
  {term1, term2, term3, z1S0, zz1S0, zS0, zzS0, vS0, temp, tempNorm, uPole, yOrderReq, z1S, zz1S, zS, zzS, vS, finalSeries, res},

  term1 = term /. preSub /. logSub /. zetaSub /. midSub // Expand;
  term2 = term1 /. postSub;
  term3 = Collect[term2, {z1, zz1, z, zz}, Factor];

  (* Base O(1) Taylor expansion to mathematically locate the depth of the 1/u pole *)
  vS0 = Series[1 - Y, {u, 0, 10}, {Y, 0, 1}, Assumptions -> {assumption, u > 0}];
  zS0 = Series[zSub1 /. {v -> 1 - Y}, {u, 0, 10}, {Y, 0, 1}, Assumptions -> {assumption, u > 0}];
  zzS0 = Series[zzSub1 /. {v -> 1 - Y}, {u, 0, 10}, {Y, 0, 1}, Assumptions -> {assumption, u > 0}];
  z1S0 = Series[z1Sub1 /. {v -> 1 - Y}, {u, 0, 10}, {Y, 0, 1}, Assumptions -> {assumption, u > 0}];
  zz1S0 = Series[zz1Sub1 /. {v -> 1 - Y}, {u, 0, 10}, {Y, 0, 1}, Assumptions -> {assumption, u > 0}];

  temp = term3 /. {z1 -> z1S0, zz1 -> zz1S0, z -> zS0, zz -> zzS0, v -> vS0};
  tempNorm = Normal[temp /. {Log[u] -> 1, Zeta[_] -> 1}];
  uPole = Max[0, -Exponent[tempNorm, u, Min]];

  (* Dynamically allocate Y depth to survive precision truncation *)
  yOrderReq = yOrderFinal + 2;

  (* Full expansion with rigorous assumptions to prevent branch-cut evaluation crashes *)
  vS = Series[1 - Y, {u, 0, 10}, {Y, 0, yOrderReq}, Assumptions -> {assumption, u > 0}];
  zS = Series[zSub1 /. {v -> 1 - Y}, {u, 0, 10}, {Y, 0, yOrderReq}, Assumptions -> {assumption, u > 0}];
  zzS = Series[zzSub1 /. {v -> 1 - Y}, {u, 0, 10}, {Y, 0, yOrderReq}, Assumptions -> {assumption, u > 0}];
  z1S = Series[z1Sub1 /. {v -> 1 - Y}, {u, 0, 10}, {Y, 0, yOrderReq}, Assumptions -> {assumption, u > 0}];
  zz1S = Series[zz1Sub1 /. {v -> 1 - Y}, {u, 0, 10}, {Y, 0, yOrderReq}, Assumptions -> {assumption, u > 0}];

  finalSeries = term3 /. {z1 -> z1S, zz1 -> zz1S, z -> zS, zz -> zzS, v -> vS};
  
  (* Expand to u^3 *)
  finalSeries = Series[finalSeries /. {Log[u] -> logU}, {u, 0, 3}, {Y, 0, yOrderReq}, Assumptions -> {assumption, u > 0}] /. {logU -> Log[u]};

  res = Expand[Normal[finalSeries]];
  ClearSystemCache[];
  res
];

(* === e1uv === *)
Print["Processing e1uv..."];
res1 = Table[
  Print["Processing term ", i, " of ", len1];
  ProcessTerm[evaluatedMPL1[[i]], 
    {-1 + z -> z1, -1 + zz -> zz1}, 
    {I[z, 1, 0] -> Log[u/v]},
    {f[a_] :> Zeta[a], f[3, 3] -> Zeta[3]^2/2, f[3, 5] -> Zeta[3]*Zeta[5] - f[5, 3]}, 
    {zz1 -> u/v/z1}, 
    {Power[z1, a_ /; a < 0] :> Power[zz1*v/u, -a]},
    (1 - u - Sqrt[(-1 + u - v)^2 - 4 v] + v)/(2 v), (* zzSub1 *)
    (1 - u + Sqrt[(-1 + u - v)^2 - 4 v] + v)/(2 v), (* zSub1 *)
    (1 - u - Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v), (* zz1Sub1 *)
    (1 - u + Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v), (* z1Sub1 *)
    Y > 0
  ],
  {i, 1, len1}
];
Export["data/allsvlistmpl_threeloope1_inuv_mirror.txt", ToString[InputForm[res1], PageWidth -> Infinity], "String"];
Print["Finished e1uv."];

(* === e1uvp === *)
Print["Processing e1uvp..."];
res1P = Table[
  Print["Processing term ", i, " of ", len1];
  ProcessTerm[evaluatedMPL1[[i]], 
    {-1 + z -> z1, -1 + zz -> zz1}, 
    {I[z, 1, 0] -> Log[u]},
    {f[a_] :> Zeta[a], f[3, 3] -> Zeta[3]^2/2, f[3, 5] -> Zeta[3]*Zeta[5] - f[5, 3]}, 
    {zz1 -> u/z1}, 
    {Power[z1, a_ /; a < 0] :> Power[zz1/u, -a]},
    1/2*(1 - u + v - Sqrt[-4 v + (1 - u + v)^2]), (* zzSub1 *)
    1/2*(1 - u + v + Sqrt[-4 v + (1 - u + v)^2]), (* zSub1 *)
    1/2*(-1 - u + v - Sqrt[-4 v + (1 - u + v)^2]), (* zz1Sub1 *)
    1/2*(-1 - u + v + Sqrt[-4 v + (1 - u + v)^2]), (* z1Sub1 *)
    Y < 0
  ],
  {i, 1, len1}
];
Export["data/allsvlistmpl_threeloope1_inuvp_mirror.txt", ToString[InputForm[res1P], PageWidth -> Infinity], "String"];
Print["Finished e1uvp."];

(* === e0uv === *)
Print["Processing e0uv..."];
res0 = Table[
  Print["Processing term ", i, " of ", len0];
  ProcessTerm[evaluatedMPL0[[i]], 
    {}, 
    {I[z, 0, 0] -> Log[u]},
    {f[a_] :> Zeta[a], f[3, 3] -> Zeta[3]^2/2, f[3, 5] -> Zeta[3]*Zeta[5] - f[5, 3]}, 
    {zz -> u/z}, 
    {Power[z, a_ /; a < 0] :> Power[zz/u, -a]},
    1/2*(1 + u - Sqrt[-4 u + (1 + u - v)^2] - v), (* zzSub1 *)
    1/2*(1 + u + Sqrt[-4 u + (1 + u - v)^2] - v), (* zSub1 *)
    0, 0,
    Y > 0
  ],
  {i, 1, len0}
];
Export["data/allsvlistmpl_threeloope0_inuv_mirror.txt", ToString[InputForm[res0], PageWidth -> Infinity], "String"];
Print["Finished e0uv."];

(* === e0uvp === *)
Print["Processing e0uvp..."];
res0P = Table[
  Print["Processing term ", i, " of ", len0];
  ProcessTerm[evaluatedMPL0[[i]], 
    {}, 
    {I[z, 0, 0] -> Log[u/v]},
    {f[a_] :> Zeta[a], f[3, 3] -> Zeta[3]^2/2, f[3, 5] -> Zeta[3]*Zeta[5] - f[5, 3]}, 
    {zz -> u/z/v}, 
    {Power[z, a_ /; a < 0] :> Power[zz*v/u, -a]},
    (-1 + u + v - Sqrt[-4 u v + (-1 + u + v)^2])/(2 v), (* zzSub1 *)
    (-1 + u + v + Sqrt[-4 u v + (-1 + u + v)^2])/(2 v), (* zSub1 *)
    0, 0,
    Y < 0
  ],
  {i, 1, len0}
];
Export["data/allsvlistmpl_threeloope0_inuvp_mirror.txt", ToString[InputForm[res0P], PageWidth -> Infinity], "String"];
Print["Finished e0uvp."];

Print["All done!"];
