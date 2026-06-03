(* =================================================================== *)
(*  Bootstrap Run: fourloopI42                                           *)
(*                                                                     *)
(*  Integrand: Decomposed Multi-Component integrand                      *)
(*  LS: 1/(z-zz),  n=2,  poleType="simple",  k=1                       *)
(*  4-loop: order=4, yOrder=5, internal points {5,6,7,8}               *)
(*  Ansatz: fourloopI42ansatz.m                                         *)
(* =================================================================== *)

$HistoryLength = 0;

runDir   = DirectoryName[$InputFileName];
rootDir  = ParentDirectory[ParentDirectory[runDir]];
SetDirectory[rootDir];
Print["Root: ", rootDir];
Print["Run:  ", runDir];

Get[FileNameJoin[{rootDir, "workflow_engine.wl"}]];
Get[FileNameJoin[{runDir, "input.wl"}]];

label = "fourloopI42";
order = 4;
yOrder = 5;
loopPoints = {5, 6, 7, 8};

ansatzExpr = ansatz;

lsConfigList = {
  {"simple", 1, ansatzExpr}
};

SolveIntegrandSystem[rootDir, label, integrandlist, coeff, lsConfigList, order, yOrder, loopPoints];
