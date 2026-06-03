# Summary of SVB Walkthrough Calculation Procedures

## Overview
This Mathematica notebook implements a **bootstrap method for computing multi-loop Feynman integrals** via leading singularities. The final pipeline correctly reconstructs all equations using identical methodology across SVHPL and MPL bounds, entirely removing redundant runtime costs.

- **Basis File Renaming & Cleanup:** The intermediate and long-named basis files were cleaned up. The final pre-computed, coordinate-transformed limit files loaded natively by `series_agent.wl` were renamed to shortened versions:
  - SVHPL limits: `allsvliste0_uptow8_inuv_e0uv.m` $\to$ `allsvliste0_uptow8_inuv.m`, `allsvliste0_uptow8_inuv_e0uvp.m` $\to$ `allsvliste0_uptow8_inuvp.m` (and similarly for `e1` and `einf` limits).
  - MPL limits: `allsvlistmpl_threeloope0_inuv_e0uv.txt` $\to$ `allsvlistmpl_threeloope0_inuv.txt`, `allsvlistmpl_threeloope0_inuvp.txt` $\to$ `allsvlistmpl_threeloope0_inuvp.txt` (and similarly for `e1` and `einf` limits).
  - The `series_agent.wl` file loading paths (`svFile` and `mplFile`) were systematically updated to consume these shorter naming conventions.

The core workflow is: (1) compute leading singularities of an integrand, (2) construct an ansatz from a basis of transcendental functions, (3) fix the ansatz coefficients by matching to the leading singularities.

**Input to the workflow**: the integrand, the leading singularities, and the integral ansatz for each leading singularity.
**Output of the workflow**: the coefficients before the ansatz.

---

## 0. Skill 0: Master Orchestrator

### 0.1 Directory Structure
Each skill operates in its own working directory. Output files are written to the skill's directory so that they are automatically discoverable by downstream skills.

```
.                           (project root)
├── master_agent.wl          — Skill 0: orchestrator
├── input_parser.wl          — Input config parser
├── config.wl                — Global configuration
├── data/                    — Pre-expanded series bases (.txt and .m)
├── review_agent.wl          — Review facade (gateway to audit)
├── ConformalWeight.m        — conformal weight calculator (shared)
├── .aetherignore            — exclude large intermediate files from AI indexing
├── series_agent/
│   └── series_agent.wl      — Skill 1: ansatz series expansion
├── asym/
│   ├── asym_new.wl          — asymptotic expansion engine (shared)
│   ├── Bases/               — LiteRed2 IBP bases
│   ├── tmp/                 — cached tensor reduction / IBP results (reusable)
│   └── boundary_agent/
│       └── boundary_agent.wl — Skill 2: boundary condition calculation
├── solve_agent/
│   └── solve_agent.wl        — Skill 3: coefficient solving
├── audit_agent/
│   ├── audit_agent.wl        — Skill 4: pre-flight and post-stage audit checks
│   └── reports/              — audit report output (.m + .md)
└── project_skills/
    └── ansatz_basis/          — Documentation for ansatz construction
        ├── SKILL.md
        └── references/
            ├── benchmark_files.md
            ├── construction_workflow.md
            └── parity_rules.md
```

### 0.2 Orchestrator (`master_agent.wl`)
`SolveIntegrandSystem[rootDir, label, config, order_:3, yOrder_:4, opts]`

Uses the `parsed` dictionary from `input_parser.wl` which supports multiple leading singularities.

- `poleOrder` is automatically derived from `poleType`: `"simple" → 1`, `"double" → 2`

Globals are no longer manually set. The pipeline reads `runs/<label>/input.wl` which defines `$Integrand`, `$Coeff`, and `$LeadingSingularities` (a list of `{poleType, prefactor, ansatzFile}`).

**Options:**
- `"Audit" -> True` (default) — run `ReviewGate` after each stage
- `"AuditReportDir" -> path` — where to write audit reports
- `"StopOnAuditFailure" -> False` — halt pipeline on FAIL

1. Loads `ConformalWeight.m` → computes `weightN` from `$Integrand`.
2. Runs **pre-flight check** (`ReviewGate[rootDir, label, "preflight"]`) — verifies all required source files exist.
3. Runs **pre-boundary check** (`ReviewGate[rootDir, label, "preboundary"]`) — verifies LiteRed2 bases, asym engine, Gmaterrep files.
4. Calls **Skill 2** → **Skill 1** → **Skill 3** in sequence, with pre-checks before each:
   - Before Skill 1: **pre-series check** (`"preseries"`) — verifies SVHPL .txt and MPL .m/.txt file format and parseability.
   - Before Skill 3: **pre-solve check** (`"presolve"`) — verifies boundary files and series expansion files exist.
5. After each skill, runs a **post-stage audit** (`ReviewGate[rootDir, label, "boundary"|"series"|"solve"]`).
6. Records `DateObject[]` timings for each stage.

### 0.3 File Dependencies and Loading
All three skills share a single `label` (one integrand, one leading singularity). Each agent accesses files relative to `$RootDir`:

| Agent | Reads from | Writes to |
|-------|-----------|-----------|
| `series_agent.wl` | `data/allsvliste*_uptow8.txt`, `data/allsvlistmpl_*e*.{m,txt}` (auto-detected via `mplBasisFile`), `root/ConformalWeight.m` | `root/series_agent/<label>_svlist*.m` (SVHPL), `root/series_agent/<label>_svlistmpl*.m` (MPL) |
| `boundary_agent.wl` | `root/asym/asym_new.wl`, `root/asym/Bases/`, `root/asym/tmp/` (reused across runs), optionally `root/runs/<label>/boundaries/` (via `"InputDir"`) | `root/asym/boundary_agent/<label>*_asyexp.m`; LiteRed2 IBP .mx caches to `"IBPDir"` (external) |
| `solve_agent.wl` | `root/series_agent/<label>_svlist*.m`, `root/asym/boundary_agent/<label>*_asyexp.m`, ansatz and basis `.m` files | `root/solve_agent/<label>_sol.m` |
| `review_agent.wl` | `root/audit_agent/audit_agent.wl` (when loaded) | `root/audit_agent/reports/` (when writing) |

### 0.4 Review Gate (`review_agent.wl`)
Thin facade providing `LoadReviewAgent[rootDir]` and `ReviewGate[rootDir, label, stage]`. When the full audit agent is loaded, `ReviewGate` delegates to `RunReviewGate`. If the audit agent cannot be loaded, the gate returns `"PASS"` (no-op) to avoid blocking the pipeline.

**Stages recognized** by `RunReviewGate`:

| Stage | Checker | When | Purpose |
|-------|---------|------|---------|
| `"preflight"` | `AuditPreflight` | Before any computation | Verify required source files (ConformalWeight.m, SVHPL .txt, MPL .txt) exist |
| `"preboundary"` | `AuditPreBoundary` | Before Skill 2 | Verify LiteRed2 bases, asym_new.wl, Gmaterrep files, tmp dir |
| `"boundary"` | `AuditBoundaryStage` | After Skill 2 | Check 6 boundary .m files exist and import correctly |
| `"preseries"` | `AuditPreSeries` | Before Skill 1 | Verify SVHPL .txt parse correctly; verify MPL expansion files (.m or .txt) load as valid lists; record format convention detected |
| `"series"` | `AuditSeriesStage` | After Skill 1 | Check 12 series expansion .m files exist and are valid lists |
| `"presolve"` | `AuditPreSolve` | Before Skill 3 | Verify boundary files and series expansion files all exist |
| `"solve"` | `AuditSolveStage` | After Skill 3 | Check solution file exists and contains valid rules |
| `"pipeline"` | `AuditPipeline` | End of run | Combined report of all stages |

**Abort behavior:** On any FAIL, the pipeline prints `[ABORT] <stage> FAIL` with details and returns `$Failed`.

### 0.5 Runtime Safety
**Missing files:** if any required file is not found at runtime, immediately stop all calculations, kill all stale Mathematica processes (`pkill -9 -f -i "Math\|Wolfram\|mathkernel"`), verify with `ps aux | grep -i wolfram | grep -v grep | wc -l` that the count is 0, and notify the user. Do not create or guess missing files — ask the user to provide them.

**Large intermediate data:** IBP reduction tables from LiteRed2 should be directed to an external directory (`"IBPDir"` option) to keep the workspace lean. IBP caches in `asym/tmp/` and the external `"IBPDir"` are reusable across runs — do not delete `targetIntegrals_reduced.m`.

---

## 1. Skill 1: Ansatz Series Expansion

### 1.1 Input
Each expansion file contains the series expansion of a corresponding basis `.m` file:

| Basis file (list of elements) | Expansion files (series at singular points) |
|------|------|
| `allsvlist_fourloop.m` (SVHPL basis) | `allsvliste0_uptow8.txt` (z→0), `allsvliste1_uptow8.txt` (z→1), `allsvlisteinf_uptow8.txt` (z→∞) |
| `allsvlistmpl_*.m` (MPL basis, auto-detected) | `allsvlistmpl_*e0.{m,txt}` (z→0), `allsvlistmpl_*e1.{m,txt}` (z→1), `allsvlistmpl_*einf.{m,txt}` (z→∞) |

**MPL expansion file format convention:** Two formats are supported, detected at load time:

| Extension | Format | Loading method | Example |
|-----------|--------|---------------|---------|
| `.m` | Mathematica expression list — no parsing needed | `Import[path]` → directly usable as list | `{I[z,0,1,0] + ..., ...}` |
| `.txt` | String-wrapped list — needs parsing | `Import[path, "String"]` → `StringTrim` → `ToExpression` → list | `"[I[z,0,1,0] + ..., ...]"` |

The loader (`series_agent.wl`) tries `.txt` first, falls back to `.m`. The pre-series audit (`AuditPreSeries`) records which format was detected and verifies each file loads correctly.

SVHPL expansion files are always `.txt` format (string-wrapped lists).

**Reuse:** If the leading singularity (and thus the `additional` prefactor) is unchanged from a previous run, the series expansions do not need to be recomputed — load the existing `.m` files from `series_agent/`.

### 1.2 SeriesExpansion Functions
All 12 `SeriesExpansion*` functions and 6 `zrep` definitions are **hard-coded** in `series_agent/series_agent.wl` — no notebook dependency. Each function takes an `additional` prefactor option and internally divides by the Jacobian / measure factor.

**Functions and their internal denominators:**
- `SeriesExpansion0` / `SeriesExpansion0P`: divide by `-(z-zz)` (simple pole at z=0)
- `SeriesExpansion1` / `SeriesExpansion1P`: divide by `-(z-zz)` (simple pole at z=1)
- `SeriesExpansionInf` / `SeriesExpansionInfP`: divide by `-(z-zz)` (simple pole at z=∞)
- `SeriesExpansion20` / `SeriesExpansion20P`: divide by `(z-zz)²` (double pole at z=0)
- `SeriesExpansion21` / `SeriesExpansion21P`: divide by `(z-zz)²` (double pole at z=1)
- `SeriesExpansion2Inf` / `SeriesExpansion2InfP`: divide by `(z-zz)²` (double pole at z=∞)

**Coordinate mappings:**
- Straight (`uv`): standard cross-ratios `u = z·zz`, `v = (1-z)(1-zz)`.
- Permuted (`uvp`): permuted cross-ratios.

### 1.3 Prefactor Logic via Conformal Weight (Safe Method)
The safest way to determine the prefactor is to compute the **conformal weight** of each external point in the integrand.

**Definition:** The conformal weight of a point `p` in an integrand is:
```
weight(p) = (# of x[__] containing p in each numerator monomial) - (# of x[__] containing p in denominator)
```
where `x[__]^n` counts as `n` copies. For a valid DCI integrand, all monomials in the numerator must have the same conformal weight.

**Rule:**
- Compute `ConformalWeight[integrand, p]` for `p = 1, 2, 3, 4`.
- **If weight == 0** for all external points: the integrand is **not** normalized with any power of `x[1,3]x[2,4]`. Add the prefactor in the normal way based on the leading singularity.
- **If weight == −n** (negative integer) for all external points: the integrand **is** normalized with `x[1,3]^n x[2,4]^n`. The normalization factor has been absorbed into the measure.

**General formula:**

Decompose the leading singularity into the **primary pole** and the **additional pole**:
```
LS = [primary pole] · [additional pole]
```
- **Primary pole** (`1/(z−zz)` or `1/(z−zz)²`): handled internally by the `SeriesExpansion*` function — do **not** include in `base`. Under permutation the primary pole absorbs **k** powers of `F` where `k` is the pole order (`k=1` for simple, `k=2` for double).
- **Additional pole** (e.g., `1/(1−u)`, `1/(1−v)`, etc.): this is `base`, the quantity you transform and the only thing entering `base_transformed`.
- **Normalization** `x[1,3]^n x[2,4]^n`: under permutation transforms to `F^n·x[1,3]^n x[2,4]^n`, contributing `F^n` to the measure denominator that must be removed from the prefactor.

**Net effect** for any non-identity permutation:
```
additional = base_transformed · (1/F^n) / (1/F^k)  =  base_transformed / F^(n−k)
```
The factor `1/F^k` from the primary pole cancels k powers of `F` from the normalization, leaving `n−k` powers in the divisor.

- For `k=1` (simple pole, e.g. `1/(z−zz)`):  `additional = base_transformed / F^(n−1)`.
- For `k=2` (double pole, e.g. `1/(z−zz)²`): `additional = base_transformed / F^(n−2)`.
- For `n=k`: `additional = base_transformed` (no division).

**Normalization factor F for each permutation** (in straight z=0 coordinates):
The permutation transforms `x[1,3]x[2,4] → x[σ(1),σ(3)] x[σ(2),σ(4)]`. The ratio F = [transformed] / [original] is:

| Permutation | Rule | Transformation of `x[1,3]x[2,4]` | F |
|-------------|------|----------------------------------|---|
| `{1,2,3,4}` | identity | `x[1,3]x[2,4]` | **1** |
| `{2,1,3,4}` | `{1→2, 2→1}` | `x[2,3]x[1,4]` | **v** |
| `{3,2,1,4}` | `{1→3, 3→1}` | `x[3,1]x[2,4]` = `x[1,3]x[2,4]` | **1** |
| `{1,3,2,4}` | `{2→3, 3→2}` | `x[1,2]x[3,4]` | **u** |
| `{2,3,1,4}` | `{1→2, 2→3, 3→1}` | `x[2,1]x[3,4]` = `x[1,2]x[3,4]` | **u** |
| `{3,1,2,4}` | `{1→3, 3→2, 2→1}` | `x[3,2]x[1,4]` = `x[2,3]x[1,4]` | **v** |

where `u = x[1,2]x[3,4] / (x[1,3]x[2,4])` and `v = x[1,4]x[2,3] / (x[1,3]x[2,4])`.

**Complete six-expansion table** (leading singularity `1/((z−zz)(1−u))`, weight `−n`):
Base = `1/(1−u)` (additional pole only). All non-identity limits divide by `F^(n−1)`.

| # | Perm | SeriesExpansion | F | n=1 Prefactor | n=2 Prefactor |
|---|------|----------------|---|---|--------------|--------------|
| 1 | `{1,2,3,4}` | `SeriesExpansion0` | 1 | `1/(1−u)` | `1/(1−u)` |
| 2 | `{2,1,3,4}` | `SeriesExpansion0P` | v | `v/(v−u)` | `1/(v−u)` |
| 3 | `{1,3,2,4}` | `SeriesExpansionInf` | u | `u/(u−1)` | `1/(u−1)` |
| 4 | `{2,3,1,4}` | `SeriesExpansionInfP` | u | `u/(u−v)` | `1/(u−v)` |
| 5 | `{3,1,2,4}` | `SeriesExpansion1` | v | `v/(v−1)` | `1/(v−1)` |
| 6 | `{3,2,1,4}` | `SeriesExpansion1P` | 1 | `1/(1−v)` | `1/(1−v)` |

**Note:** This is the solving order. Rows 3-6 (infinity and z=1 limits) all divide by `F^(n−1)` because all involve non-identity permutations. There is no "straight vs permuted" distinction for the divisor — only the identity permutation uses `F^0=1`.

**Consistency check — integrand vs. ansatz:**
The series expansion of the **ansatz** (Skill 1) must match the series expansion of the **integrand** (Skill 2). Both derive their `additional` prefactor from the same logic: compute conformal weight → `n`, decompose LS into primary pole (order `k`) + additional pole → `base`, transform `base` under each permutation → `base_transformed`, then apply `additional = base_transformed / F^(n−k)` for all non-identity limits. `poleOrder = k` is derived from `poleType`: `"simple" → 1`, `"double" → 2`.

**Mathematica implementation** (see `ConformalWeight.m`):
```mathematica
ConformalWeight[integrand_, point_] := Module[
  {num, den, monomials, monoWeights, numWeight, denTerms, denWeight},
  num = Numerator[integrand];
  den = Denominator[integrand];
  
  (* Expand numerator into monomials *)
  monomials = MonomialList[num];
  If[monomials === {}, monomials = {num}];
  
  (* For each monomial, count x[a,b] factors containing the point *)
  monoWeights = Table[
    Module[{terms},
      terms = Cases[mono, x[a_, b_] :> {a, b}, {0, Infinity}];
      terms = Join[terms, Flatten[Cases[mono, x[a_, b_]^n_ :> Table[{a, b}, n], {0, Infinity}], 1]];
      Count[Flatten[terms], point]
    ],
    {mono, monomials}
  ];
  
  (* Check that all monomials have the same weight *)
  If[Length[Union[monoWeights]] > 1,
    Print["Warning: Monomials have different conformal weights for point ", point, ": ", monoWeights];
  ];
  
  (* Numerator weight is the common weight *)
  numWeight = monoWeights[[1]];
  
  (* Count x[a,b] factors in denominator containing the point *)
  denTerms = Cases[den, x[a_, b_] :> {a, b}, {0, Infinity}];
  denTerms = Join[denTerms, Flatten[Cases[den, x[a_, b_]^n_ :> Table[{a, b}, n], {0, Infinity}], 1]];
  denWeight = Count[Flatten[denTerms], point];
  
  (* Total conformal weight *)
  numWeight - denWeight
];
```

**Tested example:**
```mathematica
integrand = (x[1,3] x[2,4] (x[3,6] x[4,5] + x[3,5] x[4,6]))/
  (x[1,5] x[1,6] x[2,5] x[2,6] x[3,5] x[3,6] x[3,7] x[4,5] x[4,6] x[4,7] x[5,7] x[6,7]);

Table[{p, ConformalWeight[integrand, p]}, {p, 1, 7}]
(* Returns:
   {{1, -1}, {2, -1}, {3, -1}, {4, -1},
    {5, -4}, {6, -4}, {7, -4}}
*)

**CRITICAL BUG FIX**: The conformal weight `n` must be evaluated at an **external vertex** (e.g., 1, 2, 3, or 4). Evaluating at a loop vertex (5, 6, 7) will return the wrong weight and introduce spurious `1/Y^5` poles in the Jacobian!
```

**Examples:**
- Integrand `1/(x[1,5]x[2,5]x[3,5]x[4,5])` has weight `-1` for all external points (normalized with implicit `x[1,3]x[2,4]`).
- Integrand `x[1,3]x[2,4]/(x[1,5]x[2,5]x[3,5]x[4,5])` has weight `0` for all external points (not normalized, explicit factor in numerator).

**Decomposition examples:**
- Simple pole: `LS = 1/(z−zz)` → primary pole = `1/(z−zz)`, additional pole = `1` → base = `1`
- `LS = 1/((z−zz)(1−u))` → primary pole = `1/(z−zz)`, additional pole = `1/(1−u)` → base = `1/(1−u)`
- `LS = 1/((z−zz)(1−v))` → primary pole = `1/(z−zz)`, additional pole = `1/(1−v)` → base = `1/(1−v)`
- Double pole: `LS = 1/(z−zz)²` → primary pole = `1/(z−zz)²` (use `SeriesExpansion20*`), additional pole = `1` → base = `1`
- **Triple pole**: `LS = v/(z−zz)³` → primary pole = `1/(z−zz)` (use `SeriesExpansion0*`), additional pole = `v/(z−zz)²` → base = `v/((1+u−v)² − 4u)`
  - Note: `(1+u−v)² − 4u = (u+v−1)² − 4uv` (same denominator)
  - Proven run: `threeloopI8` (odd ansatz, 30 coefficients → 10 non-zero)

### 1.4 Permutation Transformation Rules
The six permutations of external legs correspond to the anharmonic group acting on the cross-ratio `z`. The mapping rules are:

| Permutation | Rule notation | z transformation | u transformation | v transformation |
|-------------|---------------|------------------|------------------|------------------|
| `{1,2,3,4}` | identity | `z -> z` | `u -> u` | `v -> v` |
| `{3,2,1,4}` | `{1->3, 3->1}` | `z -> 1-z` | `u -> v` | `v -> u` |
| `{1,3,2,4}` | `{2->3, 3->2}` | `z -> 1/z` | `u -> 1/u` | `v -> v/u` |
| `{3,1,2,4}` | `{1->3, 3->2, 2->1}` | `z -> 1/(1-z)` | `u -> 1/v` | `v -> u/v` |
| `{2,3,1,4}` | `{1->2, 2->3, 3->1}` | `z -> 1-1/z` | `u -> v/u` | `v -> 1/u` |
| `{2,1,3,4}` | `{1->2, 2->1}` | `z -> z/(z-1)` | `u -> u/v` | `v -> 1/v` |

In Mathematica rule notation:
```mathematica
{{1->3, 3->1}, z->1-z, u->v, v->u}
{{2->3, 3->2}, z->1/z, u->1/u, v->v/u}
{{1->3, 3->2, 2->1}, z->1/(1-z), u->1/v, v->u/v}
{{1->2, 2->3, 3->1}, z->1-1/z, u->v/u, v->1/u}
{{1->2, 2->1}, z->z/(z-1), u->u/v, v->1/v}
```

### 1.5 Process
1. **Import Data**: Read the `.txt` files as strings, trim brackets, and convert to Mathematica expressions via `ToExpression`. This yields the series expansions of MPL basis elements `I[z, a1, a2, ..., an]` at the three singular points.
2. **Coordinate Transformation**: Apply `zrep` rules to map powers of `z` and `zz` into algebraic expressions in `u` and `Y` (where `Y = 1 - v`), using `Solve` to invert the cross-ratio relations.
3. **Six Expansions**: For each singular point (e0, e1, einf), perform two coordinate mappings (straight and permuted) using the appropriate `SeriesExpansion*` function.
4. **Apply Prefactor**: Set the `additional` option based on the leading singularity and normalization convention (see Section 1.3).
5. **Symbol Mapping**: Map special symbols:
   - `f[3]` → `Zeta[3]`, `f[5]` → `Zeta[5]`, `f[7]` → `Zeta[7]`
   - `P[0]` → `-Log[u]` or `-Log[u/v]` depending on the limit
   - `I[z, 0, 0]` → `Log[u]` or `Log[u/v]` depending on the limit

### 1.6 Output
Six `.m` files per singular point (one `svlist` and one `svlistmpl` per coordinate mapping), plus six permuted-coordinate variants. **Naming convention:** the suffix encodes the leading singularity. Each distinct leading singularity (primary pole × additional pole) requires its own set of files, named with a label identifying that singularity.

| Limit | Straight files | Permuted files |
|-------|---------------|----------------|
| z→0 | `<label>_svliste0uv.m`, `<label>_svlistmple0uv.m` | `<label>_svliste0uvp.m`, `<label>_svlistmple0uvp.m` |
| z→1 | `<label>_svliste1uv.m`, `<label>_svlistmple1uv.m` | `<label>_svliste1uvp.m`, `<label>_svlistmple1uvp.m` |
| z→∞ | `<label>_svlisteinfuv.m`, `<label>_svlistmpleinfuv.m` | `<label>_svlisteinfuvp.m`, `<label>_svlistmpleinfuvp.m` |

### 1.7 Interactive Overwrite Guard

Before starting the 6 series expansions, `RunSeriesExpansion` checks whether any of the 12 output `.m` files already exist under `series_agent/<label>_*`. If any are found:

```
[Skill 1] WARNING: 12 existing series expansion files will be overwritten:
  - .../series_agent/threeloophard2_svliste0uv.m
  - .../series_agent/threeloophard2_svlistmple0uv.m
  - ...
[Skill 1] Proceed and overwrite? (y/n)
```

- `y` / `Y` / `yes` / `Yes` — replaces all existing files and proceeds
- Anything else — prints `ABORTED by user — existing files preserved.` and returns `$Failed`

This prevents accidental corruption of cached series expansions when re-running with different parameters.

---

## 2. Skill 2: Boundary Condition Calculation

### 2.1 Input
- An integrand as a rational function with denominator being a product of propagators `x[a,b]`.
- A permutation of external legs (e.g., `{1,2,3,4}`, `{1,3,2,4}`, `{2,1,3,4}`, `{2,3,1,4}`, `{3,1,2,4}`, `{3,2,1,4}`).

**Skip behavior:** Before any computation, `RunBoundaryConditions` checks whether the 6 expected output files already exist. If they are found in `asym/boundary_agent/` (or the optional `"InputDir"`, e.g., `runs/<label>/boundaries/`), the entire IBP/tensor-reduction/series steps are skipped and the existing files are reused. Files found in `"InputDir"` are automatically copied to `asym/boundary_agent/` for downstream access.

### 2.2 Process (exact syntax from `run_I3Lhard_parallel.wl`)
The agent strictly follows the template. Only the integrand expression varies per problem.

1. **Load LiteRed2 and set kinematics**:
   ```mathematica
   Get["LiteRed2`"];
   SetDim[d];
   Declare[{l1, l2, l3, l4, p}, Vector, {u}, Number];
   SetConstraints[{p}, sp[p, p] = u];
   ```
2. **Load LiteRed2 bases** from `asym/Bases/asym`, `asym3L`, `asym2L`, `asym1L`.
3. **Launch parallel kernels**: `LaunchKernels[6]`.
4. **Load asymptotic expansion engine** and broadcast it:
   ```mathematica
   Get["./asym/asym_new.wl"];
   ParallelEvaluate[Get["./asym/asym_new.wl"]];
   ```
5. **Define global integrand and permutations** (`$Integrand`, `$Perms`).
6. **Run parallel expansion**: `RunAsymExpansionParallel[label, $Integrand, $Perms, 3, {5, 6, 7}]`.

Temporary results in `asym/tmp/` (e.g., `targetIntegrals_reduced.m`) are reused across bootstrap problems.

### 2.4 IBP Output Redirection
`RunBoundaryConditions` supports a `"IBPDir"` option (default: `"/Users/<user>/Documents/aether/svbwalkthrough_ibp"`) to redirect LiteRed2 IBP reduction tables out of the workspace. Before `RunAsymExpansionParallel` runs, the working directory is temporarily changed to `"IBPDir"` so that LiteRed2's `IBPReduce` writes its `.mx` caches there instead of creating `IBPReduction*/` directories in the project root.

```mathematica
RunBoundaryConditions[rootDir, label, order, loopPoints,
  "IBPDir" -> "/Users/me/Documents/aether/svbwalkthrough_ibp"]
```

The external directory is gitignored and aetherignored, while `asym/tmp/` (tensor reduction and target integral caches) remains in-workspace.

### 2.3 Output
`RunAsymExpansionParallel` saves 6 files to `asym/boundary_agent/`:

```
<label><perm>_order<order>_asyexp.m
```

where `<perm>` is the concatenated digit string (e.g., `1234`). These are exactly the files listed in Section 3.1's `targetData` table.

---

## 3. Skill 3: Coefficient Solving

### 3.1 Input
- `config`: The parsed input configuration, containing a list of `LeadingSingularities`, each specifying its own `ansatzExpr`. SV and MPL bases are now automatically matched to the subsets needed by each ansatz.
- Pre-computed series expansions from **Skill 1** (`series_agent/<label>_svlist*.m`, `series_agent/<label>_svlistmpl*.m`).
- `targetData` — a list of 6 boundary condition expressions. Construct by loading the output files from Skill 2 in this **exact order**:

| Position | Permutation | Limit | File to load |
|----------|-------------|-------|-------------|
| 1 | `{1,2,3,4}` | e0uv | `<label>1234_order<order>_asyexp.m` |
| 2 | `{2,1,3,4}` | e0uvp | `<label>2134_order<order>_asyexp.m` |
| 3 | `{1,3,2,4}` | einfuv | `<label>1324_order<order>_asyexp.m` |
| 4 | `{2,3,1,4}` | einfuvp | `<label>2314_order<order>_asyexp.m` |
| 5 | `{3,1,2,4}` | e1uv | `<label>3124_order<order>_asyexp.m` |
| 6 | `{3,2,1,4}` | e1uvp | `<label>3214_order<order>_asyexp.m` |

### 3.2 Process (exact notebook syntax)
The agent strictly follows the syntax of `svbwalkthrough.nb` Section 6. Only file paths and ansatz construction vary per integrand.

1. **Load basis and ansatz**:
   ```mathematica
   allsvlist    = basisSV;
   allsvlistmpl = basisMPL;
   testansatz   = ansatzExpr;
   $LEN         = Length[testansatz];
   $Order       = order;
   ```

2. **Build svrep for each limit** (import series expansions, apply `Series` to `$Order`):
   ```mathematica
   svrep = Join[
     Thread @ Rule[allsvlist,    ((Series[#, {Y, 0, $Order}] // Normal) &) /@ svliste],
     Thread @ Rule[allsvlistmpl, ((Series[#, {Y, 0, $Order}] // Normal) &) /@ svlistmple]
   ];
   ```

3. **Build setup** (substitutes partial solution from previous limits):
   ```mathematica
   setup = ((c /@ Range[$LEN]) . testansatz) /. solt /. svrep;
   ```
   After each limit is solved, `solt` carries the known coefficients forward so that subsequent limits work with the *remaining* unknowns.

4. **Compute temp** (difference with target, replace f→Zeta). Uses `Normal[...]` to avoid SeriesData/polynomial mixing:
   ```mathematica
   temp = MonomialList[
     Normal[setup - targetData[[i]]] /. {
       f[3, 3] -> Zeta[3]^2 / 2,
       f[3, 5] -> Zeta[3] Zeta[5] - f[5, 3],
       f[a_] :> Zeta[a]
     },
     {Log[u]}
   ] // DeleteCases[#, 0] &;
   ```
   **If `temp === {}`**: this limit provides no constraints — skip to the next limit.

5. **Extract coefficients** (`temp1`, **FIXED** — lifted verbatim from notebook, never changes): replace `Log[u]→1`, handle negative powers of `Y` and `u` via `invY`/`invu`, then `MonomialList` in `{u, Y, invY, invu}`, restore `Y→1, invY→1, invu→1`.

6. **Build equations** (`sys1`, **FIXED** — lifted verbatim from notebook, never changes): replace `Zeta[n]→zn`, `Pi→pi`, take `MonomialList` in `{z3, z5, z7, f[5,3], pi}`, restore `zn→1`, then `Thread@Equal[..., 0]`, flatten, delete `True`, `False`, and `0`.

7. **Incremental join and solve**:
   ```mathematica
   cVars = Select[Variables[sys[[All, 1]]],
     MatchQ[#, _[_]] && StringMatchQ[SymbolName[Head[#]], "c*"] &];
   solt = Solve[sys, cVars][[1]];
   ```
   Only `c[i]`-like symbols are passed to `Solve`; `I[z,...]`, `u`, `Y`, `Log[u]` are excluded.

8. **Verify**: substitute `solt` back into `setup` for each limit and check `temp === 0`.

### 3.3 Output
- `solve_agent/<label>_sol.m`: Raw solved numeric values for all coefficients `c[i]`.
- `runs/<label>/coeff_sol.m`: Processed list of solved coefficient values, partitioned by leading singularity (e.g., `{{c1, c2, ...}, {cN, ...}}`). Generated natively by `solve_agent.wl`.
- `runs/<label>/result.m`: Final expanded list of ansatz elements multiplied by their respective solved coefficients (e.g., `{coeff1.ansatz1, coeff2.ansatz2, ...}`). Generated natively by `solve_agent.wl` directly into the run folder without manual prefactors.
- `runs/<label>/run.log`: Console output of the `solve_agent` is natively stream-captured directly to this file during execution.

---

## 4. Key Data Files

| File | Purpose |
|------|---------|
| `master_agent.wl` | Skill 0 orchestrator |
| `series_agent/series_agent.wl` | Skill 1: ansatz series expansion |
| `asym/boundary_agent/boundary_agent.wl` | Skill 2: boundary condition calculation |
| `solve_agent/solve_agent.wl` | Skill 3: coefficient solving |
| `ConformalWeight.m` | Conformal weight calculator (shared) |
| `svbwalkthrough.nb` | Main notebook with all algorithms |
| `allsvlist_fourloop.m` | SVHPL basis (list of elements) |
| `data/allsvliste0_uptow8.txt` | Series expansion of SVHPL basis at z→0 |
| `data/allsvliste1_uptow8.txt` | Series expansion of SVHPL basis at z→1 |
| `data/allsvlisteinf_uptow8.txt` | Series expansion of SVHPL basis at z→∞ |
| `data/allsvlistmpl_*.m` files | Auto-detected: scanned for best ansatz element coverage |
| SVHPL basis | `allsvlist_fourloop.m` (fixed, all runs share it) |

### MPL basis auto-detection

The pipeline scans `allsvlistmpl_*.m` files in the project root. For each candidate, it counts how many ansatz `_I` and `_f` elements it contains. The basis with the best coverage is selected as `mplBasisFile`.

The corresponding expansion files must follow the naming convention and can be in either format:
```
allsvlistmpl_<name>.m          ← basis file
allsvlistmpl_<name>e0.{m,txt}  ← expansion at z→0  (.m = expression, .txt = string)
allsvlistmpl_<name>e1.{m,txt}  ← expansion at z→1
allsvlistmpl_<name>einf.{m,txt} ← expansion at z→∞
```

For a new problem type, drop in `<name>.m` and `<name>e{0,1,inf}.{m,txt}` — no code changes needed.

### Workspace exclusion files

| File | Purpose |
|------|---------|
| `.aetherignore` | Exclude large intermediate data (`IBPReduction*/`, `asym/tmp/`, `asym/Bases/`, `asym/logs/`, `*.mx`) from AI indexing |
| `.gitignore` | Exclude same patterns from git tracking |
| `allsvlistmpl_threeloope0.txt` | Series expansion of MPL basis at z→0 |
| `allsvlistmpl_threeloope1.txt` | Series expansion of MPL basis at z→1 |
| `allsvlistmpl_threeloopeinf.txt` | Series expansion of MPL basis at z→∞ |
| `svmplevenansatz_threeloop.m` | Even parity ansatz components |
| `svmploddansatz_threeloop.m` | Odd parity ansatz components |
| `runs/<label>/threeloophard1_ans.m` | Even-ansatz for hard topology (runs/threeloophard1/) |
| `runs/<label>/threeloophard2_ans.m` | Even-ansatz for hard topology (runs/threeloophard2/) |
| `runs/<label>/threeloopoddansatz.m` | Odd-ansatz (runs/threeloopI5/, threeloopI8/, fourloopI6boxing/) |
| `runs/<label>/result.m` | Solved final result list written natively by solve_agent |
| `runs/<label>/coeff_sol.m` | Partitioned coefficient values list natively by solve_agent |
| `runs/<label>/run.log` | Captured log of the coefficient solver execution |
| `solve_agent/<label>_sol.m` | Raw solved coefficient substitution rules |
| `review_agent.wl` | Review facade (gateway to audit agent) |
| `audit_agent/audit_agent.wl` | Skill 4: stage review checks |
| `project_skills/ansatz_basis/SKILL.md` | Ansatz construction documentation |
| `asym/asym_new.wl` | Core asymptotic expansion engine |
| `asym/boundary_agent/<label>*_asyexp.m` | Boundary condition outputs (SeriesData in Y) |
| `asym/tmp/targetIntegrals_reduced.m` | Shared target integrals cache (always keep) |

---

## 5. Workflow Diagram

```
Skill 0 (master_agent.wl): orchestrates the pipeline
  |
  ├─ ConformalWeight.m → determines weightN = n
  ├─ review_agent.wl   → ReviewGate at 8 checkpoints (4 pre, 4 post)
  |
  ├─ [PRE-FLIGHT]    ReviewGate[rootDir, label, "preflight"]
  |    Checks: ConformalWeight.m, SVHPL .txt, MPL source files exist
  |
  ├─ [PRE-BOUNDARY]  ReviewGate[rootDir, label, "preboundary"]
  |    Checks: LiteRed2 bases, asym_new.wl, Gmaterrep files, tmp dir
  |
  ├─ Skill 2 (asym/boundary_agent/boundary_agent.wl)  [SKIPPED if boundary files exist]
  |    |  - Check asym/boundary_agent/ and optional "InputDir" for existing files
  |    |  - If found: skip computation and reuse existing files
  |    |  - If not found: redirect CWD to "IBPDir" for LiteRed2 IBP output
  |    |  - RunAsymExpansionParallel for 6 permutations
  |    |  - RegionExpand, TensorReduce, IBPReduce
  |    |  - Series expansion in {u, 0} and {Y, 0, order}
  |    |  - Caches intermediate results in asym/tmp/ for reuse
  |    |  - Restore CWD
  |    v
  |  Output: asym/boundary_agent/<label>*_asyexp.m
  |
  ├─ [BOUNDARY]     ReviewGate[rootDir, label, "boundary"]
  |
  ├─ [PRE-SERIES]   ReviewGate[rootDir, label, "preseries"]
  |    Checks: SVHPL .txt parse OK; MPL .m files load as lists (no parsing)
  |             or MPL .txt files parse as lists (string-wrapped); records format
  |
  ├─ Skill 1 (series_agent/series_agent.wl)
  |    |  - poleOrder = poleType /. {"simple"→1, "double"→2}
  |    |  - additional = base_transformed / F^(weightN − poleOrder)
  |    |  - 6 expansions (e0uv, e0uvp, einfuv, einfuvp, e1uv, e1uvp)
  |    |  - MPL loader: .m → expression (no parse), .txt → string → parse
  |    v
  |  Output: series_agent/<label>_svlist*.m
  |
  ├─ [SERIES]       ReviewGate[rootDir, label, "series"]
  |
  ├─ [PRE-SOLVE]    ReviewGate[rootDir, label, "presolve"]
  |    Checks: boundary files exist (6), series expansion files exist (12)
  |
  ├─ Skill 3 (solve_agent/solve_agent.wl)
  |    |  - Opens output stream to runs/<label>/run.log
  |    |  - Load series expansions + boundary conditions
  |    |  - setup = (c[i]).ansatz /. solt /. svrep
  |    |  - Incremental solve across 6 limits
  |    |  - Partitions coefficients and reconstructs final ansatze natively
  |    v
  |  Output: solve_agent/<label>_sol.m
  |          runs/<label>/result.m
  |          runs/<label>/coeff_sol.m
  |
  ├─ [SOLVE]        ReviewGate[rootDir, label, "solve"]
  |
  v
Output: Solved coefficients c[i]

project_skills/ansatz_basis/ — separate documentation-only skill
  Teaches an agent how to construct parity-even/odd ansatz bases.
```

---

## 6. Run Convention

Each bootstrap run lives in its own directory under `runs/<label>/`:

```
runs/<label>/
  input.wl    — integrand, leading singularity, ansatz path
  run.wl      — run script (bottom-up integration of Skills 1-3)
  result.m    — final result (c[i] × ansatz, expanded)
```

The run script `runs/<label>/run.wl`:
1. Uses `input_parser.wl` to parse `runs/<label>/input.wl`.
2. Passes the `parsed` configuration to `SolveIntegrandSystem`.
3. `SolveIntegrandSystem` manages the multi-LS workflow:
   - Evaluates the integrand limits via Skill 2.
   - For each LS, computes conformal weight (from external point 1) and runs Skill 1 to generate series expansions.
   - Passes all bases and expansions to Skill 3 to incrementally solve for the coefficients.
4. **Seamless Exit**: The run script immediately exits. The underlying `solve_agent.wl` automatically drops `result.m`, `coeff_sol.m`, and `run.log` perfectly into the run directory. Legacy assembly loops have been aggressively stripped out of orchestration scripts to prevent duplication or manual prefactor errors.

### Proven run: `threeloophard1`
- Integrand: `(x[5,6]*x[3,4]−x[3,6]x[4,5]−x[3,5]x[4,6])/12p`
- LS: `1/(z−zz)²`, n=2, poleType=`"double"`, k=2
- Ansatz: `threeloophard1_ans.m` (57 elements, even parity)
- Result: 57-term combination with 26 non-zero coefficients

### Proven run: `threeloophard2`
- Integrand: `(x[3,6]x[4,5]+x[3,5]x[4,6])/12p`
- LS: `1/((z−zz)(1−v))`, n=2, poleType=`"simple"`, k=1
- Ansatz: `threeloophard2_ans.m` (43 elements, even parity)
- Result: 43-term `I[z,...]` combination (30 non-zero)

### Proven run: `threeloopI5`
- Integrand: `1/10p`
- LS: `1/((z−zz)(1−v))`, n=2, poleType=`"simple"`, k=1
- Ansatz: `threeloopoddansatz.m` (30 elements, odd parity)
- Result: 30-term combination with 19 non-zero coefficients

### Proven run: `threeloopI8`
- Integrand: `(x[1,4]x[2,3])/12p`
- LS: `v/(z−zz)³`, n=2, poleType=`"simple"`, k=1, base=`v/((1+u−v)²−4u)`
- Ansatz: `threeloopoddansatz.m` (30 elements, odd parity)
- Result: 30-term `I[z,...]` combination (10 non-zero)

### Proven run: `fourloopI6boxing`
- Integrand: 4-loop boxing (reduced to 3-loop equivalent)
- LS: `u·v/(z−zz)`, n=0, poleType=`"simple"`, k=1
- Ansatz: `threeloopoddansatz.m` (30 elements, odd parity)
- Result: unsolved (ansatz/boundary mismatch, investigation pending)

### Proven run: `fourloopI41`
- Integrand: `(x[4,7]x[5,6] − x[4,5]x[6,7] − x[4,6]x[5,7]) / 14p`
- LS: `1/((z−zz)(1−u))`, n=2, poleType=`"simple"`, k=1
- Ansatz: `fourloopI41ansatz.m` (146 elements)
- Basis: `allsvlist_fourloop.m` (510 SVHPL), `allsvlistmpl_fourloop_invzz.m` (280 MPL)
- Result: 146-term combination, 105 non-zero coefficients
- IBP output: redirected to `~/Documents/aether/svbwalkthrough_ibp/` via `"IBPDir"` option

### Key fixes baked into the pipeline
| Fix | Where |
|-----|-------|
| Pre-flight audit pipeline: preflight → preboundary → boundary → preseries → series → presolve → solve | audit_agent, master_agent, run.wl |
| MPL .m vs .txt format convention: .m = expression (no parse), .txt = string (parse via StringTrim) | series_agent, audit_agent |
| IBP output redirection via `"IBPDir"` option (LiteRed2 .mx caches to external dir) | boundary_agent |
| `add = transformed / F^(weightN − poleOrder)` with `k=poleOrder` | Skill 1 |
| `poleOrder` auto-derived from `poleType` ("simple"→1, "double"→2) | Skill 0, Skill 1 |
| `Variables` + `Exponent` counting (fixes `x[a,b]^n` double-count) | ConformalWeight |
| Boundary skip: detect existing files in `asym/boundary_agent/` or `"InputDir"` | Skill 2 |
| `Normal[...]` in `temp` computation (SeriesData vs Normal subtraction) | Skill 3 |
| Basis pre-filtering to ansatz indices (4–8× speedup) | Run script |
| MPL-empty handling: set `svlistmple*` to `{}` when `mplIndices={}` | Skill 1 |
| Empty `temp` skip (don't build equations from vanishing limits) | Skill 3 |
| `//Normal` on boundary import (SeriesData → polynomial) | Run script |
| Incremental solve only updates `sys`/`solt` when real equations found | Skill 3 |
| `cVars` extraction: `Select[allVars, _[_] && StringMatchQ[SymbolName[Head[#]], "c*"] &]` | Skill 3 |
| Filter `False` from `sys1` (`DeleteCases[#, True \| False] &`) | Skill 3 |
| Clean `c[i]` export via `Symbol["c"]` | Skill 3 |
| `asym4LbasisChange.m` required for boundary agent | Boundary agent |
| `order` forwarding from orchestrator to boundary agent | Skill 0, Skill 2 |
| 12 SeriesExpansion functions verbatim from `svbwalkthrough.wl` | Skill 1 |
| 6 `zrep` definitions per limit | Skill 1 |
| `filepath` shadowing removed from `boundary_agent.wl` | Skill 2 |

### Loop-order convention

| Loops | `$Order` (boundary + solve) | `yOrder` (series Y expansion) | Internal points |
|-------|-----|------|----------------|
| 3-loop | 3 | 4 | `{5,6,7}` |
| 4-loop | 4 | 5 | `{5,6,7,8}` |

---

## 7. Cache Cleanup for Fresh Runs

When restarting a bootstrap run from scratch, all cached outputs of prior runs must be removed:

### Files to remove for a given `<label>`:

| Directory | Pattern | Description |
|-----------|---------|-------------|
| `asym/boundary_agent/` | `<label>*_order*_asyexp.m` | Boundary condition output (6 files) |
| `asym/tmp/` | `tensor_<label>*` | Tensor reduction cache (6 `.m` + 6 subdirectories) |
| `series_agent/` | `<label>_svlist*` | Series expansion output (12 files: 6 svliste + 6 svlistmple) |
| `solve_agent/` | `<label>_sol.m` | Solved coefficients (1 file) |

### Files to KEEP:

| Directory | File | Reason |
|-----------|------|--------|
| `asym/tmp/` | `targetIntegrals_reduced.m` | Shared across all runs — contains pre-reduced target integrals |
| External `"IBPDir"` | `IBPReduction*/` (LiteRed2 .mx caches) | IBP reduction tables, reusable across runs; kept outside workspace |

### Example — clean `threeloophard2`:

```bash
rm asym/boundary_agent/threeloophard2*_order*_asyexp.m
rm -rf asym/tmp/tensor_threeloophard2*
rm series_agent/threeloophard2_svlist*
rm solve_agent/threeloophard2_sol.m
```

### Verification:

```bash
find . -name "*<label>*" -not -path "*/.git/*" -not -path "*/runs/<label>/*"
```

Only the run directory and project-root files (e.g., `<label>_ans.m`) should remain. If any cache files appear, they must be removed before a fresh run.

### Expansion Limits
* **Three-loop runs:** `Y` is evaluated to `Y^3` by default. This is because the available boundary constraints (`boundary.m`) are only provided up to $O(Y^3)$.
* **Four-loop runs:** `Y` is evaluated to `Y^4` by default.
* **Overrides:** If the user specifically instructs to evaluate a certain run at a different expansion order, always follow their explicit instructions over the defaults.
