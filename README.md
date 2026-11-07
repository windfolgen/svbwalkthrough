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

For a detailed recipe on how to construct parity-odd and parity-even SVMPL ansatz bases where the new letter (`zz` or `1/zz`) is restricted to the last N entries of the word, see [project_skills/ansatz_basis/SKILL.md](project_skills/ansatz_basis/SKILL.md). It covers the weight-6 (3-loop, N=2) reference construction from `data/reference_notebook/svbwalkthrough.wl` Section 3 and generalises it to weight 8 (4-loop, N=4) and to the `1/zz` letter.

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

### Alternative: match the boundary directly in z and zbar

This is an alternative **final series and matching procedure**. The published
`run.wl` scripts keep their existing workflows; this section does not introduce
a new execution option. The original `u,Y` and mirror-stage instructions below
remain applicable to those scripts.

#### Coordinate and expansion convention

Keep the names $z$ and $\bar z$ fixed (`zz` denotes $\bar z$ in the code). At the
origin,

$$
u=z\bar z,\qquad v=(1-z)(1-\bar z),\qquad Y=1-v=z+\bar z-z\bar z.
$$

For each channel, include its coordinate map and normalization from the table
above. Retain the svMPL expansion with **$\bar z$ expanded first**, and expand
the rational leading singularity in the same order. Multiply the complete
leading singularity, numerator and normalization before applying the final
cutoff. If the input already includes the leading singularity, apply it only
once. This matters for poles such as $(z-\bar z)^{-p}$.

Convert the known boundary $B(u,Y)$ to $B(z\bar z,z+\bar z-z\bar z)$, with the
corresponding map in other channels. Use the same formal logarithm and period
basis on both sides, for example $\ell=\log u$. Include the analytic logarithm
shifts associated with each channel or symmetry image before collecting
coefficients. Keep the branch convention of the supplied function series;
do not split logarithms into independent branches without justification.

The full expressions describe the same matching problem in different
coordinates. **Finite truncations are equivalent only when the retained
coefficients are determined by the available data on both sides.**

#### Retained terms and direct mirror constraints

Write a full ansatz column as a Laurent series
$\sum_{a,b} C_{ab}z^a\bar z^b$, at each formal logarithm/period monomial.
The seven ordinary benchmark cases used the following windows:

| Direct constraints | Keep powers in the original, fixed symbols |
|---|---|
| Standard | $a\le N,\ b\le0$ |
| Mirror | $a\le0,\ b\le N$ |

Here $N=3$ for the three-loop tests and $N=4$ for the four-loop tests.
**Retain every negative Laurent power within the chosen window**, including
poles that must cancel between ansatz columns. The lower powers follow from
the actual Laurent support, rather than an artificial cutoff at zero.

In this direct mirror test, both rows of the table use the **same
$\bar z$-first expansion of the full leading-singularity-times-svMPL column**.
Only the retained powers change. In particular, the mirror test does not
re-expand the leading singularity with $z$ first, regenerate the svMPL in the
opposite order, or exchange inverse square-root substitutions into `u,Y`.
The name *mirror* refers to the complementary coefficient window. The
implementation may exchange indices internally for extraction; the two
windows above give its meaning without renaming $z$ and $\bar z$.

Apply the selected window to the boundary as well. For a boundary regular in
$u,Y$, its known $u^0$ polynomial through $Y^N$ supplies the $z^a\bar z^0$
standard rows and the $z^0\bar z^b$ mirror rows; unwanted pole rows have zero
right-hand side. This observation requires control of the omitted boundary
terms, as explained next.

The recorded ordinary tests covered I5, I8, hard1, hard2, I41, I42 and I173.
For I173, standard rows had rank **221 of 304**; mirror-only rows had rank
**304**, and the combined system reproduced the saved solution exactly.
Thus mirror added **83** independent constraints after standard matching.
The other six cases were already uniquely fixed by standard rows. These
results validate those recorded systems; they do not certify the same window
for an arbitrary new boundary or ansatz.

#### How to choose a justified truncation

Choose a coefficient window from the **known boundary precision**, then work
backward through the complete rational prefactor to determine the required
raw svMPL depth. Both of the following conditions are needed:

1. **Boundary remainder:** if $R_B$ denotes all omitted boundary terms and
   $P_D$ selects the chosen window, establish $P_D(R_B)=0$. An unknown
   coefficient is not a zero right-hand side. Regular Taylor dependence in
   $u,Y$ is sufficient for the two leading-boundary windows above. If singular
   $Y$ dependence is possible, prove the needed bounds separately. For example,
   an unknown $u/Y^2$ term expands with $\bar z$ first as
   $\bar z/z+\cdots$ and contributes inside the mirror window, even though it
   is beyond the $u^0$ boundary at fixed $Y$.
2. **Ansatz remainder:** no omitted raw function coefficient may enter the
   chosen window after multiplication by the leading singularity,
   normalization or analytic logarithm shifts. For a window $a\le A,b\le B$,
   let $\nu$ be the lowest $\bar z$ power of the full rational factor **before
   any $z$ truncation**. Raw $\bar z$ degrees through $B-\nu$ can contribute.
   At these levels, the kernel's lowest $z$ powers determine how many positive
   raw $z$ degrees are needed. Conversely, negative raw $z$ powers require
   sufficiently many positive kernel powers. Obtain these bounds from the
   ordered Laurent expansion, including a justified lower support bound;
   observing a lower power in a finite cache alone is not a proof.

For instance,

$$
\frac{1}{z-\bar z}=\sum_{k\ge0}\frac{\bar z^k}{z^{k+1}}
\quad\text{in the chosen }\bar z\text{-first order}.
$$

Consequently, a positive raw $z$ degree can contribute to a retained zero or
negative $z$ degree. Truncating the bare svMPL to the final window before
including the leading singularity can lose necessary equations. Increasing
raw depth and checking stability is a useful additional check, but does not
replace the remainder bounds.

**Why not simply keep $a\le4,b\le4$?** That rectangle also requests mixed
positive powers absent from a leading-$u$ boundary. An unknown $c\,u$ changes
the $z\bar z$ coefficient. Even the unknown $c\,Y^5$ term changes the
$z^4\bar z$ coefficient by $5c$. For a boundary regular in $u,Y$, knowing all
$u^mY^n$ coefficients with $m,n\ge0$ and $2m+n\le8$ is a sufficient boundary
region for the full nonnegative rectangle through degree four in each variable. Matching Laurent pole
rows additionally requires their known cancellation or a specified singular
boundary. Sufficient raw ansatz depth must still be established independently.

#### Weighted boundaries and the I163/I169 distinction

For a weighted boundary with certified leading power $u^m$, the original
retained terms have the form $u^{m+r}Y^n$ with $0\le r\le\lfloor N/2\rfloor$
and $2r+n\le N$. A corresponding native calculation can factor out $u^m$
and expand in $\bar z/z$ and $z$, retaining ratio degree through
$\lfloor N/2\rfloor$ and $z$ degree through $N$. This keeps the names of the
original variables: a monomial $z^a\bar z^b$ after factoring out $u^m$ has
ratio degree $b$ and total degree $a+b$. Retain the required negative total
powers too. This construction needs analytic coordinate-unit and Laurent
support checks; a uniform rectangle in $z,\bar z$ does not encode the same
weighted precision.

The recorded I163/I169 alternative tests used this weighted construction and
exact parity identities of the **full** leading-singularity-times-numerator
columns to infer an opposite-order interpretation. They did **not** perform
the complementary-window mirror test in the preceding table. At matched
weighted precision that parity-derived check added no independent boundary
rank. I163 also needs the image-dependent shift of the logarithm ratio;
its intermediate columns differ from the original formal-log columns, while
the checked boundary solution spaces agree. Neither these checks nor the
ordinary mirror tests establish that arbitrary iterated expansions commute.

#### Matching and validation procedure

1. Load the same graph boundary and ansatz as the original calculation;
   reuse the designed IBP data.
2. Specify the channel maps, logarithm convention, coefficient windows and
   certified boundary/raw-series precision.
3. Construct each full column in the $\bar z$-first order and independently
   expand the boundary. Select standard and mirror coefficients as above.
4. Equate coefficients at each retained power, logarithm and period monomial.
   Include nonzero boundary monomials absent from all columns as contradiction
   rows, and include ansatz-only monomials with their known zero targets.
5. Solve the standard, mirror-only and combined systems independently; record
   their ranks, remaining parameters and exact residuals on every row. Apply
   any additional symmetry or regularity constraints consistently and report
   their contribution separately.
6. Compare the resulting solution space with the original method at compatible
   precision. For a benchmark, use its saved solution only for validation.
   Preserve the windows, input hashes and precision checks with the results.

The direct-matching experiments remain separate from the published workflow.
The new modules used by I163/I167/I169/I246 are described
[in the example classification below](#i163-i167-i169-and-i246); selecting
those modules does not select direct $z,\bar z$ matching.

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

---

## Output Files: `<label>.txt` vs `result.m`

Each run directory under `runs/<label>/` contains two distinct result files produced at different stages of the pipeline. They are **not** interchangeable — `result.m` is an intermediate per-leading-singularity output, while `<label>.txt` is the final assembled integral.

### Difference

| File | Produced by | Content | LS prefactor? | Status |
|------|-------------|---------|---------------|--------|
| `result.m` | Coefficient solving ([Skill 3](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/project_skills/coefficient_solving/SKILL.md)) | **List** `{result_1, result_2, ...}` — one pure transcendental expression per leading singularity, with the LS prefactor stripped away during series expansion | **No** (stripped) | Intermediate |
| `<label>.txt` | Result assembly ([Skill 5](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/project_skills/result_assembly/SKILL.md)) | **Single expression** — the full reconstructed integral `Sum_k [ leadingsingularity_k * result_k ]`, with the LS prefactor reattached | **Yes** (reattached) | **Final physical result** |

The output filename matches the run directory name, e.g. `runs/fourloopI41/fourloopI41.txt`.

### Relationship

```
<label>.txt  =  Sum_k [ leadingsingularity_k * result.m[[k]] ]  /.  {u -> z*zz, v -> (1-z)*(1-zz)}
```

- **Single-LS runs** (e.g. `fourloopI41`, `fourloopI120`): `<label>.txt = leadingsingularity * result.m[[1]]` with `u,v` replaced by `z,zz`
- **Multi-LS runs** (e.g. `fourloopI173` with 2 leading singularities): `<label>.txt = LS_1 * result.m[[1]] + LS_2 * result.m[[2]]` with `u,v` replaced by `z,zz`

Before export, the kinematic cross-ratios `u`, `v` in the leading-singularity prefactor are replaced by the complex variables `z`, `zz` via `u -> z*zz`, `v -> (1-z)*(1-zz)`, so that `<label>.txt` is expressed entirely in `z, zz` (matching the `I[z,...]` basis symbols).

### Why two files?

`result.m` preserves the per-LS decomposition, which is useful for inspecting each leading singularity's contribution separately and for debugging the solver. `<label>.txt` is the complete integral ready for physics interpretation — it is the expression that would be compared against direct integration or literature results.

### Regenerating `<label>.txt`

The assembly is a lightweight post-processing step that does not re-run the solver. The script scans every subdirectory of `runs/`: it **skips** runs without `result.m` (not yet successfully solved), and **assembles** (or renews) `<label>.txt` for every run that has `result.m`. Existing `<label>.txt` files are overwritten with refreshed content.

```bash
MathKernel -noprompt -script project_skills/result_assembly/assemble_results.wl
```

The script is idempotent — re-running it refreshes all previously assembled outputs and picks up any newly solved runs without touching unsolved ones.

See [project_skills/result_assembly/SKILL.md](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/project_skills/result_assembly/SKILL.md) for the full assembly recipe and verification checklist.

---

## Ancillary Files for the Manuscript (`anc/`)

The `anc/` subfolder collects the ancillary files of the paper [arXiv:2607.11645](https://arxiv.org/abs/2607.11645). It contains the Mathematica input used to generate and display the results presented in the manuscript — the three-loop and four-loop integral bases, analytic results for the integrals analysed in the main text, and their numerical checks.

### Integral Bases

| File | Content |
|------|---------|
| `3Loop_int_basis.m` | The **15-element three-loop integral basis** used in the paper — a list of `{denominator, numerator}` pairs in the dual coordinates `x[i,j]` (same convention as `leadingsingularity/threeloopint.m`) |
| `4Loop_int_basis.m` | The **412-element four-loop integral basis** used in the paper, in the same `{denominator, numerator}` format (same convention as `leadingsingularity/fourloopint.m`) |

### Analytic Results

| File | Content |
|------|---------|
| `3Loop_integral_insvmpl.m` | Analytic results of the three-loop integrals expressed in the svMPL basis (`I[z, ...]` and `f[...]` symbols) |
| `4Loop_integral_results_by_hyperlog.m` | Analytic results of the four-loop integrals obtained by direct integration with the Maple package **Hyperlogprocedures**, including their ε-dependence |
| `fourloopI117.txt`, `fourloopI120.txt`, `fourloopI173.txt`, `fourloopI176.txt`, `fourloopI181.txt` | Bootstrap results for individual four-loop integrals analysed in the main text — one file per integral, in the same single-expression `z`, `zz` format as the `<label>.txt` output of the corresponding runs under `runs/` |

### Notebook and Identity System

| File | Content |
|------|---------|
| `integral_basis&partial_results.nb` | The main Mathematica notebook: displays the integral bases and partial results in a readable form, generates the **magic identities, symmetry identities and Gram identities** for three and four loops, and performs the numerical checks of the analytic results |
| `sysgram.m` | The four-loop **Gram-identity system** — a large list of linear relations among the basis integrals `I4[k][{σ}]` with permuted external legs `σ`, with rational-function coefficients in `z`, `zz` |

The notebook itself points back to this repository (`https://github.com/windfolgen/svbwalkthrough.git`) for the detailed bootstrap workflow, and its sections mirror the pipeline: helper functions (`drawGraph`, `GraphReduce`, the multi-leg vertex differential equation) followed by worked three-loop and four-loop examples.


## I163, I167, I169 and I246

The examples fall into the following workflow groups. The original run
scripts and calculation bodies retain their existing behavior.

| Examples under `runs/` | Workflow selected by `input.wl` | Additional modules and constraints |
|---|---|---|
| `threeloopI5`, `threeloopI8`, `threeloophard1`, `threeloophard2`, `fourloopI41`, `fourloopI42`, `fourloopI117`, `fourloopI120`, `fourloopI173`, `fourloopI6t` | Original workflow; no new `BootstrapMethod` selection | Existing boundary, series and coefficient agents, with the existing optional mirror stage where configured |
| [`fourloopI163`](runs/fourloopI163/README.md) | `"Constrained"` | Shared orbit/profile/constraint modules; exact zero directions, diagonal regularity, circle logarithms and N2/N4/N6 boundaries |
| [`fourloopI167`](runs/fourloopI167/README.md) | `"Weighted"` | Shared weighted boundary/series modules and exact constraint solver; crossing, maximal logarithms and N4/N6 boundaries, using the registered I167 = I246 identity |
| [`fourloopI169`](runs/fourloopI169/README.md) | `"Weighted"` | The same shared modules, with crossing, diagonal/circle conditions, N4/N6 boundaries and deeper logarithm checks |
| [`fourloopI246`](runs/fourloopI246/README.md) | `"Weighted"` | The same shared modules, with crossing, maximal logarithms and N4/N6 boundaries matched to the I246 graph |

All four new examples retain the standard `input.wl`, ansatz, `run.wl`,
`coeff_sol.m`, pure-numerator `result.m` and assembled `<label>.txt` layout.
Run them through the usual entry point, for example:

```sh
wolframscript -file runs/fourloopI163/run.wl
```

Both new modes feed the shared
[`constraint_agent`](constraint_agent/workflow.wl) and
[`solve_agent/constrained_solve.wl`](solve_agent/constrained_solve.wl).
Profiles supply the integral-specific data; the shared algorithms have no
integral-number branches. The runs reuse certified graph-boundary and function
series data, reconstruct equations, solve unknown coefficients and verify every
row. They do not read saved coefficient solutions to perform the solve.

These extensions are distinct from the alternative direct $z,\bar z$ matching
procedure documented in the series-expansion section above. See the
[extension guide](series_agent/WEIGHTED_BOOTSTRAP.md) for module interfaces and
how to add profiles, the [integration record](REVIEW.md) for scope and limits,
and the [regression instructions](tests/bootstrap/README.md) for validation.
