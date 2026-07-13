---
name: coefficient_solving
description: >
  Solve for the unknown coefficients c[i] by constructing a linear system from
  boundary target data and series expansions. Incrementally solves across 6 limits,
  propagates partial solutions, and exports result.m, coeff_sol.m to the run folder.
---

# Coefficient Solving (Skill 3)

## Agent File
[solve_agent/solve_agent.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/solve_agent/solve_agent.wl)

## Entry Point
```mathematica
RunCoefficientSolving[rootDir, label, config, ansatzList, labelsList, basisSVList, basisMPLList, targetData, order]
```
- `rootDir` — project root
- `label` — run label
- `config` — Association from [input_parser.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/input_parser.wl)
- `ansatzList` — list of ansatz expressions (one per leading singularity)
- `labelsList` — list of labels for series file lookup
- `basisSVList` — list of SVHPL basis elements (one per LS)
- `basisMPLList` — list of MPL basis elements (one per LS)
- `targetData` — list of 6 boundary expressions (from Skill 2)
- `order` — Y expansion truncation order

## Input: targetData

Loaded from boundary files in this exact order (matching `$Perms`):

| Position | Permutation | Limit suffix | File |
|----------|-------------|-------------|------|
| 1 | `{1,2,3,4}` | e0uv | `<label>1234_order<order>_asyexp.m` |
| 2 | `{2,1,3,4}` | e0uvp | `<label>2134_order<order>_asyexp.m` |
| 3 | `{1,3,2,4}` | einfuv | `<label>1324_order<order>_asyexp.m` |
| 4 | `{2,3,1,4}` | einfuvp | `<label>2314_order<order>_asyexp.m` |
| 5 | `{3,1,2,4}` | e1uv | `<label>3124_order<order>_asyexp.m` |
| 6 | `{3,2,1,4}` | e1uvp | `<label>3214_order<order>_asyexp.m` |

Apply `// Normal` on import to strip `SeriesData` wrappers.

## Incremental Solve Process

For each of the 6 limits (i=1..6):

1. **Setup**: Substitute series expansions into ansatz, combine with partial solution `solt`:
   ```mathematica
   setup = Sum[(c/@Range[offset+1, offset+lenK]) . (ansatzK /. svrepK)] /. solt
   ```
2. **Compute temp**: Difference between `setup` and `targetData[[i]]`, map `f→Zeta`, `MonomialList` in `{Log[u]}`:
   ```mathematica
   temp = MonomialList[Normal[setup - targetData[[i]]] /. {f[a_]:>Zeta[a], ...}, {Log[u]}]
   ```
3. **If `temp === {}`**: This limit provides no constraints — skip to next limit.
4. **Extract coefficients** (temp1): Replace `Log[u]→1`, negative `Y`/`u` powers → `invY`/`invu`, `MonomialList` in `{u,Y,invY,invu}`, restore `Y→1`, `invY→1`, `invu→1`.
5. **Build equations** (sys1): Replace `Zeta[n]→zn`, `Pi→pi`, `MonomialList` in `{z3,z5,z7,f[5,3],pi}`, restore to 1, `Thread@Equal[...,0]`, flatten, delete `True|False|0`.
6. **Incremental join and solve**:
   ```mathematica
   sys = Join[sys, sys1];
   varsList = Select[Variables[sys[[All,1]]], _[_] && StringStartsQ[SymbolName[Head[#]], "c"] &];
   solt = Solve[sys, varsList][[1]];
   ```

## Verification

After all 6 limits are solved, substitute `solt` back into `setup` for each limit and check that the difference simplifies to zero:
```mathematica
temp = Normal[setup - targetData[[i]]] /. {f[a_]:>Zeta[a], ...} // Simplify;
If[temp =!= 0, Print["Limit ", i, " mismatch: ", InputForm[temp]]];
```

Use `// Simplify` — not raw structural equality — because unsimplified polylogarithms/zeta expressions evaluate to `False` even when algebraically zero.

## Output

| File | Content |
|------|---------|
| `solve_agent/<label>_sol.m` | Raw solved substitution rules `{c[1]→val1, c[2]→val2, ...}` |
| `solve_agent/<label>_partialsys.m` | Full equation system |
| `solve_agent/<label>_freevars.m` | `{{missingCoeffs}, {unsolvedVars}}` |
| `runs/<label>/result.m` | Final list: `{coeff1·ansatz1, coeff2·ansatz2, ...}` (simplified: `f[a,a]→f[a]^2/2`) |
| `runs/<label>/coeff_sol.m` | Partitioned coefficient values, one sublist per LS |

## Key Fixes

- `Normal[...]` must be used when computing `temp` to avoid SeriesData/Normal subtraction errors.
- `// Simplify` must be used in verification — not `temp =!= 0` on raw expressions.
- `cVars` extraction filters by `StringStartsQ[SymbolName[Head[#]], "c"] &` to exclude `I[z,...]`, `u`, `Y`, `Log[u]`.
- Empty `temp` skip: don't build equations from vanishing limits.
- Filter `True | False` from `sys1`.

## Mirror Solve

The mirror stage extends the standard solve when free parameters remain. Only **one** mirror implementation is active and validated:

- **ACTIVE**: [project_skills/mirror_solve_direct/SKILL.md](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/project_skills/mirror_solve_direct/SKILL.md) — `solve_agent/solve_agent_mirror_direct.wl`, validated on `fourloopI173` (all 6 limits, 304/304 solved, 0 benchmark violations).

The following mirror files are **under development / not active** and have not been validated end-to-end:

| File | Status |
|------|--------|
| [solve_agent/solve_agent_mirror.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/solve_agent/solve_agent_mirror.wl) | Under development — superseded by `solve_agent_mirror_direct.wl` |
| [series_agent/series_agent_mirror.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/series_agent/series_agent_mirror.wl) | Under development |
| [transform/transform_mirror.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/transform/transform_mirror.wl) | Under development |
| [transform/generate_sv_mirror.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/transform/generate_sv_mirror.wl) | Under development |
| [transform/threeloop_generate_mpl_mirror.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/transform/threeloop_generate_mpl_mirror.wl) | Under development |
| [transform/fourloop_generate_all_zrep_mirror.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/transform/fourloop_generate_all_zrep_mirror.wl) | Under development |
