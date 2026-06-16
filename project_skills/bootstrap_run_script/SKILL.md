---
name: bootstrap_run_script
description: >
  Write and configure the Wolfram Language run script (run.wl) for a bootstrap problem,
  connecting boundary calculations, series expansion, and coefficient solving with
  pre-flight and post-stage reviews.
---

# Bootstrap Run Script Creator

## Overview
This skill provides the structure, template, and best practices for writing the bootstrap orchestrator run script (`run.wl`) inside `runs/<label>/`. The script connects all three core calculation agents (Skills 1, 2, 3) and integrates the pre-flight and stage review audits (Skill 4).

## Dependencies
- [ConformalWeight.m](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/ConformalWeight.m) — Conformal weight calculator.
- [review_agent.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/review_agent.wl) — Thin facade for stage audit checks.
- [boundary_agent.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/asym/boundary_agent/boundary_agent.wl) — Skill 2 boundary conditions.
- [series_agent.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/series_agent/series_agent.wl) — Skill 1 series expansion.
- [solve_agent.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/solve_agent/solve_agent.wl) — Skill 3 linear solver.

---

## Quick Start: Standard Template for `run.wl`

The run script must always be located at `runs/<label>/run.wl`. Below is the standard, production-ready template that incorporates all consistency fixes and audit reviews.

```mathematica
(* =================================================================== *)
(*  Bootstrap Run: <label>                                             *)
(*                                                                     *)
(*  Integrand: <integrand expression description>                      *)
(*  LS: <leading singularity description>                              *)
(*  Ansatz: <ansatz file name>                                         *)
(* =================================================================== *)

$HistoryLength = 0;

(* ---- 1. Directory Layout ---- *)
runDir   = DirectoryName[$InputFileName];
rootDir  = ParentDirectory[ParentDirectory[runDir]];
SetDirectory[rootDir];
Print["Root: ", rootDir];
Print["Run:  ", runDir];

(* ---- 2. Enable Log Redirection to logs/ ---- *)
logDir = FileNameJoin[{rootDir, "logs"}];
If[!DirectoryQ[logDir], CreateDirectory[logDir]];
logFile = FileNameJoin[{logDir, "<label>.log"}];
logStream = OpenWrite[logFile];
AppendTo[$Output, logStream];
AppendTo[$Messages, logStream];
Print["Logging initialized. Writing outputs to console and: ", logFile];

(* ---- 3. Import Conformal Weight Engine ---- *)
Get[FileNameJoin[{rootDir, "ConformalWeight.m"}]];

(* ---- 3. Load Ansatz and Basis Files ---- *)
ansatzExpr = Import[FileNameJoin[{runDir, "<label>_ans.m"}]];
Print["Ansatz length: ", Length[ansatzExpr]];

basisSV  = Import[FileNameJoin[{rootDir, "allsvlist_fourloop.m"}]];
Print["basisSV length: ", Length[basisSV]];

(* ---- 4. Pre-filter SVHPL Basis (4x Speedup) ---- *)
basisElements = DeleteDuplicates @ Cases[ansatzExpr, _I | _f, {1, Infinity}];
svIndices = Function[e, If[# === {}, 0, #[[1,1]]] & @ Position[basisSV, e, {1}]] /@ basisElements;
svIndices = DeleteDuplicates[Select[svIndices, Positive]];
Print["SVHPL in ansatz: ", Length[svIndices], " (of ", Length[basisSV], ")"];
basisSVReduced  = basisSV[[svIndices]];

(* ---- 5. Auto-Detect and Pre-filter MPL Basis ---- *)
mplBasisFile = None;
mplFiles = FileNames[FileNameJoin[{rootDir, "allsvlistmpl_*.m"}]];
(* Filter out expansion txt/m files *)
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

(* ---- 6. Define Global Integrand and Limits ---- *)
$Integrand = <INTEGRAND_EXPRESSION>;
$Perms = {{1,2,3,4},{2,1,3,4},{1,3,2,4},{2,3,1,4},{3,1,2,4},{3,2,1,4}};
label = "<label>";

weightN = -ConformalWeight[$Integrand, 1];
Print["Conformal weight n = ", weightN];

poleType = "<simple|double>";
lsAddPole = <ADDITIONAL_PREFACTOR>; (* e.g., 1, 1/(1-v), etc. *)
order = <3|4>;  (* 3 for 3-loop, 4 for 4-loop *)
yOrder = <4|5>; (* 4 for 3-loop, 5 for 4-loop *)

(* ---- 7. Initialize Stage Auditing ---- *)
Get[FileNameJoin[{rootDir, "review_agent.wl"}]];
LoadReviewAgent[rootDir];

(* ====== Stage 1: Pre-flight Audit ====== *)
ReviewGate[rootDir, label, "preflight"];
ReviewGate[rootDir, label, "preboundary"];

(* ====== Skill 2: Boundary Conditions ====== *)
Print["\n=== SKILL 2: Boundary Conditions ==="];
Get[FileNameJoin[{rootDir, "asym", "boundary_agent", "boundary_agent.wl"}]];
(* loopPoints are defined as a list, matching the Type constraint in boundary_agent *)
RunBoundaryConditions[rootDir, label, order, {5,6,7}, "InputDir" -> FileNameJoin[{runDir, "boundaries"}]];
ReviewGate[rootDir, label, "boundary"];

(* ====== Load Boundary Conditions into targetData ====== *)
Print["\n=== Loading targetData ==="];
targetData = Table[
  Module[{perm, permStr, path, data},
    perm = $Perms[[i]];
    permStr = StringJoin[ToString /@ perm];
    path = FileNameJoin[{rootDir, "asym", "boundary_agent", label <> permStr <> "_order" <> ToString[order] <> "_asyexp.m"}];
    If[! FileExistsQ[path], Print["FAIL: missing boundary file: ", path]; Return[$Failed]];
    (* Applying Normal strips SeriesData wrappers and converts to standard polynomials in Y *)
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
Print["\n=== SKILL 1: Series Expansion ==="];
ReviewGate[rootDir, label, "preseries"];
LaunchKernels[6];
Get[FileNameJoin[{rootDir, "series_agent", "series_agent.wl"}]];
poleOrder = poleType /. {"simple" -> 1, "double" -> 2};
RunSeriesExpansion[rootDir, label, lsAddPole, poleType, weightN, yOrder, svIndices, mplIndices, poleOrder, mplBasisFile];
ReviewGate[rootDir, label, "series"];
CloseKernels[];

(* ====== Skill 3: Coefficient Solving ====== *)
Print["\n=== SKILL 3: Coefficient Solving ==="];
ReviewGate[rootDir, label, "presolve"];
Get[FileNameJoin[{rootDir, "solve_agent", "solve_agent.wl"}]];
RunCoefficientSolving[rootDir, label, ansatzExpr, basisSVReduced, basisMPLReduced, targetData, order];
ReviewGate[rootDir, label, "solve"];

Print["\nRun complete."];
Close[logStream];
```

---

## Detailed Step-by-Step Instructions

### Step 1: Directory Setup
All files inside `run.wl` must be imported or exported relative to the project root directory. Use `DirectoryName[$InputFileName]` to derive the run-script directory (`runs/<label>/`), navigate to the project root, and perform a `SetDirectory[rootDir]`.

### Step 2: Basis Pre-filtering
To speed up computation by 4–8×, always reduce the massive primary basis (e.g., `allsvlist_fourloop.m` with 510 elements) to only the indices actually appearing in the user's customized ansatz. Match elements using `Position[basis, element]`.

### Step 3: Conformal Weight Normalization
The conformal weight determines the permutation prefactor transformation behavior. Ensure you:
1. Define the global `$Integrand` with explicit external points `1, 2, 3, 4` and internal integration vertices (`5, 6, 7` for 3-loop).
2. Calculate the weight `n = -ConformalWeight[$Integrand, 1]`.

### Step 4: Boundary Loading Rules
Always apply `// Normal` when importing the boundary condition data files generated by Skill 2. This strips the `SeriesData` wrapper from the boundary conditions and turns them into clean polynomials in `Y`.

### Step 5: Process and Kernel Safety
1. Call `LaunchKernels[6]` only right before executing `RunSeriesExpansion` (Skill 1) which utilizes `ParallelTable`.
2. Always call `CloseKernels[]` immediately after the series expansion is complete to free up system memory and avoid process duplication issues.

### Step 6: Log Redirection
To enable monitoring of long-running tasks, configure the run script to append its stream output to `$Output` and `$Messages`. This redirects `Print` outputs and any error/warning warnings to `logs/<label>.log` while still displaying them in the terminal in real-time. Close the stream using `Close[logStream]` at the end of the script.

---

## Common Pitfalls and Mistakes

### Shadowed Option Arguments
* **Problem**: Calling `RunBoundaryConditions[rootDir, label, order, "InputDir" -> path]` where the optional fourth parameter `loopPoints` does not have a `_List` type constraint. Mathematica binds the rule `"InputDir" -> path` to `loopPoints`, ignoring your directory option and attempting to do a heavy IBP from scratch.
* **Fix**: Ensure that the fourth parameter of `RunBoundaryConditions` is declared with `loopPoints_List` in `boundary_agent.wl`, and pass the loop points explicitly as a list (e.g., `{5,6,7}`) when call options are included.

### Shadowed Variable `Y`
* **Problem**: If `Y` is globally assigned to a numeric value or another expression before coefficients are solved, the series expansions and linear systems will evaluate incorrectly.
* **Fix**: Ensure `Clear[Y]` is called before solving or keep `Y` strictly symbolic throughout.
