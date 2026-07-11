(* ::Package:: *)
(*  Skill 3 Mirror: Mirrored Coefficient Solving Agent                 *)
(*  Loads partial solve from standard pipeline, adds mirror constraints *)
(*  across $MirrorLimits. Incremental solve + verification.             *)

ClearAll[RunCoefficientSolvingMirror];

RunCoefficientSolvingMirror[rootDir_, label_, config_,
                            ansatzList_List, labelsList_List,
                            basisSVList_List, basisMPLList_List,
                            targetData_, order_:3] :=
Block[{c = Symbol["c"]},
Module[{sys, i, suffix, setup, temp, temp1, sys1, solt,
       svrepK, ansatzKRep, ansatzKSeries, offset, j, k, varsList,
       freeCount, values, finalResultList, coeffListAll,
       coeffK, resK, offsetEnd, $LEN, $Order, mirrorLimits,
       filePrefix, mplRules, missing, unsolved},

  $LEN   = Total[Length /@ ansatzList];
  $Order = order;

  Print["[Skill 3 Mirror] Total Ansatz Elements=$LEN=", $LEN, " $Order=", $Order];

  sys = Import[FileNameJoin[{rootDir, "solve_agent", label <> "_partialsys.m"}]] /. Symbol["c"] -> c;
  Print["[Skill 3 Mirror] Loaded ", Length[sys], " equations from _partialsys.m."];

  mirrorLimits = $MirrorLimits;
  Print["[Skill 3 Mirror] Solving mirror limits: ", mirrorLimits];

  solt = {};

  For[i = 1, i <= 6, i++,
    If[!MemberQ[mirrorLimits, i], Continue[]];
    suffix = Switch[i, 1, "e0uv", 2, "e0uvp", 3, "einfuv", 4, "einfuvp", 5, "e1uv", 6, "e1uvp"];

    setup = 0; offset = 0;
    Do[
      filePrefix = FileNameJoin[{rootDir, "series_agent", labelsList[[k]]}];

      mplRules = If[basisMPLList[[k]] =!= {},
        Thread @ Rule[basisMPLList[[k]], Normal /@ Import[filePrefix <> "_svlistmpl_mirror" <> suffix <> ".m"]],
        {}
      ];
      svrepK = Join[
        Thread @ Rule[basisSVList[[k]], Normal /@ Import[filePrefix <> "_svlist_mirror" <> suffix <> ".m"]],
        mplRules
      ];

      ansatzKRep = ansatzList[[k]] /. svrepK;
      ansatzKSeries = (Expand /@ ansatzKRep) /. Y^a_ /; a > $Order :> 0;
      setup = setup + (c /@ Range[offset + 1, offset + Length[ansatzList[[k]]]]) . ansatzKSeries;
      offset = offset + Length[ansatzList[[k]]];
    , {k, 1, Length[ansatzList]}];
    setup = setup /. solt;

    temp = MonomialList[
      Normal[setup - targetData[[i]]] /. {
        f[3, 3] -> Zeta[3]^2 / 2,
        f[3, 5] -> Zeta[3] Zeta[5] - f[5, 3],
        f[a_] :> Zeta[a]},
      {Log[u]}
    ] // DeleteCases[#, 0] &;

    If[temp === {}, Print["[Skill 3 Mirror] Limit ", i, ": no new constraints."]; Continue[]];

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

    sys = Join[sys, sys1];
    varsList = Select[Variables[sys[[All, 1]]], MatchQ[#, _[_]] && StringStartsQ[SymbolName[Head[#]], "c"] &];

    solt = Quiet[Solve[sys, varsList]];
    If[solt === {}, Print["[Skill 3 Mirror] [FATAL] Solve empty on limit ", i, ". ", Length[sys1], " new, ", Length[sys], " total, ", Length[varsList], " vars."]; Break[]];
    solt = solt[[1]];

    missing   = Select[Table[c[j], {j, 1, $LEN}], !MemberQ[solt[[All, 1]], #] &];
    unsolved  = Cases[solt[[All, 2]], c[j_Integer] :> c[j], Infinity] // DeleteDuplicates;
    freeCount = Length[Join[missing, unsolved] // DeleteDuplicates];
    Print["[Skill 3 Mirror] Limit ", i, " done: ", Length[sys], " eqs, free=", freeCount, "/", $LEN];
  ];

  If[solt === {}, Print["[Skill 3 Mirror] Empty — aborting."]; Return[$Failed]];

  For[i = 1, i <= 6, i++,
    If[!MemberQ[mirrorLimits, i], Continue[]];
    suffix = Switch[i, 1, "e0uv", 2, "e0uvp", 3, "einfuv", 4, "einfuvp", 5, "e1uv", 6, "e1uvp"];

    setup = 0; offset = 0;
    Do[
      filePrefix = FileNameJoin[{rootDir, "series_agent", labelsList[[k]]}];

      mplRules = If[basisMPLList[[k]] =!= {},
        Thread @ Rule[basisMPLList[[k]], Normal /@ Import[filePrefix <> "_svlistmpl_mirror" <> suffix <> ".m"]],
        {}
      ];
      svrepK = Join[
        Thread @ Rule[basisSVList[[k]], Normal /@ Import[filePrefix <> "_svlist_mirror" <> suffix <> ".m"]],
        mplRules
      ];

      ansatzKRep = ansatzList[[k]] /. svrepK;
      ansatzKSeries = (Expand /@ ansatzKRep) /. Y^a_ /; a > $Order :> 0;
      setup = setup + (c /@ Range[offset + 1, offset + Length[ansatzList[[k]]]]) . ansatzKSeries;
      offset = offset + Length[ansatzList[[k]]];
    , {k, 1, Length[ansatzList]}];
    setup = setup /. solt;

    temp = Normal[setup - targetData[[i]]] /. {
      f[3, 3] -> Zeta[3]^2 / 2, f[3, 5] -> Zeta[3] Zeta[5] - f[5, 3], f[a_] :> Zeta[a]
    } // Simplify;
    If[temp =!= 0,
      Print["[Skill 3 Mirror] Limit ", i, " mismatch: ", InputForm[temp]];
    ];
  ];

  missing   = Select[Table[c[j], {j, 1, $LEN}], !MemberQ[solt[[All, 1]], #] &];
  unsolved  = Cases[solt[[All, 2]], c[j_Integer] :> c[j], Infinity] // DeleteDuplicates;
  freeCount = Length[Join[missing, unsolved] // DeleteDuplicates];
  Print["[Skill 3 Mirror] Final: free=", freeCount, "/", $LEN, If[freeCount === 0, " — FULLY SOLVED!", ""]];

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
    Print["[Skill 3 Mirror] Exported runs/", label, "/result.m and coeff_sol.m"];
  ];

  solt
]]
