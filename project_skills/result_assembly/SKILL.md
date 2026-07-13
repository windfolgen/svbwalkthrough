---
name: result_assembly
description: >
  Assemble the full Feynman integral expression from per-leading-singularity
  results in result.m by reattaching each leading singularity prefactor.
  Scans runs/, assembles <label>.txt for every run with result.m (renewing
  existing ones), skips runs without result.m.
---

# Result Assembly (Skill 5 — Final)

## Purpose

The coefficient solving stage ([Skill 3](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/project_skills/coefficient_solving/SKILL.md)) exports `result.m` as a **list** of per-leading-singularity (per-LS) transcendental expressions:

```
result.m = { result_1, result_2, ... }   (* one entry per LS *)
```

Each `result_k` is the pure transcendental part `Sum_i c_i * ansatzK_i` (a combination of `I[z,...]` symbols), with the **leading singularity prefactor stripped away** during series expansion. This skill reattaches the leading singularity to reconstruct the **full integral**:

```
full_integral = Sum_k [ leadingsingularity_k * result_k ]
```

## Script

A ready-to-run batch script lives alongside this SKILL.md:

- [assemble_results.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/project_skills/result_assembly/assemble_results.wl)

Run it from the project root:

```bash
MathKernel -noprompt -script project_skills/result_assembly/assemble_results.wl
```

The script resolves `rootDir` from its own location, so it works regardless of the calling directory.

### What the script does

1. **Scans** every subdirectory of `runs/`.
2. For each run `<label>`:
   - **Skip** if `result.m` is missing (run not yet successfully solved).
   - **Assemble** `Sum_k [ leadingsingularity_k * result_k ]` if `result.m` exists.
   - **Renew** `<label>.txt` if it already exists; otherwise **create** it.
3. Prints a per-run log (`Assembled ... renewed/created` / `SKIP ... result.m missing`) and a final tally.

This means the script is **idempotent**: re-running it refreshes all previously assembled outputs and picks up any newly solved runs without touching unsolved ones.

## Difference: `<label>.txt` vs `result.m`

| File | Content | LS prefactor? | Use |
|------|---------|---------------|-----|
| `result.m` | List `{result_1, result_2, ...}`, one pure transcendental expression per LS | **No** (stripped) | Intermediate; inspecting each LS contribution separately |
| `<label>.txt` | Single expression: the **full reconstructed integral** `Sum_k LS_k * result_k` | **Yes** (reattached) | Final physical result of the bootstrap |

`result.m` is the raw output of the solver; `<label>.txt` is the final assembled integral ready for physics interpretation. The output filename matches the run directory name (e.g. `runs/fourloopI41/fourloopI41.txt`).

## Input

From `runs/<label>/`:

| File | Provides | Required? |
|------|----------|-----------|
| `result.m` | List of per-LS transcendental results `{result_1, ...}` | **Yes** — skip run if missing |
| `input.wl` | `leadingsingularity` (scalar for single-LS, or `{LS_1, LS_2, ...}` list for multi-LS) | Yes |

## Assembly Logic (per run)

```mathematica
(* Skip runs without result.m — not yet successfully calculated *)
If[!FileExistsQ[resultFile],
  Print["SKIP ", label, ": result.m missing (not yet solved)"]; Continue[]
];

(* Load leading singularity from input.wl *)
Block[{integrand, leadingsingularity, ansatz, OrderY},
  Get[FileNameJoin[{runDir, "input.wl"}]];
  lsExpr = leadingsingularity;
];

(* Load per-LS results *)
resultList = Import[FileNameJoin[{runDir, "result.m"}]];

(* Assemble: single-LS (scalar) vs multi-LS (list) *)
If[ListQ[lsExpr],
  assembled = Sum[lsExpr[[k]] * resultList[[k]], {k, 1, Length[resultList]}],
  assembled = lsExpr * resultList[[1]]
];

(* Replace cross-ratio variables u,v with z,zz before export *)
assembled = assembled /. {u -> z*zz, v -> (1-z)*(1-zz)};

(* Renew if <label>.txt already exists, otherwise create *)
action = If[FileExistsQ[outFile], "renewed", "created"];
Export[FileNameJoin[{runDir, label <> ".txt"}], assembled // InputForm // ToString];
```

### Why `ListQ` detects multi-LS

- Single-LS input: `leadingsingularity = 1/(z-zz)` → `ListQ` is `False` → scalar multiply with `resultList[[1]]`.
- Multi-LS input: `leadingsingularity = {1/(z-zz), (u-v-1)/(z-zz)^2}` → `ListQ` is `True` → sum over `k`.

The length of `resultList` always matches the number of leading singularities.

### Cross-ratio replacement: `u,v → z,zz`

The leading singularity and boundary data are expressed in terms of the kinematic cross-ratios `u`, `v`. The final physical result should be written in terms of the complex variables `z`, `zz` (where `u = z*zz` and `v = (1-z)*(1-zz)`). The replacement is applied **after** assembly, **before** export:

```mathematica
assembled = assembled /. {u -> z*zz, v -> (1-z)*(1-zz)};
```

This substitution only affects the leading-singularity prefactor (the `result.m` transcendental content uses `I[z,...]` symbols, which do not contain `u` or `v`).

## Output

| File | Content |
|------|---------|
| `runs/<label>/<label>.txt` | Full assembled integral (in `z, zz` variables) as a string (`InputForm`), e.g. `LS_1(z,zz)*result_1 + LS_2(z,zz)*result_2` |

The `// InputForm // ToString` ensures the expression is written as a plain-text Mathematica-readable string (no `(* Created with Wolfram Language *)` header, no box formatting).

## Batch Scanning Code

The full scan-all-runs loop (matches the shipped [assemble_results.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/project_skills/result_assembly/assemble_results.wl)):

```mathematica
runsDir = FileNameJoin[{rootDir, "runs"}];
labels  = Last /@ FileNameSplit /@ Select[FileNames["*", runsDir], DirectoryQ];

Do[
  runDir     = FileNameJoin[{runsDir, label}];
  resultFile = FileNameJoin[{runDir, "result.m"}];
  outFile    = FileNameJoin[{runDir, label <> ".txt"}];

  (* Skip runs without result.m — not yet successfully calculated *)
  If[!FileExistsQ[resultFile],
    Print["SKIP ", label, ": result.m missing (not yet solved)"]; Continue[]
  ];

  (* Load leading singularity from input.wl *)
  Block[{integrand, integrandlist, coeff, leadingsingularity,
         leadingsingularitylist, ansatz, ansatzlist, OrderY},
    Get[FileNameJoin[{runDir, "input.wl"}]];
    lsExpr = If[ValueQ[leadingsingularitylist], leadingsingularitylist, leadingsingularity];
  ];

  resultList = Import[resultFile];

  If[ListQ[lsExpr],
    assembled = Sum[lsExpr[[k]] * resultList[[k]], {k, 1, Length[resultList]}],
    assembled = lsExpr * resultList[[1]]
  ];

  (* Replace cross-ratio variables u,v with z,zz before export *)
  assembled = assembled /. {u -> z*zz, v -> (1-z)*(1-zz)};

  (* Renew if <label>.txt already exists, otherwise create *)
  action = If[FileExistsQ[outFile], "renewed", "created"];
  Export[outFile, assembled // InputForm // ToString];
  Print["Assembled ", label, " -> ", label, ".txt (", action, ", ", Length[resultList], " LS)"];
, {label, labels}];
```

## Verification Checklist

- [ ] Runs without `result.m` are skipped (not assembled)
- [ ] Runs with `result.m` are assembled — existing `<label>.txt` is **renewed**, missing one is **created**
- [ ] `Length[resultList]` equals number of LS (1 for single-LS, 2+ for multi-LS)
- [ ] `ListQ[lsExpr]` matches multi-LS mode
- [ ] `<label>.txt` contains `I[z,...]` symbols multiplied by the LS prefactor (e.g. `(1/(z-zz))`, `(z*zz - (1-z)*(1-zz))/(z-zz)^2`)
- [ ] No stray `u` or `v` symbols remain in `<label>.txt` (all replaced by `z*zz` / `(1-z)*(1-zz)`)
- [ ] For single-LS runs, `<label>.txt = LS(z,zz) * result.m[[1]]`
- [ ] For multi-LS runs, `<label>.txt = LS_1(z,zz)*result.m[[1]] + LS_2(z,zz)*result.m[[2]] + ...`
