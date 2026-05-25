(* =================================================================== *)
(*  Bootstrap Run: threeloophard2                                       *)
(*                                                                     *)
(*  Integrand: (x[3,6]x[4,5]+x[3,5]x[4,6]) / (12 propagators)          *)
(*  LS: 1/((z-zz)(1-v)),  n=2,  poleType="simple"                      *)
(*  Ansatz: threeloophard2_ans.m                                        *)
(* =================================================================== *)

$HistoryLength = 0;

(* ---- directory layout ---- *)
runDir   = DirectoryName[$InputFileName];           (* runs/threeloophard2/ *)
rootDir  = ParentDirectory[ParentDirectory[runDir]]; (* project root *)
SetDirectory[rootDir];
Print["Root: ", rootDir];
Print["Run:  ", runDir];

(* ---- load conformal weight ---- *)
Get[FileNameJoin[{rootDir, "ConformalWeight.m"}]];

(* ---- load conformal weight ---- *)
Get[FileNameJoin[{rootDir, "ConformalWeight.m"}]];

(* ---- load ansatz and basis files ---- *)
ansatzExpr = Import[FileNameJoin[{rootDir, "threeloophard2_ans.m"}]];
Print["Ansatz length: ", Length[ansatzExpr]];

basisSV  = Import[FileNameJoin[{rootDir, "allsvlist_fourloop.m"}]];
basisMPL = Import[FileNameJoin[{rootDir, "allsvlistmpl_threeloop.m"}]];
Print["basisSV length: ", Length[basisSV], ", basisMPL length: ", Length[basisMPL]];

(* ---- reduce to basis elements appearing in ansatz ---- *)
basisElements = DeleteDuplicates @ Cases[ansatzExpr, _I | _f, {1, Infinity}];
svIndices = Function[e, If[# === {}, 0, #[[1,1]]] & @ Position[basisSV, e, {1}]] /@ basisElements;
mplIndices = Function[e, If[# === {}, 0, #[[1,1]]] & @ Position[basisMPL, e, {1}]] /@ basisElements;
svIndices = DeleteDuplicates[Select[svIndices, Positive]];
mplIndices = DeleteDuplicates[Select[mplIndices, Positive]];
Print["SVHPL in ansatz: ", Length[svIndices], " (of ", Length[basisSV], ")"];
Print["MPL in ansatz: ", Length[mplIndices], " (of ", Length[basisMPL], ")"];

basisSVReduced  = basisSV[[svIndices]];
basisMPLReduced = basisMPL[[mplIndices]];

(* ---- global variables ---- *)
$Integrand = (x[3, 6] x[4, 5] + x[3, 5] x[4, 6]) /
  (x[1, 5] x[1, 6] x[2, 5] x[2, 6] x[3, 5] x[3, 6] x[3, 7] x[4, 5] x[4, 6] x[4, 7] x[5, 7] x[6, 7]);

$Perms = {{1,2,3,4},{2,1,3,4},{1,3,2,4},{2,3,1,4},{3,1,2,4},{3,2,1,4}};
label = "threeloophard2";
weightN = -ConformalWeight[$Integrand, 1];
Print["Conformal weight n = ", weightN];

poleType = "simple";
lsAddPole = 1/(1 - v);   (* additional pole for LS = 1/((z-zz)(1-v)) *)
order = 3;
yOrder = 4;

(* ---- load review + audit agents ---- *)
Get[FileNameJoin[{rootDir, "review_agent.wl"}]];
LoadReviewAgent[rootDir];
Print["Audit: ", If[ValueQ[RunReviewGate], "enabled", "disabled (audit_agent.wl not found)"]];

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
LaunchKernels[6];  (* needed for ParallelTable inside SeriesExpansion functions *)
Get[FileNameJoin[{rootDir, "series_agent", "series_agent.wl"}]];
RunSeriesExpansion[rootDir, label, lsAddPole, poleType, weightN, yOrder, svIndices, mplIndices];
ReviewGate[rootDir, label, "series"];
CloseKernels[];

(* ====== Skill 3: Coefficient Solving ====== *)
Print[""];
Print["=== SKILL 3: Coefficient Solving ==="];
Get[FileNameJoin[{rootDir, "solve_agent", "solve_agent.wl"}]];
RunCoefficientSolving[rootDir, label, ansatzExpr, basisSVReduced, basisMPLReduced, targetData, order];
ReviewGate[rootDir, label, "solve"];

(* ====== Verify solution ====== *)
Print[""];
Print["=== VERIFY ==="];
sol = Import[FileNameJoin[{rootDir, "solve_agent", label <> "_sol.m"}]];
Print["Solved ", Length[sol], " coefficients"];
Print["Sample: ", Take[sol, UpTo[5]]];

(* ====== Save result to run directory ====== *)
Print[""];
Print["=== SAVE RESULT ==="];
ansatzFinal = Import[FileNameJoin[{rootDir, "threeloophard2_ans.m"}]];
values = sol /. Rule[_[_], v_] :> v;
finalResult = Expand[Sum[values[[i]] * ansatzFinal[[i]], {i, 1, Length[ansatzFinal]}]];
Export[FileNameJoin[{runDir, "result.m"}], finalResult];
Print["Result saved to ", FileNameJoin[{runDir, "result.m"}]];
Print["Solved coefficients saved to ", FileNameJoin[{rootDir, "solve_agent", label <> "_sol.m"}]];

Print[""];
Print["Run complete."];
