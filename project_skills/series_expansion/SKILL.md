---
name: series_expansion
description: >
  Expand the ansatz basis (SVHPL and MPL) at 3 singular points (z=0, z=1, z=∞)
  in 2 coordinate frames (straight uv and permuted uvp), producing 12 output files.
  Handles simple and double poles, conformal weight normalization, and MPL auto-detection.
---

# Ansatz Series Expansion (Skill 1)

## Agent File
[series_agent/series_agent.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/series_agent/series_agent.wl)

## Entry Point
```mathematica
RunSeriesExpansion[rootDir, label, config, lsBase, poleType, yOrder, svIndices, mplIndices, poleOrder, mplBasisFile]
```
- `rootDir` — project root
- `label` — run label (may include `_lsN` suffix for multi-LS runs)
- `config` — Association from [input_parser.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/input_parser.wl)
- `lsBase` — additional pole prefactor (e.g., `1`, `1/(1-u)`, `1/(1-v)`)
- `poleType` — `"simple"` or `"double"`
- `yOrder` — Y expansion order (4 for 3-loop, 5 for 4-loop)
- `svIndices` — pre-filtered SVHPL basis indices
- `mplIndices` — pre-filtered MPL basis indices
- `poleOrder` — 1 for simple, 2 for double
- `mplBasisFile` — auto-detected MPL basis path

## 6 Expansions (3 singular points × 2 coordinate frames)

| # | Limit | Suffix | u→rule | v→rule | F |
|---|-------|--------|--------|--------|---|
| 1 | z→0, straight | `e0uv` | `u→u` | `v→v` | 1 |
| 2 | z→0, permuted | `e0uvp` | `u→u/v` | `v→1/v` | v |
| 3 | z→∞, straight | `einfuv` | `u→1/u` | `v→v/u` | u |
| 4 | z→∞, permuted | `einfuvp` | `u→v/u` | `v→1/u` | u |
| 5 | z→1, straight | `e1uv` | `u→1/v` | `v→u/v` | v |
| 6 | z→1, permuted | `e1uvp` | `u→v` | `v→u` | 1 |

## Prefactor Logic

The leading singularity is decomposed into primary pole + additional pole:
```
LS = [primary pole] · [additional pole]
```

- **Primary pole** (`1/(z−zz)` or `1/(z−zz)²`): handled internally by `SeriesExpansion*` functions — not included in `lsBase`.
- **Additional pole** (e.g., `1/(1−u)`, `v/((1+u−v)²−4u)`): this is `lsBase`.
- **Normalization**: If the integrand has conformal weight `−n`, `n` powers of `x[1,3]x[2,4]` are implicit. Under permutation this contributes `F^n`.

Net prefactor for non-identity permutations:
```
additional = base_transformed / F^(n − poleOrder)
```

Where `F` is the permutation's transformation factor for `x[1,3]x[2,4]` (see table above).

## Data Files

| File | Purpose |
|------|---------|
| `data/allsvliste0_uptow8_inuv.txt` | SVHPL expansion at z→0, straight uv |
| `data/allsvliste0_uptow8_inuvp.txt` | SVHPL expansion at z→0, permuted uvp |
| `data/allsvliste1_uptow8_inuv.txt` | SVHPL expansion at z→1, straight uv |
| `data/allsvliste1_uptow8_inuvp.txt` | SVHPL expansion at z→1, permuted uvp |
| `data/allsvlisteinf_uptow8_inuv.txt` | SVHPL expansion at z→∞, straight uv |
| `data/allsvlisteinf_uptow8_inuvp.txt` | SVHPL expansion at z→∞, permuted uvp |
| `data/allsvlistmpl_*e0_inuv.txt` | MPL expansion at z→0, straight uv |
| `data/allsvlistmpl_*e0_inuvp.txt` | MPL expansion at z→0, permuted uvp |
| `data/allsvlistmpl_*e1_inuv.txt` | MPL expansion at z→1, straight uv |
| `data/allsvlistmpl_*e1_inuvp.txt` | MPL expansion at z→1, permuted uvp |
| `data/allsvlistmpl_*einf_inuv.txt` | MPL expansion at z→∞, straight uv |
| `data/allsvlistmpl_*einf_inuvp.txt` | MPL expansion at z→∞, permuted uvp |

SVHPL files are always `.txt` (string-wrapped lists). MPL files can be `.m` (expression lists, no parsing) or `.txt` (string-wrapped, needs parsing).

## Cache Skip

If all 12 output `.m` files exist and their lengths match the expected basis dimensions, the entire expansion is skipped. If lengths mismatch (stale cache from a different ansatz), files are regenerated.

## Output

12 files in `series_agent/`:
```
<label>_svliste0uv.m     <label>_svlistmple0uv.m
<label>_svliste0uvp.m    <label>_svlistmple0uvp.m
<label>_svliste1uv.m     <label>_svlistmple1uv.m
<label>_svliste1uvp.m    <label>_svlistmple1uvp.m
<label>_svlisteinfuv.m   <label>_svlistmpleinfuv.m
<label>_svlisteinfuvp.m  <label>_svlistmpleinfuvp.m
```

## Mirror Series Expansion (In Development)

[series_agent/series_agent_mirror.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/series_agent/series_agent_mirror.wl) provides mirror kinematics expansion. Not yet integrated into the main workflow. Tested via `test/mirror_full_run.wl`.
