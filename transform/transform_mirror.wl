#!/usr/bin/env wolframscript
(* ::Package:: *)

$HistoryLength = 0;

args = $ScriptCommandLine;
If[Length[args] < 2,
  Print["Usage: wolframscript -f transform_mirror.wl <input_file> [yOrderFinal=7]"];
  Exit[1];
];

inputFile = args[[2]];
yOrderFinal = If[Length[args] >= 3, ToExpression[args[[3]]], 7];

If[!FileExistsQ[inputFile],
  Print["File not found: ", inputFile];
  Exit[1];
];

(* Detect limit type *)
limitType = If[StringContainsQ[inputFile, "einf"], "einf",
            If[StringContainsQ[inputFile, "e0"], "e0",
            If[StringContainsQ[inputFile, "e1"], "e1", "unknown"]]];

If[limitType === "unknown",
  Print["Error: Could not detect limit type (e0, e1, einf) from filename: ", inputFile];
  Exit[1];
];

(* Output files *)
baseName = FileBaseName[inputFile];
outUV = baseName <> "_inuv_mirror.txt";
outUVP = baseName <> "_inuvp_mirror.txt";

Print["=== Transformation Pipeline (Mirror) ==="];
Print["Input:   ", inputFile];
Print["Limit:   ", limitType];
Print["yOrder:  ", yOrderFinal];
Print["Outputs: ", outUV, ", ", outUVP];

evaluatedMPL = If[FileExtension[inputFile] === "m",
  Import[inputFile],
  Module[{str = StringTrim[Import[inputFile, "String"]]},
    If[StringStartsQ[str, "["] && StringEndsQ[str, "]"],
      ToExpression["{" <> StringTake[str, {2, -2}] <> "}"]
    ,
      ToExpression[str]
    ]
  ]
];

If[Head[evaluatedMPL] =!= List, 
  Print["Error: Failed to parse input file into a Mathematica List."];
  Exit[1];
];

len = Length[evaluatedMPL];
Print["Loaded ", len, " elements."];

ProcessTerm[term_, preSub_, logSub_, zetaSub_, midSub_, postSub_, zSub1_, zzSub1_, z1Sub1_, zz1Sub1_, assumption_] := Module[
  {term1, term2, term3, z1S0, zz1S0, zS0, zzS0, vS0, temp, tempNorm, uPole, yOrderReq, z1S, zz1S, zS, zzS, vS, finalSeries},

  term1 = term /. preSub /. logSub /. zetaSub /. midSub // Expand;
  term2 = term1 /. postSub;
  term3 = Collect[term2, {z1, zz1, z, zz}, Factor];

  (* Base O(u^3) Taylor expansion to mathematically locate the depth of the 1/u pole *)
  vS0 = Series[1 - Y, {u, 0, 10}, {Y, 0, 1}, Assumptions -> {assumption, u > 0}];
  zS0 = Series[zSub1 /. {v -> 1 - Y}, {u, 0, 10}, {Y, 0, 1}, Assumptions -> {assumption, u > 0}];
  zzS0 = Series[zzSub1 /. {v -> 1 - Y}, {u, 0, 10}, {Y, 0, 1}, Assumptions -> {assumption, u > 0}];
  z1S0 = Series[z1Sub1 /. {v -> 1 - Y}, {u, 0, 10}, {Y, 0, 1}, Assumptions -> {assumption, u > 0}];
  zz1S0 = Series[zz1Sub1 /. {v -> 1 - Y}, {u, 0, 10}, {Y, 0, 1}, Assumptions -> {assumption, u > 0}];

  temp = term3 /. {z1 -> z1S0, zz1 -> zz1S0, z -> zS0, zz -> zzS0, v -> vS0};
  tempNorm = Normal[temp /. {Log[u] -> 1, Zeta[_] -> 1}];
  uPole = Max[0, -Exponent[tempNorm, u, Min]];

  (* Dynamically allocate Y depth to survive precision truncation *)
  yOrderReq = yOrderFinal + 2*uPole + 2;

  (* Full expansion with rigorous assumptions to prevent branch-cut evaluation crashes *)
  vS = Series[1 - Y, {u, 0, 10}, {Y, 0, yOrderReq}, Assumptions -> {assumption, u > 0}];
  zS = Series[zSub1 /. {v -> 1 - Y}, {u, 0, 10}, {Y, 0, yOrderReq}, Assumptions -> {assumption, u > 0}];
  zzS = Series[zzSub1 /. {v -> 1 - Y}, {u, 0, 10}, {Y, 0, yOrderReq}, Assumptions -> {assumption, u > 0}];
  z1S = Series[z1Sub1 /. {v -> 1 - Y}, {u, 0, 10}, {Y, 0, yOrderReq}, Assumptions -> {assumption, u > 0}];
  zz1S = Series[zz1Sub1 /. {v -> 1 - Y}, {u, 0, 10}, {Y, 0, yOrderReq}, Assumptions -> {assumption, u > 0}];

  finalSeries = term3 /. {z1 -> z1S, zz1 -> zz1S, z -> zS, zz -> zzS, v -> vS};
  
  (* Expand to u^3 *)
  finalSeries = Series[finalSeries /. {Log[u] -> logU}, {u, 0, 3}, {Y, 0, yOrderReq}, Assumptions -> {assumption, u > 0}] /. {logU -> Log[u]};

  finalSeries
];

LaunchKernels[];
DistributeDefinitions[ProcessTerm, yOrderFinal];

Which[
  limitType === "e1",
  Print["Processing limit e1 (uv)..."];
  resUV = ParallelTable[
    ProcessTerm[evaluatedMPL[[i]], 
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
    ], {i, 1, len}];
  Export[outUV, ToString[InputForm[resUV], PageWidth -> Infinity], "String"];

  Print["Processing limit e1 (uvp)..."];
  resUVP = ParallelTable[
    ProcessTerm[evaluatedMPL[[i]], 
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
    ], {i, 1, len}];
  Export[outUVP, ToString[InputForm[resUVP], PageWidth -> Infinity], "String"];
  ,
  
  limitType === "e0",
  Print["Processing limit e0 (uv)..."];
  resUV = ParallelTable[
    ProcessTerm[evaluatedMPL[[i]], 
      {}, 
      {I[z, 0, 0] -> Log[u]},
      {f[a_] :> Zeta[a], f[3, 3] -> Zeta[3]^2/2, f[3, 5] -> Zeta[3]*Zeta[5] - f[5, 3]}, 
      {zz -> u/z}, 
      {Power[z, a_ /; a < 0] :> Power[zz/u, -a]}, 
      1/2*(1 + u - Sqrt[-4 u + (1 + u - v)^2] - v), (* zzSub1 *)
      1/2*(1 + u + Sqrt[-4 u + (1 + u - v)^2] - v), (* zSub1 *)
      0, 0,
      Y > 0
    ], {i, 1, len}];
  Export[outUV, ToString[InputForm[resUV], PageWidth -> Infinity], "String"];

  Print["Processing limit e0 (uvp)..."];
  resUVP = ParallelTable[
    ProcessTerm[evaluatedMPL[[i]], 
      {}, 
      {I[z, 0, 0] -> Log[u/v]},
      {f[a_] :> Zeta[a], f[3, 3] -> Zeta[3]^2/2, f[3, 5] -> Zeta[3]*Zeta[5] - f[5, 3]}, 
      {zz -> u/z/v}, 
      {Power[z, a_ /; a < 0] :> Power[zz*v/u, -a]}, 
      (-1 + u + v - Sqrt[-4 u v + (-1 + u + v)^2])/(2 v), (* zzSub1 *)
      (-1 + u + v + Sqrt[-4 u v + (-1 + u + v)^2])/(2 v), (* zSub1 *)
      0, 0,
      Y < 0
    ], {i, 1, len}];
  Export[outUVP, ToString[InputForm[resUVP], PageWidth -> Infinity], "String"];
  ,
 
  limitType === "einf",
  Print["Processing limit einf (uv)..."];
  resUV = ParallelTable[
    ProcessTerm[evaluatedMPL[[i]], 
      {}, 
      {P[0] -> -Log[u]},
      {f[a_] :> Zeta[a], f[3, 3] -> Zeta[3]^2/2, f[3, 5] -> Zeta[3]*Zeta[5] - f[5, 3]}, 
      {zz -> 1/u/z}, 
      {Power[z, a_ /; a < 0] :> Power[zz*u, -a]}, 
      (1 + u - v + Sqrt[-4 u + (-1 - u + v)^2])/(2 u), (* zzSub1 *)
      (1 + u - v - Sqrt[-4 u + (-1 - u + v)^2])/(2 u), (* zSub1 *)
      0, 0,
      Y > 0
    ], {i, 1, len}];
  Export[outUV, ToString[InputForm[resUV], PageWidth -> Infinity], "String"];

  Print["Processing limit einf (uvp)..."];
  resUVP = ParallelTable[
    ProcessTerm[evaluatedMPL[[i]], 
      {}, 
      {P[0] -> -Log[u/v]},
      {f[a_] :> Zeta[a], f[3, 3] -> Zeta[3]^2/2, f[3, 5] -> Zeta[3]*Zeta[5] - f[5, 3]}, 
      {zz -> v/u/z}, 
      {Power[z, a_ /; a < 0] :> Power[zz*u/v, -a]},  
      (-1 + u + v + Sqrt[-4 u v + (-1 + u + v)^2])/(2 u), (* zzSub1 *)
      (-1 + u + v - Sqrt[-4 u v + (-1 + u + v)^2])/(2 u), (* zSub1 *)
      0, 0,
      Y < 0
    ], {i, 1, len}];
  Export[outUVP, ToString[InputForm[resUVP], PageWidth -> Infinity], "String"];
];

Print["Done!"];
CloseKernels[];
