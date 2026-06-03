$HistoryLength = 0;
runDir   = DirectoryName[$InputFileName] <> "runs/fourloopI41/";
rootDir  = DirectoryName[$InputFileName];
SetDirectory[rootDir];
Get[FileNameJoin[{rootDir, "workflow_engine.wl"}]];
Get[FileNameJoin[{rootDir, "input_parser.wl"}]];

parsed = ParseInput[runDir];
Print["SV elements: ", Length[parsed["BasisSV"][[1]]]];
Print["MPL elements: ", Length[parsed["BasisMPL"][[1]]]];
