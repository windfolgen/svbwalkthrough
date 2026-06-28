(* =================================================================== *)
(*  Skill 3 Mirror: Mirrored Coefficient Solving Agent                 *)
(*                                                                     *)
(*  Reads boundary target data and mirrored series expansion data to   *)
(*  construct mirrored constraints, then combines and solves systems.  *)
(* =================================================================== *)

ClearAll[RunCoefficientSolvingMirror, CombineAndSolveSystems];

RunCoefficientSolvingMirror[rootDir_, label_, config_,
                            ansatzList_List, labelsList_List,
                            basisSVList_List, basisMPLList_List,
                            targetData_, order_:3] := Module[
  {$LEN, $Order, c,
   setup, temp, temp1, sys, solt,
   i, j, k, suffix, filePrefix, ansatzK, svrepK, mplRules, offset, varsList,
   partialSysFile, partialSolFile},

  (* ---- global setups ---- *)
  $LEN         = Total[Length /@ ansatzList];
  $Order       = order;
  sys          = {};
  solt         = {};

  Print["[Skill 3 Mirror] Total Ansatz Elements=$LEN=", $LEN, " $Order=", $Order];

  partialSysFile = FileNameJoin[{rootDir, "solve_agent", label <> "_partialsys.m"}];
  partialSolFile = FileNameJoin[{rootDir, "solve_agent", label <> "_partial_sol.m"}];

  If[FileExistsQ[partialSysFile] && FileExistsQ[partialSolFile],
    Print["[Skill 3 Mirror] Loading original partial system and solution for incremental solving..."];
    sys = Import[partialSysFile] /. Symbol["c"] -> c;
    solt = Import[partialSolFile] /. Symbol["c"] -> c;
  ];

  (* ---- incremental solve across 6 limits ---- *)
  For[i = 1, i <= 6, i++,
    If[i === 3 || i === 4, Continue[]];
    suffix = Switch[i, 1, "e0uv", 2, "e0uvp", 3, "einfuv", 4, "einfuvp", 5, "e1uv", 6, "e1uvp"];
    
    (* setup: substitute partial solution from previous limits, summing over LS *)
    Quiet[
      setup = 0;
      offset = 0;
      Do[
        ansatzK = ansatzList[[k]];
        filePrefix = FileNameJoin[{rootDir, "series_agent", labelsList[[k]]}];
        
        mplRules = If[basisMPLList[[k]] =!= {},
          Thread @ Rule[basisMPLList[[k]], Normal /@ Import[filePrefix <> "_svlistmpl_mirror" <> suffix <> ".m"]],
          {}
        ];
        svrepK = Join[
          Thread @ Rule[basisSVList[[k]], Normal /@ Import[filePrefix <> "_svlist_mirror" <> suffix <> ".m"]],
          mplRules
        ];
        
        ansatzKRep = ansatzK /. svrepK;
        ansatzKSeries = (Expand /@ ansatzKRep) /. Y^a_ /; a > $Order :> 0;
        
        setup = setup + ((c /@ Range[offset + 1, offset + Length[ansatzK]]) . ansatzKSeries) /. solt;
        offset = offset + Length[ansatzK];
      , {k, 1, Length[ansatzList]}];
    ];

    (* temp: exact notebook syntax *)
    temp = MonomialList[
      Normal[setup - targetData[[i]]] /. {
        f[3, 3] -> Zeta[3]^2 / 2,
        f[3, 5] -> Zeta[3] Zeta[5] - f[5, 3],
        f[a_] :> Zeta[a]
      },
      {Log[u]}
    ] // DeleteCases[#, 0] &;

    If[temp === {},
      Continue[];
    ];

    (***** extract coefficients (temp1) *****)
    temp1 = Table[
      (
        (temp[[j]] /. {
          Log[u] -> 1,
          Power[Y, -1] -> invY,
          Power[u, -1] -> invu,
          Power[Y, a_ /; (a < 0)] :> Power[invY, -a],
          Power[u, a_ /; (a < 0)] :> Power[invu, -a]
        } // (MonomialList[#, {u, Y, invY, invu}] &))
      ) /. {
        Y -> 1, invY -> 1, invu -> 1,
        f[3, 3] -> Zeta[3]^2 / 2,
        f[3, 5] -> Zeta[3] Zeta[5] - f[5, 3]
      },
      {j, 1, Length[temp]}
    ];

    (***** build linear system (sys1) *****)
    sys1 = Table[
      Table[
        Thread @ Equal[
          (MonomialList[
            temp1[[j]][[k]] /. {Zeta[3] -> z3, Zeta[5] -> z5, Zeta[7] -> z7, Pi -> pi},
            {z3, z5, z7, f[5, 3], pi}
          ] /. {z3 -> 1, z5 -> 1, z7 -> 1, f[5, 3] -> 1, pi -> 1})
          // DeleteDuplicates // DeleteCases[#, 0] &,
          0
        ],
        {k, 1, Length[temp1[[j]]]}
      ],
      {j, 1, Length[temp1]}
    ] // Flatten // DeleteDuplicates // DeleteCases[#, True | False] &;

    (* merge and solve incrementally *)
    sys = Join[sys, sys1];
    
    varsList = Select[Variables[sys[[All, 1]]], MatchQ[#, _[_]] && StringStartsQ[SymbolName[Head[#]], "c"] &];
    solt = Quiet[Solve[sys, varsList]];
    If[solt === {},
      Print["[Skill 3 Mirror] [FATAL ERROR] Solve returned empty on limit ", i, ". System is inconsistent — aborting mirror."];
      Break[];
    ];
    solt = solt[[1]];
  ];

  (* ---- check solve result: 3 cases ---- *)
  If[solt === {} || Head[solt] =!= List,
    Print["[Skill 3 Mirror] Combined system is empty or invalid — aborting."];
    Return[$Failed];
  ];

  totalCoeffs = $LEN;
  lhsVars = solt[[All, 1]];
  missingCoeffs = Select[Table[c[i], {i, 1, totalCoeffs}], !MemberQ[lhsVars, #] &];
  unsolvedVars = Cases[solt[[All, 2]], c[i_Integer] :> c[i], Infinity] // DeleteDuplicates;

  If[Length[missingCoeffs] > 0 || Length[unsolvedVars] > 0,
    Print["[Skill 3 Mirror] Combined system not fully solved. Writing partial solution."];
    Export[FileNameJoin[{rootDir, "solve_agent", label <> "_partial_sol.m"}], solt /. c[i_] :> Symbol["c"][i]];
    Export[FileNameJoin[{rootDir, "solve_agent", label <> "_new_sys.m"}], sys /. c[i_] :> Symbol["c"][i]];
    Print["Mirrored algebraic constraints (new_sys) written to ", FileNameJoin[{rootDir, "solve_agent", label <> "_new_sys.m"}]];
    Return[];
  ];

  Print["[Skill 3 Mirror] Combined system is fully solved! Writing solution to sol.m"];
  Export[FileNameJoin[{rootDir, "solve_agent", label <> "_sol.m"}], solt /. c[i_] :> Symbol["c"][i]];
  Export[FileNameJoin[{rootDir, "solve_agent", label <> "_new_sys.m"}], sys /. c[i_] :> Symbol["c"][i]];
  Print["Mirrored algebraic constraints (new_sys) written to ", FileNameJoin[{rootDir, "solve_agent", label <> "_new_sys.m"}]];
];

CombineAndSolveSystems[rootDir_, label_, config_, ansatzList_List, order_] := Module[
  {solFile, solt, totalCoeffs, vars, lhsVars, missingCoeffs, unsolvedVars, isSolved, values, offset, finalResultList, coeffListAll, ansatzK, coeffK, resK},

  solFile = FileNameJoin[{rootDir, "solve_agent", label <> "_sol.m"}];

  If[FileExistsQ[solFile],
    Print["[Combine & Solve] Combined system was already solved in RunCoefficientSolvingMirror. Loading solution..."];
    solt = Import[solFile];
    totalCoeffs = Total[Length /@ ansatzList];
    vars = Table[Symbol["c"][i], {i, 1, totalCoeffs}];
    
    lhsVars = solt[[All, 1]];
    missingCoeffs = Select[vars, !MemberQ[lhsVars, #] &];
    unsolvedVars = Cases[solt[[All, 2]], Symbol["c"][i_Integer] :> Symbol["c"][i], Infinity] // DeleteDuplicates;
    unsolvedVars = Join[missingCoeffs, unsolvedVars] // DeleteDuplicates;
    isSolved = (Length[unsolvedVars] == 0);
  ,
    (* Fallback to direct solve if solFile is not found *)
    Print["[Combine & Solve] sol.m not found. Falling back to default combine and solve..."];
    Module[{partialSysFile, newSysFile, partialSys, newSys, totalSys},
      partialSysFile = FileNameJoin[{rootDir, "solve_agent", label <> "_partialsys.m"}];
      newSysFile = FileNameJoin[{rootDir, "solve_agent", label <> "_new_sys.m"}];
      If[!FileExistsQ[partialSysFile] || !FileExistsQ[newSysFile],
        Print["[Combine & Solve] ERROR: Missing partialsys or new_sys files for fallback."];
        Return[];
      ];
      partialSys = Import[partialSysFile];
      newSys = Import[newSysFile];
      totalSys = DeleteDuplicates[Join[partialSys, newSys]];
      totalCoeffs = Total[Length /@ ansatzList];
      vars = Table[Symbol["c"][i], {i, 1, totalCoeffs}];
      solt = Quiet[Solve[totalSys, vars]];
      If[solt === {} || Head[solt] =!= List,
        Print["[Combine & Solve] [FATAL ERROR] Solve returned empty on fallback!"];
        Return[];
      ];
      solt = solt[[1]];
      lhsVars = solt[[All, 1]];
      missingCoeffs = Select[vars, !MemberQ[lhsVars, #] &];
      unsolvedVars = Cases[solt[[All, 2]], Symbol["c"][i_Integer] :> Symbol["c"][i], Infinity] // DeleteDuplicates;
      unsolvedVars = Join[missingCoeffs, unsolvedVars] // DeleteDuplicates;
      isSolved = (Length[unsolvedVars] == 0);
    ];
  ];

  If[isSolved,
    Print["[Combine & Solve] SUCCESS: Coefficients are fully solved!"];
    Export[FileNameJoin[{rootDir, "solve_agent", label <> "_sol.m"}], solt];
    Print["Solution written to ", FileNameJoin[{rootDir, "solve_agent", label <> "_sol.m"}]];
    
    (* Export results *)
    values = vars /. solt;
    finalResultList = {};
    coeffListAll = {};
    offset = 0;
    Do[
      ansatzK = ansatzList[[k]];
      coeffK = Table[values[[offset + i]], {i, 1, Length[ansatzK]}];
      resK = Sum[coeffK[[i]] * ansatzK[[i]], {i, 1, Length[ansatzK]}];
      resK = resK /. f[a_, a_] :> f[a]^2/2;
      
      AppendTo[finalResultList, Expand[resK]];
      AppendTo[coeffListAll, coeffK];
      
      offset = offset + Length[ansatzK];
    , {k, 1, Length[ansatzList]}];

    Export[FileNameJoin[{rootDir, "runs", label, "result.m"}], finalResultList];
    Export[FileNameJoin[{rootDir, "runs", label, "coeff_sol.m"}], coeffListAll];
    Print["Final result.m and coeff_sol.m saved to runs/", label, "/"];
  ,
    Print["[Combine & Solve] [WARNING] Coefficients are still not totally solved! ", Length[unsolvedVars], " free parameters remaining."];
    Export[FileNameJoin[{rootDir, "solve_agent", label <> "_free_vars.m"}], unsolvedVars];
    Print["Remaining free variables written to ", FileNameJoin[{rootDir, "solve_agent", label <> "_free_vars.m"}]];

    Quiet[
      If[FileExistsQ[FileNameJoin[{rootDir, "runs", label, "result.m"}]], DeleteFile[FileNameJoin[{rootDir, "runs", label, "result.m"}]]];
      If[FileExistsQ[FileNameJoin[{rootDir, "runs", label, "coeff_sol.m"}]], DeleteFile[FileNameJoin[{rootDir, "runs", label, "coeff_sol.m"}]]];
      If[FileExistsQ[FileNameJoin[{rootDir, "solve_agent", label <> "_sol.m"}]], DeleteFile[FileNameJoin[{rootDir, "solve_agent", label <> "_sol.m"}]]];
    ];
  ];
];
