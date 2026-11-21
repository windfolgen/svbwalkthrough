# Four-loop I233

From the repository root, run with Wolfram Language and a Python interpreter containing NumPy and python-flint.

```sh
wolframscript -file runs/fourloopI233/run.wl
```

Set `PERIOD_BOOTSTRAP_PYTHON` to choose a Python interpreter. The run reconstructs 1,030 independent seed parameters from 3,002 fitted rows in each prime field. The four recovered numerators contain 677, 614, 310 and 554 nonzero terms.

In physical coordinates let `u=z*zz`, `v=(1-z)*(1-zz)` and `D=zz-z`. The four entries of `result.m` multiply `u/((1-u)*D)`, `u/((1-u-v)*D)`, `u/((1-v)*D)` and `u/D^2`, in order. The native arguments of numerators 1, 2 and 4 are `1/(1-z),1/(1-zz)`. Numerator 3 uses `1-z,1-zz`. These substitutions are already made in the Wolfram result. The inventory multiplier for this graph is separate from the integral.

`input.wl` contains the graph and leading singularities. `fourloopI233ansatz.m` loads the period-decorated word coordinates. `fourloopI233.txt` is the assembled Wolfram expression and `fourloopI233.mpl` contains the Maple expression. The replay writes the coefficient lists, numerators, assembled Wolfram expression and validation report.

The separate order-four double-logarithm comparison covers three frames. The graph data were available during development of the ansatz. A direct rational check of the cubic logarithm also agrees in all 154 angular components through degrees 13, 12 and 12 in frames 1234, 4132 and 1324. Some lower-degree cubic conditions enter the fit. The validation directory includes the graph coefficients, predictions, a leading-twist check and two comparisons with Trillo. See the [replay data conventions](../../scripts/period_bootstrap/README.md).
