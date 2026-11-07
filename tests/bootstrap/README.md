# Bootstrap integration checks

From the repository root, run the complete publication check with:

```sh
python3 tests/bootstrap/run_all.py --cache-root /path/to/repository-with-caches
```

Omit `--cache-root` to check only the four new public examples and their
standalone regressions. The driver starts separate Wolfram kernels, removes
previous generated outputs for the four new examples, and saves its completion
record in `run_all_validation.json`. Logs are written under `scratch/`.

Alternatively, rerun the public scripts individually:

```sh
wolframscript -file runs/fourloopI163/run.wl
wolframscript -file runs/fourloopI167/run.wl
wolframscript -file runs/fourloopI169/run.wl
wolframscript -file runs/fourloopI246/run.wl
wolframscript -file tests/bootstrap/checks.wl
wolframscript -file tests/bootstrap/assembly.wl
wolframscript -file tests/bootstrap/weighted_jets.wl
```

The checks compare I167/I169/I246 with frozen research coefficient and numerator
references, check I163 generator coefficients, and compare its assembled
integral against the independently saved six-image formula. The assembly
comparison verifies all 3,181 formal MPL/period monomial coefficients as exact
rational functions. The orbit basis is rebuilt from its seeds. Additional
checks cover contradictions, unsupported target monomials, inconsistent zero
directions, corrupt data, changed bases, missing boundaries and unmatched graphs.
They also verify the I167 = I246 coefficient/numerator identity and confirm
that I246's input is the graph at index 246 in the ancillary basis.

Legacy regressions and the sequential extension test use isolated outputs:

```sh
python3 tests/bootstrap/prepare_legacy.py --cache-root /path/to/repository-with-caches
wolframscript -file tests/bootstrap/legacy.wl
wolframscript -file tests/bootstrap/extension.wl
```

The six legacy cases are I5, I8, hard1, hard2 at three loops, and I41/I42 at
four loops. These tests reuse existing boundary/series caches and rerun the
original coefficient solves. Both coefficients and numerator lists must match
the original committed examples exactly. Stale result files are deleted only
inside the isolated test root before each run.

`extension.wl` reruns I163 under another label with a factor-two graph
normalization, rejects order-four underdetermination and inconsistent physical
boundaries, verifies stale-output invalidation, then runs an original example
in the same kernel to check that extension state does not affect it.

The JSON reports in this directory record the current review's observed
results. `runs/*/validation/` contains earlier scientific evidence and is
distinct from these fresh integration checks. Tests require Wolfram Language;
legacy runs additionally use the normal package dependencies such as LiteRed.

The shared expansion producer is checked against 336 frozen coefficients
from its earlier N4/N6 formulas, covering both supplied prefactor families,
all six channels and both pole orders. A new prefactor at N8 is independently
checked against its exact generating expression. No integral-number branch
is used by the producer. Empty optional constraints and a basis with no
redundancy directions also pass through the shared exact solver.
