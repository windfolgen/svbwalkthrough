# Summary of SVB Walkthrough Calculation Procedures

## Overview
This Mathematica notebook implements a **bootstrap method for computing multi-loop Feynman integrals** via leading singularities. The core workflow is: (1) compute leading singularities of an integrand, (2) construct an ansatz from a basis of transcendental functions, (3) fix the ansatz coefficients by matching to the leading singularities.

**Input to the workflow**: the integrand, the leading singularities, and the integral ansatz for each leading singularity.
**Output of the workflow**: the coefficients before the ansatz.

---

## 0. Skill 0: Master Orchestrator

### 0.1 Directory Structure
Each skill operates in its own working directory. Output files are written to the skill's directory so that they are automatically discoverable by downstream skills.

```
.                           (project root)
├── master_agent.wl          — Skill 0: orchestrator
├── ConformalWeight.m        — conformal weight calculator (shared)
├── series_agent/
│   └── series_agent.wl      — Skill 1: ansatz series expansion
├── asym/
│   ├── asym_new.wl          — asymptotic expansion engine (shared)
│   ├── Bases/               — LiteRed2 IBP bases
│   ├── tmp/                 — cached tensor reduction / IBP results (reusable)
│   └── boundary_agent/
│       └── boundary_agent.wl — Skill 2: boundary condition calculation
├── audit_agent/
│   └── audit_agent.wl       — Skill 4: post-step audit and benchmark checks
└── solve_agent/
    └── solve_agent.wl        — Skill 3: coefficient solving
```

### 0.2 Orchestrator (`master_agent.wl`)
`RunSVBPipeline[rootDir, label, poleType, lsAddPole]`

Set these **globals** before calling:
- `$Integrand` — the integrand expression
- `$Perms` — `{{1,2,3,4},{1,3,2,4},{2,1,3,4},{2,3,1,4},{3,1,2,4},{3,2,1,4}}`
- `ansatzExpr`, `basisSV`, `basisMPL`, `targetData` — for Skill 3

Each integrand has **exactly one** leading singularity (one primary pole + one additional pole).

Optional audit settings:
```mathematica
"Audit" -> True                 (* run audit checks after each stage *)
"AuditReport" -> True           (* write audit_agent/reports/*.md and *.m *)
"StopOnAuditFailure" -> True    (* stop immediately on FAIL *)
"AuditResiduals" -> True        (* solve-stage residual substitution check *)
```

1. Loads `ConformalWeight.m` → computes `weightN` from `$Integrand`.
2. If auditing is enabled, runs **preflight audit** on source contracts and input consistency.
3. Calls **Skill 2** (`RunBoundaryConditions`) — uses `$Integrand` and `$Perms` as globals, matching `run_I3Lhard_parallel.wl`; then audits boundary files and freshness.
4. Calls **Skill 1** (`RunSeriesExpansion`) with `additional = base_transformed / F^(n−1)`; then audits the 12 series files, basis lengths, and freshness.
5. Calls **Skill 3** (`RunCoefficientSolving`) — uses `ansatzExpr`, `basisSV`, `basisMPL`, `targetData` as globals; then audits coefficient coverage and optionally residuals.
6. Writes a combined pipeline audit report if `"AuditReport" -> True`.
7. All file paths are resolved relative to `$RootDir`.

### 0.3 File Dependencies and Loading
All three skills share a single `label` (one integrand, one leading singularity). Each agent accesses files relative to `$RootDir`:

| Agent | Reads from | Writes to |
|-------|-----------|-----------|
| `series_agent.wl` | `root/allsvliste*_uptow8.txt`, `root/allsvlistmpl_threeloopharde*.txt`, `root/ConformalWeight.m` | `root/series_agent/<label>_svlist*.m` (SVHPL), `root/series_agent/<label>_svlistmpl*.m` (MPL) |
| `boundary_agent.wl` | `root/asym/asym_new.wl`, `root/asym/Bases/`, `root/asym/tmp/` (reused across runs) | `root/asym/boundary_agent/<label>*_asyexp.m` |
| `solve_agent.wl` | `root/series_agent/<label>_svlist*.m`, `root/asym/boundary_agent/<label>*_asyexp.m`, ansatz and basis `.m` files | `root/solve_agent/<label>_sol.m` |
| `audit_agent.wl` | Agent source files, boundary/series/solve outputs, optional benchmark targets | `root/audit_agent/reports/<label>_audit_report.{m,md}` |

---

## 1. Skill 1: Ansatz Series Expansion

### 1.1 Input
Each `.txt` file contains the series expansion of a corresponding basis `.m` file:

| Basis file (list of elements) | Expansion files (series at singular points) |
|------|------|
| `allsvlist_fourloop.m` (SVHPL basis) | `allsvliste0_uptow8.txt` (z→0), `allsvliste1_uptow8.txt` (z→1), `allsvlisteinf_uptow8.txt` (z→∞) |
| `allsvlistmpl_threeloop.m` (MPL basis) | `allsvlistmpl_threeloopharde0.txt` (z→0), `allsvlistmpl_threeloopharde1.txt` (z→1), `allsvlistmpl_threeloophardeinf.txt` (z→∞) |

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
- **Primary pole** (`1/(z−zz)` or `1/(z−zz)²`): handled internally by the `SeriesExpansion*` function — do **not** include in `base`. Under permutation it contributes a factor of `1/F` that the function already absorbs.
- **Additional pole** (e.g., `1/(1−u)`, `1/(1−v)`, etc.): this is `base`, the quantity you transform and the only thing entering `base_transformed`.
- **Normalization** `x[1,3]^n x[2,4]^n`: under permutation transforms to `F^n·x[1,3]^n x[2,4]^n`, contributing `F^n` to the measure denominator that must be removed from the prefactor.

**Net effect** for any non-identity permutation:
```
additional = base_transformed · (1/F^n) / (1/F)  =  base_transformed / F^(n−1)
```
The factor `1/F` from the primary pole cancels one power of `F` from the normalization, leaving `n−1` powers in the divisor.

- For `n = 1` (weight −1): `additional = base_transformed` (no division).
- For `n = 2` (weight −2): `additional = base_transformed / F`.

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
The series expansion of the **ansatz** (Skill 1) must match the series expansion of the **integrand** (Skill 2). Both derive their `additional` prefactor from the same logic: compute conformal weight → `n`, decompose LS into primary pole + additional pole → `base`, transform `base` under each permutation → `base_transformed`, then apply `additional = base_transformed / F^(n−1)` for all non-identity limits. The same leading singularity with a different normalization power `n` changes the prefactor by `1/F^(n−1)` on every non-identity limit.

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
```

**Examples:**
- Integrand `1/(x[1,5]x[2,5]x[3,5]x[4,5])` has weight `-1` for all external points (normalized with implicit `x[1,3]x[2,4]`).
- Integrand `x[1,3]x[2,4]/(x[1,5]x[2,5]x[3,5]x[4,5])` has weight `0` for all external points (not normalized, explicit factor in numerator).

**Decomposition examples:**
- Simple pole: `LS = 1/(z−zz)` → primary pole = `1/(z−zz)`, additional pole = `1` → base = `1`
- `LS = 1/((z−zz)(1−u))` → primary pole = `1/(z−zz)`, additional pole = `1/(1−u)` → base = `1/(1−u)`
- `LS = 1/((z−zz)(1−v))` → primary pole = `1/(z−zz)`, additional pole = `1/(1−v)` → base = `1/(1−v)`
- Double pole: `LS = 1/(z−zz)²` → primary pole = `1/(z−zz)²` (use `SeriesExpansion20*`), additional pole = `1` → base = `1`

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

**Example** (notebook labels): for the two leading singularities of the hard topology:
- `1/(z−zz)²` → label `threeloophard1` → files: `threeloophard1_svliste0uv.m`, etc.
- `1/((z−zz)(1−u))` → label `threeloophard2` → files: `threeloophard2_svliste0uv.m`, etc.

---

## 2. Skill 2: Boundary Condition Calculation

### 2.1 Input
- An integrand as a rational function with denominator being a product of propagators `x[a,b]`.
- A permutation of external legs (e.g., `{1,2,3,4}`, `{1,3,2,4}`, `{2,1,3,4}`, `{2,3,1,4}`, `{3,1,2,4}`, `{3,2,1,4}`).

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

### 2.3 Output
`RunAsymExpansionParallel` saves 6 files to `asym/boundary_agent/`:

```
<label><perm>_order<order>_asyexp.m
```

where `<perm>` is the concatenated digit string (e.g., `1234`). These are exactly the files listed in Section 3.1's `targetData` table.

---

## 3. Skill 3: Coefficient Solving

### 3.1 Input
- `ansatzExpr`: The complete `testansatz` expression (`Join[svhplansatz, svmplbasis]`).
- `basisSV` (`allsvlist_fourloop.m`): SVHPL basis list.
- `basisMPL` (`allsvlistmpl_threeloop.m`): MPL basis list.
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

4. **Compute temp** (difference with target, replace f→Zeta):
   ```mathematica
   temp = MonomialList[
     (setup - targetData[[i]]) /. {
       f[3, 3] -> Zeta[3]^2 / 2,
       f[3, 5] -> Zeta[3] Zeta[5] - f[5, 3],
       f[a_] :> Zeta[a]
     },
     {Log[u]}
   ] // DeleteCases[#, 0] &;
   ```
   **If `temp === {}`**: this limit provides no constraints — skip to the next limit.

5. **Extract coefficients** (`temp1`, **FIXED** — lifted verbatim from notebook, never changes): replace `Log[u]→1`, handle negative powers of `Y` and `u` via `invY`/`invu`, then `MonomialList` in `{u, Y, invY, invu}`, restore `Y→1, invY→1, invu→1`.

6. **Build equations** (`sys1`, **FIXED** — lifted verbatim from notebook, never changes): replace `Zeta[n]→zn`, `Pi→pi`, take `MonomialList` in `{z3, z5, z7, f[5,3], pi}`, restore `zn→1`, then `Thread@Equal[..., 0]`, flatten, delete `True` and `0`.

7. **Incremental join and solve** (exact notebook syntax):
   ```mathematica
   syst = Join[sys, sys1];
   solt = Solve[syst, Variables[syst[[All, 1]]]][[1]];
   ```

8. **Verify**: substitute `solt` back into `setup` for each limit and check `temp === 0`.

### 3.3 Output
- `solve_agent/<label>_sol.m`: Solved numeric values for all coefficients `c[i]`.

---

## 4. Skill 4: Audit Agent

`audit_agent/audit_agent.wl` is a read-only verification layer. It should be called after each stage, or once at the end of a pipeline run. It checks source-level contracts, output existence, file freshness, permutation order, expression shape, basis lengths, coefficient coverage, and optional residual matching.

When `"Audit" -> True`, `master_agent.wl` calls this audit layer automatically after preflight, boundary, series, and solve. A stage with `FAIL` stops the pipeline by default; `WARN` is reported but does not stop execution.

Current review-gate entrypoints:

```mathematica
RunReviewGate[root, label, "preflight", ...]
RunReviewGate[root, label, "boundary", ...]
RunReviewGate[root, label, "series", ...]
RunReviewGate[root, label, "solve", ...]
RunReviewGate[root, label, "pipeline", ...]
AuditAnsatzBenchmark[root, candidate, "Parity" -> "even" (* or "odd" *)]
AuditHardBenchmarkWorkspace[root]
```

Non-interactive workspace runner:

```bash
/Applications/Wolfram.app/Contents/MacOS/wolframscript -file audit_agent/run_hard_benchmark_review.wl
```

### 4.1 Main functions

```mathematica
Get[FileNameJoin[{root, "audit_agent", "audit_agent.wl"}]];

AuditSourceContracts[root]
AuditPipelineInput[root, integrand, poleType, lsBase, ansatzExpr, basisSV, basisMPL]
AuditBoundaryStep[root, label, order]
AuditSeriesStep[root, label, basisSV, basisMPL, "LSBase" -> lsBase, "WeightN" -> n]
AuditSolveStep[root, label, ansatzExpr, basisSV, basisMPL, "TargetData" -> targetData]
AuditFullPipeline[root, label, integrand, poleType, lsBase, ansatzExpr, basisSV, basisMPL]
```

Each function returns an association:

```mathematica
<|
  "Status" -> "PASS" | "WARN" | "FAIL",
  "Summary" -> <|"PASS" -> ..., "WARN" -> ..., "FAIL" -> ...|>,
  "Checks" -> {...}
|>
```

Reports can be written with:

```mathematica
SVBAuditWriteReport[root, label, report]
```

### 4.2 Checks performed

| Stage | Checks |
|-------|--------|
| Source contracts | Required source files exist; master calls boundary, series, solve in order; series has all 12 expansion functions; boundary uses `RunAsymExpansionParallel`; solve uses the accumulated `sys` equations. |
| Input | Root and required files exist; `poleType` is `simple` or `double`; `lsBase` contains only cross-ratio variables; external conformal weights are consistent; ansatz and bases are non-empty lists. |
| Boundary | Six expected permutation files are present; permutation order is compatible with solve order; files import cleanly; each result is either `0` or `SeriesData` in `Y`; optional freshness check verifies files were produced after a given run start time. |
| Series | Twelve expected files are present; SV and MPL series lengths match `basisSV` and `basisMPL`; expressions import cleanly; z-like variables are not left over; optional prefactor table is recorded. |
| Solve | Solution imports as `{c[i] -> value, ...}`; no duplicate coefficients; every ansatz coefficient is solved; values contain no failed or infinite expressions; optional residual check substitutes the solution back into all six limits. |

### 4.3 Benchmark usage

For existing hard benchmark files:

```mathematica
root = "/path/to/workspace";
Get[FileNameJoin[{root, "audit_agent", "audit_agent.wl"}]];
basisSV = Import[FileNameJoin[{root, "allsvlist_fourloop.m"}]];
basisMPL = Import[FileNameJoin[{root, "allsvlistmpl_threeloop.m"}]];
ans1 = Import[FileNameJoin[{root, "threeloophard1_ans.m"}]];
ans2 = Import[FileNameJoin[{root, "threeloophard2_ans.m"}]];

AuditBoundaryStep[root, "I3Lhard", 3]
AuditBoundaryStep[root, "I3Lhardr", 3]
AuditBoundaryStep[root, "I3Lhardt", 3]

AuditSeriesStep[root, "threeloophard1", basisSV, basisMPL]
AuditSeriesStep[root, "threeloophard2", basisSV, basisMPL]

AuditSolveStep[root, "threeloophard1", ans1, basisSV, basisMPL, "VerifyResiduals" -> False]
AuditSolveStep[root, "threeloophard2", ans2, basisSV, basisMPL, "VerifyResiduals" -> False]
```

The audit agent supports the legacy benchmark names `threeloophard_svliste0uv.m` and `threeloophard_svliste0uv_2.m` when called with labels `threeloophard1` and `threeloophard2`.

---

## 5. Key Data Files

| File | Purpose |
|------|---------|
| `master_agent.wl` | Skill 0 orchestrator |
| `review_agent.wl` | Thin public wrapper for the review gate |
| `series_agent/series_agent.wl` | Skill 1: ansatz series expansion |
| `asym/boundary_agent/boundary_agent.wl` | Skill 2: boundary condition calculation |
| `solve_agent/solve_agent.wl` | Skill 3: coefficient solving |
| `audit_agent/audit_agent.wl` | Skill 4: post-step auditing and report generation |
| `audit_agent/run_hard_benchmark_review.wl` | One-shot runner for the hard benchmark review suite |
| `project_skills/ansatz_basis/SKILL.md` | Workspace-local skill for parity-even/odd ansatz basis construction |
| `ConformalWeight.m` | Conformal weight calculator (shared) |
| `svbwalkthrough.nb` | Main notebook with all algorithms |
| `allsvlist_fourloop.m` | SVHPL basis (list of elements) |
| `allsvliste0_uptow8.txt` | Series expansion of SVHPL basis at z→0 |
| `allsvliste1_uptow8.txt` | Series expansion of SVHPL basis at z→1 |
| `allsvlisteinf_uptow8.txt` | Series expansion of SVHPL basis at z→∞ |
| `allsvlistmpl_threeloop.m` | Complete MPL basis for 3-loop (82 elements) |
| `allsvlistmpl_threeloopharde0.txt` | Series expansion of MPL basis at z→0 |
| `allsvlistmpl_threeloopharde1.txt` | Series expansion of MPL basis at z→1 |
| `allsvlistmpl_threeloophardeinf.txt` | Series expansion of MPL basis at z→∞ |
| `svmplevenansatz_threeloop.m` | Even parity ansatz components |
| `svmploddansatz_threeloop.m` | Odd parity ansatz components |
| `threeloophard1_ans.m`, `threeloophard2_ans.m` | Hard topology ansatz with symbolic `c[i]` |
| `threeloophard1_sol.m`, `threeloophard2_sol.m` | Solved coefficient values |
| `resulthard3L.m` | Final 3-loop hard result |
| `asym/asym_new.wl` | Core asymptotic expansion engine |
| `checkI3Lhard*_order3_asyexp.m` | Boundary condition outputs (SeriesData in Y) |

---

## 6. Workflow Diagram

```
Skill 0 (master_agent.wl): orchestrates the pipeline (one integrand, one LS)

Input: Integrand + leading singularity + Ansatz (basis with symbolic c[i])
  |
  ├─ ConformalWeight.m → determines weightN = n
  |
  ├─ Skill 2 (asym/boundary_agent/boundary_agent.wl)
  |    |  - RunAsymExpansion for 6 permutations
  |    |  - RegionExpand, TensorReduce, IBPReduce
  |    |  - Series expansion in {u, 0} and {Y, 0, order}
  |    |  - Caches intermediate results in asym/tmp/ for reuse
  |    v
  |  Output: asym/boundary_agent/<label>*_asyexp.m
  |
  ├─ Skill 1 (series_agent/series_agent.wl)
  |    |  - Load pre-computed .txt files
  |    |  - Compute additional = base_transformed / F^(n-1)
  |    |  - 6 expansions (e0, e1, einf × straight/permuted)
  |    v
  |  Output: series_agent/<label>_svlist*.m
  |
  ├─ Skill 3 (solve_agent/solve_agent.wl)
  |    |  - Load series expansions + boundary conditions
  |    |  - setup = (c[i]).ansatz /. svrep
  |    |  - Build linear system, solve incrementally
  |    |  - Verify consistency
  |    v
  |  Output: solve_agent/<label>_sol.m
  |
  v
Output: Solved coefficients c[i]
```
