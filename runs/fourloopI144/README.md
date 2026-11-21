# Four-loop I144

From the repository root, run with Wolfram Language and a Python interpreter containing NumPy and python-flint.

```sh
wolframscript -file runs/fourloopI144/run.wl
```

Set `PERIOD_BOOTSTRAP_PYTHON` to choose a Python interpreter. The run reconstructs 1,578 independent seed parameters from 11,642 fitted rows in each prime field. The recovered numerators contain 310, 614 and 491 nonzero terms.

In physical coordinates let `u=z*zz`, `v=(1-z)*(1-zz)` and `d=z-zz`. The three entries of `result.m` multiply `1/((1-u)*d)`, `1/((1-u+v)*d)` and `1/d^2`, in order. They use the original graph arguments. Auxiliary inversion-chart words in the trial space have zero final coefficients. The inventory multiplier for this graph is separate from the integral.

`input.wl` contains the graph and its leading singularities. `fourloopI144ansatz.m` loads the period-decorated word coordinates. `fourloopI144.txt` is the assembled Wolfram expression and `fourloopI144.mpl` contains the Maple expression. The replay writes the coefficient lists, numerators, assembled Wolfram expression and validation report.

The complete native weighted-order-four graph boundary in frame 1324 agrees over the rationals. It has 72 nonzero components, including 40 beyond the order-two overlap. The package also records diagonal regularity and two comparisons with Trillo. See the [replay data conventions](../../scripts/period_bootstrap/README.md).
