(* =================================================================== *)
(*  Bootstrap Run: threeloophard2                                        *)
(*                                                                     *)
(*  Integrand: (x[5,6]*x[3,4] - x[3,6]x[4,5] - x[3,5]x[4,6])          *)
(*             / (12 propagators with 5,6,7)                            *)
(*  LS: 1/((z-zz)(1-v)),  n=2,  poleType="simple"                       *)
(*  Ansatz: threeloophard2_ans.m  (43 elements, even parity)             *)
(* =================================================================== *)

$HistoryLength = 0;

runDir   = DirectoryName[$InputFileName];
rootDir  = ParentDirectory[ParentDirectory[runDir]];
SetDirectory[rootDir];
Print["Root: ", rootDir];
Print["Run:  ", runDir];

Get[FileNameJoin[{rootDir, "workflow_engine.wl"}]];
Get[FileNameJoin[{rootDir, "input_parser.wl"}]];

label = "threeloophard2";
order = 3;
yOrder = 4;
loopPoints = {5, 6, 7};

parsed = ParseInput[runDir];
If[parsed === $Failed, Print["Failed to parse input."]; Exit[1]];

SolveIntegrandSystem[rootDir, label, parsed, order, yOrder];
