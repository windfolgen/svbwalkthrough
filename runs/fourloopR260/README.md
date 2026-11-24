# Four-cut bootstrap of $R_{260}$

The signed remainder in the original basis is

$$
R_{260}(u,v)=uI_{260}(u,v)-I_{168}(u/v,1/v)-vI_{168}(v,u).
$$

The Gram reduction isolates a graph $M$. Write $d=z-\bar z$, $C$ for simultaneous inversion of the two endpoints, and $P_v$ for the function multiplying $v/[d(v-1)]$ in $I_{214}$. The tested ansatz is

$$
M=p_3 F+p_4 C(F)+p_5 G+p_6 C(G),\qquad G=2P_v,
$$

with $(p_3,p_4,p_5,p_6)=(v/[d(u-1)],uv/[d(u-1)],v/[d(v-1)],uv/[d(u-v)])$. The original reconstruction inserts the known $I_{214}$ function in the last two sectors and fits $F$. An independent reconstruction allows both $F$ and $G$ to vary. In the native chart $F$ is the exchange-odd projection of a seed containing 1,162 weight-eight words, 166 weight-five words multiplied by $\zeta_3$, and the term $-848\zeta_3^2 I[z,0,1,0]$. [Maple formula for the remainder](../../anc/fourloopR260.mpl) · [Original integral](../../anc/fourloopI260.mpl)

The four prefactors exhaust every clean start containing eight exterior propagators. This includes all clean starts on twelve or more distinct original propagators. A clean start means that the selected divisors meet transversely at a generic point of the component and that no further polar divisor contains it. The remaining contour classes include starts with only seven exterior propagators and nontransverse intersections. [Cut proof and its scope](../../docs/svMPL-four-loop-bootstrap.pdf)

Within two independent copies of the 1,648-dimensional period-free svMPL space, the graph and regularity equations have full joint rank. At the final stage the fitted functions match all 290 available graph values modulo 1,000,003 and all 139 available modulo 1,000,033. The selected graph minor is nonsingular at both primes. Higher-weight inputs held fixed, there is also no homogeneous deformation in any of the three explicit-period spaces tested. Global completeness of the prefactors and words, and a rational verification of every inhomogeneous high-spin value, remain open. [Independent fit of both functions](independent/README.md)

On a common rational cut, the reduced graph $M$ has residue $p_5/24$ and $I_{214}$ has residue $p_5/48$. [Shared-contour calculation](independent/README.md#shared-rational-cut)

With the released $F$ and the $P_v$ shapes held fixed, the degree-two cubic and quartic OPE logarithms fix the native and crossed normalizations independently to two. The two residuals have spin zero. Four held-out Euclidean boundary evaluations test the resulting signed graph. A fixed-$u$ differential equation for the uncut reduced graph eliminates the thirteen-propagator sector. The svMPL expression obeys the required diagonal boundary condition. Equality of the integrated source with the derivative of the bootstrapped expression remains open. [Differential identity and independent boundary tests](differential/README.md)

## Reproduce the coefficient and boundary checks

Run from the repository root with Python 3.10 or later, NumPy, SciPy and python-flint.

~~~sh
python runs/fourloopR260/weight_eight/bootstrap.py
OPENBLAS_NUM_THREADS=1 python runs/fourloopR260/weight_eight/verify.py
python runs/fourloopR260/periods/verify.py
python runs/fourloopR260/check_boundaries.py
python runs/fourloopR260/independent/check_shared_cut.py
OPENBLAS_NUM_THREADS=1 python runs/fourloopR260/independent/verify.py
~~~

- The **weight-eight fit** starts with 1,356 pivots from the light-cone and angular constraints. Eliminating them leaves 292 directions for the radial conditions. Solving at both primes and lifting to rational numbers reproduces the published function in all 92,885 ordinary product-word coordinates. The solve and the archived fit use different independent subsets of the 4,609 generators. The `ope_*.npz` files contain the kinematic equations in pivot form and the remaining radial equations. Their row labels give the log power, pole or graph constraint, radial degree, and row within that block. Exact substitution in the sparse rational light-cone table checks all 3,772 coordinates of the full generator list.
- The **function-space check** verifies 2,961 rational dependencies among the 4,609 generators and a nonzero rank-1,648 minor. The nonzero holomorphic length-eight coordinates recover all 1,162 coefficients of the native ancillary seed. The **period check** combines the fitted lower-weight seeds with the periods induced by weight eight in four external charts. [Period coefficients and fit record](fit.json)
- The **withheld OPE test** compares frozen predictions for the reduced graph $M$ with independent graph coefficients. In both channels it tests the cubic logarithm at radial degree 21 and the quartic logarithm at degrees 25–28. It also tests native $\zeta_3\log^2 U$ at degrees 21–24. All 182 distinct angular coefficients agree modulo 1,000,003. The 102 repeated at 1,000,033 also agree. The formula digest identifies the PDF attachment named `R260HighLogs.mpl`. [Predictions and graph coefficients by degree and spin](boundary.json)

## Euclidean benchmarks

Each graph error below is the standard error over 32 independent scrambled Sobol sequences of $2^{20}$ points. At each point the signed and original graphs use the same scrambles. The original graph uses its own numerator. [Per-scramble data and crossed $I_{168}$ values](euclidean/graph.json)

| $(u,v)$ | Analytic $R_{260}$ | Direct signed graph | Analytic $I_{260}$ | Direct original graph |
|---|---:|---:|---:|---:|
| $(0.3,0.4)$ | −75.30492809 | $-75.30377\pm0.00698$ | 196.87494444 | $196.87992\pm0.01629$ |
| $(0.6,0.8)$ | −87.93492298 | $-87.94000\pm0.00645$ | 106.65808202 | $106.66210\pm0.00460$ |
| $(1/16,13/16)$ | −208.26753138 | $-208.31055\pm0.07049$ | 991.09211143 | $991.16286\pm0.13797$ |

To recompute the analytic $R_{260}$ values, use SymPy, mpmath and a C++17 compiler in addition to NumPy and SciPy. The evaluator converts the stored ordinary expansions into radial differential equations, continues the crossed $I_{214}$ primitive on two detours and checks their agreement. It also evaluates $R_{168}$ independently at its two comparison points.

~~~sh
OPENBLAS_NUM_THREADS=1 python runs/fourloopR260/euclidean/verify.py
~~~
