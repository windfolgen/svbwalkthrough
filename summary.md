# SVB Walkthrough — Summary

## Overview

This project implements a **bootstrap method for computing multi-loop Feynman integrals** via leading singularities. The pipeline:

1. Computes leading singularities of an integrand
2. Constructs an ansatz from a basis of transcendental functions (SVHPL/MPL)
3. Fixes ansatz coefficients by matching to boundary conditions at 6 limits

## Directory Structure

```
.                             (project root)
├── workflow_engine.wl        — Main orchestration engine (Skill 0)
├── input_parser.wl           — parses runs/<label>/input.wl into config Association
├── config.wl                 — Fixed global configuration
├── review_agent.wl           — Facade for audit stage checks
├── ConformalWeight.m         — Conformal weight calculator (shared)
├── data/                     — Pre-expanded series bases (.txt and .m)
├── series_agent/
│   ├── series_agent.wl       — Skill 1: ansatz series expansion (Mathematica)
│   └── series_agent_mirror.wl — Mirror expansion (in development)
├── asym/
│   ├── asym_new.wl           — Core asymptotic expansion engine
│   ├── Bases/                — LiteRed2 IBP bases
│   ├── tmp/                  — Cached tensor/IBP results (reusable)
│   └── boundary_agent/
│       └── boundary_agent.wl — Skill 2: boundary condition calculation
├── solve_agent/
│   ├── solve_agent.wl        — Skill 3: coefficient solving
│   └── solve_agent_mirror.wl — Mirror solving (in development)
├── audit_agent/
│   └── audit_agent.wl        — Skill 4: pre-flight and post-stage audits
├── runs/                     — Per-problem run directories
│   └── <label>/
│       ├── input.wl          — integrand, leading singularity, ansatz
│       ├── run.wl            — bootstrap script
│       ├── run.log           — execution log
│       ├── result.m          — final expanded ansatz × coefficients
│       └── coeff_sol.m       — partitioned coefficient values
└── project_skills/
    ├── system/               — Operational rules (always loaded first)
    ├── workflow/             — How to orchestrate the pipeline
    ├── boundary_calculation/ — Skill 2 details
 │   ├── series_expansion/     — Skill 1 details (Mathematica + Maple hyperlog)
    ├── coefficient_solving/  — Skill 3 details
    └── ansatz_basis/         — How to construct ansatz bases
```

## Pipeline Overview

See [project_skills/workflow/SKILL.md](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/project_skills/workflow/SKILL.md) for the full orchestration guide.

```
ParseInput → ReviewGate["preflight"]
          → ReviewGate["preboundary"]
          → Skill 2: Boundary Conditions  (boundary_calculation)
          → ReviewGate["boundary"]
          → ReviewGate["preseries"]
          → Skill 1: Series Expansion     (series_expansion)
          → ReviewGate["series"]
          → ReviewGate["presolve"]
          → Skill 3: Coefficient Solving  (coefficient_solving)
          → ReviewGate["solve"]
```

### Skill Details

| Skill | Agent File | Skill File |
|-------|-----------|------------|
| Skill 1: Series Expansion (Mathematica) | [series_agent.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/series_agent/series_agent.wl) | [SKILL.md](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/project_skills/series_expansion/SKILL.md) |
| Series Expansion (Maple/Hyperlog) | — (external Maple script) | [SKILL_hyperlog_series_expansion.md](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/project_skills/series_expansion/SKILL_hyperlog_series_expansion.md) |
| Skill 2: Boundary Conditions | [boundary_agent.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/asym/boundary_agent/boundary_agent.wl) | [SKILL.md](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/project_skills/boundary_calculation/SKILL.md) |
| Skill 3: Coefficient Solving | [solve_agent.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/solve_agent/solve_agent.wl) | [SKILL.md](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/project_skills/coefficient_solving/SKILL.md) |
| Skill 4: Audit | [audit_agent.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/audit_agent/audit_agent.wl) | — (integrated into workflow orchestration) |

### Mirror Series & Solve (In Development)

Mirror kinematics agents exist but are not yet integrated into the main workflow engine:
- [series_agent/series_agent_mirror.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/series_agent/series_agent_mirror.wl)
- [solve_agent/solve_agent_mirror.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/solve_agent/solve_agent_mirror.wl)

Tested via: `MathKernel -noprompt -script test/mirror_full_run.wl`

## Prefactor & Permutation Reference Tables

### Conformal Weight & Normalization

The **conformal weight** `n` of the integrand determines how the prefactor transforms under external leg permutations. Compute it at external vertex 1:

```mathematica
n = -ConformalWeight[integrand, 1]
```

- **`n = 0`**: integrand is **not** normalized — no implicit `x[1,3]x[2,4]`.
- **`n > 0`**: integrand has `n` implicit powers of `x[1,3]x[2,4]` absorbed into the measure. Under permutation, the normalization contributes `F^n`.

**CRITICAL**: Always evaluate conformal weight at an **external vertex** (1, 2, 3, or 4). Evaluating at a loop vertex (5, 6, 7) returns the wrong weight and introduces spurious poles.

### Prefactor Decomposition

Decompose the leading singularity into **primary pole** + **additional pole**:

```
LS = [primary pole] · [additional pole]
```

- **Primary pole**: `1/(z−zz)^k` — handled internally by `SeriesExpansion*`. `k = 1` for simple, `k = 2` for double.
- **Additional pole**: everything else (e.g., `1/(1−u)`, `v/((1+u−v)²−4u)`). This is `base`.
- **Normalization**: `x[1,3]^n x[2,4]^n` contributes `F^n` under permutation.

Net prefactor for non-identity permutations:

```
additional = base_transformed / F^(n−k)
```

For the identity permutation, `F = 1`, so `additional = base_transformed`.

### Decomposition Examples

| Leading Singularity | Primary Pole (k) | Additional Pole (base) |
|---|---|---|
| `1/(z−zz)` | `1/(z−zz)`, k=1 | `1` |
| `1/((z−zz)(1−u))` | `1/(z−zz)`, k=1 | `1/(1−u)` |
| `1/((z−zz)(1−v))` | `1/(z−zz)`, k=1 | `1/(1−v)` |
| `1/(z−zz)²` | `1/(z−zz)²`, k=2 | `1` |
| `v/(z−zz)³` | `1/(z−zz)`, k=1 | `v/((1+u−v)²−4u)` |

### Normalization Factor F

The permutation transforms `x[1,3]x[2,4] → x[σ(1),σ(3)]x[σ(2),σ(4)]`. The ratio `F = [transformed] / [original]`:

| Permutation | Rule | x[1,3]x[2,4] → | F |
|---|---|---|---|
| `{1,2,3,4}` | identity | `x[1,3]x[2,4]` | **1** |
| `{2,1,3,4}` | `{1↔2}` | `x[2,3]x[1,4]` | **v** |
| `{3,2,1,4}` | `{1↔3}` | `x[3,1]x[2,4]` = `x[1,3]x[2,4]` | **1** |
| `{1,3,2,4}` | `{2↔3}` | `x[1,2]x[3,4]` | **u** |
| `{2,3,1,4}` | `{1→2, 2→3, 3→1}` | `x[2,1]x[3,4]` = `x[1,2]x[3,4]` | **u** |
| `{3,1,2,4}` | `{1→3, 3→2, 2→1}` | `x[3,2]x[1,4]` = `x[2,3]x[1,4]` | **v** |

where `u = x[1,2]x[3,4] / (x[1,3]x[2,4])`, `v = x[1,4]x[2,3] / (x[1,3]x[2,4])`.

### Complete Six-Expansion Table

Example: leading singularity `1/((z−zz)(1−u))`, weight `n`:

| # | Perm | Limit | SeriesExpansion | F | n=1 Prefactor | n=2 Prefactor |
|---|---|---|---|---|---|---|
| 1 | `{1,2,3,4}` | e0uv | `SeriesExpansion0` | 1 | `1/(1−u)` | `1/(1−u)` |
| 2 | `{2,1,3,4}` | e0uvp | `SeriesExpansion0P` | v | `v/(v−u)` | `1/(v−u)` |
| 3 | `{1,3,2,4}` | einfuv | `SeriesExpansionInf` | u | `u/(u−1)` | `1/(u−1)` |
| 4 | `{2,3,1,4}` | einfuvp | `SeriesExpansionInfP` | u | `u/(u−v)` | `1/(u−v)` |
| 5 | `{3,1,2,4}` | e1uv | `SeriesExpansion1` | v | `v/(v−1)` | `1/(v−1)` |
| 6 | `{3,2,1,4}` | e1uvp | `SeriesExpansion1P` | 1 | `1/(1−v)` | `1/(1−v)` |

**Consistency check**: The series expansion of the **ansatz** (Skill 1) must match the series expansion of the **integrand** (Skill 2). Both derive their `additional` prefactor from the same logic: conformal weight → `n`, decompose LS → `base`, transform → `additional = base_transformed / F^(n−k)`.

### Permutation Transformation Rules

The 6 permutations of external legs correspond to the anharmonic group acting on the cross-ratio `z`:

| Permutation | Rule | z → | u → | v → |
|---|---|---|---|---|
| `{1,2,3,4}` | identity | `z` | `u` | `v` |
| `{3,2,1,4}` | `{1↔3}` | `1−z` | `v` | `u` |
| `{1,3,2,4}` | `{2↔3}` | `1/z` | `1/u` | `v/u` |
| `{3,1,2,4}` | `{1→3, 3→2, 2→1}` | `1/(1−z)` | `1/v` | `u/v` |
| `{2,3,1,4}` | `{1→2, 2→3, 3→1}` | `1−1/z` | `v/u` | `1/u` |
| `{2,1,3,4}` | `{1↔2}` | `z/(z−1)` | `u/v` | `1/v` |

### 6 Expansions — Coordinate Mappings

| # | Limit | Suffix | u → rule | v → rule | F |
|---|---|---|---|---|---|
| 1 | z→0, straight | `e0uv` | `u→u` | `v→v` | 1 |
| 2 | z→0, permuted | `e0uvp` | `u→u/v` | `v→1/v` | v |
| 3 | z→∞, straight | `einfuv` | `u→1/u` | `v→v/u` | u |
| 4 | z→∞, permuted | `einfuvp` | `u→v/u` | `v→1/u` | u |
| 5 | z→1, straight | `e1uv` | `u→1/v` | `v→u/v` | v |
| 6 | z→1, permuted | `e1uvp` | `u→v` | `v→u` | 1 |

## Run Convention

Each problem lives in `runs/<label>/`:
- `input.wl` — defines integrand, leading singularity, ansatz
- `run.wl` — bootstrap script connecting all skills

After a run, `run.log`, `result.m`, and `coeff_sol.m` are written into the run folder.

### Loop-Order Convention

| Loops | `order` (boundary + solve) | `yOrder` (series Y) | Internal points |
|-------|-----|------|----------------|
| 3-loop | 3 | 4 | `{5,6,7}` |
| 4-loop | 4 | 5 | `{5,6,7,8}` |

## Proven Runs

### three-loop
| Label | LS | Weight | Ansatz | Non-zero coeffs |
|-------|----|--------|--------|----------------|
| `threeloopI5` | `1/((z−zz)(1−v))` | 2 | odd (30) | 19 |
| `threeloopI8` | `v/(z−zz)³` | 2 | odd (30) | 10 |
| `threeloophard1` | `1/(z−zz)²` (double) | 2 | even (57) | 26 |
| `threeloophard2` | `1/((z−zz)(1−v))` | 2 | even (43) | 30 |

### four-loop
| Label | LS | Weight | Ansatz | Non-zero coeffs |
|-------|----|--------|--------|----------------|
| `fourloopI41` | `1/((z−zz)(1−u))` | 2 | 146 | 105 |
| `fourloopI42` | multi-component | 2 | 2×146 | — |

## Key Data Files

| File | Purpose |
|------|---------|
| `data/allsvlist_fourloop.m` | Full SVHPL basis (510 elements) |
| `data/allsvliste*_uptow8_inuv*.txt` | SVHPL series expansions (6 files) |
| `data/allsvlistmpl_*.m` | MPL basis files (auto-detected) |
| `data/allsvlistmpl_*e*_inuv*.txt` | MPL series expansions (auto-detected) |
| `asym/tmp/targetIntegrals_reduced.m` | Shared target integrals cache (keep) |
| `asym/tmp/cache_tensor_record_noremove.mx` | Persistent tensor cache (keep) |

## Key Fixes Baked into Agents

| Fix | Agent |
|-----|-------|
| `preflight → preboundary → boundary → preseries → series → presolve → solve` audit pipeline | workflow_engine, audit_agent |
| MPL `.m` vs `.txt` format auto-detection | series_agent |
| IBP output redirection via `"IBPDir"` option | boundary_agent |
| `additional = base_transformed / F^(weightN − poleOrder)` | workflow_engine, series_agent |
| `poleOrder` auto-derived from `poleType` | workflow_engine |
| Permutation order hardcoded (not lexicographic) in `$Perms` | config.wl |
| Boundary skip: detect existing files or integrand cache | boundary_agent |
| `Normal[...]` in `temp` computation | solve_agent |
| `// Simplify` in verification (not raw structural equality) | solve_agent |
| Empty `temp` skip (don't build equations from vanishing limits) | solve_agent |
| `cVars` extraction by `StringStartsQ[SymbolName[Head[#]], "c"] &` | solve_agent |
| Filter `True \| False` from `sys1` | solve_agent |
| `f[a_,a_]:>f[a]^2/2` simplification in final result | solve_agent |
