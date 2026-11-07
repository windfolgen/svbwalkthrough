# I163, I167, I169 and I246 integration review

Integration based on `main` at
`f776b093f874f4dac7daf831aadbfb8109ef649c`. Publication validation uses an
isolated checkout containing only the package changes and data. The original
`test` and review worktrees, including staged and unstaged research, are preserved.

## What to review

| Area | Files |
|---|---|
| Standard run folders | [I163](runs/fourloopI163/README.md), [I167](runs/fourloopI167/README.md), [I169](runs/fourloopI169/README.md), [I246](runs/fourloopI246/README.md) |
| Reusable extra constraints | [orbit construction](constraint_agent/orbit.wl), [exact constraints](constraint_agent/constraints.wl), [profile loading](constraint_agent/profile.wl), [orchestration](constraint_agent/workflow.wl) |
| Added solving implementation | [constrained solver](solve_agent/constrained_solve.wl), [exact affine algebra](solve_agent/exact_linear.wl) |
| Integration and extension instructions | [workflow guide](series_agent/WEIGHTED_BOOTSTRAP.md) |
| Fresh regression evidence | [test guide](tests/bootstrap/README.md), [checks](tests/bootstrap/checks.json), [legacy results](tests/bootstrap/legacy_validation.json), [extension tests](tests/bootstrap/extension_validation.json), [I163 assembly](tests/bootstrap/assembly_validation.json) |

The examples use `runs/`, matching the repository's actual convention.
Every example has `input.wl`, an ansatz loader, `run.wl`, `coeff_sol.m`,
`result.m`, an assembled `.txt` formula, a log and a validation report.

I163 is now integrated from the completed research. I167/I169/I246 reuse the
earlier local integration, with explicit method selection and a shared added
coefficient solver. I246 has its own run folder and graph input, matched
directly to its certified boundaries. I167 uses those boundaries through
the established I167 = I246 identity.

## Isolation of the original workflow

New examples explicitly set `BootstrapMethod` to `Weighted` or `Constrained`.
Ordinary inputs do not load the extension. The original workflow receives a
small dispatch block; the public boundary/series/solve agents gain separate
signatures or an explicit option. Their original calculation bodies remain.
`asym/asym_new.wl`, `config.wl`, the direct mirror solver and every original
run file are unchanged from `main`.

The parser isolates file inputs so an earlier run cannot leave optional
configuration or an old ansatz active. It also rejects failed/empty ansatz
loads and admits only the new execution options, without replacing the parsed
integrand or leading singularities.

The new logic resides in separate `.wl` files. The original solver still
uses its existing `Solve` implementation. The matrix solver is invoked only
through its added public signature. No original representation-selection
optimization or change to legacy solving behavior is included in this review.

## Scientific results and fresh checks

| Example | Result |
|---|---|
| I163 | Unique 608-generator solve after removing 349 certified zero directions; seven pure numerator pieces reproduce the archived six-image formula exactly. |
| I167 | All 756 coefficients fixed; both coefficient lists and numerator functions exactly match the previous bootstrap. |
| I169 | All 735 coefficients fixed; both coefficient lists and numerator functions exactly match the previous bootstrap. |
| I246 | All 756 coefficients fixed; both coefficient lists and numerator functions exactly match the previous bootstrap and I167. |

All four examples have freshly reconstructed equations and verified every
original matrix row. I163's free-parameter counts are
`608 → 259 → 133 → 131 → 79 → 41 → 0`, corresponding to zero-direction
removal, diagonal regularity, circle logarithms, then N2/N4/N6 boundary data.
Its assembled formula comparison checks 3,181 formal MPL/period monomials
exactly. The orbit basis is independently regenerated from its seed data.

Six original examples were rerun using their existing boundary/series caches:
`threeloopI5`, `threeloopI8`, `threeloophard1`, `threeloophard2`,
`fourloopI41`, `fourloopI42`. Each reproduced both original coefficient and
numerator files exactly. An original I5 run also passed after the new workflow
and its failure paths had executed in the same kernel.

Additional checks cover renamed/scaled inputs, underdetermination, conflicting
physical boundaries, redundant contradictory rows, missing target monomials,
bad hashes, missing boundary data, changed bases, unknown graphs and invalid
zero directions. A failed rerun preserves earlier results but marks them
invalid for that attempt. See the linked machine-readable reports.

## Limits of the validation

The N4/N6 graph reductions and function-series/local-constraint packets are
packaged certified data. The fresh checks rerun equation construction,
elimination and output assembly; they do not repeat all large IBP reductions
or the archived numerical integrations. I167 uses I167 = I246, rather than a
new independent I167 reduction. The original I117, I120, I6t and I173 workflows
were not rerun from scratch in this review.

The shared expansion producer now accepts prefactors and channel depths as
profile data, with no integral-number branches. Exact root series support
higher orders without additional Taylor formulas. The regression covers 336
monomial expansions across the existing profiles, channels and N4/N6 orders,
plus an independent N8 example with a new prefactor. This checks the producer;
the complete runs continue to reuse the certified function-series packets.

The mechanism accepts data-driven constraint profiles, finite symmetry
orbits, arbitrary rational affine equations and explicit coefficient maps.
It does not prove a new graph's symmetry/regularity assumptions automatically.
I163 currently requires its registered ordered orbit basis; changing that
basis requires a matching map/operator profile. Its circle constraints are
finite order, and uniqueness is within the chosen ansatz. I167/I169/I246's weighted
provider also supports rational input-basis changes and rescalings.

The original worktree preservation and unchanged legacy source checks are
recorded in [source_preservation.json](tests/bootstrap/source_preservation.json).
Publication checks are reproducible with `python3 tests/bootstrap/run_all.py`.
Add `--cache-root /path/to/existing/checkout` to include the legacy regressions.
The script deletes the four new examples' generated results before solving,
then verifies them against frozen references. It reuses certified IBP/boundary
and series inputs by design. The latest completion record is
[run_all_validation.json](tests/bootstrap/run_all_validation.json).
