# Weight-eight bases for I167, I169 and I246

These are the bases used in the completed bootstrap, exported from the
research checkpoints into the ordinary data tree. The files use **`w,ww`**,
where `w = 1-z` and `ww = 1-zz`. Each run's ansatz loader makes this
substitution explicitly, so the run outputs use the original physical `z,zz`.

Write `M = ww`, `R = 1/ww`. Positions below count the integration letters
in `I[w,a1,...,an,0]` from the front, excluding both endpoints. These correspond
to the paper/package's last integration indices. Repeated moving letters
are allowed.

The original two-family raw space is the union of:

* words with `M` allowed in positions 1–4, all other letters in `{0,1}`;
* words with `R` allowed in positions 1–2, all other letters in `{0,1}`.

The mixed extension additionally allows `R` in positions 1–2 and `M` in
positions 3–4 of the same word, with later letters in `{0,1}`. The parity
projection is exact formal conjugation parity. Both raw families are allowed
in each numerator before the odd/even projection and coefficient fit.

The total-weight-eight completion contains words of length 8, `f[3]` times
length 5, `f[5]` times length 3, `f[3,3]` times length 2, `f[7]` times length 1,
and `f[5,3]`, `f[3] f[5]`, with `f[3,3] = f[3]^2/2`.

| File | Length | Meaning |
|---|---:|---|
| `raw_two_family_w8.m` | 1875 | Original union before parity |
| `raw_mixed_family_w8.m` | 2330 | Union including the mixed family |
| `two_family_odd_w8.m` | 340 | Original odd basis |
| `two_family_even_w8.m` | 395 | Original even basis |
| `mixed_odd_extension_w8.m` | 7 | Additional odd directions |
| `mixed_even_extension_w8.m` | 14 | Additional even directions |
| `mixed_odd_compact_w8.m` | 2 | The two additional directions used by the solution |

I169 uses the 340 + 395 = **735** basis. I167 and I246 use the complete
347 + 409 = **756** basis in their run scripts, preserving the space actually
used for the successful fit. Concatenate the old and extension lists **within
each parity sector**, then concatenate odd before even to match the equation
columns. This ordering is recorded in the series catalog; the integrated workflow
projects changed input bases onto it.

For I167/I246 the seven new odd coefficients are `{0,0,0,0,0,16,64}` and all
fourteen new even coefficients vanish. Thus a sufficient smaller basis is
`Join[two_family_odd, mixed_odd_compact]` for the odd sector and
`two_family_even` for the even sector: **342 + 395 = 737**. The compact file
contains full odd basis entries 346 and 347, in that order. This is a selected
sufficient subspace, not a claim of intrinsic minimality. Uniqueness is inherited
from the full-rank 756-column system.

The I167 and I246 run folders also contain `coeff_sol_compact737.m`, with
two coefficient lists of lengths 342 and 395 in this compact ordering. The
packaging verification reconstructs the same numerator functions exactly.

Use `Get["file.m"]` to read a list. The files contain actual expressions, not
references to ignored caches. [The integrated workflow](../../../series_agent/WEIGHTED_BOOTSTRAP.md)
explains how the bases, function-series data and independent graph boundaries
are used.
