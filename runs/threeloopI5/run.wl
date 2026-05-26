(* =================================================================== *)
(*  Bootstrap Run: threeloopI5                                          *)
(*                                                                     *)
(*  Integrand: 1 / (x[1,6] x[1,7] x[2,6] x[2,7] x[3,5] x[3,7]         *)
(*                  x[4,5] x[4,6] x[5,6] x[5,7])                       *)
(*  LS: 1/((z-zz)(1-v)),  n=2,  poleType="simple"                      *)
(*  Ansatz: threeloopoddansatz.m  (30 elements, odd parity)             *)
(* =================================================================== *)

$HistoryLength = 0;

(* ---- directory layout ---- *)
runDir   = DirectoryName[$InputFileName];           (* runs/threeloopI5/ *)
rootDir  = ParentDirectory[ParentDirectory[runDir]]; (* project root *)
SetDirectory[rootDir];
Print["Root: ", rootDir];
Print["Run:  ", runDir];

(* ---- load conformal weight ---- *)
Get[FileNameJoin[{rootDir, "ConformalWeight.m"}]];

(* ---- load ansatz and basis files ---- *)
ansatzExpr = Import[FileNameJoin[{runDir, "threeloopoddansatz.m"}]];
Print["Ansatz length: ", Length[ansatzExpr]];

basisSV  = Import[FileNameJoin[{rootDir, "allsvlist_fourloop.m"}]];
Print["basisSV length: ", Length[basisSV]];

(* ---- reduce to basis elements appearing in ansatz ---- *)
basisElements = DeleteDuplicates @ Cases[ansatzExpr, _I | _f, {1, Infinity}];
svIndices = Function[e, If[# === {}, 0, #[[1,1]]] & @ Position[basisSV, e, {1}]] /@ basisElements;
svIndices = DeleteDuplicates[Select[svIndices, Positive]];
Print["SVHPL in ansatz: ", Length[svIndices], " (of ", Length[basisSV], ")"];
basisSVReduced  = basisSV[[svIndices]];

(* ---- auto-detect MPL basis: scan allsvlistmpl_*.m, pick best coverage ---- *)
mplBasisFile = None;
mplFiles = FileNames[FileNameJoin[{rootDir, "allsvlistmpl_*.m"}]];
(* filter out expansion files (end with e0.m, e1.m, einf.m) *)
mplFiles = Select[mplFiles, !StringMatchQ[#, ___ ~~ ("e0.m" | "e1.m" | "einf.m")] &];
If[mplFiles =!= {},
  bestCount = 0;
  Do[
    mplTry = Import[f];
    idx = Function[e, If[# === {}, 0, #[[1,1]]] & @ Position[mplTry, e, {1}]] /@ basisElements;
    idx = Select[idx, Positive];
    If[Length[idx] > bestCount, bestCount = Length[idx]; bestFile = f],
    {f, mplFiles}
  ];
  If[bestCount > 0,
    mplBasisFile = bestFile;
    basisMPL = Import[mplBasisFile];
    mplIndices = Function[e, If[# === {}, 0, #[[1,1]]] & @ Position[basisMPL, e, {1}]] /@ basisElements;
    mplIndices = DeleteDuplicates[Select[mplIndices, Positive]];
    basisMPLReduced = basisMPL[[mplIndices]];
    Print["MPL in ansatz: ", Length[mplIndices], " (of ", Length[basisMPL], "), basis: ", FileBaseName[mplBasisFile]];
  ,
    Print["MPL in ansatz: 0 (no matching basis found)"];
    mplIndices = {};
    basisMPLReduced = {};
  ];
,
  Print["MPL: no basis files found"];
  mplIndices = {};
  basisMPLReduced = {};
];

(* ---- global variables ---- *)
$Integrand = 1/(x[1,6] x[1,7] x[2,6] x[2,7] x[3,5] x[3,7] x[4,5] x[4,6] x[5,6] x[5,7]);

$Perms = {{1,2,3,4},{2,1,3,4},{1,3,2,4},{2,3,1,4},{3,1,2,4},{3,2,1,4}};
label = "threeloopI5";
weightN = -ConformalWeight[$Integrand, 1];
Print["Conformal weight n = ", weightN];

poleType = "simple";
lsAddPole = 1/(1 - v);  (* base = 1/(1-v), primary pole = 1/(z-zz) *)
order = 3;
yOrder = 4;

(* ---- load review + audit agents ---- *)
Get[FileNameJoin[{rootDir, "review_agent.wl"}]];
LoadReviewAgent[rootDir];
Print["Audit: ", If[ValueQ[RunReviewGate], "enabled", "disabled"]];

(* ====== Skill 2: Boundary Conditions ====== *)
Print[""];
Print["=== SKILL 2: Boundary Conditions ==="];
Get[FileNameJoin[{rootDir, "asym", "boundary_agent", "boundary_agent.wl"}]];
RunBoundaryConditions[rootDir, label, order, "InputDir" -> FileNameJoin[{runDir, "boundaries"}]];
ReviewGate[rootDir, label, "boundary"];

(* ====== Load boundary conditions into targetData ====== *)
Print[""];
Print["=== Loading targetData ==="];
targetData = Table[
  Module[{perm, permStr, path, data},
    perm = $Perms[[i]];
    permStr = StringJoin[ToString /@ perm];
    path = FileNameJoin[{rootDir, "asym", "boundary_agent", label <> permStr <> "_order" <> ToString[order] <> "_asyexp.m"}];
    If[! FileExistsQ[path], Print["FAIL: missing ", path]; Return[$Failed]];
    Quiet[data = Import[path] // Normal, Import::nffil];
    Print["  targetData[[", i, "]] loaded from ", label, permStr];
    data
  ],
  {i, 1, 6}
];
If[MemberQ[targetData, $Failed],
  Print["ABORT: boundary files missing."];
  Return[]
];

(* ====== Skill 1: Series Expansion ====== *)
Print[""];
Print["=== SKILL 1: Series Expansion ==="];
LaunchKernels[6];
Get[FileNameJoin[{rootDir, "series_agent", "series_agent.wl"}]];
RunSeriesExpansion[rootDir, label, lsAddPole, poleType, weightN, yOrder, svIndices, mplIndices, 1, mplBasisFile];
ReviewGate[rootDir, label, "series"];
CloseKernels[];

(* ====== Skill 3: Coefficient Solving ====== *)
Print[""];
Print["=== SKILL 3: Coefficient Solving ==="];
Get[FileNameJoin[{rootDir, "solve_agent", "solve_agent.wl"}]];
RunCoefficientSolving[rootDir, label, ansatzExpr, basisSVReduced, basisMPLReduced, targetData, order];
ReviewGate[rootDir, label, "solve"];

(* ====== Save result to run directory ====== *)
Print[""];
Print["=== SAVE RESULT ==="];
sol = Import[FileNameJoin[{rootDir, "solve_agent", label <> "_sol.m"}]];
values = sol /. Rule[_[_], v_] :> v;
finalResult = Expand[Sum[values[[i]] * ansatzExpr[[i]], {i, 1, Length[ansatzExpr]}]];
Export[FileNameJoin[{runDir, "result.m"}], finalResult];
Print["Result saved to ", FileNameJoin[{runDir, "result.m"}]];
Print["Solved coefficients saved to ", FileNameJoin[{rootDir, "solve_agent", label <> "_sol.m"}]];
Print["Non-zero: ", Select[Transpose[{Range[Length[ansatzExpr]], values}], #[[2]] =!= 0 &] // TableForm];

Print[""];
Print["Run complete."];
