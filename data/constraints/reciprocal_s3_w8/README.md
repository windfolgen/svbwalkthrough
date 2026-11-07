# Reciprocal-letter S3 profile used by I163

`seed.m` contains seven pure-function sectors, their 608-column rational seed
map, six crossing images and their weights. `constraint_agent/orbit.wl`
constructs `orbit.m` by exact rational prefactor decomposition. The regression
suite regenerates that file and compares it exactly.

`boundary_jets.m` contains keys and a 608-column function-series operator.
`boundary_N2.m`, `boundary_N4.m` and `boundary_N6.m` are separately calculated
physical boundary expressions. `diagonal.m` and `circle.m` contain homogeneous
operators. None of these files contains a fitted coefficient solution.

The data were promoted from the completed `correlator32_extension` research:

| Package file | Research source |
|---|---|
| `seed.m` | `reciprocal_last2_{odd,even}_w8.m` and `I163_{odd,even}_H_seed_coordinates.m` |
| `boundary_jets.m` | `I163_S3_limit1_N6.m` |
| `boundary_N*.m` | `I163_N*_limit1/boundary.m`, native graph reductions |
| `diagonal.m` | `I163_full_diagonal.m`, all six images at generic `z=zz` |
| `circle.m` | `I163_circle.m`, seven-sector logarithm cancellation |
| `zero_generators.m` | `I163_exact_zero_generators.m` |

The zero directions were derived as whole-function identities within the
pure-HPL subspace: reflection/inversion representations obey the S3 group
relations, their average is a projector, and the nullspace of that average is
lifted into the 608 generator coordinates. The archived checks are in
`validation/whole_function_nullity.json`. The current workflow checks that
every boundary and regularity operator annihilates these directions before
fixing their coordinate gauge. This does not replace the whole-function proof
with a finite-jet test.

`profile.wl` records hashes, orders, normalization, monomial conventions and
the mathematical scope. The graph is the product of the two entries for
index 163 in `anc/4Loop_int_basis.m`. Lower orders select the same weighted
triangular region used by the native calculations.

The integration reruns the exact linear algebra and output assembly. It
reuses the completed native graph reductions and local-function expansions;
it does not claim a fresh derivation of every data packet.
