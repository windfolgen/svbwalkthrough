# Additional bootstrap constraints

I163, I167, I169 and I246 use the same public entry points and `runs/<label>/`
layout as the original examples:

```mathematica
parsed = ParseInput[runDir];
SolveIntegrandSystem[rootDir, label, parsed, 6, 6];
```

The new inputs explicitly select an extension through `bootstrapOptions`.
An input without this option follows the original workflow. The original
boundary calculation, series calculation, coefficient solver and mirror
solver bodies are retained. The extension is loaded only when selected.

| Example | Method | Additional information |
|---|---|---|
| I163 | `"Constrained"` | Weighted S3 orbit, exact zero generators, diagonal regularity, circle logarithms, N2/N4/N6 boundary data |
| I167 | `"Weighted"` | Crossing, maximal logarithms, weighted N4/N6 boundaries; ancillary I167 = I246 identity |
| I169 | `"Weighted"` | Crossing, diagonal/circle constraints, weighted N4/N6 boundaries, deeper logarithm checks |
| I246 | `"Weighted"` | Crossing, maximal logarithms and weighted N4/N6 boundaries matched directly to the I246 graph |

Both input modes feed the same exact constraint solver. `Weighted` projects
registered operators onto the supplied numerator basis; `Constrained` also
accepts a parameter map tying coefficients across symmetry images. These
choices describe input representations and are independent of run labels.

## Output convention

`coeff_sol.m` is a list of coefficient vectors, one per leading singularity.
`result.m` is a list of pure numerator functions in the same order. Multiplying
by the leading singularities in `input.wl` gives the complete integral saved
as `<label>.txt`. Each run also writes `run.log` and `workflow_validation.json`.

I163 has seven leading singularities. Its 608 orbit generators are mapped
to 8,688 entries distributed among the seven pure-function lists. These
entries have tied coefficients; they are not 8,688 independent unknowns.
`generator_coeff_sol.m` records the generator coordinates, while the usual
`coeff_sol.m` and `_sol.m` contain the expanded per-sector coefficients.
The full six-image expression is retained. The earlier three-image formula
uses a further whole-function identity and is not needed by this workflow.

The solver starts with unknown coefficients. It never imports a saved
coefficient vector or a previous affine solution. It checks every original
equation, including redundant rows, and requires zero remaining parameters
before exporting. A failed run writes `OutputsValidForThisRun: false`; result
files retained from a previous success must then not be treated as new output.

## Reusable modules

| File | Interface and purpose |
|---|---|
| `constraint_agent/orbit.wl` | `SVBOrbitAnsatz[sectors, seedMap, images, weights]` builds weighted finite-group orbits and an explicit rational map to pure numerator coefficients. It verifies the rational prefactor transformations. |
| `constraint_agent/constraints.wl` | `SVBConstraintBlock` validates arbitrary exact affine blocks; `SVBBoundaryBlock` matches independent boundary expressions to monomial keys; `SVBZeroGeneratorGauge` fixes certified function redundancies after checking that all operators annihilate them. |
| `constraint_agent/profile.wl` | Loads a data profile, checks hashes and ordered input basis, matches graph normalization, and constructs the requested boundary/regularity blocks. No integral label is hardcoded. |
| `constraint_agent/workflow.wl` | Routes explicitly selected methods, logs stages, and records failures. |
| `solve_agent/constrained_solve.wl` | Additional `RunCoefficientSolving[root,label,config,blocks,parameterMap]` implementation; exports the standard multi-LS output. |
| `solve_agent/exact_linear.wl` | Rational affine elimination, consistency and uniqueness checks, and final residual verification. |
| `series_agent/weighted_series.wl` | Projects registered function-series operators onto an input basis; supports rational combinations, rescalings and reorderings. |
| `series_agent/weighted_*jet_engine.wl` | Ordered expansions, subleading powers, reflected coordinates and mixed periods. Prefactors and channel depths come from profiles; the algorithm has no integral-number branches. |
| `asym/boundary_agent/weighted_boundary.wl` | Independent graph boundaries and native weighted boundary reconstruction. |
| `asym/weighted_region_expand.wl` | Weighted region expansion in a separate file; the original `asym_new.wl` is unchanged. |
| `transform/hyperlog/` | Maple producers for ordered, diagonal and circle expansions. |

The original long signatures of the three public agents remain available.
Only the added coefficient-solver signature loads the exact matrix solver;
ordinary runs still use their original `Solve` implementation.

## Defining another constrained problem

Set `"BootstrapMethod" -> "Constrained"` and `"ConstraintProfile"` to a
repository-relative `.wl` profile. The I163 profile in
`data/constraints/reciprocal_s3_w8/profile.wl` is a complete example.
A profile supplies:

- The ordered pure-function basis and rational parameter map in `OrbitData`.
- `Blocks` with a name, order, kind, matrix file, and independent boundary
  file where appropriate. Homogeneous blocks represent zero conditions.
- Monomial variables, shifts, a period tagger and the minimum power of `u`.
- The graph integrand, supported order, whole-function null directions and
  their mathematical certificate, plus SHA-256 hashes of packaged data.

The generic constrained profile currently requires its exact ordered basis;
a different basis needs a matching map and operator profile. It accepts any
run label and rational graph normalization. Explicit `BoundaryData` may replace
the graph cache, but the profile's symmetry and regularity assumptions must
still hold for that graph. The code does not establish those assumptions for
an arbitrary new integral. Weighted profiles additionally support basis
projection and rational basis changes.

Zero generators are removed only on the strength of a supplied whole-function
certificate. Annihilation by finite series alone is not a proof that a function
vanishes. The current certificate derives from the HPL transformation
representation; its provenance is documented with the I163 data.

## Data and regeneration

Boundary expressions and function matrices are separate. The former fix
right-hand sides; the latter describe basis functions and analytic constraints.
Their hashes are verified before use. No normal run reads files from `test/`
or any research directory.

The new end-to-end reruns reuse certified N4/N6 graph reductions and function
series. They reconstruct and solve the equations; they do not rerun all large
IBP reductions or fresh numerical integrations. I167 uses the established
I167 = I246 identity instead of an independent I167 reduction. Archived
scientific checks in each `validation/` directory are labeled as earlier work.

For native boundary reconstruction, initialize LiteRed/topology bases as in
the original boundary agent and call:

```mathematica
ComputeWeightedBoundary[rootDir, integrand, permutation, loopPoints,
  regionOrder, minimumUPower, absoluteOutputDirectory]
```

For new function data, use the [Maple producer](../transform/hyperlog/README.md)
and `SVBBuildWeightedJetMatrix[records, coordinates, profile, channel, order]`.
Here `profile` is an association, not an integral number. Weighted profiles
in `data/series/fourloop_hard/catalog.m` supply `LeadingSingularities`, the six
certified `MinimumUPowers`, `BasisReflection` and `MaximumOrder`, along with
the basis, blocks and hashes. Add a profile and its certified data to extend
the catalog; no agent code needs a branch for a new example.

`HigherJetSetup[prefactor, channel, pole, minimum, order]` is the common
root-series engine. It keeps `u^(minimum+r) Y^b` with `2 r+b <= order`.
It computes root powers using `Series`, allowing deeper orders once sufficiently
deep input data are supplied. The ordered raw jets must cover every retained
term; the chosen lower power and finite input depth are mathematical inputs,
not facts inferred from the graph. The existing period converters and key
shift `u^2 Y^16` cover the packaged weight-eight families; extending to other
periods or stronger poles requires a compatible period basis/key shift. A new constraint operator must be derived for
its chosen function basis and analytic assumptions. The orbit basis itself
is regenerated from `seed.m` in the checked-in regression suite.

See [the review record](../REVIEW.md) and [test instructions](../tests/bootstrap/README.md).
