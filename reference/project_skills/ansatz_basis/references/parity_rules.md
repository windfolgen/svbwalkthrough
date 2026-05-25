# Parity Rules

This skill is intentionally conservative.

## What to preserve

When labeling a candidate basis as parity-even or parity-odd, preserve:

- the benchmark bucket structure by weight
- the benchmark file role split:
  - grouped files for structure
  - flat files for final ansatz shape
- explicit reporting of missing and extra terms

## What not to assume

Do not assume:

- that a generated basis is complete just because it looks plausible
- that the flat benchmark is interchangeable with the grouped benchmark
- that a different linear combination is acceptable unless the task explicitly allows equivalence checking beyond exact benchmark form

## Practical rule

If there is any doubt, compare against the grouped benchmark first. Only move to the flat benchmark when the caller explicitly needs a flat ansatz list.
