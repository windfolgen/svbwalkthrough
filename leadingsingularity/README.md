# Leading Singularity Package

A Mathematica package for computing the **leading singularities** of planar
multi-loop integrands via the method of maximal cuts.

> **This package ASSISTS the user in leading singularity analysis; it does NOT
> replace it.** The algorithm emits a rich diagnostic trace (cut conditions,
> solving order, Jacobians, double/higher poles, possible elliptic cuts, …).
> These intermediate prints carry information that the final return value alone
> does not capture. The user is expected to read and check them, especially any
> warnings coloured **Red** (Error), **Magenta** (Serious), or **Pink** (Mild),
> and any plain-text `higher pole` / `double pole` / `elliptic cut` messages.

## What is leading singularity analysis?

The **leading singularity** of a multi-loop integrand is the residue on the
maximal cut — i.e. the coefficient left over after putting *every* propagator
on-shell. It is a purely algebraic object (a rational function of external
data) that captures the integrand's behaviour at its leading singularity and
is a key ingredient in modern integrand-reduction and bootstrap programmes.

This package computes it by the **method of maximal cuts** in position space:

1. **Topology.** The integrand is a rational function of position-space
   coordinates `x[i,j]` (= `xᵢ − xⱼ`). Each denominator factor `x[i,j]` is a
   graph edge; external points (default `{1,2,3,4}`) are fixed, the remaining
   vertices are loop momenta. Every loop vertex must have degree ≥ 4, because
   cutting a loop in D=4 requires four on-shell conditions.

2. **Cut loop by loop.** A loop of degree exactly 4 is pinned by four
   `V2[x[_,v]] = (xᵢ − xᵥ)²` denominators, so it can be solved directly. The
   package integrates out degree-4 loops first, then cuts the remaining loops
   one at a time. For each cut:
   - `AdmissibleCutQ` selects a 4-subset of conditions that independently
     constrain the loop variable;
   - the linear part is solved, the square-root (`λ`) terms are substituted in
     and reorganised (`PerfectSquareOut` pulls out perfect squares);
   - `Jacob` computes the Jacobian of the 4-equation system — a `λ` tag plus a
     squared part and a residual factor;
   - higher / double poles are checked against the numerator for cancellation;
   - `ResolveCondition` splits surplus quadratic conditions into sub-cases
     (replacing a quadratic by its derivative, balanced by its discriminant →
     a new `λ`).

3. **Branching.** When several 4-subsets are admissible, or a quadratic
   condition splits into two roots, the computation branches. Each surviving
   branch is carried forward as a separate `{cutlist, numlist, replambda,
   remaining_loops}` term. The number of terms can grow at each step.

4. **Final step — cross-ratios.** Once all loops are cut, the result is
   reduced to a function of the two conformal cross-ratios
   `u = (x₁₂²·x₃₄²)/(x₁₃²·x₂₄²)` and `v = (x₁₄²·x₂₃²)/(x₁₃²·x₂₄²)`, the `λ`s
   are substituted, and each leading singularity is returned as a factored
   `numerator/denominator`.

### What the return value means

- A **list** of expressions → the leading singularities (success).
- `{}` → no cut survived ("weight drop").
- `$Failed` → bad input (e.g. a loop vertex of degree < 4).

### Why the intermediate prints matter

The return value is only the final residue. The intermediate prints reveal:

- **which cut was taken at each step** (`case i:`, `Step k: integrate … first`),
- **Jacobian matrices and square roots** that survived each cut,
- **double poles / higher poles** — whether they appeared and whether the
  numerator cancelled them (`HigherPoleUncancelled` ⇒ the branch is
  unreliable),
- **possible elliptic cuts** — when the solution is insufficient even after
  resolving square roots, the integrand may live on an elliptic curve and
  cannot be fully cut by the one-loop-at-a-time strategy.

A result is trustworthy only if no Red warnings were produced on the surviving
branches, and any higher-pole / elliptic flags should be inspected by hand.

See `leadingsingularity.md` for the full function-by-function walkthrough.

## Files

| file | purpose |
|---|---|
| `LeadingSingularity.wl` | the package — algebra setup + algorithm + `LeadingSingularityAssist` wrapper |
| `threeloopint.m` | 3-loop integrand basis (15 integrands) |
| `fourloopint.m` | 4-loop integrand basis (412 integrands) |
| `summary_3L.wl` | generates the 3-loop LaTeX/PDF report from `ls_results_3.m` |
| `summary_4L.wl` | generates the 4-loop LaTeX/PDF report from `ls_results.m` + `higher_poles.m` |
| `JHEP.bst`, `jheppub.sty` | JHEP BibTeX style and LaTeX class for report compilation |
| `leadingsingularity.md` | detailed workflow documentation |

## Two entry points

### 1. `LeadingSingularities` — for humans

The original human-facing driver. Prints a coloured trace to the Mathematica
front end for the user to inspect step by step.

```mathematica
Get["LeadingSingularity.wl"];
ints = Get["threeloopint.m"];

LeadingSingularities[ints[[1]]]
```

Options:

| option | default | meaning |
|---|---|---|
| `deBug` | `False` | extra internal diagnostics |
| `"outputlevel"` | `1` | verbosity (0 = quiet, 1 = normal, >1 = verbose) |
| `"external"` | `{x[1], x[2], x[3], x[4]}` | external points |
| `"order"` | `{5, 6, ...}` | preferred loop-solving order |

### 2. `LeadingSingularityAssist` — for AI / automation

A wrapper that runs the **unmodified** algorithm (only `Print` is intercepted)
and returns a structured `Association` with classified warnings, higher-pole /
elliptic-cut feature flags, and the full plain-text log. Intended for automated
or AI consumption.

```mathematica
res = LeadingSingularityAssist[ints[[1]]];

res["Summary"]                       (* one-line status with feature labels *)
res["LeadingSingularities"]          (* the exact return value *)
res["HasHigherPole"]                 (* True if any higher-pole print *)
res["HigherPoleUncancelled"]         (* True if a higher pole survived *)
res["HasPossibleElliptic"]           (* True if an elliptic cut was detected *)
res["Warnings"]                      (* Error / Serious / Mild records *)
res["FullLog"]                       (* full plain-text trace *)
```

The return value is bit-for-bit identical to calling `LeadingSingularities`
directly — the wrapper only reorganises how diagnostics are presented.

## Typical workflow

### Single integrand

```mathematica
Get["LeadingSingularity.wl"];
ints = Get["threeloopint.m"];

(* human inspection *)
LeadingSingularities[ints[[1]]]

(* or AI-friendly *)
LeadingSingularityAssist[ints[[1]]]
```

### Batch run + PDF report

```mathematica
Get["LeadingSingularity.wl"];
ints = Get["fourloopint.m"];   (* or threeloopint.m *)

results = {};
higherPoles = {};
Do[
  res = Quiet@TimeConstrained[LeadingSingularityAssist[ints[[i]]], 120, "Timeout"];
  lsVal = If[res === "Timeout", $Failed, res["LeadingSingularities"]];
  hpUnc = If[res === "Timeout", False, res["HigherPoleUncancelled"]];
  AppendTo[results, {i, lsVal}];
  If[hpUnc, AppendTo[higherPoles, i]];
  If[Mod[i, 10] === 0,
    Put[results, "ls_results.m"];          (* ls_results_3.m for 3-loop *)
    Put[higherPoles, "higher_poles.m"];    (* 4-loop only *)
  ],
  {i, 1, Length[ints]}
];
```

Then generate the report:

```mathematica
(* 3-loop *)
Get["ls_results_3.m"]  (* already saved above *)
<< "summary_3L.wl"     (* writes summary_3L.tex *)

(* 4-loop *)
<< "summary_4L.wl"     (* reads ls_results.m + higher_poles.m, writes summary_4L.tex *)
```

Compile to PDF (run inside this folder so `.sty` / `.bst` are found):

```bash
pdflatex summary_3L.tex && bibtex summary_3L && pdflatex summary_3L.tex && pdflatex summary_3L.tex
pdflatex summary_4L.tex && bibtex summary_4L && pdflatex summary_4L.tex && pdflatex summary_4L.tex
```

## Warning severity (colours)

| colour | severity | meaning |
|---|---|---|
| **Red** `{1,0,0}` | Error | cut failed or result unreliable — do not trust the branch |
| **Magenta** `{1,0,1}` | Serious | needs care; usually recoverable |
| **Pink** `{1,0.5,0.5}` | Mild | a limit had to be resolved by reordering |
| Orange / Blue / Cyan | Info | case labels, remaining expressions, elliptic hints |

## Feature flags (in `LeadingSingularityAssist`)

| flag | meaning |
|---|---|
| `HasHigherPole` | any `double pole find!` or `higher pole` print was emitted |
| `HigherPoleUncancelled` | a higher pole survived cancellation (branch unreliable) |
| `HasPossibleElliptic` | the `elliptic cut!` / `cutting two loops` message was emitted; `EllipticCutInfo` carries the square roots and the cut list |

## Input contract

The integrand must be a single rational function: numerator and denominator
each a monomial (`Times` of `x[i,j]` factors, possibly with a numeric
coefficient). `Plus` in either part is rejected.
