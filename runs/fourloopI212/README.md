# Native double-logarithm boundary of $I_{212}$

Let $C_N=[u^0(1-v)^N\log^2u]I_{212}$ in the primary OPE chart. The bootstrap used primary moments only through $N=19$. The two-soft graph calculation and the frozen HPL expression agree separately in the rational and $\zeta(3)$ grades through $N=23$.

Run the following from the repository root with Python 3.10 or later. The calculation uses the standard library.

~~~sh
python runs/fourloopI212/boundary.py
~~~

The graph calculation constructs the two-soft tensor weights and evaluates the hard two-loop moments by triangle integration by parts. It takes its normalization from $H_{00}=6\zeta(3)$. Independently, the script expands the stored HPL prediction in $Y=1-v$ using its two differential kernels. Appendix “From soft regions to OPE boundary equations” gives the external frame, projected graph factors, soft moments, hard recursion and the exact $N=22,23$ values. [Standalone report](../../docs/svMPL-four-loop-bootstrap.pdf) · [Editable appendix](../../docs/soft_region_boundaries.tex) · [Frozen light-cone expression](double_log_boundary.json) · [Full integral](../../anc/fourloopI212.m)
