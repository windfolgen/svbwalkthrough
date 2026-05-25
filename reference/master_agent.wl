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
(*    poleType  — "simple" or "double"                                 *)
(*    lsAddPole — additional-pole expression (e.g. 1/(1-u))            *)
(*    label     — file-name prefix shared by all skills                *)
(*                                                                     *)
(*    Audit options:                                                    *)
(*      "Audit" -> True | False                                         *)
(*      "AuditReport" -> True | False                                   *)
(*      "StopOnAuditFailure" -> True | False                            *)
(*      "AuditResiduals" -> True | False                                *)
(* =================================================================== *)

ClearAll[
  RunSVBPipeline, SVBMasterLoadAudit, SVBMasterAuditSummaryString,
  SVBMasterHandleAudit
];

Options[RunSVBPipeline] = {
  "Audit" -> True,
  "AuditReport" -> True,
  "StopOnAuditFailure" -> True,
  "AuditResiduals" -> True
};

SVBMasterLoadAudit[rootDir_] := Module[{auditFile},
  auditFile = FileNameJoin[{rootDir, "audit_agent", "audit_agent.wl"}];
  If[! FileExistsQ[auditFile],
    Print["Audit requested, but audit agent was not found: ", auditFile];
    Return[$Failed];
  ];
  Get[auditFile];
  auditFile
];

SVBMasterAuditSummaryString[report_Association] := Module[{summary},
  summary = report["Summary"];
  "PASS/WARN/FAIL = " <> ToString[Lookup[summary, "PASS", 0]] <> "/" <>
    ToString[Lookup[summary, "WARN", 0]] <> "/" <>
    ToString[Lookup[summary, "FAIL", 0]]
];

SVBMasterHandleAudit[rootDir_, label_, stage_, report_Association, writeReport_, stopOnFailure_] := Module[
  {paths},
  Print["Audit ", stage, ": ", report["Status"], " (", SVBMasterAuditSummaryString[report], ")"];
  If[TrueQ[writeReport],
    paths = SVBAuditWriteReport[rootDir, label <> "_" <> stage, report];
    Print["  Audit report: ", paths["MarkdownFile"]];
  ];
  If[report["Status"] === "FAIL" && TrueQ[stopOnFailure],
    Print["Audit failed at stage '", stage, "'. Stopping pipeline."];
    Return[$Failed];
  ];
  report
];

RunSVBPipeline[rootDir_, label_,
               poleType_, lsAddPole_, order_:3, yOrder_:4,
               OptionsPattern[]] := Module[
  {weightN, auditQ, auditReportQ, stopOnFailureQ, auditResidualsQ,
   auditReports, audit, stageStartedAt, combinedAudit},

  auditQ = TrueQ[OptionValue["Audit"]];
  auditReportQ = TrueQ[OptionValue["AuditReport"]];
  stopOnFailureQ = TrueQ[OptionValue["StopOnAuditFailure"]];
  auditResidualsQ = TrueQ[OptionValue["AuditResiduals"]];
  auditReports = {};

  (* ---- load conformal weight calculator ---- *)
  Get[FileNameJoin[{rootDir, "ConformalWeight.m"}]];

  (* ---- determine normalization ---- *)
  weightN = -ConformalWeight[$Integrand, 1];

  If[auditQ,
    If[SVBMasterLoadAudit[rootDir] === $Failed, Return[$Failed]];
    audit = RunReviewGate[rootDir, label, "preflight",
      "Integrand" -> $Integrand,
      "PoleType" -> poleType,
      "LSBase" -> lsAddPole,
      "AnsatzExpr" -> ansatzExpr,
      "BasisSV" -> basisSV,
      "BasisMPL" -> basisMPL,
      "WriteReport" -> False
    ];
    AppendTo[auditReports, audit];
    If[SVBMasterHandleAudit[rootDir, label, "preflight", audit,
        auditReportQ, stopOnFailureQ] === $Failed,
      Return[$Failed]
    ];
  ];

  Print["=== Processing integrand '", label, "' ==="];
  Print["  Conformal weight n = ", weightN];
  Print["  Primary pole: ", poleType, ",  additional pole: ", lsAddPole];

  (* Skill 2: Boundary Conditions (uses global $Integrand, $Perms) *)
  stageStartedAt = DateObject[];
  RunBoundaryConditions[rootDir, label, order];
  If[auditQ,
    audit = RunReviewGate[rootDir, label, "boundary",
      "Order" -> order,
      "RunStartedAt" -> stageStartedAt,
      "ExpectedPermutations" -> $Perms,
      "WriteReport" -> False
    ];
    AppendTo[auditReports, audit];
    If[SVBMasterHandleAudit[rootDir, label, "boundary", audit,
        auditReportQ, stopOnFailureQ] === $Failed,
      Return[$Failed]
    ];
  ];

  (* Skill 1: Series Expansion *)
  stageStartedAt = DateObject[];
  RunSeriesExpansion[rootDir, label, lsAddPole, poleType, weightN, yOrder];
  If[auditQ,
    audit = RunReviewGate[rootDir, label, "series",
      "BasisSV" -> basisSV,
      "BasisMPL" -> basisMPL,
      "YOrder" -> yOrder,
      "LSBase" -> lsAddPole,
      "WeightN" -> weightN,
      "RunStartedAt" -> stageStartedAt,
      "WriteReport" -> False
    ];
    AppendTo[auditReports, audit];
    If[SVBMasterHandleAudit[rootDir, label, "series", audit,
        auditReportQ, stopOnFailureQ] === $Failed,
      Return[$Failed]
    ];
  ];

  (* Skill 3: Coefficient Solving (uses globals ansatzExpr, basisSV, basisMPL, targetData) *)
  stageStartedAt = DateObject[];
  RunCoefficientSolving[rootDir, label, ansatzExpr, basisSV, basisMPL, targetData, order];
  If[auditQ,
    audit = RunReviewGate[rootDir, label, "solve",
      "AnsatzExpr" -> ansatzExpr,
      "BasisSV" -> basisSV,
      "BasisMPL" -> basisMPL,
      "Order" -> order,
      "TargetData" -> targetData,
      "RunStartedAt" -> stageStartedAt,
      "VerifyResiduals" -> auditResidualsQ,
      "WriteReport" -> False
    ];
    AppendTo[auditReports, audit];
    If[SVBMasterHandleAudit[rootDir, label, "solve", audit,
        auditReportQ, stopOnFailureQ] === $Failed,
      Return[$Failed]
    ];

    combinedAudit = SVBAuditCombine["pipeline:" <> label, Sequence @@ auditReports];
    SVBMasterHandleAudit[rootDir, label, "pipeline", combinedAudit,
      auditReportQ, stopOnFailureQ];
  ];

  Print["Pipeline complete for '", label, "'."];
  If[auditQ, combinedAudit, Null]
];
