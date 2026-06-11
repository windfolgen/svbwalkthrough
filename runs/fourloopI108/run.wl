(* =================================================================== *)
(*  Bootstrap Run: fourloopI108                                         *)
(*                                                                     *)
(*  Integrand: (x[1,2] x[1,3] x[1,4] x[5,6]) / (14 propagators)         *)
(*  LS: 1/(z-zz),  n=2,  poleType="simple"                              *)
(*  Ansatz: allsvlistoddans.m                                           *)
(* =================================================================== *)

$HistoryLength = 0;

runDir   = DirectoryName[$InputFileName];
rootDir  = ParentDirectory[ParentDirectory[runDir]];
SetDirectory[rootDir];
Print["Root: ", rootDir];
Print["Run:  ", runDir];

Get[FileNameJoin[{rootDir, "workflow_engine.wl"}]];
Get[FileNameJoin[{rootDir, "input_parser.wl"}]];

label = "fourloopI108";
order = 4;
yOrder = 5;
loopPoints = {5, 6, 7, 8};

parsed = ParseInput[runDir];
If[parsed === $Failed, Print["Failed to parse input."]; Exit[1]];

SolveIntegrandSystem[rootDir, label, parsed, order, yOrder];
