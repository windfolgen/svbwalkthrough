# Four-loop integral I214

Row 10 of the planar four-loop correlator is $I_{214}/v$. The expressions in this directory give the basis integral $I_{214}$, including its external factors. [Planar inventory, section 4 (PDF)](../../docs/4_loop_integrals_section_4.pdf)

## Analytic result

Set $u=z\bar z$, $v=(1-z)(1-\bar z)$, $d=z-\bar z$ and $y^2=(1-u)^2-4v$. In the Wolfram and Maple expressions, `zz` denotes $\bar z$. The four leading singularities multiply four single-valued weight-eight numerators in the following order.

$$
I_{214}=\frac{v}{d}\left(P_0+\frac{P_u}{u-1}+\frac{P_v}{v-1}+\frac{u}{y}P_y\right).
$$

The first three numerators are exchange-odd combinations of single-valued hyperlogarithms. The fourth is the primitive of the closed form

$$
\mathrm dP_y=C_A\,\mathrm d\log A+C_M\,\mathrm d\log M,\qquad
A=\frac{1-u+y}{1-u-y},\quad M=\frac{(v+d+y)(v-d-y)}{(v+d-y)(v-d+y)}.
$$

Here $C_A,C_M$ are the explicit weight-seven functions `I214CA` and `I214CM` in the Maple file. Under $z\leftrightarrow\bar z$, $C_A$ is odd and $C_M$ is even. The boundary value $P_y=0$ on the regular Euclidean diagonal fixes the additive constant. The exports give this last integration along $(s z,s\bar z)$ for $0\le s\le1$, with the principal square root in the Euclidean chamber reached along that ray. Continue $y$ and the primitive together elsewhere. Load HyperlogProcedures before reading the Maple file and use `I214Euclidean(q,conjugate(q))` in that chamber. The convention is `I[z,a1,...,an,0]` with the evaluation endpoint on the left and `f[n]` equal to $\zeta(n)$ for $n=3,5,7$. [Maple expression](fourloopI214.mpl) · [Assembled Wolfram expression](fourloopI214.txt) · [Four Wolfram numerators](result.m)

## Ansatz and bounds

The first symbol entry is $u$ or $v$. Subsequent entries admit $u,v,z/\bar z,(1-z)/(1-\bar z)$. The letter $d^2$ is allowed in entries 5–7, the channel letters $1-u,1-v$ in entries 7–8, and $A,M$ in entry 8. There are 214 integrable tensors for each of the three rational prefactors and one for the square-root prefactor. A system of 2,899 exact equations fixes all 643 coefficients. Allowing the channel letters in the last three or four positions gives the same four tensors. [Weight-eight tensors and letter definitions](symbol.json.gz) · [Fits with larger symbol spaces](validation/I214_symbol_validation.json)

At fixed symbol, the period ansatz adds exchange-projected lower-weight words to the rational numerators and closed weight-seven pairs to the two coefficients of the differential. The 1,249 coordinates give 832 independent functions after word identities. The representative in the indicated independent columns has 173 nonzero coefficients. Its correction to $C_M$ is $-441\,\zeta(7)/8$. [Period ansatz](fourloopI214ansatz.m) · [Rank and independent columns](validation/function_rank.json) · [Explicit period corrections](validation/I214_candidate_periods.json)

## Reproduce the fit

From the repository root, use Wolfram Language and Python with `python-flint` installed.

```sh
wolframscript -file runs/fourloopI214/run.wl
```

Set `PERIOD_BOOTSTRAP_PYTHON` to select the interpreter. The replay reads the stored exact equations, selects invertible minors modulo 1,000,003, solves them over the rationals and verifies every residual exactly. It rebuilds the four symbol tensors and compares them to the published tensors. For the period fit it uses only orderings 1234 and 4132. It then tests ordering 1324 and assembles the Wolfram outputs from the recovered coefficients. [Run script](run.wl) · [Replay report](workflow_validation.json)

Each compressed equation file in `fit/` contains one JSON pair per line, consisting of a row label and the integer coefficients followed by the right-hand side. Symbol columns are ordered by $P_0,P_u,P_v,P_y$ and then by node in the final weight of the corresponding coproduct basis. In `coeff_sol.m` the first vector gives these symbol coordinates. The second vector follows the named columns of `fit/period_basis.json`, which also defines the fixed contribution and the functions in each period column. [Graph and prefactors](input.wl) · [Coefficients](coeff_sol.m)

## Independent checks

The Maple check differentiates the two weight-seven functions, verifies closure, and checks exchange parity of the three rational-prefactor numerators. From the repository root, set `HYPERLOG_DIR` to the HyperlogProcedures library directory and run `maple -q runs/fourloopI214/validation/check_differential.mpl`. [Differential check](validation/check_differential.mpl)

With the symbol fixed, 6,339 equations in orderings 1234 and 4132 fix the periods and predict all 3,123 equations in ordering 1324. A separate fit restricted to smaller angular powers predicts 5,427 omitted equations. Expanding the fixed formula to angular powers eight and nine gives 628 further exact matches, including 132 period equations. [Withheld equations](validation/I214_period_holdouts.json) · [Order 1234](validation/I214_frozen_check_1234_N9_native4.json) · [Order 4132](validation/I214_frozen_check_4132_N9_native4.json) · [Order 1324](validation/I214_frozen_check_1324_N9_native4.json)

| $(u,v)$ | Bootstrap $I_{214}$ | Trillo, with one standard error |
|---|---:|---:|
| $(0.3,0.4)$ | 77.46214 | 77.45271 ± 0.06555 |
| $(0.6,0.8)$ | 73.16852 | 73.16953 ± 0.01926 |

Integrating the same closed form from a different point on the regular Euclidean diagonal changes the result by less than $8.3\times10^{-12}$ at both points. [Numerical comparisons](validation/I214_candidate_periods_numerical.json) · [Second integration path](validation/I214_second_path.json)
