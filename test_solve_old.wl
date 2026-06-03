$HistoryLength = 0;
runDir   = DirectoryName[$InputFileName] <> "runs/fourloopI41/";
rootDir  = DirectoryName[$InputFileName];
SetDirectory[rootDir];
Get[FileNameJoin[{rootDir, "workflow_engine.wl"}]];
Get[FileNameJoin[{rootDir, "input_parser.wl"}]];
Get["/tmp/old_solve_agent.wl"];

parsed = ParseInput[runDir];
ansatz = parsed["LeadingSingularities"][[1,3]];
order = 4;
yOrder = 5;
label = "fourloopI41";

basisSV = Import["data/allsvlistmpl_fourloop_invzz.m"];
basisMPL = {};

targetData = Table[
  permStr = StringJoin[ToString /@ $Perms[[i]]];
  path = FileNameJoin[{rootDir, "asym", "boundary_agent", label <> permStr <> "_order" <> ToString[order] <> "_asyexp.m"}];
  Import[path] // Normal,
  {i, 1, 6}
];

RunCoefficientSolving[rootDir, label, ansatz, basisSV, basisMPL, targetData, order];
