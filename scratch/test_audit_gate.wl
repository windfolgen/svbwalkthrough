(* test_audit_gate.wl *)
rootDir = ParentDirectory[DirectoryName[AbsoluteFileName[$InputFileName]]];
SetDirectory[rootDir];

Print["Loading review agent directly..."];
Get[FileNameJoin[{rootDir, "review_agent.wl"}]];
LoadReviewAgent[rootDir];

Print["Loading input_parser.wl..."];
Get[FileNameJoin[{rootDir, "input_parser.wl"}]];

Print["Parsing inputs for threeloophard2..."];
config = ParseInput[FileNameJoin[{rootDir, "runs", "threeloophard2"}]];

Print["Running ReviewGate boundary check..."];
rBoundary = ReviewGate[rootDir, "threeloophard2", "boundary", config];
Print["Boundary Status: ", rBoundary["Status"]];
Print["Boundary Summary: ", Normal[rBoundary["Summary"]]];

Print["Running ReviewGate presolve check..."];
rPresolve = ReviewGate[rootDir, "threeloophard2", "presolve", config];
Print["Presolve Status: ", rPresolve["Status"]];
Print["Presolve Summary: ", Normal[rPresolve["Summary"]]];

If[rBoundary["Status"] === "PASS" && rPresolve["Status"] === "PASS",
  Print["SUCCESS: All audit checks passed!"],
  Print["FAILED: Some audit checks still failed."]
];
Exit[];
