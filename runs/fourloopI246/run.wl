(* Unified workflow: the same entry points as the original examples. *)
$HistoryLength = 0;
runDir = DirectoryName[$InputFileName];
rootDir = ParentDirectory[ParentDirectory[runDir]];
SetDirectory[rootDir];
Get[FileNameJoin[{rootDir, "workflow_engine.wl"}]];
Get[FileNameJoin[{rootDir, "input_parser.wl"}]];
label = "fourloopI246";
parsed = ParseInput[runDir];
If[parsed === $Failed, Exit[1]];
answer = SolveIntegrandSystem[rootDir, label, parsed, 6, 6];
Exit[If[FailureQ[answer] || answer === $Failed, 1, 0]];
