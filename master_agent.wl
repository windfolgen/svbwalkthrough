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
(*      basisMPL    — allsvlistmpl (MPL basis, auto-detected)           *)
(*      targetData  — 6 boundary expressions in solving order (see §3.1)*)
(*                                                                     *)
(*  File conventions:                                                    *)
(*    Ansatz files live under runs/<label>/<label>_ans.m                *)
(*    Basis files (.m + .txt) live at project root                     *)
(*    Boundary output: asym/boundary_agent/                            *)
(*    Series output: series_agent/                                      *)
(*    Solve output: solve_agent/                                        *)
(*                                                                     *)
(*  Options:                                                            *)
(*    "Audit" -> True            — run review gate after each stage     *)
(*    "AuditReportDir" -> None   — directory for audit reports          *)
(*    "StopOnAuditFailure" -> False — halt pipeline on audit FAIL       *)
(*                                                                     *)
(*    order      — expansion order for boundary/solve (3 for 3-loop, 4 for 4-loop) *)
(*    yOrder     — Y-expansion order for series (4 for 3-loop, 5 for 4-loop)      *)
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
               loopPoints_:{5,6,7},
               opts : OptionsPattern[]] := Module[
  {weightN, pipelineStartedAt, stageStartedAt, audit, reportDir,
   report, stageTimings = Association[], poleOrder,
   basisElements, svIndices, mplIndices, basisSVReduced, basisMPLReduced,
   mplBasisFile, mplFiles, bestCount, bestFile},

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
  svIndices = DeleteDuplicates[Select[svIndices, Positive]];
  Print["  SVHPL in ansatz: ", Length[svIndices], " (of ", Length[basisSV], ")"];
  basisSVReduced  = basisSV[[svIndices]];

  (* ---- auto-detect MPL basis: scan allsvlistmpl_*.m, pick best coverage ---- *)
  mplBasisFile = None;
  mplFiles = FileNames[FileNameJoin[{rootDir, "allsvlistmpl_*.m"}]];
  (* filter out expansion files (end with e0.m, e1.m, einf.m) *)
  mplFiles = Select[mplFiles, !StringMatchQ[#, ___ ~~ ("e0.m" | "e1.m" | "einf.m")] &];
  If[mplFiles =!= {},
    (* score each MPL basis: count ansatz elements found *)
    bestCount = 0;
    Do[
      basisMPL = Import[f];
      mplIndices = Function[e, If[# === {}, 0, #[[1,1]]] & @ Position[basisMPL, e, {1}]] /@ basisElements;
      mplIndices = DeleteDuplicates[Select[mplIndices, Positive]];
      If[Length[mplIndices] > bestCount,
        bestCount = Length[mplIndices];
        bestFile = f;
      ],
      {f, mplFiles}
    ];
    If[bestCount > 0,
      mplBasisFile = bestFile;
      basisMPL = Import[mplBasisFile];
      mplIndices = Function[e, If[# === {}, 0, #[[1,1]]] & @ Position[basisMPL, e, {1}]] /@ basisElements;
      mplIndices = DeleteDuplicates[Select[mplIndices, Positive]];
      basisMPLReduced = basisMPL[[mplIndices]];
      Print["  MPL in ansatz: ", Length[mplIndices], " (of ", Length[basisMPL], "), basis: ", FileBaseName[mplBasisFile]];
    ,
      Print["  MPL in ansatz: 0 (no matching basis found)"];
      mplIndices = {};
      basisMPLReduced = {};
    ];
  ,
    Print["  MPL: no basis files found in root"];
    mplIndices = {};
    basisMPLReduced = {};
  ];

  (* ---- pre-flight check: verify all required input files ---- *)
  If[audit,
    Print[""];
    Print["=== PRE-FLIGHT CHECKS ==="];
    report = ReviewGate[rootDir, label, "preflight"];
    If[OptionValue["StopOnAuditFailure"] && report["Status"] === "FAIL",
      Print["[ABORT] Preflight FAIL."];
      Return[$Failed]
    ];
    Print[report["Status"], ": PASS ", report["Summary","PASS"], ", WARN ", report["Summary","WARN"], ", FAIL ", report["Summary","FAIL"]];
  ];

  (* ---- pre-boundary check: LiteRed2 bases, asym engine, Gmaterrep ---- *)
  If[audit,
    Print[""];
    Print["=== PRE-BOUNDARY CHECKS ==="];
    report = ReviewGate[rootDir, label, "preboundary"];
    If[OptionValue["StopOnAuditFailure"] && report["Status"] === "FAIL",
      Print["[ABORT] Pre-Boundary FAIL."];
      Return[$Failed]
    ];
    Print[report["Status"], ": PASS ", report["Summary","PASS"], ", WARN ", report["Summary","WARN"], ", FAIL ", report["Summary","FAIL"]];
  ];

  (* Skill 2: Boundary Conditions (uses global $Integrand, $Perms) *)
  stageStartedAt = DateObject[];
  RunBoundaryConditions[rootDir, label, order, loopPoints];
  AssociateTo[stageTimings, "boundary" -> DateObject[]];
  If[audit,
    report = ReviewGate[rootDir, label, "boundary"];
    If[OptionValue["StopOnAuditFailure"] && report["Status"] === "FAIL",
      Print["[ABORT] Boundary stage FAIL."];
      Return[$Failed]
    ];
  ];

  (* ---- pre-series check: SVHPL .txt, MPL .m file format ---- *)
  If[audit,
    Print[""];
    Print["=== PRE-SERIES CHECKS ==="];
    report = ReviewGate[rootDir, label, "preseries"];
    If[OptionValue["StopOnAuditFailure"] && report["Status"] === "FAIL",
      Print["[ABORT] Pre-Series FAIL."];
      Return[$Failed]
    ];
    Print[report["Status"], ": PASS ", report["Summary","PASS"], ", WARN ", report["Summary","WARN"], ", FAIL ", report["Summary","FAIL"]];
  ];

  (* Skill 1: Series Expansion *)
  LaunchKernels[6];
  stageStartedAt = DateObject[];
  RunSeriesExpansion[rootDir, label, lsAddPole, poleType, weightN, yOrder, svIndices, mplIndices, poleOrder, mplBasisFile];
  AssociateTo[stageTimings, "series" -> DateObject[]];
  If[audit,
    report = ReviewGate[rootDir, label, "series"];
    If[OptionValue["StopOnAuditFailure"] && report["Status"] === "FAIL",
      Print["[ABORT] Series stage FAIL."];
      Return[$Failed]
    ];
  ];
  CloseKernels[];

  (* ---- pre-solve check: boundary files + series expansion files ---- *)
  If[audit,
    Print[""];
    Print["=== PRE-SOLVE CHECKS ==="];
    report = ReviewGate[rootDir, label, "presolve"];
    If[OptionValue["StopOnAuditFailure"] && report["Status"] === "FAIL",
      Print["[ABORT] Pre-Solve FAIL."];
      Return[$Failed]
    ];
    Print[report["Status"], ": PASS ", report["Summary","PASS"], ", WARN ", report["Summary","WARN"], ", FAIL ", report["Summary","FAIL"]];
  ];

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
