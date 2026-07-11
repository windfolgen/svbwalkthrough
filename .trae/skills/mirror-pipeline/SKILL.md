---
name: "mirror-pipeline"
description: "Implements the mirror symmetry pipeline for four-loop Feynman integral coefficient solving. Invoke when working on solve_agent_mirror_direct.wl or running mirror solve for SVB walkthrough project."
---

# Mirror Pipeline Skill

## Architecture (Current: Direct)

The `solve_agent_mirror_direct.wl` agent loads pre-computed ansatz expansions directly from
`data/allsvlist_fourloop_{ext}_{poleNum}.txt` files. These files already contain the full
ansatz series expansion (304 elements = all c[1..304] terms expanded in z/zz). The agent:

1. Loads the 304-element list from the appropriate `.txt` file
2. Applies f-replacement rules and zrep transformation to convert z/zz → u/Y
3. Series-expands each element to O(u⁰, Y^order) 
4. Dots with c/@Range[304] to form the setup expression
5. Builds equations from setup - targetData difference
6. Joins with standard `_partialsys.m` constraints and solves incrementally

**`series_agent_mirror.wl` is no longer needed** — the data files are pre-computed.

Data files:
```
data/allsvlist_fourloop_{ext}_{poleNum}.txt
```
where `{ext}` ∈ {e0, e0p, einf, einfp, e1, e1p} and `{poleNum}` ∈ {1, 2}.

All 12 files contain exactly 304 elements (matching total ansatz size).

Limit→ext mapping:
| Limit | suffix  | ext   |
|-------|---------|-------|
| 1     | e0uv    | e0    |
| 2     | e0uvp   | e0p   |
| 3     | einfuv  | einf  |
| 4     | einfuvp | einfp |
| 5     | e1uv    | e1    |
| 6     | e1uvp   | e1p   |

## Critical Rules

### DO NOT use Module-scoped `c`

The coefficient variable `c` (used in ansatz expressions `c[1]..c[N]`) must be Global`c`,
NOT a Module-scoped `c$NNN`. `_partialsys.m` stores equations with Global`c`. Mixing
`c$NNN` and `c` causes "Solve returned empty / system inconsistent" errors.

**Correct pattern:**
```mathematica
RunCoefficientSolvingMirror[...] :=
  Block[{c = Symbol["c"]},
  Module[{...},
    ...
  ]];
```

### Mirror Constraints vs Standard Constraints

**Mirror limits CAN overlap with standard workflow limits.** Mirror and standard constraints
are INDEPENDENT sets of equations that must be SIMULTANEOUSLY satisfied by the same
coefficient values. They expand the same limit through different code paths
(mirror: zrep transformation; standard: series substitution) and MUST be consistent.

If Solve returns empty (contradiction between standard + mirror constraints), this indicates
a bug in the transformation logic or data files — NOT an expected outcome.

## Limits that work for fourloopI173

Standard workflow: limits {1, 3, 5} produce 329 equations, 83 free variables (out of 304).
Mirror limits supplement additional constraints. Tested results:
- `$MirrorLimits = {6}` → 375 equations, 18 free variables (resolved 65 more)
