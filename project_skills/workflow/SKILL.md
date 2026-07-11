---
name: workflow
description: >
  Orchestrate the full bootstrap pipeline: parse input, run boundary conditions
  (Skill 2), series expansion (Skill 1), and coefficient solving (Skill 3), with
  pre/post-stage audit checks at every checkpoint. Knows how to invoke each skill
  in the correct order and manage multi-leading-singularity runs.
---

# Workflow Orchestration Skill

## Dependencies
- [input_parser.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/input_parser.wl) — Parses `input.wl` into a unified `<|Integrands, Coefficients, LeadingSingularities, WeightN, LoopPoints|>` Association.
- [config.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/config.wl) — Fixed paths, bases, permutations (`$Perms`, `$LiteRedBases`, `$DataDir`, etc.).
- [ConformalWeight.m](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/ConformalWeight.m) — Computes conformal weight `n` from integrand external points.
- [review_agent.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/review_agent.wl) — Facade for audit checks via `ReviewGate[rootDir, label, stage, config]`.
- [workflow_engine.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/workflow_engine.wl) — Main orchestrator exporting `SolveIntegrandSystem`.

## Input Format

Each run lives under `runs/<label>/` with an `input.wl` defining:
```mathematica
integrand = ...;          (* single integrand expression *)
leadingsingularity = ...; (* single leading singularity *)
ansatz = Import[...];     (* ansatz file *)
```

For multi-component / multi-LS runs, use:
```mathematica
integrandlist = {int1, int2};
coeff = {c1, c2};
lsConfigList = {{"simple", pref1, Flatten[ans1]}, {"double", pref2, Flatten[ans2]}};
```

And a `run.wl` bootstrap script:
```mathematica
$HistoryLength = 0;
runDir   = DirectoryName[$InputFileName];
rootDir  = ParentDirectory[ParentDirectory[runDir]];
SetDirectory[rootDir];
Get[FileNameJoin[{rootDir, "workflow_engine.wl"}]];
Get[FileNameJoin[{rootDir, "input_parser.wl"}]];
label = "<label>";
order = 4;  (* 3 for 3-loop, 4 for 4-loop *)
yOrder = 5; (* 4 for 3-loop, 5 for 4-loop *)
parsed = ParseInput[runDir];
If[parsed === $Failed, Print["Failed to parse input."]; Exit[1]];
SolveIntegrandSystem[rootDir, label, parsed, order, yOrder];
```

## Pipeline Stages

`SolveIntegrandSystem` in [workflow_engine.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/workflow_engine.wl) executes:

```
1. Log setup (run.log opened in runs/<label>/)
2. Pre-checks: Mathematica kernel, LiteRed2, FiniteFlow
3. Load all agents + review_agent
4. ReviewGate["preflight"]  — ConformalWeight.m, SVBasisFile existence
5. ReviewGate["preboundary"] — LiteRed2 bases, asym_new.wl, Gmaterrep files
6. Skill 2: Boundary Conditions (skip if files exist or cache hit)
   ReviewGate["boundary"]
7. For each Leading Singularity:
   a. Auto-detect MPL basis (scan data/allsvlistmpl_*.m for best ansatz coverage)
   b. Pre-filter SV/MPL bases to ansatz indices
   c. ReviewGate["preseries"]
   d. Skill 1: Series Expansion (skip if all 12 cache files exist)
      ReviewGate["series"]
8. ReviewGate["presolve"] — boundary + series files exist
9. Skill 3: Coefficient Solving
   ReviewGate["solve"]
10. Close log
```

## Auto-Detection

- **MPL basis**: Scans `data/allsvlistmpl_*.m`, counts ansatz `_I`/`_f` element coverage. The basis with best coverage is selected.
- **Conformal weight `n`**: Computed from `ConformalWeight[integrand, 1]` (external vertex 1, never loop vertices).
- **Loop points**: Auto-derived from max index in `x[i,j]` variables.
- **poleOrder**: Derived from `poleType`: `"simple"→1`, `"double"→2`.

## Review Gates

| Stage | Checker | When | Purpose |
|-------|---------|------|---------|
| `"preflight"` | `AuditPreflight` | Before any computation | Verify ConformalWeight.m, SVBasisFile exist |
| `"preboundary"` | `AuditPreBoundary` | Before Skill 2 | Verify LiteRed2 bases, asym_new.wl, Gmaterrep |
| `"boundary"` | `AuditBoundaryStage` | After Skill 2 | Check 6 boundary files exist and import as valid SeriesData with only u,Y |
| `"preseries"` | `AuditPreSeries` | Before Skill 1 | Verify SVHPL .txt parse OK; MPL basis/expanion files load correctly |
| `"series"` | `AuditSeriesStage` | After Skill 1 | Check 12 series expansion .m files exist and are valid lists |
| `"presolve"` | `AuditPreSolve` | Before Skill 3 | Verify all 6 boundary files + 12 series files exist |
| `"solve"` | `AuditSolveStage` | After Skill 3 | Check solution file exists, all coefficients uniquely solved |

## Run Output

After a successful run, the following files are produced:
- `runs/<label>/run.log` — Full console log from all stages
- `runs/<label>/result.m` — Final expanded ansatz × coefficients
- `runs/<label>/coeff_sol.m` — Partitioned coefficient values list
- `solve_agent/<label>_sol.m` — Raw solved substitution rules
- `series_agent/<label>_svlist*.m` (12 files) — Series expansion caches
- `asym/boundary_agent/<label>*_asyexp.m` (6 files) — Boundary condition outputs

## Mirror/Series Development (In Progress)

Mirror series expansion and mirror solve agents are under development in:
- `series_agent/series_agent_mirror.wl`
- `solve_agent/solve_agent_mirror.wl`

They are not yet integrated into the main workflow engine. The mirror workflow is tested via `test/mirror_full_run.wl`.

## Cache Cleanup for Fresh Runs

To restart from scratch for a given `<label>`:
```bash
rm asym/boundary_agent/<label>*_order*_asyexp.m
rm -rf asym/tmp/tensor_<label>*
rm series_agent/<label>_svlist*
rm solve_agent/<label>_sol.m
```

Never delete: `asym/tmp/targetIntegrals_reduced.m`, `asym/tmp/cache_tensor_record_noremove.mx`, external `IBPDir/`.
