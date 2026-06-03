$HistoryLength = 0;
runDir   = DirectoryName[$InputFileName] <> "runs/fourloopI41/";
rootDir  = DirectoryName[$InputFileName];
SetDirectory[rootDir];
Get[FileNameJoin[{rootDir, "workflow_engine.wl"}]];
Get[FileNameJoin[{rootDir, "input_parser.wl"}]];
Get["/tmp/old_solve_agent.wl"];

parsed = ParseInput[runDir];
label = "fourloopI41";
order = 4;
yOrder = 5;

(* Manually do what workflow_engine does *)
ansatz = parsed["LeadingSingularities"][[1,3]];
basisElements = DeleteDuplicates @ Cases[ansatz, _I | _f, {1, Infinity}];

fullBasisSV = Import[FileNameJoin[{$DataDir, $SVTextPrefix <> "e0_uptow8_inuv.txt"}]];
svIndices = Function[e, If[# === {}, 0, #[[1,1]]] & @ Position[fullBasisSV, e, {1}]] /@ basisElements;
svIndices = DeleteDuplicates[Select[svIndices, Positive]];
basisSV = fullBasisSV[[svIndices]];

fullBasisMPL = Import[FileNameJoin[{$DataDir, "allsvlistmpl_fourloop_invzz.m"}]];
mplIndices = Function[e, If[# === {}, 0, #[[1,1]]] & @ Position[fullBasisMPL, e, {1}]] /@ basisElements;
mplIndices = DeleteDuplicates[Select[mplIndices, Positive]];
basisMPL = fullBasisMPL[[mplIndices]];

targetData = Table[
  permStr = StringJoin[ToString /@ $Perms[[i]]];
  path = FileNameJoin[{rootDir, "asym", "boundary_agent", label <> permStr <> "_order" <> ToString[order] <> "_asyexp.m"}];
  Import[path] // Normal,
  {i, 1, 6}
];

RunCoefficientSolving[rootDir, label, ansatz, basisSV, basisMPL, targetData, order];
