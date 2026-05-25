(* Thin wrapper around audit_agent/audit_agent.wl. *)

ClearAll[LoadReviewAgent, RunStageReview, RunHardBenchmarkReview];

LoadReviewAgent[rootDir_] := Module[{path},
  path = FileNameJoin[{rootDir, "audit_agent", "audit_agent.wl"}];
  If[! FileExistsQ[path],
    Print["Review agent was not found: ", path];
    Return[$Failed];
  ];
  Get[path];
  path
];

RunStageReview[rootDir_, label_, stage_, opts___Rule] := Module[{},
  If[LoadReviewAgent[rootDir] === $Failed, Return[$Failed]];
  RunReviewGate[rootDir, label, stage, opts]
];

RunHardBenchmarkReview[rootDir_, opts___Rule] := Module[{},
  If[LoadReviewAgent[rootDir] === $Failed, Return[$Failed]];
  AuditHardBenchmarkWorkspace[rootDir, opts]
];
