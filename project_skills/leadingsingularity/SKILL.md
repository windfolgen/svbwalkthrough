---
name: leadingsingularity
description: >
  Computes leading singularities of planar multi-loop integrands via maximal cuts.
  Governs the leadingsingularity/ module — a self-contained Mathematica package
  invoked when analysing integrands, running LeadingSingularityAssist, or producing
  summary_3L/4L PDF reports. Produces the leadingsingularity field used in input.wl.
---

# Leading Singularity Calculation (Skill 0)

## Purpose

The bootstrap workflow takes `leadingsingularity` (or `leadingsingularitylist`) as an **input** in [runs/&lt;label&gt;/input.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/runs). This skill computes that input — the leading singularities of a planar multi-loop integrand — via the method of maximal cuts.

It governs the [leadingsingularity/](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/leadingsingularity) module, a self-contained Mathematica package. Full workflow documentation lives in [leadingsingularity/leadingsingularity.md](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/leadingsingularity/leadingsingularity.md).

## Agent File

[leadingsingularity/LeadingSingularity.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/leadingsingularity/LeadingSingularity.wl)

## CRITICAL RULE: Never modify the algorithm

**Any modification to the algorithm requires explicit discussion with and approval from the user before implementation.** This is a hard constraint (also recorded in project memory).

The algorithm consists of these functions in `LeadingSingularity.wl`:
- `LeadingSingularities` — the top-level driver
- `CutOneLoop` — the core per-loop cutter
- `Jacob` — Jacobian of a loop-momentum cut
- `AdmissibleCutQ` — admissibility test for a 4-subset of cut conditions
- `ResolveCondition` — resolves quadratic polynomials in intermediate steps
- `ResolveOrder` — ranks remaining loops for the next cut
- `ReOrganize`, `PerfectSquareOut` — square-root reorganisation helpers
- The algebra setup (`x`, `V`, `VD`, `V2`, `SD` definitions at the top of the file)

**What you MAY do without asking:**
- Adjust *how diagnostics are presented* (this is the purpose of `LeadingSingularityAssist`).
- Add new wrapper/helper functions that call the existing algorithm without changing its behaviour.
- Improve documentation, comments, or the `leadingsingularity.md` summary.

**What you MUST NOT do without explicit user approval:**
- Change the cut / solve / Jacobian logic of any function listed above.
- Alter the order in which cuts are taken.
- Change how double poles, higher poles, or indeterminants are handled.
- Modify the algebra rules for `x`, `V`, `VD`, `V2`, `SD`.
- Change the cross-ratio (`u`, `v`) final-expression step.

If a bug is suspected in the algorithm, **report it to the user** with the exact location and observed behaviour, then wait for their decision. Do not silently "fix" it.

## Warning severity classification

The human-facing trace colours diagnostics. **These colours carry severity information and must be respected when judging an integrand's result:**

| colour (RGBColor) | severity | meaning |
|---|---|---|
| **Red** `{1,0,0}` | **Error** — close to wrong | the cut failed or the result is unreliable. A surviving branch with a Red warning should not be trusted. |
| **Magenta** `{1,0,1}` | **Serious** | needs care; usually recoverable but worth flagging. |
| **Pink** `{1,0.5,0.5}` | **Mild** | a limit had to be resolved by reordering the solving sequence. |
| Orange / Blue / Cyan / light-blue | Info | case labels, remaining-expression displays, elliptic-cut hints. Not warnings. |

A result is trustworthy only if **no Red warnings** were produced on the surviving branches. `LeadingSingularityAssist` classifies these into the `"Warnings"` key with `"Severity"` values `Error` / `Serious` / `Mild` (Info goes to the `"Info"` key).

## Using `LeadingSingularityAssist`

`LeadingSingularityAssist[integrand, opts]` is the AI-friendly wrapper. Same options as `LeadingSingularities` (`deBug`, `"outputlevel"`, `"external"`, `"order"`). It runs the **unmodified** algorithm and returns a structured `Association`:

| key | content |
|---|---|
| `"Status"` | `"Success"` / `"Empty"` / `"Failed"` / `"Unknown"` |
| `"NumLeadingSingularities"` | count (0 when Empty/Failed) |
| `"LeadingSingularities"` | the exact return value of `LeadingSingularities` |
| `"Summary"` | one-line status with feature labels `[HigherPole]`, `[HigherPole-Uncancelled]`, `[PossibleElliptic]` |
| `"LoopVariables"` | printed "loop variables are …" lines |
| `"SolvingOrder"` | "Step 1: integrate … first" lines |
| `"Milestones"` | step / cut-count / remaining-loops / last-step lines |
| `"HasHigherPole"` | `True` if any higher-pole print was emitted (includes double poles) |
| `"HigherPoleUncancelled"` | `True` if a higher pole survived cancellation (unreliable) |
| `"HigherPoleRecords"` | "double pole find!", "encountered" (may cancel), and/or "not cancelled" (survived) |
| `"HasPossibleElliptic"` | `True` if the "elliptic cut!" / "cutting two loops" message was emitted |
| `"EllipticCutInfo"` | original/remaining square root + cut list that generates the elliptic curve |
| `"Warnings"` | colour-classified: `Error` / `Serious` / `Mild` |
| `"Info"` | colour-classified: `Info` (case labels, remaining expressions, …) |
| `"FullLog"` | the full plain-text diagnostic trace |

### Feature extraction (higher poles incl. double poles, elliptic cuts)

The algorithm prints important structural info as **plain text** (double/higher pole) or **Cyan Info** (elliptic cut) — not caught by colour-based severity. `LSAssistExtractFeatures` scans record texts for these patterns. A double pole is a higher pole of order 2, so double-pole records are merged into the higher-pole category rather than tracked separately.

- **Higher pole** (five prints, all plain):
  - `"double pole find!"` — denominator had a squared `V2` factor (order-2 pole). Record carries `checkps` + `sol`. Algorithm tries to cancel via numerator.
  - `"higher power pole encountered..."` — found, expects numerator cancellation.
  - `"not cancelled"` / `"not canceled"` — survived → `Throw` or `Continue`, branch unreliable. `HigherPoleUncancelled` flags the latter.
- **Possible elliptic**: three Cyan prints — original square root, remaining square root, and `"elliptic cut! cut list: <cutlist>"`. The cut list identifies the cut that generates the elliptic curve.

When analysing an integrand, always check `HasHigherPole`, `HigherPoleUncancelled`, and `HasPossibleElliptic` to label it appropriately.

## Input contract

The integrand must be a single rational function: numerator and denominator each a monomial (`Times` of `x[i,j]` factors, possibly with a numeric coefficient). `Plus` in either part is rejected. Do not pre-expand `Plus` expressions.

## PDF report generation

[leadingsingularity/summary_3L.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/leadingsingularity/summary_3L.wl) (3-loop, 15 integrands) and [leadingsingularity/summary_4L.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/leadingsingularity/summary_4L.wl) (4-loop, 412 integrands) produce JHEP-style LaTeX reports. They:
1. Read result data (`ls_results_3.m` / `ls_results.m` + `higher_poles.m` for 4-loop),
2. Normalize each leading singularity (multiply by `V2[x[1,3]]*V2[x[2,4]]`, fix sign, dedupe, sort),
3. `GatherBy` integrands by their normalised leading-singularity set,
4. Emit LaTeX (`\usepackage{jheppub}`) with one subsection per class.

Compile (run inside the folder so `.sty`/`.bst` are found):
```bash
pdflatex summary.tex && bibtex summary && pdflatex summary.tex && pdflatex summary.tex
# 3-loop: replace summary -> summary_3
```

## Batch run pattern

```mathematica
Get["LeadingSingularity.wl"];
integrands = Get["fourloopint.m"];   (* or threeloopint.m *)
results = {};
Do[
  res = Quiet@TimeConstrained[LeadingSingularities[integrands[[i]]], 15, "Timeout"];
  AppendTo[results, {i, res}];
  Put[results, "ls_results.m"];      (* ls_results_3.m for 3-loop *)
, {i, 1, Length[integrands]}];
```

## Output → Bootstrap Input

The leading singularities computed here become the `leadingsingularity` (single LS) or `leadingsingularitylist` (multiple LS) field in [runs/&lt;label&gt;/input.wl](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/runs). The bootstrap workflow (Skills 1–4) then uses this to strip the primary pole from the ansatz and assemble the final integral. See [project_skills/result_assembly/SKILL.md](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/project_skills/result_assembly/SKILL.md) for how the LS factor is reattached at the end.
