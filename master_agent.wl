(* =================================================================== *)
(*  Skill 0: Master Orchestrator                                      *)
(*  Location: ./ (project root)                                        *)
(*                                                                     *)
(*  Coordinates Skill 1 (series expansion), Skill 2 (boundary          *)
(*  conditions), and Skill 3 (coefficient solving).                    *)
(*                                                                     *)
(*  Each integrand has exactly ONE leading singularity.                *)
(*                                                                     *)
(*  Usage:                                                             *)
(*    First set globals: ansatzExpr, basisSV, basisMPL, targetData     *)
(*    Then call:                                                        *)
(*    RunSVBPipeline[rootDir, label,                                    *)
(*                   poleType, lsAddPole]                               *)
(*                                                                     *)
(*    Globals required:                                                 *)
(*      $Integrand  — the integrand expression                          *)
(*      $Perms      — solving order:                                   *)
(*         {{1,2,3,4},{2,1,3,4},{1,3,2,4},{2,3,1,4},{3,1,2,4},{3,2,1,4}} *)
(*      ansatzExpr  — the testansatz expression                         *)
(*      basisSV     — allsvlist (SVHPL basis)                           *)
(*      basisMPL    — allsvlistmpl (MPL basis)                          *)
(*      targetData  — 6 boundary expressions in solving order (see §3.1)*)
(*                                                                     *)
(*  Options:                                                            *)
(*    "Audit" -> True            — run review gate after each stage     *)
(*    "AuditReportDir" -> None   — directory for audit reports          *)
(*    "StopOnAuditFailure" -> False — halt pipeline on audit FAIL       *)
(*                                                                     *)
(*    poleType  — "simple" (k=1) or "double" (k=2)                    *)
(*    lsAddPole — additional-pole expression (e.g. 1/(1-u))            *)
(*    label     — file-name prefix shared by all skills                *)
(*                                                                     *)
(*    poleOrder is derived from poleType: "simple" → 1, "double" → 2   *)
(*    The add formula is: add = base_transformed / F^(weightN − k)     *)
(*    where k = poleOrder (powers of F absorbed by the z-pole).         *)
(* =================================================================== *)

ClearAll[RunSVBPipeline];
Options[RunSVBPipeline] = {
  "Audit" -> True,
  "AuditReportDir" -> None,
  "StopOnAuditFailure" -> False
};

RunSVBPipeline[rootDir_, label_,
               poleType_, lsAddPole_, order_:3, yOrder_:4,
               opts : OptionsPattern[]] := Module[
  {weightN, pipelineStartedAt, stageStartedAt, audit, reportDir,
   report, stageTimings = Association[], poleOrder,
   basisElements, svIndices, mplIndices, basisSVReduced, basisMPLReduced},

  (* ---- options ---- *)
  audit     = OptionValue["Audit"];
  reportDir = OptionValue["AuditReportDir"];
  If[reportDir === None && audit,
    reportDir = FileNameJoin[{rootDir, "audit_agent", "reports"}]
  ];

  (* ---- load conformal weight calculator ---- *)
  Get[FileNameJoin[{rootDir, "ConformalWeight.m"}]];

  (* ---- optionally load review agent ---- *)
  If[audit,
    Get[FileNameJoin[{rootDir, "review_agent.wl"}]];
    LoadReviewAgent[rootDir];
    If[reportDir =!= None && !DirectoryQ[reportDir], CreateDirectory[reportDir]];
  ];

  (* ---- determine normalization ---- *)
  weightN = -ConformalWeight[$Integrand, 1];
  poleOrder = poleType /. {"simple" -> 1, "double" -> 2};
  pipelineStartedAt = DateObject[];

  Print["=== Processing integrand '", label, "' ==="];
  Print["  Conformal weight n = ", weightN, ",  pole order k = ", poleOrder];
  Print["  Primary pole: ", poleType, ",  additional pole: ", lsAddPole];

  (* ---- pre-filter basis to ansatz-only elements (4× speedup) ---- *)
  basisElements = DeleteDuplicates @ Cases[ansatzExpr, _I | _f, {1, Infinity}];
  svIndices = Function[e, If[# === {}, 0, #[[1,1]]] & @ Position[basisSV, e, {1}]] /@ basisElements;
  mplIndices = Function[e, If[# === {}, 0, #[[1,1]]] & @ Position[basisMPL, e, {1}]] /@ basisElements;
  svIndices = DeleteDuplicates[Select[svIndices, Positive]];
  mplIndices = DeleteDuplicates[Select[mplIndices, Positive]];
  Print["  SVHPL in ansatz: ", Length[svIndices], " (of ", Length[basisSV], ")"];
  Print["  MPL in ansatz: ", Length[mplIndices], " (of ", Length[basisMPL], ")"];
  basisSVReduced  = basisSV[[svIndices]];
  basisMPLReduced = basisMPL[[mplIndices]];

  (* Skill 2: Boundary Conditions (uses global $Integrand, $Perms) *)
  stageStartedAt = DateObject[];
  RunBoundaryConditions[rootDir, label, order];
  AssociateTo[stageTimings, "boundary" -> DateObject[]];
  If[audit,
    report = ReviewGate[rootDir, label, "boundary"];
    If[OptionValue["StopOnAuditFailure"] && report["Status"] === "FAIL",
      Print["[ABORT] Boundary stage FAIL."];
      Return[$Failed]
    ];
  ];

  (* Skill 1: Series Expansion *)
  LaunchKernels[6];
  stageStartedAt = DateObject[];
  RunSeriesExpansion[rootDir, label, lsAddPole, poleType, weightN, yOrder, svIndices, mplIndices, poleOrder];
  AssociateTo[stageTimings, "series" -> DateObject[]];
  If[audit,
    report = ReviewGate[rootDir, label, "series"];
    If[OptionValue["StopOnAuditFailure"] && report["Status"] === "FAIL",
      Print["[ABORT] Series stage FAIL."];
      Return[$Failed]
    ];
  ];
  CloseKernels[];

  (* Skill 3: Coefficient Solving *)
  stageStartedAt = DateObject[];
  RunCoefficientSolving[rootDir, label, ansatzExpr, basisSVReduced, basisMPLReduced, targetData, order];
  AssociateTo[stageTimings, "solve" -> DateObject[]];
  If[audit,
    report = ReviewGate[rootDir, label, "solve"];
    If[OptionValue["StopOnAuditFailure"] && report["Status"] === "FAIL",
      Print["[ABORT] Solve stage FAIL."];
      Return[$Failed]
    ];
  ];

  Print["Pipeline complete for '", label, "'."];
  Print["Timings: ", stageTimings // Normal];
];
