# Benchmark Files

This workspace already contains the parity benchmark assets needed for ansatz-basis work.

## Grouped-by-weight references

- `allsvlistevenans.m`
- `allsvlistoddans.m`

Treat these as the primary structural references when the task is:

- "construct the basis by weight"
- "check how many basis elements appear at each weight"
- "compare a generated basis to the benchmark"

## Flat references

- `svmplevenansatz_threeloop.m`
- `svmploddansatz_threeloop.m`

Treat these as flattened references when the task is:

- "assemble a final ansatz list"
- "compare a flat candidate list"

## Related notebook context

The notebook `svbwalkthrough.nb` contains the narrative explanation for ansatz construction in Section 3. Use it to understand why the grouped and flat files exist, but prefer the exported `.m` files as the operational benchmark.
