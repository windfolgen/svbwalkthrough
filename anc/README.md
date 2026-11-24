# Analytic integrals in the ancillary basis

The indices refer to the four-loop position-space graphs in `4Loop_int_basis.m`. We use $u=z\bar z$ and $v=(1-z)(1-\bar z)$. Each expression includes the rational prefactors for its stated external ordering. Correlator multipliers, including $u/v$ for row 14, are listed in the [planar index](../docs/4_loop_integrals_section_4.pdf).

## Elliptic sector and finite auxiliaries

| Integral | Maple entry point | Result file |
|---|---|---|
| $I_{26}$ | `I26Euclidean(z,zz)` | [Scalar onefold and its 54-term weight-seven kernel](fourloopI26.mpl) |
| $R_{168}$ | `R168SV` | [Four rational prefactors with period-completed svMPL numerators](fourloopR168.mpl) |
| $I_{168}$ | `I168Euclidean(z,zz)` | [Original basis integral](fourloopI168.mpl) |
| $R_{260}$ | `R260SVEuclidean(z,zz)` | [Conditional four-cut result, including the Gram numerator and its periods](fourloopR260.mpl) |
| $I_{260}$ | `I260Euclidean(z,zz)` | [Original basis integral assembled from the four-cut candidate](fourloopI260.mpl) |
| $I_{110},I_{113},I_{142}$ | `I110SV`, `I113SV`, `I142SV` | [I110](fourloopI110.mpl) · [I113](fourloopI113.mpl) · [I142](fourloopI142.mpl) |
| $J_{112}=I_{112}-I_{26}$, $I_{112}$ | `J112SV`, `I112Euclidean(z,zz)` | [Finite subtraction](fourloopJ112.mpl) · [Original basis integral](fourloopI112.mpl) |
| $F,M,G,H,K,Y_0,T_0,C_a,L_b,L_c,I_{38}$ | `R260GramF`, `R260GramM`, `R260GramG`, `R260GramH`, `R260GramK`, `R260GramY0`, `R260GramT0`, `R260GramCa`, `R260Lb`, `R260Lc`, `I38Euclidean` | [Four-cut numerators](fourloopR260.mpl) · [Gram auxiliaries and ladder products](fourloopGramAuxiliaries.mpl) |

The two assembly identities in the original basis are

$$
I_{168}(u,v)=2vI_{26}(u,v)+R_{168}(u,v),\qquad
I_{260}(u,v)=\frac{R_{260}(u,v)+I_{168}(u/v,1/v)+v I_{168}(v,u)}{u}.
$$

The signed $R_{260}$ graph has nine independent leading singularities on the 62 exterior cut classes examined. The reduction of the Gram graph $M$ assumes the four measured cuts are complete, $G=2P_v$ globally for the $I_{214}$ numerator $P_v$, and the specified svMPL word and period spaces. Both $R_{260}$ and $I_{260}$ inherit those assumptions. The report gives the graph integrands, the ansätze, the exact comparisons with the earlier bootstrap and the two-point tests against independent graph integrals. [Standalone report with embedded formulas and verification data](../docs/svMPL-four-loop-bootstrap.pdf)

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
