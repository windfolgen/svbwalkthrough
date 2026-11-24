# Bootstrapping the elliptic integral $I_{26}$

The cut determines the elliptic integration measure. The function multiplying that measure can be fitted directly in single-valued multiple polylogarithms (svMPLs). This example reconstructs every coefficient of that function from graph boundaries and symmetries, then compares the answer to an independent reconstruction at function level.

## From the graph to the onefold

Write $s_{ij}=(x_i-x_j)^2$, $N=s_{13}s_{24}$, $u=s_{12}s_{34}/N=z\bar z$ and $v=s_{14}s_{23}/N=(1-z)(1-\bar z)$. The scalar graph in the ancillary normalization is

$$
I_{26}=N^2\int\prod_{j=5}^{8}\frac{d^4x_j}{\pi^2}
\frac{1}{s_{17}s_{18}s_{26}s_{28}s_{35}s_{37}s_{45}s_{46}s_{57}s_{58}s_{67}s_{68}}.
$$

The characteristic of the cut is $\rho=u/v^2$. With $d=z-\bar z$, define $P_7=(d/v)(2u\partial_u+v\partial_v)(dvI_{26})$. At fixed $\rho$ the differential operator in parentheses is $v\,d/dv$. Regularity sets $dvI_{26}=0$ at the real-diagonal endpoint and fixes the integration constant. Thus

$$
I_{26}(u,v)=\frac{1}{vd}\int_{x_0}^{v}\frac{dx}{y(x)}P_7(q_+(x),q_-(x)),
\qquad y^2=(1+x-\rho x^2)^2-4x,
$$

where $x_0=4/(1+\sqrt{1+4\sqrt{\rho}})^2$ and $q_\pm=(1-x+\rho x^2\pm y)/2$. In the native Euclidean chart choose $\operatorname{Im}z>0$ and $y(v)=d$. For $u>1$, use $I_{26}(u,v)=u^{-2}I_{26}(1/u,v/u)$. The Maple file supplies the kernel, the onefold and the real-diagonal prescription. [Analytic result](../../anc/fourloopI26.mpl)

## Fitting the kernel

1. Form binary words of length seven, together with $\zeta_3,\zeta_5,\zeta_3^2,\zeta_7$ times words of lengths four, two, one and zero. Allow the moving letter $\bar z$ in the last two positions in paper order, including repetitions. Add the 64 length-seven words with one $\bar z$ in position five and binary letters elsewhere. HyperlogProcedures lists integration indices in the reverse order, so position five here is the third index after $z$ in a Maple word.
2. Impose exchange evenness and simultaneous-inversion oddness on $P_7$. Match the native cubic and quartic light-cone logarithms, the crossed leading-power log bound and the native and crossed expansions by regions for $vI_{26}$. The two graph series use $Y=1-v$ in their local charts. The script differentiates them to form the inhomogeneous equations for $P_7$. [Graph inputs](inputs) · [Function projections in Maple](function_constraints.mpl)
3. Compare the ranks of the coefficient and augmented matrices. Both primes, 1,000,003 and 1,000,033, give the ranks below. Solve independent rows over the rationals and substitute in **all 2,746 equations**.

| Allowed words | Coefficient rank | Augmented rank |
|---|---:|---:|
| Binary, with period sectors | 151 | 152 |
| Moving letter in the last two positions | 337 | 338 |
| Also allowing a single moving letter in position five | 401 | 401 |

The unique solution on this support has **54 terms**. There are 36 binary words of weight seven, 12 with $\bar z$ in position five, and six binary words of weight four multiplied by $\zeta_3$. The full function, including periods, agrees exactly with the earlier reconstruction after both are expanded in ordinary hyperlogarithms. At $(u,v)=(0.47,0.93)$ it gives $P_7=-24.54513046547$. Independent differentiation of the graph gives $-24.54513046415$. At $(0.3,0.4)$ the resulting integral is $I_{26}=102.193737$ and the direct graph gives $102.1984\pm0.0260$. [Validation and further boundary coefficients](validation.json) · [Standalone report](../../docs/svMPL-four-loop-bootstrap.pdf)

## Reproduce the result

From the repository root, use Python 3.10 or later with SymPy and python-flint.

~~~sh
python runs/fourloopI26/bootstrap.py --output /tmp/I26-kernel.json
~~~

The default run reads the six tabulated word projections, constructs the graph right-hand side and fits the coefficients. It compares the recovered kernel with `anc/fourloopI26.mpl` only after solving. In the optional JSON output, `B` denotes $\bar z$, and the words use Maple order.

With Maple and HyperlogProcedures 0.8, regenerate all six projections from the individual words, then check the earlier full function independently.

~~~sh
python runs/fourloopI26/bootstrap.py --maple maple --library /path/to/HyperlogProcedures08
python runs/fourloopI26/compare.py --maple maple --library /path/to/HyperlogProcedures08
~~~

For evaluation, load the ancillary package and call `I26Euclidean(z,zz)` with the Euclidean arguments or `I26P7Value(q,qb,prec)` for the kernel alone. [Maple loading instructions](../../anc/README.md#maple-usage)
