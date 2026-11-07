# Four-loop I163

```sh
wolframscript -file runs/fourloopI163/run.wl
```

The ordinary parser and workflow entry point run an explicitly selected
constraint profile. No ignored research files or saved coefficients are
read during the solve. The packaged boundary and function-series data allow
this run to use Wolfram Language alone.

The seven leading singularities are

```mathematica
{1/(z-zz), 1/((u-1)(z-zz)), u/((u-v)(z-zz)), 1/((v-1)(z-zz)),
 1/(z-zz)^2, u/(z-zz)^2, v/(z-zz)^2}
```

`fourloopI163ansatz.m` returns seven lists of pure functions. The weighted
six-image S3 orbit ties their coefficients through a rational parameter map.
There are 608 generator coordinates before eliminating 349 certified zero
directions. The fresh solve leaves 259, 133, 131, 79, 41 and 0 parameters after
zero-direction removal, diagonal regularity, circle logarithms and N2/N4/N6
channel-one data, respectively.

`result.m` contains seven pure numerator pieces. `coeff_sol.m` contains their
coefficient lists. `fourloopI163.txt` is the complete assembled integral.
`generator_coeff_sol.m` records the 608 coordinates used by the exact solve.
The seven pieces reproduce the earlier full six-image result exactly.

Uniqueness is within the specified reciprocal-last-two orbit ansatz. The
circle tests are finite order; completeness of the alphabet remains an
assumption. The older three-image simplification and independent numerical
agreement are recorded in `validation/I163_validation.json`. Those numerical
jobs are not rerun by this script.

See [the generic extension](../../series_agent/WEIGHTED_BOOTSTRAP.md) and
[the data provenance](../../data/constraints/reciprocal_s3_w8/README.md).
