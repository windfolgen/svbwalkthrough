# Analytic integrals in the ancillary basis

The indices refer to the four-loop position-space graphs in `4Loop_int_basis.m`. We use $u=z\bar z$ and $v=(1-z)(1-\bar z)$. Each expression includes the rational prefactors for its stated external ordering. Correlator multipliers, including $u/v$ for row 14, are listed in the [planar index](../docs/4_loop_integrals_section_4.pdf).

## Wolfram results for all 32 planar terms

Each of the 31 distinct basis integrals has a pair of files with identical Wolfram Language source. Rows 15 and 23 use the same $I_{49}$ with different multipliers. The loader returns a list in diagram order. Each entry gives the row, basis index, correlator multiplier, status, filename and a two-argument basis function. It supplies the $1-z$ change of arguments for the legacy $I_{212}$ file. Row 14 gives $I_{260}$ assembled from the four-cut bootstrap of $R_{260}$ and two crossed $I_{168}$ terms. [Load all rows (.m)](fourloopPlanar32.m) · [Load all rows (.txt)](fourloopPlanar32.txt)

From the repository root in a fresh Wolfram kernel, keep `z, zz, u, v` unassigned and load either index. For example, the following returns the full row-15 term at exact conjugate endpoints as a symbolic svMPL expression.

```wl
rows = Get["anc/fourloopPlanar32.m"];
q = (2 + I)/5;
b = Conjugate[q];
row = rows[[15]];
(row["Multiplier"] /. {u -> q*b, v -> (1-q)*(1-b)}) * row["BasisFunction"][q,b]
```

The extra scalar $I_{26}$ can be loaded on its own. Both copies contain all 54 kernel terms, the quartic curve, integration endpoints, inversion chart and real-diagonal prescription. The integral head is `Inactive[Integrate]`. [I26.m](fourloopI26.m) · [I26.txt](fourloopI26.txt)

```wl
i26 = Get["anc/fourloopI26.m"];
i26[q,b]
```

For individual files, `Get` returns an expression in `z,zz` for the svMPL results and for $I_{214}$. It returns a two-argument function for $I_{26}, I_{112}, I_{168}, R_{260}, I_{260}$ and for the legacy $I_{212}$ in its $1-z$ chart. Composite files read their dependencies next to the file being loaded, using the same extension. The indexed `I[z,...,0]` and `f[k]` are formal HyperlogProcedures words and periods. Keep the moving letters symbolic during conversion to ordinary hyperlogarithms. The continuation prescription for $I_{214}$ and its crossed primitive applies to both formats.

| Row | Basis result | Row | Basis result |
|---:|---|---:|---|
| 1 | [I175.m](fourloopI175.m) · [I175.txt](fourloopI175.txt) | 17 | [I5.m](fourloopI5.m) · [I5.txt](fourloopI5.txt) |
| 2 | [I173.m](fourloopI173.m) · [I173.txt](fourloopI173.txt) | 18 | [I39.m](fourloopI39.m) · [I39.txt](fourloopI39.txt) |
| 3 | [I208.m](fourloopI208.m) · [I208.txt](fourloopI208.txt) | 19 | [I38.m](fourloopI38.m) · [I38.txt](fourloopI38.txt) |
| 4 | [I181.m](fourloopI181.m) · [I181.txt](fourloopI181.txt) | 20 | [I21.m](fourloopI21.m) · [I21.txt](fourloopI21.txt) |
| 5 | [I174.m](fourloopI174.m) · [I174.txt](fourloopI174.txt) | 21 | [I37.m](fourloopI37.m) · [I37.txt](fourloopI37.txt) |
| 6 | [I176.m](fourloopI176.m) · [I176.txt](fourloopI176.txt) | 22 | [I27.m](fourloopI27.m) · [I27.txt](fourloopI27.txt) |
| 7 | [I233.m](fourloopI233.m) · [I233.txt](fourloopI233.txt) | 23 | [I49.m](fourloopI49.m) · [I49.txt](fourloopI49.txt) |
| 8 | [I140.m](fourloopI140.m) · [I140.txt](fourloopI140.txt) | 24 | [I160.m](fourloopI160.m) · [I160.txt](fourloopI160.txt) |
| 9 | [I187.m](fourloopI187.m) · [I187.txt](fourloopI187.txt) | 25 | [I167.m](fourloopI167.m) · [I167.txt](fourloopI167.txt) |
| 10 | [I214.m](fourloopI214.m) · [I214.txt](fourloopI214.txt) | 26 | [I162.m](fourloopI162.m) · [I162.txt](fourloopI162.txt) |
| 11 | [I246.m](fourloopI246.m) · [I246.txt](fourloopI246.txt) | 27 | [I163.m](fourloopI163.m) · [I163.txt](fourloopI163.txt) |
| 12 | [I212.m](fourloopI212.m) · [I212.txt](fourloopI212.txt) | 28 | [I164.m](fourloopI164.m) · [I164.txt](fourloopI164.txt) |
| 13 | [I144.m](fourloopI144.m) · [I144.txt](fourloopI144.txt) | 29 | [I133.m](fourloopI133.m) · [I133.txt](fourloopI133.txt) |
| 14 | [I260.m](fourloopI260.m) · [I260.txt](fourloopI260.txt) | 30 | [I168.m](fourloopI168.m) · [I168.txt](fourloopI168.txt) |
| 15 | [I49.m](fourloopI49.m) · [I49.txt](fourloopI49.txt) | 31 | [I169.m](fourloopI169.m) · [I169.txt](fourloopI169.txt) |
| 16 | [I3.m](fourloopI3.m) · [I3.txt](fourloopI3.txt) | 32 | [I126.m](fourloopI126.m) · [I126.txt](fourloopI126.txt) |

### Finite remainders and auxiliary results

| Function | Wolfram and plain-text files |
|---|---|
| Finite remainders | [R168.m](fourloopR168.m) · [R168.txt](fourloopR168.txt) · [R260.m](fourloopR260.m) · [R260.txt](fourloopR260.txt) |
| Basis auxiliaries | [I110.m](fourloopI110.m) · [I110.txt](fourloopI110.txt) · [I112.m](fourloopI112.m) · [I112.txt](fourloopI112.txt) · [I113.m](fourloopI113.m) · [I113.txt](fourloopI113.txt) · [I142.m](fourloopI142.m) · [I142.txt](fourloopI142.txt) |
| Finite subtraction $J_{112}=I_{112}-I_{26}$ | [J112.m](fourloopJ112.m) · [J112.txt](fourloopJ112.txt) |
| Auxiliaries for the $I_{176}$ and $I_{181}$ assemblies | [I6t.m](fourloopI6t.m) · [I6t.txt](fourloopI6t.txt) · [I117.m](fourloopI117.m) · [I117.txt](fourloopI117.txt) · [I41.m](fourloopI41.m) · [I41.txt](fourloopI41.txt) · [I42.m](fourloopI42.m) · [I42.txt](fourloopI42.txt) |
| Auxiliary $I_{120}$ | [I120.m](fourloopI120.m) · [I120.txt](fourloopI120.txt) |
| Gram functions, ladder products and subtractions | [GramAuxiliaries.m](fourloopGramAuxiliaries.m) · [GramAuxiliaries.txt](fourloopGramAuxiliaries.txt) |

In the Maple files, names such as `R168SVNumerator[j]` denote the fitted svMPL function multiplying the corresponding leading-singularity prefactor. The four finite auxiliary results have independent graph fits on the stated svMPL supports. [Auxiliary roles and reproducible fits](../runs/fourloopAuxiliaries/README.md)

The Gram file returns an association of functions. For example, `gram = Get["anc/fourloopGramAuxiliaries.m"]` gives `gram["F"][q,b]` and `gram["R260FromI214"][q,b,j,jc]`, where `j,jc` are the independently continued $I_{214}(q,b)$ and $I_{214}(1/b,1/q)$. The [Wolfram regression check](../tests/bootstrap/planar_anc.wls) loads both formats, checks every direct-archive entry in the planar index and tests the scalar and original-basis assemblies.

## Shared pure functions

All 32 correlator terms have the common representation
$T_r=\sum_i\mathfrak l_{ri}P_i$, including each row's planar multiplier.
$P_1,\ldots,P_{43}$ form the rationally independent svMPL basis in the original ordering.
$P_{44},P_{45}$ are the two algebraic primitives $P_y,CP_y$ of $I_{214}$.
$P_{46},P_{47},P_{48}$ are $Q,SQ,WQ$ with $Q=(z-\bar z)vI_{26}$,
$Sz=z/(z-1)$ and $Wz=1-z$. [Maple](fourloopPlanarPure.mpl) · [Wolfram Language](pure_function_basis.m) · [Plain text in Wolfram syntax](fourloopPlanarPure.txt) · [32 explicit formulas and relations](../docs/4_loop_integrals_section_4.pdf#page=7)

In Wolfram Language, keep the package symbols unassigned. Load the basis from the repository root with the adjacent files `fourloopI26.m` and `fourloopI214.m` in place. The original filename also contains the same definitions. [fourloopPlanarPure.m](fourloopPlanarPure.m)

~~~wolfram
shared = Get["anc/pure_function_basis.m"];
leading = shared["LeadingSingularities"][[11]];
Total[KeyValueMap[#2 shared["P"][[#1]][z, zz] &, leading]]
~~~

In Maple, load the usual four-loop package, then read `fourloopPlanarPure.mpl`.
`PlanarP[i](z,zz)` gives the normalized function.
`PlanarLS[r]` lists pairs $[i,\mathfrak l_{ri}]$. Row 11 uses
$2v/[d(v-1)]$ on $P_{16}$ and $v/d^2$ on $P_{17}$.
Here $u=z\bar z$, $v=(1-z)(1-\bar z)$, $d=z-\bar z$, $y^2=(1-u)^2-4v$
and $y_C=u\,y(1/z,1/\bar z)$. The onefolds use the established Euclidean
chamber and continuation of the corresponding root and primitive. The
[exact word comparison and rank calculation](../runs/planarPureFunctions/README.md)
give the normalizations, external permutations and linear dependencies.

## Elliptic sector and finite auxiliaries

| Integral | Maple entry point | Result file |
|---|---|---|
| $I_{26}$ | `I26Euclidean(z,zz)` | [Scalar onefold and its 54-term weight-seven kernel](fourloopI26.mpl) |
| $R_{168}$ | `R168SV` | [Four rational prefactors with period-completed svMPL numerators](fourloopR168.mpl) |
| $I_{168}$ | `I168Euclidean(z,zz)` | [Original basis integral](fourloopI168.mpl) |
| $R_{260}$ | `R260SVEuclidean(z,zz)` | [Four-cut bootstrap, including the fitted function and its periods](fourloopR260.mpl) |
| $I_{260}$ | `I260Euclidean(z,zz)` | [Original basis integral assembled from the bootstrapped remainder](fourloopI260.mpl) |
| $I_{110},I_{113},I_{142}$ | `I110SV`, `I113SV`, `I142SV` | [I110](fourloopI110.mpl) · [I113](fourloopI113.mpl) · [I142](fourloopI142.mpl) |
| $J_{112}=I_{112}-I_{26}$, $I_{112}$ | `J112SV`, `I112Euclidean(z,zz)` | [Finite subtraction](fourloopJ112.mpl) · [Original basis integral](fourloopI112.mpl) |
| $F,M,G,H,K,Y_0,T_0,C_a,L_b,L_c,I_{38}$ | `R260GramF`, `R260GramM`, `R260GramG`, `R260GramH`, `R260GramK`, `R260GramY0`, `R260GramT0`, `R260GramCa`, `R260Lb`, `R260Lc`, `I38Euclidean` | [Four-cut functions](fourloopR260.mpl) · [Gram auxiliaries and ladder products](fourloopGramAuxiliaries.mpl) |

The worked scalar example rebuilds the elliptic kernel from its graph boundaries. The remainder runs provide coefficient fits, held-out graph tests and numerical comparisons for the formulas above. [Worked $I_{26}$ bootstrap](../runs/fourloopI26/README.md) · [$R_{168}$ benchmark](../runs/fourloopR168/README.md) · [$R_{260}$ benchmark](../runs/fourloopR260/README.md)

The two assembly identities in the original basis are

$$
I_{168}(u,v)=2vI_{26}(u,v)+R_{168}(u,v),\qquad
I_{260}(u,v)=\frac{R_{260}(u,v)+I_{168}(u/v,1/v)+v I_{168}(v,u)}{u}.
$$

The signed $R_{260}$ graph has nine independent leading singularities on the 62 exterior cut classes examined. The reduction of the Gram graph $M$ assumes the four measured cuts are complete, $G=2P_v$ globally for the $I_{214}$ function $P_v$, and the specified svMPL word and period spaces. Both $R_{260}$ and $I_{260}$ inherit those assumptions. The report gives the graph integrands, the ansätze, the exact comparisons with the earlier bootstrap and the Euclidean tests against independent graph integrals, including three points for the signed remainder and the original $I_{260}$. [Standalone report with embedded formulas and verification data](../docs/svMPL-four-loop-bootstrap.pdf)

### Maple usage

Start a fresh Maple session and substitute the two installation paths below. The loader reads the dependencies of all the Maple results in this directory.

```maple
currentdir("/path/to/HyperlogProcedures08"):
read "HyperlogProcedures":
ancDir := "/path/to/svbwalkthrough/anc":
read FileTools:-JoinPath([ancDir, "fourloopBootstrap.mpl"]):
ReadFourLoopBootstrap(ancDir):
I26Euclidean(z,zz);
R168SV;
I168Euclidean(z,zz);
R260SVEuclidean(z,zz);
I260Euclidean(z,zz);
```

Keep the package symbols `z` and `zz` unassigned. In package order, `I[z,w,0]` lists the letters of the word from outermost to innermost. Convert svMPLs to ordinary hyperlogarithms with moving letters still symbolic before point evaluation. The Euclidean procedures return analytic expressions with inert final integrals. For the physical sheet take conjugate endpoints, starting with positive imaginary part for the first endpoint. Continue the two $I_{214}$ primitives from their regular chamber when a ray meets an apparent divisor. With independently continued values $J=I_{214}$ and $J_C=CI_{214}$, use `R260SVFromI214(z,zz,J,JC)`. On a removable prefactor divisor take the limit of the combined function. The [Maple check](../tests/bootstrap/fourloop_anc.mpl) exercises the scalar quadrature, crossings, original normalizations and Gram identities from the repository root.

## Planar and auxiliary benchmarks

The legacy `.txt` files use Wolfram Language syntax for a single expression. Evaluate them with `Get` and the package's words and periods left symbolic. Maple versions are listed where available.

| Integral | Analytic expression |
|---|---|
| $I_{117},I_{120},I_{173},I_{176},I_{181}$ | [I117](fourloopI117.txt) · [I120](fourloopI120.txt) · [I173](fourloopI173.txt) · [I176](fourloopI176.txt) · [I181](fourloopI181.txt) |
| $I_{6t},I_{41},I_{42}$ in the auxiliary diagram notation | [I6t](fourloopI6t.txt) · [I41](fourloopI41.txt) · [I42](fourloopI42.txt). In the fitted orderings, $I_{176}=I_{6t}+I_{117}$ and $I_{181}=I_{42}+(1+u)I_{41}/2$. |
| $I_{144}$ | [Maple](fourloopI144.mpl) (`I144result`) · [Wolfram](fourloopI144.txt) |
| $I_{163},I_{167},I_{169},I_{246}$ | [I163](fourloopI163.txt) · [I167](fourloopI167.txt) · [I169](fourloopI169.txt) · [I246](fourloopI246.txt). The registered external orderings give $I_{167}=I_{246}$. |
| $I_{212}$ | [Maple](fourloopI212.mpl) (`I212Euclidean(z,zz)` in the original labeling) · [Wolfram pure function](fourloopI212.m) (supply `[1-z,1-zz]`). |
| $I_{214}$ | [Maple](fourloopI214.mpl) (`I214Euclidean(z,zz)`) · [Wolfram](fourloopI214.txt). Both retain the final algebraic integration. |
| $I_{233}$ | [Maple](fourloopI233.mpl) (`I233result`) · [Wolfram](fourloopI233.txt) |
| Three-loop bootstrap examples | [I5](threeloopI5.txt) · [I8](threeloopI8.txt) · [hard1](threeloophard1.txt) · [hard2](threeloophard2.txt) |

The original [three-loop svMPL collection](3Loop_integral_insvmpl.m), [four-loop direct integrations](4Loop_integral_results_by_hyperlog.m) and [Gram system](sysgram.m) give the related basis results and identities.
