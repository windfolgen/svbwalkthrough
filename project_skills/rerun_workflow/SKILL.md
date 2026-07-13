---
name: rerun_workflow
description: >
  Cache invalidation rules for rerunning the bootstrap workflow. Determines which
  cache files to remove based on what changed (integrand, leading singularity,
  ansatz) so the workflow recomputes only the affected stages. Covers 4 scenarios:
  integrand-only change, LS/ansatz-only change, both change, and fresh run.
---

# Rerun Workflow: Cache Invalidation Rules (Skill 5)

## Purpose

The bootstrap workflow caches intermediate results across 3 stages (Boundary, Series, Solving). When rerunning a `<label>` after editing `input.wl`, you must remove the **right** cache files so the workflow recomputes only the affected stages — otherwise it will silently reuse stale data.

This skill documents the 4 rerun scenarios, the exact file patterns to remove in each, and the run command.

## Cache File Inventory

| Stage | Directory | Pattern | Count | Purpose |
|-------|-----------|---------|-------|---------|
| **1. Boundary** | `asym/boundary_agent/` | `<label><perm>_order<order>_asyexp.m` | 6 | Asymptotic expansion per permutation |
| **1. Boundary** | `asym/tmp/` | `tensor_<label><perm>_order<order>_results.m` | 6 | Tensor reduction (IBP) cache |
| **1. Boundary** | `asym/boundary_agent/` | `calculated_integrands.m` | 1 | Association: integrand → label (shared across runs) |
| **2. Series** | `series_agent/` | `<label>_svlist<suffix>.m` | 6 | SVHPL series per limit |
| **2. Series** | `series_agent/` | `<label>_svlistmpl<suffix>.m` | 6 | MPL series per limit |
| **3. Solve** | `solve_agent/` | `<label>_sol.m`, `<label>_partialsys.m`, `<label>_freevars.m` | 3 | Solved coefficients + system |
| **3. Solve** | `runs/<label>/` | `result.m`, `coeff_sol.m` | 2 | Final per-LS results |
| **4. Assembly** | `runs/<label>/` | `<label>.txt` | 1 | Final assembled integral |

Where:
- `<perm>` ∈ `{1234, 2134, 1324, 2314, 3124, 3214}` (6 permutations, matching `$Perms`)
- `<suffix>` ∈ `{e0uv, e0uvp, einfuv, einfuvp, e1uv, e1uvp}` (6 limits)
- `<order>` is the Y-expansion order (e.g. `4`)

## Why Each Cache Belongs to Its Stage

| Cache | Depends on | Invalidated when |
|-------|------------|------------------|
| `*_asyexp.m` (boundary) | **integrand** | integrand changes |
| `tensor_*_results.m` | **integrand** | integrand changes |
| `calculated_integrands.m` | **integrand** (key) | integrand changes (remove the key) |
| `<label>_svlist*.m` | **ansatz + leading singularity** | ansatz or LS changes |
| `<label>_svlistmpl*.m` | **ansatz + leading singularity** | ansatz or LS changes |
| `<label>_sol.m`, `result.m`, etc. | **all** (integrand + ansatz + LS) | anything changes |

## The 4 Rerun Scenarios

### Scenario 1: Integrand changes, ansatz/LS unchanged

**When**: You edited `input.wl`'s `integrand` (or `integrandlist`) field, but `leadingsingularity` and the ansatz file (`<label>_ans.m` or `fourloopI41ansatz.m`) are the same.

**Action**: Remove **boundary** caches only. Keep series caches (they depend on ansatz, not integrand).

**Files to remove** (replace `<label>`, `<order>` accordingly):

```
asym/boundary_agent/<label>1234_order<order>_asyexp.m
asym/boundary_agent/<label>2134_order<order>_asyexp.m
asym/boundary_agent/<label>1324_order<order>_asyexp.m
asym/boundary_agent/<label>2314_order<order>_asyexp.m
asym/boundary_agent/<label>3124_order<order>_asyexp.m
asym/boundary_agent/<label>3214_order<order>_asyexp.m
asym/tmp/tensor_<label>1234_order<order>_results.m
asym/tmp/tensor_<label>2134_order<order>_results.m
asym/tmp/tensor_<label>1324_order<order>_results.m
asym/tmp/tensor_<label>2314_order<order>_results.m
asym/tmp/tensor_<label>3124_order<order>_results.m
asym/tmp/tensor_<label>3214_order<order>_results.m
```

**Do NOT remove**:
- `series_agent/<label>_svlist*.m` (12 files) — ansatz unchanged, series valid
- `asym/tmp/targetIntegrals_reduced.m` — general reduction cache, reusable
- `asym/boundary_agent/calculated_integrands.m` — the OLD integrand key will simply not match the new integrand; `CheckIntegrandCache` returns `False` and recomputes. The stale key is harmless (it points to this label's old boundary files, which you just deleted).

**Shell glob** (run from project root):
```bash
rm -f asym/boundary_agent/<label>*_asyexp.m
rm -f asym/tmp/tensor_<label>*_results.m
```

**Example** (`fourloopI117`, order 4):
```bash
rm -f asym/boundary_agent/fourloopI117*_asyexp.m
rm -f asym/tmp/tensor_fourloopI117*_results.m
```

---

### Scenario 2: Leading singularity or ansatz changes, integrand unchanged

**When**: You edited `leadingsingularity` (or `leadingsingularitylist`) or swapped the ansatz file in `input.wl`, but `integrand` is the same.

**Action**: Remove **series + solve** caches. Keep boundary caches (they depend only on integrand).

**Files to remove**:

```
series_agent/<label>_svliste0uv.m
series_agent/<label>_svlistmple0uv.m
series_agent/<label>_svliste0uvp.m
series_agent/<label>_svlistmple0uvp.m
series_agent/<label>_svlisteinfuv.m
series_agent/<label>_svlistmpleinfuv.m
series_agent/<label>_svlisteinfuvp.m
series_agent/<label>_svlistmpleinfuvp.m
series_agent/<label>_svliste1uv.m
series_agent/<label>_svlistmple1uv.m
series_agent/<label>_svliste1uvp.m
series_agent/<label>_svlistmple1uvp.m
solve_agent/<label>_sol.m
solve_agent/<label>_partialsys.m
solve_agent/<label>_freevars.m
runs/<label>/result.m
runs/<label>/coeff_sol.m
runs/<label>/<label>.txt
```

**Do NOT remove**:
- `asym/boundary_agent/<label>*_asyexp.m` (6 files) — integrand unchanged, boundary valid
- `asym/tmp/tensor_<label>*_results.m` (6 files) — same reason
- `asym/boundary_agent/calculated_integrands.m` — still valid

**Shell glob** (run from project root):
```bash
rm -f series_agent/<label>_svlist*.m
rm -f solve_agent/<label>_sol.m solve_agent/<label>_partialsys.m solve_agent/<label>_freevars.m
rm -f runs/<label>/result.m runs/<label>/coeff_sol.m runs/<label>/<label>.txt
```

---

### Scenario 3: Both integrand AND (leading singularity or ansatz) change

**When**: You edited `integrand` AND also changed `leadingsingularity` or the ansatz file.

**Action**: Remove **all** caches for this label (boundary + series + solve).

**Files to remove**: Union of Scenario 1 and Scenario 2 — i.e. all files listed in both sections above.

**Shell glob** (run from project root):
```bash
rm -f asym/boundary_agent/<label>*_asyexp.m
rm -f asym/tmp/tensor_<label>*_results.m
rm -f series_agent/<label>_svlist*.m
rm -f solve_agent/<label>_sol.m solve_agent/<label>_partialsys.m solve_agent/<label>_freevars.m
rm -f runs/<label>/result.m runs/<label>/coeff_sol.m runs/<label>/<label>.txt
```

**Do NOT remove**:
- `asym/tmp/targetIntegrals_reduced.m` — general cache, not label-specific
- `asym/boundary_agent/calculated_integrands.m` — stale key is harmless (see Scenario 1 note)

---

### Scenario 4: Fresh run (user explicitly requests)

**When**: User says "fresh run", "clean run", "recompute everything from scratch", or you want to guarantee no stale data is reused.

**Action**: Remove **all** caches for this label — same as Scenario 3.

**Files to remove**: Same as Scenario 3.

**Shell glob** (run from project root):
```bash
rm -f asym/boundary_agent/<label>*_asyexp.m
rm -f asym/tmp/tensor_<label>*_results.m
rm -f series_agent/<label>_svlist*.m
rm -f solve_agent/<label>_sol.m solve_agent/<label>_partialsys.m solve_agent/<label>_freevars.m
rm -f runs/<label>/result.m runs/<label>/coeff_sol.m runs/<label>/<label>.txt
```

Optionally, also remove `run.log` for a clean log:
```bash
rm -f runs/<label>/run.log
```

## How to Decide Which Scenario Applies

When the user says "rerun `<label>`", ask (or check `input.wl` + git diff):

1. **Did `integrand` (or `integrandlist`) change?** → boundary caches must go
2. **Did `leadingsingularity` (or `leadingsingularitylist`) change?** → series + solve caches must go
3. **Did the ansatz file (referenced in `run.wl` or `input.wl`) change?** → series + solve caches must go

Map to scenario:
- (1) only → Scenario 1
- (2) or (3) only → Scenario 2
- (1) + (2 or 3) → Scenario 3
- User says "fresh" → Scenario 4

## Run Command

After removing the appropriate caches, rerun the workflow:

```bash
MathKernel -noprompt -script runs/<label>/run.wl 2>&1 | tee runs/<label>/run.log
```

The workflow engine will:
- Recompute **only** the stages whose caches were removed
- Skip stages whose caches are still valid (prints `"already exist. Skipping expansion!"` etc.)
- Reassemble `result.m` + `coeff_sol.m` at the end of Stage 3

After the workflow completes, **re-run the assembly script** to refresh `<label>.txt`:

```bash
MathKernel -noprompt -script project_skills/result_assembly/assemble_results.wl
```

This renews `<label>.txt` (and any other runs whose `result.m` is newer than their `.txt`).

## Important Notes

1. **`calculated_integrands.m` is shared**: it maps integrands → labels across ALL runs. When an integrand changes, the old key becomes stale but is harmless — `CheckIntegrandCache` won't match the new integrand. Do NOT delete this file unless you want to force-boundary-recompute for every run.

2. **`asym/tmp/targetIntegrals_reduced.m` is general**: it's not label-specific. Do NOT remove it unless the user explicitly asks.

3. **Solve outputs are cheap to regenerate**: always remove `solve_agent/<label>_*.m` and `runs/<label>/{result,coeff_sol}.m` when rerunning — the solve stage is fast (<10s) and you want fresh results.

4. **Boundary stage is the slow one**: ~4 min for 4-loop. Only recompute when the integrand actually changed (Scenario 1, 3, 4).

5. **Series stage skip check**: `series_agent.wl` checks if all 12 `<label>_svlist*.m` files exist. If you remove only some, it will still skip. Remove all 12 or none.

## Verification After Rerun

1. Check `run.log` for `[ReviewGate]` lines — all should say `PASS`:
   ```
   [ReviewGate] "boundary" stage: "PASS" (PASS:6 WARN:0 FAIL:0)
   [ReviewGate] "series"  stage: "PASS" (PASS:12 WARN:0 FAIL:0)
   [ReviewGate] "solve"   stage: "PASS" (PASS:2 WARN:0 FAIL:0)
   ```

2. Check `[Time Record]` lines to confirm which stages actually ran:
   ```
   [Time Record] Stage 1 (Boundary Conditions) took: 233.9 seconds   <- ran
   [Time Record] Stage 2 (Series Expansion) took: 2.8 seconds         <- skipped (cached)
   [Time Record] Stage 3 (Solving System) took: 7.9 seconds           <- ran
   ```

3. Confirm `runs/<label>/result.m` was updated (modification time newer than `run.log` start).

4. Re-run assembly and confirm `<label>.txt` was renewed:
   ```
   Assembled "<label>" -> <label>.txt ("renewed", ...)
   ```
