# Independent tests of the two numerators of the reduced four-loop graph

The four-prefactor ansatz for the signed graph is $M=p_3F+p_4CF+p_5G+p_6CG$, where $C$ inverts both endpoints. The test allows independent coefficients in the same svMPL space for $F$ and $G$. The reference pair is the released $F$ and $2P_v$, where $P_v$ is the fifth-prefactor numerator of $I_{214}$. [Definitions, derivations and graph integrands](../../../docs/svMPL-four-loop-bootstrap.pdf)

## Function-space rank

Run the checks from the repository root using NumPy and python-flint.

~~~sh
OPENBLAS_NUM_THREADS=1 python runs/fourloopR260/independent/verify.py
~~~

| Cumulative constraints | Rank on the 3,296 coefficients | Free in $G$ |
|---|---:|---:|
| Two-channel radial data and angular regularity | 2,340 | 699 |
| Native and crossed leading light cones and native first-power high logarithms | 2,996 | 300 |
| Longest iterated-integral component of $G$ on $v=1$ | 3,133 | 163 |
| Extended double, cubic and quartic radial harmonics | 3,268 | 28 |
| Native first-twist double-logarithmic moments | 3,285 | 11 |
| Eleven cubic harmonics with spin $s=n-4$ | 3,296 | 0 |

The native cubic moments use radial degrees 22 through 28. The crossed moments use even degrees 22 through 28. Each uses a direct projection of the original $uI_{260}$ graph together with nine signed subtraction terms. For example, at the first prime the native degree-22 spin-18 coefficient is 323,147 and the crossed degree-28 spin-24 coefficient is 382,299. Two degree-18 controls check the signed assembly. [Signed spin contributions, coefficients and observations](independent_graph_rows.json)

The matrix columns follow the pivot order of the released weight-eight change of basis, first for $F$ and then for $G$. The two echelon matrices store the first 2,996 homogeneous equations in reduced form. The circle matrices evaluate the longest-word part of the regularized pullback to $v=1$ on the $G$ columns. The two graph matrices give 290 additional functionals on the original 3,296 columns, in the order of the observation table. The column `H_minus_M` converts native first-twist coefficients from $M$ to the normalization of the measured signed graph $H$. All other rows directly measure $M$. A null graph entry means that the independent right-hand side at that prime is unavailable. The verifier reconstructs the published pair using the rational change of basis, checks the measured values, projects the graph rows onto the residual kernel and verifies a nonsingular minor. [Released generators and rational dependencies](../weight_eight/)

The selected residual minor has determinants 174,796 and 305,403 modulo 1,000,003 and 1,000,033. Of its 163 rows, all have an independent graph right-hand side at the first prime and 84 do at the second. Full rank gives uniqueness of a rational solution within the stated space. The fitted pair passes all measured modular comparisons. Identifying the full inhomogeneous rational solution would require exact graph comparisons or sufficient modular information and a height bound on the residuals.

The six explicit-period minors test the $\zeta_3$, $\zeta_5$ and $\zeta_3^2$ graded systems with higher-weight inputs fixed. The joint ranks are 618, 138 and 18. Each file stores the source row indices, the independent words per numerator, the coefficient minor and the graph-minus-reference residual. An alternative 163 finite and single-log coefficients through degree 16 form a reserved test set. Their tabulated values are predictions. [Reserved boundary coefficients](missing_moments.json)

## Exact exterior cuts

A clean start consists of transverse original propagator divisors with no additional polar divisor through their generic intersection. Every supported eight-exterior start has sorted loop multiplicities $(2,2,2,2)$, $(0,2,3,3)$, $(1,1,3,3)$ or $(1,2,2,3)$. The last two profiles have 9 and 33 exterior orbits. The portable certificate contains the signed symmetrized graph monomials for $M$ and $Y_0=M-2(I_{214}+CI_{214})$, the triple-cut coordinates and 84 partial-fraction decompositions. The verifier constructs the meromorphic form on each orbit in the specified external frame and checks every pole and terminal coefficient over $\mathbb Q(z,\bar z)$. This step uses SymPy and python-flint.

~~~sh
python runs/fourloopR260/independent/check_cuts.py --workers 4
~~~

Use `--orbit 0` to check one pair of complete graph decompositions. The four-prefactor upper bound applies to all subsequent residues on the covered charts. Classifying contours with fewer exterior incidences and exceptional nontransverse starts remains open. The report includes the proofs for the other profiles.

## Shared rational cut

On exterior orbit 41, cut the propagators joining loops 5, 6, 7 and 8 to external sets $\{1,2,3\}$, $\{2,4\}$, $\{3,4\}$ and $\{4\}$, respectively. The verifier takes the same seven ordered residues of each graph over $\mathbb{Q}(z,\bar z)$. Put $p_5=v/[(z-\bar z)(v-1)]$. On this oriented contour, $M$ has residue $p_5/24$, $I_{214}$ has residue $p_5/48$, and $CI_{214}$ and $Y_0$ vanish. The original $uI_{260}$ and both crossed $I_{168}$ subtraction terms also vanish here. Thus this contour measures a factor of two for the reduced graph. The independent fit and the degree-two OPE equations test its extension to the svMPL numerators. [Ordered residues and graph seeds](check_shared_cut.py) · [Exact OPE normalization](../differential/README.md#an-exact-low-order-test-of-the-factor-of-two)

~~~sh
python runs/fourloopR260/independent/check_shared_cut.py
~~~
