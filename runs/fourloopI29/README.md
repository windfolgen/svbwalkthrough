# Four-loop elliptic integral $I_{29}$

Write $s_{ij}=(x_i-x_j)^2$, $N=s_{13}s_{24}$, $u=s_{12}s_{34}/N=z\bar z$, $v=s_{14}s_{23}/N=(1-z)(1-\bar z)$, and $d=z-\bar z$. In the frame $(x_1,x_2,x_3,x_4)=(0,z,1,\infty)$ the graph as drawn by Borinsky and Schnetz is $F=I_{29}/u$. In their square the top-left, top-right, bottom-right and bottom-left integration vertices can be labeled $5,7,6,8$, respectively. Thus $(0,z)$ both attach to $(7,8)$, and $(1,\infty)$ both attach to $(5,6)$. The factor $u$ restores the numerator $s_{12}s_{34}$ of entry 29 in the ancillary basis. [Borinsky and Schnetz, arXiv:2206.10460v2 PDF, Eq. (20), p. 30](https://arxiv.org/pdf/2206.10460v2#page=30) · [Ancillary integrands](../../anc/4Loop_int_basis.m)

$$
F=N^2\int\prod_{i=5}^8\frac{d^4x_i}{\pi^2}
\frac{1}{s_{17}s_{18}s_{27}s_{28}s_{35}s_{36}s_{45}s_{46}s_{57}s_{58}s_{67}s_{68}}.
$$

## Cut and characteristic

Represent each point by a twistor line, and let $\langle ij\rangle$ be the determinant of the two pairs of columns defining lines $i,j$. Take lines 1 and 2 to be the two coordinate planes in four dimensions, and lines 3 and 4 to be the column spans of $(\mathbf 1,\mathbf 1)^T$ and $(\mathbf 1,\operatorname{diag}(a,b))^T$, respectively. Then $u=(1-a)(1-b)$ and $v=ab$. Cutting lines 7 and 8 against both 1 and 2 makes each a transversal spanned by $(1,p,0,0)^T,(0,0,1,q)^T$. A common rescaling of all four slopes acts trivially on the cross ratios. After taking its logarithmic residue the two pairs of slopes can be written $(x,y)$ and $(1,t)$.

Vertices 5 and 6 each give the same quadruple-cut box with corners $3,4,7,8$. Each Jacobian is proportional to $D^{-1/2}$, where $D=(A-B-C)^2-4BC$, $A=\langle34\rangle\langle78\rangle$, $B=\langle37\rangle\langle48\rangle$, $C=\langle38\rangle\langle47\rangle$. The two factors give $1/D$. Taking a residue in $x$ introduces the discriminant

$$
\operatorname{disc}_xD =
16u(y-t)^2(t-1)(at-b)\big[(a-1)y-(b-1)\big]\big[a(b-1)y-b(a-1)\big].
$$

The pole $y=t$ leaves a holomorphic differential on a quartic with roots $1,b/a,(b-1)/(a-1),b(a-1)/(a(b-1))$. Their cross ratio in this order, using $(r_1-r_3)(r_2-r_4)/[(r_1-r_4)(r_2-r_3)]$, is $v$. Up to a kinematics-independent constant the cut of $F$ is a Legendre period divided by $\sqrt u\,d$. Thus it is annihilated by $\partial_u|_v$ after multiplication by $\sqrt u\,d$. [Exact determinant check](cut.py)

The kernel fixed by the bootstrap is $K=\sqrt u\,d\,\partial_u|_v(\sqrt u\,d\,F)$. Write $D_u=(1+u-v)^2-4u=d^2$. Then $K=uD_u\partial_u F+(D_u+u\partial_uD_u)F/2$. The onefold reconstructed from $K$ uses $dx/\sqrt{x[(1+x-v)^2-4x]}$ at fixed $v$, with endpoints $x_0=(1-\sqrt v)^2$ and $u$. At a regular real diagonal $\sqrt u\,d F$ vanishes. The chart $v=1$ has a coincident lower endpoint and can be reached by continuity. At an ordinary real diagonal $q=\bar q=t$, the differential definition gives $I_{29}=K(t,t)/[2(t-1)]$, with the continuous value of the kernel.

## Graph boundaries and an independent spectral representation

Gromov, Kazakov and Korchemsky's two-magnon graph-building kernel joins two pairs of vertices by all four possible propagators. Three copies joined in succession on the pairs $(1,2),(7,8),(5,6),(3,4)$ give precisely the twelve edges above. Their dimensionless reduced correlator therefore obeys $[\xi^8]\mathcal G_2=u^2 F=uI_{29}$ with $d^4x/\pi^2$ per integration. The tree and two-loop coefficients divided by $u^2$ are $1/v$ and the square of the one-loop box. The paper gives an all-coupling partial-wave representation and discusses the elliptic four-loop coefficient. [arXiv:1808.02688v1 PDF, Fig. 10 and Eqs. (4.43)–(4.45), printed p. 24](https://arxiv.org/pdf/1808.02688v1#page=26) · [Eigenvalue, Eq. (4.47), printed p. 25](https://arxiv.org/pdf/1808.02688v1#page=27) · [Four-loop discussion, Sec. 6.3, printed p. 36](https://arxiv.org/pdf/1808.02688v1#page=38)

For $Y=1-v$, $L=\log u$, the leading Euclidean boundary is

$$
[u^0Y^0] F = \tfrac16 L^4-2L^3+8L^2-20\zeta(3)L+60\zeta(3)-56 .
$$

The complete leading-twist quartic logarithm is

$$
[u^0L^4]F=\frac{2}{3Y^2}\big[H_{101}(Y)-H_{011}(Y)\big],
\qquad H'_{{0}w}=H_w/Y,\quad H'_{{1}w}=H_w/(1-Y).
$$

To derive it from the graph, order the four radii between $|z|$ and 1. A quartic log requires vertices 7 and 8 first, followed by 5 and 6. Either pair may be interchanged, giving four orders, each of weight $1/24$. In each order, the leading traceless angular moment for a vertex joined to two inner points with longitudinal coordinates $a,b$ is the uniform average on $[a,b]$. Indeed its $m$th moment is $\sum_{j=0}^m a^j b^{m-j}/(m+1)$. Thus 7 and 8 give independent uniform $a,b$ on $[0,1]$. The integrals at 5 and 6 each average $1/(1-Yt)$ on $[a,b]$. Squaring that average and changing variables to $s=1-Ya$, $t=1-Yb$ gives

$$
Y^2 [u^0 L^4]F=\frac16\int_{1-Y}^1 ds\int_{1-Y}^1dt\,\frac{\log^2(s/t)}{(s-t)^2}.
$$

Differentiating the two lower limits gives $\{2H_{01}(Y)/(1-Y)-2H_{11}(Y)/Y\}/3$. The vanishing value at $Y=0$ fixes the primitive. In particular the leading quartic coefficient is $1/6$ for this graph and $1/24$ for $I_{26}$.

The spectral series routine takes the four-loop coefficient of the physical conformal-block poles at $\Delta=S+4+2n$, $S$ even, $n\geq0$. It retains all powers of $L$ through four at any requested Taylor degree. The rational and $\zeta(3)$ contributions can be extracted separately. [Exact series implementation](spectral.py)

For the explicit residue formula let $h=(\Delta+S)/2$, $k=(\Delta-S-2)/2$, $B_h(z)=z^h\,{}_2F_1(h,h;2h;z)$ and $g_{\Delta,S}=u[B_h(z)B_k(\bar z)-B_h(\bar z)B_k(z)]/d$. With the normalization fixed by the tree correlator, the physical-pole expansion reads

$$
F=\frac{1}{u^2}\sum_{S=0,2,\ldots}\sum_{n\ge0}
\underset{\Delta=S+4+2n}{\operatorname{Res}}\,
 W(\Delta,S) E(\Delta,S)^3 g_{\Delta,S},\qquad
W=-\frac{(S+1)(\Delta-2)}{2}\,
\frac{\Gamma(4+S-\Delta)\Gamma(h)^2}
{\Gamma(S+\Delta-1)\Gamma((4+S-\Delta)/2)^2}.
$$

Here $E$ is the two-magnon eigenvalue in units of $(16\pi^2)^{-2}$. The following form isolates each double pole before expanding in $\delta=\Delta-(S+4+2n)$,

$$
E=\frac{16}{(S+1)(\Delta-2)}\sum_{j\ge0}(-1)^j
\left[\frac1{(\Delta-S-4-2j)^2}-\frac1{(\Delta+S+2j)^2}\right].
$$

The zero of $W$ reduces the sixth-order pole of $E^3$ to order five. Expanding $u^{\delta/2}$ generates the five logarithmic coefficients. Replacing $E^3$ by $E$ or $E^2$ reproduces the tree graph or the squared box with the same measure. [Physical-pole partial waves, arXiv:1808.02688v1, Sec. 3, printed pp. 12–13](https://arxiv.org/pdf/1808.02688v1#page=14) · [Eigenvalue, printed p. 25](https://arxiv.org/pdf/1808.02688v1#page=27)

## Function ansatz and checks

At fixed $v$ the integrated result in the ancillary normalization is

$$
I_{29}=\frac{\sqrt u}{d}\int_{(1-\sqrt v)^2}^{u}\!
\frac{K(q_+(x),q_-(x))\,dx}{\sqrt x\sqrt{D(x)}},
\quad D(x)=(1+x-v)^2-4x,\quad q_\pm(x)=\tfrac12(1+x-v\pm\sqrt{D(x)}).
$$

Choose the upper half-plane sheet $\sqrt{D(u)}=d$ and use exchange for its conjugate. A direct native fit with the 401 $I_{26}$ words alone fails. On $z=\bar z=t$, the seven nonconstant binary HPLs regular at $t=0$ of weights at most three give a coefficient matrix of rank 7 for the $L^4$ projection. Its augmented rank is 8 already through $t^8$. Adding the diagonal letter 2 permits $-4(H_{011}+H_{211})/3$, verified through $t^{32}$ with $H'_{2w}=H_w/(2-t)$. This points to the singular locus $v=1$ of the cut, which meets the diagonal at $0,2$. At fixed $\bar z$ its letter is $c=\bar z/(\bar z-1)$.

Use the 401-word $I_{26}$ trial space and add 75 words with $c$ in the outermost integration and binary indices elsewhere, including the shorter words multiplied by the allowed periods. Impose exchange evenness, invariance under $z\mapsto z/(z-1)$ and its conjugate, and the native spectral jet $z^i\bar z^j$ with $i,j\le5$ for all log and period components. The resulting 3,141 rational equations have rank 476. The solution has 45 binary weight-seven words, 12 with $\bar z$ in paper position five, 27 with $c$ in the outermost integration, and eight weight-four words multiplied by $\zeta(3)$. The largest absolute coefficient is 120. [Maple kernel and onefold](../../anc/fourloopI29.mpl) · [Wolfram function](../../anc/fourloopI29.m) · [Plain text](../../anc/fourloopI29.txt)

The fitted kernel reproduces all 315 additional nonzero coefficients in the native jet through $i,j\le8$, including periods. In the crossed cusp $w=1-z\to0$ the primitive soft graph is a wheel with four spokes. Its logarithmic coefficient in $F$ is $-20\zeta(5)\log v$. To see the normalization, expand the four rim propagators in spherical harmonics on $S^3$. Orthogonality forces the same index $m-1$ on each rim and gives the factor $m^{-2}$. In log-squared-radius coordinates the remaining three differences have integral $\int_{\mathbb R}(2a/(a^2+p^2))^4\,dp/(2\pi)=5/(2a^3)$ with $a=m/2$. The coefficient is therefore $20\sum_{m\ge1}m^{-5}$. Differentiating at fixed $v$ predicts $[\log v]K=20\zeta(5)(w+\bar w)+O(|w|^2)$, independently of the native fit. The crossed svMPL expansion reproduces both linear terms. It also tests regularity at both real-diagonal endpoints of the characteristic. On $w=\sqrt v\,e^{i\theta}$ the integral between them is proportional to the angular average of $K/|1-w|$. Exchange symmetry reduces this to its zero Fourier mode. All five diagonal Taylor coefficients through $w^4\bar w^4$ of $K/\sqrt{(1-w)(1-\bar w)}$ vanish separately in every logarithm and period sector. At $v=1/4$, the full integral $\int_0^\pi K(1-\tfrac12 e^{-i\theta},1-\tfrac12 e^{i\theta})\,d\theta/|1-\tfrac12 e^{i\theta}|$ has numerical residual $-4.86\times10^{-6}$ at 12 nodes and $8.93\times10^{-11}$ at 20 nodes, with the absolute weighted contributions summing to about 85. [Endpoint quadrature in Maple](check_period.mpl)

At $z=0.35+0.25i$, the onefold gives $F=142.993952659006$ at both 12 and 20 Gauss–Legendre nodes after $x=1+v-2\sqrt v\cos\theta$. The spectral expansion through total degree 38 gives $142.993952659006$ to the displayed precision. Separately, integration of vertices 5 and 6 reduces the graph to two identical one-loop triangles. Randomized Sobol integration of that positive integral gives $143.0050\pm0.0094$ (32 scrambles, $2^{21}$ points each, one standard error). The uniqueness statement refers to the specified finite svMPL ansatz.

Run the following commands from this directory with Python, SymPy and python-flint. The Euclidean graph check also uses SciPy and NumPy.

```sh
python cut.py
python bootstrap.py
python checks.py
python euclidean.py --power 21 --scrambles 32
```

The default solve uses archived HyperlogProcedures 0.8 projections. To regenerate all 476 columns, set `I29_LIBRARY` to the directory containing `HyperlogProcedures` and `I29_WORK` to an existing local scratch directory. Run `python bootstrap.py --words "$I29_WORK/words.mpl"`, then `maple -q projections.mpl`, then `python bootstrap.py --projections "$I29_WORK"`.

For a fresh held-out test, also set `I29_ANC` to the absolute path of `anc/fourloopI29.mpl`. Run `maple -q check_kernel.mpl` followed by `python checks.py --projections "$I29_WORK"`. This compares the actual 92-term function with the spectral jet and the crossed graph boundary.

With the same `I29_LIBRARY` and `I29_ANC`, `maple -q check_onefold.mpl` evaluates the final integration at 12 and 20 quadrature nodes and compares it with the spectral value above.
