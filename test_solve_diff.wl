$HistoryLength = 0;
runDir   = DirectoryName[$InputFileName] <> "runs/fourloopI41/";
rootDir  = DirectoryName[$InputFileName];
SetDirectory[rootDir];
Get[FileNameJoin[{rootDir, "workflow_engine.wl"}]];
Get[FileNameJoin[{rootDir, "input_parser.wl"}]];

parsed = ParseInput[runDir];
label = "fourloopI41";
order = 4;
yOrder = 5;

ansatzList = parsed["LeadingSingularities"][[All,3]];
labelsList = {label};
basisSVList = parsed["BasisSV"]; (* WAIT, parsed doesn't have it! *)
