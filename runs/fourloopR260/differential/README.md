# Testing the fifth numerator of the reduced four-loop graph

The proposed identity is $G=2P_v$. Here $G$ multiplies $p_5=v/[d(v-1)]$ in the reduced graph $M$, $d=z-\bar z$ and $P_v$ is the coefficient of the same prefactor in the independently known $I_{214}$. Inversion $C:(u,v)\mapsto(1/u,v/u)$ supplies the partner $p_6 C(G)$, with $p_6=uv/[d(u-v)]$. Thus the fifth and sixth contributions cancel in $Y_0=M-2(I_{214}+CI_{214})$ if the identity holds. The full graph and the candidate satisfy a common boundary condition. An integrated source from graphs with fewer propagators still needs an independent evaluation to establish equality throughout the Euclidean domain. [Graph definitions and reconstruction](../README.md)

## An exact low-order test of the factor of two

Keep the released $F$ fixed and allow separate constants $a,b$ in $p_5 a P_v+p_6 b C(P_v)$. Set $z=th$, $\bar z=t/h$, $u=t^2$, and $c=(h+h^{-1})/2$. On the Euclidean sheet $c$ is the cosine of the external angle. The table gives the coefficient of $t^2\log^k u$. The graph column is obtained directly from the signed graph monomials.

| $k$ | Graph $M$ | Graph minus $p_3F+p_4CF$ | $p_5P_v$ | $p_6 C(P_v)$ |
|---:|---|---:|---:|---:|
| 4 | $1277/7776-(367/3888)c^2$ | $1/12$ | $0$ | $1/24$ |
| 3 | $-18791/11664+(9151/5832)c^2$ | $-11/6$ | $-1/12$ | $-5/6$ |

The quartic logarithm gives $b/24=1/12$. The cubic logarithm then gives $-a/12-5b/6=-11/6$. Their unique solution is **$a=b=2$**. The result holds identically in the angle. The two residuals have spin zero. These equations determine the normalizations with the shapes and $F$ fixed. A deformation of $G$ starting at a later radial order can evade both. The low-order equations are presented for their analytic sensitivity to the normalizations and can overlap the graph information used for the bootstrap. The four physical graph evaluations below were withheld from the fit.

For the graph column, order the four loop radii between the small external radius and the unit radius. Each term in the expansion of a squared distance has the form $[s^n](1-2s\cos\theta+s^2)^e$, where $e$ is its exponent and $s$ is a ratio of ordered radii. Four resonant radial integrations give the factor $1/24$ in the coefficient of $\log^4 u$. For the cubic coefficient include one freely integrated gap in the ordered interval and the two extensions with one loop outside that interval. A nonzero scaled radial exponent $q$ contributes $-1/(3q)$. This includes the four choices of outside loop through the permutations. The angular integrations pair indices on $S^3$ with denominator $4\cdot6\cdots(2j+2)$ at degree $2j$. The graph computation returns the exact polynomial in $c$ for each log power. [Ordered radial and angular calculation](low_spin_graph.py)

For the function columns the verifier expands the ordinary differential of the released svMPLs through degree four, because $p_5$ starts at $t^{-2}$ at a generic angle. It projects each period sector separately over $\mathbb Q(h)$ and converts $\log t$ to $\log u$. The two surviving nonconstant angular initial states in the cubic calculation evaluate to $+\log h$ and $-\log h$ with equal coefficients. They cancel exactly. All explicit-period columns vanish in these two probes. [Exact comparison for all angles](low_spin.py)

## What determines the two numerators

Allowing two independent weight-eight numerators gives 3,296 period-free coefficients. Immediately before the last eleven graph moments there are eleven free directions. Seven native cubic moments at radial degrees 22 through 28 and four crossed ones at degrees 22, 24, 26 and 28 select a unique solution in this space. Their angular spins are the radial degrees minus four. Replaying the calculation gives rank 3,296 at both primes and agreement with every available graph value (290 at 1,000,003 and 139 at 1,000,033). These eleven moments belong to the fit. The largest spin used in this **last stage** is 24. Other tabulated angular checks reach spin 28. An alternative family of 163 single-log and finite terms through radial degree 16 also separates the earlier 163 free directions. Its archived numbers are predictions pending independent graph evaluation. [Rank certificate and measured inputs](../independent/README.md)

Partial residues and OPE data motivate the prefactors. A reduced graph can contribute a nonzero integral even when its residue on all thirteen parent propagators vanishes. An explicit example below is the scalar graph obtained by omitting $s_{15}$. Absence of a prefactor on a set of cuts therefore requires an additional argument before it can be used to identify a full function-level numerator. The same issue applies to any bootstrap that assumes completeness of its cut-derived ansatz. Its practical significance depends on what independent evaluation is available. [Exterior-cut certificate](../independent/README.md)

## The uncut differential identity

Use $s_{ij}=(x_i-x_j)^2$, fix $x_1=0,x_2=p,x_3=k,x_4=\infty$, and set $p^2=u,k^2=1,(p-k)^2=v$. Define $w=(1+u-v)/2$, $\delta=u-w^2$ and $\lambda=-4\delta=d^2$. Order the distances as

$$
15,16,17,25,26,28,35,37,38,56,57,68,78\;\big|\;18,27,36,58,67 .
$$

For a vector of powers $a$, write $J_D(a)=\int\prod_{i=5}^8(d^Dx_i/\pi^{D/2})\prod_e s_e^{-a_e}$. The first thirteen entries enumerate propagators. Negative entries denote numerator factors. Relabeling the four integration vertices and applying the original packet weights divided by 96 reduces the 336 terms of $M$ to twelve and the 240 terms of $Y_0$ to eight. Both contain exactly one term with thirteen propagators. It is $uv J_D(N)$, where $N$ has all thirteen propagators and numerator $s_{58}s_{67}$. Define $M_D,Y_{0,D}$ by continuing these aligned packets to dimension $D$.

For either packet $X_D$, the following identity holds before taking any cuts,

$$
2\delta(\partial_v-\beta_D)X_D=S_D[X],\qquad
\beta_D=\frac{2D-7}{v}+\frac{3-D}{2}\frac{\partial_v\lambda}{\lambda}.
$$

The derivative holds $u$ fixed. To derive it, take the unique $B\in\operatorname{span}(p,k)$ with $B\cdot p=B\cdot k=1/(2v)$ away from $\delta=0$. Put $\alpha=-B\cdot k$, $\Omega x=B(k\cdot x)-k(B\cdot x)$, and

$$
V(x)=2(B\cdot x)x-x^2B+\alpha x+\Omega x .
$$

This vector field fixes $0,k$, leaves $p^2$ constant and changes $(p-k)^2$ at unit speed. Its divergence is $D(2B\cdot x+\alpha)$. The logarithmic derivative of each squared distance is the sum of $2B\cdot x+\alpha$ at its endpoints. Changing the four loop variables by this field gives the external derivative without raising any propagator power.

Subtract nine integrated total derivatives to eliminate every term with thirteen propagators. Each row below gives an extra numerator on the seed $N$, a loop vertex $i$, an anchor $j$, and the multiplier of $uv\,\partial_{x_i}\cdot[(x_j-x_i)\,\mathrm{seed}]$. Write $t=(1-w)/v$, $r=(u-w)/v$.

| Extra numerator | $i$ | $j$ | Multiplier |
|---|---:|---:|---:|
| $s_{18}$ | 8 | 5 | $-1$ |
| $s_{27}$ | 7 | 5 | $t$ |
| $s_{36}$ | 6 | 5 | $r$ |
| $s_{58}$ | 8 | 1 | $1$ |
| $s_{58}$ | 8 | 2 | $-t$ |
| $s_{58}$ | 8 | 3 | $-r$ |
| $1$ | 6 | 5 | $w$ |
| $1$ | 7 | 5 | $w$ |
| $1$ | 8 | 5 | $w$ |

The integration-by-parts identities are understood by analytic regularization and continuation. The resulting coefficients are regular at $D=4$. Individual integrals can have poles, so the four-dimensional limit applies to the sum. The following counts are counts of indexed integrals before master reduction. [Exact coefficients and derivation](source.py)

| Propagators present | 12 | 11 | 10 | 9 |
|---|---:|---:|---:|---:|
| $S_D[M]$ | 65 | 44 | 53 | 28 |
| $S_D[Y_0]$ | 49 | 8 | 53 | 28 |

An independent external derivative taken directly on the propagators, followed by a Kira 3.1 reduction at symbolic $u,v,D$, tests all thirteen quotients obtained by cutting twelve propagators. Six vanish for both sources. Omitting $15,25,35,56,57,68,78$ gives respectively 3, 6, 6, 3, 3, 2 and 2 nonzero master coefficients. Six further eleven-propagator quotients vanish for both packets. The omitted pairs in the edge numbering above are $(2,3),(2,5),(2,6),(2,8),(2,9),(5,6)$. Lower sectors discarded in each quotient can still contribute to the uncut integral. [Exact quotient reductions](quotients.py)

### Three scalar subintegrals

Let $J_{-ij}$ denote the scalar four-dimensional integral of all thirteen propagators except $s_{ij}$, with numerator one. Removing $15,25$ or $35$ makes all four integrated vertices four-valent. Three-point covariance then fixes the powers of $u,v$. Complete each graph to a four-regular graph by joining the deficient external vertex to the other two external vertices. For the first completion the complement consists of a triangle and a four-cycle. Removing the three vertices of that triangle separates the completed graph into two pieces, each giving a completed $K_5$ period after the triangle is restored. The product is $(6\zeta(3))^2$. The other two completions have complement a seven-cycle and are completed five-loop zig-zags. The five-loop period is $441\zeta(7)/8$. In the normalization used here this gives

$$
J_{-15}=\frac{36\zeta(3)^2}{u v^2},\qquad
J_{-25}=\frac{441\zeta(7)}{8u v},\qquad
J_{-35}=\frac{441\zeta(7)}{8u^2v}.
$$

HyperlogProcedures 0.8 reproduces all three as graphical functions. Its shuffle normalization gives $2 f_{3,3}=\zeta(3)^2$. Other nonzero master coefficients and their required regulator orders still enter the source. [Brown and Schnetz, *Proof of the zig-zag conjecture*, PDF p. 2, Theorem 1.1](https://www.ihes.fr/~brown/ZigZag.pdf#page=2) · [Maple verification](periods.mpl)

## Boundary and uniqueness

At $D=4$ a homogeneous solution at fixed $u$ is $v/d$. Consequently a sufficient certificate for the candidate $M_*$ is the single source identity

$$
\lim_{D\to4} S_D[M]=
2\delta\,\frac{v}{d}\,\partial_v\!\left(\frac{d}{v}M_*\right).
$$

It suffices to prove this on an open two-dimensional Euclidean patch adjacent to a regular diagonal segment. There the difference of $dM/v$ and $dM_*/v$ is constant in $v$ for each $u$. On the diagonal $v=(1-\sqrt u)^2$ both vanish for small positive $u$. The aligned graph terms are regular for separated Euclidean external points. The source verifier checks strict four-dimensional power counting for every cluster of integration vertices, at each fixed external point and at infinity after inversion. For the candidate the complete tangential restriction of $F,CF,P_v,CP_v$ vanishes, including explicit periods. Equality of the two functions would then extend on their common connected physical sheet by analytic continuation.

The restriction uses the ordinary differential of the released svMPLs. Pull it back to $z=t h,\bar z=t/h$ near $h=\pm1$, or to $\bar z=t,z=t/(t-1)+ht$ near $h=0$ for $v=1$. No radial pole away from zero coalesces with the tangential origin. Multiply the triangular residue matrices for every radial word down to the 213 allowed angular constants. All fourteen diagonal period columns and all three native $P_v$ columns on $v=1$ vanish term by term. On the crossed circle corresponding to $u=1$, all five period columns of $F+CF$ vanish. Inversion gives the corresponding result at $u=v$. Grouping the generic displaced radial letters before restriction also eliminates every angular initial word containing either of the two potentially singular angular letters. The remaining initial values are powers of logarithms of a nonzero ratio. The radial equation is uniformly regular singular at the origin with constant residue. This proves local transverse regularity on the generic segments, so division by an apparent simple zero is legitimate there. The checks apply to the candidate; a boundary value of the uncut graph supplies separate evidence. [Full-word and transverse checks](restrictions.py)

## Withheld Euclidean boundaries

Direct graph integration uses the signed $R_{260}$ graph at the specified kinematics. Integrating the two box subgraphs leaves an eight-dimensional quadrature. Each error is the standard error of 24 independent scrambled Sobol estimates with $2^{18}$ points each. The analytic entry is the one-sided limit from regular kinematics with fixed $u$. Three extrapolation stencils agree to $3\times10^{-6}$.

| Boundary | $(u,v)$ | svMPL $R_{260}$ | Direct signed graph |
|---|---|---:|---:|
| $v=1$ | $(0.36,1)$ | $-120.1428272$ | $-120.1511\pm0.0292$ |
| $v=1$ | $(0.64,1)$ | $-98.1070279$ | $-98.0929\pm0.0183$ |
| $z=\bar z=1/4$ | $(1/16,9/16)$ | $-178.0124212$ | $-178.1007\pm0.1937$ |
| $z=\bar z=-1/2$ | $(1/4,9/4)$ | $-188.6078838$ | $-188.6708\pm0.0340$ |

On $v=1$ regularity makes $p_5P_v$ finite. Its limit contains a normal derivative of $P_v$. The physical value therefore tests more than the vanishing of the numerator on that circle. Vary a common coefficient in $G=aP_v$ with the other sectors fixed. The two circle graph values give $a=1.9999232\pm0.0002708$ and $a=2.0001506\pm0.0001952$. Allowing separate native and crossed coefficients gives $1.99940\pm0.00058$ and $2.00130\pm0.00078$, with matching scrambles paired across the two points. These are numerical tests of fixed shapes; the degree-two result above determines their normalizations exactly. [Graph and analytic data](boundaries.json) · [Independent signed integrator](boundary_graph.py)

The physical analytic continuation uses $\log(h^2)=2\log h$ along the upper-half-plane angular path. In the crossed elliptic primitive, the detours around the real axis stay inside the nearest pair of nonreal singularities. These prescriptions keep the same sheet as the diagonal is approached. [Angular continuation](../euclidean/radial.py) · [Elliptic continuation](../euclidean/verify.py)

## Reproduction

From the repository root run the following commands with Python, SymPy, NumPy and python-flint. The export contains both exact sources in the stated edge order. To regenerate the Kira tables use the job writer, run Kira 3.1 in each generated folder, then pass their parent to the checker with `--from-jobs`.

~~~sh
python runs/fourloopR260/differential/low_spin.py
python runs/fourloopR260/differential/boundaries.py
python runs/fourloopR260/differential/source.py --export /tmp/r260-sources.json
python runs/fourloopR260/differential/quotients.py
python runs/fourloopR260/differential/restrictions.py
~~~

The boundary checker also accepts `--graph` and `--analytic` to redo the quadratures and svMPL continuations. These options use SciPy. The analytic option also needs mpmath and a C++17 compiler. Set `OPENBLAS_NUM_THREADS=1` for the numerical runs.
