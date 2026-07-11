# Hyperlog Series Expansion Skill

Calculate series expansions of single-valued MPLs using the Maple package HyperlogProcedures.

## Overview

There are **two kinds** of series expansions, distinguished by whether the additional factor is 1 or the leading singularity:

| Kind | Input | Additional Factor | Syntax | Reusable? | Used By |
|------|-------|-------------------|--------|-----------|---------|
| **Function expansion** | List of svMPL functions | `1` | `Series(el, z=0, zz, 7, 7)` | Yes — reusable across runs | Standard workflow (`data/` files) |
| **Ansatz expansion** | Ansatz (svMPL list) | Leading singularity `add` | `Series(el*add, z=0, zz, 7, 7)` | No — specific to one run | Mirror checks (e.g. `fourloopI173`) |

### Kind 1: Function Series Expansion

The input is a list of individual svMPL functions (e.g. `I[z,...,0]`, `f[...]`). The additional factor is **1**, so you directly perform the series expansion on each element:

```maple
Series(el, z = 0, zz, 7, 7)
```

Since no leading-singularity prefactor is involved, the output is purely a function expansion and **can be reused** across different calculations as long as the ansatz involves those svMPLs. The Mathematica `series_agent.wl` (Skill 1) applies the leading-singularity prefactor and kinematic substitutions at runtime.

This is the mode used for the pre-computed files under `data/`:

| Basis File | Description |
|------------|-------------|
| `allsvlist_fourloop.m` | SVHPLs up to weight 8 |
| `allsvlistmpl_threeloop.m` | svMPLs up to weight 6 (with `\bar{z}` letter) |
| `allsvlistmpl_fourloop_invzz.m` | svMPLs up to weight 8 (with `1/\bar{z}` letter) |

Each produces 6 output files (3 limits × 2 variants `_inuv` / `_inuvp`), as described in [README.md](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/README.md).

### Kind 2: Ansatz Series Expansion

The input is the full ansatz. The additional factor is **not** 1 — you directly multiply the leading singularity onto each element before expanding:

```maple
Series(el * add, z = 0, zz, 7, 7)
```

This produces the series expansion of the ansatz directly, including the leading-singularity prefactor. The output is **specific to one run** and cannot be reused.

This mode is used when **mirror checks** are performed, for example `fourloopI173`. The rest of this document describes this mode in detail.

---

## Prerequisites

- Maple 2023+ with HyperlogProcedures
- `HyperlogProcedures` and `cachedatamine.m` in the working directory (e.g., `/home/ana/maple/HyperlogProcedures08/`)
- Ansatz files in Wolfram Language `.m` format

## Input Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `ansatz_even` | Path to even ansatz file | `svlistevenansatz_w8.m` |
| `ansatz_odd` | Path to odd ansatz file | `svlistoddansatz_w8.m` |
| `output_dir` | Directory for output files | `testfourloopI173/` |
| `order` | Series expansion order (n, nn) | `7` |
| `z_point` | Expansion point | `0`, `1`, or `infinity` |
| `calculations` | List of `{name, factor}` pairs | See below |

## Factor Expressions

Factors are Maple expressions in variables `z` and `zz` representing the leading singularity:

| Factor | Description |
|--------|-------------|
| `1/(z-zz)` | Simple pole |
| `(-2+z+zz)/(z-zz)^2` | Double pole with numerator |
| `1/(z-zz)/(1-z)/(1-zz)` | Pole with (1-z)(1-zz) |
| `1/(z-zz)/(z*zz)` | Pole with z*zz denominator |

## Maple Script Structure

```maple
read "/path/to/HyperlogProcedures":
kernelopts(numcpus = 1):

# Read ansatz files — use FileTools[Text][ReadFile], NOT Import
strEven := FileTools[Text][ReadFile]("/path/to/svlistevenansatz_w8.m"):
strOdd := FileTools[Text][ReadFile]("/path/to/svlistoddansatz_w8.m"):
SVListEven := parse(strEven):
SVListOdd := parse(strOdd):
SVList := [op(SVListEven), op(SVListOdd)]:
printf("Processing %a elements\n", nops(SVList)):

# --- Calculation 1 ---
L0_1 := []:
for el in SVList do
  L0_1 := [op(L0_1), Series(el*add, z = 0, zz, 7, 7)];
end do:
Export("/path/to/output/e0_1.txt", convert(L0_1, string)):
printf("Done e0_1\n"):

# --- Calculation 2 ---
L0_2 := []:
for el in SVList do
  L0_2 := [op(L0_2), Series(el*add2, z = 0, zz, 7, 7)];
end do:
Export("/path/to/output/e0_2.txt", convert(L0_2, string)):
printf("Done e0_2\n"):

# ... more calculations ...

printf("All done.\n"):
```

## Important Notes

1. **Run from HyperlogProcedures directory**: The script must execute from the directory containing `HyperlogProcedures` and `cachedatamine.m`, otherwise cache files won't be found.

2. **Use FileTools[Text][ReadFile]**: Wolfram `.m` files must be read with `FileTools[Text][ReadFile]` then `parse()`. `Import()` fails on these files.

3. **Parallel execution**: Different z-points (e0, e1, einf) can run in parallel. Each script handles one z-point with multiple factors.

4. **Identical factors**: If two outputs have identical factors (e.g., `einf_1` and `einfp_1`), compute once and copy the output file rather than recalculating.

## Example: Four-Loop I173 Mirror Check (Kind 2)

### e0 (z = 0)
```
e0_1:     factor = 1/(z-zz)
e0_2:     factor = (-2+z+zz)/(z-zz)^2
e0p_1:    factor = 1/(z-zz)/(1-z)/(1-zz)
e0p_2:    factor = (-2+z+zz)/(z-zz)^2/(1-z)/(1-zz)
```

### e1 (z = 1)
```
e1_1:     factor = 1/(z-zz)/(1-z)/(1-zz)
e1_2:     factor = (-2+z+zz)/(z-zz)^2/(1-z)/(1-zz)
e1p_1:    factor = 1/(z-zz)
e1p_2:    factor = (-2+z+zz)/(z-zz)^2
```

### einf (z = infinity)
```
einf_1:   factor = 1/(z-zz)/(z*zz)
einf_2:   factor = (-2+z+zz)/(z-zz)^2/(z*zz)
```
Note: `einfp_1` = `einf_1` and `einfp_2` = `einf_2` — just copy the files.

## Bash Runner Script

```bash
#!/bin/bash
HP_DIR="/home/ana/maple/HyperlogProcedures08"
MAPLE="/home/ana/maple2023/bin/maple"
SCRIPT_DIR="/path/to/scripts"
OUT_DIR="/path/to/output"

# Run e0
cd ${HP_DIR} && ${MAPLE} ${SCRIPT_DIR}/calc_series_e0.mpl > ${OUT_DIR}/e0.log 2>&1 &

# Run e1
cd ${HP_DIR} && ${MAPLE} ${SCRIPT_DIR}/calc_series_e1.mpl > ${OUT_DIR}/e1.log 2>&1 &

# Run einf
cd ${HP_DIR} && ${MAPLE} ${SCRIPT_DIR}/calc_series_einf.mpl > ${OUT_DIR}/einf.log 2>&1 &
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `could not open cachedatamine.m` | Run from directory containing HyperlogProcedures |
| `Import` fails on .m files | Use `FileTools[Text][ReadFile]` + `parse()` |
| Series hangs | Check that z_point matches factor singularities |
| Very large output files | Normal for order-7 expansions of 300+ elements |
