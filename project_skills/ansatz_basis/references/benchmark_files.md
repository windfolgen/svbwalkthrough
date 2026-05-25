# Benchmark Files

## Grouped by weight (primary references)
- `allsvlistevenans.m` — parity-even SVHPL basis, grouped by
  transcendental weight (list of lists).
- `allsvlistoddans.m` — parity-odd SVHPL basis, grouped by weight.

These are the **primary structural references** for construction.
Always compare weight-by-weight against these files first.

## Flat (secondary references)
- `svmplevenansatz_threeloop.m` — parity-even ansatz, flat list.
- `svmploddansatz_threeloop.m` — parity-odd ansatz, flat list.

These are the **final output format** used by the ansatz in the
coefficient-solving pipeline.  They are derived from the grouped
files and should only be consulted after the grouped structure is
confirmed.

## Context
The notebook `svbwalkthrough.nb` Section 3 describes the original
ansatz construction.  The grouped files are produced by the
`allsvlistevenans` / `allsvlistoddans` routines in that notebook.
