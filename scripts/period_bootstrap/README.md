# Replaying a period-resolved bootstrap

Each run supplies two reductions of the same weighted boundary and regularity equations, modulo 1,000,003 and 1,000,033. The input matrices and their GPL maps are frozen at the boundary-assembly stage. The replay starts with these matrices. Regenerating the original position-space graph expansions is a separate calculation.

In each `fit/p*.npz`, `lhs` and `rhs` give the full nonzero equation rows in independent seed coordinates. The first square block spans the columns. The replay solves that block in FLINT and verifies every fitted row. `rows.json` identifies each row by its source stage and zero-based row index. The seed indices in `seed_columns` select a representative after removing redundant parametrizations. The three arrays `ptr`, `cols` and `v` encode the linear map from seed coefficients to GPL coefficients in compressed sparse row format.

The separate `holdout*.npz` contain equation rows and graph values evaluated after solving. `holdout_rows.json` identifies the OPE frame and power indices. A row predicted to vanish counts as a tested row. The run reports nonzero checks separately.

Each row of `words.json` specifies a numerator, a GPL word, a power of pi and a level-two period word. The GPL digits 0 through 4 select 0, 1, the conjugate chart argument, its reciprocal and its complement. Words run from evaluation endpoint to base point. Empty words denote 1. The linear map restricts the allowed combinations of these coordinates. `coeff_sol.m` gives GPL coefficients aligned with the per-numerator lists in the ansatz file. Coefficients multiplying a level-two period follow that convention before the basis converts it to the package's periods.

The solver uses the Chinese remainder theorem and bounded rational reconstruction on the two modular results. It checks the denominator and both congruences. Independent exact and numerical tests of the resulting functions are recorded in each run's `validation/` directory.
