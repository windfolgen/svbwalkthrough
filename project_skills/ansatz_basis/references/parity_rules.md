# Parity Rules

Conservative rules for parity labelling of SVHPL basis elements:

## Preserve
- **Benchmark bucket structure**: the grouped benchmark files
  define the canonical partition of elements into weight buckets.
  Do not regroup elements across weight boundaries.
- **Grouped/flat file role split**: the grouped file is the primary
  structural reference; the flat file is a derived convenience
  format.  Always validate grouped first.
- **Explicit diff reporting**: when a mismatch is found, report
  which weight bucket(s) differ and what is missing / extra.

## Do not assume
- **Completeness without proof**: a candidate basis that matches the
  benchmark is valid ONLY if the benchmark is known to be complete
  for that weight and parity.  Without explicit benchmark coverage,
  label the result as "candidate".
- **Interchangeability of grouped and flat**: different linear
  combinations of the same basis elements can produce different
  grouped results.  Always compare grouped-to-grouped and
  flat-to-flat.
- **Acceptability of alternative linear combinations**: if the flat
  basis contains the same elements as the benchmark but in a
  different order, the grouped comparison will catch mismatches at
  the bucket level.

## Practical rule
Always compare against the grouped benchmark first.  If grouped
passes, flatten and compare against the flat benchmark as a
consistency check.  If grouped fails, do not proceed to flat
comparison.
