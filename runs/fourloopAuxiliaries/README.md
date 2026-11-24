# Four finite auxiliary integrals

These integrals have independent svMPL bootstraps. In the ordering of the four $R_{168}$ prefactors, put $d=z-\bar z$ and call the four functions $F_1,\ldots,F_4$. Two of the auxiliary results give the exact relations

$$
F_2=2vd\,I_{110},\qquad
J_{112}=I_{112}-I_{26}
       =I_{110}+\frac{F_3+F_4}{2d(u-v)}.
$$

The $I_{110}$ fit tests the function multiplying $1/d$ in $R_{168}$. Together the $J_{112}$ and $I_{110}$ fits also test the sum of the functions on the last two prefactors. A reflected Gram reduction of $uI_{260}$ contains several external orderings of $I_{110}$, $I_{113}$, and $I_{142}$. Their formulas give the corresponding terms of that reduction. The released four-cut expression assembles $I_{260}$ directly from $R_{260}$ and two crossed $I_{168}$ terms. [Analytic formulas and loading conventions](../../anc/README.md) · [Four-cut expression](../fourloopR260/README.md)

| Target | Leading-singularity prefactors in basis order | Fitted coefficients | Rank after symmetry | OPE equations |
|---|---|---:|---:|---:|
| [$I_{110}$](../../anc/fourloopI110.mpl) | $1/(vd)$ | 451 | 2 | 540 |
| [$I_{113}$](../../anc/fourloopI113.mpl) | $v/(ud),\ v(z+\bar z)/(ud^2)$ | 734 | 112 | 585 |
| [$I_{142}$](../../anc/fourloopI142.mpl) | $v/[d(v-1)],\ v/d^2$ | 472 | 98 | 546 |
| [$J_{112}$](../../anc/fourloopJ112.mpl) | $-1/[d(u-v)],\ 1/(vd)$ | 1,127 | 93 | 828 |

Run the following from the repository root with Python 3.10 or later, NumPy and python-flint.

~~~sh
python runs/fourloopAuxiliaries/bootstrap.py
~~~

Each target directory contains its word and period supports, the parity maps back to those words, and the projected OPE matrices and graph values at 1,000,003 and 1,000,033. The supports come from the earlier reconstruction. The fit first solves for all coefficients on that support at both primes and verifies every graph row. It then reconstructs rational coefficients and compares each function against the corresponding Maple formula. The full-function comparison against the earlier radial reconstruction also tests the period terms. Across the four targets it checks 6,096, 6,882, 5,904 and 13,590 radial words respectively. [Comparison by sector](function_comparison.json) · [Derivation and graph integrands](../../docs/svMPL-four-loop-bootstrap.pdf)
