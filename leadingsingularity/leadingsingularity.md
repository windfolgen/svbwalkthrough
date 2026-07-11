# LeadingSingularity module

A self-contained Mathematica module that computes the **leading singularities** of
planar multi-loop integrands by the method of maximal cuts. The package is written
for human reading: it prints a coloured, step-by-step diagnostic trace and returns
the list of leading singularities. `LeadingSingularityAssist` (added at the end of
the package) re-presents the same diagnostics as a structured Association that is
easy for an AI model to consume.

## Module contents

| file | role |
|---|---|
| `LeadingSingularity.wl` | the package (algebra + algorithm + `LeadingSingularityAssist`) |
| `threeloopint.m` | 15 three-loop integrands (input data) |
| `fourloopint.m` | 412 four-loop integrands (input data) |
| `summary_3L.wl` | builds the LaTeX/PDF report for the 3-loop results |
| `summary_4L.wl` | builds the LaTeX/PDF report for the 4-loop results |
| `JHEP.bst`, `jheppub.sty` | JHEP BibTeX style + LaTeX class for the report |

## Algebraic representation

The integrand is a rational function of position-space coordinates. The package
sets up the following algebra (defined at the top of `LeadingSingularity.wl`):

- `x[a, b]` — the vector from point `a` to point `b`. It is antisymmetric
  (`x[a,b] = -x[b,a]`) and telescopes (`x[a,b] + x[b,c] = x[a,c]`). These rules
  fire automatically via `UpValues` on `x`.
- `V[a]` — a (loop) momentum vector; `VD[a,b] = V[a]·V[b]` (orderless);
  `V2[a] = V[a]²` (the squared length); `SD[a,b]` is the irreducible scalar
  product used only when no `x`-relation reduces `VD[a,b]`.
- Dot products are reduced to `V2[...]` of `x`-differences whenever possible, e.g.
  `VD[x[a,b], x[a,c]] = 1/2 (V2[x[a,b]] + V2[x[a,c]] - V2[x[b,c]])`. So after the
  setup every denominator factor is of the form `V2[x[i,j]]` (= `x[i,j]²`).
- `Subscript[λ, tag]` abbreviates a square root that survives a cut, where `tag`
  records the external points involved and a hash of the radicand. `replambda`
  is the list of `λ -> radicand` rules accumulated as cuts are taken.
- `ShowV2[expr]` pretty-prints `V2[x[a,b]]` as `x_{a,b}²`.

Input contract: the integrand's numerator and denominator must each be a single
monomial (a `Times` of `x[i,j]` factors, possibly with a numeric coefficient).
`Plus` in either part is rejected.

## Workflow of `LeadingSingularities[integrand, opts]`

Options: `deBug -> False`, `"outputlevel" -> 2`, `"external" -> {1,2,3,4}`,
`"order" -> 0`. At `"outputlevel" -> 1` it returns the intermediate
`{cutlist, numlist, replambda}` after the first integration step; at `2` (default)
it returns the final list of leading singularities.

1. **Build the topology.** Denominator factors `x[i,j]` become graph edges;
   external vertices (default `{1,2,3,4}`) are coloured red, the remaining
   vertices are the loop momenta. Each loop vertex must have degree ≥ 4.
2. **Step 1 — integrate out the degree-4 loops first.** A loop vertex of degree
   exactly 4 is pinned by four `V2[x[_,v]]` denominators, so it can be cut
   directly. `Jacob` computes the Jacobian of that cut (returns a `λ` tag plus a
   squared part and a residual factor). Those four denominators are removed and
   replaced by the `λ` and Jacobian factors in `cutlist`. If several loops qualify,
   they are ordered by connectivity so independent ones go first.
3. **Steps 2 … k — cut the remaining loops one at a time.** Each remaining term is
   `{cutlist, numlist, replambda, remain}`. For each term:
   - count how many conditions mention each remaining loop;
   - if some loop already has ≥ 4 conditions, cut it; otherwise `ResolveOrder`
     ranks the loops (by condition count, then by how many numerator/`λ` terms
     involve them) and the best candidate is cut;
   - `CutOneLoop` performs the cut (see below).
   The number of terms can branch (grow) at each step.
4. **`CutOneLoop[cutlist, numlist, var, replambda, remain]`** — the core cutter:
   - enumerates admissible 4-subsets of the conditions (`AdmissibleCutQ`: a subset
     is admissible if, counting square-root terms at half power, it supplies ≥ 4
     independent conditions on `var`);
   - solves the linear part, substitutes into the square-root (`λ`) terms, and
     reorganises them (`ReOrganize` + `PerfectSquareOut`);
   - detects **double poles** and records the pre-pole solution so the numerator
     can be tested for cancellation;
   - cancels higher poles against the numerator, splits surplus conditions into
     sub-cases via `ResolveCondition` (a quadratic condition is replaced by its
     derivative w.r.t. a chosen variable, balanced by its discriminant → a new `λ`);
   - computes the Jacobian for each 4-equation sub-system, substitutes the
     solution into the remaining denominator/numerator;
   - if a `0/0` indeterminant appears (`{0,0}`), it retries with one fewer cut
     (Pink "one solving order identified") to resolve the limit;
   - `Sow[{denominator_factors, numerator_factors, replambda, remaining_loops}]`
     for each surviving cut.
5. **Last Step — express in cross-ratios** (only when ≤ 4 externals). Each cut
   result is reduced to a function of
   `u = (x₁₂²·x₃₄²)/(x₁₃²·x₂₄²)` and `v = (x₁₄²·x₂₃²)/(x₁₃²·x₂₄²)`, the `λ`s are
   substituted (their perfect-square parts pulled out), and the leading
   singularity `numerator/denominator` is `Factor`-ed and collected. The returned
   list is these leading-singularity expressions.

Return values: a list of leading singularities (success); `{}` (no cut survived —
"weight drop"); `$Failed` (bad input, e.g. a loop of degree < 4).

### Helper functions

`PerfectSquareOut`, `Jacob`, `AdmissibleCutQ`, `ResolveCondition`, `ReOrganize`,
`CutOneLoop`, `ResolveOrder` — see the workflow above and the inline comments in
`LeadingSingularity.wl`.

## Warning colour classification

The human trace colours each diagnostic. **These colours carry severity
information and must be respected when analysing an integrand:**

| colour (RGBColor) | severity | meaning | representative messages |
|---|---|---|---|
| **Red** `{1,0,0}` | **Error** — close to wrong | the cut failed or the result is unreliable | `no cut detected for loop …`, `no solution! check the system`, `the condition is not enough for …`, `this case need to be solved by hand!`, `the loop momentum has not been totally solved`, `higher pole not canceled`, `the numerator cancels most of the denominator`, `2 or more quadratic polynomials!` |
| **Magenta** `{1,0,1}` | **Serious** | needs care, usually recoverable | `the cut condition may be not enough!`, `square root is 0`, `need less cut for the polynomial under square root`, `this cut is 0. check it`, `the cut condition has been resolved!`, `variabels do not exist in the numerator` |
| **Pink** `{1,0.5,0.5}` | **Mild** | a limit had to be resolved by reordering | `indeterminant encountered! the solving order is important`, `one solving order identified` |
| Orange `{1,0.5,0}` | Info | case / cut labels | `case i:`, `the Nth cut:` |
| Blue `{0,0,1}` | Info | result of a cut | `the remaining expression is …` |
| Cyan | Info | elliptic-cut hint | `you may need to consider cutting two loops at the same time or this is a elliptic cut!` |
| `{0.4,0.53,1.}`, `{0.52,0.54,1.}` | Info | numerator / extra square-root display | — |

So when judging an integrand: Red ⇒ that branch is essentially wrong/failed;
Magenta ⇒ serious but the algorithm tried to handle it; Pink ⇒ a mild reorder.
A result is trustworthy only if no Red warnings were produced on the surviving
branches.

## Running a batch and producing the PDF report

The result-data files that the summary scripts consume are produced by running
`LeadingSingularities` over every integrand. The canonical pattern (the deleted
`run_ls*.wl` used this) is:

```mathematica
Get["LeadingSingularity.wl"];
integrands = Get["fourloopint.m"];   (* or threeloopint.m *)
results = {};
Do[
  res = Quiet@Check[
      TimeConstrained[LeadingSingularities[integrands[[i]]], 15, "Timeout"],
      "Failed"];
  AppendTo[results, {i, res}];
  Put[results, "ls_results.m"];      (* ls_results_3.m for 3-loop *)
, {i, 1, Length[integrands]}];
```

For the 4-loop report, `summary_4L.wl` additionally reads `higher_poles.m`, a flat
list of integrand indices that produced an uncancelled higher pole. Both summary
scripts:

1. `normalize[res]` — multiplies each leading singularity by
   `V2[x[1,3]]*V2[x[2,4]]` to put it on a common denominator, fixes an overall
   sign, dedupes and sorts. Maps `{}` → `"WeightDrop"` and failures → `"Failed"`.
2. `GatherBy` integrands by their normalised leading-singularity set, sort classes
   by size (failed/weight-drop last).
3. Emit LaTeX (`\documentclass{article}` + `\usepackage{jheppub}`) with one
   subsection per class: integrand indices, the leading singularities as
   `\begin{equation}…\end{equation}`, and (4-loop) a bold "uncancelled higher
   poles" note.
4. `Export` to `summary.tex` (4-loop) / `summary_3.tex` (3-loop).

Compile to PDF (run inside the folder so the `.sty`/`.bst` are found):

```bash
pdflatex summary.tex && bibtex summary && pdflatex summary.tex && pdflatex summary.tex
# 3-loop: replace summary -> summary_3
```

This produces `summary.pdf` / `summary_3.pdf` in JHEP style.

## `LeadingSingularityAssist[integrand, opts]` — AI-friendly wrapper

Same options as `LeadingSingularities`. It runs the **unmodified** algorithm and
returns a structured `Association`:

| key | content |
|---|---|
| `"Status"` | `"Success"` / `"Empty"` / `"Failed"` / `"Unknown"` |
| `"NumLeadingSingularities"` | count (0 when Empty/Failed) |
| `"LeadingSingularities"` | the exact return value of `LeadingSingularities` |
| `"Summary"` | one-line status string, includes feature labels `[HigherPole]`, `[HigherPole-Uncancelled]`, `[PossibleElliptic]` when detected |
| `"LoopVariables"` | list of printed "loop variables are …" lines |
| `"SolvingOrder"` | list of "Step 1: integrate … first" lines |
| `"Milestones"` | step / cut-count / remaining-loops / last-step lines |
| `"HasHigherPole"` | `True` if any higher-pole print was emitted (includes double poles) |
| `"HigherPoleUncancelled"` | `True` if a higher pole survived cancellation (branch unreliable) |
| `"HigherPoleRecords"` | records: "double pole find!", "encountered" (may be cancelled), and/or "not cancelled" (survived) |
| `"HasPossibleElliptic"` | `True` if the "elliptic cut!" / "cutting two loops" message was emitted |
| `"EllipticCutInfo"` | records with the original/remaining square root and the cut list that generates the elliptic curve |
| `"Warnings"` | records with severity `Error` / `Serious` / `Mild` (colour-based) |
| `"Info"` | records with severity `Info` (case labels, remaining expressions, …) |
| `"FullLog"` | the full plain-text diagnostic trace |

Each warning/info/feature record is `<| "Severity" -> s, "Text" -> str |>`.
Severity is derived from the colour of the `Style` wrapper in each `Print` call,
using the table above (Red→Error, Magenta→Serious, Pink→Mild, any other
colour→Info, no colour→Plain).

### Feature extraction: higher poles (incl. double poles), elliptic cuts

The algorithm prints important structural information as **plain text** (double
pole, higher pole) or **Cyan Info** (elliptic cut), which the colour-based
severity classifier does not flag as warnings. `LSAssistExtractFeatures` scans
all record texts for these specific patterns and surfaces them as dedicated keys.
A double pole is a higher pole of order 2, so double-pole records are merged
into the higher-pole category rather than tracked separately.

- **Higher pole** (five distinct prints, all plain):
  - `"double pole find! checkps: <..> sol: <..>"` — the denominator contains a
    squared `V2` factor (a pole of order 2). The algorithm then tries to cancel
    it against the numerator. The record carries `checkps` (the pole factors)
    and `sol` (the pre-pole solution).
  - `"higher power pole encountered, it should be cancelled by numerator: <den>"`
    — the algorithm found a higher pole and expects the numerator to cancel it.
  - `"higher pole not cancelled: <expr>"` → `Throw[{}]`, the case fails. The
    higher pole survived.
  - `"higher pole not canceled!"` → `Throw[{}]`, the case fails.
  - `"higher poles not canceled through Jacobian factor! <cutlist>"` →
    `Continue[]`, this cut is skipped at the final cross-ratio step.

  `HigherPoleUncancelled` is `True` when any "not cancel" message appears — the
  surviving branch is unreliable. When `HasHigherPole` is `True` but
  `HigherPoleUncancelled` is `False`, the higher pole was encountered but
  successfully cancelled by the numerator.

- **Possible elliptic cut** (three consecutive Cyan prints): the solution was
  insufficient after resolving square roots. The trigger is
  `"you may need to consider cutting two loops in the same time or this is a
  elliptic cut! cut list: <cutlist>"`. The preceding two prints give the
  original and remaining square roots (the radicand of the elliptic curve).
  `EllipticCutInfo` collects all three so the cut that generates the elliptic
  curve can be identified.

How it stays non-invasive (verified: the return value of `LeadingSingularities` is
bit-for-bit identical whether run directly or through the wrapper):

- only `Print` is locally rebound (`Block[{Print = LSAssistCapturePrint}, …]`);
  the replacement appends a record to a plain list (`LSAssistBag`) and returns
  `Null`, exactly as `Print` would;
- a plain list is used instead of `Sow`/`Reap` on purpose — `LeadingSingularities`
  and `CutOneLoop` use `Reap`/`Sow` internally to collect cut results, so `Sow`
  here would corrupt those results and be swallowed by the algorithm's own `Reap`;
- `Quiet` suppresses kernel messages; `Check` is **not** used, because the
  algorithm emits benign messages (`Solve::incnst`, `Power::infy`, …) during
  normal operation and `Check` would falsely report `$Failed`. Failure is detected
  from the return value (`$Failed` / `$Aborted` / `{}` / list) instead.

## Rules and constraints

- **Never modify the algorithm.** Any change to the cut / solve / Jacobian logic
  of `LeadingSingularities`, `CutOneLoop`, `Jacob`, `AdmissibleCutQ`,
  `ResolveCondition`, `ResolveOrder`, or the algebra setup requires explicit
  approval from the user. `LeadingSingularityAssist` may only adjust *how
  diagnostics are presented*, never *what is computed*.
- Respect the warning severities when analysing integrands (Red ⇒ unreliable
  branch; Magenta ⇒ serious; Pink ⇒ mild).
- Keep the input as a monomial rational function of `x[i,j]`; do not pre-expand
  `Plus` expressions.
