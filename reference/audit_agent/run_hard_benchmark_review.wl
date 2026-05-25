(* Run the hard benchmark review suite for this workspace. *)

root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], ".."}]];

Get[FileNameJoin[{root, "audit_agent", "audit_agent.wl"}]];

report = AuditHardBenchmarkWorkspace[root, "WriteReport" -> True];

Print["Hard benchmark review status: ", report["Status"]];
Print["PASS/WARN/FAIL: ", report["Summary"]];

If[KeyExistsQ[report, "ReportFiles"],
  Print["Markdown report: ", report["ReportFiles", "MarkdownFile"]];
  Print["Mathematica report: ", report["ReportFiles", "MFile"]];
];
