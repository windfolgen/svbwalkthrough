# Four-loop I246

Run from the repository root:

```sh
wolframscript -file runs/fourloopI246/run.wl
```

This uses the integrated weighted workflow with the **347 odd + 409 even = 756** basis.
`input.wl` explicitly selects `BootstrapMethod -> "Weighted"`.
It requires only Wolfram Language. The basis and equation files are shared
under `data/`; no ignored research cache is needed.

This run uses the I246 graph itself and matches its certified boundary data
directly. The resulting coefficients and numerator functions agree with I167,
consistent with the ancillary I167 = I246 identity.

The two leading singularities, in the original coordinates, are:

```mathematica
{v/((v-1) (z-zz)), v/(z-zz)^2}
```

`coeff_sol.m` contains two coefficient vectors; `result.m` contains the
corresponding pure odd/even numerator functions. `fourloopI246.txt` is the
full assembled integral in original `z,zz` coordinates. `run.log` and
`workflow_validation.json` record the fresh equation construction, exact solve
and all-row checks. `replay_validation.json` is the earlier archived replay report.
The files in `validation/` are archived scientific checks from the research,
not numerical jobs rerun by `run.wl`.

`run.wl` calls the original `ParseInput` and `SolveIntegrandSystem` entry
points at order six. The boundary, series and solving agents include the new
procedures. The actual ansatz determines the matrix columns, so rational basis
changes and leading-singularity rescalings are supported. The run uses
certified boundary and series caches, just as the original workflow uses
precomputed data; it does not repeat the large N6 IBP derivation each time.

See [the integrated workflow](../../series_agent/WEIGHTED_BOOTSTRAP.md) and
[the basis](../../data/ansatz/fourloop_hard/README.md).
