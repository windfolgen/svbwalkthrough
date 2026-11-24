# Pure functions of the 32 planar integrals

In the original external ordering, write the full planar term, including its multiplier, as
$$
T_r=\sum_{i=1}^{48}\mathfrak l_{ri}P_i,\qquad d=z-\bar z .
$$
The 62 svMPL occurrences span 43 functions over the rationals, including all period terms. The exact elimination reconstructs every occurrence. Its 43 selected words give a nonzero minor at both archived primes. Five further labels give the onefold evaluations in this ordering. [All 32 expansions and shared functions](../../docs/4_loop_integrals_section_4.pdf#page=7) · [Analytic functions and prefactors](../../anc/README.md#shared-pure-functions)

| Comparison | svMPL | Onefold | All |
|---|---:|---:|---:|
| Occurrences | 62 | 6 | 68 |
| Literal equality in the chosen normalization | 52 | 5 | 57 |
| Equality up to a nonzero rational factor | 47 | 5 | 52 |
| Equality up to scale and the six external orderings | 33 | 2 | 35 |

The complete coefficient on each original prefactor is one occurrence. A product counts as one function. Row 14 is the assembled four-cut benchmark for the original integral. Its two crossed scalar primitives are kept separately. The rational basis of row 30 follows the unpaired prefactors printed in Table 4. The measured prefactors of the signed remainder and the reduced Gram graph are recorded separately in the [R260 calculation](../fourloopR260/README.md).

The exact comparison can be rerun from the repository root with Python 3.10 or later and its standard library.

~~~sh
python3 runs/planarPureFunctions/census.py --output /tmp/planar-relations.json
cmp /tmp/planar-relations.json runs/planarPureFunctions/relations.json
~~~

Each entry of the [result](relations.json) uses a row and a sector in Table 4 order. The PDF defines the sector order for row 14 and takes the elliptic primitive last in row 30. An orbit entry lists every map and scale that takes its representative to the indicated member. The six maps are the identity, reflection $W:z\mapsto1-z$, inversion $C:z\mapsto1/z$, $S:z\mapsto z/(z-1)$, $CW:z\mapsto1/(1-z)$ and $WC:z\mapsto(z-1)/z$. Both endpoints transform together. The list of representatives in `fixed_basis` defines $P_1,\ldots,P_{43}$ in order. Each is an original coefficient function. The lower weight kernel inside $P_{46}=(z-\bar z)vI_{26}$ has the existing Maple name `I26P7SV`.

The [word archive](canonical_words.zip) stores exact rational coefficients in tab-separated files for all six charts. Rows 1–32 contain the ordinary source functions. Auxiliary records 0.1 and 0.2 give the odd Gram function and the native two-loop ladder square. The five ordinary components of row 14 are assembled from these records, the square fishnet and the rational functions of $I_{214}$. The comparison checks every transformed match in all six orderings. It then performs exact elimination and verifies each fixed-ordering expansion by substitution.

To regenerate the word vectors from the ancillary integrals, set `PURE_OUTPUT` to an existing local working directory and `HYPERLOG_DIR` to an installation of HyperlogProcedures 0.8. Run the following from the repository root. The Wolfram step verifies every rational-prefactor projection identically. The Maple step normalizes words and periods and transports the complete functions. The final export uses Python with SymPy.

~~~sh
wolframscript -file runs/planarPureFunctions/extract.wls
maple -q runs/planarPureFunctions/compare.mpl
python3 runs/planarPureFunctions/census.py "$PURE_OUTPUT" --output /tmp/planar-relations.json
python3 runs/planarPureFunctions/export.py "$PURE_OUTPUT" /path/to/output-directory
~~~
