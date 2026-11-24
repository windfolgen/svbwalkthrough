# The finite remainder $R_{168}$

The common elliptic integral subtracts as $R_{168}=I_{168}-2vI_{26}$. Put $d=z-\bar z$. Its four svMPL numerators multiply $v/d^2$, $1/d$, and the two prefactors $v[(u-v)^{-1}\pm(1-v)^{-1}]/d$, in that order. Their exchange parities are $(+,-,-,-)$ and their inversion parities are $(+,-,-,+)$. [Ancillary formula](../../anc/fourloopR168.mpl) · [Integrands, ansatz and graph tests](../../docs/svMPL-four-loop-bootstrap.pdf)

The earlier two-variable reconstruction supplies the word support. Freeing all 3,032 coefficients on that support and imposing the function symmetries leaves 34, 2, 38 and 31 directions in the four sectors. At each of the two primes the 591 OPE equations have rank 105. Rational reconstruction reproduces all four ancillary numerators, including the period terms.

From the repository root, use Python 3.10 or later with NumPy, SymPy and python-flint.

~~~sh
python runs/fourloopR168/bootstrap.py
python runs/fourloopR168/quartic.py
~~~

The first command uses the word and period names in [the trial support](support.json). The two `graph_*.npz` files contain the OPE matrix and right-hand side after projection onto the exchange and inversion parities, and each sector's map back to its original word basis. The script solves both systems before comparing with the Maple formula.

The second command fits the native $\log^4 u$ boundary independently. For $Y=1-v$, the eight binary HPL columns are $G_w(Y)/(24Y)$ with $|w|=4$ and last letter one. The graph supplies the coefficient of $Y^{n-1}$ from $-(T_n-T_{n-1})/12$, where $T_n=\sum_{j=1}^n[(H_n-H_{n-j})/j]^2$ and $H_n$ is the harmonic number. The first eight moments fix coefficients $2,-4,4$ on $0001,0011,0101$. The next 56 moments all agree over the rationals.

| $(u,v)$ | $R_{168}$ | Direct signed graph (one standard error) |
|---|---:|---:|
| $(0.3,0.4)$ | 37.22504594 | $37.19576\pm0.03113$ |
| $(0.6,0.8)$ | 21.91166893 | $21.90754\pm0.01167$ |

The direct integrations used 20 scrambled sequences of $2^{19}$ points per kinematic point. The full-function comparison with the earlier reconstruction gives zero residual in each of the four sectors. [Validation data](validation.json) · [Numerical replay for both remainders](../fourloopR260/euclidean/verify.py)
