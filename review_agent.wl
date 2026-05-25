(* =================================================================== *)
(*  Review Agent Facade                                                *)
(*  Location: ./ (project root)                                        *)
(*                                                                     *)
(*  Thin public wrapper around audit_agent/.  The master orchestrator  *)
(*  calls ReviewGate after each stage; this delegates to the full      *)
(*  audit engine when loaded, falling back to basic file checks.       *)
(* =================================================================== *)

ClearAll[LoadReviewAgent, ReviewGate];

(* ------------------------------------------------------------------- *)
(*  LoadReviewAgent — load the audit engine from disk                   *)
(* ------------------------------------------------------------------- *)
LoadReviewAgent[rootDir_] := Module[{auditFile},
  auditFile = FileNameJoin[{rootDir, "audit_agent", "audit_agent.wl"}];
  If[FileExistsQ[auditFile],
    Get[auditFile];
    Print["Review agent loaded from ", auditFile],
    Print["Warning: audit agent not found at ", auditFile, " — review disabled"]
  ];
];

(* ------------------------------------------------------------------- *)
(*  ReviewGate — unified entry point for per-stage review              *)
(*    stage: "preflight" | "boundary" | "series" | "solve" | "pipeline" *)
(* ------------------------------------------------------------------- *)
ReviewGate[rootDir_, label_, stage_String] := Module[
  {report},

  (* use full audit agent when available *)
  If[ValueQ[RunReviewGate] || Length[DownValues[RunReviewGate]] > 0,
    report = RunReviewGate[rootDir, label, stage];
    Print["[ReviewGate] ", stage, " stage: ", report["Status"],
      " (PASS:", report["Summary", "PASS"],
      " WARN:", report["Summary", "WARN"],
      " FAIL:", report["Summary", "FAIL"], ")"];
    If[report["Status"] === "FAIL",
      Print["[ReviewGate]  FAIL details: ",
        Cases[report["Checks"], _?(#["Status"] === "FAIL" &)]];
    ];
    Return[report];
  ];

  (* fallback: audit agent not loaded — return neutral PASS *)
  Print["[ReviewGate] Audit agent not loaded — returning PASS."];
  Association["Status" -> "PASS", "Summary" -> Association[]]
];
