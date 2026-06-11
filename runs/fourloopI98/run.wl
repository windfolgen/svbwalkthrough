(* =================================================================== *)
(*  Bootstrap Run: fourloopI98                                          *)
(*                                                                     *)
(*  Integrand: (x[1,2] x[1,4] x[3,5]) / (13 propagators)               *)
(*  LS: 1/(z-zz),  n=2,  poleType="simple"                              *)
(*  Ansatz: svlistoddansatz_w8.m                                        *)
(* =================================================================== *)

$HistoryLength = 0;

runDir   = DirectoryName[$InputFileName];
rootDir  = ParentDirectory[ParentDirectory[runDir]];
SetDirectory[rootDir];
Print["Root: ", rootDir];
Print["Run:  ", runDir];

Get[FileNameJoin[{rootDir, "workflow_engine.wl"}]];
Get[FileNameJoin[{rootDir, "input_parser.wl"}]];

label = "fourloopI98";
order = 4;
yOrder = 5;
loopPoints = {5, 6, 7, 8};

parsed = ParseInput[runDir];
If[parsed === $Failed, Print["Failed to parse input."]; Exit[1]];

SolveIntegrandSystem[rootDir, label, parsed, order, yOrder];
