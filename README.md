# SVB Walkthrough — Bootstrap Feynman Integrals

This project implements a **bootstrap method for computing multi-loop Feynman integrals** via leading singularities. Given an integrand, a leading singularity, and an ansatz of transcendental functions, the pipeline computes the exact coefficients via series expansion, boundary conditions, and linear solving.

See [summary.md](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/summary.md) for the full technical overview and [init.md](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/init.md) for how to start working in this workspace.

---

## Prerequisites — Dependency Installation

### LiteRed2

LiteRed2 is a Mathematica package for multiloop IBP (Integration-By-Parts) reduction. The boundary condition agent (Skill 2) requires it.

- Repository: [https://github.com/rparnam/LiteRed2](https://github.com/rparnam/LiteRed2)
- Installation: clone the repository and add its directory to Mathematica's `$Path`.

```mathematica
(* Add to init.m or run before loading workflow *)
AppendTo[$Path, "/path/to/LiteRed2"];
```

Verify installation:
```mathematica
Get["LiteRed2`"];
Print[$Packages];  (* should include "LiteRed`" *)
```

### FiniteFlow *(Optional)*

FiniteFlow is a C++ library for numerical evaluation over finite fields and multivariate rational function reconstruction, with a Mathematica interface. **Not required** — the pipeline runs fine without it; a warning is printed but execution continues.

If you want to install it:
- Repository: [https://github.com/peraro/finiteflow](https://github.com/peraro/finiteflow)
- Requires: CMake, GMP, FLINT (or [flint-finiteflow-dep](https://github.com/peraro/flint-finiteflow-dep))

```bash
git clone https://github.com/peraro/finiteflow.git
cd finiteflow
cmake . && make install
```

On Apple Silicon Macs add `-DCMAKE_OSX_ARCHITECTURES=arm64` to the `cmake` command.

---

## Leading Singularity Analysis (`leadingsingularity/`)

The `leadingsingularity/` subfolder is a self-contained Mathematica module for computing the leading singularities of planar multi-loop integrands via the method of maximal cuts. It provides:

- **`LeadingSingularities[integrand, opts]`** — the human-facing driver, printing a coloured step-by-step trace for inspection.
- **`LeadingSingularityAssist[integrand, opts]`** — an AI-friendly wrapper (same algorithm, structured `Association` output with classified warnings and higher-pole / elliptic-cut feature flags).
- Integrand data: `threeloopint.m` (15 basis), `fourloopint.m` (412 basis).
- Batch summary scripts (`summary_3L.wl`, `summary_4L.wl`) that produce JHEP-style PDF reports.

> **This package assists leading singularity analysis; it does not replace it.** The user should read and check the intermediate prints (warnings, higher-pole / elliptic-cut messages).

See [leadingsingularity/README.md](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/leadingsingularity/README.md) for usage details and [leadingsingularity/leadingsingularity.md](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/leadingsingularity/leadingsingularity.md) for the full workflow documentation.

---

## Function Series Expansion (User-Provided)

These are series expansion data for svMPL functions appearing in the ansatz, pre-calculated by the user using the Maple package **Hyperlogprocedures** and stored as text files under `data/`. The workflow's `series_agent.wl` (Skill 1) loads these files, applies the leading-singularity prefactor and kinematic substitutions, and produces the final per-run series coefficients.

For details on the Maple expansion procedure, see [project_skills/series_expansion/SKILL_hyperlog_series_expansion.md](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/project_skills/series_expansion/SKILL_hyperlog_series_expansion.md).

### Naming Convention

Each basis has **6 series expansion files** — one for each combination of:

| Limit | Suffix | Description |
|-------|--------|-------------|
| `z → 0` | `e0` | Expansion around z=0 |
| `z → 1` | `e1` | Expansion around z=1 |
| `z → ∞` | `einf` | Expansion at infinity |

× two variants per limit:

The `_inuv` / `_inuvp` distinction corresponds to the two S₄ permutations used at each limit point. They differ in how the cross-ratios `u`, `v` are transformed:

| Variant | Suffix | Permutation | Description |
|---------|--------|-------------|-------------|
| straight | `_inuv` | identity `{1,2,3,4}` | Direct expansion in `u`, `v` |
| permuted | `_inuvp` | `{2,1,3,4}` (`1↔2`) | Expansion after swapping external legs 1↔2 |

The full 6-expansion coordinate mappings (3 limits × 2 variants):

| # | Limit | Suffix | u → | v → | F |
|---|-------|--------|-----|-----|---|
| 1 | z→0, straight | `e0uv` (`_inuv`) | `u` | `v` | 1 |
| 2 | z→0, permuted | `e0uvp` (`_inuvp`) | `u/v` | `1/v` | v |
| 3 | z→∞, straight | `einfuv` (`_inuv`) | `1/u` | `v/u` | u |
| 4 | z→∞, permuted | `einfuvp` (`_inuvp`) | `v/u` | `1/u` | u |
| 5 | z→1, straight | `e1uv` (`_inuv`) | `1/v` | `u/v` | v |
| 6 | z→1, permuted | `e1uvp` (`_inuvp`) | `v` | `u` | 1 |

where `F` is the normalization factor from the permutation (see [summary.md](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/summary.md) for details).

### Current Basis Files in `data/`

#### 1. `allsvlist_fourloop.m` — SVHPLs up to weight 8

Pure single-valued harmonic polylogarithms. Used as the default SVHPL basis for all 4-loop runs.

Series expansion files:

| Limit | Straight (`_inuv`) | Permuted (`_inuvp`) |
|-------|--------------------|---------------------|
| z→0 (`e0`) | `allsvliste0_uptow8_inuv.txt` | `allsvliste0_uptow8_inuvp.txt` |
| z→1 (`e1`) | `allsvliste1_uptow8_inuv.txt` | `allsvliste1_uptow8_inuvp.txt` |
| z→∞ (`einf`) | `allsvlisteinf_uptow8_inuv.txt` | `allsvlisteinf_uptow8_inuvp.txt` |

*(Mirror-variant files with pole-order suffix: `allsvlist_fourloop_{e0,e1,einf}_{1,2}_order5.txt`)*

#### 2. `allsvlistmpl_threeloop.m` — svMPLs up to weight 6

Single-valued multiple polylogarithms. The **last two entries** introduce a new letter `\bar{z}` (complex conjugate of z) not present in the SVHPL basis.

Series expansion files:

| Limit | Straight (`_inuv`) | Permuted (`_inuvp`) |
|-------|--------------------|---------------------|
| z→0 (`e0`) | `allsvlistmpl_threeloope0_inuv.txt` | `allsvlistmpl_threeloope0_inuvp.txt` |
| z→1 (`e1`) | `allsvlistmpl_threeloope1_inuv.txt` | `allsvlistmpl_threeloope1_inuvp.txt` |
| z→∞ (`einf`) | `allsvlistmpl_threeloopeinf_inuv.txt` | `allsvlistmpl_threeloopeinf_inuvp.txt` |

#### 3. `allsvlistmpl_fourloop_invzz.m` — svMPLs up to weight 8

Single-valued MPLs extended to weight 8. The **last two entries** introduce a new letter `1/\bar{z}` (reciprocal of complex conjugate).

Series expansion files (`.m` for z-space basis, `.txt` for expanded series):

| Limit | Basis (`.m`) | Straight (`_inuv`) | Permuted (`_inuvp`) |
|-------|-------------|--------------------|---------------------|
| z→0 (`e0`) | `allsvlistmpl_fourloop_invzze0.m` | `...e0_inuv.txt` | `...e0_inuvp.txt` |
| z→1 (`e1`) | `allsvlistmpl_fourloop_invzze1.m` | `...e1_inuv.txt` | `...e1_inuvp.txt` |
| z→∞ (`einf`) | `allsvlistmpl_fourloop_invzzeinf.m` | `...einf_inuv.txt` | `...einf_inuvp.txt` |

#### 4. `allsvlistmpl_fourloophard.m` — svMPLs with `\bar{z}` letter

Single-valued MPLs for 4-loop hard-topology runs. The **last four entries** introduce the letter `\bar{z}` (complex conjugate of z).

Series expansion files (base only, no `_inuv`/`_inuvp` variants):

| Limit | Expansion File |
|-------|---------------|
| z→0 (`e0`) | `allsvlistmpl_fourloopharde0.txt` |
| z→1 (`e1`) | `allsvlistmpl_fourloopharde1.txt` |
| z→∞ (`einf`) | `allsvlistmpl_fourloophardeinf.txt` |

### Ansatz Files in `data/ansatz/`

These are **raw ansatz** basis files. The ansatz for each specific problem is constructed from them — typically by selecting a subset of entries or combining even/odd lists. Each is a Wolfram Language `.m` file containing a list of basis functions. The `input.wl` for a run imports the constructed ansatz via `Import`.

| File | Description |
|------|-------------|
| `allsvlistevenans.m` | Parity-even ansatz of svHPLs under `z ↔ zz`, up to weight 8 |
| `allsvlistoddans.m` | Parity-odd ansatz of svHPLs under `z ↔ zz`, up to weight 8 |
| `svlistoddansatz_w8.m` | Parity-odd ansatz at weight 8 |
| `svlistevenansatz_w8.m` | Parity-even ansatz at weight 8 |
| `svmplevenansatz_threeloop.m` | Weight-6 parity-even ansatz with `zz` in the last two entries |
| `svmploddansatz_threeloop.m` | Weight-6 parity-odd ansatz with `zz` possibly in the last two entries |
| `svmplevenansatz_fourloophard_small.m` | Parity-even ansatz at weight 8 with `zz` possibly in the last four entries |
| `svmploddansatz_fourloophard_small.m` | Parity-odd ansatz at weight 8 with `zz` possibly in the last four entries |

---

## Quick Start: How to Write `input.wl`

Each bootstrap problem lives in `runs/<label>/`. To create a new problem, create a directory `runs/<label>/` with two files:

1. **`input.wl`** — defines the integrand, leading singularity, and ansatz
2. **`run.wl`** — bootstrap script (standard template, just change the label)

Place your ansatz `.m` file alongside `input.wl` in the same directory. Then run `run.wl` with Mathematica.

### `run.wl` Template

```mathematica
$HistoryLength = 0;

runDir   = DirectoryName[$InputFileName];
rootDir  = ParentDirectory[ParentDirectory[runDir]];
SetDirectory[rootDir];

Get[FileNameJoin[{rootDir, "workflow_engine.wl"}]];
Get[FileNameJoin[{rootDir, "input_parser.wl"}]];

label = "<your-label>";
order = 4;   (* 3 for 3-loop, 4 for 4-loop *)
yOrder = 5;  (* 4 for 3-loop, 5 for 4-loop *)

parsed = ParseInput[runDir];
If[parsed === $Failed, Print["Failed to parse input."]; Exit[1]];

SolveIntegrandSystem[rootDir, label, parsed, order, yOrder];
```

### Mirror Solve Stage (Optional)

When the standard solve (Stage 3) leaves free parameters — i.e. the boundary + series constraints are insufficient to fix all coefficients — the pipeline can optionally launch a **mirror solve stage** (Stage 4). This stage expands the ansatz using a **mirrored kinematic substitution** (z/zz square-root signs swapped relative to the standard `series_agent`), reaching the opposite Riemann sheet, which yields additional independent linear equations on the same coefficients.

The mirror stage is controlled entirely by the `$MirrorInputFilesOverride` setting in `run.wl`. If this variable is absent (or set to `None`), Stage 4 is disabled and the pipeline behaves exactly as before. If it is set, Stage 4 launches **only when** free parameters remain after the standard solve; if the standard solve fully determines all coefficients, Stage 4 is skipped automatically.

#### Important: Provide Mirror Series Expansion Files

The mirror stage uses a **different expansion algorithm** from the standard `series_agent.wl`. Instead of re-expanding the ansatz from scratch, it loads **pre-computed series expansion files** in which the leading-singularity factor is already baked into each ansatz element. These files are **not** the same as the `_inuv` / `_inuvp` series files used by the standard series agent — they are a separate set, one per leading singularity per limit point.

You must provide these files yourself. They can be readily calculated by the Maple package **Hyperlogprocedures** (the same tool used for the standard series files) — see [project_skills/series_expansion/SKILL_hyperlog_series_expansion.md](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/project_skills/series_expansion/SKILL_hyperlog_series_expansion.md) for the detailed procedure. The expected naming convention is:

```
svansatzw8_{ext}_{k}.txt
```

where `{ext}` ∈ `{e0, e1, einf}` (the three limit points, with the `p` variants `e0p/e1p/einfp` reusing the same file as their non-`p` counterpart), and `{k}` indexes the leading singularity (1, 2, …). Each file must contain a flat list of series-expanded ansatz elements whose total count matches the combined ansatz length; element ranges per leading singularity are sliced automatically using `lsOffsets` / `lsLengths` derived from `Length[lsConfigList]`.

#### Enabling the Mirror Stage

Add the `$MirrorInputFilesOverride` association to `run.wl`. Keys are ext types (`"e0"`, `"einf"`, `"e1"`); values are **lists of file paths**, one per leading singularity. The list length per ext must match `Length[lsConfigList]` (the number of leading singularities). The override is required because `config.wl` (loaded inside the engine) resets `$MirrorInputFiles` to `None`.

```mathematica
label = "fourloopI173";
order = 4;
yOrder = 5;

(* Mirror input files — enables the mirror solve stage (Stage 4).
   Keys are ext types (e0, einf, e1); values are lists of per-LS files.
   List length per ext must match the number of leading singularities
   (2 for this problem). Comment out or set to None to disable the mirror stage. *)
$MirrorInputFilesOverride = <|
  "e0"   -> {FileNameJoin[{rootDir, "data", "svansatzw8_e0_1.txt"}],
             FileNameJoin[{rootDir, "data", "svansatzw8_e0_2.txt"}]},
  "einf" -> {FileNameJoin[{rootDir, "data", "svansatzw8_einf_1.txt"}],
             FileNameJoin[{rootDir, "data", "svansatzw8_einf_2.txt"}]},
  "e1"   -> {FileNameJoin[{rootDir, "data", "svansatzw8_e1_1.txt"}],
             FileNameJoin[{rootDir, "data", "svansatzw8_e1_2.txt"}]}
|>;

parsed = ParseInput[runDir];
If[parsed === $Failed, Print["Failed to parse input."]; Exit[1]];

SolveIntegrandSystem[rootDir, label, parsed, order, yOrder];
```

Live example: [runs/fourloopI173/run.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/runs/fourloopI173/run.wl)

#### What the Mirror Stage Does

1. For each of the 6 limits `{1, 6, 2, 3, 4, 5}` (configurable via `$MirrorLimits` in `config.wl`), loads the per-LS series files, combines them into a single 304-element list, and multiplies the leading-singularity prefactor (`addInZZ`) — unless `$MirrorMultiplyLSFactor = False`, in which case the factor is already in the input files.
2. Truncates in the natural expansion variable per limit type: `ptr=0` (e0/e0p) uses `{z,0,5},{zz,0,5}`; `ptr=1` (e1/e1p) uses `{z1,0,5},{zz1,0,5}` after shifting `z1=z-1, zz1=zz-1`; `ptr=2` (einf/einfp) uses `{z,Infinity,5},{zz,Infinity,5}`.
3. Substitutes the **mirrored** zrep (square-root signs swapped vs. standard `series_agent.wl`) to reach the opposite Riemann sheet, then series-expands in `{u,0,0},{Y,0,order}`.
4. Extracts linear equations in `c[_]` via `MonomialList`, audits the system (all coefficients must be rational, all variables must be `c[_Integer]`), merges with the partial system from Stage 3, and solves. If the full system fully determines all coefficients (free=0), exports `result.m` and `coeff_sol.m`.

#### Reference Run: fourloopI173

| Metric | Value |
|--------|-------|
| Leading singularities | 2 (simple + double pole) |
| Ansatz elements | 304 (135 odd + 169 even) |
| Standard solve (Stage 3) | fixed 221/304 (83 free remaining) |
| Mirror solve (Stage 4) | fixed additional 83 → 304/304 (free=0) |
| Mirror equations | 1658 (from 6 limits) |
| Partial equations | 329 |
| Total system | 1987 equations |
| Solved | 304/304 (free=0) — FULLY SOLVED |
| Stage 4 time | ~26 minutes |

---

## `input.wl` Patterns

### Pattern 1: Single Integrand, Simple Leading Singularity

The most common case: one integrand, one leading singularity, one ansatz.

```mathematica
integrand = (x[4,7]*x[5,6]-x[4,5]x[6,7]-x[4,6]x[5,7])/
  (x[1,5] x[1,6] x[2,5] x[2,7] x[3,6] x[3,7] x[4,5] x[4,6] x[4,8] x[5,7] x[5,8] x[6,7] x[6,8] x[7,8]);

leadingsingularity = 1/((z-zz)*(1-u));

ansatz = Import[FileNameJoin[{DirectoryName[$InputFileName], "fourloopI41ansatz.m"}]];

OrderY = 4;
```

Live example: [runs/fourloopI41/input.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/runs/fourloopI41/input.wl)

### Pattern 2: Multi-Component Integrand (integrandlist + coeff)

When the integrand has multiple tensor components, use `integrandlist` with a coefficient list `coeff`:

```mathematica
integrandlist = {
  (x[3,6] x[4,5]) / (x[1,5] x[1,6] x[2,5] x[2,6] x[3,5] x[3,6] x[3,7] x[4,5] x[4,6] x[4,7] x[5,7] x[6,7]),
  (x[3,5] x[4,6]) / (x[1,5] x[1,6] x[2,5] x[2,6] x[3,5] x[3,6] x[3,7] x[4,5] x[4,6] x[4,7] x[5,7] x[6,7])
};

coeff = {1, 1};

leadingsingularity = 1/(z-zz)/(1-v);

ansatz = Import[FileNameJoin[{DirectoryName[$InputFileName], "threeloophard2_ans.m"}]];

OrderY = 3;
```

Live example: [runs/threeloophard2/input.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/runs/threeloophard2/input.wl)

Coefficients can be expressions in `x[i,j]`:

```mathematica
integrandlist = {int1, int2};
coeff = {1, -1/2*(x[1,2]x[3,4]+x[1,3]x[2,4])};

leadingsingularity = 1/(z-zz);

ansatz = Import[FileNameJoin[{DirectoryName[$InputFileName], "fourloopI42ansatz.m"}]];

OrderY = 4;
```

Live example: [runs/fourloopI42/input.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/runs/fourloopI42/input.wl)

### Pattern 3: Multiple Leading Singularities (leadingsingularity list + ansatz list)

When the integrand has multiple leading singularities, provide lists:

```mathematica
integrand = (x[1,8]x[3,7]x[2,4])/(x[2,5]x[3,5]x[5,7]x[5,8]x[1,6]x[4,6]x[6,7]x[6,8]x[1,7]x[2,7]x[3,8]x[4,8]x[7,8]);

leadingsingularity = {
  1/(z-zz),
  (u-v-1)/(z-zz)^2
};

ansatz = {
  Import[FileNameJoin[{DirectoryName[$InputFileName], "svlistoddansatz_w8.m"}]],
  Import[FileNameJoin[{DirectoryName[$InputFileName], "svlistevenansatz_w8.m"}]]
};

OrderY = 4;
```

Live example: [runs/fourloopI173/input.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/runs/fourloopI173/input.wl)

### Pattern 4: Double Pole Leading Singularity

```mathematica
integrand = ((x[5,6]*x[3,4] - x[3,6]x[4,5] - x[3,5]x[4,6])/
  (x[5,1]x[5,2]x[5,3]x[5,4]x[6,1]x[6,2]x[6,3]x[6,4]x[6,7]x[5,7]x[7,3]x[7,4]));

leadingsingularity = 1/(z-zz)^2;

ansatz = Import[FileNameJoin[{DirectoryName[$InputFileName], "threeloophard1_ans.m"}]];

OrderY = 3;
```

Live example: [runs/threeloophard1/input.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/runs/threeloophard1/input.wl)

### Pattern 5: Triple Pole Leading Singularity

```mathematica
integrand = (x[1,4] x[2,3]) / (
  x[1,5] x[1,6] x[1,7] x[2,5] x[2,6] x[2,7] x[3,5] x[3,6] x[3,7] x[4,5] x[4,6] x[4,7]);

leadingsingularity = v/(z-zz)^3;

ansatz = Import[FileNameJoin[{DirectoryName[$InputFileName], "threeloopoddansatz.m"}]];

OrderY = 3;
```

Live example: [runs/threeloopI8/input.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/runs/threeloopI8/input.wl)

---

## `input.wl` Reference

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `integrand` | expression | Rational function of `x[i,j]`. **Required unless** using `integrandlist`. |
| `integrandlist` | list of expressions | Multiple tensor components. Use with `coeff`. |
| `coeff` | list of expressions | Coefficients for each `integrandlist` component. |
| `leadingsingularity` | expression | Leading singularity in terms of `z`, `zz`, `u`, `v`. |
| `ansatz` | list (from `Import`) | Ansatz basis — a flat list of `I[z,...]` and `f[...]` elements. |
| `OrderY` | integer | Y expansion order. Usually 3 for 3-loop, 4 for 4-loop. |

### Optional Multi-LS Variables

| Variable | Type | Description |
|----------|------|-------------|
| `leadingsingularitylist` | list | Multiple LS expressions (use with `ansatzlist`). |
| `ansatzlist` | list of lists | One ansatz per LS. |

### `run.wl` Variables

| Variable | Value | Description |
|----------|-------|-------------|
| `label` | string | Run name, matches the directory name under `runs/`. |
| `order` | 3 or 4 | Boundary/solve expansion order. 3 for 3-loop, 4 for 4-loop. |
| `yOrder` | 4 or 5 | Series Y expansion order. 4 for 3-loop, 5 for 4-loop. |

### Active Run Directories (for reference)

```
runs/
├── threeloopI5/       single integrand, simple LS (1/((z-zz)(1-v)))
├── threeloopI8/       single integrand, triple pole LS (v/(z-zz)³)
├── threeloophard1/    single integrand, double pole LS (1/(z-zz)²)
├── threeloophard2/    multi-component integrand
├── fourloopI41/       single integrand, simple LS (1/((z-zz)(1-u)))
├── fourloopI42/       multi-component integrand with coeff
├── fourloopI117/      4-loop single integrand
├── fourloopI120/      4-loop single integrand
├── fourloopI173/      multi-LS (odd + even ansatz)
└── fourloopI6t/       4-loop single integrand
```
