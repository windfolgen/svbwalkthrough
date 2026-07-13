---
name: mirror_solve_direct
description: >
  Mirror stage coefficient solving via direct ansatz expansion. Loads
  pre-expanded 304-element ansatz files (LS factor baked in), multiplies
  addInZZ, truncates per-ptr, applies mirrored zrep, series-expands, and
  solves the combined partial+mirror system. Validated on fourloopI173
  (2 leading singularities, all 6 limits, fully solved with 0 free
  variables and 0 benchmark violations).
---

# Mirror Solve Direct (Skill 3b — Active)

## Status: ACTIVE — Validated on `fourloopI173`

This is the **only** mirror-stage skill that has produced a fully solved, benchmark-consistent result. It is validated on `fourloopI173` (2 leading singularities, 304-element ansatz, all 6 limits).

| Metric | Value |
|--------|-------|
| Validated run | `fourloopI173` |
| Limits solved | 6 (all) |
| Mirror equations | 1658 |
| Full system equations | 1987 (329 partial + 1658 mirror) |
| Variables solved | 304/304 |
| Free variables | 0 |
| Benchmark violations | 0 (all 6 limits + partialsys) |

See [test/mirror_check_walkthrough.md](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/test/mirror_check_walkthrough.md) for the full validation history (Tests 1–10), culminating in the truncation-variable fix that made all 6 limits consistent.

## Other Mirror Files — NOT ACTIVE / Under Development

The following mirror files exist in the repo but are **under development** and have NOT been validated to produce consistent, fully solved results. Do not use them for production runs:

| File | Status | Notes |
|------|--------|-------|
| [series_agent/series_agent_mirror.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/series_agent/series_agent_mirror.wl) | Under development | Mirrored series agent; zrep sign fixes applied but not independently validated end-to-end |
| [solve_agent/solve_agent_mirror.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/solve_agent/solve_agent_mirror.wl) | Under development | Earlier mirror solve agent; superseded by `solve_agent_mirror_direct.wl` |
| [transform/transform_mirror.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/transform/transform_mirror.wl) | Under development | Mirror transform pipeline |
| [transform/generate_sv_mirror.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/transform/generate_sv_mirror.wl) | Under development | SV generation for mirror kinematics |
| [transform/threeloop_generate_mpl_mirror.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/transform/threeloop_generate_mpl_mirror.wl) | Under development | 3-loop MPL generation for mirror |
| [transform/fourloop_generate_all_zrep_mirror.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/transform/fourloop_generate_all_zrep_mirror.wl) | Under development | 4-loop zrep generation for mirror |

Only [solve_agent/solve_agent_mirror_direct.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/solve_agent/solve_agent_mirror_direct.wl) is the validated, active implementation.

## Purpose

The standard coefficient solving ([Skill 3](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/project_skills/coefficient_solving/SKILL.md)) uses the 6 OPE limits in standard kinematics. When free parameters remain (`free > 0`), the **mirror stage** adds equations from the **opposite Riemann sheet** (mirrored `z`/`zz` square-root signs) to fully determine the coefficients.

The mirror stage is **conditional**: it only runs when the standard solve leaves free parameters AND `$MirrorInputFiles` is set. It does NOT replace the standard solve — it extends it.

## Agent File

[solve_agent/solve_agent_mirror_direct.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/solve_agent/solve_agent_mirror_direct.wl)

## Entry Point

```mathematica
RunCoefficientSolvingMirror[rootDir, label, config, ansatzList, labelsList,
                             basisSVList, basisMPLList, targetData, order]
```

Same signature as the standard `RunCoefficientSolving`, plus these global flags (set before calling):

| Flag | Purpose | Validated value |
|------|---------|-----------------|
| `$MirrorLimits` | List of limit indices to process (subset of `{1,2,3,4,5,6}`) | `{1,6,2,3,4,5}` (all 6) |
| `$MirrorInputFiles` | Association: limit type → list of `nLS` input file paths | see below |
| `$MirrorMultiplyLSFactor` | Whether to multiply `(-2+z+zz)` LS factor | `False` (LS factor already baked into input files) |
| `$MirrorNegateLS1` | Negate LS1 input elements (experimental) | `False` (does not fix inconsistency — see Test 5) |

## Input

### 1. Pre-expanded ansatz files (`$MirrorInputFiles`)

Each limit type (`e0`, `e1`, `einf`) requires `nLS` text files, each containing a **304-element list** of pre-expanded ansatz series in `z`/`zz` (LS factor already multiplied in):

```mathematica
$MirrorInputFiles = <|
  "e0"   -> {FileNameJoin[{dataDir, "svansatzw8_e0_1.txt"}],
             FileNameJoin[{dataDir, "svansatzw8_e0_2.txt"}]},
  "e1"   -> {FileNameJoin[{dataDir, "svansatzw8_e1_1.txt"}],
             FileNameJoin[{dataDir, "svansatzw8_e1_2.txt"}]},
  "einf" -> {FileNameJoin[{dataDir, "svansatzw8_einf_1.txt"}],
             FileNameJoin[{dataDir, "svansatzw8_einf_2.txt"}]}
|>;
```

- File `k` provides elements `[offsetK+1 .. offsetK+lenK]` for leading singularity `k`.
- `c[1..135]` → LS1 (oddAnsatz), `c[136..304]` → LS2 (evenAnsatz) — combined via `Join`, not addition.
- The `p` variants (`e0p`, `e1p`, `einfp`) reuse the non-`p` files — the `uv`/`uvp` distinction comes from `zrep` and `Series` assumptions, not the file.

**Validation**: `Length[filePaths]` must equal `nLS`, otherwise the limit is skipped with an error.

### 2. Partial system from standard solve

`solve_agent/<label>_partialsys.m` — the equation system from the standard solve (Skill 3). The mirror equations are merged with this via `Join[partialSys, mirrorSys]`.

## Pipeline (per limit)

For each limit `i` in `$MirrorLimits`:

### Step 1: Determine limit configuration

```mathematica
Switch[i,
  1, {ext = "e0";  ptr = 0; suffix = "e0uv";    part2Factor = 1},
  2, {ext = "e0p"; ptr = 0; suffix = "e0uvp";   part2Factor = 1/v},
  3, {ext = "einf"; ptr = 2; suffix = "einfuv"; part2Factor = 1/u},
  4, {ext = "einfp"; ptr = 2; suffix = "einfuvp"; part2Factor = 1/u},
  5, {ext = "e1";  ptr = 1; suffix = "e1uv";    part2Factor = 1/v},
  6, {ext = "e1p"; ptr = 1; suffix = "e1uvp";   part2Factor = 1}
];
```

### Step 2: Load and combine input files

Load `nLS` files, slice each to its LS range, and `Join` (not add):

```mathematica
ansatzKSeries = Join[
  data1[[1 ;; len1]],          (* LS1: c[1..135] *)
  data2[[len1+1 ;; len1+len2]] (* LS2: c[136..304] *)
];
```

### Step 3: Multiply `addInZZ` (LS factor in z/zz)

```mathematica
addInZZList[[k]] = lsConfig[[k, 2]] /. {u -> z*zz, v -> (1-z)*(1-zz)} // Simplify;
```

If `$MirrorMultiplyLSFactor = False` (validated setting), `addInZZList` is set to all 1s — the LS factor is already in the input files.

### Step 4: Pre-Series symbol replacement

Before truncation, replace z-dependent special symbols to prevent `I[0,0,0]` leakage:

| ptr | Odd (Y>0) | Even (Y<0) |
|-----|-----------|------------|
| 0 | `I[z,0,0] -> Log[u]` | `I[z,0,0] -> Log[u/v]` |
| 1 | `I[z,1,0] -> Log[u/v]` | `I[z,1,0] -> Log[u]` |
| 2 | `I[z,0,0] -> Log[u]`, `P[0] -> -Log[u]` | `I[z,0,0] -> Log[u/v]`, `P[0] -> -Log[u/v]` |

Also: `f[a_] :> Zeta[a]`, `f[3,3] -> Zeta[3]^2/2`, `f[3,5] -> Zeta[3]Zeta[5] - f[5,3]`.

### Step 5: Truncate (THE CRITICAL FIX — Test 9)

**Per-ptr truncation variable** — this was the root cause of all inconsistency before the fix:

```mathematica
Switch[ptr,
  0, expr = Normal[Series[expr, {z, 0, 5}, {zz, 0, 5}]],
  1, expr = expr /. {-1 + z -> z1, -1 + zz -> zz1};
     expr = Normal[Series[expr, {z1, 0, 5}, {zz1, 0, 5}]],
  2, expr = Normal[Series[expr, {z, Infinity, 5}, {zz, Infinity, 5}]]
];
```

- **ptr=0** (e0/e0p): expand around `z=0`, `zz=0`
- **ptr=1** (e1/e1p): shift to `z1=z-1`, `zz1=zz-1`, then expand around `z1=0`, `zz1=0`
- **ptr=2** (einf/einfp): expand around `z=Infinity`, `zz=Infinity`

The `-1+z -> z1` substitution MUST happen before truncation, not after — truncating in `z`/`zz` for e1/e1p limits produces equations that conflict with the benchmark (Test 4: 40 violations; Test 9: 0 violations after fix).

### Step 6: Apply mirrored zrep

Six mirrored zrep tables (`zrep0`, `zrep0P`, `zrep1`, `zrep1P`, `zrepInf`, `zrepInfP`) — square-root signs **swapped** relative to standard `series_agent.wl`:

| zrep | z sign | zz sign | Used by |
|------|--------|---------|---------|
| zrep0 | `-Sqrt` | `+Sqrt` | limit 1 (e0uv) |
| zrep0P | `-Sqrt` | `+Sqrt` | limit 2 (e0uvp) |
| zrep1 | z/z1=`-Sqrt` | zz/zz1=`+Sqrt` | limit 5 (e1uv) |
| zrep1P | z/z1=`-Sqrt` | zz/zz1=`+Sqrt` | limit 6 (e1uvp) |
| zrepInf | `+Sqrt` | `-Sqrt` | limit 3 (einfuv) |
| zrepInfP | `+Sqrt` | `-Sqrt` | limit 4 (einfuvp) |

Plus inline `z`/`zz`/`z1`/`zz1` replacements (mirrored signs) for bare symbols not caught by the `Power[_, i]` table.

### Step 7: Multiply part2Factor and Series expand

```mathematica
expr = expr * part2Factor /. {v -> 1 - Y};
expr = expr /. {Log[u] -> logU};
expr = Normal[Series[expr, {u, 0, 0}, {Y, 0, order},
  Assumptions -> {If[OddQ[i], Y > 0, Y < 0]}]];
(expr /. {logU -> Log[u]}) // Expand
```

Y assumption: `Y > 0` for odd limits (1,3,5), `Y < 0` for even limits (2,4,6).

### Step 8: Extract equations

Same `MonomialList` extraction as standard Skill 3:
1. `temp = MonomialList[Normal[setup - targetData[[i]]] /. f -> Zeta, {Log[u]}]`
2. If `temp === {}`, no new constraints — skip this limit.
3. `temp1`: replace `Log[u]→1`, negative powers → `invY`/`invu`, `MonomialList` in `{u,Y,invY,invu}`, restore to 1.
4. `sys1`: replace `Zeta[n]→zn`, `MonomialList` in `{z3,z5,z7,f[5,3],pi}`, `Thread@Equal[...,0]`, flatten, dedupe, delete `True|False|0`.

Per-limit equations saved to `test/<label>_mirrorSys_limit<i>.m`.

## Post-loop: Audit, Merge, Solve

### AuditSystem

After all limits processed, audit the mirror system:

```mathematica
AuditSystem[mirrorSys, "Mirror system (before merge)"]
```

Verifies every equation is linear in `c[_Integer]` with rational coefficients. **If audit FAILS (e.g. `I[0,0,0]` leaked in), abort immediately and return `$Failed`** — do not attempt to solve.

### Merge and solve

```mathematica
fullSys = Join[partialSys, mirrorSys];
solt = Solve[fullSys, varsList];
```

- Baseline: solve `partialSys` alone (3-minute timeout) → `partialSolved`
- Full: solve `fullSys` (3-minute timeout) → `fullSolved`
- If `solt === {}`: full system inconsistent — return `$Failed`
- If `solt === $Aborted`: timeout — return `$Failed`

### Output (only if `freeCount === 0`)

```mathematica
Export[FileNameJoin[{rootDir, "runs", label, "result.m"}], finalResultList];
Export[FileNameJoin[{rootDir, "runs", label, "coeff_sol.m"}], coeffListAll];
```

If `freeCount > 0`, no export — the system is not fully solved.

## Hard Constraints (from project memory)

- **`$MirrorMultiplyLSFactor`**: must be `False` for the validated workflow (LS factor baked into input files).
- **`$MirrorInputFiles`**: must be set; each limit type's file list length must equal `nLS`.
- **Per-ptr truncation**: ptr=0 uses `{z,0,5},{zz,0,5}`; ptr=1 uses `{z1,0,5},{zz1,0,5}` after shift; ptr=2 uses `{z,Infinity,5},{zz,Infinity,5}`.
- **`I[0,0,0]` abort**: if `I[0,0,0]` appears in any equation, immediately stop and return `$Failed`.
- **No partial substitution during generation**: generate the full mirror system first, then merge with `_partialsys.m` and check consistency.
- **Input file combination**: `Join[file1[[1;;135]], file2[[136;;304]]]` — not direct addition.
- **Verification loop removed**: the linear `Solve` already guarantees consistency; do not re-run `ParallelTable` for verification (doubles runtime).

## Lessons Learned

- **Wrong truncation variable** (Test 4→9): truncating e1/e1p limits in `z`/`zz` instead of `z1`/`zz1` was the root cause of all benchmark violations. Fix: per-ptr Switch.
- **`add=1` efficiency**: use `//Expand` then `*add`; for `add=v⁻¹`, skip `Expand` and directly `*add` + `Series`.
- **`Series[{z,0,7},{zz,0,7}]` breaks `I[z,0,0]`**: it expands to `I[0,0,0]`. Replace `I[z,0,0]` with `Log[u]` BEFORE `Series`.
- **zrep table range 10 vs 16**: no effect on output (Test 8) — the `zz1 -> u/z1` substitution reduces all powers before the table lookup.
- **`$MirrorNegateLS1` does not fix inconsistency** (Test 5): negating LS1 input produces the same 40 violations.
- **Inline z/zz replacements are redundant** (Test 6): `Power[z,1]` table rule already catches bare `z`/`zz`.

## Verification Checklist

- [ ] `AuditSystem` passes for mirror system (all equations linear in `c[_]`, rational coefficients)
- [ ] `AuditSystem` passes for full system (partial + mirror)
- [ ] `partialSolved < fullSolved` (mirror equations add new constraints)
- [ ] `solt =!= {}` (full system consistent)
- [ ] `solt =!= $Aborted` (no timeout)
- [ ] `freeCount === 0` (fully solved)
- [ ] Per-limit equations saved to `test/<label>_mirrorSys_limit<i>.m`
- [ ] `result.m` and `coeff_sol.m` exported to `runs/<label>/`
- [ ] (Optional) Benchmark check: 0 violations per limit against known-correct solution
