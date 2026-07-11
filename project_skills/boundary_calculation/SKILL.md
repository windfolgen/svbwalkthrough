---
name: boundary_calculation
description: >
  Compute boundary conditions for a given integrand by running LiteRed2 IBP reduction
  and asymptotic expansion across all 6 S4 permutations. Outputs SeriesData in Y.
  Supports cache reuse, integrand matching, and IBP output redirection.
---

# Boundary Condition Calculation (Skill 2)

## Agent File
[asym/boundary_agent/boundary_agent.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/asym/boundary_agent/boundary_agent.wl)

## Entry Point
```mathematica
RunBoundaryConditions[rootDir, label, config, order, opts]
```
- `rootDir` — project root
- `label` — run label
- `config` — Association from [input_parser.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/input_parser.wl)
- `order` — expansion order (3 for 3-loop, 4 for 4-loop)

### Options
- `"InputDir" -> None` — alternative directory for pre-computed boundary files (e.g., `runs/<label>/boundaries/`)
- `"IBPDir" -> Automatic` — external directory for LiteRed2 IBP `.mx` caches

## Skip Logic

Before computing, the agent checks in this order:
1. **Existing output files**: If all 6 `<label><perm>_order<order>_asyexp.m` exist in `asym/boundary_agent/`, skip.
2. **Integrand cache**: Checks `calculated_integrands.m` for a previously computed matching integrand. If found, loads, scales, and saves.
3. **InputDir**: If files exist in `"InputDir"`, copies them to `asym/boundary_agent/` and skips.

## Process

1. Load LiteRed2, set kinematics (`SetDim[d]`, `Declare[{l1,l2,l3,l4,p}, Vector]`)
2. Load bases from `asym/Bases/{asym, asym3L, asym2L, asym1L}`
3. `LaunchKernels[6]`, load `asym/asym_new.wl` on master and parallels
4. Redirect CWD to `"IBPDir"` so LiteRed2 writes `.mx` caches externally
5. `RunAsymExpansionParallel[label, $Integrand, perms, order, loopPoints]`
   - For each permutation, selects the coordinate exchange representation that minimizes `ToTensorProduct` terms
   - Uses persistent global tensor caching via `asym/tmp/cache_tensor_record_noremove.mx`
6. Restore CWD, relocate `check<label>*` files to `asym/boundary_agent/<label><perm>_order<order>_asyexp.m`
7. Update `calculated_integrands.m` association

## Output

6 files in `asym/boundary_agent/`:
```
<label>1234_order<order>_asyexp.m
<label>2134_order<order>_asyexp.m
<label>1324_order<order>_asyexp.m
<label>2314_order<order>_asyexp.m
<label>3124_order<order>_asyexp.m
<label>3214_order<order>_asyexp.m
```

Each file contains `SeriesData` in `Y` with coefficients that are functions of `u`.

## Permutation Solving Order

The 6 permutations follow a strict order (not lexicographic) aligned with limit proximity:
1. `{1,2,3,4}` — u→0, straight
2. `{2,1,3,4}` — u→0, permuted
3. `{1,3,2,4}` — u→∞, straight
4. `{2,3,1,4}` — u→∞, permuted
5. `{3,1,2,4}` — u→1, straight
6. `{3,2,1,4}` — u→1, permuted

This order is hardcoded in [config.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/config.wl) `$Perms` and must not be changed.

## Performance: Symmetry Selection

The integrand is invariant under coordinate exchanges `{1↔3, 2↔4}`, `{1↔2, 3↔4}`, `{1↔4, 2↔3}`. For each of the 6 permutations, the orchestrator evaluates all 4 symmetry cases and selects the one that minimizes `Length[ToTensorProduct[...]]` (the true tensor reduction bottleneck), not `RegionExpand` term count.

## Cached Files

- `asym/tmp/targetIntegrals_reduced.m` — shared across runs, always keep
- `asym/tmp/cache_tensor_record_noremove.mx` — persistent global tensor cache
- External `"IBPDir"` — LiteRed2 .mx IBP caches, kept outside workspace
