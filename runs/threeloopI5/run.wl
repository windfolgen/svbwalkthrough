(* =================================================================== *)
(*  Bootstrap Run: threeloopI5                                           *)
(*                                                                     *)
(*  Integrand: 1 / (10 propagators)                                     *)
(*  LS: 1/((z-zz)(1-v)),  n=2,  poleType="simple"                       *)
(*  Ansatz: threeloopoddansatz.m  (30 elements, odd parity)              *)
(* =================================================================== *)

$HistoryLength = 0;

runDir   = DirectoryName[$InputFileName];
rootDir  = ParentDirectory[ParentDirectory[runDir]];
SetDirectory[rootDir];
Print["Root: ", rootDir];
Print["Run:  ", runDir];

Get[FileNameJoin[{rootDir, "workflow_engine.wl"}]];
Get[FileNameJoin[{rootDir, "input_parser.wl"}]];

label = "threeloopI5";
order = 3;
yOrder = 4;
loopPoints = {5, 6, 7};

parsed = ParseInput[runDir];
If[parsed === $Failed, Print["Failed to parse input."]; Exit[1]];

SolveIntegrandSystem[rootDir, label, parsed, order, yOrder];
