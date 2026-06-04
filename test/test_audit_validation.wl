(* test_audit_validation.wl *)
$HistoryLength = 0;
testDir = DirectoryName[$InputFileName];
rootDir = ParentDirectory[testDir];

Print["Root Directory: ", rootDir];
SetDirectory[rootDir];

Get[FileNameJoin[{rootDir, "config.wl"}]];
Get[FileNameJoin[{rootDir, "audit_agent", "audit_agent.wl"}]];

RunTest[label_, runContent_, inputContent_, expectedStatus_] := Module[
  {runFolder, runFile, inputFile, report, checks, status},
  
  runFolder = FileNameJoin[{rootDir, "runs", label}];
  If[!DirectoryQ[runFolder], CreateDirectory[runFolder]];
  
  runFile = FileNameJoin[{runFolder, "run.wl"}];
  inputFile = FileNameJoin[{runFolder, "input.wl"}];
  
  If[StringQ[runContent], Put[OutputForm[runContent], runFile]];
  If[StringQ[inputContent], Put[OutputForm[inputContent], inputFile]];
  
  report = AuditInput[rootDir, label, <||>];
  status = report["Status"];
  checks = report["Checks"];
  
  Print["Test Label: ", label];
  Print["  Report Status: ", status];
  Do[
    Print["    ", check["Check"], " -> ", check["Status"], " (", check["Message"], ")"];
  , {check, checks}];
  
  (* Clean up *)
  If[FileExistsQ[runFile], DeleteFile[runFile]];
  If[FileExistsQ[inputFile], DeleteFile[inputFile]];
  If[DirectoryQ[runFolder], DeleteDirectory[runFolder]];
  
  If[status =!= expectedStatus,
    Print["FAILED: Expected status ", expectedStatus, " but got ", status];
    Exit[1];
  ];
  Print["SUCCESS: Status matched expected: ", expectedStatus, "\n"];
];

Print["\n=== TEST 1: Correct run.wl and input.wl ==="];
RunTest[
  "test_audit_correct",
  "(* run.wl *)\nGet[\"workflow_engine.wl\"];\nGet[\"input_parser.wl\"];\nSolveIntegrandSystem[rootDir, label, parsed, order, yOrder];",
  "integrand = 1;\nleadingsingularity = 1;\nansatz = {1};\nOrderY = 3;",
  "PASS"
];

Print["=== TEST 2: Missing run.wl ==="];
RunTest[
  "test_audit_missing_run",
  None, (* Missing run.wl *)
  "integrand = 1;\nleadingsingularity = 1;\nansatz = {1};\nOrderY = 3;",
  "FAIL"
];

Print["=== TEST 3: Invalid run.wl structure (missing imports) ==="];
RunTest[
  "test_audit_invalid_run",
  "(* empty run.wl *)",
  "integrand = 1;\nleadingsingularity = 1;\nansatz = {1};\nOrderY = 3;",
  "WARN"
];

Print["=== TEST 4: Mismatched list lengths in input.wl ==="];
RunTest[
  "test_audit_mismatch",
  "(* run.wl *)\nGet[\"workflow_engine.wl\"];\nGet[\"input_parser.wl\"];\nSolveIntegrandSystem[rootDir, label, parsed, order, yOrder];",
  "integrandlist = {1, 2};\ncoeff = {1};\nleadingsingularitylist = {1};\nansatzlist = {1, 2};\nOrderY = 3;",
  "FAIL"
];

Print["=== TEST 5: Missing coefficients for list input ==="];
RunTest[
  "test_audit_missing_coeff",
  "(* run.wl *)\nGet[\"workflow_engine.wl\"];\nGet[\"input_parser.wl\"];\nSolveIntegrandSystem[rootDir, label, parsed, order, yOrder];",
  "integrandlist = {1, 2};\nleadingsingularity = 1;\nansatz = {1};\nOrderY = 3;",
  "FAIL"
];

Print["ALL TESTS PASSED SUCCESSFULLY!"];
