(* =================================================================== *)
(*  Skill 3: Coefficient Solving Agent                                 *)
(*                                                                     *)
(*  Reads boundary target data and series expansion data to construct  *)
(*  and solve a linear system for the unknown coefficients c[i].       *)
(*                                                                     *)
(*  Arguments:                                                         *)
(*    rootDir      — project root directory                            *)
(*    label        — run label (e.g. "threeloophard1")                 *)
(*    ansatzList   — list of ansatz expressions for each LS            *)
(*    labelsList   — list of labels used for series files per LS       *)
(*    basisSVList  — list of SVHPL basis elements per LS               *)
(*    basisMPLList — list of MPL basis elements per LS                 *)
(*    targetData   — list of boundary data (one SeriesData per perm)   *)
(*    order        — series expansion order for Y                      *)
(* =================================================================== *)

ClearAll[RunCoefficientSolving];

RunCoefficientSolving[rootDir_, label_, config_,
                      ansatzList_List, labelsList_List,
                      basisSVList_List, basisMPLList_List,
                      targetData_, order_:3] := Module[
  {$LEN, $Order, c,
   setup, temp, temp1, sys, solt,
   i, j, k, suffix, filePrefix, ansatzK, svrepK, mplRules, offset, varsList},

  (* ---- global setups ---- *)
  $LEN         = Total[Length /@ ansatzList];
  $Order       = order;
  sys          = {};
  solt         = {};

  Print["[Skill 3] Total Ansatz Elements=$LEN=", $LEN, " $Order=", $Order];

  (* ---- prepare output directory ---- *)
  If[!DirectoryQ[FileNameJoin[{rootDir, "solve_agent"}]],
    CreateDirectory[FileNameJoin[{rootDir, "solve_agent"}]]
  ];

  (* ---- incremental solve across 6 limits ---- *)
  For[i = 1, i <= 6, i++,
    suffix = Switch[i, 1, "e0uv", 2, "e0uvp", 3, "einfuv", 4, "einfuvp", 5, "e1uv", 6, "e1uvp"];
    
    (* setup: substitute partial solution from previous limits, summing over LS *)
    Quiet[
      setup = 0;
      offset = 0;
      Do[
        ansatzK = ansatzList[[k]];
        filePrefix = FileNameJoin[{rootDir, "series_agent", labelsList[[k]]}];
        
        mplRules = If[basisMPLList[[k]] =!= {},
          Thread @ Rule[basisMPLList[[k]], Normal /@ Import[filePrefix <> "_svlistmpl" <> suffix <> ".m"]],
          {}
        ];
        svrepK = Join[
          Thread @ Rule[basisSVList[[k]], Normal /@ Import[filePrefix <> "_svlist" <> suffix <> ".m"]],
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
      Print["Limit ", i, " (", suffix, "): temp is empty. Verified that no new conditions are given under the current solution."];
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
    Module[{sys1},
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
      Print["  system size after limit ", i, ": ", Length[sys], " vars: ", Length[varsList]];
      
      solt = Quiet[Solve[sys, varsList]];
      If[solt === {},
        Print["[FATAL ERROR] Solve returned an empty set on Limit ", i, ". System is inconsistent — aborting."];
        Break[];
      ];
      solt = solt[[1]];
    ];
  ];
  
  If[solt === {},
    Return[$Failed];
  ];

  (* ---- verify: substitute back and check all limits ---- *)
  For[i = 1, i <= 6, i++,
    suffix = Switch[i, 1, "e0uv", 2, "e0uvp", 3, "einfuv", 4, "einfuvp", 5, "e1uv", 6, "e1uvp"];
    
    Quiet[
      setup = 0;
      offset = 0;
      Do[
        ansatzK = ansatzList[[k]];
        filePrefix = FileNameJoin[{rootDir, "series_agent", labelsList[[k]]}];
        
        mplRules = If[basisMPLList[[k]] =!= {},
          Thread @ Rule[basisMPLList[[k]], Normal /@ Import[filePrefix <> "_svlistmpl" <> suffix <> ".m"]],
          {}
        ];
        svrepK = Join[
          Thread @ Rule[basisSVList[[k]], Normal /@ Import[filePrefix <> "_svlist" <> suffix <> ".m"]],
          mplRules
        ];
        
        ansatzKRep = ansatzK /. svrepK;
        ansatzKSeries = (Expand /@ ansatzKRep) /. Y^a_ /; a > $Order :> 0;
        
        setup = setup + ((c /@ Range[offset + 1, offset + Length[ansatzK]]) . ansatzKSeries) /. solt;
        offset = offset + Length[ansatzK];
      , {k, 1, Length[ansatzList]}];
    ];

    temp = Normal[setup - targetData[[i]]] /. {
      f[3, 3] -> Zeta[3]^2 / 2, f[3, 5] -> Zeta[3] Zeta[5] - f[5, 3], f[a_] :> Zeta[a]
    } // Simplify;
    
    If[temp =!= 0,
      Print["Limit ", i, " mismatch: ", InputForm[temp]];
    ];
  ];

  (* save to disk *)
  Export[FileNameJoin[{rootDir, "solve_agent", label <> "_sol.m"}], solt /. c[i_] :> Symbol["c"][i]];
  Print["Solution written to ", FileNameJoin[{rootDir, "solve_agent", label <> "_sol.m"}]];
  Export[FileNameJoin[{rootDir, "solve_agent", label <> "_partialsys.m"}], sys /. c[i_] :> Symbol["c"][i]];
  Print["Equation system written to ", FileNameJoin[{rootDir, "solve_agent", label <> "_partialsys.m"}]];

  Module[{isSolved = True, totalCoeffs = $LEN, lhsVars, unsolvedVars, missingCoeffs},
    If[solt === {} || Head[solt] =!= List,
      isSolved = False;
      Print["[FATAL ERROR] Solve returned empty or failed."];
    ,
      lhsVars = solt[[All, 1]];
      missingCoeffs = Select[Table[c[i], {i, 1, totalCoeffs}], !MemberQ[lhsVars, #] &];
      unsolvedVars = Cases[solt[[All, 2]], c[i_Integer] :> c[i], Infinity] // DeleteDuplicates;
      
      If[Length[missingCoeffs] > 0 || Length[unsolvedVars] > 0,
        isSolved = False;
        Print["[WARNING] Coefficients are not totally solved! ", Length[unsolvedVars], " free parameters remaining: ", unsolvedVars];
        Export[FileNameJoin[{rootDir, "solve_agent", label <> "_freevars.m"}], {missingCoeffs, unsolvedVars}];
      ,
        Export[FileNameJoin[{rootDir, "solve_agent", label <> "_freevars.m"}], {{}, {}}];
      ];

      If[isSolved,
        (* Export results *)
        Module[{values, offset, finalResultList, coeffListAll, ansatzK, resK, coeffK},
          values = Table[c[i], {i, 1, totalCoeffs}] /. solt;
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
          
          (* Replace Module-local c with global c *)
          finalResultList = finalResultList /. c[i_] :> Symbol["c"][i];
          coeffListAll = coeffListAll /. c[i_] :> Symbol["c"][i];
          
          Export[FileNameJoin[{rootDir, "runs", label, "result.m"}], finalResultList];
          Export[FileNameJoin[{rootDir, "runs", label, "coeff_sol.m"}], coeffListAll];
          Print["Final result.m and coeff_sol.m saved to runs/", label, "/"];
        ];
      ,
        Print["[WARNING] Skipping export of result.m and coeff_sol.m due to unsolved parameters."];
        Quiet[
          If[FileExistsQ[FileNameJoin[{rootDir, "runs", label, "result.m"}]], DeleteFile[FileNameJoin[{rootDir, "runs", label, "result.m"}]]];
          If[FileExistsQ[FileNameJoin[{rootDir, "runs", label, "coeff_sol.m"}]], DeleteFile[FileNameJoin[{rootDir, "runs", label, "coeff_sol.m"}]]];
        ];
      ];
    ];
  ];

];
