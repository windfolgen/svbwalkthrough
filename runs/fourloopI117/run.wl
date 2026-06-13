(* =================================================================== *)
(*  Bootstrap Run: fourloopI117                                         *)
(*                                                                     *)
(*  Integrand: (x[1,3] x[1,6] x[2,4])/(x[1,5] x[1,7] x[1,8] x[2,6] x[2,8] x[3,6] x[3,8] x[4,6] x[4,7] x[5,6] x[5,7] x[5,8] x[6,7]) *)
(*  LS: 1/(z-zz),  n=2,  poleType="simple"                              *)
(*  Ansatz: fourloopI41ansatz.m                                           *)
(* =================================================================== *)

$HistoryLength = 0;

runDir   = DirectoryName[$InputFileName];
rootDir  = ParentDirectory[ParentDirectory[runDir]];
SetDirectory[rootDir];
Print["Root: ", rootDir];
Print["Run:  ", runDir];

Get[FileNameJoin[{rootDir, "workflow_engine.wl"}]];
Get[FileNameJoin[{rootDir, "input_parser.wl"}]];

label = "fourloopI117";
order = 4;
yOrder = 5;

parsed = ParseInput[runDir];
If[parsed === $Failed, Print["Failed to parse input."]; Exit[1]];

SolveIntegrandSystem[rootDir, label, parsed, order, yOrder];
