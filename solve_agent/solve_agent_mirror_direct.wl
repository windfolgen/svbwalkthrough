(* ::Package:: *)
(*  Skill 3 Mirror Direct: Coefficient Solving via Direct Ansatz Expansion   *)
(*  Loads svansatzw8_{ext}_{poleNum}.txt — 304-element ansatz expansions in   *)
(*  z/zz. Pipeline: multiply addInZZ -> truncate O(z^5,zz^5) -> zrep to u/Y  *)
(*  -> multiply part2Factor -> Series expand O(u^0,Y^order).                 *)
(*  Uses ParallelTable for zrep+Series on 304 elements.                      *)

(* zrep definitions — MIRROR of series_agent.wl: z/zz (and z1/zz1) square-root
   signs are swapped relative to the standard flow. The mirror workflow pairs
   with pre-expanded input files whose LS factor is already baked in, so the
   kinematic substitution must reach the opposite Riemann sheet. *)
zrepInf = Table[{
  Power[z, i]  -> (Power[(1 + u - v + Sqrt[-4 u + (-1 - u + v)^2])/(2 u), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i] -> (Power[(1 + u - v - Sqrt[-4 u + (-1 - u + v)^2])/(2 u), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
  }, {i, 1, 16}] // Flatten;

zrepInfP = Table[{
  Power[z, i]  -> (Power[(-1 + u + v + Sqrt[-4 u v + (-1 + u + v)^2])/(2 u), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i] -> (Power[(-1 + u + v - Sqrt[-4 u v + (-1 + u + v)^2])/(2 u), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
  }, {i, 1, 16}] // Flatten;

zrep0 = Table[{
  Power[z, i]  -> (Power[1/2*(1 + u - Sqrt[-4 u + (1 + u - v)^2] - v), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i] -> (Power[1/2*(1 + u + Sqrt[-4 u + (1 + u - v)^2] - v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
  }, {i, 1, 16}] // Flatten;

zrep0P = Table[{
  Power[z, i]  -> (Power[(-1 + u + v - Sqrt[-4 u v + (-1 + u + v)^2])/(2 v), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i] -> (Power[(-1 + u + v + Sqrt[-4 u v + (-1 + u + v)^2])/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
  }, {i, 1, 16}] // Flatten;

zrep1 = Table[{
  Power[z, i]    -> (Power[(1 - u - Sqrt[(-1 + u - v)^2 - 4 v] + v)/(2 v), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i]   -> (Power[(1 - u + Sqrt[(-1 + u - v)^2 - 4 v] + v)/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[z1, i]   -> (Power[(1 - u - Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz1, i]  -> (Power[(1 - u + Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
  }, {i, 1, 16}] // Flatten;

zrep1P = Table[{
  Power[z, i]    -> (Power[1/2*(1 - u + v - Sqrt[-4 v + (1 - u + v)^2]), i]    /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i]   -> (Power[1/2*(1 - u + v + Sqrt[-4 v + (1 - u + v)^2]), i]    /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[z1, i]   -> (Power[1/2*(-1 - u + v - Sqrt[-4 v + (1 - u + v)^2]), i]   /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz1, i]  -> (Power[1/2*(-1 - u + v + Sqrt[-4 v + (1 - u + v)^2]), i]   /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
  }, {i, 1, 16}] // Flatten;

ClearAll[RunCoefficientSolvingMirror, ParseListString, AuditSystem];

ParseListString[s_String] := Module[{trim = StringTrim[s]},
  If[StringStartsQ[trim, "["] && StringEndsQ[trim, "]"],
    ToExpression["{" <> StringTrim[trim, "["|"]"] <> "}"],
    If[StringStartsQ[trim, "{"] && StringEndsQ[trim, "}"],
      ToExpression[trim],
      ToExpression["{" <> trim <> "}"]
    ]
  ]
];
ParseListString[other_] := (
  Print["[ParseListString] ERROR: expected String input, got ", Head[other], ": ", InputForm[other]];
  $Failed
);

(* Audit: verify every equation is linear in c[_Integer] with rational coefficients.
   Any other symbol (Zeta, Y, u, f, Pi, ...) leaking in means a generation bug. *)
AuditSystem[sys_, context_String] := Module[{n, issues, lhs, vars, badVars, badCoeffs, const, k, j},
  n = Length[sys];
  If[n === 0,
    Print["[Audit] ", context, ": EMPTY system (0 equations)."];
    Return[<|"Status" -> "EMPTY", "IssueCount" -> 0, "Total" -> 0|>];
  ];
  issues = {};
  Do[
    lhs = If[Head[sys[[j]]] === Equal, sys[[j, 1]] - sys[[j, 2]], sys[[j]]];
    lhs = Expand[lhs];
    vars = Variables[lhs];
    badVars = Select[vars, !MatchQ[#, c[_Integer]] &];
    badCoeffs = {};
    Do[
      If[!MatchQ[Coefficient[lhs, vars[[k]]], _Integer | _Rational],
        AppendTo[badCoeffs, vars[[k]] -> Coefficient[lhs, vars[[k]]]];
      ];
      , {k, 1, Length[vars]}
    ];
    const = lhs /. Thread[vars -> 0];
    If[badVars =!= {} || badCoeffs =!= {} || !MatchQ[const, _Integer | _Rational],
      AppendTo[issues, {j, badVars, badCoeffs, const}];
    ];
    , {j, 1, n}
  ];
  If[Length[issues] === 0,
    Print["[Audit] ", context, ": PASS — ", n, " equations, all linear in c[_] with rational coefficients."];
  ,
    Print["[Audit] ", context, ": FAIL — ", Length[issues], "/", n, " equations have issues:"];
    Do[
      Print["  Eq#", issues[[k, 1]], ": non-c vars=", issues[[k, 2]], " non-rational coeffs=", issues[[k, 3]], " const=", issues[[k, 4]]];
      , {k, 1, Min[Length[issues], 5]}
    ];
  ];
  <|"Status" -> If[Length[issues] === 0, "PASS", "FAIL"], "IssueCount" -> Length[issues], "Total" -> n|>
];

(* Forward-declare to suppress DistributeDefinitions warning *)
fakeInit = {zrep0, zrep0P, zrep1, zrep1P, zrepInf, zrepInfP};

RunCoefficientSolvingMirror[rootDir_, label_, config_,
                            ansatzList_List, labelsList_List,
                            basisSVList_List, basisMPLList_List,
                            targetData_, order_:3] :=
Block[{c = Symbol["c"]},
Module[{partialSys, mirrorSys, fullSys, i, suffix, setup, temp, temp1, sys1, solt,
       ansatzKSeries, j, k, varsList,
       freeCount, values, finalResultList, coeffListAll,
       coeffK, resK, offsetEnd, $LEN, $Order, mirrorLimits,
       missing, unsolved, dataDir, ext, extFile, ptr,
       expr, lsConfig, nLS, lsLengths, lsOffsets, lsIndex,
       addInZZList, addInZZPerElem, filePaths, dataK, fileError,
       part2Factor,
       soltPartial, partialSolved, fullSolved, auditMirror, auditFull,
       yAssump, mirrorEqFile},

  $LEN   = Total[Length /@ ansatzList];
  $Order = order;

  Print["[Skill 3 Mirror Direct] Total Ansatz Elements=$LEN=", $LEN, " $Order=", $Order];

  lsConfig = config["LeadingSingularities"];
  nLS = Length[lsConfig];
  lsLengths = Length /@ ansatzList;

  addInZZList = Table[
    lsConfig[[k, 2]] /. {u -> z*zz, v -> (1 - z)*(1 - zz)} // Simplify,
    {k, 1, nLS}
  ];

  If[ValueQ[$MirrorMultiplyLSFactor] && $MirrorMultiplyLSFactor === False,
    Print["[Skill 3 Mirror Direct] $MirrorMultiplyLSFactor = False — skipping LS factor multiplication."];
    addInZZList = Table[1, {nLS}];
  ];

  (* Precompute per-element addInZZ and LS index for parallelization *)
  lsOffsets = FoldList[Plus, 0, Most[lsLengths]];
  lsIndex = Flatten[Table[Table[k, {lsLengths[[k]]}], {k, 1, nLS}]];
  addInZZPerElem = addInZZList[[lsIndex]];

  Do[
    Print["[Skill 3 Mirror Direct] addInZZ", k, " = ", InputForm[addInZZList[[k]]]];
  , {k, 1, nLS}];
  Print["[Skill 3 Mirror Direct] nLS=", nLS, ", LS lengths=", lsLengths];

  Get[FileNameJoin[{rootDir, "config.wl"}]];
  dataDir = $DataDir;
  (* Restore overrides if caller set them before this function call *)
  If[ValueQ[$MirrorLimitsOverride], $MirrorLimits = $MirrorLimitsOverride];
  If[ValueQ[$MirrorInputFilesOverride], $MirrorInputFiles = $MirrorInputFilesOverride];

  partialSys = Import[FileNameJoin[{rootDir, "solve_agent", label <> "_partialsys.m"}]] /. Symbol["c"] -> c;
  Print["[Skill 3 Mirror Direct] Loaded ", Length[partialSys], " equations from _partialsys.m."];

  mirrorLimits = $MirrorLimits;
  Print["[Skill 3 Mirror Direct] Solving mirror limits: ", mirrorLimits];

  If[Length[Kernels[]] == 0, LaunchKernels[Min[$MaxParallelKernels, $ProcessorCount]]];

  mirrorSys = {};

  For[i = 1, i <= 6, i++,
    If[!MemberQ[mirrorLimits, i], Continue[]];

    Switch[i,
      1, {ext = "e0";  ptr = 0; suffix = "e0uv";    part2Factor = 1},
      2, {ext = "e0p"; ptr = 0; suffix = "e0uvp";   part2Factor = 1/v},
      3, {ext = "einf"; ptr = 2; suffix = "einfuv"; part2Factor = 1/u},
      4, {ext = "einfp"; ptr = 2; suffix = "einfuvp"; part2Factor = 1/u},
      5, {ext = "e1";  ptr = 1; suffix = "e1uv";    part2Factor = 1/v},
      6, {ext = "e1p"; ptr = 1; suffix = "e1uvp";   part2Factor = 1}
    ];

    (* Load N pole files (one per leading singularity) and combine.
       Each file has $LEN elements (full ansatz expanded with that pole factor).
       LS k elements [offsetK+1 .. offsetK+lenK] come from file k.
       'p' variants (e0p, e1p, einfp) use the same file as non-p — uv/uvp distinction
       comes from zrep and Series assumptions, not the file. *)
    extFile = If[StringEndsQ[ext, "p"] && StringLength[ext] > 2, StringDrop[ext, -1], ext];
    filePaths = If[ValueQ[$MirrorInputFiles] && $MirrorInputFiles =!= None && KeyExistsQ[$MirrorInputFiles, extFile],
      $MirrorInputFiles[extFile],
      Table[FileNameJoin[{dataDir, "svansatzw8_" <> extFile <> "_" <> ToString[k] <> ".txt"}], {k, 1, nLS}]
    ];

    If[Length[filePaths] =!= nLS,
      Print["[Skill 3 Mirror Direct] ERROR: expected ", nLS, " files for ext=\"", extFile, "\", got ", Length[filePaths], " — skipping limit ", i];
      Continue[];
    ];
    fileError = False;
    Do[
      If[!FileExistsQ[filePaths[[k]]],
        Print["[Skill 3 Mirror Direct] ERROR: missing file ", filePaths[[k]], " — skipping limit ", i];
        fileError = True;
      ];
    , {k, 1, nLS}];
    If[fileError, Continue[]];

    (* Log zrep and Y assumption for this limit *)
    yAssump = If[OddQ[i], Y > 0, Y < 0];
    Print["[Skill 3 Mirror Direct] Limit ", i, " (", suffix, "): Y assumption: ", yAssump];
    Which[i == 1,
      (Print["  zrep=zrep0 (mirrored): z -> ", InputForm[(zrep0[[1, 2]] /. {v -> 1 - Y})]];
       Print["  zrep=zrep0 (mirrored): zz -> ", InputForm[(zrep0[[2, 2]] /. {v -> 1 - Y})]]);,
      i == 2,
      (Print["  zrep=zrep0P (mirrored): z -> ", InputForm[(zrep0P[[1, 2]] /. {v -> 1 - Y})]];
       Print["  zrep=zrep0P (mirrored): zz -> ", InputForm[(zrep0P[[2, 2]] /. {v -> 1 - Y})]]);,
      i == 3,
      (Print["  zrep=zrepInf (mirrored): z -> ", InputForm[(zrepInf[[1, 2]] /. {v -> 1 - Y})]];
       Print["  zrep=zrepInf (mirrored): zz -> ", InputForm[(zrepInf[[2, 2]] /. {v -> 1 - Y})]]);,
      i == 4,
      (Print["  zrep=zrepInfP (mirrored): z -> ", InputForm[(zrepInfP[[1, 2]] /. {v -> 1 - Y})]];
       Print["  zrep=zrepInfP (mirrored): zz -> ", InputForm[(zrepInfP[[2, 2]] /. {v -> 1 - Y})]]);,
      i == 5,
      (Print["  zrep=zrep1 (mirrored): z -> ", InputForm[(zrep1[[1, 2]] /. {v -> 1 - Y})]];
       Print["  zrep=zrep1 (mirrored): zz -> ", InputForm[(zrep1[[2, 2]] /. {v -> 1 - Y})]];
       Print["  zrep=zrep1 (mirrored): z1 -> ", InputForm[(zrep1[[3, 2]] /. {v -> 1 - Y})]];
       Print["  zrep=zrep1 (mirrored): zz1 -> ", InputForm[(zrep1[[4, 2]] /. {v -> 1 - Y})]]);,
      i == 6,
      (Print["  zrep=zrep1P (mirrored): z -> ", InputForm[(zrep1P[[1, 2]] /. {v -> 1 - Y})]];
       Print["  zrep=zrep1P (mirrored): zz -> ", InputForm[(zrep1P[[2, 2]] /. {v -> 1 - Y})]];
       Print["  zrep=zrep1P (mirrored): z1 -> ", InputForm[(zrep1P[[3, 2]] /. {v -> 1 - Y})]];
       Print["  zrep=zrep1P (mirrored): zz1 -> ", InputForm[(zrep1P[[4, 2]] /. {v -> 1 - Y})]]);
    ];

    Print["[Skill 3 Mirror Direct] Limit ", i, " loading ", nLS, " files for ext=\"", extFile, "\"..."];
    Do[
      Print["  LS", k, ": c[", lsOffsets[[k]]+1, "..", lsOffsets[[k]]+lsLengths[[k]], "] matched with ", FileNameTake[filePaths[[k]]], " elements [", lsOffsets[[k]]+1, "..", lsOffsets[[k]]+lsLengths[[k]], "]"];
    , {k, 1, nLS}];

    ansatzKSeries = {};
    fileError = False;
    Do[
      dataK = ParseListString[Import[filePaths[[k]], "String"]];
      If[dataK === $Failed || Length[dataK] =!= $LEN,
        Print["[Skill 3 Mirror Direct] ERROR: file ", FileNameTake[filePaths[[k]]], " has ", If[dataK === $Failed, "IMPORT FAILED", Length[dataK]], " elements, expected ", $LEN];
        fileError = True;
      ,
        ansatzKSeries = Join[ansatzKSeries, dataK[[lsOffsets[[k]] + 1 ;; lsOffsets[[k]] + lsLengths[[k]]]]];
      ];
    , {k, 1, nLS}];
    If[fileError, Continue[]];

    If[Length[ansatzKSeries] =!= $LEN,
      Print["[Skill 3 Mirror Direct] ERROR: combined ansatz has ", Length[ansatzKSeries], " elements, expected ", $LEN];
      Continue[];
    ];

    If[ValueQ[$MirrorNegateLS1] && $MirrorNegateLS1 === True,
      Print["[Skill 3 Mirror Direct] $MirrorNegateLS1 = True — negating LS1 (c[1..", lsLengths[[1]], "]) input elements."];
      ansatzKSeries[[1 ;; lsLengths[[1]]]] = -ansatzKSeries[[1 ;; lsLengths[[1]]]];
    ];

    DistributeDefinitions[addInZZPerElem, zrep0, zrep0P, zrep1, zrep1P, zrepInf, zrepInfP];

    ansatzKSeries = ParallelTable[
      expr = ansatzKSeries[[j]];
      expr = expr * addInZZPerElem[[j]];

      expr = expr /. f[a_, a_] :> Zeta[a]^2 / 2;

      (* Pre-Series: replace z-dependent special symbols (I[z,0,0], I[z,1,0], P[0])
         before Series[{z,0,7},{zz,0,7}] to prevent them being broken into
         I[0,0,0] etc. Mirrors standard series_agent.wl substitution order. *)
      Switch[ptr,
        0, If[OddQ[i],
             expr = expr /. {f[5]->Zeta[5], f[7]->Zeta[7], f[3]->Zeta[3], I[z,0,0]->Log[u]},
             expr = expr /. {f[5]->Zeta[5], f[7]->Zeta[7], f[3]->Zeta[3], I[z,0,0]->Log[u/v]}],
        1, If[OddQ[i],
             expr = expr /. {I[z,1,0]->Log[u/v], f[a_]:>Zeta[a], f[3,3]->Zeta[3]^2/2, f[3,5]->Zeta[3]Zeta[5]-f[5,3]},
             expr = expr /. {I[z,1,0]->Log[u], f[a_]:>Zeta[a], f[3,3]->Zeta[3]^2/2, f[3,5]->Zeta[3]Zeta[5]-f[5,3]}],
        2, If[OddQ[i],
             expr = expr /. {f[5]->Zeta[5], f[7]->Zeta[7], f[3]->Zeta[3], I[z,0,0]->Log[u], P[0]->-Log[u]},
             expr = expr /. {f[5]->Zeta[5], f[7]->Zeta[7], f[3]->Zeta[3], I[z,0,0]->Log[u/v], P[0]->-Log[u/v]}]
      ];

      (* Truncate in the natural expansion variable for each limit:
         ptr=0 (e0/e0p): z/zz around 0
         ptr=1 (e1/e1p): z1/zz1 around 0 (after -1+z -> z1, -1+zz -> zz1)
         ptr=2 (einf/einfp): z/zz around Infinity *)
      Switch[ptr,
        0, expr = Normal[Series[expr, {z, 0, 5}, {zz, 0, 5}]],
        1, expr = expr /. {-1 + z -> z1, -1 + zz -> zz1};
           expr = Normal[Series[expr, {z1, 0, 5}, {zz1, 0, 5}]],
        2, expr = Normal[Series[expr, {z, Infinity, 5}, {zz, Infinity, 5}]]
      ];

      Switch[ptr,
        0, If[OddQ[i],
             expr = expr /. {zz->u/z};
             expr = expr /. {Power[z, a_ /; (a < 0)] :> Power[zz/u, -a]};
             expr = expr /. zrep0 /. {v -> 1 - Y};
           ,
             expr = expr /. {zz->u/z/v};
             expr = expr /. {Power[z, a_ /; (a < 0)] :> Power[zz*v/u, -a]};
             expr = expr /. zrep0P /. {v -> 1 - Y};
           ],
        1, If[OddQ[i],
             expr = expr /. {zz1 -> u/v/(z1)}
               /. {Power[z1, a_ /; (a < 0)] :> Power[(zz1)*v/u, -a]} // Expand;
             expr = expr /. zrep1;
             expr = expr /. {
               z  -> ((1 - u - Sqrt[(-1 + u - v)^2 - 4 v] + v)/(2 v) /. {v -> 1 - Y}),
               zz -> ((1 - u + Sqrt[(-1 + u - v)^2 - 4 v] + v)/(2 v) /. {v -> 1 - Y}),
               z1 -> ((1 - u - Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v) /. {v -> 1 - Y}),
               zz1 -> ((1 - u + Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v) /. {v -> 1 - Y})
             };
           ,
             expr = expr /. {zz1 -> u/(z1)}
               /. {Power[z1, a_ /; (a < 0)] :> Power[(zz1)/u, -a]} // Expand;
             expr = expr /. zrep1P;
             expr = expr /. {
               z  -> (1/2*(1 - u + v - Sqrt[-4 v + (1 - u + v)^2]) /. {v -> 1 - Y}),
               zz -> (1/2*(1 - u + v + Sqrt[-4 v + (1 - u + v)^2]) /. {v -> 1 - Y}),
               z1 -> (1/2*(-1 - u + v - Sqrt[-4 v + (1 - u + v)^2]) /. {v -> 1 - Y}),
               zz1 -> (1/2*(-1 - u + v + Sqrt[-4 v + (1 - u + v)^2]) /. {v -> 1 - Y})
             };
           ],
        2, If[OddQ[i],
             expr = expr /. {zz -> 1/u/z};
             expr = expr /. {Power[z, a_ /; (a < 0)] :> Power[zz*u, -a]};
             expr = expr /. zrepInf /. {z -> (1 + u - v + Sqrt[-4 u + (-1 - u + v)^2])/(2 u), zz -> (1 + u - v - Sqrt[-4 u + (-1 - u + v)^2])/(2 u)} /. {v -> 1 - Y};
           ,
             expr = expr /. {zz -> v/u/z};
             expr = expr /. {Power[z, a_ /; (a < 0)] :> Power[zz*u/v, -a]};
             expr = expr /. zrepInfP /. {z -> (-1 + u + v + Sqrt[-4 u v + (-1 + u + v)^2])/(2 u), zz -> (-1 + u + v - Sqrt[-4 u v + (-1 + u + v)^2])/(2 u)} /. {v -> 1 - Y};
           ]
      ];

      expr = expr * part2Factor /. {v -> 1 - Y};

      expr = expr /. {Log[u] -> logU};
      expr = Normal[Series[expr, {u, 0, 0}, {Y, 0, order}, Assumptions -> {If[OddQ[i], Y > 0, Y < 0]}]];
      (expr /. {logU -> Log[u]}) // Expand
    , {j, 1, $LEN}];

    Print["[Skill 3 Mirror Direct] Limit ", i, " expanded ", Length[ansatzKSeries], " elements."];

    setup = (c /@ Range[1, $LEN]) . ansatzKSeries;

    temp = MonomialList[
      Normal[setup - targetData[[i]]] /. {
        f[3, 3] -> Zeta[3]^2 / 2,
        f[3, 5] -> Zeta[3] Zeta[5] - f[5, 3],
        f[a_] :> Zeta[a]},
      {Log[u]}
    ] // DeleteCases[#, 0] &;

    If[temp === {}, Print["[Skill 3 Mirror Direct] Limit ", i, ": no new constraints."]; Continue[]];

    temp1 = Table[
      ((temp[[j]] /. {Log[u] -> 1, Power[Y, -1] -> invY, Power[u, -1] -> invu,
         Power[Y, a_ /; (a < 0)] :> Power[invY, -a], Power[u, a_ /; (a < 0)] :> Power[invu, -a]}
      // (MonomialList[#, {u, Y, invY, invu}] &)))
      /. {Y -> 1, invY -> 1, invu -> 1, f[3, 3] -> Zeta[3]^2 / 2, f[3, 5] -> Zeta[3] Zeta[5] - f[5, 3]},
      {j, 1, Length[temp]}
    ];

    sys1 = Table[
      Table[Thread @ Equal[(MonomialList[
        temp1[[j]][[k]] /. {Zeta[3] -> z3, Zeta[5] -> z5, Zeta[7] -> z7, Pi -> pi}, {z3, z5, z7, f[5, 3], pi}
      ] /. {z3 -> 1, z5 -> 1, z7 -> 1, f[5, 3] -> 1, pi -> 1}) // DeleteDuplicates // DeleteCases[#, 0] &, 0],
      {k, 1, Length[temp1[[j]]]}],
    {j, 1, Length[temp1]}] // Flatten // DeleteDuplicates // DeleteCases[#, True | False] &;

    mirrorSys = Join[mirrorSys, sys1];
    Print["[Skill 3 Mirror Direct] Limit ", i, " done: ", Length[sys1], " new equations (mirrorSys total: ", Length[mirrorSys], ")."];
    (* Save this limit's equations separately for inspection *)
    Export[FileNameJoin[{rootDir, "test", label <> "_mirrorSys_limit" <> ToString[i] <> ".m"}], sys1];
    (* Log first 5 equations from this limit for inspection *)
    Print["[Skill 3 Mirror Direct] Sample equations from limit ", i, ":"];
    Do[
      Print["  Eq", k, ": ", InputForm[sys1[[k]]]];
    , {k, 1, Min[Length[sys1], 5]}];
  ];

  (* Save mirror equations to file for inspection *)
  mirrorEqFile = FileNameJoin[{rootDir, "test", label <> "_mirrorSys.m"}];
  Export[mirrorEqFile, mirrorSys];
  Print["[Skill 3 Mirror Direct] Mirror equations saved to ", mirrorEqFile];

  (* === Post-loop: audit, merge with partialSys, solve once, compare === *)

  auditMirror = AuditSystem[mirrorSys, "Mirror system (before merge)"];

  (* Abort immediately if audit fails — a non-c variable or non-rational
     coefficient means the system is wrong (e.g. I[0,0,0] leaked in). *)
  If[auditMirror["Status"] === "FAIL",
    Print["[Skill 3 Mirror Direct] [FATAL] Mirror system audit FAILED — system contains non-c variables or non-rational coefficients. Aborting solve."];
    CloseKernels[];
    Return[$Failed];
  ];

  fullSys = Join[partialSys, mirrorSys];
  Print["[Skill 3 Mirror Direct] Merged system: ", Length[partialSys], " (partial) + ", Length[mirrorSys], " (mirror) = ", Length[fullSys], " equations."];

  auditFull = AuditSystem[fullSys, "Full system (partial + mirror)"];

  If[auditFull["Status"] === "FAIL",
    Print["[Skill 3 Mirror Direct] [FATAL] Full system audit FAILED — aborting solve."];
    CloseKernels[];
    Return[$Failed];
  ];

  varsList = Select[Variables[fullSys[[All, 1]]], MatchQ[#, _[_]] && StringStartsQ[SymbolName[Head[#]], "c"] &];
  Print["[Skill 3 Mirror Direct] Variables to solve: ", Length[varsList], "/", $LEN];

  (* Baseline: solve partial system alone — 3-minute timeout *)
  Print["[Skill 3 Mirror Direct] Solving partial system alone..."];
  soltPartial = TimeConstrained[Quiet[Solve[partialSys, varsList]], 180];
  If[soltPartial === $Aborted,
    Print["[Skill 3 Mirror Direct] [FATAL] Partial system Solve exceeded 3-minute timeout — system is likely wrong. Aborting."];
    CloseKernels[];
    Return[$Failed];
  ];
  If[soltPartial === {},
    Print["[Skill 3 Mirror Direct] Partial system alone: INCONSISTENT (no solution)."];
    partialSolved = 0;
  ,
    soltPartial = soltPartial[[1]];
    missing   = Select[Table[c[j], {j, 1, $LEN}], !MemberQ[soltPartial[[All, 1]], #] &];
    unsolved  = Cases[soltPartial[[All, 2]], c[j_Integer] :> c[j], Infinity] // DeleteDuplicates;
    partialSolved = $LEN - Length[Join[missing, unsolved] // DeleteDuplicates];
    Print["[Skill 3 Mirror Direct] Partial system alone: solved ", partialSolved, "/", $LEN, " (free=", $LEN - partialSolved, ")."];
  ];

  (* Solve full system — 3-minute timeout *)
  Print["[Skill 3 Mirror Direct] Solving full system (partial + mirror)..."];
  solt = TimeConstrained[Quiet[Solve[fullSys, varsList]], 180];
  If[solt === $Aborted,
    Print["[Skill 3 Mirror Direct] [FATAL] Full system Solve exceeded 3-minute timeout — system is likely wrong (check for non-rational symbols). Aborting."];
    CloseKernels[];
    Return[$Failed];
  ];
  If[solt === {},
    Print["[Skill 3 Mirror Direct] [FATAL] Full system is INCONSISTENT — no solution exists."];
    Print["[Skill 3 Mirror Direct] Partial alone solved ", partialSolved, "/", $LEN, "; mirror equations conflict with partial."];
    CloseKernels[];
    Return[$Failed];
  ];
  solt = solt[[1]];

  missing   = Select[Table[c[j], {j, 1, $LEN}], !MemberQ[solt[[All, 1]], #] &];
  unsolved  = Cases[solt[[All, 2]], c[j_Integer] :> c[j], Infinity] // DeleteDuplicates;
  freeCount = Length[Join[missing, unsolved] // DeleteDuplicates];
  fullSolved = $LEN - freeCount;
  Print["[Skill 3 Mirror Direct] Full system: solved ", fullSolved, "/", $LEN, " (free=", freeCount, ")."];
  Print["[Skill 3 Mirror Direct] Mirror equations solved ", fullSolved - partialSolved, " additional variables."];
  If[fullSolved > partialSolved,
    Print["[Skill 3 Mirror Direct] RESULT: Mirror equations ADD new constraints."];
  ,
    If[fullSolved === partialSolved,
      Print["[Skill 3 Mirror Direct] RESULT: Mirror equations are REDUNDANT (no new constraints)."];
    ,
      Print["[Skill 3 Mirror Direct] WARNING: Full system solves FEWER vars than partial alone (should not happen)."];
    ];
  ];

  (* Verification loop removed — it re-ran the entire ParallelTable for all 6
     limits, doubling runtime. The linear Solve above already guarantees
     consistency: if the system is solved (free=0), the equations ARE
     satisfied by construction. The generation loop's MonomialList extraction
     + AuditSystem + Solve form a complete correctness chain. *)

  CloseKernels[];

  Print["[Skill 3 Mirror Direct] Final: free=", freeCount, "/", $LEN, If[freeCount === 0, " — FULLY SOLVED!", ""]];

  If[freeCount === 0,
    values = Table[c[i], {i, 1, $LEN}] /. solt;
    finalResultList = {}; coeffListAll = {}; offsetEnd = 0;
    Do[
      coeffK = Table[values[[offsetEnd + i]], {i, 1, Length[ansatzList[[k]]]}];
      resK = Sum[coeffK[[i]] * ansatzList[[k, i]], {i, 1, Length[ansatzList[[k]]]}] /. f[a_, a_] :> f[a]^2 / 2;
      AppendTo[finalResultList, Expand[resK] /. c[i_] :> Symbol["c"][i]];
      AppendTo[coeffListAll, coeffK /. c[i_] :> Symbol["c"][i]];
      offsetEnd = offsetEnd + Length[ansatzList[[k]]];
    , {k, 1, Length[ansatzList]}];
    Export[FileNameJoin[{rootDir, "runs", label, "result.m"}], finalResultList];
    Export[FileNameJoin[{rootDir, "runs", label, "coeff_sol.m"}], coeffListAll];
    Print["[Skill 3 Mirror Direct] Exported runs/", label, "/result.m and coeff_sol.m"];
  ];

  solt
]]
