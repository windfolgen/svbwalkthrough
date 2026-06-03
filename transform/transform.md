# transformation procedures

The general description of the work: the goal of this procedure is to transform expressions in z and zz to another expressions of u and Y. The initial set of variables {z,zz} has different correspondence to {u,Y} under different permutations.

# input and output

The input files can be identified with names:
    1. "allsvliste*_uptow8.txt".
    2. "allsvlistmpl_threeloope*.txt"
    3. "allsvlistmpl_fourloop_invzze*.m"
The output files are names with "_inuv" and "_inuvp" appended according to the permutations of external points 1234. You can refer to Summarize.md for the correspondence between permuations and names. However, here thing is simpler. You get the input from somewhere, then you output the same name with two possible permutation for e0, e1 and einf.

# method used

To perform this transformation efficiently without encountering `Series::sbyc` division-by-zero crashes or structurally broken `SeriesData` objects, the following methodology was established and validated across both 3-loop and 4-loop datasets:

1. **Dynamically Calculated `Y` Expansion Order:**
   The required depth of the `Y` parameter is unique for each term based on the depth of the $1/u$ singularity it contains. A baseline `Series` expansion at $O(1)$ is first used to mathematically determine the maximal pole depth `uPole`. From this, the dynamically required sequence depth is strictly enforced: `yOrderReq = yOrderFinal + 2*uPole + 2`. This guarantees no singular poles are accidentally truncated. 
   - *Note*: Three-loop limits are evaluated to `yOrderFinal = 3` by default. Four-loop limits are evaluated to `yOrderFinal = 4` by default.

2. **Algebraic Substitution to Prevent `Series::sbyc`:**
   Previously, performing simultaneous multi-variable `Series` expansions on expressions with poles (like $1/z$) triggered `Series::sbyc` (Division by a series with no coefficients) failures. This is circumvented by performing an explicit, algebraic substitution of $z$ and $\bar{z}$ using exact pre-computed series expansions (e.g., `zS` and `zzS`), completely bypassing the solver's internal multivariate division bugs.

3. **Rigorous Parameter Assumptions:**
   Square roots with internal phase-ambiguity, such as `Sqrt[(-1+u-v)^2 - 4v]`, mathematically collapse into ambiguous forms like `Sqrt[Y^2]` near $u=0$, causing drastic performance penalties as algebraic algorithms struggle to select branch cuts. By strictly injecting `Assumptions -> {Y > 0, u > 0}` into every `Series` evaluation, the logic is constrained to explicit polynomials instantly.

4. **Flattening `SeriesData` Structures:**
   Nested `SeriesData` expressions from intermediate term combinations will structurally crash downstream matrix solvers (producing `Part specification $Failed[[...]]` errors). To guarantee stability across thousands of ansatz elements, the finalized output is strictly flattened into raw polynomials using `Expand[Normal[...]]` before being serialized to the `.txt` output.

## Usage
Generalized generator scripts (such as `threeloop_generate_mpl.wl` and `fourloop_generate_all_zrep.wl`) have been written to execute this transformation natively.

**Example:**
```bash
wolframscript -f threeloop_generate_mpl.wl
```
This detects the active limit equations, applies the algorithmic logic to map the $z, \bar{z}$ variables into $u, Y$ under both the `uv` and `uvp` permutations, and yields the dynamically computed, compressed, and robust series outputs:
- `allsvlistmpl_threeloope1_inuv.txt`
- `allsvlistmpl_threeloope1_inuvp.txt`
